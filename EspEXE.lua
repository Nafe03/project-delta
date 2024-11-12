-- Optimized Ultimate ESP Script

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

-- Cache for ESP elements to allow cleanup
local ESPObjects = {}

-- Helper function to create ESP elements
local function createESP(player)
    -- Ensure ESP elements are only created if toggled on
    local espElements = {}

    -- Function to create Box ESP
    local function createBox()
        local Box = Drawing.new("Quad")
        Box.Visible = false
        Box.Color = _G.Colors.Box
        Box.Thickness = 2
        Box.Transparency = 1
        Box.ZIndex = 1
        espElements.Box = Box

        -- Update Box ESP position and visibility
        local function updateBox()
            if player.Character and player.Character.PrimaryPart then
                local character = player.Character
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
        end

        -- Update the Box continuously
        RunService.RenderStepped:Connect(updateBox)
    end

    -- Function to create Health ESP
    local function createHealthBar()
        local HealthBar = Drawing.new("Line")
        HealthBar.Visible = false
        HealthBar.Thickness = 2
        HealthBar.ZIndex = 2
        espElements.Health = HealthBar

        -- Update Health ESP
        local function updateHealthBar()
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
        end

        -- Update the Health continuously
        RunService.RenderStepped:Connect(updateHealthBar)
    end

    -- Function to create Distance ESP
    local function createDistance()
        local DistanceLabel = Drawing.new("Text")
        DistanceLabel.Visible = false
        DistanceLabel.Size = 20
        DistanceLabel.Color = _G.Colors.Distance
        DistanceLabel.Center = true
        DistanceLabel.Outline = true
        DistanceLabel.ZIndex = 3
        espElements.Distance = DistanceLabel

        -- Update Distance ESP
        local function updateDistance()
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
        end

        -- Update the Distance continuously
        RunService.RenderStepped:Connect(updateDistance)
    end

    -- Function to create Name ESP
    local function createName()
        local NameLabel = Drawing.new("Text")
        NameLabel.Visible = false
        NameLabel.Size = 20
        NameLabel.Color = _G.Colors.Name
        NameLabel.Center = true
        NameLabel.Outline = true
        NameLabel.ZIndex = 4
        espElements.Name = NameLabel

        -- Update Name ESP
        local function updateName()
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
        end

        -- Update the Name continuously
        RunService.RenderStepped:Connect(updateName)
    end

    -- Function to create Skeleton ESP
    local function createSkeleton()
        local Skeleton = {}
        for _, partName in ipairs({"Head", "LeftArm", "RightArm", "LeftLeg", "RightLeg", "Torso"}) do
            local line = Drawing.new("Line")
            line.Visible = false
            line.Color = _G.Colors.Skeleton
            line.Thickness = 2
            line.ZIndex = 5
            Skeleton[partName] = line
        end

        -- Update Skeleton ESP
        local function updateSkeleton()
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
        end

        -- Update the Skeleton continuously
        RunService.RenderStepped:Connect(updateSkeleton)
    end

    -- Create necessary ESP elements
    if _G.BoxESPEnabled then createBox() end
    if _G.HealthESPEnabled then createHealthBar() end
    if _G.DistanceESPEnabled then createDistance() end
    if _G.NameESPEnabled then createName() end
    if _G.SkeletonESPEnabled then createSkeleton() end

    -- Store the ESP elements in a table
    ESPObjects[player.UserId] = espElements
end

-- Function to clean up ESP elements
local function cleanUpESP(player)
    if ESPObjects[player.UserId] then
        for _, element in pairs(ESPObjects[player.UserId]) do
            element.Visible = false
            element:Remove()  -- Remove the drawing object to prevent memory leaks
        end
        ESPObjects[player.UserId] = nil
    end
end

-- Initialize ESP for existing players
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        createESP(player)
    end
end

-- Monitor when players join or leave
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        createESP(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if player ~= LocalPlayer then
        cleanUpESP(player)
    end
end)

-- Toggle ESP when settings are updated
local function toggleESPFeature(settingName, newState)
    _G[settingName] = newState
    -- Update the ESP of all players when toggled
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if newState then
                createESP(player)
            else
                cleanUpESP(player)
            end
        end
    end
end
