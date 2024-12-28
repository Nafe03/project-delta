-- Enhanced ESP System
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ESP Settings (preserved from original)
_G.ESPEnabled = true
_G.HealthESPEnabled = true
_G.NameESPEnabled = true
_G.BoxESPEnabled = true
_G.DistanceESPEnabled = true
_G.HighlightEnabled = true

_G.HighlightColor = Color3.fromRGB(0, 255, 0)
_G.BoxColor = Color3.fromRGB(255, 255, 255)
_G.HealthTextColor = Color3.fromRGB(255, 255, 255)

-- Create ESP Container
local ESP = {
    Players = {},
    Enabled = _G.ESPEnabled,
    HealthEnabled = _G.HealthESPEnabled,
    NamesEnabled = _G.NameESPEnabled,
    BoxesEnabled = _G.BoxESPEnabled,
    DistanceEnabled = _G.DistanceESPEnabled,
    HighlightEnabled = _G.HighlightEnabled
}

-- ESP Components Constructor
local function CreateESPComponents()
    local Components = {}
    
    -- Create Container
    local BillboardGui = Instance.new("BillboardGui")
    BillboardGui.Name = "ESP"
    BillboardGui.AlwaysOnTop = true
    BillboardGui.Size = UDim2.new(0, 200, 0, 50)
    BillboardGui.StudsOffset = Vector3.new(0, 2.5, 0)
    
    -- Name ESP
    local Name = Instance.new("TextLabel")
    Name.Name = "PlayerName"
    Name.BackgroundTransparency = 1
    Name.Size = UDim2.new(1, 0, 0, 20)
    Name.Font = Enum.Font.GothamBold
    Name.TextColor3 = Color3.new(1, 1, 1)
    Name.TextScaled = true
    Name.TextStrokeTransparency = 0.5
    Name.Parent = BillboardGui
    
    -- Health Bar Container
    local HealthBarBG = Instance.new("Frame")
    HealthBarBG.Name = "HealthBarBG"
    HealthBarBG.BorderSizePixel = 0
    HealthBarBG.BackgroundColor3 = Color3.new(0, 0, 0)
    HealthBarBG.BackgroundTransparency = 0.5
    HealthBarBG.Size = UDim2.new(0.8, 0, 0, 4)
    HealthBarBG.Position = UDim2.new(0.1, 0, 0.8, 0)
    HealthBarBG.Parent = BillboardGui
    
    -- Health Bar
    local HealthBar = Instance.new("Frame")
    HealthBar.Name = "HealthBar"
    HealthBar.BorderSizePixel = 0
    HealthBar.BackgroundColor3 = Color3.new(0, 1, 0)
    HealthBar.Size = UDim2.new(1, 0, 1, 0)
    HealthBar.Parent = HealthBarBG
    
    -- Health Text
    local HealthText = Instance.new("TextLabel")
    HealthText.Name = "HealthText"
    HealthText.BackgroundTransparency = 1
    HealthText.Size = UDim2.new(1, 0, 0, 20)
    HealthText.Position = UDim2.new(0, 0, 0.9, 0)
    HealthText.Font = Enum.Font.GothamBold
    HealthText.TextColor3 = _G.HealthTextColor
    HealthText.TextScaled = true
    HealthText.TextStrokeTransparency = 0.5
    HealthText.Parent = BillboardGui
    
    -- Distance Text
    local Distance = Instance.new("TextLabel")
    Distance.Name = "Distance"
    Distance.BackgroundTransparency = 1
    Distance.Size = UDim2.new(1, 0, 0, 20)
    Distance.Position = UDim2.new(0, 0, 1.1, 0)
    Distance.Font = Enum.Font.GothamBold
    Distance.TextColor3 = Color3.new(1, 1, 1)
    Distance.TextScaled = true
    Distance.TextStrokeTransparency = 0.5
    Distance.Parent = BillboardGui
    
    Components.BillboardGui = BillboardGui
    Components.Name = Name
    Components.HealthBarBG = HealthBarBG
    Components.HealthBar = HealthBar
    Components.HealthText = HealthText
    Components.Distance = Distance
    
    return Components
end

