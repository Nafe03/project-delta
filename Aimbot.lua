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

-- Global Settings
_G.AimbotEnabled = true
_G.TeamCheck = false
_G.AimPart = "Head"
_G.AirAimPart = "LowerTorso"
_G.Sensitivity = 0       -- Smoothness level (lower = faster)
_G.PredictionAmount = 0       -- Prediction for moving targets
_G.AirPredictionAmount = 0    -- Prediction for airborne targets
_G.BulletDropCompensation = 0
_G.DistanceAdjustment = true
_G.UseCircle = true
_G.WallCheck = true

_G.CircleSides = 64
_G.CircleColor = Color3.fromRGB(255, 255, 255)
_G.CircleTransparency = 0.7
_G.CircleRadius = 120
_G.CircleFilled = false
_G.CircleVisible = true
_G.CircleThickness = 1

_G.VisibleHighlight = true
_G.TargetLockKey = Enum.KeyCode.E
_G.ToggleAimbotKey = Enum.KeyCode.Q

-- FOV Circle Setup (initial setup)
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

-- Function to send notifications
local function Notify(title, text)
    StarterGui:SetCore("SendNotification", {
        Title = title;
        Text = text;
        Duration = 2;
    })
end

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

-- Function to get the closest player to the mouse
local function GetClosestPlayerToMouse()
    local Target = nil
    local ShortestDistance = _G.CircleRadius  -- Dynamic FOV circle radius

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

                    -- Only consider players within the current circle radius and closest to the mouse
                    if vectorDistance < ShortestDistance and vectorDistance <= _G.CircleRadius and IsTargetVisible(part) then
                        ShortestDistance = vectorDistance
                        Target = player
                    end
                end
            end
        end
    end

    return Target
end

-- Prediction Adjustment Function based on Target Speed and Estimated Latency
local function CalculatePredictionMultiplier(target)
    local AimPart = target.Character:FindFirstChild(_G.AimPart)
    if not AimPart then return 0 end

    local Velocity = AimPart.Velocity.Magnitude
    local estimatedLatency = 0.05  -- Approximated latency in seconds; adjust based on average ping

    -- Calculate prediction multiplier based on target speed and latency
    local predictionMultiplier = Velocity * estimatedLatency
    return predictionMultiplier
end

-- Prediction Function with Dynamic Multiplier for Fast Targets
local function PredictTargetPosition(Target)
    local AimPart = Target.Character:FindFirstChild(_G.AimPart)
    if not AimPart then return AimPart.Position end

    local humanoid = Target.Character:FindFirstChild("Humanoid")
    if not humanoid then return AimPart.Position end

    local Velocity = AimPart.Velocity
    local dynamicPrediction = CalculatePredictionMultiplier(Target)

    -- Adjust horizontal and vertical predictions based on target speed and latency
    local horizontalVelocity = Vector3.new(Velocity.X, 0, Velocity.Z) * dynamicPrediction
    local predictedPosition = AimPart.Position + horizontalVelocity

    -- Vertical prediction if target is airborne
    if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
        predictedPosition = predictedPosition + Vector3.new(0, Velocity.Y * _G.AirPredictionAmount, 0)
    end

    return predictedPosition
end

-- ResolveTargetPosition with bullet drop and prediction adjustments
local function ResolveTargetPosition(Target)
    local humanoid = Target.Character:FindFirstChild("Humanoid")
    local aimPartName = (humanoid and humanoid:GetState() == Enum.HumanoidStateType.Freefall) and _G.AirAimPart or _G.AimPart
    local AimPart = Target.Character:FindFirstChild(aimPartName)
    if not AimPart then return end

    local PredictedPosition = PredictTargetPosition(Target)
    local Distance = (Camera.CFrame.Position - PredictedPosition).Magnitude

    -- Adjust for bullet drop if enabled
    if _G.BulletDropCompensation > 0 and _G.DistanceAdjustment then
        PredictedPosition = PredictedPosition + Vector3.new(0, -Distance * _G.BulletDropCompensation, 0)
    end

    return PredictedPosition
end

-- Update and Track Target Lock Status
UserInputService.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = true
        if _G.AimbotEnabled then
            CurrentTarget = GetClosestPlayerToMouse()
            if CurrentTarget then
                Notify("Aimbot", "Locked onto " .. CurrentTarget.Name)
                if _G.VisibleHighlight then
                    CurrentHighlight = Instance.new("Highlight", CurrentTarget.Character)
                    CurrentHighlight.FillColor = Color3.new(1, 0, 0)
                    CurrentHighlight.OutlineColor = Color3.new(1, 1, 0)
                end
            end
        end
    elseif Input.KeyCode == _G.ToggleAimbotKey then
        _G.AimbotEnabled = not _G.AimbotEnabled
        Notify("Aimbot", "Aimbot " .. (_G.AimbotEnabled and "Enabled" or "Disabled"))
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

-- Update Aim Smoothness and Accuracy
RunService.RenderStepped:Connect(function()
    if _G.UseCircle then
        FOVCircle.Position = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
    else
        FOVCircle.Visible = false
    end

    if Holding and _G.AimbotEnabled and CurrentTarget then
        local character = CurrentTarget.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local ResolvedPosition = ResolveTargetPosition(CurrentTarget)
                if ResolvedPosition then
                    local newCFrame = CFrame.new(Camera.CFrame.Position, ResolvedPosition)
                    local tween = TweenService:Create(Camera, TweenInfo.new(_G.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = newCFrame})
                    tween:Play()
                end
            else
                CurrentTarget = nil
            end
        else
            CurrentTarget = nil
        end
    end
end)
