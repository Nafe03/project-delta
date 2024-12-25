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

-- Da Hood Optimized Settings
_G.AimbotEnabled = true
_G.TeamCheck = false
_G.AimPart = "Head"           -- Head for accuracy
_G.AirAimPart = "UpperTorso"  -- Better for jumping targets
_G.Sensitivity = 0         -- Optimized for Da Hood recoil
_G.PredictionAmount = 0     -- Da Hood specific prediction
_G.AirPredictionAmount = 0  -- For jumping players
_G.SilentAim = false         -- Toggle for silent aim
_G.AutoPrediction = false     -- Auto-adjusts based on ping
_G.UseCircle = true
_G.WallCheck = false
_G.KnockdownCheck = false     -- Check if target is knocked
_G.AutoReload = false        -- Auto reload when empty
_G.AutoGunMod = false      -- Reduces recoil automatically

-- Advanced Da Hood Settings
_G.LockMode = "Regular"    -- Regular, Silent, or Rage
_G.UnlockOnKnocked = false -- Unlock when target gets knocked
_G.PredictVelocity = true -- Advanced velocity prediction
_G.SmartPart = false      -- Switches aim part based on situation
_G.JumpOffset = 0      -- Compensation for jumping
_G.RecoilControl = 0   -- Reduces recoil (0-1)

-- Visuals
_G.CircleSides = 64
_G.CircleColor = Color3.fromRGB(255, 0, 0)
_G.CircleTransparency = 0.7
_G.CircleRadius = 80  -- Optimized for Da Hood
_G.CircleFilled = false
_G.CircleVisible = true
_G.CircleThickness = 2

-- ESP Settings
_G.BoxEnabled = true
_G.BoxColor = Color3.fromRGB(255, 0, 0)
_G.BoxTransparency = 0.5
_G.BoxThickness = 2
_G.ShowHealth = true
_G.ShowDistance = true
_G.VisibleHighlight = true

-- Keybinds
_G.ToggleAimbotKey = Enum.KeyCode.Q
_G.TargetLockKey = Enum.KeyCode.E
_G.SilentAimToggle = Enum.KeyCode.X

-- Initialize FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
FOVCircle.Radius = _G.CircleRadius
FOVCircle.Filled = _G.CircleFilled
FOVCircle.Color = _G.CircleColor
FOVCircle.Visible = _G.CircleVisible
FOVCircle.Transparency = _G.CircleTransparency
FOVCircle.NumSides = _G.CircleSides
FOVCircle.Thickness = _G.CircleThickness

-- Target Variables
local CurrentTarget = nil
local CurrentHighlight = nil
local LastPrediction = Vector3.new()
local LastTargetPos = Vector3.new()
local PredictionVelocity = Vector3.new()

-- Da Hood Specific Functions
local function IsTargetKnocked(player)
    if not _G.KnockdownCheck then return false end
    local character = player.Character
    if not character then return true end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return true end
    
    -- Check Da Hood specific knocked states
    if humanoid.Health <= 0 then return true end
    if character:FindFirstChild("BodyEffects") then
        local bodyEffects = character.BodyEffects
        if bodyEffects:FindFirstChild("K.O") and bodyEffects["K.O"].Value then
            return true
        end
        if bodyEffects:FindFirstChild("Dead") and bodyEffects["Dead"].Value then
            return true
        end
    end
    
    return false
end

-- Enhanced Prediction System for Da Hood
local function CalculatePrediction(target, aimPart)
    if not target or not aimPart then return Vector3.new() end
    
    local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
    local velocity = aimPart.Velocity
    local distance = (aimPart.Position - Camera.CFrame.Position).Magnitude
    
    -- Base prediction
    local predictionAmount = _G.PredictionAmount
    
    -- Auto-adjust prediction based on ping
    if _G.AutoPrediction then
        predictionAmount = predictionAmount + (ping / 1000 * 2)
    end
    
    -- Calculate movement-based prediction
    local prediction = velocity * (predictionAmount / 10)
    
    -- Add jump prediction if target is in air
    local humanoid = target.Character:FindFirstChild("Humanoid")
    if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Jumping then
        prediction = prediction + Vector3.new(0, _G.JumpOffset * velocity.Y, 0)
    end
    
    -- Smooth prediction transition
    LastPrediction = LastPrediction:Lerp(prediction, 0.5)
    
    return LastPrediction
