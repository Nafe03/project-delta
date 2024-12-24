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

-- Function to create ESP UI
local function createBillboardESP(character, playerName)
    -- Find or create the BillboardGui
    local billboardGui = character:FindFirstChild("ESPUI")
    if not billboardGui then
        billboardGui = Instance.new("BillboardGui")
        billboardGui.Name = "ESPUI"
        billboardGui.Adornee = character:WaitForChild("Head")
        billboardGui.Size = UDim2.new(0, 200, 0, 50)
        billboardGui.StudsOffset = Vector3.new(0, 3, 0)
        billboardGui.AlwaysOnTop = true
        billboardGui.Parent = character
    end

    -- Name Label
    local nameLabel = billboardGui:FindFirstChild("NameLabel")
    if not nameLabel then
        nameLabel = Instance.new("TextLabel", billboardGui)
        nameLabel.Name = "NameLabel"
        nameLabel.Size = UDim2.new(1, 0, 0.3, 0)
        nameLabel.Position = UDim2.new(0, 0, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = _G.BoxColor
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
        distanceLabel.Position = UDim2.new(0, 0, 0.3, 0)
        distanceLabel.BackgroundTransparency = 1
        distanceLabel.TextColor3 = _G.BoxColor
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
        healthLabel.Position = UDim2.new(0, 0, 0.6, 0)
        healthLabel.BackgroundTransparency = 1
        healthLabel.TextColor3 = _G.HealthTextColor
        healthLabel.TextScaled = true
        healthLabel.Font = Enum.Font.GothamBold
        healthLabel.TextStrokeTransparency = 0.5
        healthLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    end
    healthLabel.Visible = _G.HealthTextEnabled

    return function()
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            if _G.DistanceESPEnabled then
                local playerDistance = (Player.Character.PrimaryPart.Position - character.PrimaryPart.Position).Magnitude
                distanceLabel.Text = string.format("%.1f studs", playerDistance)
                distanceLabel.Visible = true
            else
                distanceLabel.Visible = false
            end

            if _G.HealthTextEnabled then
                healthLabel.Text = string.format("HP: %d/%d", math.floor(humanoid.Health), humanoid.MaxHealth)
                healthLabel.Visible = true
            else
                healthLabel.Visible = false
            end

            nameLabel.Visible = _G.NameESPEnabled
        end
    end
end

-- Function to remove ESP UI
local function removeESP(character)
    local billboardGui = character:FindFirstChild("ESPUI")
    if billboardGui then
        billboardGui:Destroy()
    end
end

-- Apply ESP to each player
local function applyESP(player)
    local character = player.Character or player.CharacterAdded:Wait()

    -- Remove any existing ESP to prevent duplicates
    removeESP(character)

    -- Create ESP UI
    local updateESP = createBillboardESP(character, player.Name)

    -- Update ESP every frame
    RunService.RenderStepped:Connect(function()
        if _G.ESPEnabled then
            updateESP()
        else
            removeESP(character)
        end
    end)
end

-- Initialize ESP for all players
local function initializeESP(player)
    player.CharacterAdded:Connect(function()
        applyESP(player)
    end)
    if player.Character then
        applyESP(player)
    end
end

-- Apply ESP to all existing players
for _, player in ipairs(Players:GetPlayers()) do
    initializeESP(player)
end
Players.PlayerAdded:Connect(initializeESP)

-- Toggle ESP features dynamically
local function toggleESPFeature(feature, state)
    _G[feature] = state
end

-- Example color and feature toggle functions
toggleESPFeature("BoxESPEnabled", true) -- Enable Box ESP
