local Players = game:GetService("Players")
local DefaultColor = Color3.fromRGB(0, 0, 0)
local HealthESPEnabled = true  -- Toggle for Health ESP
local NameESPEnabled = true    -- Toggle for Name ESP

-- Function to apply highlight to the player
local function ApplyHighlight(Player)
    local Connections = {}
    local Character = Player.Character or Player.CharacterAdded:Wait()
    local Humanoid = Character:WaitForChild("Humanoid")
    local Highlighter = Instance.new("Highlight", Character)
    local BillboardGui, NameLabel

    -- Update fill color based on team color
    local function UpdateFillColor()
        Highlighter.FillColor = (Player.TeamColor and Player.TeamColor.Color) or DefaultColor
    end

    -- Health ESP: Change highlight transparency based on health
    local function UpdateHealthTransparency()
        if HealthESPEnabled and Humanoid.Health > 0 then
            -- The lower the health, the less transparent the fill becomes
            Highlighter.FillTransparency = 1 - (Humanoid.Health / Humanoid.MaxHealth)
        else
            Highlighter.FillTransparency = 1  -- Fully transparent if disabled
        end
    end

    -- Name ESP: Display player name above their head
    local function CreateNameESP()
        if NameESPEnabled and not BillboardGui then
            BillboardGui = Instance.new("BillboardGui", Character)
            BillboardGui.Size = UDim2.new(0, 100, 0, 50)
            BillboardGui.Adornee = Character:WaitForChild("Head")
            BillboardGui.StudsOffset = Vector3.new(0, 2, 0)
            BillboardGui.AlwaysOnTop = true

            NameLabel = Instance.new("TextLabel", BillboardGui)
            NameLabel.Size = UDim2.new(1, 0, 1, 0)
            NameLabel.Text = Player.Name
            NameLabel.BackgroundTransparency = 1
            NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            NameLabel.TextScaled = true
        end
    end

    -- Disconnect function when player dies
    local function Disconnect()
        Highlighter:Destroy()
        if BillboardGui then
            BillboardGui:Destroy()
        end
        for _, Connection in next, Connections do
            Connection:Disconnect()
        end
    end

    -- Connect events to handle dynamic updates
    table.insert(Connections, Player:GetPropertyChangedSignal("TeamColor"):Connect(UpdateFillColor))
    table.insert(Connections, Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        if Humanoid.Health <= 0 then
            Disconnect()
        else
            UpdateHealthTransparency()
        end
    end))

    -- Initial updates
    UpdateFillColor()
    UpdateHealthTransparency()
    CreateNameESP()
end

-- Function to apply highlights when player spawns or joins
local function HighlightPlayer(Player)
    if Player.Character then
        ApplyHighlight(Player)
    end
    Player.CharacterAdded:Connect(function()
        ApplyHighlight(Player)
    end)
end

-- Apply highlights to all existing players and new ones
for _, Player in next, Players:GetPlayers() do
    HighlightPlayer(Player)
end
Players.PlayerAdded:Connect(HighlightPlayer)
