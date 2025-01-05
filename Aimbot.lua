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

-- FOV Circle Settings
_G.CircleSides = 64
_G.CircleColor = Color3.fromRGB(255, 255, 255)
_G.CircleTransparency = 1
_G.CircleRadius = 120
_G.CircleFilled = false
_G.CircleVisible = true
_G.CircleThickness = 1

-- Damage Indicator Function

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

-- Enhanced prediction function for air and CFrame exploit handling
-- Enhanced prediction function for CFrame movement detection
local function PredictTargetPosition(Target)
    local character = Target.Character
    if not character then return end

    local AimPart = character:FindFirstChild(_G.AimPart)
    local HumanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local Humanoid = character:FindFirstChild("Humanoid")

    if not (AimPart and HumanoidRootPart and Humanoid) then return end

    -- Store the last known positions and timestamps for CFrame detection
    if not _G.LastPositions then
        _G.LastPositions = {}
    end
    if not _G.LastTimestamps then
        _G.LastTimestamps = {}
    end

    local currentTime = tick()
    local playerId = Target.UserId

    -- Initialize player tracking if not exists
    if not _G.LastPositions[playerId] then
        _G.LastPositions[playerId] = {
            pos = HumanoidRootPart.Position,
            time = currentTime,
            velocity = Vector3.new(0, 0, 0),
            acceleration = Vector3.new(0, 0, 0)
        }
    end

    local lastData = _G.LastPositions[playerId]
    local timeDelta = currentTime - lastData.time
    
    -- Calculate real position and velocity
    local currentPosition = HumanoidRootPart.Position
    local rawVelocity = (currentPosition - lastData.pos) / timeDelta
    local realVelocity = HumanoidRootPart.Velocity
    
    -- Detect CFrame movement by comparing raw position change to expected velocity-based movement
    local expectedPosition = lastData.pos + (realVelocity * timeDelta)
    local positionDifference = (currentPosition - expectedPosition).Magnitude
    local isCFrameMovement = positionDifference > 5 -- Threshold for CFrame detection

    -- Calculate acceleration
    local velocityDelta = rawVelocity - lastData.velocity
    local acceleration = velocityDelta / timeDelta

    -- Update tracking data
    _G.LastPositions[playerId] = {
        pos = currentPosition,
        time = currentTime,
        velocity = rawVelocity,
        acceleration = acceleration
    }

    -- Enhanced prediction calculation
    local function CalculatePrediction()
        local predictionTime = _G.PredictionAmount * 0.1 -- Convert to seconds
        
        -- Base position with head offset if enabled
        local basePosition = AimPart.Position
        if _G.UseHeadOffset and _G.AimPart == "Head" then
            basePosition = basePosition + Vector3.new(0, _G.HeadVerticalOffset, 0)
        end

        -- If CFrame movement detected, use enhanced prediction
        if isCFrameMovement then
            -- Calculate pattern-based prediction
            local patternMultiplier = _G.PredictionMultiplier * 2 -- Increase multiplier for CFrame movements
            local predictedOffset = rawVelocity * predictionTime * patternMultiplier
            
            -- Add acceleration component for more accurate prediction
            predictedOffset = predictedOffset + (acceleration * predictionTime * predictionTime * 0.5)
            
            -- Add extra vertical prediction for anti-aim handling
            local verticalComponent = Vector3.new(0, math.abs(rawVelocity.Y) * 1.5, 0)
            predictedOffset = predictedOffset + verticalComponent
            
            return basePosition + predictedOffset
        else
            -- Standard prediction for normal movement
            local predictedOffset = realVelocity * predictionTime * _G.PredictionMultiplier
            return basePosition + predictedOffset
        end
    end

    local predictedPosition = CalculatePrediction()

    -- Apply additional compensation for fast movements
    local speed = rawVelocity.Magnitude
    if speed > _G.FastTargetSpeedThreshold then
        local speedMultiplier = math.clamp(speed / 50, 1, 3)
        local extraPrediction = rawVelocity.Unit * (speed * 0.1) * speedMultiplier
        predictedPosition = predictedPosition + extraPrediction
    end

    -- Bullet drop compensation
    if _G.BulletDropCompensation > 0 and _G.DistanceAdjustment then
        local distance = (Camera.CFrame.Position - predictedPosition).Magnitude
        local dropCompensation = Vector3.new(
            0,
            -distance * _G.BulletDropCompensation * math.clamp(speed / 30, 0.5, 1.5),
            0
        )
        predictedPosition = predictedPosition + dropCompensation
    end

    return predictedPosition
end

-- Update the ResolveTargetPosition function to use the new prediction
local function ResolveTargetPosition(Target)
    if not Target or not Target.Character then return end
    
    local predictedPosition = PredictTargetPosition(Target)
    if not predictedPosition then return end
    
    local character = Target.Character
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if humanoid and rootPart then
        local speed = rootPart.Velocity.Magnitude
        if speed > _G.FastTargetSpeedThreshold then
            local currentPos = rootPart.Position
            local smoothFactor = math.clamp(1 - (speed / 200), 0.3, 0.8)
            predictedPosition = currentPos:Lerp(predictedPosition, smoothFactor)
        end
    end
    
    return predictedPosition
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
                if _G.VisibleHighlight then
                    CurrentHighlight = Instance.new("Highlight", CurrentTarget.Character)
                    CurrentHighlight.FillColor = Color3.new(1, 0, 0)
                    CurrentHighlight.OutlineColor = Color3.new(1, 1, 0)
                end
            end
        end
    elseif Input.KeyCode == _G.ToggleAimbotKey then
        _G.AimbotEnabled = not _G.AimbotEnabled
        if _G.AimbotEnabled then
            _G.LegitAimbot = false
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

RunService.RenderStepped:Connect(function()
    if _G.UseCircle then
        FOVCircle.Position = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
        FOVCircle.Radius = _G.CircleRadius
    else
        FOVCircle.Visible = false
    end

    if Holding and ((_G.AimbotEnabled or _G.LegitAimbot) and CurrentTarget) then
        local character = CurrentTarget.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 and not IsPlayerKnocked(CurrentTarget) then
                local aimPosition = ResolveTargetPosition(CurrentTarget)
                
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
