-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local DefaultColor = Color3.fromRGB(0, 0, 0)

-- ESP Settings
local HealthESPEnabled = true  -- Initially off
local NameESPEnabled = true   -- Initially off
local BoxESPEnabled = true     -- Initially off
local DistanceESPEnabled = true  -- Initially off

-- Function to apply highlight to the player
local function ApplyHighlight(Player)
    local Connections = {}
    local Character = Player.Character or Player.CharacterAdded:Wait()
    local Humanoid = Character:WaitForChild("Humanoid")
    local Highlighter = Instance.new("Highlight", Character)
    local BillboardGui, NameLabel, DistanceLabel, BoxESP

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

    -- Box ESP: Display a box around the player
    local function CreateBoxESP()
        if BoxESPEnabled and not BoxESP then
            BoxESP = Instance.new("BoxHandleAdornment", Character)
            BoxESP.Adornee = Character:WaitForChild("HumanoidRootPart")
            BoxESP.Size = Vector3.new(4, 7, 2)  -- Adjust size based on the character
            BoxESP.ZIndex = 1
            BoxESP.Transparency = 0.5
            BoxESP.Color3 = Color3.new(1, 0, 0)  -- Red color for Box ESP
            BoxESP.AlwaysOnTop = true
        end
    end

    -- Distance ESP: Show distance to the player
    local function CreateDistanceESP()
        if DistanceESPEnabled and not DistanceLabel then
            if not BillboardGui then
                BillboardGui = Instance.new("BillboardGui", Character)
                BillboardGui.Size = UDim2.new(0, 100, 0, 50)
                BillboardGui.Adornee = Character:WaitForChild("Head")
                BillboardGui.StudsOffset = Vector3.new(0, 2, 0)
                BillboardGui.AlwaysOnTop = true
            end

            -- Create Distance Label
            DistanceLabel = Instance.new("TextLabel", BillboardGui)
            DistanceLabel.Size = UDim2.new(1, 0, 0.5, 0)
            DistanceLabel.Position = UDim2.new(0, 0, 1, 0)
            DistanceLabel.BackgroundTransparency = 1
            DistanceLabel.TextColor3 = Color3.new(0, 255, 0)  -- Green color for distance
            DistanceLabel.TextScaled = true

            -- Update the distance
            game:GetService("RunService").Stepped:Connect(function()
                if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                    local distance = (Player.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                    DistanceLabel.Text = string.format("Distance: %.1f", distance)
                end
            end)
        end
    end

    -- Name ESP: Display player name above their head
    local function CreateNameESP()
        if NameESPEnabled and not NameLabel then
            if not BillboardGui then
                BillboardGui = Instance.new("BillboardGui", Character)
                BillboardGui.Size = UDim2.new(0, 100, 0, 50)
                BillboardGui.Adornee = Character:WaitForChild("Head")
                BillboardGui.StudsOffset = Vector3.new(0, 2, 0)
                BillboardGui.AlwaysOnTop = true
            end

            -- Create Name Label
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
        if BoxESP then
            BoxESP:Destroy()
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
    CreateBoxESP()
    CreateDistanceESP()
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

-- Function to enable or disable ESP features
local function setHealthESP(enabled)
    HealthESPEnabled = enabled
    for _, Player in next, Players:GetPlayers() do
        if Player.Character then
            local Humanoid = Player.Character:FindFirstChild("Humanoid")
            if Humanoid then
                -- Manually call to update health transparency
                UpdateHealthTransparency(Player, Humanoid)
            end
        end
    end
end

local function setNameESP(enabled)
    NameESPEnabled = enabled
    for _, Player in next, Players:GetPlayers() do
        if Player.Character then
            if enabled then
                CreateNameESP(Player)  -- Create name ESP
            else
                -- Find and destroy existing BillboardGui
                local BillboardGui = Player.Character:FindFirstChildOfClass("BillboardGui")
                if BillboardGui then
                    BillboardGui:Destroy()
                end
            end
        end
    end
end

local function setBoxESP(enabled)
    BoxESPEnabled = enabled
    for _, Player in next, Players:GetPlayers() do
        if Player.Character then
            if enabled then
                CreateBoxESP(Player)  -- Create Box ESP
            else
                -- Find and destroy existing BoxHandleAdornment
                local BoxESP = Player.Character:FindFirstChildOfClass("BoxHandleAdornment")
                if BoxESP then
                    BoxESP:Destroy()
                end
            end
        end
    end
end

local function setDistanceESP(enabled)
    DistanceESPEnabled = enabled
    for _, Player in next, Players:GetPlayers() do
        if Player.Character then
            if enabled then
                CreateDistanceESP(Player)  -- Create Distance ESP
            else
                -- Find and destroy existing BillboardGui
                local BillboardGui = Player.Character:FindFirstChildOfClass("BillboardGui")
                if BillboardGui and BillboardGui:FindFirstChild("DistanceLabel") then
                    BillboardGui:Destroy()
                end
            end
        end
    end
end

-- Example: Toggle settings through your UI (link this to your actual UI script)
-- This is a placeholder; you should replace it with your UI toggle events
local function onHealthESPToggle(newState)
    setHealthESP(newState)
    print("Health ESP:", newState and "Enabled" or "Disabled")
end

local function onNameESPToggle(newState)
    setNameESP(newState)
    print("Name ESP:", newState and "Enabled" or "Disabled")
end

local function onBoxESPToggle(newState)
    setBoxESP(newState)
    print("Box ESP:", newState and "Enabled" or "Disabled")
end

local function onDistanceESPToggle(newState)
    setDistanceESP(newState)
    print("Distance ESP:", newState and "Enabled" or "Disabled")
end

-- Example UI connection (you would connect these to your UI)
-- onHealthESPToggle(true) -- Call this function when health ESP toggle is enabled
-- onHealthESPToggle(false) -- Call this function when health ESP toggle is disabled
-- onNameESPToggle(true) -- Call this function when name ESP toggle is enabled
-- onNameESPToggle(false) -- Call this function when name ESP toggle is
