local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Holding = false
local LockedTarget = nil
local TargetLockEnabled = false
local StrafeAngle = 0 -- Initialize strafe angle

_G.AimbotEnabled = true
_G.TeamCheck = false -- If set to true then the script would only lock your aim at enemy team members.
_G.AimPart = "Head" -- Where the aimbot script would lock at.
_G.Sensitivity = 0 -- How many seconds it takes for the aimbot script to officially lock onto the target's aimpart.
_G.PredictionAmount = 0 -- Amount of prediction (velocity multiplier) for left/right movement
_G.AirPredictionAmount = 0 -- Amount of prediction (velocity multiplier) for up/down movement

_G.CircleSides = 64 -- How many sides the FOV circle would have.
_G.CircleColor = Color3.fromRGB(255, 255, 255) -- (RGB) Color that the FOV circle would appear as.
_G.CircleTransparency = 0.7 -- Transparency of the circle.
_G.CircleRadius = 80 -- The radius of the circle / FOV.
_G.CircleFilled = false -- Determines whether or not the circle is filled.
_G.CircleVisible = true -- Determines whether or not the circle is visible.
_G.CircleThickness = 0 -- The thickness of the circle.

_G.TargetStrafe = false -- Toggle for target strafing
_G.StrafeDisten = math.pi * 5 -- Distance for strafing using math.pi
_G.StrafeSpeed = 2 -- Speed of strafing
_G.StrafeDirection = 1 -- 1 for clockwise, -1 for counter-clockwise
_G.StrafeHeight = 0 -- Height offset for strafing
_G.RandomPosTargetStrafe = false -- Enable random position target strafing

-- Wall check settings
_G.WallCheckEnabled = false -- Toggle for wall check feature
_G.WallCheckTransparency = 1 -- Maximum transparency that still counts as a wall

-- Triggerbot settings
_G.TriggerbotEnabled = false -- Toggle for triggerbot (off by default)
_G.TriggerbotDelay = 0.1 -- Delay in seconds before the triggerbot fires
_G.TriggerbotFOV = 5 -- FOV for the triggerbot (smaller than aimbot FOV for precision)

-- Variables to control the frequency of random position updates
local strafeUpdateCounter = 0
local strafeUpdateFrequency = 10 -- Adjust this value to control how often the position updates
local lastTriggerTime = 0 -- For triggerbot timing

local FOVCircle = Drawing.new("Circle")
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
FOVCircle.Radius = _G.CircleRadius
FOVCircle.Filled = _G.CircleFilled
FOVCircle.Color = _G.CircleColor
FOVCircle.Visible = _G.CircleVisible
FOVCircle.Radius = _G.CircleRadius
FOVCircle.Transparency = _G.CircleTransparency
FOVCircle.NumSides = _G.CircleSides
FOVCircle.Thickness = _G.CircleThickness

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

-- Function to check if the target is in front of the player
local function IsTargetInFront(targetPosition)
    local playerPosition = Camera.CFrame.Position
    local playerForward = Camera.CFrame.LookVector
    local directionToTarget = (targetPosition - playerPosition).Unit
    -- Calculate the angle between the player's forward direction and the direction to the target
    local dotProduct = playerForward:Dot(directionToTarget)
    local angle = math.acos(dotProduct)
    -- Convert the angle from radians to degrees
    local angleDegrees = math.deg(angle)
    -- Check if the angle is within the threshold (e.g., 90 degrees)
    local threshold = 90
    return angleDegrees <= threshold
end

-- Wall check function to determine if a target is visible
local function IsTargetVisible(targetPart)
    if not _G.WallCheckEnabled then return true end
    
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, targetPart.Parent}
    
    local raycastResult = workspace:Raycast(origin, direction * (targetPart.Position - origin).Magnitude, raycastParams)
    
    if raycastResult then
        -- Check if the hit object is transparent enough to not be considered a wall
        if raycastResult.Instance.Transparency > _G.WallCheckTransparency then
            return true
        else
            return false -- Hit a wall
        end
    else
        return true -- No obstacles in the way
    end
