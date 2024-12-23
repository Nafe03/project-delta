-- Made by Blissful#4992

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Local Player Info
local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ESP Settings
_G.ESPEnabled = true  -- Master toggle for all ESP
_G.HealthESPEnabled = false
_G.NameESPEnabled = false
_G.BoxESPEnabled = false
_G.DistanceESPEnabled = false
_G.HighlightEnabled = false
_G.HealthTextEnabled = false -- Separate toggle for health text
_G.HighlightColor = Color3.fromRGB(0, 255, 0) -- Default highlight color
_G.BoxColor = Color3.fromRGB(255, 255, 255) -- Default box color
_G.HealthTextColor = Color3.fromRGB(255, 255, 255)

-- Function to create or update ESP Highlight
local function updateHighlight(character)
    local highlight = character:FindFirstChild("Highlight") or Instance.new("Highlight")
    highlight.Parent = character
    highlight.FillColor = _G.HighlightColor
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
    highlight.OutlineTransparency = 0
    highlight.Enabled = _G.HighlightEnabled and _G.ESPEnabled
    return highlight
end

-- Function to create or update ESP UI
local function updateESPUI(character, playerName)
    local head = character:FindFirstChild("Head")
    if not head then return end

    local billboardGui = head:FindFirstChild("ESPUI") or Instance.new("BillboardGui")
    billboardGui.Name = "ESPUI"
    billboardGui.Size = UDim2.new(0, 100, 0, 100)
    billboardGui.Adornee = head
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.AlwaysOnTop = true
    billboardGui.Parent = head

    local nameLabel = billboardGui:FindFirstChild("NameLabel") or Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0.3, 0)
    nameLabel.Position = UDim2.new(0, 0, -1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Text = playerName
    nameLabel.Visible = _G.NameESPEnabled and _G.ESPEnabled
    nameLabel.Parent = billboardGui

    local distanceLabel = billboardGui:FindFirstChild("DistanceLabel") or Instance.new("TextLabel")
    distanceLabel.Name = "DistanceLabel"
    distanceLabel.Size = UDim2.new(1, 0, 0.3, 0)
    distanceLabel.Position = UDim2.new(0, 0, 1.3, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    distanceLabel.TextScaled = true
    distanceLabel.Font = Enum.Font.GothamBold
    distanceLabel.TextStrokeTransparency = 0.5
    distanceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    distanceLabel.Visible = _G.DistanceESPEnabled and _G.ESPEnabled
    distanceLabel.Parent = billboardGui

    local healthLabel = billboardGui:FindFirstChild("HealthLabel") or Instance.new("TextLabel")
    healthLabel.Name = "HealthLabel"
    healthLabel.Size = UDim2.new(1, 0, 0.3, 0)
    healthLabel.Position = UDim2.new(0, 0, 0, 0)
    healthLabel.BackgroundTransparency = 1
    healthLabel.TextColor3 = _G.HealthTextColor
    healthLabel.TextScaled = true
    healthLabel.Font = Enum.Font.GothamBold
    healthLabel.TextStrokeTransparency = 0.5
    healthLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    healthLabel.Visible = _G.HealthTextEnabled and _G.ESPEnabled
    healthLabel.Parent = billboardGui

    local healthBarBackground = billboardGui:FindFirstChild("HealthBarBackground") or Instance.new("Frame")
    healthBarBackground.Name = "HealthBarBackground"
    healthBarBackground.Size = UDim2.new(1, 0, 0.1, 0)
    healthBarBackground.Position = UDim2.new(0, 0, 0.3, 0)
    healthBarBackground.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    healthBarBackground.BorderSizePixel = 0
    healthBarBackground.Visible = _G.HealthESPEnabled and _G.ESPEnabled
    healthBarBackground.Parent = billboardGui

    local healthBar = healthBarBackground:FindFirstChild("HealthBar") or Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthBar.BorderSizePixel = 0
    healthBar.Parent = healthBarBackground

    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        local playerDistance = (Player.Character.PrimaryPart.Position - character.PrimaryPart.Position).Magnitude
        distanceLabel.Text = string.format("%.1f studs", playerDistance)

        if _G.HealthESPEnabled then
            local healthFraction = humanoid.Health / humanoid.MaxHealth
            healthBar.Size = UDim2.new(healthFraction, 0, 1, 0)
            healthBar.BackgroundColor3 = Color3.fromRGB(255 * (1 - healthFraction), 255 * healthFraction, 0)
        end

        if _G.HealthTextEnabled then
            healthLabel.Text = string.format("HP: %d/%d", math.floor(humanoid.Health), humanoid.MaxHealth)
        end
    end
end

-- Function to draw or update Box ESP
local function updateBoxESP(player)
    local box = player:FindFirstChild("ESPBox") or Drawing.new("Quad")
    box.Visible = false
    box.Color = _G.BoxColor
    box.Thickness = 1
    box.Transparency = 1

    RunService.RenderStepped:Connect(function()
        if _G.BoxESPEnabled and _G.ESPEnabled and player.Character and player.Character.PrimaryPart then
            local character = player.Character
            local pos, vis = Camera:WorldToViewportPoint(character.PrimaryPart.Position)
            if vis then
                local topLeft = Camera:WorldToViewportPoint((character.PrimaryPart.CFrame * CFrame.new(-2, 3, 0)).Position)
                local topRight = Camera:WorldToViewportPoint((character.PrimaryPart.CFrame * CFrame.new(2, 3, 0)).Position)
                local bottomLeft = Camera:WorldToViewportPoint((character.PrimaryPart.CFrame * CFrame.new(-2, -3, 0)).Position)
                local bottomRight = Camera:WorldToViewportPoint((character.PrimaryPart.CFrame * CFrame.new(2, -3, 0)).Position)

                box.PointA = Vector2.new(topRight.X, topRight.Y)
                box.PointB = Vector2.new(topLeft.X, topLeft.Y)
                box.PointC = Vector2.new(bottomLeft.X, bottomLeft.Y)
                box.PointD = Vector2.new(bottomRight.X, bottomRight.Y)
                box.Visible = true
            else
                box.Visible = false
            end
        else
            box.Visible = false
        end
    end)
end

-- Apply ESP to a player
local function applyESP(player)
    local character = player.Character or player.CharacterAdded:Wait()
    if _G.ESPEnabled then
        updateHighlight(character)
        updateESPUI(character, player.Name)
        updateBoxESP(player)
    end
end

-- Initialize ESP for all players
local function initializeESP()
    for _, player in ipairs(Players:GetPlayers()) do
        applyESP(player)
        player.CharacterAdded:Connect(function()
            applyESP(player)
        end)
    end
    Players.PlayerAdded:Connect(function(newPlayer)
        newPlayer.CharacterAdded:Connect(function()
            applyESP(newPlayer)
        end)
    end)
end

initializeESP()
