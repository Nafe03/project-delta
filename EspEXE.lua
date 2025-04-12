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
_G.HealthESPEnabled = false
_G.NameESPEnabled = false
_G.BoxESPEnabled = false
_G.SkeletonESP = false
_G.TracersEnabled = false
_G.DistanceESPEnabled = false
_G.ShowAmmo = false
_G.ShowTeam = false -- Show ESP for teammates
_G.MaxDistance = 0 -- Maximum distance for ESP (in studs)
_G.FadeDistance = 0 -- Distance at which ESP starts fading
_G.TeamColor = Color3.fromRGB(0, 255, 0) -- Color for teammates
_G.EnemyColor = Color3.fromRGB(255, 0, 0) -- Color for enemies
_G.BoxColor = Color3.fromRGB(255, 255, 255)
_G.NameColor = Color3.fromRGB(255, 255, 255)
_G.AmmoColor = Color3.fromRGB(255, 255, 255)
_G.SkeletonColor = Color3.fromRGB(255, 255, 255)
_G.TracerColor = Color3.fromRGB(255, 255, 255)
_G.Charm = false -- Enable charm (glow) feature
_G.CharmVisibleColor = Color3.fromRGB(0, 255, 0) -- Color for visible parts
_G.CharmHiddenColor = Color3.fromRGB(255, 255, 255) -- Color for hidden parts
_G.ItemHold = false -- Enable item hold feature

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

-- Function to Get Current Tool of a Player
local function GetPlayerTool(player)
    local character = player.Character
    if character then
        local tool = character:FindFirstChildOfClass("Tool")
        if tool then
            return tool.Name
        end
    end
    return "None"
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

-- Function to Create Item Hold ESP
local function CreateItemHoldESP()
    local itemTag = Drawing.new("Text")
    itemTag.Size = 18
    itemTag.Center = true
    itemTag.Outline = true
    itemTag.Color = _G.AmmoColor
    itemTag.Font = 3
    itemTag.Visible = false
    return itemTag
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

-- Function to Update Charm (Glow) ESP
local function UpdateCharmESP(character)
    if not _G.Charm then return end

    -- Check if the character already has a Highlight object
    local highlight = character:FindFirstChild("Charm_Highlight")
    if not highlight then
        -- Create a new Highlight object if it doesn't exist
        highlight = Instance.new("Highlight")
        highlight.Name = "Charm_Highlight"
        highlight.FillTransparency = 0.5 -- Adjust glow visibility
        highlight.OutlineTransparency = 0 -- Solid outline
        highlight.Parent = character
    end

    -- Check if the character is visible to the camera
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local screenPoint, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
    if onScreen then
        -- Raycast from the camera to the character's root part
        local ray = Ray.new(Camera.CFrame.Position, (rootPart.Position - Camera.CFrame.Position).Unit * _G.MaxDistance)
        local hit, position = Workspace:FindPartOnRayWithIgnoreList(ray, {character, Player.Character})

        if hit and hit:IsDescendantOf(character) then
            -- Character is visible
            highlight.FillColor = _G.CharmVisibleColor
            highlight.OutlineColor = _G.CharmVisibleColor
        else
            -- Character is behind something
            highlight.FillColor = _G.CharmHiddenColor
            highlight.OutlineColor = _G.CharmHiddenColor
        end
    else
        -- Character is off-screen
        highlight.FillColor = _G.CharmHiddenColor
        highlight.OutlineColor = _G.CharmHiddenColor
    end
end

