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
_G.Sensitivity = 0 -- Smoothness level (lower = faster)
_G.PredictionAmount = 0 -- Horizontal prediction for moving targets
_G.AirPredictionAmount = 0 -- Vertical prediction for airborne targets
_G.BulletDropCompensation = 0
_G.DistanceAdjustment = true
_G.UseCircle = true
_G.WallCheck = true
_G.PredictionMultiplier = 1 -- Multiplier for fast-moving targets

_G.CircleSides = 64
_G.CircleColor = Color3.fromRGB(255, 255, 255)
_G.CircleTransparency = 0.7
_G.CircleRadius = 120
_G.CircleFilled = false
_G.CircleVisible = true
_G.CircleThickness = 1

_G.BoxEnabled = false
_G.BoxColor = Color3.fromRGB(255, 0, 0)
_G.BoxTransparency = 0.5
_G.BoxThickness = 0.05

_G.VisibleHighlight = true
_G.TargetLockKey = Enum.KeyCode.E
_G.ToggleAimbotKey = Enum.KeyCode.Q

-- FOV Circle Setup
local FOVCircle = Drawing.new("Circle")
FOVCircle.Filled = _G.CircleFilled
FOVCircle.Color = _G.CircleColor
FOVCircle.Visible = _G.CircleVisible
FOVCircle.Transparency = _G.CircleTransparency
FOVCircle.NumSides = _G.CircleSides
FOVCircle.Thickness = _G.CircleThickness

-- Utility Functions
local function Notify(title, text)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = 2
    })
end

local function IsTargetVisible(targetPart)
    if not _G.WallCheck then return true end

    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit * (targetPart.Position - origin).Magnitude

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    params.FilterType = Enum.RaycastFilterType.Blacklist

    local result = Workspace:Raycast(origin, direction, params)
    return not (result and result.Instance ~= targetPart)
end

local function GetClosestPlayerToMouse()
    local closestPlayer, shortestDistance = nil, _G.CircleRadius
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if _G.TeamCheck and player.Team == LocalPlayer.Team then
                continue
            end

            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local aimPart = player.Character:FindFirstChild(_G.AimPart)
                if aimPart then
                    local screenPoint = Camera:WorldToScreenPoint(aimPart.Position)
                    local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePos).Magnitude

                    if distance < shortestDistance and distance <= _G.CircleRadius and IsTargetVisible(aimPart) then
                        closestPlayer, shortestDistance = player, distance
                    end
                end
            end
        end
    end

    return closestPlayer
end

local function PredictTargetPosition(target)
    local aimPart = target.Character:FindFirstChild(_G.AimPart)
    if not aimPart then return nil end

    local velocity = aimPart.Velocity
    local predictedPosition = aimPart.Position
    local humanoid = target.Character:FindFirstChild("Humanoid")

    if humanoid then
        if humanoid:GetState() == Enum.HumanoidStateType.Freefall or humanoid:GetState() == Enum.HumanoidStateType.Jumping then
            predictedPosition += Vector3.new(0, velocity.Y * _G.AirPredictionAmount, 0)
        else
            local walkSpeed = humanoid.WalkSpeed
            local multiplier = walkSpeed > 16 and _G.PredictionMultiplier or 1
            predictedPosition += Vector3.new(velocity.X, 0, velocity.Z) * _G.PredictionAmount * multiplier
        end
    end

    return predictedPosition
end

local function ResolveTargetPosition(target)
    local aimPartName = target.Character:FindFirstChild("Humanoid"):GetState() == Enum.HumanoidStateType.Freefall and _G.AirAimPart or _G.AimPart
    local aimPart = target.Character:FindFirstChild(aimPartName)
    if not aimPart then return nil end

    local predictedPosition = PredictTargetPosition(target)
    local distance = (Camera.CFrame.Position - predictedPosition).Magnitude

    if _G.DistanceAdjustment and _G.BulletDropCompensation > 0 then
        predictedPosition -= Vector3.new(0, distance * _G.BulletDropCompensation, 0)
    end

    return predictedPosition
end

-- Event Handlers
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = true
        if _G.AimbotEnabled then
            local target = GetClosestPlayerToMouse()
            if target then
                Notify("Aimbot", "Locked onto " .. target.Name)

                if _G.VisibleHighlight then
                    local highlight = Instance.new("Highlight", target.Character)
                    highlight.FillColor = Color3.new(1, 0, 0)
                    highlight.OutlineColor = Color3.new(1, 1, 0)
                end
            end
        end
    elseif input.KeyCode == _G.ToggleAimbotKey then
        _G.AimbotEnabled = not _G.AimbotEnabled
        Notify("Aimbot", "Aimbot " .. (_G.AimbotEnabled and "Enabled" or "Disabled"))
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = false
    end
end)

RunService.RenderStepped:Connect(function()
    if _G.UseCircle then
        FOVCircle.Position = UserInputService:GetMouseLocation()
        FOVCircle.Radius = _G.CircleRadius
    else
        FOVCircle.Visible = false
    end

    if Holding and _G.AimbotEnabled then
        local target = GetClosestPlayerToMouse()
        if target then
            local resolvedPosition = ResolveTargetPosition(target)
            if resolvedPosition then
                local tween = TweenService:Create(Camera, TweenInfo.new(_G.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = CFrame.new(Camera.CFrame.Position, resolvedPosition)})
                tween:Play()
            end
        end
    end
end)
