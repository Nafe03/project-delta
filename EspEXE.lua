-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DefaultColor = Color3.fromRGB(0, 0, 0)

-- ESP Settings
local ESPSettings = {
    HealthESPEnabled = true,
    NameESPEnabled = true,
    BoxESPEnabled = true,
    DistanceESPEnabled = true,
}

-- Function to create a new Highlight instance
local function createHighlight(character)
    local highlight = Instance.new("Highlight", character)
    highlight.FillColor = DefaultColor
    highlight.FillTransparency = 0.5  -- Start semi-transparent
    return highlight
end

-- Function to create Box ESP
local function createBoxESP(character)
    local boxESP = Instance.new("BoxHandleAdornment")
    boxESP.Size = character:GetExtentsSize() + Vector3.new(0.2, 0.2, 0.2) -- Slightly larger
    boxESP.Adornee = character
    boxESP.Color3 = Color3.fromRGB(255, 0, 0)
    boxESP.Transparency = 0.5
    boxESP.ZIndex = 5
    boxESP.AlwaysOnTop = true
    boxESP.Parent = character
    return boxESP
end

-- Function to create Distance ESP
local function createDistanceESP(character, playerName)
    local billboardGui = Instance.new("BillboardGui", character)
    billboardGui.Size = UDim2.new(0, 100, 0, 50)
    billboardGui.Adornee = character:WaitForChild("Head")
    billboardGui.StudsOffset = Vector3.new(0, 2, 0)
    billboardGui.AlwaysOnTop = true

    local nameLabel = Instance.new("TextLabel", billboardGui)
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true

    -- Update distance label
    local function updateDistance()
        local playerDistance = (Players.LocalPlayer.Character.PrimaryPart.Position - character.PrimaryPart.Position).Magnitude
        nameLabel.Text = string.format("%s - %.1f studs", playerName, playerDistance)
    end

    return updateDistance
end

-- Function to apply highlights to the player
local function ApplyHighlight(Player)
    local Character = Player.Character or Player.CharacterAdded:Wait()
    local Humanoid = Character:WaitForChild("Humanoid")
    local highlight = createHighlight(Character)

    local boxESP
    local updateDistanceFunc

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

    -- Create ESP elements
    if ESPSettings.BoxESPEnabled then
        boxESP = createBoxESP(Character)
    end

    if ESPSettings.DistanceESPEnabled then
        updateDistanceFunc = createDistanceESP(Character, Player.Name)
        updateDistanceFunc()  -- Initial update
        local connection = RunService.RenderStepped:Connect(updateDistanceFunc)
        -- Disconnect when player dies or character is removed
        Humanoid.Died:Connect(function()
            connection:Disconnect()
            if boxESP then boxESP:Destroy() end
        end)
    end

    -- Connect events for dynamic updates
    Player:GetPropertyChangedSignal("TeamColor"):Connect(UpdateFillColor)
    Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        if Humanoid.Health <= 0 then
            highlight:Destroy()
            if boxESP then boxESP:Destroy() end
            if updateDistanceFunc then updateDistanceFunc() end
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
            elseif setting == "BoxESPEnabled" then
                if enabled then
                    createBoxESP(Player.Character)
                else
                    local boxESP = Player.Character:FindFirstChildOfClass("BoxHandleAdornment")
                    if boxESP then boxESP:Destroy() end
                end
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
