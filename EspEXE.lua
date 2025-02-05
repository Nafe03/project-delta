-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

-- Local Player Info
local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ESP Settings
_G.ESPEnabled = true
_G.HealthESPEnabled = true
_G.NameESPEnabled = true
_G.BoxESPEnabled = true
_G.SkeletonESP = false
_G.TracersEnabled = true
_G.DistanceESPEnabled = true
_G.ShowAmmo = true
_G.ShowTeam = true -- Show ESP for teammates
_G.MaxDistance = 500 -- Maximum distance for ESP (in studs)
_G.FadeDistance = 300 -- Distance at which ESP starts fading
_G.TeamColor = Color3.fromRGB(0, 255, 0) -- Color for teammates
_G.EnemyColor = Color3.fromRGB(255, 0, 0) -- Color for enemies
_G.BoxColor = Color3.fromRGB(255, 255, 255)
_G.NameColor = Color3.fromRGB(255, 255, 255)
_G.AmmoColor = Color3.fromRGB(255, 255, 255)
_G.SkeletonColor = Color3.fromRGB(255, 255, 255)
_G.TracerColor = Color3.fromRGB(255, 255, 255)

-- Active ESP Storage
local activeESP = {}

-- Function to Create Name ESP
local function CreateNameESP(player)
    local nameTag = Drawing.new("Text")
    nameTag.Size = 20
    nameTag.Center = true
    nameTag.Outline = true
    nameTag.Color = _G.NameColor
    nameTag.Font = 3
    nameTag.Visible = false
    return nameTag
end

-- Function to Create Skeleton ESP
local function CreateSkeletonESP()
    local skeletonLines = {}
    for i = 1, 14 do
        local line = Drawing.new("Line")
        line.Thickness = 1
        line.Color = _G.SkeletonColor
        line.Visible = false
        table.insert(skeletonLines, line)
    end
    return skeletonLines
end

-- Function to Get Current Ammo of a Player
local function GetPlayerAmmo(player)
    local backpack = player:FindFirstChild("Backpack")
    local character = player.Character
    
    -- Check equipped tool first
    if character then
        local tool = character:FindFirstChildOfClass("Tool")
        if tool and tool:FindFirstChild("Script") and tool.Script:FindFirstChild("Ammo") then
            return tool.Script.Ammo.Value
        end
    end
    
    -- Then check backpack
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and tool:FindFirstChild("Script") and tool.Script:FindFirstChild("Ammo") then
                return tool.Script.Ammo.Value
            end
        end
    end
    return "N/A"
end

-- Function to Create Ammo ESP
local function CreateAmmoESP()
    local ammoTag = Drawing.new("Text")
    ammoTag.Size = 18
    ammoTag.Center = true
    ammoTag.Outline = true
    ammoTag.Color = _G.AmmoColor
    ammoTag.Font = 3
    ammoTag.Visible = false
    return ammoTag
end

-- Function to Create Tracer
local function CreateTracer()
    local tracer = Drawing.new("Line")
    tracer.Thickness = 1
    tracer.Color = _G.TracerColor
    tracer.Visible = false
    return tracer
end