end

-- Function to calculate strafe position around target
local function CalculateStrafePosition(targetPosition)
    if not _G.TargetStrafe then return nil end
    local strafePosition
    if _G.RandomPosTargetStrafe then
        -- Increment the update counter
        strafeUpdateCounter = strafeUpdateCounter + _G.StrafeSpeed
        -- Check if it's time to update the random position
        if strafeUpdateCounter >= strafeUpdateFrequency then
            strafeUpdateCounter = 0 -- Reset the counter
            -- Calculate random offsets for X, Y, and Z
            local randomX = math.random(-_G.StrafeDisten, _G.StrafeDisten)
            local randomY = math.random(-_G.StrafeDisten, _G.StrafeDisten)
            local randomZ = math.random(-_G.StrafeDisten, _G.StrafeDisten)
            -- Create the strafe position with random offsets
            strafePosition = targetPosition + Vector3.new(randomX, randomY + _G.StrafeHeight, randomZ)
        end
    else
        -- Calculate the strafe position using a circular path
        local x = math.cos(StrafeAngle) * _G.StrafeDisten
        local z = math.sin(StrafeAngle) * _G.StrafeDisten
        -- Create the strafe position offset from the target
        strafePosition = targetPosition + Vector3.new(x, _G.StrafeHeight, z)
        -- Update the strafe angle for the next frame
        StrafeAngle = StrafeAngle + (_G.StrafeSpeed * 0.01 * _G.StrafeDirection)
    end
    return strafePosition
end

local function GetClosestPlayer()
    local MaximumDistance = _G.CircleRadius
    local Target = nil

    for _, v in next, Players:GetPlayers() do
        if v.Name ~= LocalPlayer.Name then
            if _G.TeamCheck == true then
                if v.Team ~= LocalPlayer.Team then
                    if v.Character ~= nil then
                        if v.Character:FindFirstChild("HumanoidRootPart") ~= nil then
                            if v.Character:FindFirstChild("Humanoid") ~= nil and v.Character:FindFirstChild("Humanoid").Health ~= 0 and not IsPlayerKnocked(v) then
                                local ScreenPoint = Camera:WorldToScreenPoint(v.Character:WaitForChild("HumanoidRootPart", math.huge).Position)
                                local VectorDistance = (Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2.new(ScreenPoint.X, ScreenPoint.Y)).Magnitude
                                
                                -- Check if target is in front of player and visible (not behind a wall)
                                if VectorDistance < MaximumDistance and 
                                   IsTargetInFront(v.Character.HumanoidRootPart.Position) and 
                                   IsTargetVisible(v.Character.HumanoidRootPart) then
                                    Target = v
                                    MaximumDistance = VectorDistance -- Update to get the closest
                                end
                            end
                        end
                    end
                end
            else
                if v.Character ~= nil then
                    if v.Character:FindFirstChild("HumanoidRootPart") ~= nil then
                        if v.Character:FindFirstChild("Humanoid") ~= nil and v.Character:FindFirstChild("Humanoid").Health ~= 0 and not IsPlayerKnocked(v) then
                            local ScreenPoint = Camera:WorldToScreenPoint(v.Character:WaitForChild("HumanoidRootPart", math.huge).Position)
                            local VectorDistance = (Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2.new(ScreenPoint.X, ScreenPoint.Y)).Magnitude
                            
                            -- Check if target is in front of player and visible (not behind a wall)
                            if VectorDistance < MaximumDistance and 
                               IsTargetInFront(v.Character.HumanoidRootPart.Position) and 
                               IsTargetVisible(v.Character.HumanoidRootPart) then
                                Target = v
                                MaximumDistance = VectorDistance -- Update to get the closest
                            end
                        end
                    end
                end
            end
        end
    end

    return Target
end

