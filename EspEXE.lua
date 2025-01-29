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
_G.NameESPEnabled = true
_G.BoxESPEnabled = true
_G.SkeletonESP = true
_G.DistanceESPEnabled = false
_G.ShowAmmo = true

_G.BoxColor = Color3.fromRGB(255, 255, 255)
_G.NameColor = Color3.fromRGB(255, 255, 255)
_G.AmmoColor = Color3.fromRGB(255, 255, 255)
_G.SkeletonColor = Color3.fromRGB(255, 255, 255)

-- Active ESP Storage
local activeESP = {}

local function cleanupESP(player)
    if activeESP[player] then
        if activeESP[player].box then activeESP[player].box:Remove() end
        if activeESP[player].healthBar then activeESP[player].healthBar:Remove() end
        if activeESP[player].nameTag then activeESP[player].nameTag:Remove() end
        if activeESP[player].ammoTag then activeESP[player].ammoTag:Remove() end
        if activeESP[player].skeletonLines then
            for _, line in ipairs(activeESP[player].skeletonLines) do
                line:Remove()
            end
        end
        if activeESP[player].updateConnection then
            activeESP[player].updateConnection:Disconnect()
        end
        if activeESP[player].characterConnection then
            activeESP[player].characterConnection:Disconnect()
        end
        activeESP[player] = nil
    end
end

local function applyESP(player)
    if not player or player == Player then return end -- Don't apply to local player
    cleanupESP(player)

    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart", 5)
    if not rootPart then return end

    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Filled = false
    box.Color = _G.BoxColor
    box.Visible = false
    
    local nameTag = Drawing.new("Text")
    nameTag.Size = 20
    nameTag.Center = true
    nameTag.Outline = true
    nameTag.Color = _G.NameColor
    nameTag.Font = 3
    nameTag.Visible = false
    
    local ammoTag = Drawing.new("Text")
    ammoTag.Size = 18
    ammoTag.Center = true
    ammoTag.Outline = true
    ammoTag.Color = _G.AmmoColor
    ammoTag.Font = 3
    ammoTag.Visible = false
    
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if character and character.Parent and rootPart then
            local screenPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
            if onScreen then
                local size = Vector2.new(3700 / screenPos.Z, 4700 / screenPos.Z)
                local boxPosition = Vector2.new(screenPos.X - size.X / 2, screenPos.Y - size.Y / 2)
                box.Size = size
                box.Position = boxPosition
                box.Visible = _G.BoxESPEnabled
                
                nameTag.Position = Vector2.new(screenPos.X, boxPosition.Y - 20)
                nameTag.Text = player.Name
                nameTag.Visible = _G.NameESPEnabled
                
                ammoTag.Position = Vector2.new(screenPos.X, boxPosition.Y + size.Y + 5)
                ammoTag.Text = "Ammo: XX"  -- Replace with actual ammo value retrieval
                ammoTag.Visible = _G.ShowAmmo
            else
                box.Visible = false
                nameTag.Visible = false
                ammoTag.Visible = false
            end
        else
            cleanupESP(player)
            connection:Disconnect()
        end
    end)
    
    activeESP[player] = {box = box, nameTag = nameTag, ammoTag = ammoTag, updateConnection = connection}
end

local function initializeESP(player)
    applyESP(player)
    player.CharacterAdded:Connect(function()
        applyESP(player)
    end)
    player.AncestryChanged:Connect(function(_, parent)
        if not parent then
            cleanupESP(player)
        end
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= Player then
        initializeESP(player)
    end
end

Players.PlayerAdded:Connect(initializeESP)
Players.PlayerRemoving:Connect(cleanupESP)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= Player then
        applyESP(player)
    end
end

-- Handle new players joining
Players.PlayerAdded:Connect(function(player)
    if player ~= Player then
        applyESP(player)
    end
end)

-- Handle players leaving
Players.PlayerRemoving:Connect(function(player)
    cleanupESP(player)
end)

-- Toggle ESP Features
local function toggleESPFeature(feature, state)
    _G[feature] = state
end

local function onSkeletonESPToggle(newState)
    toggleESPFeature("SkeletonESP", newState)
end

-- Usage examples:
-- Toggle all ESP features
-- toggleESPFeature("ESPEnabled", true/false)
-- Toggle specific features
-- toggleESPFeature("BoxESPEnabled", true/false)
-- toggleESPFeature("HealthESPEnabled", true/false)
-- toggleESPFeature("NameESPEnabled", true/false)
-- toggleESPFeature("SkeletonESP", true/false)
-- toggleESPFeature("ShowAmmo", true/false)
