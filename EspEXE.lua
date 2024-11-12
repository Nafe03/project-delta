-- Made by Blissful#4992

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

-- Local Player Info
local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ESP Settings
_G.HealthESPEnabled = false
_G.NameESPEnabled = false
_G.BoxESPEnabled = false
_G.DistanceESPEnabled = false
_G.HighlightEnabled = false
_G.HighlightColor = Color3.fromRGB(0, 255, 0) -- Default highlight color
_G.BoxColor = Color3.fromRGB(255, 255, 255) -- Default box color
_G.HealthTextColor = TextColor3.fromRGB(255, 255, 255)

-- Function to create ESP Highlight
local function createHighlight(character)
    local highlight = character:FindFirstChild("Highlight") or Instance.new("Highlight")
    highlight.Parent = character
    highlight.FillColor = _G.HighlightColor
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
    highlight.OutlineTransparency = 0
    return highlight
end

-- Function to create Distance, Name, and Health Bar ESP UI
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
    healthLabel.Visible = _G.HealthESPEnabled

    -- Health Bar Background
    local healthBarBackground = Instance.new("Frame", billboardGui)
    healthBarBackground.Size = UDim2.new(1, 0, 0.1, 0)
    healthBarBackground.Position = UDim2.new(0, 0, 0.3, 0)
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

        local playerDistance = (Player.Character.PrimaryPart.Position - character.PrimaryPart.Position).Magnitude
        distanceLabel.Visible = _G.DistanceESPEnabled
        distanceLabel.Text = string.format("%.1f studs", playerDistance)

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

        if _G.NameESPEnabled then
            local NameESPEnabled = humanoid.Name
            nameLabel.Size = UDim2.new(healthFraction, 0, 1, 0)
            nameLabel.BackgroundColor3 = Color3.fromRGB(255 * (1 - healthFraction), 255 * healthFraction, 0)
            nameLabel.Text = string.format("HP: %d/%d", humanoid.Name)
            nameLabel.Visible = true
        else
            nameLabel.Size = UDim2.new(0, 0, 0, 0)
            nameLabel.Visible = false
        end
    end

    return updateESP
end

-- Function to Draw 2D Box ESP around a player
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
                    -- Calculate box corners
                    local TopLeft = Camera:WorldToViewportPoint((character.PrimaryPart.CFrame * CFrame.new(-2, 3, 0)).Position)
                    local TopRight = Camera:WorldToViewportPoint((character.PrimaryPart.CFrame * CFrame.new(2, 3, 0)).Position)
                    local BottomLeft = Camera:WorldToViewportPoint((character.PrimaryPart.CFrame * CFrame.new(-2, -3, 0)).Position)
                    local BottomRight = Camera:WorldToViewportPoint((character.PrimaryPart.CFrame * CFrame.new(2, -3, 0)).Position)

                    Box.PointA = Vector2.new(TopRight.X, TopRight.Y)
                    Box.PointB = Vector2.new(TopLeft.X, TopLeft.Y)
                    Box.PointC = Vector2.new(BottomLeft.X, BottomLeft.Y)
                    Box.PointD = Vector2.new(BottomRight.X, BottomRight.Y)
                    Box.Visible = _G.BoxESPEnabled
                    Box.Color = _G.BoxColor -- Update box color dynamically
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
    local Humanoid = Character:WaitForChild("Humanoid")

    if _G.HighlightEnabled then
        local highlight = createHighlight(Character)
        highlight.FillColor = _G.HighlightColor
    end

    local updateESPFunc = createESPUI(Character, Player.Name)

    updateESPFunc()
    DrawESPBox(Player)

    RunService.RenderStepped:Connect(function()
        updateESPFunc()
        if _G.HighlightEnabled then
            highlight.Enabled = true
        end
    end)
end

-- Function to initialize ESP for all players
local function initializeESP(Player)
    Player.CharacterAdded:Connect(function()
        applyESP(Player)
    end)
    if Player.Character then
        applyESP(Player)
    end
end

-- Apply ESP to all players in-game and new ones joining
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

-- Change highlight color
local function setHighlightColor(newColor)
    _G.HighlightColor = newColor
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player.Character then
            applyESP(Player)
        end
    end
end

-- Change box color
local function setBoxColor(newColor)
    _G.BoxColor = newColor
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player.Character then
            applyESP(Player)
        end
    end
end

local function setHealthTextColor(newColor)
    _G.HealthTextColor = newColor
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player.Character then
            applyESP(Player)
        end
    end
end

-- Example UI toggle functions
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

-- Change color example
setHighlightColor(Color3.fromRGB(255, 255, 255)) -- Set highlight to red
setBoxColor(Color3.fromRGB(255, 255, 255)) -- Set box color to green
setHealthTextColor(Color3.fromRGB(255, 255, 255)) -- Set box color to green