local function DrawESPBoxWithHealthAndArmor(player)
    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart", 5)
    if not rootPart then return end

    -- Create ESP elements
    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Filled = false
    box.Color = _G.BoxColor
    box.Visible = false

    -- Create health bar background (new)
    local healthBarBackground = Drawing.new("Square")
    healthBarBackground.Thickness = 1
    healthBarBackground.Filled = true
    healthBarBackground.Color = Color3.fromRGB(40, 40, 40) -- Dark gray background
    healthBarBackground.Transparency = 0.7 -- Slightly transparent
    healthBarBackground.Visible = false

    -- Create health bar
    local healthBar = Drawing.new("Square")
    healthBar.Thickness = 1
    healthBar.Filled = true
    healthBar.Color = Color3.fromRGB(0, 255, 0)
    healthBar.Visible = false

    -- Create health bar outline (new)
    local healthBarOutline = Drawing.new("Square")
    healthBarOutline.Thickness = 1
    healthBarOutline.Filled = false
    healthBarOutline.Color = Color3.fromRGB(0, 0, 0) -- Black outline
    healthBarOutline.Visible = false

    local nameTag = CreateNameESP(player)
    local ammoTag = CreateAmmoESP()
    local itemTag = CreateItemHoldESP()
    local tracer = CreateTracer()
    local skeletonLines = CreateSkeletonESP()
    
    -- To avoid lag, we'll use a timer instead of updating every frame
    local lastUpdate = 0
    local updateInterval = 0.05 -- Update every 0.05 seconds (20 times per second)
    
    -- Function to update ESP elements with optimization
    local function updateESP()
        if not _G.ESPEnabled then
            box.Visible = false
            healthBar.Visible = false
            healthBarBackground.Visible = false
            healthBarOutline.Visible = false
            nameTag.Visible = false
            ammoTag.Visible = false
            itemTag.Visible = false
            tracer.Visible = false
            for _, line in ipairs(skeletonLines) do
                line.Visible = false
            end
            return
        end
        
        -- Skip if character is gone
        if not character or not character.Parent or not rootPart then
            box.Visible = false
            healthBar.Visible = false
            healthBarBackground.Visible = false
            healthBarOutline.Visible = false
            nameTag.Visible = false
            ammoTag.Visible = false
            itemTag.Visible = false
            tracer.Visible = false
            for _, line in ipairs(skeletonLines) do
                line.Visible = false
            end
            return
        end

        local rootPos = rootPart.Position
        local myRootPart = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        
        -- If player doesn't have a character yet, hide ESP
        if not myRootPart then
            box.Visible = false
            healthBar.Visible = false
            healthBarBackground.Visible = false
            healthBarOutline.Visible = false
            nameTag.Visible = false
            ammoTag.Visible = false
            itemTag.Visible = false
            tracer.Visible = false
            for _, line in ipairs(skeletonLines) do
                line.Visible = false
            end
            return
        end
        
        -- Check distance and skip far away players
        local distance = (myRootPart.Position - rootPos).Magnitude
        if distance > _G.MaxDistance then
            box.Visible = false
            healthBar.Visible = false
            healthBarBackground.Visible = false
            healthBarOutline.Visible = false
            nameTag.Visible = false
            ammoTag.Visible = false
            itemTag.Visible = false
            tracer.Visible = false
            for _, line in ipairs(skeletonLines) do
                line.Visible = false
            end
            return
        end
        
        -- Performance: Only do the WorldToViewportPoint check once
        local screenPos, onScreen = Camera:WorldToViewportPoint(rootPos)
        
        if onScreen then
            local size = Vector2.new(2500 / screenPos.Z, 3500 / screenPos.Z) -- Reduced size values
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

            -- Update Enhanced Health Bar
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                local healthFraction = humanoid.Health / humanoid.MaxHealth
                
                -- Health bar dimensions - wider and positioned to the left of the box
                local healthBarWidth = 3
                local healthBarPosition = Vector2.new(boxPosition.X - healthBarWidth - 5, boxPosition.Y)
                
                -- Background (full height always)
                healthBarBackground.Size = Vector2.new(healthBarWidth, size.Y)
                healthBarBackground.Position = healthBarPosition
                healthBarBackground.Visible = _G.HealthESPEnabled
                
                -- Health bar (varies with health)
                healthBar.Size = Vector2.new(healthBarWidth, size.Y * healthFraction)
                healthBar.Position = Vector2.new(healthBarPosition.X, healthBarPosition.Y + size.Y * (1 - healthFraction))
                
                -- Color gradient from red to green based on health
                healthBar.Color = Color3.fromRGB(255 * (1 - healthFraction), 255 * healthFraction, 0)
                healthBar.Visible = _G.HealthESPEnabled
                
                -- Outline (same size as background)
                healthBarOutline.Size = Vector2.new(healthBarWidth, size.Y)
                healthBarOutline.Position = healthBarPosition
                healthBarOutline.Visible = _G.HealthESPEnabled
            else
                healthBar.Visible = false
                healthBarBackground.Visible = false
                healthBarOutline.Visible = false
            end

            -- Update Ammo Tag
            ammoTag.Position = Vector2.new(screenPos.X, boxPosition.Y + size.Y + 5)
            ammoTag.Text = "Ammo: " .. tostring(GetPlayerAmmo(player))
            ammoTag.Color = _G.AmmoColor
            ammoTag.Visible = _G.ShowAmmo

            -- Update Item Hold Tag
            itemTag.Position = Vector2.new(screenPos.X, boxPosition.Y + size.Y + 25)
            itemTag.Text = "Holding: " .. tostring(GetPlayerTool(player))
            itemTag.Color = _G.AmmoColor
            itemTag.Visible = _G.ItemHold
            
            -- Update Tracer
            tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            tracer.To = Vector2.new(screenPos.X, screenPos.Y)
            tracer.Color = _G.TracerColor
            tracer.Visible = _G.TracersEnabled
            
            -- Skeleton ESP is expensive, only update if enabled and player is close
            if _G.SkeletonESP and distance < (_G.MaxDistance / 2) then
                UpdateSkeletonESP(skeletonLines, character)
            else
                for _, line in ipairs(skeletonLines) do
                    line.Visible = false
                end
            end
            
            -- Charm is even more expensive, only update if enabled and player is very close
            if _G.Charm and distance < (_G.MaxDistance / 3) then
                UpdateCharmESP(character)
            end
        else
            box.Visible = false
            healthBar.Visible = false
            healthBarBackground.Visible = false
            healthBarOutline.Visible = false
            nameTag.Visible = false
            ammoTag.Visible = false
            itemTag.Visible = false
            tracer.Visible = false
            for _, line in ipairs(skeletonLines) do
                line.Visible = false
            end
        end
    end

    -- Connect to RenderStepped but at reduced frequency
    local renderStepName = "ESP_" .. player.Name
    local lastRendered = 0
    local connection = RunService.RenderStepped:Connect(function()
        local now = tick()
        if now - lastRendered >= updateInterval then  -- Only update 20 times per second max
            lastRendered = now
            updateESP()
        end
    end)

    -- Handle Character Removal with safeguards
    local function cleanupDrawings()
        pcall(function()
            box.Visible = false
            healthBar.Visible = false
            healthBarBackground.Visible = false
            healthBarOutline.Visible = false
            nameTag.Visible = false
            ammoTag.Visible = false
            itemTag.Visible = false
            tracer.Visible = false
            
            for _, line in ipairs(skeletonLines) do
                line.Visible = false
                pcall(function() line:Remove() end)
            end
            
            pcall(function() box:Remove() end)
            pcall(function() healthBar:Remove() end)
            pcall(function() healthBarBackground:Remove() end)
            pcall(function() healthBarOutline:Remove() end)
            pcall(function() nameTag:Remove() end)
            pcall(function() ammoTag:Remove() end)
            pcall(function() itemTag:Remove() end)
            pcall(function() tracer:Remove() end)
            
            if connection then connection:Disconnect() end
        end)
    end

    if character then
        character.AncestryChanged:Connect(function(_, parent)
            if not parent then
                cleanupDrawings()
            end
        end)
    end

    return box, healthBar, healthBarBackground, healthBarOutline, nameTag, skeletonLines, ammoTag, itemTag, tracer, connection
