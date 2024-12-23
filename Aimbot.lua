-- Services
local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

-- Local Player and State
local LocalPlayer = Players.LocalPlayer
local Holding = false
local LastUpdate = tick()
local UpdateInterval = 0.016 -- 60fps target

-- Settings with improved defaults
local Settings = {
    AimbotEnabled = true,
    TeamCheck = false,
    AimPart = "Head",
    AirAimPart = "LowerTorso",
    Sensitivity = 0.15,
    PredictionAmount = 0.165,
    AirPredictionAmount = 0.2,
    BulletDropCompensation = 0.1,
    DistanceAdjustment = true,
    UseCircle = true,
    WallCheck = true,
    PredictionMultiplier = 1.5,
    MaxDistance = 1000,
    TargetLockKey = Enum.KeyCode.E,
    ToggleAimbotKey = Enum.KeyCode.Q,
    
    -- FOV Circle settings
    CircleSides = 64,
    CircleColor = Color3.fromRGB(255, 255, 255),
    CircleTransparency = 0.7,
    CircleRadius = 120,
    CircleFilled = false,
    CircleVisible = true,
    CircleThickness = 1,
    
    -- Box settings
    BoxEnabled = true,
    BoxColor = Color3.fromRGB(255, 0, 0),
    BoxTransparency = 0.5,
    BoxThickness = 0.05,
    
    -- Highlight settings
    VisibleHighlight = true,
    HighlightFillColor = Color3.fromRGB(255, 0, 0),
    HighlightOutlineColor = Color3.fromRGB(255, 255, 0)
}

-- Initialize FOV Circle
local FOVCircle = Drawing.new("Circle")
local function UpdateFOVCircle()
    FOVCircle.Position = UserInputService:GetMouseLocation()
    FOVCircle.Radius = Settings.CircleRadius
    FOVCircle.Filled = Settings.CircleFilled
    FOVCircle.Color = Settings.CircleColor
    FOVCircle.Visible = Settings.CircleVisible and Settings.UseCircle
    FOVCircle.Transparency = Settings.CircleTransparency
    FOVCircle.NumSides = Settings.CircleSides
    FOVCircle.Thickness = Settings.CircleThickness
end

-- Cached variables
local CurrentTarget = nil
local CurrentHighlight = nil
local CurrentBox = nil
local CachedParts = {}

-- Optimized wall check with caching
local function IsTargetVisible(targetPart)
    if not Settings.WallCheck then return true end
    
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit * (targetPart.Position - origin).Magnitude
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    local raycastResult = Workspace:Raycast(origin, direction, raycastParams)
    return not raycastResult or raycastResult.Instance == targetPart
end

-- Improved target selection
local function GetClosestPlayerToMouse()
    local shortestDistance = Settings.CircleRadius
    local target = nil
    local mousePos = UserInputService:GetMouseLocation()
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if Settings.TeamCheck and player.Team == LocalPlayer.Team then continue end
        
        local character = player.Character
        if not character then continue end
        
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end
        
        local aimPart = character:FindFirstChild(Settings.AimPart)
        if not aimPart then continue end
        
        local screenPoint = Camera:WorldToScreenPoint(aimPart.Position)
        if screenPoint.Z < 0 then continue end
        
        local distance = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(screenPoint.X, screenPoint.Y)).Magnitude
        if distance < shortestDistance and IsTargetVisible(aimPart) then
            shortestDistance = distance
            target = player
        end
    end
    
    return target
end

-- Enhanced position prediction
local function PredictTargetPosition(target)
    if not target or not target.Character then return nil end
    
    local humanoid = target.Character:FindFirstChild("Humanoid")
    local aimPart = target.Character:FindFirstChild(
        humanoid and humanoid:GetState() == Enum.HumanoidStateType.Freefall 
        and Settings.AirAimPart 
        or Settings.AimPart
    )
    
    if not aimPart then return nil end
    
    local velocity = aimPart.Velocity
    local position = aimPart.Position
    local distance = (Camera.CFrame.Position - position).Magnitude
    
    -- Enhanced prediction logic
    if humanoid then
        local predictionAmount = Settings.PredictionAmount
        if humanoid.WalkSpeed > 30 then
            predictionAmount *= Settings.PredictionMultiplier
        end
        
        if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
            position += velocity * Settings.AirPredictionAmount
        else
            position += velocity * predictionAmount
        end
        
        -- Bullet drop compensation
        if Settings.DistanceAdjustment and Settings.BulletDropCompensation > 0 then
            position += Vector3.new(0, -distance * Settings.BulletDropCompensation, 0)
        end
    end
    
    return position
end

-- Visual feedback
local function CreateVisuals(character)
    if Settings.BoxEnabled then
        CurrentBox = Instance.new("BoxHandleAdornment")
        CurrentBox.Adornee = character
        CurrentBox.Color3 = Settings.BoxColor
        CurrentBox.Transparency = Settings.BoxTransparency
        CurrentBox.Size = character:GetExtentsSize()
        CurrentBox.AlwaysOnTop = true
        CurrentBox.ZIndex = 1
        CurrentBox.Parent = character
    end
    
    if Settings.VisibleHighlight then
        CurrentHighlight = Instance.new("Highlight")
        CurrentHighlight.FillColor = Settings.HighlightFillColor
        CurrentHighlight.OutlineColor = Settings.HighlightOutlineColor
        CurrentHighlight.Parent = character
    end
end

local function CleanupVisuals()
    if CurrentHighlight then CurrentHighlight:Destroy() end
    if CurrentBox then CurrentBox:Destroy() end
    CurrentHighlight = nil
    CurrentBox = nil
end

-- Input handling
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = true
        if Settings.AimbotEnabled then
            CurrentTarget = GetClosestPlayerToMouse()
            if CurrentTarget then
                StarterGui:SetCore("SendNotification", {
                    Title = "Target Locked",
                    Text = CurrentTarget.Name,
                    Duration = 2
                })
                CreateVisuals(CurrentTarget.Character)
            end
        end
    elseif input.KeyCode == Settings.ToggleAimbotKey then
        Settings.AimbotEnabled = not Settings.AimbotEnabled
        StarterGui:SetCore("SendNotification", {
            Title = "Aimbot",
            Text = Settings.AimbotEnabled and "Enabled" or "Disabled",
            Duration = 2
        })
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = false
        CurrentTarget = nil
        CleanupVisuals()
    end
end)

-- Main loop with performance optimization
RunService.RenderStepped:Connect(function()
    local currentTime = tick()
    if currentTime - LastUpdate < UpdateInterval then return end
    LastUpdate = currentTime
    
    UpdateFOVCircle()
    
    if Holding and Settings.AimbotEnabled and CurrentTarget then
        local predictedPosition = PredictTargetPosition(CurrentTarget)
        if predictedPosition then
            local targetCFrame = CFrame.new(Camera.CFrame.Position, predictedPosition)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 1 - Settings.Sensitivity)
        else
            CurrentTarget = nil
            CleanupVisuals()
        end
    end
end)
