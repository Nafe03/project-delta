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
_G.SkeletonESP = true
_G.DistanceESPEnabled = false

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

        -- Torso to Left Arm
        if screenPoints.leftArm then
            skeletonLines[2].From = screenPoints.torso
            skeletonLines[2].To = screenPoints.leftArm
        end

        -- Torso to Right Arm
        if screenPoints.rightArm then
            skeletonLines[3].From = screenPoints.torso
            skeletonLines[3].To = screenPoints.rightArm
        end

        -- Torso to Left Leg
        if screenPoints.leftLeg then
            skeletonLines[4].From = screenPoints.torso
            skeletonLines[4].To = screenPoints.leftLeg
        end

        -- Torso to Right Leg
        if screenPoints.rightLeg then
            skeletonLines[5].From = screenPoints.torso
            skeletonLines[5].To = screenPoints.rightLeg
        end

        -- Left Arm to Left Hand (if available)
        local leftHand = character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm")
        if leftHand then
            local leftHandPoint = getScreenPoint(leftHand)
            if leftHandPoint then
                skeletonLines[6].From = screenPoints.leftArm
                skeletonLines[6].To = leftHandPoint
            end
        end

        -- Right Arm to Right Hand (if available)
        local rightHand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
        if rightHand then
            local rightHandPoint = getScreenPoint(rightHand)
            if rightHandPoint then
                skeletonLines[7].From = screenPoints.rightArm
                skeletonLines[7].To = rightHandPoint
            end
        end

        -- Left Leg to Left Foot (if available)
        local leftFoot = character:FindFirstChild("LeftFoot") or character:FindFirstChild("Left Leg")
        if leftFoot then
            local leftFootPoint = getScreenPoint(leftFoot)
            if leftFootPoint then
                skeletonLines[8].From = screenPoints.leftLeg
                skeletonLines[8].To = leftFootPoint
            end
        end

        -- Right Leg to Right Foot (if available)
        local rightFoot = character:FindFirstChild("RightFoot") or character:FindFirstChild("Right Leg")
        if rightFoot then
            local rightFootPoint = getScreenPoint(rightFoot)
            if rightFootPoint then
                skeletonLines[9].From = screenPoints.rightLeg
                skeletonLines[9].To = rightFootPoint
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

    -- Create Name Tag
    local nameTag = CreateNameESP(player)

    -- Create Skeleton ESP
    local skeletonLines = CreateSkeletonESP()

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

                -- Update Skeleton ESP
                UpdateSkeletonESP(skeletonLines, character)
            else
                box.Visible = false
                healthBar.Visible = false
                nameTag.Visible = false
                for _, line in ipairs(skeletonLines) do
                    line.Visible = false
                end
            end
        else
            box.Visible = false
            healthBar.Visible = false
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
            nameTag:Remove()
        end
    end)

    return box, healthBar, nameTag, skeletonLines, connection
end

-- Apply ESP to Player
local function applyESP(player)
    if not player then return end
    local character = player.Character or player.CharacterAdded:Wait()
    if not character then return end

    -- Create ESP elements
    local box, healthBar, nameTag, skeletonLines, connection = DrawESPBoxWithHealthAndArmor(player)

    -- Store ESP objects for cleanup later
    activeESP[player] = {
        box = box,
        healthBar = healthBar,
        nameTag = nameTag,
        skeletonLines = skeletonLines,
        updateConnection = connection,
    }
end

-- Initialize ESP for all players
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
Players.PlayerRemoving:Connect(function(player)
    if activeESP[player] then
        for _, line in ipairs(activeESP[player].skeletonLines) do
            line:Remove()
        end
        activeESP[player] = nil
    end
end)

-- Toggle ESP Features
local function toggleESPFeature(feature, state)
    _G[feature] = state
end

local function onSkeletonESPToggle(newState)
    toggleESPFeature("SkeletonESP", newState)
end

-- Example usage:
-- onSkeletonESPToggle(true)  -- Enable Skeleton ESP
-- onSkeletonESPToggle(false) -- Disable Skeleton ESP
