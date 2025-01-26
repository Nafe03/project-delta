-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Local Player Info
local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ESP Settings
_G.ESPEnabled = true
_G.HealthESPEnabled = true
_G.NameESPEnabled = true
_G.BoxESPEnabled = true
_G.DistanceESPEnabled = false
_G.SkeletonESP = true

_G.BoxColor = Color3.fromRGB(255, 255, 255)
_G.NameColor = Color3.fromRGB(255, 255, 255)
_G.SkeletonColor = Color3.fromRGB(255, 0, 0)

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
local function CreateSkeletonESP(player)
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

-- Function to Update Skeleton ESP
local function UpdateSkeletonESP(skeletonLines, character)
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local head = character:FindFirstChild("Head")
    local torso = character:FindFirstChild("UpperTorso")
    local leftArm = character:FindFirstChild("LeftUpperArm")
    local rightArm = character:FindFirstChild("RightUpperArm")
    local leftLeg = character:FindFirstChild("LeftUpperLeg")
    local rightLeg = character:FindFirstChild("RightUpperLeg")

    if not (head and torso and leftArm and rightArm and leftLeg and rightLeg) then return end

    local points = {
        head.Position,
        torso.Position,
        leftArm.Position,
        rightArm.Position,
        leftLeg.Position,
        rightLeg.Position
    }

    local screenPoints = {}
    for _, point in ipairs(points) do
        local screenPoint, onScreen = Camera:WorldToViewportPoint(point)
        if onScreen then
            table.insert(screenPoints, Vector2.new(screenPoint.X, screenPoint.Y))
        else
            return
        end
    end

    -- Head to Torso
    skeletonLines[1].From = screenPoints[1]
    skeletonLines[1].To = screenPoints[2]

    -- Torso to Left Arm
    skeletonLines[2].From = screenPoints[2]
    skeletonLines[2].To = screenPoints[3]

    -- Torso to Right Arm
    skeletonLines[3].From = screenPoints[2]
    skeletonLines[3].To = screenPoints[4]

    -- Torso to Left Leg
    skeletonLines[4].From = screenPoints[2]
    skeletonLines[4].To = screenPoints[5]

    -- Torso to Right Leg
    skeletonLines[5].From = screenPoints[2]
    skeletonLines[5].To = screenPoints[6]

    -- Left Arm to Left Lower Arm
    local leftLowerArm = character:FindFirstChild("LeftLowerArm")
    if leftLowerArm then
        local screenPoint, onScreen = Camera:WorldToViewportPoint(leftLowerArm.Position)
        if onScreen then
            skeletonLines[6].From = screenPoints[3]
            skeletonLines[6].To = Vector2.new(screenPoint.X, screenPoint.Y)
        end
    end

    -- Right Arm to Right Lower Arm
    local rightLowerArm = character:FindFirstChild("RightLowerArm")
    if rightLowerArm then
        local screenPoint, onScreen = Camera:WorldToViewportPoint(rightLowerArm.Position)
        if onScreen then
            skeletonLines[7].From = screenPoints[4]
            skeletonLines[7].To = Vector2.new(screenPoint.X, screenPoint.Y)
        end
    end

    -- Left Leg to Left Lower Leg
    local leftLowerLeg = character:FindFirstChild("LeftLowerLeg")
    if leftLowerLeg then
        local screenPoint, onScreen = Camera:WorldToViewportPoint(leftLowerLeg.Position)
        if onScreen then
            skeletonLines[8].From = screenPoints[5]
            skeletonLines[8].To = Vector2.new(screenPoint.X, screenPoint.Y)
        end
    end

    -- Right Leg to Right Lower Leg
    local rightLowerLeg = character:FindFirstChild("RightLowerLeg")
    if rightLowerLeg then
        local screenPoint, onScreen = Camera:WorldToViewportPoint(rightLowerLeg.Position)
        if onScreen then
            skeletonLines[9].From = screenPoints[6]
            skeletonLines[9].To = Vector2.new(screenPoint.X, screenPoint.Y)
        end
    end

    -- Left Lower Arm to Left Hand
    local leftHand = character:FindFirstChild("LeftHand")
    if leftHand then
        local screenPoint, onScreen = Camera:WorldToViewportPoint(leftHand.Position)
        if onScreen then
            skeletonLines[10].From = skeletonLines[6].To
            skeletonLines[10].To = Vector2.new(screenPoint.X, screenPoint.Y)
        end
    end

    -- Right Lower Arm to Right Hand
    local rightHand = character:FindFirstChild("RightHand")
    if rightHand then
        local screenPoint, onScreen = Camera:WorldToViewportPoint(rightHand.Position)
        if onScreen then
            skeletonLines[11].From = skeletonLines[7].To
            skeletonLines[11].To = Vector2.new(screenPoint.X, screenPoint.Y)
        end
    end

    -- Left Lower Leg to Left Foot
    local leftFoot = character:FindFirstChild("LeftFoot")
    if leftFoot then
        local screenPoint, onScreen = Camera:WorldToViewportPoint(leftFoot.Position)
        if onScreen then
            skeletonLines[12].From = skeletonLines[8].To
            skeletonLines[12].To = Vector2.new(screenPoint.X, screenPoint.Y)
        end
    end

    -- Right Lower Leg to Right Foot
    local rightFoot = character:FindFirstChild("RightFoot")
    if rightFoot then
        local screenPoint, onScreen = Camera:WorldToViewportPoint(rightFoot.Position)
        if onScreen then
            skeletonLines[13].From = skeletonLines[9].To
            skeletonLines[13].To = Vector2.new(screenPoint.X, screenPoint.Y)
        end
    end

    -- Torso to Head
    skeletonLines[14].From = screenPoints[2]
    skeletonLines[14].To = screenPoints[1]

    for _, line in ipairs(skeletonLines) do
        line.Visible = _G.SkeletonESP
    end
