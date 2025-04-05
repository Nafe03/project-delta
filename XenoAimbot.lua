-- Local Script - Place in StarterPlayerScripts
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
-- Global Settings
_G.AimbotEnabled = true
_G.LegitAimbot = false
_G.TeamCheck = false
_G.HotKeyAimbot = Enum.KeyCode.Q -- Set your desired hotkey here
_G.AimPart = "Head"
_G.AirAimPart = "LowerTorso"
_G.Sensitivity = 0      
_G.LegitSensitivity = 0.1 
_G.PredictionAmount = 0.1
_G.AirPredictionAmount = 0.2
_G.BulletDropCompensation = 0.05
_G.DistanceAdjustment = true
_G.WallCheck = true
_G.PredictionMultiplier = 0.55
_G.FastTargetSpeedThreshold = 35
_G.DynamicSensitivity = true
_G.DamageAmount = 0
_G.HeadVerticalOffset = 0
_G.UseHeadOffset = false
_G.ToggleAimbot = false -- Toggle mode
_G.DamageDisplay = false -- Enable/disable damage display
_G.VisibleHighlight = true -- For highlighting targets

-- Movement Prediction Settings
_G.MovementPredictionType = "Auto" -- "Auto", "Vector", "CFrame", or "Mixed"
_G.PatternDetectionEnabled = true -- Enable movement pattern detection
_G.PatternMemoryLength = 10 -- Number of positions to remember for pattern analysis
_G.PredictionSmoothness = 0.5 -- Smoothness factor for predictions (0-1)
_G.AdaptivePrediction = true -- Adjust prediction based on target behavior

-- Target Strafe Settings
_G.TargetStrafe = false -- Toggle for target strafing
_G.StrafeDisten = math.pi * 5 -- Distance for strafing using math.pi
_G.StrafeSpeed = 2 -- Speed of strafing
_G.StrafeDirection = 1 -- 1 for clockwise, -1 for counter-clockwise
_G.StrafeHeight = 0 -- Height offset for strafing

-- Silent Aim Settings
_G.SilentAim = false
_G.SilentAimHitChance = 100 -- Percentage chance to hit the target
_G.SilentAimRadius = 120 -- Radius for silent aim

-- Enhanced Resolver Settings
_G.ResolverEnabled = true
_G.ResolverPrediction = 0.1 -- Base prediction amount for resolver
_G.AntiLockDetectionThreshold = 50 -- Speed threshold for anti-lock detection
_G.DetectJumpCycling = true -- Detect jump-based anti-aims
_G.DetectCFrameSpoofing = true -- Detect CFrame manipulation
_G.ResolverMode = "Adaptive" -- "Adaptive", "Aggressive", or "Conservative"
_G.ResolverSmoothing = 0.2 -- Smoothness for resolver position transitions

-- FOV Circle Settings
_G.UseCircle = true
_G.CircleRadius = 120
_G.CircleColor = Color3.fromRGB(255, 255, 255)
_G.CircleThickness = 1
_G.CircleTransparency = 1
_G.CircleFilled = false

-- Current Target Variables
local CurrentTarget = nil
local CurrentHighlight = nil

-- Target Strafe Variables
local StrafeAngle = 0

-- Damage Display Variables
local DamageDisplay = nil
local TotalDamage = 0

