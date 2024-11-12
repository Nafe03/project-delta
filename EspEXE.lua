-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = game:GetService("Workspace").CurrentCamera

-- ESP Settings
_G.HealthESPEnabled = false
_G.NameESPEnabled = false
_G.BoxESPEnabled = false
_G.DistanceESPEnabled = false
_G.HighlightColor = Color3.fromRGB(0, 255, 0)  -- Default highlight color

-- Function to create highlight for a character
local function createHighlight(character, color)
    local highlight = character:FindFirstChild("Highlight") or Instance.new("Highlight")
    highlight.Parent = character
    highlight.FillColor = color or _G.HighlightColor
    highlight.FillTransparency = 0.5
    return highlight
end

-- Function to create Billboard GUI for Distance and Name ESP
local function createBillboardGui(character, playerName)
    local billboardGui = character:FindFirstChild("ESP") or Instance.new("BillboardGui")
    billboardGui.Name = "ESP"
    billboardGui.Size = UDim2.new(0, 150, 0, 100)
    billboardGui.Adornee = character:WaitForChild("Head")
    billboardGui.StudsOffset = Vector3.new(0, 2.5, 0)
    billboardGui.AlwaysOnTop = true
    billboardGui.Parent = character

    local nameLabel = billboardGui:FindFirstChild("NameLabel") or Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0.3, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Parent = billboardGui

    local distanceLabel = billboardGui:FindFirstChild("DistanceLabel") or Instance.new("TextLabel")
    distanceLabel.Name = "DistanceLabel"
    distanceLabel.Size = UDim2.new(1, 0, 0.3, 0)
    distanceLabel.Position = UDim2.new(0, 0, 0.3, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    distanceLabel.TextScaled = true
    distanceLabel.Font = Enum.Font.GothamBold
    distanceLabel.TextStrokeTransparency = 0.5
    distanceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    distanceLabel.Parent = billboardGui

    return nameLabel, distanceLabel
end

-- Box ESP Function
local function createBoxESP(player)
    local box = Drawing.new("Quad")
    box.Visible = false
    box.Color = Color3.fromRGB(255, 255, 255)
    box.Thickness = 1
    box.Transparency = 1

    local function updateBox()
        if player.Character and player.Character.PrimaryPart and player.Character:FindFirstChildOfClass("Humanoid") then
            local pos, vis = Camera:WorldToViewportPoint(player.Character.PrimaryPart.Position)
            if vis and _G.BoxESPEnabled then
                local points = {}
                for _, part in pairs(player.Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        local p, vis = Camera:WorldToViewportPoint(part.Position)
                        if vis then
                            table.insert(points, p)
                        end
                    end
                end

                if #points > 0 then
                    local left, right, top, bottom = points[1], points[1], points[1], points[1]
                    for _, p in pairs(points) do
                        if p.X < left.X then left = p end
                        if p.X > right.X then right = p end
                        if p.Y < top.Y then top = p end
                        if p.Y > bottom.Y then bottom = p end
                    end

                    box.PointA = Vector2.new(right.X, top.Y)
                    box.PointB = Vector2.new(left.X, top.Y)
                    box.PointC = Vector2.new(left.X, bottom.Y)
                    box.PointD = Vector2.new(right.X, bottom.Y)
                    box.Visible = true
                else
                    box.Visible = false
                end
            else
                box.Visible = false
            end
        else
            box.Visible = false
        end
    end

    local conn
    conn = RunService.RenderStepped:Connect(updateBox)

    -- Cleanup function to disconnect the event when the player leaves
    player.AncestryChanged:Connect(function()
        if not player:IsDescendantOf(Players) then
            box:Remove()
            if conn then
                conn:Disconnect()
            end
        end
    end)
end

-- Function to update ESP elements for a player
local function updateESP(player)
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    local nameLabel, distanceLabel = createBillboardGui(character, player.Name)
    local highlight = createHighlight(character, _G.HighlightColor)
    createBoxESP(player)

    local function updateElements()
        local playerDistance = (Players.LocalPlayer.Character.PrimaryPart.Position - character.PrimaryPart.Position).Magnitude
        nameLabel.Text = _G.NameESPEnabled and player.Name or ""
        distanceLabel.Text = _G.DistanceESPEnabled and string.format("%.1f studs", playerDistance) or ""

        if _G.HealthESPEnabled then
            local healthFraction = humanoid.Health / humanoid.MaxHealth
        else
            highlight.FillTransparency = 1
        end
    end

    RunService.RenderStepped:Connect(updateElements)
end

-- Apply ESP to all players and handle new ones
for _, player in ipairs(Players:GetPlayers()) do
    player.CharacterAdded:Connect(function() updateESP(player) end)
    if player.Character then updateESP(player) end
end
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function() updateESP(player) end)
end)

-- Toggle functions to enable/disable ESP features
local function setESPFeature(setting, enabled)
    _G[setting] = enabled
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then updateESP(player) end
    end
end

-- Change highlight color dynamically
local function setHighlightColor(newColor)
    _G.HighlightColor = newColor
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("Highlight") then
            player.Character.Highlight.FillColor = newColor
        end
    end
end

-- UI Toggle functions (example calls for testing)
local function onHealthESPToggle(state) setESPFeature("HealthESPEnabled", state) end
local function onNameESPToggle(state) setESPFeature("NameESPEnabled", state) end
local function onBoxESPToggle(state) setESPFeature("BoxESPEnabled", state) end
local function onDistanceESPToggle(state) setESPFeature("DistanceESPEnabled", state) end

-- Example color change
setHighlightColor(Color3.fromRGB(255, 0, 0)) -- Change highlight color to red
