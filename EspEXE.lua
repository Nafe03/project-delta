-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- ESP Settings stored in _G for global access
_G.HealthESPEnabled = false
_G.NameESPEnabled = false
_G.BoxESPEnabled = false
_G.DistanceESPEnabled = false
_G.HighlightColor = Color3.fromRGB(0, 255, 0)  -- Default highlight color

-- Function to create a new Highlight instance
local function createHighlight(character, color)
    local highlight = character:FindFirstChild("Highlight") or Instance.new("Highlight")
    highlight.Parent = character
    highlight.FillColor = color or _G.HighlightColor
    highlight.FillTransparency = 0.5
    return highlight
end

-- Function to create Distance, Name, and Health Bar ESP UI
local function createESPUI(character, playerName)
    local billboardGui = Instance.new("BillboardGui", character)
    billboardGui.Size = UDim2.new(0, 150, 0, 100)
    billboardGui.Adornee = character:WaitForChild("Head")
    billboardGui.StudsOffset = Vector3.new(0, 2.5, 0)
    billboardGui.AlwaysOnTop = true

    -- Distance Label
    local distanceLabel = Instance.new("TextLabel", billboardGui)
    distanceLabel.Size = UDim2.new(1, 0, 0.3, 0)
    distanceLabel.Position = UDim2.new(0, 0, 0, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    distanceLabel.TextScaled = true
    distanceLabel.Font = Enum.Font.GothamBold
    distanceLabel.TextStrokeTransparency = 0.5
    distanceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

    -- Health Label
    local healthLabel = Instance.new("TextLabel", billboardGui)
    healthLabel.Size = UDim2.new(1, 0, 0.3, 0)
    healthLabel.Position = UDim2.new(0, 0, 0.3, 0)
    healthLabel.BackgroundTransparency = 1
    healthLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    healthLabel.TextScaled = true
    healthLabel.Font = Enum.Font.GothamBold
    healthLabel.TextStrokeTransparency = 0.5
    healthLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

    -- Health Bar Background
    local healthBarBackground = Instance.new("Frame", billboardGui)
    healthBarBackground.Size = UDim2.new(1, 0, 0.1, 0)
    healthBarBackground.Position = UDim2.new(0, 0, 0.6, 0)
    healthBarBackground.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    healthBarBackground.BorderSizePixel = 0

    -- Health Bar
    local healthBar = Instance.new("Frame", healthBarBackground)
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthBar.BorderSizePixel = 0

    -- Update function for Distance, Name, and Health
    local function updateESP()
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then return end
        
        local playerDistance = (Players.LocalPlayer.Character.PrimaryPart.Position - character.PrimaryPart.Position).Magnitude
        distanceLabel.Visible = _G.DistanceESPEnabled
        distanceLabel.Text = string.format("%s - %.1f studs", playerName, playerDistance)

        if _G.HealthESPEnabled then
            local healthFraction = humanoid.Health / humanoid.MaxHealth
            healthBar.Size = UDim2.new(healthFraction, 0, 1, 0)
            healthBar.BackgroundColor3 = Color3.fromRGB(255 * (1 - healthFraction), 255 * healthFraction, 0)
            healthLabel.Text = string.format("HP: %d/%d", math.floor(humanoid.Health), humanoid.MaxHealth)
            healthLabel.Visible = true
        else
            healthBar.Size = UDim2.new(0, 0, 0, 0)
            healthLabel.Visible = false
        end
    end

    return updateESP
end

-- Function to apply ESP to a player
local function applyESP(Player)
    local Character = Player.Character or Player.CharacterAdded:Wait()
    local Humanoid = Character:WaitForChild("Humanoid")

    -- Setup highlight
    local highlight = createHighlight(Character, _G.HighlightColor)
    local updateESPFunc = createESPUI(Character, Player.Name)

    -- Update functions for highlight
    local function updateHighlight()
        highlight.FillColor = _G.HighlightColor
        highlight.Enabled = _G.HealthESPEnabled or _G.DistanceESPEnabled or _G.NameESPEnabled
        if _G.HealthESPEnabled and Humanoid.Health > 0 then
            highlight.FillTransparency = 1 - (Humanoid.Health / Humanoid.MaxHealth)
        else
            highlight.FillTransparency = 1
        end
    end

    -- Initial and dynamic updates for ESP and highlight
    updateESPFunc()
    updateHighlight()
    local connection = RunService.RenderStepped:Connect(function()
        updateESPFunc()
        updateHighlight()
    end)

    -- Disconnect when player dies
    Humanoid.Died:Connect(function()
        connection:Disconnect()
        highlight:Destroy()
    end)

    -- Update on team or health change
    Player:GetPropertyChangedSignal("TeamColor"):Connect(updateHighlight)
    Humanoid:GetPropertyChangedSignal("Health"):Connect(updateHighlight)
end

-- Apply ESP to all players in-game and future players
local function initializeESP(Player)
    Player.CharacterAdded:Connect(function()
        applyESP(Player)
    end)
    if Player.Character then
        applyESP(Player)
    end
end

-- Set up ESP for all current players and connect PlayerAdded event
for _, Player in ipairs(Players:GetPlayers()) do
    initializeESP(Player)
end
Players.PlayerAdded:Connect(initializeESP)

-- Function to enable or disable ESP features dynamically
local function toggleESPFeature(feature, state)
    _G[feature] = state
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player.Character then
            applyESP(Player)
        end
    end
end

-- Function to change the highlight color dynamically
local function setHighlightColor(newColor)
    _G.HighlightColor = newColor
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player.Character then
            applyESP(Player)
        end
    end
end

-- Example UI connections for toggling features
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

-- Example usage for changing highlight color
setHighlightColor(Color3.fromRGB(255, 0, 0)) -- Change highlight to red