-- Create a proper FOV circle using GUI elements
local function CreateFOVCircle()
    -- First, clean up any existing FOV circle
    if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
        local existingGui = LocalPlayer.PlayerGui:FindFirstChild("AimbotGUI")
        if existingGui then
            existingGui:Destroy()
        end
    end
    
    -- Create a new ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AimbotGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Try to place it in PlayerGui, fallback to CoreGui if in FE environment
    local success, err = pcall(function()
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end)
    
    if not success then
        screenGui.Parent = game:GetService("CoreGui")
    end
    
    -- Create circle frame
    local circle = Instance.new("Frame")
    circle.Name = "FOVCircle"
    circle.BackgroundTransparency = _G.CircleFilled and (1 - _G.CircleTransparency) or 1
    circle.BackgroundColor3 = _G.CircleColor
    circle.AnchorPoint = Vector2.new(0.5, 0.5)
    circle.Size = UDim2.new(0, _G.CircleRadius * 2, 0, _G.CircleRadius * 2)
    circle.Position = UDim2.new(0.5, 0, 0.5, 0)
    circle.Parent = screenGui
    
    -- Make it circular
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(1, 0)
    uiCorner.Parent = circle
    
    -- Add stroke for outline
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Color = _G.CircleColor
    uiStroke.Thickness = _G.CircleThickness
    uiStroke.Transparency = _G.CircleTransparency
    uiStroke.Parent = circle
    
    return {
        ScreenGui = screenGui,
        Circle = circle,
        Stroke = uiStroke,
        UpdatePosition = function(self, position)
            self.Circle.Position = UDim2.new(0, position.X, 0, position.Y)
        end,
        UpdateRadius = function(self, radius)
            self.Circle.Size = UDim2.new(0, radius * 2, 0, radius * 2)
        end,
        UpdateVisibility = function(self, visible)
            self.ScreenGui.Enabled = visible
        end,
        UpdateColor = function(self, color)
            self.Circle.BackgroundColor3 = color
            self.Stroke.Color = color
        end,
        UpdateProperties = function(self)
            self.Circle.BackgroundTransparency = _G.CircleFilled and (1 - _G.CircleTransparency) or 1
            self.Stroke.Thickness = _G.CircleThickness
            self.Stroke.Transparency = _G.CircleTransparency
            self:UpdateRadius(_G.CircleRadius)
            self:UpdateColor(_G.CircleColor)
            self:UpdateVisibility(_G.UseCircle)
        end
    }
end

-- Create our FOV Circle
local FOVCircle = CreateFOVCircle()

-- Function to create the damage display GUI
local function CreateDamageDisplay()
    if not _G.DamageDisplay then return end

    DamageDisplay = Instance.new("ScreenGui")
    DamageDisplay.Name = "DamageDisplay"
    DamageDisplay.ResetOnSpawn = false
    
    local success, err = pcall(function()
        DamageDisplay.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end)
    
    if not success then
        DamageDisplay.Parent = game:GetService("CoreGui")
    end

    local DamageLabel = Instance.new("TextLabel")
    DamageLabel.Name = "DamageLabel"
    DamageLabel.Parent = DamageDisplay
    DamageLabel.Size = UDim2.new(0, 200, 0, 50)
    DamageLabel.Position = UDim2.new(0.8, 0, 0.1, 0)
    DamageLabel.BackgroundTransparency = 1
    DamageLabel.TextColor3 = Color3.new(1, 1, 1)
    DamageLabel.TextStrokeTransparency = 0
    DamageLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    DamageLabel.TextSize = 20
    DamageLabel.Text = "Damage: 0"
    DamageLabel.Font = Enum.Font.SourceSansBold
end

-- Function to update the damage display
local function UpdateDamageDisplay(damage)
    if not _G.DamageDisplay or not DamageDisplay then return end

    TotalDamage = TotalDamage + damage
    local DamageLabel = DamageDisplay:FindFirstChild("DamageLabel")
    if DamageLabel then
        DamageLabel.Text = "Damage: " .. tostring(TotalDamage)
    end
end

-- Function to reset the damage display
local function ResetDamageDisplay()
    if not _G.DamageDisplay or not DamageDisplay then return end

    TotalDamage = 0
    local DamageLabel = DamageDisplay:FindFirstChild("DamageLabel")
    if DamageLabel then
        DamageLabel.Text = "Damage: 0"
    end
end

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

