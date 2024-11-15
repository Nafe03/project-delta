-- Super Cool Enhanced ESP Script by Blissful#4992

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

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
_G.GlowEnabled = false  -- New feature for glowing effect
_G.HighlightColor = Color3.fromRGB(0, 255, 0)
_G.BoxColor = Color3.fromRGB(255, 255, 255)
_G.HealthTextColor = Color3.fromRGB(255, 255, 255)
_G.GlowColor = Color3.fromRGB(255, 0, 0)
_G.TransitionSpeed = 0.15  -- Smoothing speed

-- Function to create Highlight with Glow Effect
local function createHighlight(character)
    local highlight = character:FindFirstChild("Highlight") or Instance.new("Highlight")
    highlight.Parent = character
    highlight.FillColor = _G.HighlightColor
    highlight.FillTransparency = 0.25
    highlight.OutlineColor = _G.GlowEnabled and _G.GlowColor or Color3.fromRGB(0, 0, 0)
    highlight.OutlineTransparency = 0
    highlight.Enabled = _G.HighlightEnabled
    return highlight
end

-- Function to create dynamic ESP UI with Labels and Health Bar
local function createESPUI(character, playerName)
    local billboardGui = Instance.new("BillboardGui", character)
    billboardGui.Size = UDim2.new(0, 150, 0, 150)
    billboardGui.Adornee = character:WaitForChild("Head")
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.AlwaysOnTop = true

    -- Name Label (above player)
    local nameLabel = Instance.new("TextLabel", billboardGui)
    nameLabel.Size = UDim2.new(1, 0, 0.3, 0)
    nameLabel.Position = UDim2.new(0, 0, -1.2, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Text = playerName
    nameLabel.Visible = _G.NameESPEnabled

    -- Distance Label (below player)
    local distanceLabel = Instance.new("TextLabel", billboardGui)
    distanceLabel.Size = UDim2.new(1, 0, 0.3, 0)
    distanceLabel.Position = UDim2.new(0, 0, 1.4, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    distanceLabel.TextScaled = true
    distanceLabel.Font = Enum.Font.GothamBold
    distanceLabel.TextStrokeTransparency = 0.3
    distanceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    distanceLabel.Visible = _G.DistanceESPEnabled

    -- Health Text Label (under player)
    local healthLabel = Instance.new("TextLabel", billboardGui)
    healthLabel.Size = UDim2.new(1, 0, 0.3, 0)
    healthLabel.Position = UDim2.new(0, 0, 1.7, 0)
    healthLabel.BackgroundTransparency = 1
    healthLabel.TextColor3 = _G.HealthTextColor
    healthLabel.TextScaled = true
    healthLabel.Font = Enum.Font.GothamBold
    healthLabel.TextStrokeTransparency = 0.3
    healthLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    healthLabel.Visible = _G.HealthTextEnabled

    -- Health Bar (next to player)
    local healthBarBackground = Instance.new("Frame", billboardGui)
    healthBarBackground.Size = UDim2.new(0.1, 0, 1, 0)
    healthBarBackground.Position = UDim2.new(1.2, 0, 0, 0)
    healthBarBackground.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    healthBarBackground.BorderSizePixel = 0
    healthBarBackground.Visible = _G.HealthESPEnabled

    local healthBar = Instance.new("Frame", healthBarBackground)
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthBar.BorderSizePixel = 0

    -- Update function for Distance, Name, and Health
    local function updateESP()
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then return end

        -- Smooth transition for health bar
        local healthFraction = humanoid.Health / humanoid.MaxHealth
        healthBar:TweenSize(UDim2.new(1, 0, healthFraction, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Sine, _G.TransitionSpeed, true)

        healthBar.BackgroundColor3 = Color3.fromRGB(255 * (1 - healthFraction), 255 * healthFraction, 0)

        if _G.HealthESPEnabled then
            healthLabel.Text = string.format("HP: %d/%d", math.floor(humanoid.Health), humanoid.MaxHealth)
            healthLabel.Visible = true
            healthLabel.TextColor3 = _G.HealthTextColor
        else
            healthLabel.Visible = false
        end

        local playerDistance = (Player.Character.PrimaryPart.Position - character.PrimaryPart.Position).Magnitude
        distanceLabel.Visible = _G.DistanceESPEnabled
        distanceLabel.Text = string.format("%.1f studs", playerDistance)

        nameLabel.Visible = _G.NameESPEnabled
    end

    return updateESP
end

-- Draw stylish 2D Box ESP around a player
local function DrawESPBox(player)
    local Box = Drawing.new("Quad")
    Box.Visible = false
    Box.Color = _G.BoxColor
    Box.Thickness = 2
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
