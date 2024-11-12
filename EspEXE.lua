-- Made by Blissful#4992, Optimized Ultimate ESP Script

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Local Player Info
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ESP Settings
_G.BoxESPEnabled = false
_G.HealthESPEnabled = false
_G.NameESPEnabled = false
_G.DistanceESPEnabled = false
_G.SkeletonESPEnabled = false

_G.Colors = {
    Box = Color3.fromRGB(255, 255, 255),
    Health = Color3.fromRGB(0, 255, 0),
    Name = Color3.fromRGB(255, 255, 255),
    Distance = Color3.fromRGB(0, 255, 255),
    Skeleton = Color3.fromRGB(255, 0, 0)
}

-- Function to create 2D Box ESP
local function createBoxESP(player)
    local Box = Drawing.new("Quad")
    Box.Visible = false
    Box.Color = _G.Colors.Box
    Box.Thickness = 2
    Box.Transparency = 1

    local function updateBox()
        RunService.RenderStepped:Connect(function()
            if player.Character and player.Character.PrimaryPart then
                local character = player.Character
                local head = character:FindFirstChild("Head")
                local pos, onScreen = Camera:WorldToViewportPoint(character.PrimaryPart.Position)
                if onScreen then
                    local size = Vector3.new(2, 3, 0)
                    local TopLeft = Camera:WorldToViewportPoint((character.PrimaryPart.CFrame * CFrame.new(-size.X, size.Y, 0)).Position)
                    local TopRight = Camera:WorldToViewportPoint((character.PrimaryPart.CFrame * CFrame.new(size.X, size.Y, 0)).Position)
                    local BottomLeft = Camera:WorldToViewportPoint((character.PrimaryPart.CFrame * CFrame.new(-size.X, -size.Y, 0)).Position)
                    local BottomRight = Camera:WorldToViewportPoint((character.PrimaryPart.CFrame * CFrame.new(size.X, -size.Y, 0)).Position)

                    Box.PointA = Vector2.new(TopRight.X, TopRight.Y)
                    Box.PointB = Vector2.new(TopLeft.X, TopLeft.Y)
                    Box.PointC = Vector2.new(BottomLeft.X, BottomLeft.Y)
                    Box.PointD = Vector2.new(BottomRight.X, BottomRight.Y)
                    Box.Visible = _G.BoxESPEnabled
                else
                    Box.Visible = false
                end
            else
                Box.Visible = false
            end
        end)
    end

    updateBox()
end

-- Function to create Health Bar ESP
local function createHealthBarESP(player)
    local HealthBar = Drawing.new("Line")
    HealthBar.Visible = false
    HealthBar.Thickness = 2

    local function updateHealthBar()
        RunService.RenderStepped:Connect(function()
            if player.Character and player.Character.PrimaryPart then
                local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                local head = player.Character:FindFirstChild("Head")
                if humanoid and head then
                    local healthFraction = humanoid.Health / humanoid.MaxHealth
                    local color = Color3.fromRGB(255 * (1 - healthFraction), 255 * healthFraction, 0)

                    local topPos = Camera:WorldToViewportPoint((head.CFrame * CFrame.new(0, 0.5, 0)).Position)
                    local bottomPos = Camera:WorldToViewportPoint((head.CFrame * CFrame.new(0, -0.5, 0)).Position)

                    HealthBar.From = Vector2.new(topPos.X, topPos.Y)
                    HealthBar.To = Vector2.new(bottomPos.X, bottomPos.Y)
                    HealthBar.Color = color
                    HealthBar.Visible = _G.HealthESPEnabled
                else
                    HealthBar.Visible = false
                end
            else
                HealthBar.Visible = false
            end
        end)
    end

    updateHealthBar()
end

-- Function to create Distance ESP
local function createDistanceESP(player)
    local DistanceLabel = Drawing.new("Text")
    DistanceLabel.Visible = false
    DistanceLabel.Size = 20
    DistanceLabel.Color = _G.Colors.Distance
    DistanceLabel.Center = true
    DistanceLabel.Outline = true

    local function updateDistance()
        RunService.RenderStepped:Connect(function()
            if player.Character and player.Character.PrimaryPart then
                local playerDistance = (LocalPlayer.Character.PrimaryPart.Position - player.Character.PrimaryPart.Position).Magnitude
                local pos, onScreen = Camera:WorldToViewportPoint(player.Character.PrimaryPart.Position)
                if onScreen then
                    DistanceLabel.Position = Vector2.new(pos.X, pos.Y + 20)
                    DistanceLabel.Text = string.format("%.1f studs", playerDistance)
                    DistanceLabel.Visible = _G.DistanceESPEnabled
                else
                    DistanceLabel.Visible = false
                end
            else
                DistanceLabel.Visible = false
            end
        end)
    end

    updateDistance()
