-- Services
local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

-- Local Player
local LocalPlayer = Players.LocalPlayer
local Holding = false
local CurrentTarget = nil
local LastAimPosition = nil

-- Global Settings
_G.AimbotEnabled = false    -- Rage mode
_G.LegitAimbot = false     -- Legit mode
_G.TeamCheck = false
_G.AimPart = "Head"        -- Default aim part
_G.AirAimPart = "HumanoidRootPart"  -- Better for jumping targets
_G.Sensitivity = 0        -- Rage mode instant snap
_G.LegitSensitivity = 0  -- Smooth aim for legit
_G.PredictionAmount = 0  -- Optimized for Da Hood
_G.AirPredictionAmount = 0
_G.CircleRadius = 80      -- Smaller FOV for accuracy
_G.WallCheck = true
_G.UseCircle = true
_G.VisibleHighlight = false

-- FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
FOVCircle.Radius = _G.CircleRadius
FOVCircle.Filled = false
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Visible = true
FOVCircle.Transparency = 0.7
FOVCircle.NumSides = 64
FOVCircle.Thickness = 1

local function Notify(title, text)
    StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 2})
end

local function IsPlayerKnocked(player)
    local character = player.Character
    if not character then return true end
    
    local bodyEffects = character:FindFirstChild("BodyEffects")
    if bodyEffects then
        local KO = bodyEffects:FindFirstChild("K.O")
        local Dead = bodyEffects:FindFirstChild("Dead")
        return (KO and KO.Value) or (Dead and Dead.Value)
    end
    return false
end

local function IsTargetVisible(targetPart)
    if not _G.WallCheck then return true end
    
    local ray = Ray.new(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position).Unit * 300)
    local ignoreList = {LocalPlayer.Character, targetPart.Parent}
    local hit = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
    return hit == nil
end

local function GetClosestPlayerToMouse()
    local Target = nil
    local ShortestDistance = math.huge
    local MousePos = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        local character = player.Character
        if not character then continue end
        
        if IsPlayerKnocked(player) then continue end
        
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end
        
        local part = character:FindFirstChild(_G.AimPart)
        if not part then continue end
        
        local screenPoint = Camera:WorldToScreenPoint(part.Position)
        if screenPoint.Z < 0 then continue end
        
        local distance = (Vector2.new(MousePos.X, MousePos.Y) - Vector2.new(screenPoint.X, screenPoint.Y)).Magnitude
        if distance > _G.CircleRadius then continue end
        
        if not IsTargetVisible(part) then continue end
        
        if distance < ShortestDistance then
            ShortestDistance = distance
            Target = player
        end
    end
    
    return Target
end

local function PredictPosition(target)
    local part = target.Character:FindFirstChild(_G.AimPart)
    if not part then return nil end
    
    local humanoid = target.Character:FindFirstChild("Humanoid")
    if not humanoid then return part.Position end
    
    local velocity = target.Character.HumanoidRootPart.Velocity
    local prediction
    
    if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
        prediction = Vector3.new(
            velocity.X * _G.PredictionAmount,
            velocity.Y * _G.AirPredictionAmount,
            velocity.Z * _G.PredictionAmount
        )
    else
        prediction = Vector3.new(
            velocity.X * _G.PredictionAmount,
            0,
            velocity.Z * _G.PredictionAmount
        )
    end
    
    return part.Position + prediction
end

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = true
        if _G.AimbotEnabled or _G.LegitAimbot then
            CurrentTarget = GetClosestPlayerToMouse()
            if CurrentTarget then
                Notify("Locked", CurrentTarget.Name)
            end
        end
    elseif input.KeyCode == Enum.KeyCode.Q then
        _G.AimbotEnabled = not _G.AimbotEnabled
        if _G.AimbotEnabled then _G.LegitAimbot = false end
        Notify("Rage", _G.AimbotEnabled and "On" or "Off")
    elseif input.KeyCode == Enum.KeyCode.V then
        _G.LegitAimbot = not _G.LegitAimbot
        if _G.LegitAimbot then _G.AimbotEnabled = false end
        Notify("Legit", _G.LegitAimbot and "On" or "Off")
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = false
        CurrentTarget = nil
        LastAimPosition = nil
    end
end)

RunService.RenderStepped:Connect(function()
    FOVCircle.Position = UserInputService:GetMouseLocation()
    
    if Holding and CurrentTarget and ((_G.AimbotEnabled or _G.LegitAimbot)) then
        local character = CurrentTarget.Character
        if not character then return end
        
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 or IsPlayerKnocked(CurrentTarget) then
            CurrentTarget = nil
            return
        end
        
        local aimPosition = PredictPosition(CurrentTarget)
        if not aimPosition then return end
        
        local sensitivity = _G.LegitAimbot and _G.LegitSensitivity or _G.Sensitivity
        local currentCFrame = Camera.CFrame
        local targetCFrame = CFrame.new(currentCFrame.Position, aimPosition)
        
        Camera.CFrame = currentCFrame:Lerp(targetCFrame, sensitivity)
    end
end)
