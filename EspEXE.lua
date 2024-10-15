--// Written by depso
local Players = game:GetService("Players")

-- ESP toggle variable
local espEnabled = true  -- Set to true to enable ESP by default

local function ApplyHighlight(Player)
    local Connections = {}

    --// Parts
    local Character = Player.Character or Player.CharacterAdded:Wait()
    local Humanoid = Character:WaitForChild("Humanoid")
    local HightLighter = Instance.new("Highlight", Character)

    local function UpdateFillColor()
        local DefaultColor = Color3.fromRGB(255, 48, 51)
        HightLighter.FillColor = (Player.TeamColor and Player.TeamColor.Color) or DefaultColor
    end

    local function Disconnect()
        HightLighter:Destroy()  -- Use Destroy() instead of Remove()
        
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
end

local function HightLightPlayer(Player)
    if Player.Character then
        if espEnabled then  -- Check if ESP is enabled
            ApplyHighlight(Player)
        end
    end
    Player.CharacterAdded:Connect(function()
        if espEnabled then  -- Check if ESP is enabled
            ApplyHighlight(Player)
        end
    end)
end

--// Apply highlights to players
for _, Player in next, Players:GetPlayers() do
    HightLightPlayer(Player)
end

Players.PlayerAdded:Connect(HightLightPlayer)

-- Function to toggle ESP
local function ToggleESP()
    espEnabled = not espEnabled  -- Toggle the ESP state
    for _, Player in next, Players:GetPlayers() do
        if Player.Character then
            if espEnabled then
                ApplyHighlight(Player)  -- Apply highlight if ESP is enabled
            else
                -- Remove highlight if ESP is disabled
                if Player.Character:FindFirstChild("Highlight") then
                    Player.Character.Highlight:Destroy()
                end
            end
        end
    end
end

-- Example of binding the ToggleESP function to a key (e.g., 'E')
local UserInputService = game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then
        if input.KeyCode == Enum.KeyCode.E then  -- Change to desired key
            ToggleESP()
        end
    end
end)