end

-- Function to create Name ESP
local function createNameESP(player)
    local NameLabel = Drawing.new("Text")
    NameLabel.Visible = false
    NameLabel.Size = 20
    NameLabel.Color = _G.Colors.Name
    NameLabel.Center = true
    NameLabel.Outline = true

    local function updateName()
        RunService.RenderStepped:Connect(function()
            if player.Character and player.Character.PrimaryPart then
                local pos, onScreen = Camera:WorldToViewportPoint(player.Character.PrimaryPart.Position)
                if onScreen then
                    NameLabel.Position = Vector2.new(pos.X, pos.Y - 30)
                    NameLabel.Text = player.Name
                    NameLabel.Visible = _G.NameESPEnabled
                else
                    NameLabel.Visible = false
                end
            else
                NameLabel.Visible = false
            end
        end)
    end

    updateName()
end

-- Function to create Skeleton ESP
local function createSkeletonESP(player)
    local Skeleton = {}
    for _, partName in ipairs({"Head", "LeftArm", "RightArm", "LeftLeg", "RightLeg", "Torso"}) do
        local line = Drawing.new("Line")
        line.Visible = false
        line.Color = _G.Colors.Skeleton
        line.Thickness = 2
        Skeleton[partName] = line
    end

    local function updateSkeleton()
        RunService.RenderStepped:Connect(function()
            if player.Character and player.Character:FindFirstChild("Head") then
                local parts = player.Character
                local headPos = Camera:WorldToViewportPoint(parts.Head.Position)
                if parts:FindFirstChild("LeftArm") and parts:FindFirstChild("RightArm") then
                    local leftArmPos = Camera:WorldToViewportPoint(parts.LeftArm.Position)
                    local rightArmPos = Camera:WorldToViewportPoint(parts.RightArm.Position)
                    local torsoPos = Camera:WorldToViewportPoint(parts.Torso.Position)

                    Skeleton["LeftArm"].From = Vector2.new(torsoPos.X, torsoPos.Y)
                    Skeleton["LeftArm"].To = Vector2.new(leftArmPos.X, leftArmPos.Y)
                    Skeleton["RightArm"].From = Vector2.new(torsoPos.X, torsoPos.Y)
                    Skeleton["RightArm"].To = Vector2.new(rightArmPos.X, rightArmPos.Y)
                    
                    Skeleton["Head"].From = Vector2.new(torsoPos.X, torsoPos.Y)
                    Skeleton["Head"].To = Vector2.new(headPos.X, headPos.Y)

                    for _, line in pairs(Skeleton) do
                        line.Visible = _G.SkeletonESPEnabled
                    end
                else
                    for _, line in pairs(Skeleton) do
                        line.Visible = false
                    end
                end
            else
                for _, line in pairs(Skeleton) do
                    line.Visible = false
                end
            end
        end)
    end

    updateSkeleton()
end

local function applyESP(Player)
    local Character = Player.Character or Player.CharacterAdded:Wait()
    local Humanoid = Character:WaitForChild("Humanoid")

    local highlight = createHighlight(Character)
    local updateESPFunc = createESPUI(Character, Player.Name)

    -- Set up highlight and update functions
    local function updateHighlight()
        highlight.FillColor = _G.HighlightColor
        highlight.Enabled = _G.HealthESPEnabled or _G.DistanceESPEnabled or _G.BoxESPEnabled
    end

    updateESPFunc()
    updateHighlight()
    DrawESPBox(Player)

    RunService.RenderStepped:Connect(function()
        updateESPFunc()
        updateHighlight()
    end)
end

-- Initialize ESP for each player
local function initializeESP(player)
    player.CharacterAdded:Connect(function()
        createBoxESP(player)
        createHealthBarESP(player)
        createDistanceESP(player)
        createNameESP(player)
        createSkeletonESP(player)
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        initializeESP(player)
    end
end
Players.PlayerAdded:Connect(initializeESP)

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
