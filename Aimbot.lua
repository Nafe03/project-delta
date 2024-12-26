-- Fixed Aimbot Script
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

-- Global Settings (Optimized for Da Hood)
_G.AimbotEnabled = true
_G.TeamCheck = false
_G.AimPart = "Head"  -- Head for Da Hood is most effective
_G.LockPart = "HumanoidRootPart"  -- For better prediction
_G.Sensitivity = 0  -- Smoothed for Da Hood's movement
_G.PredictionAmount = 0  -- Tuned for Da Hood's netcode
_G.JumpOffset = 0  -- Compensation for jumping
_G.MaxLockRange = 350  -- Maximum lock range
_G.UnlockOnDeath = true

-- FOV Settings
_G.UseCircle = true
_G.CircleRadius = 100
_G.CircleColor = Color3.fromRGB(255, 0, 0)
_G.CircleTransparency = 0.5
_G.CircleFilled = false
_G.CircleVisible = true
_G.CircleThickness = 1
_G.CircleSides = 64

-- Variables
local CurrentTarget = nil
local FOVCircle = Drawing.new("Circle")
local MovementPattern = {}

-- Setup FOV Circle
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
FOVCircle.Radius = _G.CircleRadius
FOVCircle.Color = _G.CircleColor
FOVCircle.Transparency = _G.CircleTransparency
FOVCircle.Filled = _G.CircleFilled
FOVCircle.Visible = _G.CircleVisible
FOVCircle.Thickness = _G.CircleThickness
FOVCircle.NumSides = _G.CircleSides

-- Prediction Function
local function CalculatePrediction(target)
    if not target or not target.Character then return nil end

    local rootPart = target.Character:FindFirstChild(_G.LockPart)
    if not rootPart then return nil end

    local position = rootPart.Position
    local velocity = rootPart.Velocity
    local prediction = position + (velocity * _G.PredictionAmount)

    -- Jump compensation
    if target.Character:FindFirstChild("Humanoid") then
        local humanoid = target.Character.Humanoid
        if humanoid:GetState() == Enum.HumanoidStateType.Jumping or 
           humanoid:GetState() == Enum.HumanoidStateType.Freefall then
            prediction = prediction + Vector3.new(0, _G.JumpOffset, 0)
        end
    end

    return prediction
end

-- Target Selection Function
local function GetClosestTarget()
    local closest = nil
    local shortestDistance = _G.MaxLockRange
    local mousePosition = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if _G.TeamCheck and player.Team == LocalPlayer.Team then continue end

        local character = player.Character
        if not character or not character:FindFirstChild(_G.AimPart) then continue end

        local aimPart = character[_G.AimPart]
        local screenPoint = Camera:WorldToScreenPoint(aimPart.Position)
        if screenPoint.Z < 0 then continue end

        local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePosition).Magnitude
        if distance > _G.CircleRadius then continue end

        if distance < shortestDistance then
            shortestDistance = distance
            closest = player
        end
    end

    return closest
end

-- Aimbot Logic
RunService.RenderStepped:Connect(function()
    -- Update FOV Circle
    if _G.UseCircle then
        FOVCircle.Position = UserInputService:GetMouseLocation()
        FOVCircle.Visible = true
    end

    -- Aimbot Logic
    if Holding and _G.AimbotEnabled then
        CurrentTarget = CurrentTarget or GetClosestTarget()

        if CurrentTarget and CurrentTarget.Character then
            local aimPart = CurrentTarget.Character:FindFirstChild(_G.AimPart)
            if aimPart then
                local predictionPoint = CalculatePrediction(CurrentTarget)
                if predictionPoint then
                    local targetCFrame = CFrame.new(Camera.CFrame.Position, predictionPoint)

                    -- Apply stickiness and smoothing
                    Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, _G.Sensitivity)
                end
            end
        else
            CurrentTarget = nil
        end
    else
        CurrentTarget = nil
    end
end)

-- Input Handling
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = false
        CurrentTarget = nil
    end
end)
