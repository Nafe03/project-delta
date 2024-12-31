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
_G.UseCircle = true
_G.WallCheck = false
_G.PredictionMultiplier = 1.5
_G.FastTargetSpeedThreshold = 35
_G.DynamicSensitivity = true
_G.DamageAmount = 0

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
local function PredictTargetPosition(Target)
    local character = Target.Character
    if not character then return end

    local AimPart = character:FindFirstChild(_G.AimPart)
    local AirAimPart = character:FindFirstChild(_G.AirAimPart)
    local HumanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local Humanoid = character:FindFirstChild("Humanoid")

    if not (AimPart and HumanoidRootPart and Humanoid) then return end

    -- Use AirAimPart if the target is airborne
    if IsPlayerAirborne(Target) and AirAimPart then
        AimPart = AirAimPart
    end

    local Velocity = HumanoidRootPart.Velocity
    local Position = AimPart.Position
    local Speed = Velocity.Magnitude

    -- Detect potential exploiters/flyers
    local function DetectAbnormalMovement()
        local isFlying = false
        local isExploiting = false

        local groundHeight = workspace:Raycast(Position, Vector3.new(0, -1000, 0))
        local heightFromGround = groundHeight and (Position.Y - groundHeight.Position.Y) or 0

        local timeInAir = 0
        if Humanoid:GetState() == Enum.HumanoidStateType.Freefall then
            timeInAir = timeInAir + 1
        else
            timeInAir = 0
        end

        if heightFromGround > 20 and timeInAir > 50 then
            isFlying = true
        end

        if Speed > 100 then
            isExploiting = true
        end

        return isFlying, isExploiting
    end

    local isFlying, isExploiting = DetectAbnormalMovement()

    if isFlying or isExploiting then
        local flyPredictionMultiplier = 2.5
        local verticalOffset = Vector3.new(
            Velocity.X * _G.PredictionAmount * flyPredictionMultiplier,
            Velocity.Y * _G.PredictionAmount * flyPredictionMultiplier,
            Velocity.Z * _G.PredictionAmount * flyPredictionMultiplier
        )

        if isFlying then
            verticalOffset = verticalOffset + Vector3.new(
                0,
                Velocity.Y * _G.AirPredictionAmount * 3,
                0
            )
        end

        return Position + verticalOffset
    end

    local function CalculateBaseOffset()
        local baseMultiplier = _G.PredictionAmount
        local speedBasedMultiplier = math.clamp(Speed / 50, 0.1, 2)

        return Vector3.new(
            Velocity.X * baseMultiplier * speedBasedMultiplier,
            Velocity.Y * baseMultiplier * speedBasedMultiplier * 0.5,
            Velocity.Z * baseMultiplier * speedBasedMultiplier
        )
    end

    local function AnalyzeMovementPattern()
        return {
            isZigZagging = math.abs(Velocity.X) > 15 and math.abs(Velocity.Z) > 15,
            isJumping = Humanoid:GetState() == Enum.HumanoidStateType.Jumping,
            isFalling = Humanoid:GetState() == Enum.HumanoidStateType.Freefall,
            isRunning = Speed > 15
        }
    end

    local function CalculateAdaptivePrediction()
        local baseOffset = CalculateBaseOffset()
        local pattern = AnalyzeMovementPattern()
        local finalOffset = baseOffset

        if pattern.isZigZagging then
            finalOffset = finalOffset * 1.2
        end

        if pattern.isJumping or pattern.isFalling then
            AimPart = character:FindFirstChild(_G.AirAimPart) or AimPart
            local verticalMultiplier = pattern.isJumping and 1.3 or 0.7
            finalOffset = finalOffset + Vector3.new(
                0,
                Velocity.Y * _G.AirPredictionAmount * verticalMultiplier,
                0
            )
        end

        local distanceToTarget = (Camera.CFrame.Position - Position).Magnitude
        local distanceMultiplier = math.clamp(distanceToTarget / 100, 0.5, 2)
        finalOffset = finalOffset * distanceMultiplier

        return finalOffset
    end

    local predictedOffset = CalculateAdaptivePrediction()
    local predictedPosition = Position + predictedOffset

    -- Bullet drop compensation
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
                    local currentCFrame = Camera.CFrame
                    local targetCFrame = CFrame.new(currentCFrame.Position, aimPosition)
                    
                    -- Use appropriate smoothness based on mode
                    local lerpAmount = _G.LegitAimbot and _G.LegitSensitivity or _G.Sensitivity
                    Camera.CFrame = currentCFrame:Lerp(targetCFrame, lerpAmount)
                end
            else
                CurrentTarget = nil
            end
        end
    end
end)
