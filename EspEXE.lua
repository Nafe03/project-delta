-- Made by Blissful#4992

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

-- Local Player Info
local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ESP Settings
_G.ESPEnabled = true  -- Master toggle for all ESP
_G.HealthESPEnabled = false
_G.NameESPEnabled = false
_G.BoxESPEnabled = false
_G.DistanceESPEnabled = false
_G.HighlightEnabled = false
_G.HealthTextEnabled = false -- Separate toggle for health text
_G.HighlightColor = Color3.fromRGB(0, 255, 0) -- Default highlight color
_G.BoxColor = Color3.fromRGB(255, 255, 255) -- Default box color
_G.HealthTextColor = Color3.fromRGB(255, 255, 255)

-- Create Highlight for a Character
local function createHighlight(character)
    local highlight = character:FindFirstChild("Highlight") or Instance.new("Highlight")
    highlight.Parent = character
    highlight.FillColor = _G.HighlightColor
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
    highlight.OutlineTransparency = 0
    highlight.Enabled = _G.HighlightEnabled
    return highlight
end

-- Create ESP UI (Name, Distance, Health)
local function createESPUI(character)
    local billboardGui = character:FindFirstChildOfClass("BillboardGui") or Instance.new("BillboardGui", character)
    billboardGui.Size = UDim2.new(0, 100, 0, 100)
    billboardGui.Adornee = character:WaitForChild("Head")
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.AlwaysOnTop = true

    -- Utility function to create a label
    local function createLabel(name, position)
        local label = billboardGui:FindFirstChild(name) or Instance.new("TextLabel", billboardGui)
        label.Name = name
        label.Size = UDim2.new(1, 0, 0.3, 0)
        label.Position = position
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextScaled = true
        label.Font = Enum.Font.GothamBold
        label.TextStrokeTransparency = 0.5
        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        label.Visible = false
        return label
    end

    -- Labels for Name, Distance, and Health
    local nameLabel = createLabel("NameLabel", UDim2.new(0, 0, -1, 0))
    local distanceLabel = createLabel("DistanceLabel", UDim2.new(0, 0, 1.3, 0))
    local healthLabel = createLabel("HealthLabel", UDim2.new(0, 0, 0, 0))

    -- Health Bar
    local healthBarBackground = billboardGui:FindFirstChild("HealthBarBackground") or Instance.new("Frame", billboardGui)
    healthBarBackground.Name = "HealthBarBackground"
    healthBarBackground.Size = UDim2.new(1, 0, 0.1, 0)
    healthBarBackground.Position = UDim2.new(0, 0, 0.3, 0)
    healthBarBackground.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    healthBarBackground.BorderSizePixel = 0
    healthBarBackground.Visible = false

    local healthBar = healthBarBackground:FindFirstChild("HealthBar") or Instance.new("Frame", healthBarBackground)
    healthBar.Name = "HealthBar"
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthBar.BorderSizePixel = 0

    return function(humanoid)
        local distance = (Player.Character.PrimaryPart.Position - character.PrimaryPart.Position).Magnitude

        -- Update Name
        nameLabel.Visible = _G.NameESPEnabled
        nameLabel.Text = character.Name

        -- Update Distance
        distanceLabel.Visible = _G.DistanceESPEnabled
        distanceLabel.Text = string.format("%.1f studs", distance)

        -- Update Health
        if humanoid then
            local healthFraction = humanoid.Health / humanoid.MaxHealth
            healthLabel.Visible = _G.HealthTextEnabled
            healthLabel.Text = string.format("HP: %d/%d", math.floor(humanoid.Health), humanoid.MaxHealth)

            healthBarBackground.Visible = _G.HealthESPEnabled
            healthBar.Size = UDim2.new(healthFraction, 0, 1, 0)
            healthBar.BackgroundColor3 = Color3.fromRGB(255 * (1 - healthFraction), 255 * healthFraction, 0)
        end
    end
end

-- Improved BoxESP Implementation

-- Table to track ESP elements for cleanup
local activeBoxes = {}

-- Function to create BoxESP for a player
local function createBoxESP(player)
    local box = Drawing.new("Quad")
    box.Thickness = 1
    box.Transparency = 1
    box.Visible = false

    local function updateBox()
        if player.Character and player.Character.PrimaryPart and _G.BoxESPEnabled then
            local character = player.Character
            local primaryPart = character.PrimaryPart

            -- Calculate the box corners
            local topLeft = Camera:WorldToViewportPoint((primaryPart.CFrame * CFrame.new(-2, 3, 0)).Position)
            local topRight = Camera:WorldToViewportPoint((primaryPart.CFrame * CFrame.new(2, 3, 0)).Position)
            local bottomLeft = Camera:WorldToViewportPoint((primaryPart.CFrame * CFrame.new(-2, -3, 0)).Position)
            local bottomRight = Camera:WorldToViewportPoint((primaryPart.CFrame * CFrame.new(2, -3, 0)).Position)

            -- Update box points and visibility
            box.PointA = Vector2.new(topRight.X, topRight.Y)
            box.PointB = Vector2.new(topLeft.X, topLeft.Y)
            box.PointC = Vector2.new(bottomLeft.X, bottomLeft.Y)
            box.PointD = Vector2.new(bottomRight.X, bottomRight.Y)
            box.Color = _G.BoxColor
            box.Visible = true
        else
            box.Visible = false
        end
    end

    -- Return both the box and its updater function
    return box, updateBox
end

-- Function to apply BoxESP to a player
local function applyBoxESP(player)
    -- Create and track the BoxESP
    local box, updateBox = createBoxESP(player)
    activeBoxes[player] = box

    -- Update the box on each frame
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if _G.ESPEnabled and _G.BoxESPEnabled then
            updateBox()
        else
            box.Visible = false -- Hide if ESP is disabled
        end
    end)

    -- Cleanup when the player leaves
    player.AncestryChanged:Connect(function()
        if not player:IsDescendantOf(game) then
            box:Remove()
            activeBoxes[player] = nil
            connection:Disconnect()
        end
    end)
end

-- Function to remove all active ESP elements
local function removeAllESP()
    for player, box in pairs(activeBoxes) do
        if box then
            box:Remove()
        end
    end
    activeBoxes = {}
end

-- Function to toggle ESP dynamically
local function toggleESPFeature(feature, state)
    _G[feature] = state

    if not _G.ESPEnabled then
        removeAllESP() -- Cleanup all ESP if master toggle is off
    elseif feature == "BoxESPEnabled" and not state then
        -- Specific cleanup for BoxESP
        for _, box in pairs(activeBoxes) do
            if box then
                box.Visible = false
            end
        end
    end
end

-- Initialize BoxESP for all players
local function initializeBoxESP()
    for _, player in ipairs(Players:GetPlayers()) do
        applyBoxESP(player)
    end

    -- Handle new players joining
    Players.PlayerAdded:Connect(applyBoxESP)

    -- Cleanup for players leaving
    Players.PlayerRemoving:Connect(function(player)
        if activeBoxes[player] then
            activeBoxes[player]:Remove()
            activeBoxes[player] = nil
        end
    end)
end

-- Initialize BoxESP
initializeBoxESP()

