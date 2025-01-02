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
_G.LegitAimbot = false
_G.TeamCheck = false
_G.AimPart = "Head"
_G.AirAimPart = "LowerTorso"
_G.Sensitivity = 1      
_G.LegitSensitivity = 0.1 
_G.PredictionAmount = 0
_G.AirPredictionAmount = 0
_G.BulletDropCompensation = 0
_G.DistanceAdjustment = false
_G.UseCircle = false
_G.WallCheck = false
_G.PredictionMultiplier = 1.45
_G.FastTargetSpeedThreshold = 35
_G.DynamicSensitivity = true
_G.DamageAmount = 0
_G.HeadVerticalOffset = 0.3 -- Adjust this value to change how much above the head it aims
_G.UseHeadOffset = true -- Toggle for head offset feature
_G.LinePredic = true -- Toggle for the prediction line

-- FOV Circle Settings
_G.CircleSides = 64
_G.CircleColor = Color3.fromRGB(255, 255, 255)
_G.CircleTransparency = 1
_G.CircleRadius = 120
_G.CircleFilled = false
_G.CircleVisible = true
_G.CircleThickness = 1

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

-- Define the line object for visualizing the prediction
local PredictionLine = Drawing.new("Line")
PredictionLine.Thickness = 2
PredictionLine.Color = Color3.fromRGB(255, 0, 0) -- Red line for visualization
PredictionLine.Transparency = 1
PredictionLine.Visible = false

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

-- Function to get the closest player to the mouse
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
                local part = player.Character:FindFirstChild(_G.AimPart)
                if part then
                    local screenPoint = Camera:WorldToScreenPoint(part.Position)
                    local mousePos = UserInputService:GetMouseLocation()
                    local vectorDistance = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(screenPoint.X, screenPoint.Y)).Magnitude

                    if vectorDistance < ShortestDistance and vectorDistance <= _G.CircleRadius and IsTargetVisible(part) then
                        ShortestDistance = vectorDistance
                        Target = player
                    end
                end
            end
        end
    end

    return Target
end

-- Function to check if a player is airborne
local function IsPlayerAirborne(player)
    local character = player.Character
    if not character then return false end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Freefall then
        return true
    end
    
    return false
end

-- Enhanced prediction function
local function PredictTargetPosition(Target)
    local character = Target.Character
    if not character then return end

    local AimPart = character:FindFirstChild(_G.AimPart)
    local Position = AimPart and AimPart.Position
    if not Position then return end

    -- Prediction logic
    local HumanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local Velocity = HumanoidRootPart and HumanoidRootPart.Velocity
    if not Velocity then return Position end

    local Prediction = Position + (Velocity * _G.PredictionMultiplier)
    return Prediction
end

-- Update the ResolveTargetPosition function to use the new prediction
local function ResolveTargetPosition(Target)
    return PredictTargetPosition(Target)
end

-- Input handling
UserInputService.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = true
        if _G.AimbotEnabled or _G.LegitAimbot then
            CurrentTarget = GetClosestPlayerToMouse()
            if CurrentTarget then
                local mode = _G.AimbotEnabled and "Aimbot" or "Legit Aimbot"
                Notify(mode, "Locked onto " .. CurrentTarget.Name)
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = false
        CurrentTarget = nil
        PredictionLine.Visible = false
    end
end)

RunService.RenderStepped:Connect(function()
    if _G.UseCircle then
        FOVCircle.Position = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
        FOVCircle.Radius = _G.CircleRadius
    else
        FOVCircle.Visible = false
    end

    if Holding and ((_G.AimbotEnabled or _G.LegitAimbot) and CurrentTarget) then
        local aimPosition = ResolveTargetPosition(CurrentTarget)
        if aimPosition then
            -- Set line visibility and position
            if _G.LinePredic then
                PredictionLine.Visible = true
                PredictionLine.From = UserInputService:GetMouseLocation()
                PredictionLine.To = Camera:WorldToScreenPoint(aimPosition)
            else
                PredictionLine.Visible = false
            end

            -- Instantly set camera CFrame to look at the predicted position
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, aimPosition)
        else
            PredictionLine.Visible = false
        end
    else
        PredictionLine.Visible = false
    end
end)