-- Function to Update Skeleton ESP
local function UpdateSkeletonESP(skeletonLines, character)
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- Get all necessary body parts
    local head = character:FindFirstChild("Head")
    local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    local leftArm = character:FindFirstChild("LeftUpperArm") or character:FindFirstChild("Left Arm")
    local rightArm = character:FindFirstChild("RightUpperArm") or character:FindFirstChild("Right Arm")
    local leftLeg = character:FindFirstChild("LeftUpperLeg") or character:FindFirstChild("Left Leg")
    local rightLeg = character:FindFirstChild("RightUpperLeg") or character:FindFirstChild("Right Leg")

    if not (head and torso and leftArm and rightArm and leftLeg and rightLeg) then return end

    -- Convert world positions to screen positions
    local function getScreenPoint(part)
        if part then
            local screenPoint, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                return Vector2.new(screenPoint.X, screenPoint.Y)
            end
        end
        return nil
    end

    local screenPoints = {
        head = getScreenPoint(head),
        torso = getScreenPoint(torso),
        leftArm = getScreenPoint(leftArm),
        rightArm = getScreenPoint(rightArm),
        leftLeg = getScreenPoint(leftLeg),
        rightLeg = getScreenPoint(rightLeg)
    }

    -- Draw skeleton lines
    if screenPoints.head and screenPoints.torso then
        -- Head to Torso
        skeletonLines[1].From = screenPoints.head
        skeletonLines[1].To = screenPoints.torso
        skeletonLines[1].Color = _G.SkeletonColor

        -- Torso to Left Arm
        if screenPoints.leftArm then
            skeletonLines[2].From = screenPoints.torso
            skeletonLines[2].To = screenPoints.leftArm
            skeletonLines[2].Color = _G.SkeletonColor
        end

        -- Torso to Right Arm
        if screenPoints.rightArm then
            skeletonLines[3].From = screenPoints.torso
            skeletonLines[3].To = screenPoints.rightArm
            skeletonLines[3].Color = _G.SkeletonColor
        end

        -- Torso to Left Leg
        if screenPoints.leftLeg then
            skeletonLines[4].From = screenPoints.torso
            skeletonLines[4].To = screenPoints.leftLeg
            skeletonLines[4].Color = _G.SkeletonColor
        end

        -- Torso to Right Leg
        if screenPoints.rightLeg then
            skeletonLines[5].From = screenPoints.torso
            skeletonLines[5].To = screenPoints.rightLeg
            skeletonLines[5].Color = _G.SkeletonColor
        end

        -- Left Arm to Left Hand (if available)
        local leftHand = character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm")
        if leftHand then
            local leftHandPoint = getScreenPoint(leftHand)
            if leftHandPoint and screenPoints.leftArm then
                skeletonLines[6].From = screenPoints.leftArm
                skeletonLines[6].To = leftHandPoint
                skeletonLines[6].Color = _G.SkeletonColor
            end
        end

        -- Right Arm to Right Hand (if available)
        local rightHand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
        if rightHand then
            local rightHandPoint = getScreenPoint(rightHand)
            if rightHandPoint and screenPoints.rightArm then
                skeletonLines[7].From = screenPoints.rightArm
                skeletonLines[7].To = rightHandPoint
                skeletonLines[7].Color = _G.SkeletonColor
            end
        end

        -- Left Leg to Left Foot (if available)
        local leftFoot = character:FindFirstChild("LeftFoot") or character:FindFirstChild("Left Leg")
        if leftFoot then
            local leftFootPoint = getScreenPoint(leftFoot)
            if leftFootPoint and screenPoints.leftLeg then
                skeletonLines[8].From = screenPoints.leftLeg
                skeletonLines[8].To = leftFootPoint
                skeletonLines[8].Color = _G.SkeletonColor
            end
        end

        -- Right Leg to Right Foot (if available)
        local rightFoot = character:FindFirstChild("RightFoot") or character:FindFirstChild("Right Leg")
        if rightFoot then
            local rightFootPoint = getScreenPoint(rightFoot)
            if rightFootPoint and screenPoints.rightLeg then
                skeletonLines[9].From = screenPoints.rightLeg
                skeletonLines[9].To = rightFootPoint
                skeletonLines[9].Color = _G.SkeletonColor
            end
        end

        -- Make all lines visible
        for _, line in ipairs(skeletonLines) do
            line.Visible = _G.SkeletonESP
        end
    else
        -- Hide all lines if not on screen
        for _, line in ipairs(skeletonLines) do
            line.Visible = false
        end
    end
end

