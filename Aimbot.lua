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

-- Function to update the FOV Circle
local function UpdateFOVCircle()
    FOVCircle.Position = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
    FOVCircle.Radius = _G.CircleRadius
    FOVCircle.Filled = _G.CircleFilled
    FOVCircle.Color = _G.CircleColor
    FOVCircle.Visible = _G.CircleVisible
    FOVCircle.Transparency = _G.CircleTransparency
    FOVCircle.NumSides = _G.CircleSides
    FOVCircle.Thickness = _G.CircleThickness
end

UpdateFOVCircle() -- Initialize FOV Circle

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

-- Function to check if a player is knocked in Da Hood
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

-- Function to get the closest player to the mouse that is inside the FOV Circle
local function GetClosestPlayerToMouse()
    local Target = nil
    local ShortestDistance = _G.CircleRadius

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if _G.TeamCheck and player.Team == LocalPlayer.Team then
                continue
            end
            
            if IsPlayerKnocked(player) then
                continue
            end

            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local aimPart = player.Character:FindFirstChild(_G.AimPart)
                if aimPart then
                    local screenPoint, onScreen = Camera:WorldToScreenPoint(aimPart.Position)
                    local mousePos = UserInputService:GetMouseLocation()
                    local distanceFromMouse = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(screenPoint.X, screenPoint.Y)).Magnitude

                    -- Check if the target is within the FOV circle and in front of the camera
                    if onScreen and screenPoint.Z > 0 and distanceFromMouse <= ShortestDistance and distanceFromMouse <= _G.CircleRadius and IsTargetVisible(aimPart) then
                        ShortestDistance = distanceFromMouse
                        Target = player
                    end
                end
            end
        end
    end

    return Target
end


-- Resolve Target Position with dynamic adjustments for fast targets
-- Function to calculate prediction for moving targets
local function ResolveTargetPosition(Target)
    if not Target or not Target.Character then return nil end

    -- Determine the aim part (e.g., "Head" or "LowerTorso") based on the target's state
    local humanoid = Target.Character:FindFirstChild("Humanoid")
    local aimPartName = (humanoid and humanoid:GetState() == Enum.HumanoidStateType.Freefall) and _G.AirAimPart or _G.AimPart
    local AimPart = Target.Character:FindFirstChild(aimPartName)

    if not AimPart then return nil end

    local AimPosition = AimPart.Position
    local TargetVelocity = Target.Character:FindFirstChild("HumanoidRootPart") and Target.Character.HumanoidRootPart.Velocity or Vector3.zero
    local Distance = (Camera.CFrame.Position - AimPosition).Magnitude

    -- Calculate bullet travel time based on distance and an assumed bullet speed
    local BulletSpeed = 1000 -- Adjust this value based on your game's bullet speed
    local TravelTime = Distance / BulletSpeed

    -- Predict target's position based on their velocity and travel time
    local PredictedPosition = AimPosition + TargetVelocity * TravelTime * _G.PredictionMultiplier

    -- Adjust for bullet drop if enabled
    if _G.BulletDropCompensation > 0 and _G.DistanceAdjustment then
        PredictedPosition = PredictedPosition - Vector3.new(0, Distance * _G.BulletDropCompensation, 0)
    end

    return PredictedPosition
end


-- Input handling for aimbot activation and locking
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

-- Update FOV circle and aimbot behavior on RenderStepped
RunService.RenderStepped:Connect(function()
    UpdateFOVCircle()

    if Holding and _G.AimbotEnabled and CurrentTarget then
        local character = CurrentTarget.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 and not IsPlayerKnocked(CurrentTarget) then
                local aimPosition = ResolveTargetPosition(CurrentTarget)
                if aimPosition then
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, aimPosition)
                end
            else
                CurrentTarget = nil
            end
        end
    end
end)
