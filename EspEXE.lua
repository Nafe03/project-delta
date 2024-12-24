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

-- Function to create ESP Highlight
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

-- Function to create and update ESP UI
local function createOrUpdateESPUI(character, playerName)
    local billboardGui = character:FindFirstChildOfClass("BillboardGui")
    if not billboardGui then
        billboardGui = Instance.new("BillboardGui", character)
        billboardGui.Size = UDim2.new(0, 100, 0, 100)
        billboardGui.Adornee = character:WaitForChild("Head")
        billboardGui.StudsOffset = Vector3.new(0, 3, 0)
        billboardGui.AlwaysOnTop = true
    end

    local function createLabel(name, position, color, text)
        local label = billboardGui:FindFirstChild(name)
        if not label then
            label = Instance.new("TextLabel", billboardGui)
            label.Name = name
            label.Size = UDim2.new(1, 0, 0.3, 0)
            label.Position = position
            label.BackgroundTransparency = 1
            label.TextColor3 = color
            label.TextScaled = true
            label.Font = Enum.Font.GothamBold
            label.TextStrokeTransparency = 0.5
            label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        end
        label.Text = text
        return label
    end

    local nameLabel = createLabel("NameLabel", UDim2.new(0, 0, -1, 0), Color3.fromRGB(255, 255, 255), playerName)
    nameLabel.Visible = _G.NameESPEnabled

    local distanceLabel = createLabel("DistanceLabel", UDim2.new(0, 0, 1.3, 0), Color3.fromRGB(255, 255, 255), "")
    distanceLabel.Visible = _G.DistanceESPEnabled

    local healthLabel = createLabel("HealthLabel", UDim2.new(0, 0, 0, 0), _G.HealthTextColor, "")
    healthLabel.Visible = _G.HealthTextEnabled

    -- Health Bar Background
    local healthBarBackground = billboardGui:FindFirstChild("HealthBarBackground")
    if not healthBarBackground then
        healthBarBackground = Instance.new("Frame", billboardGui)
        healthBarBackground.Name = "HealthBarBackground"
        healthBarBackground.Size = UDim2.new(1, 0, 0.1, 0)
        healthBarBackground.Position = UDim2.new(0, 0, 0.3, 0)
        healthBarBackground.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        healthBarBackground.BorderSizePixel = 0
    end
    healthBarBackground.Visible = _G.HealthESPEnabled

    -- Health Bar
    local healthBar = healthBarBackground:FindFirstChild("HealthBar")
    if not healthBar then
        healthBar = Instance.new("Frame", healthBarBackground)
        healthBar.Name = "HealthBar"
        healthBar.Size = UDim2.new(1, 0, 1, 0)
        healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        healthBar.BorderSizePixel = 0
    end

    local function updateESP()
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then return end

        local playerDistance = (Player.Character.PrimaryPart.Position - character.PrimaryPart.Position).Magnitude
        if _G.DistanceESPEnabled then
            distanceLabel.Text = string.format("%.1f studs", playerDistance)
        end

        if _G.HealthESPEnabled then
            local healthFraction = humanoid.Health / humanoid.MaxHealth
            healthBar.Size = UDim2.new(healthFraction, 0, 1, 0)
            healthBar.BackgroundColor3 = Color3.fromRGB(255 * (1 - healthFraction), 255 * healthFraction, 0)
        end

        if _G.HealthTextEnabled then
            healthLabel.Text = string.format("HP: %d/%d", math.floor(humanoid.Health), humanoid.MaxHealth)
        end
    end

    return updateESP
end

-- Function to handle player ESP
local function handlePlayerESP(player)
    local function onCharacterAdded(character)
        if _G.HighlightEnabled then
            createHighlight(character)
        end

        local updateESPFunc = createOrUpdateESPUI(character, player.Name)
        RunService.RenderStepped:Connect(function()
            if _G.ESPEnabled then
                updateESPFunc()
            end
        end)
    end

    player.CharacterAdded:Connect(onCharacterAdded)
    if player.Character then
        onCharacterAdded(player.Character)
    end
end

-- Apply ESP to all players in-game and new ones joining
for _, player in ipairs(Players:GetPlayers()) do
    handlePlayerESP(player)
end
Players.PlayerAdded:Connect(handlePlayerESP)
