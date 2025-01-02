local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Holding = false

-- Enhanced Settings
_G.AimbotEnabled = true
_G.RageMode = false
_G.SilentAim = true
_G.AutoShoot = false
_G.AutoReload = false
_G.TeamCheck = false
_G.AimPart = "Head"
_G.FallbackAimPart = "UpperTorso"
_G.TargetPriority = "Distance" -- Distance, Health, or Threat
_G.RageSensitivity = 1
_G.LegitSensitivity = 0.15
_G.RagePredictionMultiplier = 2.5
_G.LegitPredictionMultiplier = 1.2
_G.MaxPredictionDistance = 150
_G.BulletDropCompensation = 0.02
_G.WallPenetration = true
_G.AutoWallBang = true
_G.MultiPoint = true
_G.HeadSafety = true
_G.AntiAimViewer = true
_G.LegitSmoothing = true
_G.RageHitChance = 100
_G.LegitHitChance = 65

-- Advanced FOV Settings
_G.DynamicFOV = true
_G.BaseFOV = 120
_G.MinFOV = 60
_G.MaxFOV = 180
_G.FOVSpeed = 2

-- Anti-Aim Settings
_G.AntiAim = false
_G.AAType = "Spin" -- Spin, Jitter, Random
_G.AASpeed = 50
_G.Desync = true
_G.DesyncPower = 15

-- Visuals
_G.ShowTargetInfo = true
_G.ShowPrediction = true
_G.ShowHitboxes = true
_G.RainbowMode = false

local function CreateHitboxModel(character)
    if not _G.ShowHitboxes then return end
    local model = Instance.new("Model")
    model.Name = "HitboxModel"
    
    local parts = {"Head", "UpperTorso", "LowerTorso"}
    for _, partName in ipairs(parts) do
        local part = character:FindFirstChild(partName)
        if part then
            local box = Instance.new("SelectionBox")
            box.Name = partName .. "Hitbox"
            box.Adornee = part
            box.Color3 = Color3.new(1, 0, 0)
            box.Parent = model
        end
    end
    
    model.Parent = character
end

local function ApplyAntiAim()
    if not _G.AntiAim or not LocalPlayer.Character then return end
    
    local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    if _G.AAType == "Spin" then
        humanoidRootPart.CFrame = humanoidRootPart.CFrame * CFrame.Angles(0, math.rad(_G.AASpeed), 0)
    elseif _G.AAType == "Jitter" then
        humanoidRootPart.CFrame = humanoidRootPart.CFrame * CFrame.Angles(0, math.rad(math.random(-180, 180)), 0)
    end
    
    if _G.Desync then
        local desyncOffset = Vector3.new(
            math.random(-_G.DesyncPower, _G.DesyncPower),
            0,
            math.random(-_G.DesyncPower, _G.DesyncPower)
        )
        humanoidRootPart.CFrame = humanoidRootPart.CFrame + desyncOffset
    end
end

local function UpdateFOV()
    if not _G.DynamicFOV then return _G.BaseFOV end
    
    local currentTarget = GetClosestPlayerToMouse()
    if not currentTarget then return _G.BaseFOV end
    
    local distance = (LocalPlayer.Character.HumanoidRootPart.Position - currentTarget.Character.HumanoidRootPart.Position).Magnitude
    local dynamicFOV = math.clamp(_G.BaseFOV * (50 / distance), _G.MinFOV, _G.MaxFOV)
    
    return dynamicFOV
end

local function PredictTargetPosition(target)
    if not target or not target.Character then return nil end
    
    local character = target.Character
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end
    
    local velocity = humanoidRootPart.Velocity
    local position = humanoidRootPart.Position
    local distance = (LocalPlayer.Character.HumanoidRootPart.Position - position).Magnitude
    
    local predMultiplier = _G.RageMode and _G.RagePredictionMultiplier or _G.LegitPredictionMultiplier
    local timeToTarget = distance / 1000
    
    local prediction = velocity * timeToTarget * predMultiplier
    
    if distance > _G.MaxPredictionDistance then
        prediction = prediction * (_G.MaxPredictionDistance / distance)
    end
    
    if _G.BulletDropCompensation > 0 then
        prediction = prediction + Vector3.new(0, -distance * _G.BulletDropCompensation, 0)
    end
    
    return position + prediction
end

local function GetHitChance()
    local chance = _G.RageMode and _G.RageHitChance or _G.LegitHitChance
    return math.random(1, 100) <= chance
end

local function AutoWall(origin, target)
    if not _G.WallPenetration then return false end
    
    local direction = (target - origin).Unit
    local distance = (target - origin).Magnitude
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    
    local result = Workspace:Raycast(origin, direction * distance, raycastParams)
    if result then
        local material = result.Material
        local penetratable = {
            [Enum.Material.Wood] = true,
            [Enum.Material.WoodPlanks] = true,
            [Enum.Material.Glass] = true,
            [Enum.Material.Plastic] = true
        }
        
        return penetratable[material] or false
    end
    
    return true
end

RunService.RenderStepped:Connect(function()
    if _G.AimbotEnabled then
        local target = GetClosestPlayerToMouse()
        if target and Holding then
            local aimPosition = PredictTargetPosition(target)
            if aimPosition and GetHitChance() then
                if _G.RageMode then
                    Camera.CFrame = CFrame.new(Camera.CFrame.Position, aimPosition)
                else
                    local currentCFrame = Camera.CFrame
                    local targetCFrame = CFrame.new(currentCFrame.Position, aimPosition)
                    local smoothing = _G.LegitSmoothing and _G.LegitSensitivity or 1
                    Camera.CFrame = currentCFrame:Lerp(targetCFrame, smoothing)
                end
                
                if _G.AutoShoot and AutoWall(Camera.CFrame.Position, aimPosition) then
                    mouse1click()
                end
            end
        end
    end
    
    ApplyAntiAim()
end)
