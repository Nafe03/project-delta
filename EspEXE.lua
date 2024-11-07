-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- ESP Settings
local ESPSettings = {
    HealthESPEnabled = false,
    NameESPEnabled = true,
    BoxESPEnabled = false,
    DistanceESPEnabled = true,
    HighlightColor = Color3.fromRGB(0, 255, 0)  -- Default highlight color
}

-- Function to create a highlight for a character
local function createHighlight(character)
    local highlight = character:FindFirstChild("Highlight") or Instance.new("Highlight")
    highlight.Parent = character
    highlight.FillColor = ESPSettings.HighlightColor
    highlight.FillTransparency = 0
    return highlight
end

-- Function to create Distance and Health ESP
local function createESPUI(character, playerName)
    local billboardGui = Instance.new("BillboardGui", character)
    billboardGui.Size = UDim2.new(0, 150, 0, 100)
    billboardGui.Adornee = character:FindFirstChild("Head")
    billboardGui.StudsOffset = Vector3.new(0, 2.5, 0)
    billboardGui.AlwaysOnTop = true

    -- Distance Label
    local distanceLabel = Instance.new("TextLabel", billboardGui)
    distanceLabel.Size = UDim2.new(1, 0, 0.3, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    distanceLabel.TextScaled = true
    distanceLabel.Font = Enum.Font.GothamBold
    distanceLabel.TextStrokeTransparency = 0.5
    distanceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

    -- Health Bar
    local healthBarBackground = Instance.new("Frame", billboardGui)
    healthBarBackground.Size = UDim2.new(1, 0, 0.1, 0)
    healthBarBackground.Position = UDim2.new(0, 0, 0.35, 0)
    healthBarBackground.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    healthBarBackground.BorderSizePixel = 0

    local healthBar = Instance.new("Frame", healthBarBackground)
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthBar.BorderSizePixel = 0

    -- Function to update ESP components
    local function updateESP()
        local playerDistance = (Players.LocalPlayer.Character.PrimaryPart.Position - character.PrimaryPart.Position).Magnitude
        distanceLabel.Text = string.format("%s - %.1f studs", playerName, playerDistance)

        if ESPSettings.HealthESPEnabled then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                local healthFraction = humanoid.Health / humanoid.MaxHealth
                healthBar.Size = UDim2.new(healthFraction, 0, 1, 0)
                healthBar.BackgroundColor3 = Color3.fromRGB(255 * (1 - healthFraction), 255 * healthFraction, 0)
            end
        end
    end
    return updateESP
end

-- Function to apply ESP highlights and UI to a player
local function applyESP(Player)
    local character = Player.Character or Player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")

    -- Setup or update highlight
    local highlight = createHighlight(character)
    local updateESPFunc = createESPUI(character, Player.Name)

    -- Update highlight color and transparency dynamically
    local function updateHighlightProperties()
        highlight.FillColor = ESPSettings.HighlightColor
        if ESPSettings.HealthESPEnabled and humanoid.Health > 0 then
            highlight.FillTransparency = 1 - (humanoid.Health / humanoid.MaxHealth)
        else
            highlight.FillTransparency = 1
        end
    end

    -- Initial update and connection to update every frame
    updateESPFunc()
    updateHighlightProperties()
    local connection = RunService.RenderStepped:Connect(function()
        updateESPFunc()
        updateHighlightProperties()
    end)

    -- Disconnect connections when character dies
    humanoid.Died:Connect(function()
        connection:Disconnect()
        highlight:Destroy()
    end)

    -- Update highlight color if player's team changes
    Player:GetPropertyChangedSignal("TeamColor"):Connect(function()
        highlight.FillColor = Player.TeamColor.Color or ESPSettings.HighlightColor
    end)
end

-- Function to enable or disable ESP features
local function toggleESPFeature(setting, state)
    ESPSettings[setting] = state
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            applyESP(player)
        end
    end
end

-- Function to dynamically change highlight color
local function updateHighlightColor(newColor)
    ESPSettings.HighlightColor = newColor
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            applyESP(player)  -- Reapply highlight with new color
        end
    end
    print("Highlight color updated to:", newColor)
end

-- Apply ESP for players in-game and new players joining
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        applyESP(player)
    end)
    if player.Character then
        applyESP(player)
    end
end)

-- Initialize ESP for all existing players
for _, player in ipairs(Players:GetPlayers()) do
    applyESP(player)
end

-- Example usage of toggling ESP features (connect these to UI buttons)
toggleESPFeature("HealthESPEnabled", true)
toggleESPFeature("DistanceESPEnabled", true)
updateHighlightColor(Color3.fromRGB(255, 0, 0)) -- Change highlight to red
