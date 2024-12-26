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
_G.AimbotEnabled = false
_G.TeamCheck = false
_G.AimPart = "Head"
_G.AirAimPart = "LowerTorso"
_G.Sensitivity = 0       -- Smoothness level (lower = faster)
_G.PredictionAmount = 0       -- Horizontal prediction for moving targets
_G.AirPredictionAmount = 0    -- Vertical prediction for airborne targets
_G.BulletDropCompensation = 0
_G.DistanceAdjustment = false
_G.UseCircle = true
_G.WallCheck = false
_G.PredictionMultiplier = 1.5 -- Multiplier for prediction on fast targets
_G.FastTargetSpeedThreshold = 35  -- Speed threshold to identify macros or rapid movements
_G.DynamicSensitivity = true  -- Enable dynamic sensitivity adjustment based on target movement speed

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

-- Function to send notifications
local function Notify(title, text)
    StarterGui:SetCore("SendNotification", {
        Title = title;
        Text = text;
        Duration = 2;
    })
end

-- Function to check if a player is knocked
local function IsPlayerKnocked(player)
    local character = player.Character
    if not character then return true end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return true end
    
    -- Check if player is knocked in Da Hood
    local knocked = character:FindFirstChild("BodyEffects")
    if knocked and knocked:FindFirstChild("K.O") then
        return knocked["K.O"].Value
    end
    
    return false
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

-- Prediction Logic
local function PredictTargetPosition(Target)
    local AimPart = Target.Character:FindFirstChild(_G.AimPart)
    if not AimPart then return end

    local Velocity = AimPart.Velocity
    local predictedPosition = AimPart.Position
    local speed = Velocity.Magnitude

    local isFastMoving = speed >= _G.FastTargetSpeedThreshold
    local predictionFactor = _G.PredictionMultiplier * (isFastMoving and 1.5 or 1)

    local humanoid = Target.Character:FindFirstChild("Humanoid")
    if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall and humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
        predictedPosition = predictedPosition + Vector3.new(Velocity.X, 0, Velocity.Z) * _G.PredictionAmount * predictionFactor
    end

    if humanoid and (humanoid:GetState() == Enum.HumanoidStateType.Freefall or humanoid:GetState() == Enum.HumanoidStateType.Jumping) then
        predictedPosition = predictedPosition + Vector3.new(0, Velocity.Y * _G.AirPredictionAmount * predictionFactor, 0)
    end

    return predictedPosition
end

local function ResolveTargetPosition(Target)
    local humanoid = Target.Character:FindFirstChild("Humanoid")
    local aimPartName = (humanoid and humanoid:GetState() == Enum.HumanoidStateType.Freefall) and _G.AirAimPart or _G.AimPart
    local AimPart = Target.Character:FindFirstChild(aimPartName)
    if not AimPart then return end

    local PredictedPosition = PredictTargetPosition(Target)
    local Distance = (Camera.CFrame.Position - PredictedPosition).Magnitude

    if _G.BulletDropCompensation > 0 and _G.DistanceAdjustment then
        PredictedPosition = PredictedPosition + Vector3.new(0, -Distance * _G.BulletDropCompensation, 0)
    end

    return PredictedPosition
end

-- Input Handling
UserInputService.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = true
        if _G.AimbotEnabled then
            CurrentTarget = GetClosestPlayerToMouse()
            if CurrentTarget then
                Notify("Aimbot", "Locked onto " .. CurrentTarget.Name)
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
    end
end)

-- Update FOV Circle and Aimbot Behavior
RunService.RenderStepped:Connect(function()
    if _G.UseCircle then
        FOVCircle.Position = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
        FOVCircle.Radius = _G.CircleRadius
    else
        FOVCircle.Visible = false
    end

    if Holding and _G.AimbotEnabled and CurrentTarget then
        local character = CurrentTarget.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local aimPosition = ResolveTargetPosition(CurrentTarget)
            if aimPosition then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, aimPosition)
            end
        end
    end
end)
