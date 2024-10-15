local Players = game:GetService("Players")
local DefaultColor = Color3.fromRGB(0, 0, 0)

local function ApplyHighlight(Player)
    local Connections = {}

    --// Parts
    local Character = Player.Character or Player.CharacterAdded:Wait()
    local Humanoid = Character:WaitForChild("Humanoid")
    local Highlighter = Instance.new("Highlight", Character)

    local function UpdateFillColor()
        Highlighter.FillColor = (Player.TeamColor and Player.TeamColor.Color) or DefaultColor
    end

    local function Disconnect()
        Highlighter:Destroy()  -- Use Destroy instead of Remove
        for _, Connection in next, Connections do
            Connection:Disconnect()
        end
    end

    --// Connect functions to events
    table.insert(Connections, Player:GetPropertyChangedSignal("TeamColor"):Connect(UpdateFillColor))
    table.insert(Connections, Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        if Humanoid.Health <= 0 then
            Disconnect()
        end
    end))

    -- Update fill color initially
    UpdateFillColor()
end

local function HighlightPlayer(Player)
    if Player.Character then
        ApplyHighlight(Player)  -- Fix the function call
    end
    Player.CharacterAdded:Connect(function()
        ApplyHighlight(Player)  -- Fix the function call
    end)
end

--// Apply highlights to players
for _, Player in next, Players:GetPlayers() do
    HighlightPlayer(Player)  -- Fix the function call
end
Players.PlayerAdded:Connect(HighlightPlayer)