-- Function to Draw ESP Box with Health, Armor, and Ammo
local function DrawESPBoxWithHealthAndArmor(player)
    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart", 5)
    if not rootPart then return end

    -- Check if the player is within the maximum distance
    local distance = (Player.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
    if distance > _G.MaxDistance then
        return
    end

    -- Create Box
    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Filled = false
    box.Color = _G.BoxColor
    box.Visible = false

    -- Create Health Bar
    local healthBar = Drawing.new("Square")
    healthBar.Thickness = 1
    healthBar.Filled = true
    healthBar.Color = Color3.fromRGB(0, 255, 0)
    healthBar.Visible = false

    -- Create Name Tag
    local nameTag = CreateNameESP(player)
    
    -- Create Ammo Tag
    local ammoTag = CreateAmmoESP()

    -- Create Tracer
    local tracer = CreateTracer()

    -- Create Skeleton ESP
    local skeletonLines = CreateSkeletonESP()

    local connection
    connection = RunService.Heartbeat:Connect(function()
        if character and character.Parent and rootPart then
            local rootPos = rootPart.Position
            local screenPos, onScreen = Camera:WorldToViewportPoint(rootPos)

            -- Check distance again
            local distance = (Player.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
            if distance > _G.MaxDistance then
                box.Visible = false
                healthBar.Visible = false
                nameTag.Visible = false
                ammoTag.Visible = false
                tracer.Visible = false
                for _, line in ipairs(skeletonLines) do
                    line.Visible = false
                end
                return
            end

            if onScreen then
                local size = Vector2.new(3700 / screenPos.Z, 4700 / screenPos.Z)
                local boxPosition = Vector2.new(screenPos.X - size.X / 2, screenPos.Y - size.Y / 2)

                -- Update Box
                box.Size = size
                box.Position = boxPosition
                box.Color = _G.BoxColor
                box.Visible = _G.BoxESPEnabled

                -- Update Name Tag
                nameTag.Position = Vector2.new(screenPos.X, boxPosition.Y - 20)
                nameTag.Text = player.Name
                nameTag.Color = _G.NameColor
                nameTag.Visible = _G.NameESPEnabled
                
                -- Update Ammo Tag
                ammoTag.Position = Vector2.new(screenPos.X, boxPosition.Y + size.Y + 5)
                ammoTag.Text = "Ammo: " .. tostring(GetPlayerAmmo(player))
                ammoTag.Color = _G.AmmoColor
                ammoTag.Visible = _G.ShowAmmo

                -- Update Health Bar
                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid then
                    local healthFraction = humanoid.Health / humanoid.MaxHealth
                    healthBar.Size = Vector2.new(5, size.Y * healthFraction)
                    healthBar.Position = Vector2.new(boxPosition.X - 9, boxPosition.Y + size.Y * (1 - healthFraction))
                    healthBar.Color = Color3.fromRGB(255 * (1 - healthFraction), 255 * healthFraction, 0)
                    healthBar.Visible = _G.HealthESPEnabled
                else
                    healthBar.Visible = false
                end

                -- Update Tracer
                tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                tracer.Color = _G.TracerColor
                tracer.Visible = _G.TracersEnabled

                -- Update Skeleton ESP
                UpdateSkeletonESP(skeletonLines, character)
            else
                box.Visible = false
                healthBar.Visible = false
                nameTag.Visible = false
                ammoTag.Visible = false
                tracer.Visible = false
                for _, line in ipairs(skeletonLines) do
                    line.Visible = false
                end
            end
        else
            box.Visible = false
            healthBar.Visible = false
            nameTag.Visible = false
            ammoTag.Visible = false
            tracer.Visible = false
            for _, line in ipairs(skeletonLines) do
                line.Visible = false
            end
        end
    end)

    -- Handle Character Removal
    character.AncestryChanged:Connect(function(_, parent)
        if not parent then
            box.Visible = false
            healthBar.Visible = false
            nameTag.Visible = false
            ammoTag.Visible = false
            tracer.Visible = false
            for _, line in ipairs(skeletonLines) do
                line.Visible = false
                line:Remove()
            end
            if connection then
                connection:Disconnect()
            end
            box:Remove()
            healthBar:Remove()
            nameTag:Remove()
            ammoTag:Remove()
            tracer:Remove()
        end
    end)

    return box, healthBar, nameTag, skeletonLines, ammoTag, tracer, connection
end

-- Apply ESP to Player
local function applyESP(player)
    if not player or player == Player then return end -- Don't apply to nil or local player
    
    -- Clean up existing ESP if any
    if activeESP[player] then
        if activeESP[player].box then activeESP[player].box:Remove() end
        if activeESP[player].healthBar then activeESP[player].healthBar:Remove() end
        if activeESP[player].nameTag then activeESP[player].nameTag:Remove() end
        if activeESP[player].ammoTag then activeESP[player].ammoTag:Remove() end
        if activeESP[player].tracer then activeESP[player].tracer:Remove() end
        if activeESP[player].skeletonLines then
            for _, line in ipairs(activeESP[player].skeletonLines) do
                line:Remove()
            end
        end
        if activeESP[player].updateConnection then
            activeESP[player].updateConnection:Disconnect()
        end
        activeESP[player] = nil
    end

    -- Wait for character
    local character = player.Character
    if not character then
        player.CharacterAdded:Wait()
        character = player.Character
    end

    -- Create ESP elements
    local box, healthBar, nameTag, skeletonLines, ammoTag, tracer, connection = DrawESPBoxWithHealthAndArmor(player)

    -- Store ESP objects for cleanup
    activeESP[player] = {
        box = box,
        healthBar = healthBar,
        nameTag = nameTag,
        skeletonLines = skeletonLines,
        ammoTag = ammoTag,
        tracer = tracer,
        updateConnection = connection,
        characterConnection = nil
    }

    -- Handle character changes
    activeESP[player].characterConnection = player.CharacterAdded:Connect(function()
        -- Remove old ESP
        if activeESP[player] then
            if activeESP[player].box then activeESP[player].box:Remove() end
            if activeESP[player].healthBar then activeESP[player].healthBar:Remove() end
            if activeESP[player].nameTag then activeESP[player].nameTag:Remove() end
            if activeESP[player].ammoTag then activeESP[player].ammoTag:Remove() end
            if activeESP[player].tracer then activeESP[player].tracer:Remove() end
            if activeESP[player].skeletonLines then
                for _, line in ipairs(activeESP[player].skeletonLines) do
                    line:Remove()
                end
            end
            if activeESP[player].updateConnection then
                activeESP[player].updateConnection:Disconnect()
            end
        end
        
        -- Create new ESP
        local newBox, newHealthBar, newNameTag, newSkeletonLines, newAmmoTag, newTracer, newConnection = DrawESPBoxWithHealthAndArmor(player)
        
        activeESP[player] = {
            box = newBox,
            healthBar = newHealthBar,
            nameTag = newNameTag,
            skeletonLines = newSkeletonLines,
            ammoTag = newAmmoTag,
            tracer = newTracer,
            updateConnection = newConnection,
            characterConnection = activeESP[player].characterConnection
        }
    end)
end

local function cleanupESP(player)
    if activeESP[player] then
        if activeESP[player].box then activeESP[player].box:Remove() end
        if activeESP[player].healthBar then activeESP[player].healthBar:Remove() end
        if activeESP[player].nameTag then activeESP[player].nameTag:Remove() end
        if activeESP[player].ammoTag then activeESP[player].ammoTag:Remove() end
        if activeESP[player].tracer then activeESP[player].tracer:Remove() end
        if activeESP[player].skeletonLines then
            for _, line in ipairs(activeESP[player].skeletonLines) do
                line:Remove()
            end
        end
        if activeESP[player].updateConnection then
            activeESP[player].updateConnection:Disconnect()
        end
        if activeESP[player].characterConnection then
            activeESP[player].characterConnection:Disconnect()
        end
        activeESP[player] = nil
    end
end

local function initializeESP(player)
    player.CharacterAdded:Connect(function()
        applyESP(player)
    end)
    player.AncestryChanged:Connect(function(_, parent)
        if not parent then
            if activeESP[player] then
                for _, line in ipairs(activeESP[player].skeletonLines) do
                    line:Remove()
                end
                activeESP[player] = nil
            end
        end
    end)
    if player.Character then
        applyESP(player)
    end
end

-- Initialize ESP for all players
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= Player then  -- Don't apply ESP to local player
        initializeESP(player)
    end
end

-- Handle new players joining
Players.PlayerAdded:Connect(function(player)
    if player ~= Player then  -- Don't apply ESP to local player
        initializeESP(player)
    end
end)

-- Handle players leaving
Players.PlayerRemoving:Connect(function(player)
    cleanupESP(player)
end)

-- Toggle ESP Features
local function toggleESPFeature(feature, state)
    _G[feature] = state
end

-- Example usage:
-- toggleESPFeature("BoxESPEnabled", true)  -- Enable Box ESP
-- toggleESPFeature("HealthESPEnabled", false)  -- Disable Health ESP
