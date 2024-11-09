-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- ESP Settings
_G.HealthESPEnabled = false
_G.NameESPEnabled = false
_G.BoxESPEnabled = false
_G.DistanceESPEnabled = false
_G.HighlightColor = Color3.fromRGB(0, 255, 0)  -- Default color for highlight

-- Function to create highlight for a character
local function createHighlight(character, color)
    local highlight = character:FindFirstChild("Highlight") or Instance.new("Highlight")
    highlight.Parent = character
    highlight.FillColor = color or _G.HighlightColor
    highlight.FillTransparency = 0.5
    return highlight
end

-- Function to create ESP elements (Distance and Health Bars)
local function createBillboardGui(character, playerName)
    local billboardGui = character:FindFirstChild("ESP") or Instance.new("BillboardGui")
    billboardGui.Name = "ESP"
    billboardGui.Size = UDim2.new(0, 150, 0, 100)
    billboardGui.Adornee = character:WaitForChild("Head")
    billboardGui.StudsOffset = Vector3.new(0, 2.5, 0)
    billboardGui.AlwaysOnTop = true
    billboardGui.Parent = character

    local distanceLabel = billboardGui:FindFirstChild("DistanceLabel") or Instance.new("TextLabel")
    distanceLabel.Name = "DistanceLabel"
    distanceLabel.Size = UDim2.new(1, 0, 0.3, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    distanceLabel.TextScaled = true
    distanceLabel.Font = Enum.Font.GothamBold
    distanceLabel.TextStrokeTransparency = 0.5
    distanceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    distanceLabel.Parent = billboardGui

    local healthBarBackground = billboardGui:FindFirstChild("HealthBackground") or Instance.new("Frame")
    healthBarBackground.Name = "HealthBackground"
    healthBarBackground.Size = UDim2.new(1, 0, 0.1, 0)
    healthBarBackground.Position = UDim2.new(0, 0, 0.35, 0)
    healthBarBackground.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    healthBarBackground.BorderSizePixel = 0
    healthBarBackground.Parent = billboardGui

    local healthBar = healthBarBackground:FindFirstChild("HealthBar") or Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthBar.BorderSizePixel = 0
    healthBar.Parent = healthBarBackground

    return distanceLabel, healthBar
end

-- Function to update ESP elements for a player
local function updateESP(player)
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    local distanceLabel, healthBar = createBillboardGui(character, player.Name)
    local highlight = createHighlight(character, _G.HighlightColor)

    local function updateElements()
        local distance = (Players.LocalPlayer.Character.PrimaryPart.Position - character.PrimaryPart.Position).Magnitude
        distanceLabel.Text = _G.DistanceESPEnabled and string.format("%s - %.1f studs", player.Name, distance) or ""
        
        if _G.HealthESPEnabled then
            local healthFraction = humanoid.Health / humanoid.MaxHealth
            healthBar.Size = UDim2.new(healthFraction, 0, 1, 0)
            healthBar.BackgroundColor3 = Color3.fromRGB(255 * (1 - healthFraction), 255 * healthFraction, 0)
            highlight.FillTransparency = 1 - healthFraction
        else
            healthBar.Size = UDim2.new(0, 0, 0, 0)
            highlight.FillTransparency = 1
        end
    end

    local connection = RunService.RenderStepped:Connect(updateElements)
    humanoid.Died:Connect(function()
        connection:Disconnect()
        if character:FindFirstChild("ESP") then character.ESP:Destroy() end
        if character:FindFirstChild("Highlight") then character.Highlight:Destroy() end
    end)

    updateElements()  -- Initial call
end

-- Apply ESP to all players and handle new ones
for _, player in ipairs(Players:GetPlayers()) do
    player.CharacterAdded:Connect(function() updateESP(player) end)
    if player.Character then updateESP(player) end
end
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function() updateESP(player) end)
end)

-- Toggle functions to enable/disable ESP features
local function setESPFeature(setting, enabled)
    _G[setting] = enabled
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then updateESP(player) end
    end
end

-- Change highlight color dynamically
local function setHighlightColor(newColor)
    _G.HighlightColor = newColor
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("Highlight") then
            player.Character.Highlight.FillColor = newColor
        end
    end
end

-- UI Toggle functions (example calls for testing)
local function onHealthESPToggle(state) setESPFeature("HealthESPEnabled", state) end
local function onDistanceESPToggle(state) setESPFeature("DistanceESPEnabled", state) end

-- Example color change
setHighlightColor(Color3.fromRGB(255, 0, 0)) -- Change highlight color to red
