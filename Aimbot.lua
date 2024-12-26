-- Services
local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
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
_G.PredictionAmount = 0  -- Adjust prediction scaling
_G.AirPredictionAmount = 0
_G.Sensitivity = 0          -- Lower = faster snapping
_G.BulletDropCompensation = 0
_G.DistanceAdjustment = true
_G.CircleRadius = 150       -- FOV Circle radius
_G.CircleColor = Color3.new(1, 1, 1)
_G.CircleThickness = 1
_G.CircleTransparency = 0.7
_G.CircleSides = 64
_G.CircleFilled = false
_G.WallCheck = true

-- FOV Circle
local FOVCircle = Drawing.new("Circle")
local function UpdateFOVCircle()
    FOVCircle.Position = UserInputService:GetMouseLocation()
    FOVCircle.Radius = _G.CircleRadius
    FOVCircle.Color = _G.CircleColor
    FOVCircle.Thickness = _G.CircleThickness
    FOVCircle.Transparency = _G.CircleTransparency
    FOVCircle.NumSides = _G.CircleSides
    FOVCircle.Filled = _G.CircleFilled
    FOVCircle.Visible = _G.AimbotEnabled
end
UpdateFOVCircle()

-- Function to notify the user
local function Notify(title, text)
    StarterGui:SetCore("SendNotification", { Title = title; Text = text; Duration = 2 })
end

-- Function to check visibility
local function IsVisible(targetPart)
    if not _G.WallCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local result = Workspace:Raycast(origin, direction * (targetPart.Position - origin).Magnitude, raycastParams)
    return not result or result.Instance == targetPart
end

-- Function to get closest player within FOV
local function GetClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = _G.CircleRadius

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if _G.TeamCheck and player.Team == LocalPlayer.Team then continue end
            local character = player.Character
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local aimPart = character:FindFirstChild(_G.AimPart)
                if aimPart and IsVisible(aimPart) then
                    local screenPos, onScreen = Camera:WorldToScreenPoint(aimPart.Position)
                    if onScreen then
                        local mousePos = UserInputService:GetMouseLocation()
                        local distance = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                        if distance < shortestDistance then
                            closestPlayer = player
                            shortestDistance = distance
                        end
                    end
                end
            end
        end
    end
    return closestPlayer
end

-- Function to calculate prediction
local function PredictTargetPosition(target)
    local aimPart = target.Character:FindFirstChild(_G.AimPart)
    if not aimPart then return end

    local velocity = aimPart.Velocity
    local speed = velocity.Magnitude
    local predictionFactor = _G.PredictionMultiplier * (speed >= _G.FastTargetSpeedThreshold and 1.5 or 1)

    local prediction = Vector3.new(velocity.X, 0, velocity.Z) * _G.PredictionAmount * predictionFactor

    if target.Character:FindFirstChild("Humanoid").FloorMaterial == Enum.Material.Air then
        prediction = prediction + Vector3.new(0, velocity.Y * _G.AirPredictionAmount * predictionFactor, 0)
    end

    return aimPart.Position + prediction
end


-- Input handlers
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = true
    elseif input.KeyCode == Enum.KeyCode.Q then
        _G.AimbotEnabled = not _G.AimbotEnabled
        Notify("Aimbot", "Aimbot " .. (_G.AimbotEnabled and "Enabled" or "Disabled"))
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = false
    end
end)

-- Main loop
RunService.RenderStepped:Connect(function()
    UpdateFOVCircle()

    if Holding and _G.AimbotEnabled then
        local target = GetClosestPlayer()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local predictedPosition = PredictTargetPosition(target)
            if predictedPosition then
                local cameraPosition = Camera.CFrame.Position
                local direction = (predictedPosition - cameraPosition).Unit
                local newCFrame = CFrame.new(cameraPosition, cameraPosition + direction)
                Camera.CFrame = Camera.CFrame:Lerp(newCFrame, _G.Sensitivity)
            end
        end
    end
end)
