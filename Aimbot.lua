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
_G.Sensitivity = 0  -- Increased for smoother tracking
_G.StickyRadius = 3000  -- Radius for sticky aim effect
_G.PredictionAmount = 0
_G.AirPredictionAmount = 0
_G.BulletDropCompensation = 0
_G.DistanceAdjustment = true
_G.UseCircle = true
_G.WallCheck = false
_G.PredictionMultiplier = 1
_G.StickDuration = 0  -- How long aim stays "stuck" after releasing key

-- FOV Settings
_G.CircleSides = 64
_G.CircleColor = Color3.fromRGB(255, 255, 255)
_G.CircleTransparency = 0.7
_G.CircleRadius = 120
_G.CircleFilled = false
_G.CircleVisible = true
_G.CircleThickness = 1

-- Additional Sticky Aim Variables
local LastTargetTime = 0
local StickyTarget = nil
local IsSticky = false

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

-- Improved target finding with sticky effect
local function GetClosestPlayerToMouse()
    local Target = nil
    local ShortestDistance = math.huge
    local MousePosition = UserInputService:GetMouseLocation()
    
    -- Check if we should keep the sticky target
    if StickyTarget and StickyTarget.Character and time() - LastTargetTime < _G.StickDuration then
        local stickyPart = StickyTarget.Character:FindFirstChild(_G.AimPart)
        if stickyPart then
            local screenPoint = Camera:WorldToScreenPoint(stickyPart.Position)
            if screenPoint.Z > 0 then
                local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - MousePosition).Magnitude
                if distance <= _G.StickyRadius then
                    return StickyTarget
                end
            end
        end
    end

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

            if not IsWithinFOVCircle(screenPoint) then
                continue
            end

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

    if Target then
        StickyTarget = Target
        LastTargetTime = time()
        IsSticky = true
    end

    return Target
end

-- Enhanced prediction function
local function PredictTargetPosition(Target)
    local AimPart = Target.Character:FindFirstChild(_G.AimPart)
    if not AimPart then return AimPart.Position end

    local Velocity = AimPart.Velocity
    local predictedPosition = AimPart.Position
    local humanoid = Target.Character:FindFirstChild("Humanoid")
    
    if humanoid then
        local walkSpeed = humanoid.WalkSpeed
        local predictionAmount = _G.PredictionAmount
        
        -- Enhanced prediction for moving targets
        if walkSpeed > 0 then
            predictionAmount = predictionAmount * (1 + (walkSpeed / 50)) * _G.PredictionMultiplier
        end

        -- Different prediction for airborne targets
        if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
            predictedPosition = predictedPosition + (Velocity * _G.AirPredictionAmount)
        else
            predictedPosition = predictedPosition + (Velocity * predictionAmount)
        end

        -- Distance-based adjustment
        if _G.DistanceAdjustment then
            local distance = (AimPart.Position - Camera.CFrame.Position).Magnitude
            local distanceMultiplier = math.clamp(distance / 100, 0.1, 2)
            predictedPosition = predictedPosition + (Velocity * predictionAmount * distanceMultiplier)
        end
    end

    return predictedPosition
end

-- Modified input handling for sticky aim
UserInputService.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = true
        if _G.AimbotEnabled then
            CurrentTarget = GetClosestPlayerToMouse()
            if CurrentTarget then
                LastTargetTime = time()
                IsSticky = true
                -- Rest of your notification and highlight code...
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = false
        -- Don't immediately clear target for sticky effect
        wait(_G.StickDuration)
        if not Holding then
            CurrentTarget = nil
            IsSticky = false
            -- Clear highlights and boxes...
        end
    end
end)

-- Enhanced aimbot loop with smooth tracking
RunService.RenderStepped:Connect(function()
    if _G.UseCircle then
        FOVCircle.Position = UserInputService:GetMouseLocation()
        FOVCircle.Radius = _G.CircleRadius
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end

    if (Holding or IsSticky) and _G.AimbotEnabled and CurrentTarget then
        local character = CurrentTarget.Character
        if not character then
            CurrentTarget = nil
            IsSticky = false
            return
        end

        local humanoid = character:FindFirstChild("Humanoid")
        if not (humanoid and humanoid.Health > 0) then
            CurrentTarget = nil
            IsSticky = false
            return
        end

        local aimPart = character:FindFirstChild(_G.AimPart)
        if not aimPart then
            CurrentTarget = nil
            IsSticky = false
            return
        end

        local predictedPos = PredictTargetPosition(CurrentTarget)
        if predictedPos then
            local targetCFrame = CFrame.new(Camera.CFrame.Position, predictedPos)
            
            -- Smooth aim transition
            local smoothness = IsSticky and _G.Sensitivity * 1.5 or _G.Sensitivity
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 1 - smoothness)
        end
    end
end)
