-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Local Player Info
local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ESP Settings
_G.ESPEnabled = true
_G.HealthESPEnabled = true
_G.NameESPEnabled = false
_G.BoxESPEnabled = true
_G.DistanceESPEnabled = false

_G.BoxColor = Color3.fromRGB(255, 255, 255)

-- Active ESP Storage
local activeESP = {}

-- Function to Create Box ESP with Health Bar
local function DrawESPBoxWithHealth(player)
    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart", 5)
    if not rootPart then return end -- Avoid errors if HumanoidRootPart is missing

    -- Create Box
    local box = Drawing.new("Square")
    box.Thickness = 2
    box.Filled = false
    box.Color = _G.BoxColor
    box.Visible = false

    -- Create Health Bar
    local healthBar = Drawing.new("Square")
    healthBar.Thickness = 1
    healthBar.Filled = true
    healthBar.Color = Color3.fromRGB(0, 255, 0)
    healthBar.Visible = false

    -- Update Box and Health Bar Position
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if character and character.Parent and rootPart and _G.BoxESPEnabled then
            local rootPos = rootPart.Position
            local screenPos, onScreen = Camera:WorldToViewportPoint(rootPos)

            if onScreen then
                local size = Vector2.new(3700 / screenPos.Z, 4700 / screenPos.Z)
                local boxPosition = Vector2.new(screenPos.X - size.X / 2, screenPos.Y - size.Y / 2)

                -- Update Box
                box.Size = size
                box.Position = boxPosition
                box.Color = _G.BoxColor
                box.Visible = true

                -- Update Health Bar
                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid then
                    local healthFraction = humanoid.Health / humanoid.MaxHealth
                    healthBar.Size = Vector2.new(5, size.Y * healthFraction)
                    healthBar.Position = Vector2.new(boxPosition.X - 5, boxPosition.Y + size.Y * (1 - healthFraction))
                    healthBar.Color = Color3.fromRGB(255 * (1 - healthFraction), 255 * healthFraction, 0)
                    healthBar.Visible = _G.HealthESPEnabled
                else
                    healthBar.Visible = false
                end
            else
                box.Visible = false
                healthBar.Visible = false
            end
        else
            box.Visible = false
            healthBar.Visible = false
        end
    end)

    -- Handle Character Removal
    character.AncestryChanged:Connect(function(_, parent)
        if not parent then
            box.Visible = false
            healthBar.Visible = false
            if connection then
                connection:Disconnect()
            end
            box:Remove()
            healthBar:Remove()
        end
    end)

    return box, healthBar, connection
end

-- Apply Box ESP with Health Bar to Player
local function applyBoxESPWithHealth(player)
    if not player then return end
    local character = player.Character or player.CharacterAdded:Wait()
    if not character then return end

    -- Create Box and Health Bar
    local box, healthBar, connection = DrawESPBoxWithHealth(player)

    -- Store ESP objects for cleanup later
    activeESP[player] = {
        box = box,
        healthBar = healthBar,
        updateConnection = connection,
    }
end

-- Remove ESP for a player
local function removeESP(player)
    local espData = activeESP[player]
    if espData then
        if espData.box then
            espData.box:Remove()
        end
        if espData.healthBar then
            espData.healthBar:Remove()
        end
        if espData.updateConnection then
            espData.updateConnection:Disconnect()
        end
        activeESP[player] = nil
    end
end

-- Initialize ESP for all players
local function initializeESP(player)
    player.CharacterAdded:Connect(function()
        applyBoxESPWithHealth(player)
    end)
    player.AncestryChanged:Connect(function(_, parent)
        if not parent then
            removeESP(player)
        end
    end)
    if player.Character then
        applyBoxESPWithHealth(player)
    end
end

-- Apply ESP to all players in-game and new ones joining
for _, player in ipairs(Players:GetPlayers()) do
    initializeESP(player)
end
Players.PlayerAdded:Connect(initializeESP)
Players.PlayerRemoving:Connect(removeESP)


-- Toggle ESP Features
local function toggleESPFeature(feature, state)
	_G[feature] = state
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

local function onHighlightToggle(newState)
	toggleESPFeature("HighlightEnabled", newState)
end

-- Example color change usage
local function setHighlightColor(newColor)
	_G.HighlightColor = newColor
end

local function setBoxColor(newColor)
	_G.BoxColor = newColor
end

local function setHealthTextColor(newColor)
	_G.HealthTextColor = newColor
end

setHighlightColor(Color3.fromRGB(255, 255, 255)) -- Changes highlight to red
setBoxColor(Color3.fromRGB(255, 255, 255)) -- Changes box to green
setHealthTextColor(Color3.fromRGB(255, 255, 255)) -- Sets health text
