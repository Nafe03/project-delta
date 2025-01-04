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

-- Enhanced prediction function with more accurate calculations
-- Enhanced prediction function for better CFrame exploit detection and compensation
-- Enhanced prediction function to handle CFrame exploits and speed hacks
local function PredictTargetPosition(Target)
    local character = Target.Character
    if not character then return end

    local AimPart = character:FindFirstChild(_G.AimPart)
    local AirAimPart = character:FindFirstChild(_G.AirAimPart)
    local HumanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local Humanoid = character:FindFirstChild("Humanoid")

    if not (AimPart and HumanoidRootPart and Humanoid) then return end

    -- Store historical positions for better exploit detection
    if not character:GetAttribute("PosHistory") then
        character:SetAttribute("PosHistory", {})
    end
    
    local posHistory = character:GetAttribute("PosHistory")
    table.insert(posHistory, HumanoidRootPart.Position)
    if #posHistory > 10 then
        table.remove(posHistory, 1)
    end
    character:SetAttribute("PosHistory", posHistory)

    -- Calculate velocity and acceleration
    local Velocity = HumanoidRootPart.Velocity
    local Speed = Velocity.Magnitude
    
    -- Detect teleports and irregular movements
    local isTeleporting = false
    local isSpeedHacking = false
    local isCFrameExploiting = false
    
    if #posHistory >= 2 then
        local currentPos = posHistory[#posHistory]
        local prevPos = posHistory[#posHistory - 1]
        local posDelta = (currentPos - prevPos).Magnitude
        
        -- Detect sudden position changes (teleports)
        if posDelta > 50 then
            isTeleporting = true
        end
        
        -- Detect speed hacks
        if Speed > 100 then
            isSpeedHacking = true
        end
        
        -- Detect CFrame exploitation
        if posDelta > (Speed * 2) then
            isCFrameExploiting = true
        end
    end

    -- Base position calculation
    local Position = AimPart.Position
    if _G.UseHeadOffset and _G.AimPart == "Head" then
        Position = Position + Vector3.new(0, _G.HeadVerticalOffset, 0)
    end

    -- Enhanced prediction multipliers based on exploit detection
    local predMultiplier = _G.PredictionMultiplier
    if isTeleporting then
        predMultiplier = predMultiplier * 2.5
    end
    if isSpeedHacking then
        predMultiplier = predMultiplier * 1.8
    end
    if isCFrameExploiting then
        predMultiplier = predMultiplier * 2.2
    end

    -- Calculate adaptive prediction
    local function CalculateAdaptivePrediction()
        local baseMultiplier = _G.PredictionAmount * predMultiplier
        local speedFactor = math.clamp(Speed / 30, 0.5, 3)
        
        local predictedOffset = Vector3.new(
            Velocity.X * baseMultiplier * speedFactor,
            Velocity.Y * baseMultiplier * speedFactor * 0.7,
            Velocity.Z * baseMultiplier * speedFactor
        )

        -- Additional compensation for exploits
        if isCFrameExploiting or isSpeedHacking then
            local movementDirection = Velocity.Unit
            local extrapolationDistance = Speed * 0.1 * predMultiplier
            predictedOffset = predictedOffset + (movementDirection * extrapolationDistance)
        end

        return predictedOffset
    end

    -- Apply prediction
    local predictedOffset = CalculateAdaptivePrediction()
    local predictedPosition = Position + predictedOffset

    -- Enhanced compensation for high-speed vertical movement
    if math.abs(Velocity.Y) > 40 then
        local verticalCompensation = Vector3.new(
            0,
            Velocity.Y * _G.PredictionAmount * 1.5,
            0
        )
        predictedPosition = predictedPosition + verticalCompensation
    end

    -- Distance-based adjustments
    if _G.DistanceAdjustment then
        local distance = (Camera.CFrame.Position - predictedPosition).Magnitude
        local distanceMultiplier = math.clamp(distance / 100, 0.8, 2.5)
        predictedPosition = Position + (predictedOffset * distanceMultiplier)
    end

    -- Final smoothing for more stable prediction
    if character:GetAttribute("LastPredicted") then
        local lastPredicted = character:GetAttribute("LastPredicted")
        local smoothFactor = isCFrameExploiting and 0.7 or 0.8
        predictedPosition = Vector3.new(
            lastPredicted.X + (predictedPosition.X - lastPredicted.X) * smoothFactor,
            lastPredicted.Y + (predictedPosition.Y - lastPredicted.Y) * smoothFactor,
            lastPredicted.Z + (predictedPosition.Z - lastPredicted.Z) * smoothFactor
        )
    end

    character:SetAttribute("LastPredicted", predictedPosition)
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