-- Function to get a player directly under the mouse cursor for triggerbot
local function GetPlayerUnderMouse()
    local MaxDistance = _G.TriggerbotFOV or 5 -- Smaller FOV for triggerbot for precision
    local Target = nil

    for _, v in next, Players:GetPlayers() do
        if v.Name ~= LocalPlayer.Name then
            if _G.TeamCheck == true then
                if v.Team ~= LocalPlayer.Team then
                    if v.Character and v.Character:FindFirstChild(_G.AimPart) then
                        local aimPart = v.Character[_G.AimPart]
                        if aimPart and v.Character:FindFirstChild("Humanoid") and 
                           v.Character.Humanoid.Health > 0 and not IsPlayerKnocked(v) then
                            
                            local ScreenPoint = Camera:WorldToScreenPoint(aimPart.Position)
                            local VectorDistance = (Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2.new(ScreenPoint.X, ScreenPoint.Y)).Magnitude
                            
                            -- Check if player is under mouse cursor, in front of player, and not behind wall
                            if VectorDistance < MaxDistance and 
                               IsTargetInFront(aimPart.Position) and 
                               IsTargetVisible(aimPart) then
                                Target = v
                                MaxDistance = VectorDistance
                            end
                        end
                    end
                end
            else
                if v.Character and v.Character:FindFirstChild(_G.AimPart) then
                    local aimPart = v.Character[_G.AimPart]
                    if aimPart and v.Character:FindFirstChild("Humanoid") and 
                       v.Character.Humanoid.Health > 0 and not IsPlayerKnocked(v) then
                        
                        local ScreenPoint = Camera:WorldToScreenPoint(aimPart.Position)
                        local VectorDistance = (Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2.new(ScreenPoint.X, ScreenPoint.Y)).Magnitude
                        
                        -- Check if player is under mouse cursor, in front of player, and not behind wall
                        if VectorDistance < MaxDistance and 
                           IsTargetInFront(aimPart.Position) and 
                           IsTargetVisible(aimPart) then
                            Target = v
                            MaxDistance = VectorDistance
                        end
                    end
                end
            end
        end
    end

    return Target
end

-- Function to simulate a mouse click for the triggerbot
local function TriggerClick()
    -- Simulate mouse press
    mouse1press()
    -- Small delay
    wait(0.01)
    -- Simulate mouse release
    mouse1release()
end

-- Enhanced prediction function with directional prediction
local function PredictPosition(targetPart)
    if not targetPart then return targetPart.Position end
    
    local velocity = targetPart.Velocity
    local position = targetPart.Position
    
    -- Create a directional prediction by splitting velocity into components
    -- Create a vector with only left/right (X and Z) components for horizontal movement
    local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
    
    -- Create a vector with only up/down (Y) component for vertical movement
    local verticalVelocity = Vector3.new(0, velocity.Y, 0)
    
    -- Apply different prediction amounts to different directions
    return position + (horizontalVelocity * _G.PredictionAmount) + (verticalVelocity * _G.AirPredictionAmount)
end

-- Check if a target is valid (still exists and alive)
local function IsTargetValid(target)
    return target and target.Character and 
           target.Character:FindFirstChild("Humanoid") and 
           target.Character.Humanoid.Health > 0 and
           target.Character:FindFirstChild(_G.AimPart) and
           not IsPlayerKnocked(target)
end

