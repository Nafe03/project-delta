-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Local Player Info
local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ESP Settings
-- [Previous code remains the same until the ESP Settings section]

-- ESP Settings
_G.ESPEnabled = true
_G.HealthESPEnabled = true
_G.NameESPEnabled = true
_G.BoxESPEnabled = true
_G.DistanceESPEnabled = false
_G.SkeletonESP = true  -- New setting for skeleton ESP

_G.BoxColor = Color3.fromRGB(255, 255, 255)
_G.NameColor = Color3.fromRGB(255, 255, 255)
_G.SkeletonColor = Color3.fromRGB(255, 255, 255)  -- Color for skeleton lines

-- [Previous code remains the same until the activeESP storage]

-- Active ESP Storage
local activeESP = {}

-- Function to Create Skeleton Lines
local function CreateSkeletonLines()
    local lines = {}
    for i = 1, 15 do  -- Create lines for skeleton connections
        local line = Drawing.new("Line")
        line.Thickness = 1
        line.Color = _G.SkeletonColor
        line.Visible = false
        lines[i] = line
    end
    return lines
end

-- Function to Update Skeleton ESP
local function UpdateSkeletonESP(character, skeletonLines)
    if not character or not _G.SkeletonESP then
        for _, line in ipairs(skeletonLines) do
            line.Visible = false
        end
        return
    end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end

    -- Define important parts for skeleton
    local joints = {
        head = character:FindFirstChild("Head"),
        upperTorso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"),
        lowerTorso = character:FindFirstChild("LowerTorso"),
        leftUpperArm = character:FindFirstChild("LeftUpperArm"),
        rightUpperArm = character:FindFirstChild("RightUpperArm"),
        leftLowerArm = character:FindFirstChild("LeftLowerArm"),
        rightLowerArm = character:FindFirstChild("RightLowerArm"),
        leftHand = character:FindFirstChild("LeftHand"),
        rightHand = character:FindFirstChild("RightHand"),
        leftUpperLeg = character:FindFirstChild("LeftUpperLeg"),
        rightUpperLeg = character:FindFirstChild("RightUpperLeg"),
        leftLowerLeg = character:FindFirstChild("LeftLowerLeg"),
        rightLowerLeg = character:FindFirstChild("RightLowerLeg"),
        leftFoot = character:FindFirstChild("LeftFoot"),
        rightFoot = character:FindFirstChild("RightFoot")
    }

    local function drawBone(line, part1, part2)
        if not part1 or not part2 then
            line.Visible = false
            return
        end

        local pos1 = Camera:WorldToViewportPoint(part1.Position)
        local pos2 = Camera:WorldToViewportPoint(part2.Position)

        if pos1.Z < 0 or pos2.Z < 0 then
            line.Visible = false
            return
        end

        line.From = Vector2.new(pos1.X, pos1.Y)
        line.To = Vector2.new(pos2.X, pos2.Y)
        line.Color = _G.SkeletonColor
        line.Visible = true
    end

    local lineIndex = 1
    
    -- Draw spine
    if joints.head and joints.upperTorso then
        drawBone(skeletonLines[lineIndex], joints.head, joints.upperTorso)
        lineIndex = lineIndex + 1
    end
    
    if joints.upperTorso and joints.lowerTorso then
        drawBone(skeletonLines[lineIndex], joints.upperTorso, joints.lowerTorso)
        lineIndex = lineIndex + 1
    end

    -- Draw arms
    if joints.upperTorso and joints.leftUpperArm then
        drawBone(skeletonLines[lineIndex], joints.upperTorso, joints.leftUpperArm)
        lineIndex = lineIndex + 1
    end

    if joints.leftUpperArm and joints.leftLowerArm then
        drawBone(skeletonLines[lineIndex], joints.leftUpperArm, joints.leftLowerArm)
        lineIndex = lineIndex + 1
    end

    if joints.leftLowerArm and joints.leftHand then
        drawBone(skeletonLines[lineIndex], joints.leftLowerArm, joints.leftHand)
        lineIndex = lineIndex + 1
    end

    if joints.upperTorso and joints.rightUpperArm then
        drawBone(skeletonLines[lineIndex], joints.upperTorso, joints.rightUpperArm)
        lineIndex = lineIndex + 1
    end

    if joints.rightUpperArm and joints.rightLowerArm then
        drawBone(skeletonLines[lineIndex], joints.rightUpperArm, joints.rightLowerArm)
        lineIndex = lineIndex + 1
    end

    if joints.rightLowerArm and joints.rightHand then
        drawBone(skeletonLines[lineIndex], joints.rightLowerArm, joints.rightHand)
        lineIndex = lineIndex + 1
    end

    -- Draw legs
    if joints.lowerTorso and joints.leftUpperLeg then
        drawBone(skeletonLines[lineIndex], joints.lowerTorso, joints.leftUpperLeg)
        lineIndex = lineIndex + 1
    end

    if joints.leftUpperLeg and joints.leftLowerLeg then
        drawBone(skeletonLines[lineIndex], joints.leftUpperLeg, joints.leftLowerLeg)
        lineIndex = lineIndex + 1
    end

    if joints.leftLowerLeg and joints.leftFoot then
        drawBone(skeletonLines[lineIndex], joints.leftLowerLeg, joints.leftFoot)
        lineIndex = lineIndex + 1
    end

    if joints.lowerTorso and joints.rightUpperLeg then
        drawBone(skeletonLines[lineIndex], joints.lowerTorso, joints.rightUpperLeg)
        lineIndex = lineIndex + 1
    end

    if joints.rightUpperLeg and joints.rightLowerLeg then
        drawBone(skeletonLines[lineIndex], joints.rightUpperLeg, joints.rightLowerLeg)
        lineIndex = lineIndex + 1
    end

    if joints.rightLowerLeg and joints.rightFoot then
        drawBone(skeletonLines[lineIndex], joints.rightLowerLeg, joints.rightFoot)
        lineIndex = lineIndex + 1
    end

    -- Hide unused lines
    for i = lineIndex, #skeletonLines do
        skeletonLines[i].Visible = false
    end