-- ESP Update Function
local function UpdateESP(player, components)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or not player.Character:FindFirstChild("Humanoid") then
        return
    end
    
    local character = player.Character
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    -- Update Position
    components.BillboardGui.Adornee = rootPart
    
    -- Update Name
    components.Name.Text = player.Name
    components.Name.Visible = ESP.NamesEnabled
    
    -- Update Health
    local health = humanoid.Health
    local maxHealth = humanoid.MaxHealth
    local healthPercent = health / maxHealth
    
    components.HealthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
    components.HealthBar.BackgroundColor3 = Color3.new(1 - healthPercent, healthPercent, 0)
    components.HealthText.Text = math.floor(health) .. "/" .. math.floor(maxHealth)
    
    components.HealthBarBG.Visible = ESP.HealthEnabled
    components.HealthText.Visible = ESP.HealthEnabled
    
    -- Update Distance
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local distance = (LocalPlayer.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
        components.Distance.Text = math.floor(distance) .. " studs"
        components.Distance.Visible = ESP.DistanceEnabled
    end
    
    -- Update Box ESP
    if ESP.BoxesEnabled then
        -- Create box ESP if it doesn't exist
        if not components.Box then
            components.Box = Drawing.new("Square")
            components.Box.Thickness = 2
            components.Box.Color = _G.BoxColor
            components.Box.Filled = false
        end
        
        -- Update box position
        local rootPos = rootPart.Position
        local screenPos, onScreen = Camera:WorldToViewportPoint(rootPos)
        
        if onScreen then
            local size = Vector2.new(4000 / screenPos.Z, 5000 / screenPos.Z)
            components.Box.Size = size
            components.Box.Position = Vector2.new(screenPos.X - size.X / 2, screenPos.Y - size.Y / 2)
            components.Box.Visible = true
        else
            components.Box.Visible = false
        end
    elseif components.Box then
        components.Box.Visible = false
    end
    
    -- Update Highlight
    if ESP.HighlightEnabled then
        if not components.Highlight then
            components.Highlight = Instance.new("Highlight")
            components.Highlight.FillColor = _G.HighlightColor
            components.Highlight.OutlineColor = Color3.new(1, 1, 1)
            components.Highlight.FillTransparency = 0.5
            components.Highlight.Parent = character
        end
        components.Highlight.Enabled = true
    elseif components.Highlight then
        components.Highlight.Enabled = false
    end
end

-- Player Added Function
local function PlayerAdded(player)
    if player == LocalPlayer then return end
    
    local components = CreateESPComponents()
    ESP.Players[player] = components
    
    RunService.RenderStepped:Connect(function()
        if ESP.Enabled then
            UpdateESP(player, components)
        else
            components.BillboardGui.Enabled = false
            if components.Box then
                components.Box.Visible = false
            end
            if components.Highlight then
                components.Highlight.Enabled = false
            end
        end
    end)
end

-- Initialize
for _, player in pairs(Players:GetPlayers()) do
    PlayerAdded(player)
end

Players.PlayerAdded:Connect(PlayerAdded)

Players.PlayerRemoving:Connect(function(player)
    if ESP.Players[player] then
        -- Clean up ESP components
        for _, component in pairs(ESP.Players[player]) do
            if typeof(component) == "Instance" then
                component:Destroy()
            elseif typeof(component) == "table" and component.Remove then
                component:Remove()
            end
        end
        ESP.Players[player] = nil
    end
end)

-- Toggle Functions
function ESP:ToggleESP(enabled)
    self.Enabled = enabled
    _G.ESPEnabled = enabled
end

function ESP:ToggleHealth(enabled)
    self.HealthEnabled = enabled
    _G.HealthESPEnabled = enabled
end

function ESP:ToggleNames(enabled)
    self.NamesEnabled = enabled
    _G.NameESPEnabled = enabled
end

function ESP:ToggleBoxes(enabled)
    self.BoxesEnabled = enabled
    _G.BoxESPEnabled = enabled
end

function ESP:ToggleDistance(enabled)
    self.DistanceEnabled = enabled
    _G.DistanceESPEnabled = enabled
end

function ESP:ToggleHighlight(enabled)
    self.HighlightEnabled = enabled
    _G.HighlightEnabled = enabled
end

return ESP
