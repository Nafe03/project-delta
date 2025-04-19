local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Holding = false
local LockedTarget = nil
local TargetLockEnabled = false

_G.AimbotEnabled = true
_G.TeamCheck = false -- If set to true then the script would only lock your aim at enemy team members.
_G.AimPart = "Head" -- Where the aimbot script would lock at.
_G.Sensitivity = 0 -- How many seconds it takes for the aimbot script to officially lock onto the target's aimpart.
_G.PredictionAmount = 0 -- Amount of prediction (velocity multiplier) to use when aiming

_G.CircleSides = 64 -- How many sides the FOV circle would have.
_G.CircleColor = Color3.fromRGB(255, 255, 255) -- (RGB) Color that the FOV circle would appear as.
_G.CircleTransparency = 0.7 -- Transparency of the circle.
_G.CircleRadius = 80 -- The radius of the circle / FOV.
_G.CircleFilled = false -- Determines whether or not the circle is filled.
_G.CircleVisible = true -- Determines whether or not the circle is visible.
_G.CircleThickness = 0 -- The thickness of the circle.

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

local function GetClosestPlayer()
    local MaximumDistance = _G.CircleRadius
    local Target = nil

    for _, v in next, Players:GetPlayers() do
        if v.Name ~= LocalPlayer.Name then
            if _G.TeamCheck == true then
                if v.Team ~= LocalPlayer.Team then
                    if v.Character ~= nil then
                        if v.Character:FindFirstChild("HumanoidRootPart") ~= nil then
                            if v.Character:FindFirstChild("Humanoid") ~= nil and v.Character:FindFirstChild("Humanoid").Health ~= 0 then
                                local ScreenPoint = Camera:WorldToScreenPoint(v.Character:WaitForChild("HumanoidRootPart", math.huge).Position)
                                local VectorDistance = (Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2.new(ScreenPoint.X, ScreenPoint.Y)).Magnitude
                                
                                -- Check if target is in front of player
                                if VectorDistance < MaximumDistance and IsTargetInFront(v.Character.HumanoidRootPart.Position) then
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
                        if v.Character:FindFirstChild("Humanoid") ~= nil and v.Character:FindFirstChild("Humanoid").Health ~= 0 then
                            local ScreenPoint = Camera:WorldToScreenPoint(v.Character:WaitForChild("HumanoidRootPart", math.huge).Position)
                            local VectorDistance = (Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2.new(ScreenPoint.X, ScreenPoint.Y)).Magnitude
                            
                            -- Check if target is in front of player
                            if VectorDistance < MaximumDistance and IsTargetInFront(v.Character.HumanoidRootPart.Position) then
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

-- Prediction function
local function PredictPosition(targetPart)
    if not targetPart then return targetPart.Position end
    
    local velocity = targetPart.Velocity
    local position = targetPart.Position
    
    -- Apply prediction based on target's velocity and prediction amount
    return position + (velocity * _G.PredictionAmount)
end

-- Check if a target is valid (still exists and alive)
local function IsTargetValid(target)
    return target and target.Character and 
           target.Character:FindFirstChild("Humanoid") and 
           target.Character.Humanoid.Health > 0 and
           target.Character:FindFirstChild(_G.AimPart)
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
end)

UserInputService.InputEnded:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = false
        -- We no longer reset LockedTarget here, as we want it to remain locked
        -- until explicitly toggled off or a new target is selected
    end
end)

RunService.RenderStepped:Connect(function()
    FOVCircle.Position = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
    FOVCircle.Radius = _G.CircleRadius
    FOVCircle.Filled = _G.CircleFilled
    FOVCircle.Color = _G.CircleColor
    FOVCircle.Visible = _G.CircleVisible
    FOVCircle.Radius = _G.CircleRadius
    FOVCircle.Transparency = _G.CircleTransparency
    FOVCircle.NumSides = _G.CircleSides
    FOVCircle.Thickness = _G.CircleThickness

    -- Check if the locked target is still valid
    if LockedTarget and not IsTargetValid(LockedTarget) then
        LockedTarget = nil
        TargetLockEnabled = false
    end

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
            
            -- Apply prediction to the aim position
            local predictedPosition = PredictPosition(targetPart)
            
            -- Create a tween to smoothly move the camera to the predicted position
            TweenService:Create(Camera, TweenInfo.new(_G.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), 
                {CFrame = CFrame.new(Camera.CFrame.Position, predictedPosition)}):Play()
        end
    end
end)
