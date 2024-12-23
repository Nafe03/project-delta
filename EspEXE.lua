local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ESP Settings
local Settings = {
    ESPEnabled = true,
    HealthESPEnabled = false,
    NameESPEnabled = false,
    BoxESPEnabled = false,
    DistanceESPEnabled = false,
    HealthTextEnabled = false,
    TeamCheck = false,
    
    Colors = {
        Box = Color3.fromRGB(255, 255, 255),
        Health = Color3.fromRGB(255, 255, 255),
        Name = Color3.fromRGB(255, 255, 255),
        Distance = Color3.fromRGB(255, 255, 255)
    }
}

-- Cache and cleanup handling
local ESPObjects = {}

local function cleanupESP(player)
    if ESPObjects[player] then
        for _, object in pairs(ESPObjects[player]) do
            pcall(function() object:Destroy() end)
        end
        ESPObjects[player] = nil
    end
end

local function createESPElements(player)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    cleanupESP(player)
    
    ESPObjects[player] = {}
    local objects = ESPObjects[player]
    
    -- BillboardGui setup
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 200, 0, 50)
    billboardGui.AlwaysOnTop = true
    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
    billboardGui.Parent = player.Character.HumanoidRootPart
    objects.billboard = billboardGui

    -- Name ESP
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.25, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Settings.Colors.Name
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Parent = billboardGui
    objects.nameLabel = nameLabel

    -- Health ESP
    local healthLabel = Instance.new("TextLabel")
    healthLabel.Size = UDim2.new(1, 0, 0.25, 0)
    healthLabel.Position = UDim2.new(0, 0, 0.25, 0)
    healthLabel.BackgroundTransparency = 1
    healthLabel.TextColor3 = Settings.Colors.Health
    healthLabel.TextStrokeTransparency = 0
    healthLabel.TextSize = 14
    healthLabel.Font = Enum.Font.SourceSansBold
    healthLabel.Parent = billboardGui
    objects.healthLabel = healthLabel

    -- Distance ESP
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Size = UDim2.new(1, 0, 0.25, 0)
    distanceLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextColor3 = Settings.Colors.Distance
    distanceLabel.TextStrokeTransparency = 0
    distanceLabel.TextSize = 14
    distanceLabel.Font = Enum.Font.SourceSansBold
    distanceLabel.Parent = billboardGui
    objects.distanceLabel = distanceLabel

    -- Box ESP
    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Filled = false
    box.Transparency = 1
    box.Color = Settings.Colors.Box
    objects.box = box

    -- Update function
    local function updateESP()
        if not Settings.ESPEnabled or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
            billboardGui.Enabled = false
            box.Visible = false
            return
        end

        if Settings.TeamCheck and player.Team == LocalPlayer.Team then
            billboardGui.Enabled = false
            box.Visible = false
            return
        end

        local humanoid = player.Character:FindFirstChild("Humanoid")
        local rootPart = player.Character.HumanoidRootPart
        
        -- Update name
        nameLabel.Visible = Settings.NameESPEnabled
        nameLabel.Text = player.Name

        -- Update health
        if Settings.HealthESPEnabled and humanoid then
            healthLabel.Visible = true
            healthLabel.Text = string.format("Health: %d/%d", humanoid.Health, humanoid.MaxHealth)
            healthLabel.TextColor3 = Color3.fromRGB(
                255 * (1 - humanoid.Health/humanoid.MaxHealth),
                255 * (humanoid.Health/humanoid.MaxHealth),
                0
            )
        else
            healthLabel.Visible = false
        end

        -- Update distance
        if Settings.DistanceESPEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (LocalPlayer.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
            distanceLabel.Visible = true
            distanceLabel.Text = string.format("%.1f studs", distance)
        else
            distanceLabel.Visible = false
        end

        -- Update box ESP
        if Settings.BoxESPEnabled then
            local vector, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
            if onScreen then
                local size = Vector2.new(4000 / vector.Z, 5000 / vector.Z)
                box.Size = size
                box.Position = Vector2.new(vector.X - size.X / 2, vector.Y - size.Y / 2)
                box.Visible = true
            else
                box.Visible = false
            end
        else
            box.Visible = false
        end

        billboardGui.Enabled = Settings.ESPEnabled
    end

    RunService.RenderStepped:Connect(updateESP)
end

-- Player handling
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(function()
            createESPElements(player)
        end)
    end
end)

Players.PlayerRemoving:Connect(cleanupESP)

-- Initialize existing players
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        createESPElements(player)
    end
end

-- Settings updater
getgenv().updateESPSettings = function(setting, value)
    Settings[setting] = value
end

return Settings
