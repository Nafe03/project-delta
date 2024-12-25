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

-- Global Settings (Optimized for Da Hood)
_G.AimbotEnabled = true
_G.TeamCheck = false
_G.AimPart = "Head"  -- Head for Da Hood is most effective
_G.LockPart = "HumanoidRootPart"  -- For better prediction
_G.Sensitivity = 0.15  -- Smoothed for Da Hood's movement
_G.PredictionAmount = 0.135  -- Tuned for Da Hood's netcode
_G.JumpOffset = 0.2  -- Compensation for jumping
_G.UseAcceleration = true  -- Better prediction for Da Hood movement
_G.MaxAcceleration = 0.3  -- Limit prediction scaling
_G.SmartPrediction = true  -- Adapts to target movement
_G.AutoPrediction = true  -- Adjusts based on ping

-- FOV Settings
_G.UseCircle = true
_G.CircleRadius = 100  -- Smaller for better accuracy
_G.CircleColor = Color3.fromRGB(255, 0, 0)
_G.CircleTransparency = 0.5
_G.CircleFilled = false
_G.CircleVisible = true
_G.CircleThickness = 1
_G.CircleSides = 64

-- Visual Settings
_G.VisibleCheck = true
_G.ShowLockIndicator = true
_G.LockIndicatorColor = Color3.fromRGB(255, 0, 0)
_G.ShowPrediction = false  -- Visual prediction point

-- Lock Settings
_G.LockMode = true  -- Enhanced target locking
_G.Stickiness = 0.8  -- How "sticky" the aim is
_G.MaxLockRange = 350  -- Maximum lock range
_G.UnlockOnDeath = true

-- Setup FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
FOVCircle.Radius = _G.CircleRadius
FOVCircle.Color = _G.CircleColor
FOVCircle.Transparency = _G.CircleTransparency
FOVCircle.Filled = _G.CircleFilled
FOVCircle.Visible = _G.CircleVisible
FOVCircle.Thickness = _G.CircleThickness
FOVCircle.NumSides = _G.CircleSides

-- Variables
local CurrentTarget = nil
local LockIndicator = nil
local PredictionPoint = nil
local LastPing = 0
local LastPosition = nil
local MovementPattern = {}

-- Enhanced prediction system
local function CalculatePrediction(target)
    if not target or not target.Character then return nil end
    
    local humanoid = target.Character:FindFirstChild("Humanoid")
    local rootPart = target.Character:FindFirstChild(_G.LockPart)
    if not (humanoid and rootPart) then return nil end

    local velocity = rootPart.Velocity
    local position = rootPart.Position
    local prediction = position
    
    -- Calculate base prediction
    local basePrediction = _G.PredictionAmount
    
    -- Adjust for ping if AutoPrediction is enabled
    if _G.AutoPrediction then
        local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
        basePrediction = basePrediction * (1 + (ping / 1000))
    end
    
    -- Smart movement prediction
    if _G.SmartPrediction then
        -- Store movement pattern
        if LastPosition then
            local movement = (position - LastPosition).Magnitude
            table.insert(MovementPattern, movement)
            if #MovementPattern > 5 then
                table.remove(MovementPattern, 1)
            end
            
            -- Calculate average movement
            local avgMovement = 0
            for _, mov in ipairs(MovementPattern) do
                avgMovement = avgMovement + mov
            end
            avgMovement = avgMovement / #MovementPattern
            
            -- Adjust prediction based on movement pattern
            basePrediction = basePrediction * (1 + (avgMovement / 10))
        end
        LastPosition = position
    end
    
    -- Apply prediction
    prediction = prediction + (velocity * basePrediction)
    
    -- Jump compensation
    if humanoid:GetState() == Enum.HumanoidStateType.Jumping or 
       humanoid:GetState() == Enum.HumanoidStateType.Freefall then
        prediction = prediction + Vector3.new(0, _G.JumpOffset, 0)
    end
    
    return prediction
end

-- Improved target selection
local function GetClosestTarget()
    local closest = nil
    local shortestDistance = _G.MaxLockRange
    local mousePosition = UserInputService:GetMouseLocation()
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        -- Basic checks
        if not player.Character or not player.Character:FindFirstChild(_G.AimPart) then continue end
        if _G.TeamCheck and player.Team == LocalPlayer.Team then continue end
        
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end
        
        -- Position checks
        local aimPart = player.Character[_G.AimPart]
        local screenPoint = Camera:WorldToScreenPoint(aimPart.Position)
        if screenPoint.Z < 0 then continue end
        
        -- FOV check
        local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePosition).Magnitude
        if distance > _G.CircleRadius then continue end
        
        -- Visibility check
        if _G.VisibleCheck then
            local ray = Ray.new(Camera.CFrame.Position, (aimPart.Position - Camera.CFrame.Position).Unit * shortestDistance)
            local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, player.Character})
            if hit then continue end
        end
        
        -- Update closest target
        if distance < shortestDistance then
            shortestDistance = distance
            closest = player
        end
    end
    
    return closest
end

-- Main aimbot loop
RunService.RenderStepped:Connect(function()
    -- Update FOV Circle
    if _G.UseCircle then
        FOVCircle.Position = UserInputService:GetMouseLocation()
        FOVCircle.Visible = true
    end
    
    -- Main aimbot logic
    if Holding and _G.AimbotEnabled then
        -- Get or update target
        CurrentTarget = CurrentTarget or GetClosestTarget()
        
        if CurrentTarget and CurrentTarget.Character then
            local aimPart = CurrentTarget.Character:FindFirstChild(_G.AimPart)
            if aimPart then
                -- Calculate aim position
                local predictionPoint = CalculatePrediction(CurrentTarget)
                if predictionPoint then
                    -- Create camera CFrame
                    local targetCFrame = CFrame.new(Camera.CFrame.Position, predictionPoint)
                    
                    -- Apply smoothing
                    if _G.Sensitivity > 0 then
                        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 1 - _G.Sensitivity)
                    else
                        Camera.CFrame = targetCFrame
                    end
                end
            end
        end
    end
end)

-- Input handling
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = false
        CurrentTarget = nil
        LastPosition = nil
        MovementPattern = {}
    end
end)
