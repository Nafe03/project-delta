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
_G.ESPEnabled = true  -- Master toggle for all ESP
_G.HealthESPEnabled = true
_G.NameESPEnabled = false
_G.BoxESPEnabled = false
_G.DistanceESPEnabled = false
_G.HighlightEnabled = false
_G.HealthTextEnabled = false -- Separate toggle for health text
_G.HighlightColor = Color3.fromRGB(0, 255, 0) -- Default highlight color
_G.BoxColor = Color3.fromRGB(255, 255, 255) -- Default box color
_G.HealthTextColor = Color3.fromRGB(255, 255, 255)

-- Function to create ESP Highlight
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

-- Function to create Distance, Name, and Vertical Health Bar ESP UI
local function createESPUI(character, playerName)
    local billboardGui = character:FindFirstChildOfClass("BillboardGui")
    if not billboardGui then
        billboardGui = Instance.new("BillboardGui", character)
        billboardGui.Size = UDim2.new(0, 100, 0, 100)
        billboardGui.Adornee = character:WaitForChild("Head")
        billboardGui.StudsOffset = Vector3.new(0, 3, 0)
        billboardGui.AlwaysOnTop = true
    end

    -- Name Label
    local nameLabel = billboardGui:FindFirstChild("NameLabel")
    if not nameLabel then
        nameLabel = Instance.new("TextLabel", billboardGui)
        nameLabel.Name = "NameLabel"
        nameLabel.Size = UDim2.new(1, 0, 0.3, 0)
        nameLabel.Position = UDim2.new(0, 0, -1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextStrokeTransparency = 0.5
        nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    end
    nameLabel.Text = playerName
    nameLabel.Visible = _G.NameESPEnabled

    -- Health Bar Container
    local healthBarContainer = billboardGui:FindFirstChild("HealthBarContainer")
    if not healthBarContainer then
        healthBarContainer = Instance.new("Frame", billboardGui)
        healthBarContainer.Name = "HealthBarContainer"
        healthBarContainer.Size = UDim2.new(0.1, 0, 1.5, 0)
        healthBarContainer.Position = UDim2.new(-0.2, 0, 0, 0)
        healthBarContainer.BackgroundTransparency = 1
        healthBarContainer.BorderSizePixel = 0
    end

    -- Health Bar Background
    local healthBarBackground = healthBarContainer:FindFirstChild("HealthBarBackground")
    if not healthBarBackground then
        healthBarBackground = Instance.new("Frame", healthBarContainer)
        healthBarBackground.Name = "HealthBarBackground"
        healthBarBackground.Size = UDim2.new(1, 0, 1, 0)
        healthBarBackground.Position = UDim2.new(0, 0, 0, 0)
        healthBarBackground.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        healthBarBackground.BorderSizePixel = 0
    end

    -- Health Bar
    local healthBar = healthBarBackground:FindFirstChild("HealthBar")
    if not healthBar then
        healthBar = Instance.new("Frame", healthBarBackground)
        healthBar.Name = "HealthBar"
        healthBar.AnchorPoint = Vector2.new(0.5, 1)
        healthBar.Position = UDim2.new(0.5, 0, 1, 0)
        healthBar.Size = UDim2.new(0.6, 0, 0, 0)
        healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        healthBar.BorderSizePixel = 0
    end

    -- Update function for Health Bar
    local function updateESP()
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then return end

        if _G.HealthESPEnabled then
            local healthFraction = humanoid.Health / humanoid.MaxHealth
            healthBar.Size = UDim2.new(0.6, 0, healthFraction, 0)
            healthBar.BackgroundColor3 = Color3.fromRGB(255 * (1 - healthFraction), 255 * healthFraction, 0)
            healthBarBackground.Visible = true
        else
            healthBarBackground.Visible = false
        end

        nameLabel.Visible = _G.NameESPEnabled
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
                if vis and _G.BoxESPEnabled then
                    local TopLeft = Camera:WorldToViewportPoint((character.PrimaryPart.CFrame * CFrame.new(-2, 3, 0)).Position)
                    local TopRight = Camera:WorldToViewportPoint((character.PrimaryPart.CFrame * CFrame.new(2, 3, 0)).Position)
                    local BottomLeft = Camera:WorldToViewportPoint((character.PrimaryPart.CFrame * CFrame.new(-2, -3, 0)).Position)
                    local BottomRight = Camera:WorldToViewportPoint((character.PrimaryPart.CFrame * CFrame.new(2, -3, 0)).Position)

                    Box.PointA = Vector2.new(TopRight.X, TopRight.Y)
                    Box.PointB = Vector2.new(TopLeft.X, TopLeft.Y)
                    Box.PointC = Vector2.new(BottomLeft.X, BottomLeft.Y)
                    Box.PointD = Vector2.new(BottomRight.X, BottomRight.Y)
                    Box.Visible = true
                    Box.Color = _G.BoxColor
                else
                    Box.Visible = false
                end

                if not _G.BoxESPEnabled then
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
    updateESPFunc()
    DrawESPBox(Player)

    RunService.RenderStepped:Connect(function()
        if _G.ESPEnabled then
            updateESPFunc()
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

-- Set box color
local function setBoxColor(newColor)
    _G.BoxColor = newColor
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player.Character then
            applyESP(Player)
        end
    end
end

-- Set health text color and update active ESPs
local function setHealthTextColor(newColor)
    _G.HealthTextColor = newColor
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player.Character then
            local updateESPFunc = createESPUI(Player.Character, Player.Name)
            updateESPFunc()
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

-- Example color change usage
setHighlightColor(Color3.fromRGB(255, 0, 0)) -- Changes highlight to red
setBoxColor(Color3.fromRGB(0, 255, 0)) -- Changes box to green
setHealthTextColor(Color3.fromRGB(255, 255, 255)) -- Sets health text
