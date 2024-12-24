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
_G.HealthTextColor = Color3.fromRGB(255, 255, 255) -- Health text color

-- Update functions for real-time color changes
local function updateHighlightColor(character)
    local highlight = character:FindFirstChild("Highlight")
    if highlight then
        highlight.FillColor = _G.HighlightColor
    end
end

local function updateHealthTextColor(billboardGui)
    if billboardGui then
        local healthLabel = billboardGui:FindFirstChild("HealthLabel")
        if healthLabel then
            healthLabel.TextColor3 = _G.HealthTextColor
        end
    end
end

-- Function to create ESP highlight
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

-- Function to create and update ESP UI
local function createOrUpdateESPUI(character, playerName)
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

    -- Distance Label
    local distanceLabel = billboardGui:FindFirstChild("DistanceLabel")
    if not distanceLabel then
        distanceLabel = Instance.new("TextLabel", billboardGui)
        distanceLabel.Name = "DistanceLabel"
        distanceLabel.Size = UDim2.new(1, 0, 0.3, 0)
        distanceLabel.Position = UDim2.new(0, 0, 1.3, 0)
        distanceLabel.BackgroundTransparency = 1
        distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        distanceLabel.TextScaled = true
        distanceLabel.Font = Enum.Font.GothamBold
        distanceLabel.TextStrokeTransparency = 0.5
        distanceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    end
    distanceLabel.Visible = _G.DistanceESPEnabled

    -- Health Label
    local healthLabel = billboardGui:FindFirstChild("HealthLabel")
    if not healthLabel then
        healthLabel = Instance.new("TextLabel", billboardGui)
        healthLabel.Name = "HealthLabel"
        healthLabel.Size = UDim2.new(1, 0, 0.3, 0)
        healthLabel.Position = UDim2.new(0, 0, 0, 0)
        healthLabel.BackgroundTransparency = 1
        healthLabel.TextColor3 = _G.HealthTextColor
        healthLabel.TextScaled = true
        healthLabel.Font = Enum.Font.GothamBold
        healthLabel.TextStrokeTransparency = 0.5
        healthLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    end
    healthLabel.Visible = _G.HealthTextEnabled

    -- Update function for ESP
    local function updateESP()
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then return end

        local playerDistance = (Player.Character.PrimaryPart.Position - character.PrimaryPart.Position).Magnitude
        if _G.DistanceESPEnabled then
            distanceLabel.Text = string.format("%.1f studs", playerDistance)
            distanceLabel.Visible = true
        else
            distanceLabel.Visible = false
        end

        if _G.HealthTextEnabled then
            healthLabel.Text = string.format("HP: %d/%d", math.floor(humanoid.Health), humanoid.MaxHealth)
            healthLabel.TextColor3 = _G.HealthTextColor -- Real-time update
            healthLabel.Visible = true
        else
            healthLabel.Visible = false
        end

        nameLabel.Visible = _G.NameESPEnabled
    end

    return updateESP
end

-- Function to draw 2D Box ESP
local function drawESPBox(character)
    local box = Drawing.new("Quad")
    box.Visible = false
    box.Color = _G.BoxColor
    box.Thickness = 2
    box.Transparency = 1

    local function updateBox()
        if not _G.BoxESPEnabled then
            box.Visible = false
            return
        end

        local primaryPart = character.PrimaryPart
        if primaryPart then
            local corners = {
                Camera:WorldToViewportPoint((primaryPart.CFrame * CFrame.new(-2, 3, 0)).Position),
                Camera:WorldToViewportPoint((primaryPart.CFrame * CFrame.new(2, 3, 0)).Position),
                Camera:WorldToViewportPoint((primaryPart.CFrame * CFrame.new(2, -3, 0)).Position),
                Camera:WorldToViewportPoint((primaryPart.CFrame * CFrame.new(-2, -3, 0)).Position),
            }
            box.PointA, box.PointB, box.PointC, box.PointD = corners[1], corners[2], corners[3], corners[4]
            box.Color = _G.BoxColor -- Real-time update
            box.Visible = true
        else
            box.Visible = false
        end
    end

    RunService.RenderStepped:Connect(updateBox)
end

-- Apply ESP to a player
local function applyESP(player)
    local function onCharacterAdded(character)
        if _G.HighlightEnabled then
            createHighlight(character)
        end

        local updateESPFunc = createOrUpdateESPUI(character, player.Name)
        drawESPBox(character)
        RunService.RenderStepped:Connect(function()
            if _G.ESPEnabled then
                updateESPFunc()
            end
        end)
    end

    player.CharacterAdded:Connect(onCharacterAdded)
    if player.Character then
        onCharacterAdded(player.Character)
    end
end

-- Initialize ESP for all players
for _, player in ipairs(Players:GetPlayers()) do
    applyESP(player)
end
Players.PlayerAdded:Connect(applyESP)
