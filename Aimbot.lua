-- Services
local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Local Player
local LocalPlayer = Players.LocalPlayer
local Holding = false

-- Global Settings
_G.AimbotEnabled = false
_G.TeamCheck = false -- If true, only lock onto enemy team members.
_G.AimPart = "Head" -- Part to lock onto: "Head", "HumanoidRootPart", etc.
_G.Sensitivity = nil -- Tween duration for camera movement.
_G.PredictionAmount = 0 -- Time to predict into the future based on target's velocity.

_G.CircleSides = 64 -- Number of sides for the FOV circle.
_G.CircleColor = Color3.fromRGB(255, 255, 255) -- FOV circle color.
_G.CircleTransparency = 0.7 -- FOV circle transparency.
_G.CircleRadius = 80 -- FOV circle radius.
_G.CircleFilled = false -- Whether the FOV circle is filled.
_G.CircleVisible = true -- Whether the FOV circle is visible.
_G.CircleThickness = 0 -- FOV circle thickness.

-- Drawing FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
FOVCircle.Radius = _G.CircleRadius
FOVCircle.Filled = _G.CircleFilled
FOVCircle.Color = _G.CircleColor
FOVCircle.Visible = _G.CircleVisible
FOVCircle.Transparency = _G.CircleTransparency
FOVCircle.NumSides = _G.CircleSides
FOVCircle.Thickness = _G.CircleThickness

-- Current Target Variable
local CurrentTarget = nil

-- Function to Get the Closest Player within FOV
local function GetClosestPlayer()
    local MaximumDistance = _G.CircleRadius
    local Target = nil
    local ShortestDistance = MaximumDistance

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if _G.TeamCheck then
                if player.Team == LocalPlayer.Team then
                    continue -- Skip teammates if TeamCheck is enabled
                end
            end

            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local part = player.Character:FindFirstChild(_G.AimPart)
                if part then
                    local screenPoint = Camera:WorldToScreenPoint(part.Position)
                    local mousePos = UserInputService:GetMouseLocation()
                    local vectorDistance = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(screenPoint.X, screenPoint.Y)).Magnitude

                    if vectorDistance < ShortestDistance then
                        ShortestDistance = vectorDistance
                        Target = player
                    end
                end
            end
        end
    end

    return Target
end

-- Prediction Function to Account for Target's Movement
local function PredictTargetPosition(Target)
    local AimPart = Target.Character:FindFirstChild(_G.AimPart)
    if not AimPart then return AimPart.Position end

    local Velocity = AimPart.Velocity
    local Prediction = AimPart.Position + (Velocity * _G.PredictionAmount)
    return Prediction
end

-- Input Handlers
UserInputService.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = true
        if _G.AimbotEnabled then
            CurrentTarget = GetClosestPlayer()
            if CurrentTarget then
                -- Notify about the target locked
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "Aimbot",
                    Text = "Locked onto " .. CurrentTarget.Name,
                    Duration = 2
                })
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = false
        CurrentTarget = nil -- Clear the target when holding ends
    end
end)

-- RenderStepped Loop for Aimbot and FOV Circle
RunService.RenderStepped:Connect(function()
    -- Update FOV Circle Properties
    FOVCircle.Position = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
    FOVCircle.Radius = _G.CircleRadius
    FOVCircle.Filled = _G.CircleFilled
    FOVCircle.Color = _G.CircleColor
    FOVCircle.Visible = _G.CircleVisible
    FOVCircle.Transparency = _G.CircleTransparency
    FOVCircle.NumSides = _G.CircleSides
    FOVCircle.Thickness = _G.CircleThickness

    -- Aimbot Logic
    if Holding and _G.AimbotEnabled and CurrentTarget then
        local character = CurrentTarget.Character
        if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild(_G.AimPart) then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                -- Predict Target Position
                local PredictedPosition = PredictTargetPosition(CurrentTarget)
                local AimPart = character[_G.AimPart]

                -- Final Position Calculation
                local FinalPosition = PredictedPosition

                -- Tween Camera to Aim at Final Position
                local newCFrame = CFrame.new(Camera.CFrame.Position, FinalPosition)
                local tween = TweenService:Create(Camera, TweenInfo.new(_G.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = newCFrame})
                tween:Play()
            else
                CurrentTarget = nil -- Clear target if humanoid is dead
            end
        else
            CurrentTarget = nil -- Clear target if parts are missing
        end
    end
end)

-- Optional: Update FOV Circle on Screen Resize
RunService.RenderStepped:Connect(function()
    FOVCircle.Position = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
end)
