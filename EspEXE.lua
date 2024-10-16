-- Services
local Players = game:GetService("Players")
local DefaultColor = Color3.fromRGB(0, 0, 0)

-- ESP Settings
local HealthESPEnabled = true  -- Initially off
local NameESPEnabled = true     -- Initially off
local BoxESPEnabled = true      -- Initially off
local DistanceESPEnabled = true  -- Initially off

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
            Highlighter.FillTransparency = 1 - (Humanoid.Health / Humanoid.MaxHealth)
        else
            Highlighter.FillTransparency = 1  -- Fully transparent if disabled
        end
    end

    -- Box ESP: Create a box around the player
    local function CreateBoxESP()
        if BoxESPEnabled and not Character:FindFirstChild("BoxESP") then
            local BoxESP = Instance.new("BoxHandleAdornment")
            BoxESP.Size = Character:GetExtentsSize() + Vector3.new(0.2, 0.2, 0.2)  -- Slightly larger than the character
            BoxESP.Adornee = Character
            BoxESP.Color3 = Color3.fromRGB(255, 0, 0)
            BoxESP.Transparency = 0.5  -- Semi-transparent
            BoxESP.ZIndex = 5
            BoxESP.AlwaysOnTop = true
            BoxESP.Parent = Character
        end
    end

    -- Distance ESP: Display distance from the local player
    local function CreateDistanceESP()
        if DistanceESPEnabled and not BillboardGui then
            BillboardGui = Instance.new("BillboardGui", Character)
            BillboardGui.Size = UDim2.new(0, 100, 0, 50)
            BillboardGui.Adornee = Character:WaitForChild("Head")
            BillboardGui.StudsOffset = Vector3.new(0, 2, 0)
            BillboardGui.AlwaysOnTop = true

            NameLabel = Instance.new("TextLabel", BillboardGui)
            NameLabel.Size = UDim2.new(1, 0, 1, 0)
            NameLabel.BackgroundTransparency = 1
            NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            NameLabel.TextScaled = true
            
            -- Update the distance label
            local function UpdateDistanceLabel()
                local playerDistance = (Players.LocalPlayer.Character.PrimaryPart.Position - Character.PrimaryPart.Position).magnitude
                NameLabel.Text = string.format("%s - %.1f studs", Player.Name, playerDistance)
            end
            
            -- Connect to an update loop for distance
            local updateConnection = game:GetService("RunService").RenderStepped:Connect(UpdateDistanceLabel)
            table.insert(Connections, updateConnection)
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
    CreateBoxESP()
    CreateDistanceESP()
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
                CreateNameESP(Player)
            else
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
                CreateBoxESP(Player)  -- Create box ESP
            else
                local BoxESP = Player.Character:FindFirstChild("BoxESP")
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
                CreateDistanceESP(Player)  -- Create distance ESP
            else
                local BillboardGui = Player.Character:FindFirstChildOfClass("BillboardGui")
                if BillboardGui then
                    BillboardGui:Destroy()
                end
            end
        end
    end
end

-- Example: Toggle settings through your UI (link this to your actual UI script)
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
-- onHealthESPToggle(true)
-- onHealthESPToggle(false)
-- onNameESPToggle(true)
-- onNameESPToggle(false)
-- onBoxESPToggle(true)
-- onBoxESPToggle(false)
-- onDistanceESPToggle(true)
-- onDistanceESPToggle(false)
