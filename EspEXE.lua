-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- ESP Settings
_G.HealthESPEnabled = false
_G.NameESPEnabled = false
_G.BoxESPEnabled = false
_G.DistanceESPEnabled = false
_G.HighlightColor = Color3.fromRGB(0, 255, 0)  -- Default green color for highlight

-- Function to create a new Highlight instance
local function createHighlight(character, color)
    local highlight = Instance.new("Highlight", character)
    highlight.FillColor = color or _G.HighlightColor
    highlight.FillTransparency = 0.5  -- Semi-transparent
    return highlight
end

-- Function to create Distance and Health Bar ESP
local function createDistanceAndHealthESP(character, playerName)
    local billboardGui = Instance.new("BillboardGui", character)
    billboardGui.Size = UDim2.new(0, 150, 0, 100)
    billboardGui.Adornee = character:WaitForChild("Head")
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

    -- Health Bar Background
    local healthBarBackground = Instance.new("Frame", billboardGui)
    healthBarBackground.Size = UDim2.new(1, 0, 0.1, 0)
    healthBarBackground.Position = UDim2.new(0, 0, 0.35, 0)
    healthBarBackground.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    healthBarBackground.BorderSizePixel = 0

    -- Health Bar
    local healthBar = Instance.new("Frame", healthBarBackground)
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthBar.BorderSizePixel = 0

    -- Update distance label and health bar
    local function updateDistanceAndHealth()
        local playerDistance = (Players.LocalPlayer.Character.PrimaryPart.Position - character.PrimaryPart.Position).Magnitude
        distanceLabel.Text = string.format("%s - %.1f studs", playerName, playerDistance)

        if _G.HealthESPEnabled then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                local healthFraction = humanoid.Health / humanoid.MaxHealth
                healthBar.Size = UDim2.new(healthFraction, 0, 1, 0)
                healthBar.BackgroundColor3 = Color3.fromRGB(255 * (1 - healthFraction), 255 * healthFraction, 0)
            end
        else
            healthBar.Size = UDim2.new(0, 0, 0, 0)
        end
    end

    return updateDistanceAndHealth
end

-- Function to apply highlights to the player
local function ApplyHighlight(Player)
    local Character = Player.Character or Player.CharacterAdded:Wait()
    local Humanoid = Character:WaitForChild("Humanoid")
    
    -- Clear any existing highlights
    if Character:FindFirstChild("Highlight") then
        Character:FindFirstChild("Highlight"):Destroy()
    end
    
    local highlight = createHighlight(Character, _G.HighlightColor)
    local updateDistanceAndHealthFunc

    -- Update fill color based on team color or specified color
    local function UpdateFillColor()
        highlight.FillColor = _G.HighlightColor or (Player.TeamColor and Player.TeamColor.Color)
    end

    -- Health ESP: Change highlight transparency based on health
    local function UpdateHealthTransparency()
        if _G.HealthESPEnabled and Humanoid.Health > 0 then
            highlight.FillTransparency = 1 - (Humanoid.Health / Humanoid.MaxHealth)
        else
            highlight.FillTransparency = 1
        end
    end

    if _G.DistanceESPEnabled then
        updateDistanceAndHealthFunc = createDistanceAndHealthESP(Character, Player.Name)
        updateDistanceAndHealthFunc()
        local connection = RunService.RenderStepped:Connect(function()
            updateDistanceAndHealthFunc()
            UpdateHealthTransparency()
        end)

        -- Disconnect when player dies or character is removed
        Humanoid.Died:Connect(function()
            connection:Disconnect()
            highlight:Destroy()
        end)
    end

    -- Connect events for dynamic updates
    Player:GetPropertyChangedSignal("TeamColor"):Connect(UpdateFillColor)
    Humanoid:GetPropertyChangedSignal("Health"):Connect(UpdateHealthTransparency)

    -- Initial updates
    UpdateFillColor()
    UpdateHealthTransparency()
end

-- Function to apply highlights when player spawns or joins
local function HighlightPlayer(Player)
    Player.CharacterAdded:Connect(function(character)
        ApplyHighlight(Player)
    end)

    if Player.Character then
        ApplyHighlight(Player)
    end
end

-- Apply highlights to all existing players and new ones
for _, Player in ipairs(Players:GetPlayers()) do
    HighlightPlayer(Player)
end
Players.PlayerAdded:Connect(HighlightPlayer)

-- Function to enable or disable ESP features
local function setESPEnabled(setting, enabled)
    _G[setting] = enabled
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player.Character then
            ApplyHighlight(Player)
        end
    end
end

-- Function to change the highlight color dynamically
local function setHighlightColor(newColor)
    _G.HighlightColor = newColor
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player.Character then
            ApplyHighlight(Player)
        end
    end
end

-- Example UI connection (connect these to your UI)
local function onHealthESPToggle(newState)
    setESPEnabled("HealthESPEnabled", newState)
end

local function onNameESPToggle(newState)
    setESPEnabled("NameESPEnabled", newState)
end

local function onBoxESPToggle(newState)
    setESPEnabled("BoxESPEnabled", newState)
end

local function onDistanceESPToggle(newState)
    setESPEnabled("DistanceESPEnabled", newState)
end

-- Example usage to change highlight color
setHighlightColor(Color3.fromRGB(255, 0, 0))  -- Change highlight to red