end

-- Modify the DrawESPBoxWithHealth function to include skeleton lines
local function DrawESPBoxWithHealth(player)
    -- [Previous box, health bar, and name tag code remains the same]
    
    -- Add skeleton lines
    local skeletonLines = CreateSkeletonLines()
    
    -- Modify the RenderStepped connection to include skeleton updates
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if character and character.Parent and rootPart then
            -- [Previous box, health bar, and name tag updates remain the same]
            
            -- Update skeleton ESP
            if _G.SkeletonESP then
                UpdateSkeletonESP(character, skeletonLines)
            else
                for _, line in ipairs(skeletonLines) do
                    line.Visible = false
                end
            end
        else
            -- [Previous visibility settings remain the same]
            for _, line in ipairs(skeletonLines) do
                line.Visible = false
            end
        end
    end)

    -- Modify cleanup to include skeleton lines
    character.AncestryChanged:Connect(function(_, parent)
        if not parent then
            -- [Previous cleanup code remains the same]
            for _, line in ipairs(skeletonLines) do
                line.Visible = false
                line:Remove()
            end
        end
    end)

    return box, healthBar, healthBackground, nameTag, skeletonLines, connection
end

-- Add skeleton lines to ESP storage in applyBoxESPWithHealth
local function applyBoxESPWithHealth(player)
    -- [Previous code remains the same until DrawESPBoxWithHealth call]
    local box, healthBar, healthBackground, nameTag, skeletonLines, connection = DrawESPBoxWithHealth(player)

    activeESP[player] = {
        box = box,
        healthBar = healthBar,
        healthBackground = healthBackground,
        nameTag = nameTag,
        skeletonLines = skeletonLines,
        updateConnection = connection,
    }
end

-- Modify removeESP to clean up skeleton lines
local function removeESP(player)
    local espData = activeESP[player]
    if espData then
        -- [Previous cleanup code remains the same]
        if espData.skeletonLines then
            for _, line in ipairs(espData.skeletonLines) do
                line:Remove()
            end
        end
        activeESP[player] = nil
    end
end

-- Add skeleton ESP toggle function
local function onSkeletonESPToggle(newState)
    toggleESPFeature("SkeletonESP", newState)
end

-- [Rest of the code remains the same]

-- Initialize ESP for all players
local function initializeESP(player)
    player.CharacterAdded:Connect(function()
        applyBoxESPWithHealth(player)
    end)
    player.AncestryChanged:Connect(function(_, parent)
        if not parent then
            removeESP(player)
        end
    end)
    if player.Character then
        applyBoxESPWithHealth(player)
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

-- Color Settings
local function setBoxColor(newColor)
    _G.BoxColor = newColor
end

local function setNameColor(newColor)
    _G.NameColor = newColor
end
