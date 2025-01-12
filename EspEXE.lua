-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local PlayerArmor = workspace.Players."Players".BodyEffects.Armor

-- Local Player Info
local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ESP Settings
_G.ESPEnabled = true
_G.HealthESPEnabled = true
_G.NameESPEnabled = true
_G.BoxESPEnabled = true
_G.DistanceESPEnabled = false

_G.BoxColor = Color3.fromRGB(255, 255, 255)
_G.NameColor = Color3.fromRGB(255, 255, 255)

-- Active ESP Storage
local activeESP = {}

-- Function to Create Name ESP
local function CreateNameESP(player)
    local nameTag = Drawing.new("Text")
    nameTag.Size = 20
    nameTag.Center = true
    nameTag.Outline = true
    nameTag.Color = _G.NameColor
    nameTag.Font = 3
    nameTag.Visible = false
    return nameTag
end

-- Function to Create Box ESP with Health and Armor Bars
local function DrawESPBoxWithHealthAndArmor(player)
    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart", 5)
    if not rootPart then return end

    -- Create Box
    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Filled = false
    box.Color = _G.BoxColor
    box.Visible = false

    -- Create Health Bar
    local healthBar = Drawing.new("Square")
    healthBar.Thickness = 1
    healthBar.Filled = true
    healthBar.Color = Color3.fromRGB(0, 255, 0)
    healthBar.Visible = false

    -- Create Armor Bar
    local armorBar = Drawing.new("Square")
    armorBar.Thickness = 1
    armorBar.Filled = true
    armorBar.Color = Color3.fromRGB(0, 0, 255) -- Blue color for armor
    armorBar.Visible = false

    -- Create Name Tag
    local nameTag = CreateNameESP(player)

    local connection
    connection = RunService.RenderStepped:Connect(function()
        if character and character.Parent and rootPart then
            local rootPos = rootPart.Position
            local screenPos, onScreen = Camera:WorldToViewportPoint(rootPos)

            if onScreen then
                local size = Vector2.new(3700 / screenPos.Z, 4700 / screenPos.Z)
                local boxPosition = Vector2.new(screenPos.X - size.X / 2, screenPos.Y - size.Y / 2)

                -- Update Box
                box.Size = size
                box.Position = boxPosition
                box.Color = _G.BoxColor
                box.Visible = _G.BoxESPEnabled

                -- Update Name Tag
                nameTag.Position = Vector2.new(screenPos.X, boxPosition.Y - 20)
                nameTag.Text = player.Name
                nameTag.Color = _G.NameColor
                nameTag.Visible = _G.NameESPEnabled

                -- Update Health Bar
                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid then
                    local healthFraction = humanoid.Health / humanoid.MaxHealth
                    healthBar.Size = Vector2.new(5, size.Y * healthFraction)
                    healthBar.Position = Vector2.new(boxPosition.X - 9, boxPosition.Y + size.Y * (1 - healthFraction))
                    healthBar.Color = Color3.fromRGB(255 * (1 - healthFraction), 255 * healthFraction, 0)
                    healthBar.Visible = _G.HealthESPEnabled
                else
                    healthBar.Visible = false
                end

                -- Update Armor Bar
                local armorValue = workspace.Players:FindFirstChild(player.Name)
                if armorValue and armorValue:FindFirstChild("BodyEffects") and armorValue.BodyEffects:FindFirstChild("Armor") then
                    local currentArmor = armorValue.BodyEffects.Armor.Value
                    local maxArmor = 100 -- Assuming max armor is 100
                    local armorFraction = currentArmor / maxArmor
                    armorBar.Size = Vector2.new(5, size.Y * armorFraction)
                    armorBar.Position = Vector2.new(boxPosition.X - 15, boxPosition.Y + size.Y * (1 - armorFraction))
                    armorBar.Visible = _G.HealthESPEnabled
                else
                    armorBar.Visible = false
                end
            else
                box.Visible = false
                healthBar.Visible = false
                armorBar.Visible = false
                nameTag.Visible = false
            end
        else
            box.Visible = false
            healthBar.Visible = false
            armorBar.Visible = false
            nameTag.Visible = false
        end
    end)

    -- Handle Character Removal
    character.AncestryChanged:Connect(function(_, parent)
        if not parent then
            box.Visible = false
            healthBar.Visible = false
            armorBar.Visible = false
            nameTag.Visible = false
            if connection then
                connection:Disconnect()
            end
            box:Remove()
            healthBar:Remove()
            armorBar:Remove()
            nameTag:Remove()
        end
    end)

    return box, healthBar, armorBar, nameTag, connection
end

-- Apply Box ESP with Health and Armor Bars to Player
local function applyBoxESPWithHealthAndArmor(player)
    if not player then return end
    local character = player.Character or player.CharacterAdded:Wait()
    if not character then return end

    -- Create Box, Health Bar, Armor Bar, and Name Tag
    local box, healthBar, armorBar, nameTag, connection = DrawESPBoxWithHealthAndArmor(player)

    -- Store ESP objects for cleanup later
    activeESP[player] = {
        box = box,
        healthBar = healthBar,
        armorBar = armorBar,
        nameTag = nameTag,
        updateConnection = connection,
    }
end

-- Initialize ESP for all players
local function initializeESP(player)
    player.CharacterAdded:Connect(function()
        applyBoxESPWithHealthAndArmor(player)
    end)
    player.AncestryChanged:Connect(function(_, parent)
        if not parent then
            removeESP(player)
        end
    end)
    if player.Character then
        applyBoxESPWithHealthAndArmor(player)
    end
end

-- Apply ESP to all players in-game and new ones joining
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= Player then  -- Don't apply ESP to local player
        initializeESP(player)
    end
end
Players.PlayerAdded:Connect(function(player)
    if player ~= Player then  -- Don't apply ESP to local player
        initializeESP(player)
    end
end)
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

-- Color Settings
local function setBoxColor(newColor)
    _G.BoxColor = newColor
end

local function setNameColor(newColor)
    _G.NameColor = newColor
end