end

-- Safe remove function for ESP elements
local function safeRemove(obj)
    if obj then
        pcall(function() 
            obj.Visible = false
            obj:Remove() 
        end)
    end
end

-- Apply ESP to Player
local function applyESP(player)
    if not player or player == Player then return end -- Don't apply to nil or local player
    
    -- Clean up existing ESP if any
    if activeESP[player] then
        if activeESP[player].updateConnection then
            activeESP[player].updateConnection:Disconnect()
        end
        
        safeRemove(activeESP[player].box)
        safeRemove(activeESP[player].healthBar)
        safeRemove(activeESP[player].healthBarBackground)
        safeRemove(activeESP[player].healthBarOutline)
        safeRemove(activeESP[player].nameTag)
        safeRemove(activeESP[player].ammoTag)
        safeRemove(activeESP[player].itemTag)
        safeRemove(activeESP[player].tracer)
        
        if activeESP[player].skeletonLines then
            for _, line in ipairs(activeESP[player].skeletonLines) do
                safeRemove(line)
            end
        end
        
        activeESP[player] = nil
    end

    -- Wait for character
    local character = player.Character
    if not character then
        player.CharacterAdded:Wait()
        character = player.Character
    end

    -- Create ESP elements with improved health bar
    local box, healthBar, healthBarBackground, healthBarOutline, nameTag, skeletonLines, ammoTag, itemTag, tracer, connection = DrawESPBoxWithHealthAndArmor(player)

    -- Store ESP objects for cleanup
    activeESP[player] = {
        box = box,
        healthBar = healthBar,
        healthBarBackground = healthBarBackground,
        healthBarOutline = healthBarOutline,
        nameTag = nameTag,
        skeletonLines = skeletonLines,
        ammoTag = ammoTag,
        itemTag = itemTag,
        tracer = tracer,
        updateConnection = connection,
        characterConnection = nil
    }

    -- Handle character changes
    activeESP[player].characterConnection = player.CharacterAdded:Connect(function()
        -- Remove old ESP safely
        if activeESP[player] then
            if activeESP[player].updateConnection then
                activeESP[player].updateConnection:Disconnect()
            end
            
            safeRemove(activeESP[player].box)
            safeRemove(activeESP[player].healthBar)
            safeRemove(activeESP[player].healthBarBackground)
            safeRemove(activeESP[player].healthBarOutline)
            safeRemove(activeESP[player].nameTag)
            safeRemove(activeESP[player].ammoTag)
            safeRemove(activeESP[player].itemTag)
            safeRemove(activeESP[player].tracer)
            
            if activeESP[player].skeletonLines then
                for _, line in ipairs(activeESP[player].skeletonLines) do
                    safeRemove(line)
                end
            end
        end
        
        -- Create new ESP
        local newBox, newHealthBar, newHealthBarBackground, newHealthBarOutline, newNameTag, newSkeletonLines, newAmmoTag, newItemTag, newTracer, newConnection = DrawESPBoxWithHealthAndArmor(player)
        
        activeESP[player] = {
            box = newBox,
            healthBar = newHealthBar,
            healthBarBackground = newHealthBarBackground,
            healthBarOutline = newHealthBarOutline,
            nameTag = newNameTag,
            skeletonLines = newSkeletonLines,
            ammoTag = newAmmoTag,
            itemTag = newItemTag,
            tracer = newTracer,
            updateConnection = newConnection,
            characterConnection = activeESP[player].characterConnection
        }
    end)
