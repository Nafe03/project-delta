-- Services
-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DefaultColor = Color3.fromRGB(0, 255, 0)  -- Green color for highlight

-- ESP Settings
local ESPSettings = {
    HealthESPEnabled = true,
    NameESPEnabled = true,
    BoxESPEnabled = false,
    DistanceESPEnabled = true,
}

-- Function to create a new Highlight instance
local function createHighlight(character)
    local highlight = Instance.new("Highlight", character)
    highlight.FillColor = DefaultColor  -- Set to green
    highlight.FillTransparency = 0.5  -- Semi-transparent
    return highlight
end

-- Function to create Distance and Health Bar ESP
local function createDistanceAndHealthESP(character, playerName)
    local billboardGui = Instance.new("BillboardGui", character)
    billboardGui.Size = UDim2.new(0, 150, 0, 100)
    billboardGui.Adornee = character:WaitForChild("Head")
    billboardGui.StudsOffset = Vector3.new(0, 2.5, 0)  -- Above the player's head
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
    healthBarBackground.Position = UDim2.new(0, 0, 0.35, 0)  -- Position above the arm
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

        if ESPSettings.HealthESPEnabled then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                local healthFraction = humanoid.Health / humanoid.MaxHealth
                healthBar.Size = UDim2.new(healthFraction, 0, 1, 0)
                healthBar.BackgroundColor3 = Color3.fromRGB(255 * (1 - healthFraction), 255 * healthFraction, 0)  -- Color shifts from red to green
            end
        end
    end

    return updateDistanceAndHealth
end

-- Function to apply highlights to the player
local function ApplyHighlight(Player)
    local Character = Player.Character or Player.CharacterAdded:Wait()
    local Humanoid = Character:WaitForChild("Humanoid")
    local highlight = createHighlight(Character)

    local updateDistanceAndHealthFunc

    -- Update fill color based on team color
    local function UpdateFillColor()
        highlight.FillColor = (Player.TeamColor and Player.TeamColor.Color) or DefaultColor
    end

    -- Health ESP: Change highlight transparency based on health
    local function UpdateHealthTransparency()
        if ESPSettings.HealthESPEnabled and Humanoid.Health > 0 then
            highlight.FillTransparency = 1 - (Humanoid.Health / Humanoid.MaxHealth)
        else
            highlight.FillTransparency = 1
        end
    end

    if ESPSettings.DistanceESPEnabled then
        updateDistanceAndHealthFunc = createDistanceAndHealthESP(Character, Player.Name)
        updateDistanceAndHealthFunc()  -- Initial update
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
    Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        if Humanoid.Health <= 0 then
            highlight:Destroy()
            if updateDistanceAndHealthFunc then updateDistanceAndHealthFunc() end
        else
            UpdateHealthTransparency()
        end
    end)

    -- Initial updates
    UpdateFillColor()
    UpdateHealthTransparency()
end

-- Function to apply highlights when player spawns or joins
local function HighlightPlayer(Player)
    if Player.Character then
        ApplyHighlight(Player)
    end
    Player.CharacterAdded:Connect(function()
        ApplyHighlight(Player)
    end)
end

-- Apply highlights to all existing players and new ones
for _, Player in next, Players:GetPlayers() do
    HighlightPlayer(Player)
end
Players.PlayerAdded:Connect(HighlightPlayer)

-- Function to enable or disable ESP features
local function setESPEnabled(setting, enabled)
    ESPSettings[setting] = enabled
    for _, Player in next, Players:GetPlayers() do
        if Player.Character then
            if setting == "HealthESPEnabled" then
                UpdateHealthTransparency(Player.Character:FindFirstChild("Humanoid"))
            elseif setting == "DistanceESPEnabled" then
                -- Handle Distance ESP toggle here
            end
        end
    end
end

-- Example UI connection (you would connect these to your UI)
local function onHealthESPToggle(newState)
    setESPEnabled("HealthESPEnabled", newState)
    print("Health ESP:", newState and "Enabled" or "Disabled")
end

local function onNameESPToggle(newState)
    setESPEnabled("NameESPEnabled", newState)
    print("Name ESP:", newState and "Enabled" or "Disabled")
end

local function onBoxESPToggle(newState)
    setESPEnabled("BoxESPEnabled", newState)
    print("Box ESP:", newState and "Enabled" or "Disabled")
end

local function onDistanceESPToggle(newState)
    setESPEnabled("DistanceESPEnabled", newState)
    print("Distance ESP:", newState and "Enabled" or "Disabled")
end

-- Example calls (you would connect these to your UI)
-- onHealthESPToggle(true)
-- onHealthESPToggle(false)
-- onNameESPToggle(true)
-- onNameESPToggle(false)
-- onBoxESPToggle(true)
-- onBoxESPToggle(false)
-- onDistanceESPToggle(true)
-- onDistanceESPToggle(false)
