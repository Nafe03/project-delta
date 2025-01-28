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
_G.LegitAimbot = false
_G.TeamCheck = false
_G.AimPart = "Head"
_G.AirAimPart = "LowerTorso"
_G.Sensitivity = 0      
_G.LegitSensitivity = 0.1 
_G.PredictionAmount = 0
_G.AirPredictionAmount = 0
_G.BulletDropCompensation = 0
_G.DistanceAdjustment = false
_G.UseCircle = false
_G.WallCheck = false
_G.PredictionMultiplier = 1
_G.FastTargetSpeedThreshold = 35
_G.DynamicSensitivity = true
_G.DamageAmount = 0
_G.HeadVerticalOffset = 0
_G.UseHeadOffset = false

-- Silent Aim Settings
_G.SilentAim = false
_G.SilentAimHitChance = 100 -- Percentage chance to hit the target
_G.SilentAimRadius = 120 -- Radius for silent aim

-- Resolver Settings
_G.ResolverEnabled = true
_G.ResolverPrediction = 0.1 -- Adjust this value based on testing
_G.AntiLockDetectionThreshold = 50

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

-- Function to check if a player is knocked
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
    local ShortestDistance = _G.SilentAim and _G.SilentAimRadius or _G.CircleRadius

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

                    if vectorDistance < ShortestDistance and vectorDistance <= (_G.SilentAim and _G.SilentAimRadius or _G.CircleRadius) and IsTargetVisible(part) then
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

local function IsUsingAntiLock(player)
    if not player or not player.Character then
        return false
    end

    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        return false
    end

    -- Check if the player's velocity exceeds the threshold
    local velocity = humanoidRootPart.Velocity
    local speed = velocity.Magnitude

    return speed > _G.AntiLockDetectionThreshold
end

-- Function to resolve anti-lock
local function ResolveAntiLock(target)
    if not _G.ResolverEnabled or not target or not target.Character then
        return nil
    end

    local character = target.Character
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")

    if not (humanoidRootPart and humanoid) then
        return nil
    end

    -- Get the target's velocity and speed
    local velocity = humanoidRootPart.Velocity
    local speed = velocity.Magnitude

    -- If the player is using anti-lock, predict their real position
    if IsUsingAntiLock(target) then
        -- Predict the real position based on their movement direction
        local movementDirection = velocity.Unit
        local resolvedPosition = humanoidRootPart.Position + (movementDirection * _G.ResolverPrediction)

        return resolvedPosition
    end

    -- If not using anti-lock, return the current position
    return humanoidRootPart.Position
end

-- Modify the PredictTargetPosition function to include the resolver
local function PredictTargetPosition(Target)
    local character = Target.Character
    if not character then return end

    local AimPart = character:FindFirstChild(_G.AimPart)
    local AirAimPart = character:FindFirstChild(_G.AirAimPart)
    local HumanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local Humanoid = character:FindFirstChild("Humanoid")

    if not (AimPart and HumanoidRootPart and Humanoid) then return end

    -- Apply head offset if enabled and aiming at head
    local Position = AimPart.Position
    if _G.UseHeadOffset and _G.AimPart == "Head" then
        Position = Position + Vector3.new(0, _G.HeadVerticalOffset, 0)
    end

    -- Use AirAimPart if the target is airborne
    if IsPlayerAirborne(Target) and AirAimPart then
        AimPart = AirAimPart
        Position = AirAimPart.Position
    end

    -- Get velocity and speed
    local Velocity = HumanoidRootPart.Velocity
    local Speed = Velocity.Magnitude

    -- Calculate prediction offset
    local function CalculatePredictionOffset()
        local baseMultiplier = _G.PredictionAmount
        local speedBasedMultiplier = math.clamp(Speed / 50, 0.15, 2)

        return Vector3.new(
            Velocity.X * baseMultiplier * speedBasedMultiplier,
            Velocity.Y * baseMultiplier * speedBasedMultiplier * 0.5,
            Velocity.Z * baseMultiplier * speedBasedMultiplier
        )
    end

    local predictedOffset = CalculatePredictionOffset()
    local predictedPosition = Position + predictedOffset

    -- Bullet drop compensation if enabled
    if _G.BulletDropCompensation > 0 and _G.DistanceAdjustment then
        local distance = (Camera.CFrame.Position - predictedPosition).Magnitude
        local dropCompensation = Vector3.new(
            0,
            -distance * _G.BulletDropCompensation * math.clamp(Speed / 30, 0.5, 1.5),
            0
        )
        predictedPosition = predictedPosition + dropCompensation
    end

    return predictedPosition
end


-- Silent Aim Function
local function SilentAim()
    if _G.SilentAim then
        local closestPlayer = GetClosestPlayerToMouse()
        if closestPlayer and closestPlayer.Character and closestPlayer.Character:FindFirstChild(_G.AimPart) then
            local hitChance = math.random(1, 100)
            if hitChance <= _G.SilentAimHitChance then
                local predictedPosition = PredictTargetPosition(closestPlayer)
                if predictedPosition then
                    return predictedPosition
                end
            end
        end
    end
    return nil
end

-- Hook into the mouse's Hit property for silent aim
local oldMouseHit
oldMouseHit = hookmetamethod(game, "__index", function(self, key)
    if self == UserInputService and key == "GetMouseLocation" and _G.SilentAim then
        local silentAimPosition = SilentAim()
        if silentAimPosition then
            return silentAimPosition
        end
    end
    return oldMouseHit(self, key)
end)

-- Input handling
UserInputService.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = true
        if _G.AimbotEnabled or _G.LegitAimbot then
            CurrentTarget = GetClosestPlayerToMouse()
            if CurrentTarget then
                local mode = _G.AimbotEnabled and "Aimbot" or "Legit Aimbot"
                Notify(mode, "Locked onto " .. CurrentTarget.Name)
                if _G.VisibleHighlight then
                    CurrentHighlight = Instance.new("Highlight", CurrentTarget.Character)
                    CurrentHighlight.FillColor = Color3.new(1, 0, 0)
                    CurrentHighlight.OutlineColor = Color3.new(1, 1, 0)
                end
            end
        end
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

-- Heartbeat-based resolver with instant aimlock
RunService.Heartbeat:Connect(function()
    if Holding and ((_G.AimbotEnabled or _G.LegitAimbot) and CurrentTarget) then
        local character = CurrentTarget.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 and not IsPlayerKnocked(CurrentTarget) then
                local aimPosition = PredictTargetPosition(CurrentTarget)
                
                if aimPosition then
                    -- Instantly set camera CFrame to look at the predicted position
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, aimPosition)
                end
            else
                CurrentTarget = nil
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if _G.UseCircle then
        FOVCircle.Position = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
        FOVCircle.Radius = _G.CircleRadius
    else
        FOVCircle.Visible = false
    end
end)
