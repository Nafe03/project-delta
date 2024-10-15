--// Written by depso
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- ESP toggle variable
local espEnabled = true  -- Set to true to enable ESP by default
local teamCheck = true   -- Set to true if you want team-based ESP filtering

-- Function to apply Name ESP
local function ApplyNameESP(Player)
    local Character = Player.Character or Player.CharacterAdded:Wait()
    local Head = Character:WaitForChild("Head")
    
    -- Create BillboardGui for name display
    local BillboardGui = Instance.new("BillboardGui", Head)
    BillboardGui.Name = "NameESP"
    BillboardGui.AlwaysOnTop = true
    BillboardGui.Size = UDim2.new(0, 100, 0, 25)
    BillboardGui.StudsOffset = Vector3.new(0, 2, 0)

    local TextLabel = Instance.new("TextLabel", BillboardGui)
    TextLabel.Size = UDim2.new(1, 0, 1, 0)
    TextLabel.Text = Player.Name
    TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TextLabel.TextScaled = true
    TextLabel.BackgroundTransparency = 1
end

-- Function to apply Highlight
local function ApplyHighlight(Player)
    local Connections = {}

    --// Parts
    local Character = Player.Character or Player.CharacterAdded:Wait()
    local Humanoid = Character:WaitForChild("Humanoid")
    local HightLighter = Instance.new("Highlight", Character)

    local function UpdateFillColor()
        local DefaultColor = Color3.fromRGB(255, 48, 51)  -- Default color if no team color is found
        if teamCheck then
            -- If team check is enabled, only highlight enemies (not on the same team)
            if Player.TeamColor ~= LocalPlayer.TeamColor then
                HightLighter.FillColor = (Player.TeamColor and Player.TeamColor.Color) or DefaultColor
            else
                HightLighter.Enabled = false  -- Disable highlight for teammates if teamCheck is true
            end
        else
            -- No team check, apply the highlight regardless of team
            HightLighter.FillColor = (Player.TeamColor and Player.TeamColor.Color) or DefaultColor
        end
    end

    local function Disconnect()
        -- Clean up the highlight and connections
        HightLighter:Destroy()
        for _, Connection in next, Connections do
            Connection:Disconnect()
        end
    end

    -- Update highlight when team changes
    table.insert(Connections, Player:GetPropertyChangedSignal("TeamColor"):Connect(UpdateFillColor))

    -- Remove highlight when player dies
    table.insert(Connections, Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        if Humanoid.Health <= 0 then
            Disconnect()
        end
    end))

    UpdateFillColor()  -- Call once initially to set color
    ApplyNameESP(Player)  -- Apply Name ESP
end

-- Function to highlight the player
local function HighlightPlayer(Player)
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

-- Apply highlights to all players in the game
for _, Player in next, Players:GetPlayers() do
    HighlightPlayer(Player)
end

Players.PlayerAdded:Connect(HighlightPlayer)

-- Function to toggle ESP
local function ToggleESP()
    espEnabled = not espEnabled  -- Toggle the ESP state
    for _, Player in next, Players:GetPlayers() do
        if Player.Character then
            if espEnabled then
                ApplyHighlight(Player)  -- Apply highlight if ESP is enabled
            else
                -- Remove highlight and name ESP if ESP is disabled
                if Player.Character:FindFirstChild("Highlight") then
                    Player.Character.Highlight:Destroy()
                end
                if Player.Character.Head:FindFirstChild("NameESP") then
                    Player.Character.Head.NameESP:Destroy()
                end
            end
        end
    end
end

-- Example of binding the ToggleESP function to a key (e.g., 'E')
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then
        if input.KeyCode == Enum.KeyCode.E then  -- Change to desired key
            ToggleESP()
        end
    end
end)
