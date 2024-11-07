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
_G.TeamCheck = false
_G.AimPart = "Head"
_G.Sensitivity = 0
_G.PredictionAmount = 0
_G.UseCircle = true

_G.CircleSides = 64
_G.CircleColor = Color3.fromRGB(255, 255, 255)
_G.CircleTransparency = 0.7
_G.CircleRadius = 80
_G.CircleFilled = false
_G.CircleVisible = true
_G.CircleThickness = 0

_G.VisibleCheek = false -- Toggle for visual cue

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
local CurrentHighlight = nil

-- Function to Get the Closest Player within FOV
local function GetClosestPlayer()
    local MaximumDistance = _G.CircleRadius
    local Target = nil
    local ShortestDistance = MaximumDistance

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if _G.TeamCheck then
                if player.Team == LocalPlayer.Team then
                    continue
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

-- Resolver Function to Correct the Predicted Position
local function ResolveTargetPosition(Target)
    -- Implement a simple correction logic here
    -- For instance, adding a small offset to the predicted position
    local PredictedPosition = PredictTargetPosition(Target)
    local CorrectionOffset = Vector3.new(0, 0.5, 0) -- Adjust this value as needed
    local ResolvedPosition = PredictedPosition + CorrectionOffset
    return ResolvedPosition
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
                -- Add a highlight to the current target if visible
                if _G.VisibleCheek then
                    CurrentHighlight = Instance.new("Highlight", CurrentTarget.Character)
                    CurrentHighlight.FillColor = Color3.new(1, 0, 0) -- Red color for highlight
                    CurrentHighlight.OutlineColor = Color3.new(1, 1, 0) -- Yellow outline
                end
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = false
        CurrentTarget = nil -- Clear the target when holding ends
        -- Remove highlight if it exists
        if CurrentHighlight then
            CurrentHighlight:Destroy()
            CurrentHighlight = nil
        end
    end
end)

-- RenderStepped Loop for Aimbot and FOV Circle
RunService.RenderStepped:Connect(function()
    -- Update FOV Circle Properties if UseCircle is true
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

    -- Aimbot Logic
    if Holding and _G.AimbotEnabled and CurrentTarget then
        local character = CurrentTarget.Character
        if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild(_G.AimPart) then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                -- Resolve Target Position
                local ResolvedPosition = ResolveTargetPosition(CurrentTarget)
                local AimPart = character[_G.AimPart]

                -- Final Position Calculation
                local FinalPosition = ResolvedPosition

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
    if _G.UseCircle then
        FOVCircle.Position = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
    end
end)
