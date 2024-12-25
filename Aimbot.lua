-- Services
local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

-- Local Player
local LocalPlayer = Players.LocalPlayer
local Holding = false

-- Enhanced Global Settings
_G.AimbotEnabled = true
_G.TeamCheck = false
_G.AimPart = "Head"
_G.AirAimPart = "HumanoidRootPart"
_G.Sensitivity = 0       -- Adjusted for smoother aim
_G.PredictionAmount = 0  -- Enhanced prediction
_G.AirPredictionAmount = 0 -- Better air prediction
_G.StickyAimEnabled = true   -- New sticky aim feature
_G.StickyAimStrength = 1   -- How "sticky" the aim is (0-1)
_G.StickyAimRange = 15000      -- Range for sticky aim to activate
_G.AutoPrediction = true     -- Automatically adjusts prediction based on ping
_G.SmartPrediction = true    -- Adjusts prediction based on target movement
_G.AdaptiveRadius = true     -- FOV circle adjusts based on distance
_G.WallCheck = true
_G.AutoAimPart = true       -- Automatically switches aim part based on situation
_G.HeadshotChance = 0     -- Chance to target head vs body

-- Visual Settings
_G.CircleSides = 64
_G.CircleColor = Color3.fromRGB(255, 255, 255)
_G.CircleTransparency = 0.7
_G.CircleRadius = 120
_G.MinCircleRadius = 60    -- Minimum FOV radius
_G.MaxCircleRadius = 180   -- Maximum FOV radius
_G.CircleFilled = false
_G.CircleVisible = true
_G.CircleThickness = 1

_G.BoxEnabled = true
_G.BoxColor = Color3.fromRGB(255, 0, 0)
_G.BoxTransparency = 0.5
_G.BoxThickness = 0.05

-- Advanced Settings
local LastTargetPos = nil
local LastPingTime = 0
local PingWindow = {}
local TargetVelocityHistory = {}
local MaxVelocityHistory = 10
local SmoothingWindow = {}
local MaxSmoothingPoints = 5

-- FOV Circle Setup
local FOVCircle = Drawing.new("Circle")
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
FOVCircle.Radius = _G.CircleRadius
FOVCircle.Filled = _G.CircleFilled
FOVCircle.Color = _G.CircleColor
FOVCircle.Visible = _G.CircleVisible
FOVCircle.Transparency = _G.CircleTransparency
FOVCircle.NumSides = _G.CircleSides
FOVCircle.Thickness = _G.CircleThickness

-- Current Target Variables
local CurrentTarget = nil
local CurrentHighlight = nil
local CurrentBox = nil
local LastTargetCheckTime = 0
local TargetLockStrength = 0

-- Enhanced Notification System
local function Notify(title, text, duration)
    StarterGui:SetCore("SendNotification", {
        Title = title;
        Text = text;
        Duration = duration or 2;
    })
end

-- Advanced Target Visibility Check
local function IsTargetVisible(targetPart)
    if not _G.WallCheck then return true end
    
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local distance = direction.Magnitude
    direction = direction.Unit
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, targetPart.Parent}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    local raycastResult = Workspace:Raycast(origin, direction * distance, raycastParams)
    return raycastResult == nil
end

-- Smart Aim Part Selection
local function GetBestAimPart(target)
    if not _G.AutoAimPart then return target.Character:FindFirstChild(_G.AimPart) end
    
    local humanoid = target.Character:FindFirstChild("Humanoid")
    if not humanoid then return target.Character:FindFirstChild(_G.AimPart) end
    
    -- Check if target is in air
    if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
        return target.Character:FindFirstChild(_G.AirAimPart)
    end
    
    -- Random chance for headshot based on HeadshotChance
    if math.random() < _G.HeadshotChance then
        local head = target.Character:FindFirstChild("Head")
        if head and IsTargetVisible(head) then
            return head
        end
    end
    
    -- Default to upper torso or humanoid root part if other parts aren't suitable
    return target.Character:FindFirstChild("UpperTorso") or 
           target.Character:FindFirstChild("HumanoidRootPart")
end

-- Enhanced Prediction System
local function CalculatePrediction(target, aimPart)
    if not target or not aimPart then return Vector3.new() end
    
    local velocity = aimPart.Velocity
    local distance = (aimPart.Position - Camera.CFrame.Position).Magnitude
    local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
    
    -- Record velocity history
    table.insert(TargetVelocityHistory, velocity)
    if #TargetVelocityHistory > MaxVelocityHistory then
        table.remove(TargetVelocityHistory, 1)
    end
    
    -- Calculate average velocity
    local avgVelocity = Vector3.new()
    for _, v in ipairs(TargetVelocityHistory) do
        avgVelocity = avgVelocity + v
    end
    avgVelocity = avgVelocity / #TargetVelocityHistory
    
    -- Adaptive prediction based on ping and distance
    local predictionMultiplier = _G.PredictionAmount
    if _G.AutoPrediction then
        predictionMultiplier = predictionMultiplier * (ping / 1000) * (distance / 100)
    end
    
    -- Calculate final prediction
    local prediction = avgVelocity * predictionMultiplier
    
    -- Apply additional vertical prediction if target is in air
    local humanoid = target.Character:FindFirstChild("Humanoid")
    if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Freefall then
        prediction = prediction + Vector3.new(0, _G.AirPredictionAmount * velocity.Y, 0)
    end
    
    return prediction
