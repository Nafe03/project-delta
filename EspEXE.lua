local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ESP Settings
_G.ESPEnabled = true
_G.HealthESPEnabled = true
_G.NameESPEnabled = true
_G.BoxESPEnabled = true
_G.DistanceESPEnabled = true
_G.HighlightEnabled = true

_G.HighlightColor = Color3.fromRGB(0, 255, 0)
_G.BoxColor = Color3.fromRGB(255, 255, 255)
_G.HealthTextColor = Color3.fromRGB(255, 255, 255)

-- ESP Components storage
local PlayerESP = {}

-- Create ESP Components for a player
local function CreateESPComponents(player)
    if player == LocalPlayer then return end
    
    local components = {}
    
    -- Billboard GUI
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "ESP_" .. player.Name
    billboardGui.AlwaysOnTop = true
    billboardGui.Size = UDim2.new(0, 200, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 2.5, 0)
    
    -- Name ESP
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameESP"
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextScaled = true
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Parent = billboardGui
    
    -- Health Bar Background
    local healthBarBg = Instance.new("Frame")
    healthBarBg.Name = "HealthBarBg"
    healthBarBg.Size = UDim2.new(0.8, 0, 0, 4)
    healthBarBg.Position = UDim2.new(0.1, 0, 0.7, 0)
    healthBarBg.BackgroundColor3 = Color3.new(0, 0, 0)
    healthBarBg.BorderSizePixel = 0
    healthBarBg.Parent = billboardGui
    
    -- Health Bar
    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.BackgroundColor3 = Color3.new(0, 1, 0)
    healthBar.BorderSizePixel = 0
    healthBar.Parent = healthBarBg
    
    -- Health Text
    local healthText = Instance.new("TextLabel")
    healthText.Name = "HealthText"
    healthText.BackgroundTransparency = 1
    healthText.Size = UDim2.new(1, 0, 0, 20)
    healthText.Position = UDim2.new(0, 0, 0.8, 0)
    healthText.Font = Enum.Font.GothamBold
    healthText.TextColor3 = _G.HealthTextColor
    healthText.TextScaled = true
    healthText.TextStrokeTransparency = 0
    healthText.Parent = billboardGui
    
    -- Distance Text
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Name = "DistanceESP"
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Size = UDim2.new(1, 0, 0, 20)
    distanceLabel.Position = UDim2.new(0, 0, 1, 0)
    distanceLabel.Font = Enum.Font.GothamBold
    distanceLabel.TextColor3 = Color3.new(1, 1, 1)
    distanceLabel.TextScaled = true
    distanceLabel.TextStrokeTransparency = 0
    distanceLabel.Parent = billboardGui
    
    -- Box ESP
    local box = Drawing.new("Square")
    box.Thickness = 2
    box.Filled = false
    
    -- Highlight
    local highlight = Instance.new("Highlight")
    highlight.FillColor = _G.HighlightColor
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.5
    
    components.BillboardGui = billboardGui
    components.NameLabel = nameLabel
    components.HealthBarBg = healthBarBg
    components.HealthBar = healthBar
    components.HealthText = healthText
    components.DistanceLabel = distanceLabel
    components.Box = box
    components.Highlight = highlight
    
    return components
end

-- Update ESP for a player
local function updateESP(player)
    if not player or player == LocalPlayer then return end
    if not PlayerESP[player] then
        PlayerESP[player] = CreateESPComponents(player)
    end
    
    local components = PlayerESP[player]
    if not components then return end
    
    -- Check if ESP is enabled globally
    local isEnabled = _G.ESPEnabled
    components.BillboardGui.Enabled = isEnabled
    components.Box.Visible = isEnabled and _G.BoxESPEnabled
    if components.Highlight then
        components.Highlight.Enabled = isEnabled and _G.HighlightEnabled
    end
    
    -- If ESP is disabled, return early
    if not isEnabled then return end
    
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Humanoid") then
        components.BillboardGui.Enabled = false
        components.Box.Visible = false
        if components.Highlight then components.Highlight.Enabled = false end
        return
    end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    -- Update Billboard GUI position
    components.BillboardGui.Adornee = rootPart
    
    -- Update Name ESP
    components.NameLabel.Text = player.Name
    components.NameLabel.Visible = _G.NameESPEnabled
    
    -- Update Health ESP
    local health = humanoid.Health
    local maxHealth = humanoid.MaxHealth
    local healthPercent = health / maxHealth
    
    components.HealthBarBg.Visible = _G.HealthESPEnabled
    components.HealthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
    components.HealthBar.BackgroundColor3 = Color3.new(1 - healthPercent, healthPercent, 0)
    
    -- Update Health Text
    components.HealthText.Text = math.floor(health) .. "/" .. math.floor(maxHealth)
    components.HealthText.Visible = _G.HealthESPEnabled
    components.HealthText.TextColor3 = _G.HealthTextColor
    
    -- Update Distance ESP
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local distance = (LocalPlayer.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
        components.DistanceLabel.Text = math.floor(distance) .. " studs"
        components.DistanceLabel.Visible = _G.DistanceESPEnabled
    end
    
    -- Update Box ESP
    if _G.BoxESPEnabled then
        local rootPos = rootPart.Position
        local screenPos, onScreen = Camera:WorldToViewportPoint(rootPos)
        
        if onScreen then
            local size = Vector2.new(4000 / screenPos.Z, 5000 / screenPos.Z)
            components.Box.Size = size
            components.Box.Position = Vector2.new(screenPos.X - size.X / 2, screenPos.Y - size.Y / 2)
            components.Box.Color = _G.BoxColor
            components.Box.Visible = true
        else
            components.Box.Visible = false
        end
    else
        components.Box.Visible = false
    end
    
    -- Update Highlight
    if components.Highlight then
        components.Highlight.Parent = _G.HighlightEnabled and character or nil
        components.Highlight.FillColor = _G.HighlightColor
    end
end

-- Clean up ESP components
local function cleanupESP(player)
    local components = PlayerESP[player]
    if components then
        if components.BillboardGui then components.BillboardGui:Destroy() end
        if components.Box then components.Box:Remove() end
        if components.Highlight then components.Highlight:Destroy() end
        PlayerESP[player] = nil
    end
end

-- Initialize ESP for all players
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        task.spawn(function()
            PlayerESP[player] = CreateESPComponents(player)
            updateESP(player)
        end)
    end
end

-- Connect player events
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        task.spawn(function()
            PlayerESP[player] = CreateESPComponents(player)
            updateESP(player)
        end)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    cleanupESP(player)
end)

-- Update ESP every frame
RunService.RenderStepped:Connect(function()
    if _G.ESPEnabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                updateESP(player)
            end
        end
    end
end)

-- Functions to toggle ESP features
local function toggleESP()
    _G.ESPEnabled = not _G.ESPEnabled
end

local function toggleHealthESP()
    _G.HealthESPEnabled = not _G.HealthESPEnabled
end

local function toggleNameESP()
    _G.NameESPEnabled = not _G.NameESPEnabled
end

local function toggleBoxESP()
    _G.BoxESPEnabled = not _G.BoxESPEnabled
end

local function toggleDistanceESP()
    _G.DistanceESPEnabled = not _G.DistanceESPEnabled
end

local function toggleHighlight()
    _G.HighlightEnabled = not _G.HighlightEnabled
end

-- Return toggle functions for use with UI
return {
    toggleESP = toggleESP,
    toggleHealthESP = toggleHealthESP,
    toggleNameESP = toggleNameESP,
    toggleBoxESP = toggleBoxESP,
    toggleDistanceESP = toggleDistanceESP,
    toggleHighlight = toggleHighlight
}