UserInputService.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = true
        
        -- If right-click is pressed again and we already have a locked target, reset it
        -- This allows selecting a new target
        if TargetLockEnabled then
            LockedTarget = nil
            TargetLockEnabled = false
        else
            -- Set the locked target when initially holding right-click
            LockedTarget = GetClosestPlayer()
            if LockedTarget then
                TargetLockEnabled = true
            end
        end
    end
    
    -- Add a key to toggle locking (E key in this case)
    if Input.KeyCode == Enum.KeyCode.E then
        LockedTarget = nil
        TargetLockEnabled = false
    end
    
    -- Toggle target strafing with B key
    if Input.KeyCode == Enum.KeyCode.B then
        _G.TargetStrafe = not _G.TargetStrafe
    end
    
    -- Toggle random position strafe with N key
    if Input.KeyCode == Enum.KeyCode.N then
        _G.RandomPosTargetStrafe = not _G.RandomPosTargetStrafe
    end
    
    -- Change strafe direction with M key
    if Input.KeyCode == Enum.KeyCode.M then
        _G.StrafeDirection = _G.StrafeDirection * -1 -- Flip direction
    end
    
    -- Toggle triggerbot with T key
    if Input.KeyCode == Enum.KeyCode.T then
        _G.TriggerbotEnabled = not _G.TriggerbotEnabled
        print("Triggerbot " .. (_G.TriggerbotEnabled and "Enabled" or "Disabled"))
    end
    
    -- Toggle wall check with V key
    if Input.KeyCode == Enum.KeyCode.V then
        _G.WallCheckEnabled = not _G.WallCheckEnabled
        print("Wall Check " .. (_G.WallCheckEnabled and "Enabled" or "Disabled"))
    end
end)

UserInputService.InputEnded:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = false
        -- We no longer reset LockedTarget here, as we want it to remain locked
        -- until explicitly toggled off or a new target is selected
    end
end)

RunService.RenderStepped:Connect(function()
    -- Update FOV circle
    FOVCircle.Position = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
    FOVCircle.Radius = _G.CircleRadius
    FOVCircle.Filled = _G.CircleFilled
    FOVCircle.Color = _G.CircleColor
    FOVCircle.Visible = _G.CircleVisible
    FOVCircle.Transparency = _G.CircleTransparency
    FOVCircle.NumSides = _G.CircleSides
    FOVCircle.Thickness = _G.CircleThickness

    -- Check if the locked target is still valid
    if LockedTarget and not IsTargetValid(LockedTarget) then
        LockedTarget = nil
        TargetLockEnabled = false
    end

    -- Aimbot logic
    if Holding == true and _G.AimbotEnabled == true then
        local target
        
        -- If we have a locked target and lock is enabled, use it
        if TargetLockEnabled and LockedTarget then
            target = LockedTarget
        else
            -- Otherwise get closest player (this allows switching targets)
            target = GetClosestPlayer()
            
            -- If we found a target and we're holding right-click, lock to it
            if target and Holding then
                LockedTarget = target
                TargetLockEnabled = true
            end
        end
        
        if target and target.Character and target.Character:FindFirstChild(_G.AimPart) then
            local targetPart = target.Character[_G.AimPart]
            local targetRootPart = target.Character.HumanoidRootPart
            
            -- Skip if wall check is enabled and target is not visible
            if _G.WallCheckEnabled and not IsTargetVisible(targetPart) then
                return
            end
            
            -- Apply direction-based prediction to the aim position
            local predictedPosition = PredictPosition(targetPart)
            
            -- If target strafing is enabled, move the character around the target
            if _G.TargetStrafe and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local strafePosition = CalculateStrafePosition(targetRootPart.Position)
                if strafePosition then
                    -- Move the player to the strafe position
                    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(strafePosition, targetRootPart.Position)
                end
            end
            
            -- Create a tween to smoothly move the camera to the predicted position
            TweenService:Create(Camera, TweenInfo.new(_G.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), 
                {CFrame = CFrame.new(Camera.CFrame.Position, predictedPosition)}):Play()
        end
    end
    
    -- Triggerbot logic
    if _G.TriggerbotEnabled then
        local currentTime = tick()
        
        -- Only check for player under mouse if enough time has passed since last trigger
        if currentTime - lastTriggerTime > _G.TriggerbotDelay then
            local playerUnderMouse = GetPlayerUnderMouse()
            
            if playerUnderMouse then
                -- Fire the triggerbot
                TriggerClick()
                lastTriggerTime = currentTime
            end
        end
    end
end)
