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
_G.Sensitivity == 0  -- Tweening speed for smoother aiming
_G.PredictionAmount = 0.05  -- Small value for predictive aiming
_G.UseCircle = true

_G.CircleSides = 64
_G.CircleColor = Color3.fromRGB(255, 255, 255)
_G.CircleTransparency = 0.7
_G.CircleRadius = 80
_G.CircleFilled = false
_G.CircleVisible = true
_G.CircleThickness = 1

_G.VisibleCheek = false  -- Toggle for visual cue

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

-- Current Target Variables
local CurrentTarget = nil
local CurrentHighlight = nil

-- Function to Get the Closest Player within FOV
local function GetClosestPlayer()
    local maximumDistance = _G.CircleRadius
    local target, shortestDistance = nil, maximumDistance

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
                    local distance = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(screenPoint.X, screenPoint.Y)).Magnitude

                    if distance < shortestDistance then
                        shortestDistance = distance
                        target = player
                    end
                end
            end
        end
    end

    return target
end

-- Prediction Function to Account for Target's Movement
local function PredictTargetPosition(target)
    local aimPart = target.Character:FindFirstChild(_G.AimPart)
    if not aimPart then return aimPart.Position end

    local velocity = aimPart.Velocity
    return aimPart.Position + (velocity * _G.PredictionAmount)
end

-- Input Handlers
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
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

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = false
        CurrentTarget = nil  -- Clear the target when holding ends

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
        FOVCircle.Position = UserInputService:GetMouseLocation()
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
                -- Predict Target Position
                local predictedPosition = PredictTargetPosition(CurrentTarget)
                
                -- Final Position Calculation
                local finalPosition = predictedPosition

                -- Tween Camera to Aim at Final Position
                local newCFrame = CFrame.new(Camera.CFrame.Position, finalPosition)
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
        FOVCircle.Position = UserInputService:GetMouseLocation()
    end
end)