end

-- Smart Aim Part Selection for Da Hood
local function GetBestAimPart(target)
    if not _G.SmartPart then return target.Character:FindFirstChild(_G.AimPart) end
    
    local character = target.Character
    if not character then return nil end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return nil end
    
    -- Check if target is in air
    if humanoid:GetState() == Enum.HumanoidStateType.Jumping then
        return character:FindFirstChild(_G.AirAimPart)
    end
    
    -- Check distance for optimal aim part
    local distance = (character.HumanoidRootPart.Position - Camera.CFrame.Position).Magnitude
    if distance < 20 then
        return character:FindFirstChild("Head") -- Close range headshots
    end
    
    return character:FindFirstChild(_G.AimPart)
end

-- Enhanced target selection for Da Hood
local function GetClosestPlayerToMouse()
    local Target = nil
    local ShortestDistance = math.huge
    local MousePosition = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            -- Skip knocked players
            if IsTargetKnocked(player) then continue end
            
            -- Team check (if enabled)
            if _G.TeamCheck and player.Team == LocalPlayer.Team then continue end
            
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if not humanoid or humanoid.Health <= 0 then continue end
            
            local aimPart = GetBestAimPart(player)
            if not aimPart then continue end
            
            local screenPoint = Camera:WorldToScreenPoint(aimPart.Position)
            if screenPoint.Z < 0 then continue end
            
            -- FOV Check
            local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - MousePosition).Magnitude
            if distance > _G.CircleRadius then continue end
            
            -- Wall Check
            if _G.WallCheck and not IsTargetVisible(aimPart) then continue end
            
            if distance < ShortestDistance then
                ShortestDistance = distance
                Target = player
            end
        end
    end
    
    return Target
end

-- Input handling with Da Hood specific features
UserInputService.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = true
        if _G.AimbotEnabled then
            CurrentTarget = GetClosestPlayerToMouse()
            if CurrentTarget then
                Notify("Target Locked", CurrentTarget.Name, 1)
                if _G.VisibleHighlight then
                    if CurrentHighlight then CurrentHighlight:Destroy() end
                    CurrentHighlight = Instance.new("Highlight")
                    CurrentHighlight.FillColor = Color3.new(1, 0, 0)
                    CurrentHighlight.OutlineColor = Color3.new(1, 1, 0)
                    CurrentHighlight.Parent = CurrentTarget.Character
                end
            end
        end
    elseif Input.KeyCode == _G.ToggleAimbotKey then
        _G.AimbotEnabled = not _G.AimbotEnabled
        Notify("Aimbot", _G.AimbotEnabled and "Enabled" or "Disabled", 1)
    elseif Input.KeyCode == _G.SilentAimToggle then
        _G.SilentAim = not _G.SilentAim
        Notify("Silent Aim", _G.SilentAim and "Enabled" or "Disabled", 1)
    end
end)

-- Main loop with Da Hood optimizations
RunService.RenderStepped:Connect(function()
    -- Update FOV Circle
    if _G.UseCircle then
        FOVCircle.Position = UserInputService:GetMouseLocation()
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end

    if Holding and _G.AimbotEnabled and CurrentTarget then
        -- Check if target is still valid
        if IsTargetKnocked(CurrentTarget) then
            CurrentTarget = nil
            return
        end
        
        local character = CurrentTarget.Character
        if not character then
            CurrentTarget = nil
            return
        end
        
        local aimPart = GetBestAimPart(CurrentTarget)
        if not aimPart then
            CurrentTarget = nil
            return
        end
        
        -- Calculate aim position with prediction
        local predictedPosition = aimPart.Position + CalculatePrediction(CurrentTarget, aimPart)
        
        -- Apply aim
        if _G.LockMode == "Regular" then
            local targetCFrame = CFrame.new(Camera.CFrame.Position, predictedPosition)
            
            -- Apply smooth aim with recoil control
            if _G.Sensitivity > 0 then
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, (1 - _G.Sensitivity) * _G.RecoilControl)
            else
                Camera.CFrame = targetCFrame
            end
        end
    end
end)

-- Initialize
Notify("Da Hood Aimbot", "Loaded Successfully", 3)
