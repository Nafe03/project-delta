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
_G.Sensitivity = 0
_G.PredictionAmount = 0
_G.AirPredictionAmount = 0
_G.BulletDropCompensation = 0
_G.DistanceAdjustment = false
_G.UseCircle = true
_G.WallCheck = false
_G.PredictionMultiplier = 0

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

-- Function to check if a point is within the FOV circle
local function IsWithinFOVCircle(screenPoint)
    local mousePos = UserInputService:GetMouseLocation()
    local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePos).Magnitude
    return distance <= _G.CircleRadius
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
        return not (raycastResult and raycastResult.Instance ~= targetPart)
    end
    return true
end

-- Improved function to get the closest player to the mouse
local function GetClosestPlayerToMouse()
    local Target = nil
    local ShortestDistance = math.huge
    local MousePosition = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if _G.TeamCheck and player.Team == LocalPlayer.Team then
                continue
            end

            local humanoid = player.Character:FindFirstChild("Humanoid")
            if not (humanoid and humanoid.Health > 0) then
                continue
            end

            local aimPart = player.Character:FindFirstChild(_G.AimPart)
            if not aimPart then
                continue
            end

            local screenPoint = Camera:WorldToScreenPoint(aimPart.Position)
            if screenPoint.Z < 0 then
                continue
            end

            -- Check if the player is within the FOV circle
            if not IsWithinFOVCircle(screenPoint) then
                continue
            end

            -- Check if the target is visible through walls if wall check is enabled
            if not IsTargetVisible(aimPart) then
                continue
            end

            local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - MousePosition).Magnitude
            if distance < ShortestDistance then
                ShortestDistance = distance
                Target = player
            end
        end
    end

    return Target
end

-- Function to create box ESP
local function CreateBox(targetCharacter)
    local Box = Instance.new("BoxHandleAdornment")
    Box.Adornee = targetCharacter
    Box.Color3 = _G.BoxColor
    Box.Transparency = _G.BoxTransparency
    Box.Size = Vector3.new(4, 6, 4)
    Box.AlwaysOnTop = true
    Box.ZIndex = 1
    Box.Parent = targetCharacter
    return Box
end

-- Improved target position prediction
local function PredictTargetPosition(Target)
    local AimPart = Target.Character:FindFirstChild(_G.AimPart)
    if not AimPart then return AimPart.Position end

    local Velocity = AimPart.Velocity
    local predictedPosition = AimPart.Position

    local humanoid = Target.Character:FindFirstChild("Humanoid")
    if humanoid then
        local walkSpeed = humanoid.WalkSpeed
        local predictionAmount = _G.PredictionAmount

        if walkSpeed > 30 then
            predictionAmount = predictionAmount * _G.PredictionMultiplier
        end

        if humanoid:GetState() ~= Enum.HumanoidStateType.Freefall and humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
            predictedPosition = predictedPosition + Vector3.new(Velocity.X, 0, Velocity.Z) * predictionAmount
        else
            predictedPosition = predictedPosition + Vector3.new(0, Velocity.Y * _G.AirPredictionAmount, 0)
        end
    end

    return predictedPosition
end

-- Input handling
UserInputService.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = true
        if _G.AimbotEnabled then
            CurrentTarget = GetClosestPlayerToMouse()
            if CurrentTarget then
                Notify("Aimbot", "Locked onto " .. CurrentTarget.Name)
                if _G.VisibleHighlight then
                    CurrentHighlight = Instance.new("Highlight")
                    CurrentHighlight.FillColor = Color3.new(1, 0, 0)
                    CurrentHighlight.OutlineColor = Color3.new(1, 1, 0)
                    CurrentHighlight.Parent = CurrentTarget.Character
                end
                if _G.BoxEnabled then
                    CurrentBox = CreateBox(CurrentTarget.Character)
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
        if CurrentBox then
            CurrentBox:Destroy()
            CurrentBox = nil
        end
    end
end)

-- Main aimbot loop
RunService.RenderStepped:Connect(function()
    if _G.UseCircle then
        FOVCircle.Position = UserInputService:GetMouseLocation()
        FOVCircle.Radius = _G.CircleRadius
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end

    if Holding and _G.AimbotEnabled and CurrentTarget then
        local character = CurrentTarget.Character
        if not character then
            CurrentTarget = nil
            return
        end

        local humanoid = character:FindFirstChild("Humanoid")
        if not (humanoid and humanoid.Health > 0) then
            CurrentTarget = nil
            return
        end

        local aimPart = character:FindFirstChild(_G.AimPart)
        if not aimPart then
            CurrentTarget = nil
            return
        end

        local screenPoint = Camera:WorldToScreenPoint(aimPart.Position)
        if screenPoint.Z < 0 or not IsWithinFOVCircle(screenPoint) then
            CurrentTarget = nil
            return
        end

        local predictedPos = PredictTargetPosition(CurrentTarget)
        if predictedPos then
            local targetCFrame = CFrame.new(Camera.CFrame.Position, predictedPos)
            if _G.Sensitivity > 0 then
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 1 - _G.Sensitivity)
            else
                Camera.CFrame = targetCFrame
            end
        end
    end
end)
