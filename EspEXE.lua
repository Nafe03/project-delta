-- Made by Blissful#4992

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Local Player Info
local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

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

-- Function to create Highlight ESP
local function createHighlight(character)
    local highlight = character:FindFirstChild("Highlight") or Instance.new("Highlight")
    highlight.Parent = character
    highlight.FillColor = _G.HighlightColor
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
    highlight.OutlineTransparency = 0
    highlight.Enabled = _G.HighlightEnabled
end

-- Function to create ESP UI
local function createESPUI(character, playerName)
    local head = character:FindFirstChild("Head")
    if not head then return end

    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 100, 0, 100)
    billboardGui.Adornee = head
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.AlwaysOnTop = true
    billboardGui.Parent = character

    -- Name Label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.3, 0)
    nameLabel.Position = UDim2.new(0, 0, -1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Text = playerName
    nameLabel.Visible = _G.NameESPEnabled
    nameLabel.Parent = billboardGui

    -- Distance Label
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Size = UDim2.new(1, 0, 0.3, 0)
    distanceLabel.Position = UDim2.new(0, 0, 1.3, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    distanceLabel.TextScaled = true
    distanceLabel.Font = Enum.Font.GothamBold
    distanceLabel.Visible = _G.DistanceESPEnabled
    distanceLabel.Parent = billboardGui

    -- Health Bar Background
    local healthBarBackground = Instance.new("Frame")
    healthBarBackground.Size = UDim2.new(1, 0, 0.1, 0)
    healthBarBackground.Position = UDim2.new(0, 0, 0.3, 0)
    healthBarBackground.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    healthBarBackground.BorderSizePixel = 0
    healthBarBackground.Visible = _G.HealthESPEnabled
    healthBarBackground.Parent = billboardGui

    -- Health Bar
    local healthBar = Instance.new("Frame")
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthBar.BorderSizePixel = 0
    healthBar.Parent = healthBarBackground

    -- Update Function
    local function updateESP()
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then return end

        -- Distance Calculation
        local distance = (Player.Character.PrimaryPart.Position - character.PrimaryPart.Position).Magnitude
        distanceLabel.Text = string.format("%.1f studs", distance)

        -- Health Bar Update
        if _G.HealthESPEnabled then
            local healthFraction = humanoid.Health / humanoid.MaxHealth
            healthBar.Size = UDim2.new(healthFraction, 0, 1, 0)
            healthBar.BackgroundColor3 = Color3.fromRGB(255 * (1 - healthFraction), 255 * healthFraction, 0)
        end

        nameLabel.Visible = _G.NameESPEnabled
        distanceLabel.Visible = _G.DistanceESPEnabled
        healthBarBackground.Visible = _G.HealthESPEnabled
    end

    return updateESP
end

-- Function to Create Box ESP
local function createBoxESP(character)
    local box = Drawing.new("Quad")
    box.Visible = false
    box.Color = _G.BoxColor
    box.Thickness = 2
    box.Transparency = 1

    RunService.RenderStepped:Connect(function()
        if character.PrimaryPart and _G.BoxESPEnabled then
            local cframe = character.PrimaryPart.CFrame

            local corners = {
                Camera:WorldToViewportPoint((cframe * CFrame.new(2, 3, 0)).Position),
                Camera:WorldToViewportPoint((cframe * CFrame.new(-2, 3, 0)).Position),
                Camera:WorldToViewportPoint((cframe * CFrame.new(-2, -3, 0)).Position),
                Camera:WorldToViewportPoint((cframe * CFrame.new(2, -3, 0)).Position)
            }

            box.PointA = Vector2.new(corners[1].X, corners[1].Y)
            box.PointB = Vector2.new(corners[2].X, corners[2].Y)
            box.PointC = Vector2.new(corners[3].X, corners[3].Y)
            box.PointD = Vector2.new(corners[4].X, corners[4].Y)
            box.Visible = true
        else
            box.Visible = false
        end
    end)
end

-- Apply ESP to Each Player
local function applyESP(player)
    player.CharacterAdded:Connect(function(character)
        if _G.HighlightEnabled then createHighlight(character) end
        local updateFunc = createESPUI(character, player.Name)
        createBoxESP(character)

        RunService.RenderStepped:Connect(function()
            if _G.ESPEnabled then
                updateFunc()
            end
        end)
    end)

    if player.Character then
        applyESP(player)
    end
end

-- Initialize ESP for All Players
for _, player in ipairs(Players:GetPlayers()) do
    applyESP(player)
end
Players.PlayerAdded:Connect(applyESP)

-- Toggle ESP Features
local function toggleESPFeature(feature, state)
    _G[feature] = state
end

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

local function onHighlightToggle(newState)
    toggleESPFeature("HighlightEnabled", newState)
end

-- Example color change usage
local function setHighlightColor(newColor)
    _G.HighlightColor = newColor
end

local function setBoxColor(newColor)
    _G.BoxColor = newColor
end

local function setHealthTextColor(newColor)
    _G.HealthTextColor = newColor
end

setHighlightColor(Color3.fromRGB(255, 0, 0)) -- Changes highlight to red
setBoxColor(Color3.fromRGB(0, 255, 0)) -- Changes box to green
setHealthTextColor(Color3.fromRGB(255, 255, 255)) -- Sets health text
