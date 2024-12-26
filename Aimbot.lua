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
_G.Sensitivity = 0
_G.PredictionAmount = 0
_G.AirPredictionAmount = 0
_G.BulletDropCompensation = 0
_G.DistanceAdjustment = false
_G.UseCircle = true
_G.WallCheck = false
_G.CircleRadius = 120
_G.CircleSides = 64
_G.CircleColor = Color3.fromRGB(255, 255, 255)
_G.CircleTransparency = 0.7
_G.CircleFilled = false
_G.CircleVisible = true
_G.CircleThickness = 1
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

-- Function to get the closest player to the mouse within the FOV circle
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

-- Input handling for aimbot activation and locking
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

-- Update FOV circle and aimbot behavior on RenderStepped
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
        if character and character:FindFirstChild("HumanoidRootPart") then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 and not IsPlayerKnocked(CurrentTarget) then
                local aimPart = character:FindFirstChild(_G.AimPart)
                if aimPart then
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, aimPart.Position)
                end
            else
                CurrentTarget = nil
            end
        end
    end
end)
