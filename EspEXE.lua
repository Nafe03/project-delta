-- Made by Blissful#4992, Enhanced ESP Script

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

-- Local Player Info
local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ESP Settings
_G.ESPEnabled = true  
_G.HealthESPEnabled = false
_G.NameESPEnabled = false
_G.BoxESPEnabled = false
_G.DistanceESPEnabled = false
_G.HighlightEnabled = false
_G.HealthTextEnabled = false 
_G.SmoothUpdates = true -- Smoother updates for ESP visuals
_G.HighlightColor = Color3.fromRGB(0, 255, 0)
_G.BoxColor = Color3.fromRGB(255, 255, 255)
_G.HealthTextColor = Color3.fromRGB(255, 255, 255)

-- Function to create Highlight for ESP
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

-- Function to create ESP UI elements for Distance, Name, and Health
local function createESPUI(character, playerName)
    local billboardGui = Instance.new("BillboardGui", character)
    billboardGui.Size = UDim2.new(0, 100, 0, 100)
    billboardGui.Adornee = character:WaitForChild("Head")
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.AlwaysOnTop = true

    -- Name Label
    local nameLabel = Instance.new("TextLabel", billboardGui)
    nameLabel.Size = UDim2.new(1, 0, 0.3, 0)
    nameLabel.Position = UDim2.new(0, 0, -1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Text = playerName
    nameLabel.Visible = _G.NameESPEnabled

    -- Distance Label
    local distanceLabel = Instance.new("TextLabel", billboardGui)
    distanceLabel.Size = UDim2.new(1, 0, 0.3, 0)
    distanceLabel.Position = UDim2.new(0, 0, 1.3, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    distanceLabel.TextScaled = true
    distanceLabel.Font = Enum.Font.GothamBold
    distanceLabel.TextStrokeTransparency = 0.5
    distanceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    distanceLabel.Visible = _G.DistanceESPEnabled

    -- Health Label
    local healthLabel = Instance.new("TextLabel", billboardGui)
    healthLabel.Size = UDim2.new(1, 0, 0.3, 0)
    healthLabel.Position = UDim2.new(0, 0, 0, 0)
    healthLabel.BackgroundTransparency = 1
    healthLabel.TextColor3 = _G.HealthTextColor
    healthLabel.TextScaled = true
    healthLabel.Font = Enum.Font.Arcade
    healthLabel.TextStrokeTransparency = 0.5
    healthLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    healthLabel.Visible = _G.HealthTextEnabled

    -- Health Bar
    local healthBarBackground = Instance.new("Frame", billboardGui)
    healthBarBackground.Size = UDim2.new(1, 0, 0.1, 0)
    healthBarBackground.Position = UDim2.new(0, 0, 0.3, 0)
    healthBarBackground.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    healthBarBackground.BorderSizePixel = 0
    healthBarBackground.Visible = _G.HealthESPEnabled

    local healthBar = Instance.new("Frame", healthBarBackground)
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthBar.BorderSizePixel = 0

    -- Update function for dynamic UI
    local function updateESP()
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then return end

        local playerDistance = (Player.Character.PrimaryPart.Position - character.PrimaryPart.Position).Magnitude
        distanceLabel.Visible = _G.DistanceESPEnabled
        distanceLabel.Text = string.format("%.1f studs", playerDistance)

        if _G.HealthESPEnabled then
            local healthFraction = humanoid.Health / humanoid.MaxHealth
            healthBar.Size = UDim2.new(healthFraction, 0, 1, 0)
            healthBar.BackgroundColor3 = Color3.fromRGB(255 * (1 - healthFraction), 255 * healthFraction, 0)
            healthBarBackground.Visible = true
        else
            healthBarBackground.Visible = false
        end

        if _G.HealthTextEnabled then
            healthLabel.Text = string.format("HP: %d/%d", math.floor(humanoid.Health), humanoid.MaxHealth)
            healthLabel.Visible = true
        else
            healthLabel.Visible = false
        end

        nameLabel.Visible = _G.NameESPEnabled
    end

    return updateESP
end

-- Draws a smooth 2D Box around players
local function DrawESPBox(player)
    local Box = Drawing.new("Quad")
    Box.Visible = false
    Box.Color = _G.BoxColor
    Box.Thickness = 1
    Box.Transparency = 1

    local function UpdateBox()
        RunService.RenderStepped:Connect(function()
            if player.Character and player.Character.PrimaryPart then
                local character = player.Character
                local pos, vis = Camera:WorldToViewportPoint(character.PrimaryPart.Position)
                if vis then
                    local TopLeft = Camera:WorldToViewportPoint((character.PrimaryPart.CFrame * CFrame.new(-2, 3, 0)).Position)
                    local TopRight = Camera:WorldToViewportPoint((character.PrimaryPart.CFrame * CFrame.new(2, 3, 0)).Position)
                    local BottomLeft = Camera:WorldToViewportPoint((character.PrimaryPart.CFrame * CFrame.new(-2, -3, 0)).Position)
                    local BottomRight = Camera:WorldToViewportPoint((character.PrimaryPart.CFrame * CFrame.new(2, -3, 0)).Position)

                    Box.PointA = Vector2.new(TopRight.X, TopRight.Y)
                    Box.PointB = Vector2.new(TopLeft.X, TopLeft.Y)
                    Box.PointC = Vector2.new(BottomLeft.X, BottomLeft.Y)
                    Box.PointD = Vector2.new(BottomRight.X, BottomRight.Y)
                    Box.Visible = _G.BoxESPEnabled
                    Box.Color = _G.BoxColor
                else
                    Box.Visible = false
                end
            else
                Box.Visible = false
            end
        end)
    end

    UpdateBox()
end

-- Apply ESP to each player
local function applyESP(Player)
    local Character = Player.Character or Player.CharacterAdded:Wait()
    if _G.HighlightEnabled then
        createHighlight(Character)
    end

    local updateESPFunc = createESPUI(Character, Player.Name)
    DrawESPBox(Player)

    RunService.RenderStepped:Connect(function()
        if _G.ESPEnabled then
            updateESPFunc()
        end
    end)
end

-- Initialize ESP for all players
local function initializeESP(Player)
    Player.CharacterAdded:Connect(function()
        applyESP(Player)
    end)
    if Player.Character then
        applyESP(Player)
    end
end

-- Apply ESP to all players and any new players
for _, Player in ipairs(Players:GetPlayers()) do
    initializeESP(Player)
end
Players.PlayerAdded:Connect(initializeESP)

-- Toggle ESP features dynamically
local function toggleESPFeature(feature, state)
    _G[feature] = state
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player.Character then
            applyESP(Player)
        end
    end
end

-- Set colors dynamically
local function setHighlightColor(newColor)
    _G.HighlightColor = newColor
end

local function setBoxColor(newColor)
    _G.BoxColor = newColor
end

local function setHealthTextColor(newColor)
    _G.HealthTextColor = newColor
end

-- Example usage for toggles and color changes
setHighlightColor(Color3.fromRGB(255, 0, 0))
setBoxColor(Color3.fromRGB(0, 255, 0))
setHealthTextColor(Color3.fromRGB(255, 255, 255))