end

local function cleanupESP(player)
    if activeESP[player] then
        if activeESP[player].updateConnection then
            activeESP[player].updateConnection:Disconnect()
        end
        
        safeRemove(activeESP[player].box)
        safeRemove(activeESP[player].healthBar)
        safeRemove(activeESP[player].healthBarBackground)
        safeRemove(activeESP[player].healthBarOutline)
        safeRemove(activeESP[player].nameTag)
        safeRemove(activeESP[player].ammoTag)
        safeRemove(activeESP[player].itemTag)
        safeRemove(activeESP[player].tracer)
        
        if activeESP[player].skeletonLines then
            for _, line in ipairs(activeESP[player].skeletonLines) do
                safeRemove(line)
            end
        end
        
        activeESP[player] = nil
    end
end

local function initializeESP(player)
    if player == Player then return end -- Skip local player

    player.CharacterAdded:Connect(function()
        applyESP(player)
    end)

    player.AncestryChanged:Connect(function(_, parent)
        if not parent then
            cleanupESP(player)
        end
    end)

    if player.Character then
        applyESP(player)
    end
end

-- Initialize ESP for all players
for _, player in ipairs(Players:GetPlayers()) do
    initializeESP(player)
end

-- Handle new players joining
Players.PlayerAdded:Connect(function(player)
    initializeESP(player)
end)

-- Handle players leaving
Players.PlayerRemoving:Connect(function(player)
    cleanupESP(player)
end)

-- Optional: Function to toggle ESP features
local function toggleESPFeature(featureName, value)
    if _G[featureName] ~= nil then
        _G[featureName] = value
    end
end

-- Example usage:
-- toggleESPFeature("BoxESPEnabled", true)  -- Enable Box ESP
-- toggleESPFeature("HealthESPEnabled", true)  -- Enable Health ESP with the improved look
