-- Services
local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- Local Player
local LocalPlayer = Players.LocalPlayer
local Holding = false

-- Global Settings
_G.AimbotEnabled = true
_G.TeamCheck = false
_G.AimPart = "Head"           -- Primary aim part for grounded targets
_G.AirAimPart = "Torso"        -- Aim part for airborne targets
_G.Sensitivity = 0.1           -- Aim smoothing, lower is more smooth
_G.PredictionAmount = 0.2      -- Base prediction amount for horizontal movements
_G.AirPredictionAmount = 0.2   -- Prediction for air movement
_G.BulletDropCompensation = 0.03  -- Bullet drop offset based on distance
_G.DistanceAdjustment = true   -- Adjust prediction based on distance
_G.UseCircle = true
_G.WallCheck = true
_G.ResolverEnabled = true      -- Toggle resolver for handling anti-aim techniques

_G.CircleSides = 64
_G.CircleColor = Color3.fromRGB(255, 255, 255)
_G.CircleTransparency = 0.7
_G.CircleRadius = 120
_G.CircleFilled = false
_G.CircleVisible = true
_G.CircleThickness = 1

_G.VisibleCheek = true

-- Enhanced Resolver Configurations
local PositionHistory = {}      -- Stores recent positions for jitter detection
local LastPredictedPosition = nil
local LastAimPartPosition = Vector3.zero

-- Function to Draw FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
FOVCircle.Radius = _G.CircleRadius
FOVCircle.Filled = _G.CircleFilled
FOVCircle.Color = _G.CircleColor
FOVCircle.Visible = _G.CircleVisible
FOVCircle.Transparency = _G.CircleTransparency
FOVCircle.NumSides = _G.CircleSides
FOVCircle.Thickness = _G.CircleThickness

-- Function to check if the target is visible (Wall Check)
local function IsTargetVisible(targetPart)
    if _G.WallCheck then
        local origin = Camera.CFrame.Position
        local direction = (targetPart.Position - origin).Unit * (targetPart.Position - origin).Magnitude
        local raycastParams = RaycastParams.new()
        
        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

        local raycastResult = Workspace:Raycast(origin, direction, raycastParams)
        
        if raycastResult and raycastResult.Instance ~= targetPart then
            return false
        end
    end
    return true
end

-- Function to Get the Closest Player to the Mouse Cursor
local function GetClosestPlayerToMouse()
    local Target = nil
    local ShortestDistance = _G.CircleRadius

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if _G.TeamCheck and player.Team == LocalPlayer.Team then
                continue
            end

            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local part = player.Character:FindFirstChild(_G.AimPart)
                if part then
                    local screenPoint = Camera:WorldToScreenPoint(part.Position)
                    local mousePos = UserInputService:GetMouseLocation()
                    local vectorDistance = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(screenPoint.X, screenPoint.Y)).Magnitude

                    -- Wall Check: Only consider target if visible (not behind walls)
                    if vectorDistance < ShortestDistance and IsTargetVisible(part) then
                        ShortestDistance = vectorDistance
                        Target = player
                    end
                end
            end
        end
    end

    return Target
end

-- Advanced Resolver Function to handle Anti-Aim
local function PredictTargetPosition(Target)
    local AimPart = Target.Character:FindFirstChild(_G.AimPart)
    if not AimPart then return AimPart.Position end

    local Velocity = AimPart.Velocity
    local horizontalVelocity = Vector3.new(Velocity.X, 0, Velocity.Z) * _G.PredictionAmount
    local predictedPosition = AimPart.Position + horizontalVelocity

    -- Apply air prediction if the target is in the air
    local humanoid = Target.Character:FindFirstChild("Humanoid")
    if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Freefall then
        predictedPosition = predictedPosition + Vector3.new(0, Velocity.Y * _G.AirPredictionAmount, 0)
    end

    -- Distance Adjustment
    if _G.DistanceAdjustment then
        local distanceFactor = (Camera.CFrame.Position - AimPart.Position).Magnitude * 0.01
        predictedPosition = predictedPosition + (horizontalVelocity * distanceFactor)
    end

    return predictedPosition
end

local function ResolveTargetPosition(Target)
    -- Determine whether to use ground or air aim part based on target state
    local humanoid = Target.Character:FindFirstChild("Humanoid")
    local aimPartName = (humanoid and humanoid:GetState() == Enum.HumanoidStateType.Freefall) and _G.AirAimPart or _G.AimPart
    local AimPart = Target.Character:FindFirstChild(aimPartName)
    if not AimPart then return end

    -- Add position to history for jitter analysis
    table.insert(PositionHistory, AimPart.Position)
    if #PositionHistory > 5 then table.remove(PositionHistory, 1) end

    -- Jitter Detection
    local jitterOffset = Vector3.zero
    if #PositionHistory >= 2 then
        for i = 1, #PositionHistory - 1 do
            jitterOffset = jitterOffset + (PositionHistory[i] - PositionHistory[i + 1])
        end
        jitterOffset = jitterOffset / #PositionHistory
    end

    -- Predict Position using basic and jitter-based adjustments
    local PredictedPosition = PredictTargetPosition(Target)
    local correctedPosition = PredictedPosition + jitterOffset * 0.5

    -- Bullet Drop Compensation
    local Distance = (Camera.CFrame.Position - correctedPosition).Magnitude
    if _G.BulletDropCompensation > 0 then
        correctedPosition = correctedPosition + Vector3.new(0, -Distance * _G.BulletDropCompensation, 0)
    end

    -- Offset and return the resolved position
    local CorrectionOffset = Vector3.new(0, 0.5, 0)
    local ResolvedPosition = correctedPosition + CorrectionOffset
    return ResolvedPosition
end

-- Input Handlers
UserInputService.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = true
        if _G.AimbotEnabled then
            CurrentTarget = GetClosestPlayerToMouse()
            if CurrentTarget then
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "Aimbot",
                    Text = "Locked onto " .. CurrentTarget.Name,
                    Duration = 2
                })
                if _G.VisibleCheek then
                    CurrentHighlight = Instance.new("Highlight", CurrentTarget.Character)
                    CurrentHighlight.FillColor = Color3.new(1, 0, 0)
                    CurrentHighlight.OutlineColor = Color3.new(1, 1, 0)
                end
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = false
        CurrentTarget = nil
        if CurrentHighlight then
            CurrentHighlight:Destroy()
            CurrentHighlight = nil
        end
    end
end)

-- RenderStepped Loop for Aimbot and FOV Circle
RunService.RenderStepped:Connect(function()
    if _G.UseCircle then
        FOVCircle.Position = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
        FOVCircle.Radius = _G.CircleRadius
        FOVCircle.Filled = _G.CircleFilled
        FOVCircle.Color = _G.CircleColor
        FOVCircle.Visible = _G.CircleVisible
        FOVCircle.Transparency = _G.CircleTransparency
        FOVCircle.NumSides = _G.CircleSides
        FOVCircle.Thickness = _G.CircleThickness
    else
        FOVCircle.Visible = false
    end

    if Holding and _G.AimbotEnabled and CurrentTarget then
        local character = CurrentTarget.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local ResolvedPosition = ResolveTargetPosition(CurrentTarget)
                local FinalPosition = ResolvedPosition
                local newCFrame = CFrame.new(Camera.CFrame.Position, FinalPosition)
                local tween = TweenService:Create(Camera, TweenInfo.new(_G.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = newCFrame})
                tween:Play()
            else
                CurrentTarget = nil
            end
        else
            CurrentTarget = nil
        end
    end
end)