end

-- Improved Target Selection
local function GetClosestPlayerToMouse()
    local Target = nil
    local ShortestDistance = math.huge
    local MousePosition = UserInputService:GetMouseLocation()
    
    -- Only check for new target every 0.1 seconds to improve performance
    local currentTime = tick()
    if currentTime - LastTargetCheckTime < 0.1 and CurrentTarget then
        return CurrentTarget
    end
    LastTargetCheckTime = currentTime
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if _G.TeamCheck and player.Team == LocalPlayer.Team then continue end
        
        local character = player.Character
        if not character then continue end
        
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end
        
        local aimPart = GetBestAimPart(player)
        if not aimPart then continue end
        
        local screenPoint = Camera:WorldToScreenPoint(aimPart.Position)
        if screenPoint.Z < 0 then continue end
        
        local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - MousePosition).Magnitude
        
        -- Apply sticky aim if enabled
        if _G.StickyAimEnabled and CurrentTarget == player then
            distance = distance * (1 - _G.StickyAimStrength)
        end
        
        -- Check if within FOV
        if distance <= _G.CircleRadius and distance < ShortestDistance then
            if IsTargetVisible(aimPart) then
                ShortestDistance = distance
                Target = player
            end
        end
    end
    
    return Target
end

-- Smooth Aim Function
local function SmoothAim(targetCFrame)
    local smoothness = _G.Sensitivity
    
    -- Add current aim point to smoothing window
    table.insert(SmoothingWindow, targetCFrame)
    if #SmoothingWindow > MaxSmoothingPoints then
        table.remove(SmoothingWindow, 1)
    end
    
    -- Calculate smooth aim position
    local smoothCFrame = targetCFrame
    if #SmoothingWindow > 1 then
        local avgCFrame = CFrame.new()
        for _, cf in ipairs(SmoothingWindow) do
            avgCFrame = avgCFrame:Lerp(cf, 1/#SmoothingWindow)
        end
        smoothCFrame = Camera.CFrame:Lerp(avgCFrame, smoothness)
    end
    
    return smoothCFrame
end

-- Enhanced Box ESP
local function UpdateBoxESP(target)
    if not _G.BoxEnabled then return end
    
    if CurrentBox then
        CurrentBox:Destroy()
    end
    
    CurrentBox = Instance.new("BoxHandleAdornment")
    CurrentBox.Adornee = target.Character
    CurrentBox.Color3 = _G.BoxColor
    CurrentBox.Transparency = _G.BoxTransparency
    CurrentBox.Size = target.Character:GetExtentsSize()
    CurrentBox.AlwaysOnTop = true
    CurrentBox.ZIndex = 1
    CurrentBox.Parent = target.Character
end

-- Input Handling
UserInputService.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = true
        if _G.AimbotEnabled then
            CurrentTarget = GetClosestPlayerToMouse()
            if CurrentTarget then
                Notify("Target Acquired", CurrentTarget.Name, 1)
                if _G.BoxEnabled then
                    UpdateBoxESP(CurrentTarget)
                end
            end
        end
    elseif Input.KeyCode == _G.ToggleAimbotKey then
        _G.AimbotEnabled = not _G.AimbotEnabled
        Notify("Aimbot", _G.AimbotEnabled and "Enabled" or "Disabled", 1)
    end
end)

UserInputService.InputEnded:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = false
        CurrentTarget = nil
        if CurrentBox then
            CurrentBox:Destroy()
            CurrentBox = nil
        end
    end
end)

-- Main Loop
RunService.RenderStepped:Connect(function()
    -- Update FOV Circle
    if _G.UseCircle then
        FOVCircle.Position = UserInputService:GetMouseLocation()
        
        -- Adaptive FOV radius
        if _G.AdaptiveRadius and CurrentTarget then
            local distance = (Camera.CFrame.Position - CurrentTarget.Character.HumanoidRootPart.Position).Magnitude
            local adaptiveRadius = math.clamp(
                _G.CircleRadius * (100 / distance),
                _G.MinCircleRadius,
                _G.MaxCircleRadius
            )
            FOVCircle.Radius = adaptiveRadius
        else
            FOVCircle.Radius = _G.CircleRadius
        end
        
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end
    
    -- Aimbot Logic
    if Holding and _G.AimbotEnabled then
        CurrentTarget = CurrentTarget or GetClosestPlayerToMouse()
        
        if CurrentTarget then
            local character = CurrentTarget.Character
            if character then
                local aimPart = GetBestAimPart(CurrentTarget)
                if aimPart then
                    local predictedPosition = aimPart.Position + CalculatePrediction(CurrentTarget, aimPart)
                    local targetCFrame = CFrame.new(Camera.CFrame.Position, predictedPosition)
                    
                    -- Apply smooth aim
                    Camera.CFrame = SmoothAim(targetCFrame)
                    
                    -- Update ESP
                    if _G.BoxEnabled then
                        UpdateBoxESP(CurrentTarget)
                    end
                end
            end
        end
    end
end)

-- Initialize
Notify("Aimbot Loaded", "Press Q to toggle", 3)