end

-- Function to Create Box ESP with Health and Armor Bars
local function DrawESPBoxWithHealthAndArmor(player)
    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart", 5)
    if not rootPart then return end

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

    -- Create Armor Bar
    local armorBar = Drawing.new("Square")
    armorBar.Thickness = 1
    armorBar.Filled = true
    armorBar.Color = Color3.fromRGB(0, 0, 255) -- Blue color for armor
    armorBar.Visible = false

    -- Create Name Tag
    local nameTag = CreateNameESP(player)

    -- Create Skeleton ESP
    local skeletonLines = CreateSkeletonESP(player)

    local connection
    connection = RunService.RenderStepped:Connect(function()
        if character and character.Parent and rootPart then
            local rootPos = rootPart.Position
            local screenPos, onScreen = Camera:WorldToViewportPoint(rootPos)

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

                -- Update Armor Bar
                local armorValue = workspace.Players:FindFirstChild(player.Name)
                if armorValue and armorValue:FindFirstChild("BodyEffects") and armorValue.BodyEffects:FindFirstChild("Armor") then
                    local currentArmor = armorValue.BodyEffects.Armor.Value
                    local maxArmor = 100 -- Assuming max armor is 100
                    local armorFraction = currentArmor / maxArmor
                    armorBar.Size = Vector2.new(5, size.Y * armorFraction)
                    armorBar.Position = Vector2.new(boxPosition.X - 15, boxPosition.Y + size.Y * (1 - armorFraction))
                    armorBar.Visible = _G.HealthESPEnabled
                else
                    armorBar.Visible = false
                end

                -- Update Skeleton ESP
                UpdateSkeletonESP(skeletonLines, character)
            else
                box.Visible = false
                healthBar.Visible = false
                armorBar.Visible = false
                nameTag.Visible = false
                for _, line in ipairs(skeletonLines) do
                    line.Visible = false
                end
            end
        else
            box.Visible = false
            healthBar.Visible = false
            armorBar.Visible = false
            nameTag.Visible = false
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
            armorBar.Visible = false
            nameTag.Visible = false
            for _, line in ipairs(skeletonLines) do
                line.Visible = false
                line:Remove()
            end
            if connection then
                connection:Disconnect()
            end
            box:Remove()
            healthBar:Remove()
            armorBar:Remove()
            nameTag:Remove()
        end
    end)

    return box, healthBar, armorBar, nameTag, skeletonLines, connection
end

-- Apply Box ESP with Health and Armor Bars to Player
local function applyBoxESPWithHealthAndArmor(player)
    if not player then return end
    local character = player.Character or player.CharacterAdded:Wait()
    if not character then return end

    -- Create Box, Health Bar, Armor Bar, Name Tag, and Skeleton ESP
    local box, healthBar, armorBar, nameTag, skeletonLines, connection = DrawESPBoxWithHealthAndArmor(player)

    -- Store ESP objects for cleanup later
    activeESP[player] = {
        box = box,
        healthBar = healthBar,
        armorBar = armorBar,
        nameTag = nameTag,
        skeletonLines = skeletonLines,
        updateConnection = connection,
    }
end

-- Initialize ESP for all players
local function initializeESP(player)
    player.CharacterAdded:Connect(function()
        applyBoxESPWithHealthAndArmor(player)
    end)
    player.AncestryChanged:Connect(function(_, parent)
        if not parent then
            removeESP(player)
        end
    end)
    if player.Character then
        applyBoxESPWithHealthAndArmor(player)
    end
end

-- Apply ESP to all players in-game and new ones joining
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= Player then  -- Don't apply ESP to local player
        initializeESP(player)
    end
end
Players.PlayerAdded:Connect(function(player)
    if player ~= Player then  -- Don't apply ESP to local player
        initializeESP(player)
    end
end)
Players.PlayerRemoving:Connect(removeESP)

-- Toggle ESP Features
local function toggleESPFeature(feature, state)
    _G[feature] = state
end

local function onHealthESPToggle(newState)
    toggleESPFeature("HealthESPEnabled", newState)
end

local function onNameESPToggle(newState)
    toggleESPFeature("NameESPEnabled", newState)
end

local function onBoxESPToggle(newState)
    toggleESPFeature("BoxESPEnabled", newState)
end

local function onDistanceESPToggle(newState)
    toggleESPFeature("DistanceESPEnabled", newState)
end

local function onSkeletonESPToggle(newState)
    toggleESPFeature("SkeletonESP", newState)
end

-- Color Settings
local function setBoxColor(newColor)
    _G.BoxColor = newColor
end

local function setNameColor(newColor)
    _G.NameColor = newColor
end

local function setSkeletonColor(newColor)
    _G.SkeletonColor = newColor
end