-- Enhanced function to resolve anti-lock including CFrame manipulation
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

    -- Initialize prediction data if it doesn't exist
    if not target.ResolverData then
        target.ResolverData = {
            LastPositions = {},
            LastOrientations = {},
            LastTimes = {},
            JumpPatterns = {},
            LastJumpTime = 0,
            AntiAimDetected = false,
            AntiAimType = "None", -- "Velocity", "CFrame", "Desync", "Jitter"
            JumpCount = 0
        }
    end

    local resolverData = target.ResolverData
    local currentTime = tick()
    
    -- Store position, orientation, and time data
    table.insert(resolverData.LastPositions, humanoidRootPart.Position)
    table.insert(resolverData.LastOrientations, humanoidRootPart.CFrame - humanoidRootPart.Position)
    table.insert(resolverData.LastTimes, currentTime)
    
    -- Keep only last 20 entries for pattern analysis
    if #resolverData.LastPositions > 20 then
        table.remove(resolverData.LastPositions, 1)
        table.remove(resolverData.LastOrientations, 1)
        table.remove(resolverData.LastTimes, 1)
    end
    
    -- Get the target's velocity and speed
    local velocity = humanoidRootPart.Velocity
    local speed = velocity.Magnitude
    
    -- Detect anti-aim patterns
    local function DetectAntiAimPatterns()
        if #resolverData.LastPositions < 5 then return "None" end
        
        -- Check for velocity manipulation anti-aim
        local velocityChanges = 0
        local cframeChanges = 0
        local orientationJitter = 0
        local teleportDetected = false
        
        for i = 2, #resolverData.LastPositions do
            local prevPos = resolverData.LastPositions[i-1]
            local currPos = resolverData.LastPositions[i]
            local prevOrientation = resolverData.LastOrientations[i-1]
            local currOrientation = resolverData.LastOrientations[i]
            local timeDiff = resolverData.LastTimes[i] - resolverData.LastTimes[i-1]
            
            if timeDiff > 0 then
                -- Calculate expected position based on velocity
                local projectedPos = prevPos + (humanoidRootPart.Velocity * timeDiff)
                local posDiff = (currPos - projectedPos).Magnitude
                
                -- Calculate orientation difference
                local orientationDiff = (prevOrientation:ToObjectSpace(currOrientation).Position).Magnitude
                
                -- Check for significant position or orientation changes
                if posDiff > 5 then velocityChanges = velocityChanges + 1 end
                if orientationDiff > 0.5 then orientationJitter = orientationJitter + 1 end
                
                -- Detect teleportation (very large position changes)
                if posDiff > 20 and timeDiff < 0.1 then
                    teleportDetected = true
                end
                
                -- Detect CFrame manipulation
                local expectedRotation = humanoidRootPart.CFrame.LookVector
                local actualRotation = currOrientation.LookVector
                if (expectedRotation - actualRotation).Magnitude > 0.5 then
                    cframeChanges = cframeChanges + 1
                end
            end
        end
        
        -- Determine anti-aim type based on patterns
        if teleportDetected then
            return "Teleport"
        elseif velocityChanges > 3 and velocityChanges > cframeChanges then
            return "Velocity"
        elseif cframeChanges > 3 and cframeChanges > velocityChanges then
            return "CFrame"
        elseif orientationJitter > 3 then
            return "Jitter"
        elseif speed > _G.AntiLockDetectionThreshold then
            return "Speed"
        else
            return "None"
        end
    end
    
    -- Detect the type of anti-aim
    resolverData.AntiAimType = DetectAntiAimPatterns()
    resolverData.AntiAimDetected = (resolverData.AntiAimType ~= "None")
    
    -- If anti-aim detected, resolve the position
    if resolverData.AntiAimDetected then
        local resolvedPosition = humanoidRootPart.Position
        
        -- Resolution strategies for different anti-aim types
        if resolverData.AntiAimType == "Velocity" then
            -- Resolve velocity manipulation by analyzing acceleration patterns
            if #resolverData.LastPositions >= 3 then
                local pos1 = resolverData.LastPositions[#resolverData.LastPositions-2]
                local pos2 = resolverData.LastPositions[#resolverData.LastPositions-1]
                local pos3 = resolverData.LastPositions[#resolverData.LastPositions]
                local time1 = resolverData.LastTimes[#resolverData.LastTimes-2]
                local time2 = resolverData.LastTimes[#resolverData.LastTimes-1]
                local time3 = resolverData.LastTimes[#resolverData.LastTimes]
                
                local vel1 = (pos2 - pos1) / (time2 - time1)
                local vel2 = (pos3 - pos2) / (time3 - time2)
                local accel = (vel2 - vel1) / (time3 - time1)
                
                -- Predict true position using acceleration
                resolvedPosition = pos3 + (vel2 * _G.ResolverPrediction) + 
                                  (0.5 * accel * _G.ResolverPrediction * _G.ResolverPrediction)
            end
        elseif resolverData.AntiAimType == "CFrame" then
            -- Resolve CFrame manipulation by analyzing real movement patterns
            if #resolverData.LastPositions >= 5 then
                -- Use a more stable position calculation based on average movement
                local avgVelocity = Vector3.new(0, 0, 0)
                local count = 0
                
                for i = 2, #resolverData.LastPositions do
                    local posDiff = resolverData.LastPositions[i] - resolverData.LastPositions[i-1]
                    local timeDiff = resolverData.LastTimes[i] - resolverData.LastTimes[i-1]
                    
                    if timeDiff > 0 then
                        avgVelocity = avgVelocity + (posDiff / timeDiff)
                        count = count + 1
                    end
                end
                
                if count > 0 then
                    avgVelocity = avgVelocity / count
                    resolvedPosition = humanoidRootPart.Position + (avgVelocity * _G.ResolverPrediction)
                end
            end
        elseif resolverData.AntiAimType == "Jitter" or resolverData.AntiAimType == "Teleport" then
            -- For jitter/teleport, use a smoothed position from recent history
            if #resolverData.LastPositions >= 3 then
                -- Use a weighted average of recent positions (more weight to newer positions)
                local totalWeight = 0
                local weightedSum = Vector3.new(0, 0, 0)
                
                for i = 1, #resolverData.LastPositions do
                    local weight = i / #resolverData.LastPositions
                    weightedSum = weightedSum + (resolverData.LastPositions[i] * weight)
                    totalWeight = totalWeight + weight
                end
                
                if totalWeight > 0 then
                    resolvedPosition = weightedSum / totalWeight
                end
            end
        elseif resolverData.AntiAimType == "Speed" then
            -- For speed-based anti-aim, use velocity projection with higher prediction
            local movementDirection = velocity.Unit
            resolvedPosition = humanoidRootPart.Position + (movementDirection * speed * _G.ResolverPrediction)
        end
        
        return resolvedPosition
    end
    
    -- If no anti-aim detected or unable to resolve, return nil
    return nil
end

-- Function to calculate strafe position around target
local function CalculateStrafePosition(targetPosition)
    if not _G.TargetStrafe then return nil end
    
    -- Calculate the strafe position using a circular path
    local x = math.cos(StrafeAngle) * _G.StrafeDisten
    local z = math.sin(StrafeAngle) * _G.StrafeDisten
    
    -- Create the strafe position offset from the target
    local strafeOffset = Vector3.new(x, _G.StrafeHeight, z)
    local strafePosition = targetPosition + strafeOffset
    
    -- Update the strafe angle for the next frame
    StrafeAngle = StrafeAngle + (_G.StrafeSpeed * 0.01 * _G.StrafeDirection)
    
    return strafePosition
end

-- Function to predict target position with enhanced CFrame and Vector movement detection
local function PredictTargetPosition(Target)
    local character = Target.Character
    if not character then return nil end

    local AimPart = character:FindFirstChild(_G.AimPart)
    local AirAimPart = character:FindFirstChild(_G.AirAimPart)
    local HumanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local Humanoid = character:FindFirstChild("Humanoid")

    if not (AimPart and HumanoidRootPart and Humanoid) then return nil end

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

    -- Store historical positions for pattern detection
    if not Target.PredictionData then
        Target.PredictionData = {
            PreviousPositions = {},
            PreviousCFrames = {},
            PreviousTimes = {},
            MovementType = "Unknown", -- "Vector", "CFrame", or "Mixed"
            LastUpdateTime = tick()
        }
    end
    
    local predictionData = Target.PredictionData
    local currentTime = tick()
    local deltaTime = currentTime - predictionData.LastUpdateTime
    
    -- Update historical data (keep last 10 positions for pattern analysis)
    if deltaTime > 0.01 then -- Only update if enough time has passed
        table.insert(predictionData.PreviousPositions, HumanoidRootPart.Position)
        table.insert(predictionData.PreviousCFrames, HumanoidRootPart.CFrame)
        table.insert(predictionData.PreviousTimes, currentTime)
        
        -- Keep only last 10 entries
        if #predictionData.PreviousPositions > 10 then
            table.remove(predictionData.PreviousPositions, 1)
            table.remove(predictionData.PreviousCFrames, 1)
            table.remove(predictionData.PreviousTimes, 1)
        end
        
        predictionData.LastUpdateTime = currentTime
    end
    
    -- Detect movement type based on historical data
    if #predictionData.PreviousPositions >= 3 then
        local vectorConsistency = 0
        local cframeConsistency = 0
        
        for i = 2, #predictionData.PreviousPositions do
            local prevPos = predictionData.PreviousPositions[i-1]
            local currPos = predictionData.PreviousPositions[i]
            local timeDiff = predictionData.PreviousTimes[i] - predictionData.PreviousTimes[i-1]
            
            -- Check vector movement consistency (linear motion)
            local posDiff = currPos - prevPos
            local velocity = posDiff / timeDiff
            local predictedNextPos = currPos + (velocity * timeDiff)
            
            -- Check if there's a next position to compare with
            if i < #predictionData.PreviousPositions then
                local actualNextPos = predictionData.PreviousPositions[i+1]
                local vectorPredictionError = (predictedNextPos - actualNextPos).Magnitude
                
                -- Check CFrame movement consistency (rotation + position)
                local prevCF = predictionData.PreviousCFrames[i-1]
                local currCF = predictionData.PreviousCFrames[i]
                local cfDiff = prevCF:Inverse() * currCF
                local predictedNextCF = currCF * cfDiff
                local actualNextCF = predictionData.PreviousCFrames[i+1]
                local cframePredictionError = (predictedNextCF.Position - actualNextCF.Position).Magnitude
                
                -- Update consistency scores
                if vectorPredictionError < cframePredictionError then
                    vectorConsistency = vectorConsistency + 1
                else
                    cframeConsistency = cframeConsistency + 1
                end
            end
        end
        
        -- Determine movement type based on consistency scores
        if vectorConsistency > cframeConsistency * 1.5 then
            predictionData.MovementType = "Vector"
        elseif cframeConsistency > vectorConsistency * 1.5 then
            predictionData.MovementType = "CFrame"
        else
            predictionData.MovementType = "Mixed"
        end
    end
    
    -- Get current velocity and speed
    local Velocity = HumanoidRootPart.Velocity
    local Speed = Velocity.Magnitude
    
    local predictedPosition = Position
    
    -- Predict based on detected movement type
    if predictionData.MovementType == "Vector" or predictionData.MovementType == "Unknown" then
        -- Standard velocity-based prediction
        local baseAmount = IsPlayerAirborne(Target) and _G.AirPredictionAmount or _G.PredictionAmount
        local speedMultiplier = Speed > _G.FastTargetSpeedThreshold and _G.PredictionMultiplier or 1
        
        local finalPredictionAmount = baseAmount * speedMultiplier
        
        -- Apply dynamic sensitivity if enabled
        if _G.DynamicSensitivity then
            finalPredictionAmount = finalPredictionAmount * math.clamp(Speed / 30, 0.5, 2.5)
        end
        
        -- Calculate prediction based on velocity
        predictedPosition = Position + (Velocity * finalPredictionAmount)
    elseif predictionData.MovementType == "CFrame" then
        -- CFrame-based prediction using previous transformations
        if #predictionData.PreviousCFrames >= 2 then
            local prevCF = predictionData.PreviousCFrames[#predictionData.PreviousCFrames-1]
            local currCF = predictionData.PreviousCFrames[#predictionData.PreviousCFrames]
            local deltaTime = predictionData.PreviousTimes[#predictionData.PreviousTimes] - 
                             predictionData.PreviousTimes[#predictionData.PreviousTimes-1]
            
            -- Calculate CFrame difference and predict next position
            local cfDiff = prevCF:Inverse() * currCF
            
            -- Extract rotation and position components
            local rotationMatrix = CFrame.new(Vector3.new(), cfDiff.Position) * 
                                 CFrame.Angles(cfDiff:ToEulerAnglesXYZ())
            
            -- Calculate prediction amount based on speed and settings
            local baseAmount = IsPlayerAirborne(Target) and _G.AirPredictionAmount or _G.PredictionAmount
            local speedMultiplier = Speed > _G.FastTargetSpeedThreshold and _G.PredictionMultiplier or 1
            local predictionFactor = baseAmount * speedMultiplier
            
            -- Apply CFrame prediction
            local predictedCF = currCF * (rotationMatrix^predictionFactor)
            predictedPosition = predictedCF.Position
        end
    else -- Mixed movement type
        -- Combine both predictions for mixed movement
        -- Vector prediction
        local baseAmount = IsPlayerAirborne(Target) and _G.AirPredictionAmount or _G.PredictionAmount
        local speedMultiplier = Speed > _G.FastTargetSpeedThreshold and _G.PredictionMultiplier or 1
        local vectorPrediction = Position + (Velocity * baseAmount * speedMultiplier)
        
        -- CFrame prediction
        local cfPrediction = Position
        if #predictionData.PreviousCFrames >= 2 then
            local prevCF = predictionData.PreviousCFrames[#predictionData.PreviousCFrames-1]
            local currCF = predictionData.PreviousCFrames[#predictionData.PreviousCFrames]
            local cfDiff = prevCF:Inverse() * currCF
            local predictedCF = currCF * cfDiff
            cfPrediction = predictedCF.Position
        end
        
        -- Blend predictions based on confidence (50/50 split for mixed)
        predictedPosition = vectorPrediction:Lerp(cfPrediction, 0.5)
    end
    
    -- Resolver for anti-lock movement if enabled
    if _G.ResolverEnabled then
        local resolvedPosition = ResolveAntiLock(Target)
        if resolvedPosition then
            -- Blend the resolved position with our prediction
            predictedPosition = predictedPosition:Lerp(resolvedPosition, 0.5)
        end
    end

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

-- Optimized Target Strafe using CFrame teleportation
local function OptimizedTargetStrafe(targetPosition)
    if not _G.TargetStrafe or not LocalPlayer.Character then
        return false
    end
    
    local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        return false
    end
    
    -- Calculate strafe position
    local strafePosition = CalculateStrafePosition(targetPosition)
    if not strafePosition then
        return false
    end
    
    -- Calculate the orientation to look at the target
    local lookVector = (targetPosition - strafePosition).Unit
    local upVector = Vector3.new(0, 1, 0) -- Standard up vector
    
    -- Create the CFrame for teleportation (position + orientation)
    local targetCFrame = CFrame.new(strafePosition, targetPosition)
    
    -- Apply the CFrame directly to the HumanoidRootPart
    humanoidRootPart.CFrame = targetCFrame
    
    return true
end

-- Input handling
UserInputService.InputBegan:Connect(function(Input)
    -- Activate Aimbot when HotKey is pressed
    if Input.KeyCode == _G.HotKeyAimbot then
        if _G.ToggleAimbot then
            -- Toggle mode
            Holding = not Holding
            if Holding then
                CurrentTarget = GetClosestPlayerToMouse()
                if CurrentTarget then
                    local mode = _G.AimbotEnabled and "Aimbot" or "Legit Aimbot"
                    Notify(mode, "Locked onto " .. CurrentTarget.Name)
                    if _G.VisibleHighlight then
                        CurrentHighlight = Instance.new("Highlight")
                        CurrentHighlight.FillColor = Color3.new(1, 0, 0)
                        CurrentHighlight.OutlineColor = Color3.new(1, 1, 0)
                        CurrentHighlight.Parent = CurrentTarget.Character
                    end
                end
            else
                CurrentTarget = nil
                if CurrentHighlight then
                    CurrentHighlight:Destroy()
                    CurrentHighlight = nil
                end
            end
        else
            -- Hold mode
            Holding = true
            if _G.AimbotEnabled or _G.LegitAimbot then
                CurrentTarget = GetClosestPlayerToMouse()
                if CurrentTarget then
                    local mode = _G.AimbotEnabled and "Aimbot" or "Legit Aimbot"
                    Notify(mode, "Locked onto " .. CurrentTarget.Name)
                    if _G.VisibleHighlight then
                        CurrentHighlight = Instance.new("Highlight")
                        CurrentHighlight.FillColor = Color3.new(1, 0, 0)
                        CurrentHighlight.OutlineColor = Color3.new(1, 1, 0)
                        CurrentHighlight.Parent = CurrentTarget.Character
                    end
                end
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(Input)
    -- Deactivate Aimbot when HotKey is released (only in hold mode)
    if Input.KeyCode == _G.HotKeyAimbot and not _G.ToggleAimbot then
        Holding = false
        CurrentTarget = nil
        if CurrentHighlight then
            CurrentHighlight:Destroy()
            CurrentHighlight = nil
        end
    end
end)

-- Heartbeat-based resolver with aimlock
RunService.Heartbeat:Connect(function()
    if Holding and ((_G.AimbotEnabled or _G.LegitAimbot) and CurrentTarget) then
        local character = CurrentTarget.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 and not IsPlayerKnocked(CurrentTarget) then
                local targetPosition = PredictTargetPosition(CurrentTarget)
                
                if targetPosition then
                    -- Handle optimized target strafing if enabled
                    if _G.TargetStrafe then
                        OptimizedTargetStrafe(targetPosition)
                    end
                    
                    -- Set camera CFrame to look at the predicted position
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPosition)
                end
            else
                CurrentTarget = nil
                if CurrentHighlight then
                    CurrentHighlight:Destroy()
                    CurrentHighlight = nil
                end
            end
        end
    end
end)

-- Update FOV Circle position on RenderStepped
RunService.RenderStepped:Connect(function()
    -- Update FOV Circle position and properties
    if _G.UseCircle and FOVCircle then
        local mouseLocation = UserInputService:GetMouseLocation()
        FOVCircle:UpdatePosition(mouseLocation)
        FOVCircle:UpdateProperties()
    else
        if FOVCircle then
            FOVCircle:UpdateVisibility(false)
        end
    end
end)

-- Create the damage display GUI
CreateDamageDisplay()

-- Simulate damage tracking (replace this with actual damage detection if available)
local function SimulateDamageTracking()
    while true do
        wait(1)
        if _G.DamageDisplay and DamageDisplay and Holding and CurrentTarget then
            -- Simulate damage (replace this with actual damage detection)
            local damage = math.random(10, 30)
            UpdateDamageDisplay(damage)
        end
    end
end

-- Start the damage tracking simulation
coroutine.wrap(SimulateDamageTracking)()

-- Provide a quick help message when the script starts
wait(1)
Notify("Aimbot Loaded", "Press " .. _G.HotKeyAimbot.Name .. " to activate")
