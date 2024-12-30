-- Services [previous services remain the same]
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

-- Enhanced Global Settings
_G.AimbotEnabled = true
_G.TeamCheck = false
_G.AimPart = "Head"
_G.AirAimPart = "LowerTorso"
_G.Sensitivity = 0
_G.PredictionAmount = 0.022   -- Increased base prediction
_G.AirPredictionAmount = 0.011 -- Enhanced air prediction
_G.BulletDropCompensation = 0.05
_G.DistanceAdjustment = true
_G.UseCircle = true
_G.WallCheck = false
_G.PredictionMultiplier = 2.5  -- Increased multiplier for more aggressive prediction
_G.FastTargetSpeedThreshold = 28  -- Lowered threshold to catch more fast movements
_G.DynamicSensitivity = true

-- Position tracking enhancement
local PositionHistory = {}
local VelocityHistory = {}
local HISTORY_LENGTH = 10
local ACCELERATION_WEIGHT = 1.35

-- Enhanced velocity calculation
local function UpdatePositionHistory(player)
    if not PositionHistory[player] then
        PositionHistory[player] = {}
        VelocityHistory[player] = {}
    end
    
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local currentPosition = character.HumanoidRootPart.Position
    table.insert(PositionHistory[player], 1, {
        position = currentPosition,
        timestamp = tick()
    })
    
    -- Maintain history length
    if #PositionHistory[player] > HISTORY_LENGTH then
        table.remove(PositionHistory[player])
    end
    
    -- Calculate and store velocity
    if #PositionHistory[player] >= 2 then
        local current = PositionHistory[player][1]
        local previous = PositionHistory[player][2]
        local velocity = (current.position - previous.position) / (current.timestamp - previous.timestamp)
        table.insert(VelocityHistory[player], 1, velocity)
        
        if #VelocityHistory[player] > HISTORY_LENGTH then
            table.remove(VelocityHistory[player])
        end
    end
end

-- Enhanced prediction calculation
local function CalculateAdvancedPrediction(player)
    if not VelocityHistory[player] or #VelocityHistory[player] < 2 then return Vector3.new(0, 0, 0) end
    
    local currentVelocity = VelocityHistory[player][1]
    local previousVelocity = VelocityHistory[player][2]
    
    -- Calculate acceleration
    local acceleration = (currentVelocity - previousVelocity)
    
    -- Calculate weighted prediction
    local basePrediction = currentVelocity
    local accelerationPrediction = acceleration * ACCELERATION_WEIGHT
    
    return basePrediction + accelerationPrediction
end

-- Enhanced target position prediction
local function PredictTargetPosition(Target)
    local AimPart = Target.Character:FindFirstChild(_G.AimPart)
    if not AimPart then return end
    
    UpdatePositionHistory(Target)
    local predictedVelocity = CalculateAdvancedPrediction(Target)
    local predictedPosition = AimPart.Position
    
    -- Get current speed
    local speed = predictedVelocity.Magnitude
    local isFastMoving = speed >= _G.FastTargetSpeedThreshold
    
    -- Calculate adaptive prediction multiplier
    local speedFactor = math.min(speed / 50, 2) -- Cap at 2x for very fast speeds
    local adaptivePredictionMultiplier = _G.PredictionMultiplier * (isFastMoving and speedFactor or 1)
    
    -- Apply horizontal prediction with enhanced multiplier
    predictedPosition = predictedPosition + Vector3.new(
        predictedVelocity.X * _G.PredictionAmount * adaptivePredictionMultiplier,
        0,
        predictedVelocity.Z * _G.PredictionAmount * adaptivePredictionMultiplier
    )
    
    return predictedPosition
end

-- Enhanced airborne prediction
local function PredictAirborneTargetPosition(Target)
    local AimPart = Target.Character:FindFirstChild(_G.AirAimPart)
    if not AimPart then return end
    
    UpdatePositionHistory(Target)
    local predictedVelocity = CalculateAdvancedPrediction(Target)
    local predictedPosition = AimPart.Position
    
    -- Enhanced air prediction with gravity compensation
    local airTime = _G.AirPredictionAmount
    local gravity = Vector3.new(0, -196.2, 0) -- Roblox gravity constant
    
    -- Calculate position with gravity
    predictedPosition = predictedPosition + 
        (predictedVelocity * airTime) +
        (0.5 * gravity * airTime * airTime)
    
    return predictedPosition
end

-- The rest of your existing code remains the same, including:
-- ResolveTargetPosition function
-- Input handling
-- RunService.RenderStepped connection
-- FOV Circle setup and updates

-- Enhanced target resolution
local function ResolveTargetPosition(Target)
    local humanoid = Target.Character:FindFirstChild("Humanoid")
    local aimPartName = (humanoid and humanoid:GetState() == Enum.HumanoidStateType.Freefall) and _G.AirAimPart or _G.AimPart
    local AimPart = Target.Character:FindFirstChild(aimPartName)
    if not AimPart then return end

    local PredictedPosition
    if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Freefall then
        PredictedPosition = PredictAirborneTargetPosition(Target)
    else
        PredictedPosition = PredictTargetPosition(Target)
    end

    local Distance = (Camera.CFrame.Position - PredictedPosition).Magnitude

    -- Enhanced bullet drop compensation
    if _G.BulletDropCompensation > 0 and _G.DistanceAdjustment then
        local dropCompensation = _G.BulletDropCompensation * math.pow(Distance/100, 1.5) -- Non-linear drop compensation
        PredictedPosition = PredictedPosition + Vector3.new(0, dropCompensation, 0)
    end

    return PredictedPosition
end
