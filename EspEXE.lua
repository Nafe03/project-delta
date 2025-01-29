-- Optimized ESP Script for Roblox
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

-- Function to Create Drawing Objects Efficiently
local function CreateESPText(color, size)
    local text = Drawing.new("Text")
    text.Size = size
    text.Center = true
    text.Outline = true
    text.Color = color
    text.Font = 3
    text.Visible = false
    return text
end

local function CreateESPBox()
    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Filled = false
    box.Color = _G.BoxColor
    box.Visible = false
    return box
end

local function CreateHealthBar()
    local healthBar = Drawing.new("Square")
    healthBar.Thickness = 1
    healthBar.Filled = true
    healthBar.Visible = false
    return healthBar
end

local function CreateSkeleton()
    local skeleton = {}
    for i = 1, 5 do
        local line = Drawing.new("Line")
        line.Thickness = 1
        line.Color = _G.SkeletonColor
        line.Visible = false
        table.insert(skeleton, line)
    end
    return skeleton
end

-- Function to Get Ammo
local function GetPlayerAmmo(player)
    local backpack = player:FindFirstChild("Backpack")
    local character = player.Character
    if character then
        local tool = character:FindFirstChildOfClass("Tool")
        if tool and tool:FindFirstChild("Script") and tool.Script:FindFirstChild("Ammo") then
            return tool.Script.Ammo.Value
        end
    end
    return "N/A"
end

-- Function to Draw ESP
local function UpdateESP(player, objects)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then 
        for _, obj in pairs(objects) do obj.Visible = false end
        return 
    end
    
    local rootPart = player.Character.HumanoidRootPart
    local screenPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
    
    if not onScreen then
        for _, obj in pairs(objects) do obj.Visible = false end
        return
    end
    
    local size = Vector2.new(3700 / screenPos.Z, 4700 / screenPos.Z)
    local boxPos = Vector2.new(screenPos.X - size.X / 2, screenPos.Y - size.Y / 2)
    
    -- Update Box
    objects.box.Size = size
    objects.box.Position = boxPos
    objects.box.Visible = _G.BoxESPEnabled
    
    -- Update Name
    objects.name.Position = Vector2.new(screenPos.X, boxPos.Y - 20)
    objects.name.Text = player.Name
    objects.name.Visible = _G.NameESPEnabled
    
    -- Update Ammo
    objects.ammo.Position = Vector2.new(screenPos.X, boxPos.Y + size.Y + 5)
    objects.ammo.Text = "Ammo: " .. tostring(GetPlayerAmmo(player))
    objects.ammo.Visible = _G.ShowAmmo
    
    -- Update Health
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if humanoid then
        local healthFraction = humanoid.Health / humanoid.MaxHealth
        objects.health.Size = Vector2.new(5, size.Y * healthFraction)
        objects.health.Position = Vector2.new(boxPos.X - 9, boxPos.Y + size.Y * (1 - healthFraction))
        objects.health.Color = Color3.fromRGB(255 * (1 - healthFraction), 255 * healthFraction, 0)
        objects.health.Visible = _G.HealthESPEnabled
    else
        objects.health.Visible = false
    end
    
    -- Update Skeleton
    if _G.SkeletonESP then
        local character = player.Character
        if character then
            local function drawLine(index, part1, part2)
                if part1 and part2 then
                    local p1, vis1 = Camera:WorldToViewportPoint(part1.Position)
                    local p2, vis2 = Camera:WorldToViewportPoint(part2.Position)
                    if vis1 and vis2 then
                        objects.skeleton[index].From = Vector2.new(p1.X, p1.Y)
                        objects.skeleton[index].To = Vector2.new(p2.X, p2.Y)
                        objects.skeleton[index].Visible = true
                    else
                        objects.skeleton[index].Visible = false
                    end
                else
                    objects.skeleton[index].Visible = false
                end
            end
            
            drawLine(1, character:FindFirstChild("Head"), character:FindFirstChild("UpperTorso"))
            drawLine(2, character:FindFirstChild("UpperTorso"), character:FindFirstChild("LeftUpperArm"))
            drawLine(3, character:FindFirstChild("UpperTorso"), character:FindFirstChild("RightUpperArm"))
            drawLine(4, character:FindFirstChild("UpperTorso"), character:FindFirstChild("LeftUpperLeg"))
            drawLine(5, character:FindFirstChild("UpperTorso"), character:FindFirstChild("RightUpperLeg"))
        end
    else
        for _, line in ipairs(objects.skeleton) do
            line.Visible = false
        end
    end
end

-- Function to Apply ESP
local function ApplyESP(player)
    if activeESP[player] then return end
    local objects = {
        box = CreateESPBox(),
        name = CreateESPText(_G.NameColor, 20),
        ammo = CreateESPText(_G.AmmoColor, 18),
        health = CreateHealthBar(),
        skeleton = CreateSkeleton()
    }
    
    activeESP[player] = objects
    
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not player.Parent or not _G.ESPEnabled then
            connection:Disconnect()
            for _, obj in pairs(objects) do obj:Remove() end
            activeESP[player] = nil
            return
        end
        UpdateESP(player, objects)
    end)
end


-- Initialize ESP for Players
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= Player then ApplyESP(player) end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= Player then ApplyESP(player) end
end)

Players.PlayerRemoving:Connect(function(player)
    if activeESP[player] then
        for _, obj in pairs(activeESP[player]) do obj:Remove() end
        activeESP[player] = nil
    end
end)
