-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ESP Drawing objects storage
local ESPObjects = {}

-- Font mapping
local fontMap = {
    ["SourceSans"] = Drawing.Fonts.UI,
    ["Plex"] = Drawing.Fonts.Plex,
    ["System"] = Drawing.Fonts.System,
    ["Monospace"] = Drawing.Fonts.Monospace
}

-- Initialize default settings if they don't exist in getgenv()
if not getgenv().espColor then getgenv().espColor = Color3.new(1, 1, 1) end
if not getgenv().nameColor then getgenv().nameColor = Color3.new(1, 1, 1) end
if not getgenv().distanceColor then getgenv().distanceColor = Color3.new(1, 1, 1) end
if not getgenv().healthBarColor then getgenv().healthBarColor = Color3.new(0, 1, 0) end
if not getgenv().weaponColor then getgenv().weaponColor = Color3.new(1, 1, 0) end
if not getgenv().armorBarColor then getgenv().armorBarColor = Color3.new(0, 0.5, 1) end
if not getgenv().penisColor then getgenv().penisColor = Color3.new(0.85, 0.65, 0.5) end
if not getgenv().nameTextSize then getgenv().nameTextSize = 18 end
if not getgenv().distanceTextSize then getgenv().distanceTextSize = 16 end
if not getgenv().nameDisplayMode then getgenv().nameDisplayMode = "Username" end
if not getgenv().maxDistance then getgenv().maxDistance = 1000 end -- Added MaxDistance setting

-- Global ESP toggle variables
_G.ESPEnabled = true
_G.HealthESPEnabled = true
_G.NameESPEnabled = true
_G.BoxESPEnabled = true
_G.DistanceESPEnabled = true
_G.WeaponESPEnabled = true
_G.ArmorESPEnabled = true
_G.PenisESPEnabled = true
_G.OutlineEnabled = false
_G.GlowEnabled = true -- Added glow toggle
_G.MaxDistance = 1000 -- Added MaxDistance toggle

-- Set up reference to existing globals if they exist, otherwise use the new _G values
getgenv().espEnabled = getgenv().espEnabled or _G.ESPEnabled
getgenv().healthBarESP = getgenv().healthBarESP or _G.HealthESPEnabled
getgenv().nameESPEnabled = getgenv().nameESPEnabled or _G.NameESPEnabled
getgenv().studsESPEnabled = getgenv().studsESPEnabled or _G.DistanceESPEnabled
getgenv().weaponESPEnabled = getgenv().weaponESPEnabled or _G.WeaponESPEnabled
getgenv().armorBarESP = getgenv().armorBarESP or _G.ArmorESPEnabled
getgenv().penisESPEnabled = getgenv().penisESPEnabled or _G.PenisESPEnabled
getgenv().outlineEnabled = getgenv().outlineEnabled or _G.OutlineEnabled
getgenv().glowEnabled = getgenv().glowEnabled or _G.GlowEnabled -- Added glow reference
getgenv().maxDistance = getgenv().maxDistance or _G.MaxDistance -- Added MaxDistance reference

-- Function to synchronize _G variables with getgenv variables
local function syncESPSettings()
    getgenv().espEnabled = _G.ESPEnabled
    getgenv().healthBarESP = _G.HealthESPEnabled
    getgenv().nameESPEnabled = _G.NameESPEnabled
    getgenv().studsESPEnabled = _G.DistanceESPEnabled
    getgenv().weaponESPEnabled = _G.WeaponESPEnabled
    getgenv().armorBarESP = _G.ArmorESPEnabled
    getgenv().penisESPEnabled = _G.PenisESPEnabled
    getgenv().outlineEnabled = _G.OutlineEnabled
    getgenv().glowEnabled = _G.GlowEnabled -- Added glow sync
    getgenv().maxDistance = _G.MaxDistance -- Added MaxDistance sync
end

-- Function to destroy ESP for a player
local function DestroyESP(player)
    if ESPObjects[player] then
        for _, obj in pairs(ESPObjects[player]) do
            if obj and typeof(obj) == "table" and obj.Remove then
                obj:Remove()
            elseif obj and typeof(obj) == "Instance" then
                obj:Destroy()
            end
        end
        ESPObjects[player] = nil
    end
end

-- Function to create ESP for a player
local function CreateESP(player)
    DestroyESP(player)

    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Filled = false
    box.Color = getgenv().espColor
    box.Visible = false
    box.ZIndex = 1

    local boxOutline = Drawing.new("Square")
    boxOutline.Thickness = 3
    boxOutline.Filled = false
    boxOutline.Color = Color3.new(0, 0, 0)
    boxOutline.Visible = false
    boxOutline.ZIndex = 0

    local username = Drawing.new("Text")
    username.Size = getgenv().nameTextSize
    username.Center = true
    username.Color = getgenv().nameColor
    username.Visible = false
    username.Font = fontMap["SourceSans"]
    username.Outline = getgenv().outlineEnabled
    username.OutlineColor = Color3.new(0, 0, 0)

    local distance = Drawing.new("Text")
    distance.Size = getgenv().distanceTextSize
    distance.Center = true
    distance.Color = getgenv().distanceColor
    distance.Visible = false
    distance.Font = fontMap["SourceSans"]
    distance.Outline = getgenv().outlineEnabled
    distance.OutlineColor = Color3.new(0, 0, 0)

    local healthBar = Drawing.new("Square")
    healthBar.Thickness = 1
    healthBar.Filled = true
    healthBar.Color = getgenv().healthBarColor
    healthBar.Visible = false
    healthBar.ZIndex = 1

    local healthBarOutline = Drawing.new("Square")
    healthBarOutline.Thickness = 3
    healthBarOutline.Filled = false
    healthBarOutline.Color = Color3.new(0, 0, 0)
    healthBarOutline.Visible = false
    healthBarOutline.ZIndex = 0

    local weapon = Drawing.new("Text")
    weapon.Size = getgenv().nameTextSize
    weapon.Center = true
    weapon.Color = getgenv().weaponColor
    weapon.Visible = false
    weapon.Font = fontMap["SourceSans"]
    weapon.Outline = getgenv().outlineEnabled
    weapon.OutlineColor = Color3.new(0, 0, 0)

    local armorBar = Drawing.new("Square")
    armorBar.Thickness = 1
    armorBar.Filled = true
    armorBar.Color = getgenv().armorBarColor
    armorBar.Visible = false
    armorBar.ZIndex = 1

    local armorBarOutline = Drawing.new("Square")
    armorBarOutline.Thickness = 3
    armorBarOutline.Filled = false
    armorBarOutline.Color = Color3.new(0, 0, 0)
    armorBarOutline.Visible = false
    armorBarOutline.ZIndex = 0

    local penisLine = Drawing.new("Line")
    penisLine.Thickness = 2
    penisLine.Color = getgenv().penisColor
    penisLine.Visible = false
    penisLine.ZIndex = 1

    local highlight = Instance.new("Highlight")
    highlight.Adornee = player.Character
    highlight.FillColor = Color3.new(1, 0, 0) -- Default color when behind a wall
    highlight.OutlineColor = Color3.new(1, 1, 1) -- Default color when visible
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Enabled = _G.GlowEnabled

    ESPObjects[player] = {
        Box = box,
        BoxOutline = boxOutline,
        Username = username,
        Distance = distance,
        HealthBar = healthBar,
        HealthBarOutline = healthBarOutline,
        Weapon = weapon,
        ArmorBar = armorBar,
        ArmorBarOutline = armorBarOutline,
        PenisLine = penisLine,
        Highlight = highlight
    }
end

-- Function to apply ESP settings
local function applyESP()
    for _, objects in pairs(ESPObjects) do
        -- These will just update the visibility settings, not positions
        if not _G.ESPEnabled then
            -- If main ESP is disabled, hide everything
            for _, obj in pairs(objects) do
                if obj and typeof(obj) == "table" and obj.Visible ~= nil then
                    obj.Visible = false
                elseif obj and typeof(obj) == "Instance" then
                    obj.Enabled = false
                end
            end
        else
            -- Otherwise, set visibility based on individual toggles
            if objects.Box and typeof(objects.Box) == "table" then
                objects.Box.Visible = _G.BoxESPEnabled
            end
            if objects.BoxOutline and typeof(objects.BoxOutline) == "table" then
                objects.BoxOutline.Visible = _G.OutlineEnabled and _G.BoxESPEnabled
            end
            if objects.Username and typeof(objects.Username) == "table" then
                objects.Username.Visible = _G.NameESPEnabled
            end
            if objects.Distance and typeof(objects.Distance) == "table" then
                objects.Distance.Visible = _G.DistanceESPEnabled
            end
            if objects.HealthBar and typeof(objects.HealthBar) == "table" then
                objects.HealthBar.Visible = _G.HealthESPEnabled
            end
            if objects.HealthBarOutline and typeof(objects.HealthBarOutline) == "table" then
                objects.HealthBarOutline.Visible = _G.OutlineEnabled and _G.HealthESPEnabled
            end
            if objects.Weapon and typeof(objects.Weapon) == "table" then
                objects.Weapon.Visible = _G.WeaponESPEnabled
            end
            if objects.ArmorBar and typeof(objects.ArmorBar) == "table" then
                objects.ArmorBar.Visible = _G.ArmorESPEnabled
            end
            if objects.ArmorBarOutline and typeof(objects.ArmorBarOutline) == "table" then
                objects.ArmorBarOutline.Visible = _G.OutlineEnabled and _G.ArmorESPEnabled
            end
            if objects.PenisLine and typeof(objects.PenisLine) == "table" then
                objects.PenisLine.Visible = _G.PenisESPEnabled
            end
            if objects.Highlight and typeof(objects.Highlight) == "Instance" then
                objects.Highlight.Enabled = _G.GlowEnabled
            end
        end
    end
end

-- Function to update ESP - Fixed to handle type check errors
local function UpdateESP()
    for player, objects in pairs(ESPObjects) do
        if not player or not player.Parent or not player:IsA("Player") then
            DestroyESP(player)
            continue
        end

        local character = player.Character
        if not character or not _G.ESPEnabled or player == LocalPlayer then
            -- Hide all ESP elements if ESP is disabled or character doesn't exist
            for _, obj in pairs(objects) do
                if obj and typeof(obj) == "table" and obj.Visible ~= nil then
                    obj.Visible = false
                elseif obj and typeof(obj) == "Instance" then
                    obj.Enabled = false
                end
            end
            continue -- Skip to next player
        end

        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChildOfClass("Humanoid")

        if not rootPart or not humanoid then
            -- Hide ESP for non-existent humanoids
            for _, obj in pairs(objects) do
                if obj and typeof(obj) == "table" and obj.Visible ~= nil then
                    obj.Visible = false
                elseif obj and typeof(obj) == "Instance" then
                    obj.Enabled = false
                end
            end
            continue -- Skip to next player
        end

        -- Fix: Check if Health is a number and greater than 0
        local health = tonumber(humanoid.Health)
        if not health or health <= 0 then
            -- Hide ESP for dead humanoids
            for _, obj in pairs(objects) do
                if obj and typeof(obj) == "table" and obj.Visible ~= nil then
                    obj.Visible = false
                elseif obj and typeof(obj) == "Instance" then
                    obj.Enabled = false
                end
            end
            continue -- Skip to next player
        end

        local rootPosition, onScreen = Camera:WorldToViewportPoint(rootPart.Position)

        if not onScreen then
            -- Hide all ESP elements if off-screen
            for _, obj in pairs(objects) do
                if obj and typeof(obj) == "table" and obj.Visible ~= nil then
                    obj.Visible = false
                elseif obj and typeof(obj) == "Instance" then
                    obj.Enabled = false
                end
            end
            continue -- Skip to next player
        end

        -- Check the distance to the player
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (LocalPlayer.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
            if distance > getgenv().maxDistance then
                -- Hide all ESP elements if the player is too far
                for _, obj in pairs(objects) do
                    if obj and typeof(obj) == "table" and obj.Visible ~= nil then
                        obj.Visible = false
                    elseif obj and typeof(obj) == "Instance" then
                        obj.Enabled = false
                    end
                end
                continue -- Skip to next player
            end
        end

        -- Check if the player is behind a wall using raycasting
        local ray = Ray.new(Camera.CFrame.Position, (rootPart.Position - Camera.CFrame.Position).unit * 1000)
        local hitPart, hitPosition = Workspace:FindPartOnRay(ray, character)
        local isBehindWall = hitPart and hitPart.Transparency < 1 and hitPart.CanCollide

        -- Update glow color based on visibility
        if objects.Highlight and typeof(objects.Highlight) == "Instance" then
            if isBehindWall then
                objects.Highlight.FillColor = Color3.new(1, 0, 0) -- Red when behind a wall
                objects.Highlight.OutlineColor = Color3.new(1, 0, 0)
            else
                objects.Highlight.FillColor = Color3.new(0, 1, 0) -- Green when visible
                objects.Highlight.OutlineColor = Color3.new(0, 1, 0)
            end
        end

        -- If we get here, the player is valid, on-screen, and ESP is enabled
        -- Calculate positions for ESP elements
        local headPosition = Camera:WorldToViewportPoint(rootPart.Position + Vector3.new(0, 3, 0))
        local footPosition = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))
        local boxHeight = math.abs(headPosition.Y - footPosition.Y)
        local boxWidth = boxHeight / 2

        -- Update Box ESP
        if _G.BoxESPEnabled and objects.Box and typeof(objects.Box) == "table" then
            objects.Box.Position = Vector2.new(rootPosition.X - boxWidth / 2, headPosition.Y)
            objects.Box.Size = Vector2.new(boxWidth, boxHeight)
            objects.Box.Color = getgenv().espColor
            objects.Box.Visible = true

            if _G.OutlineEnabled and objects.BoxOutline and typeof(objects.BoxOutline) == "table" then
                objects.BoxOutline.Position = Vector2.new(rootPosition.X - boxWidth / 2, headPosition.Y)
                objects.BoxOutline.Size = Vector2.new(boxWidth, boxHeight)
                objects.BoxOutline.Visible = true
            else
                if objects.BoxOutline and typeof(objects.BoxOutline) == "table" then
                    objects.BoxOutline.Visible = false
                end
            end
        else
            if objects.Box and typeof(objects.Box) == "table" then
                objects.Box.Visible = false
            end
            if objects.BoxOutline and typeof(objects.BoxOutline) == "table" then
                objects.BoxOutline.Visible = false
            end
        end

        -- Update Name ESP
        if _G.NameESPEnabled and objects.Username and typeof(objects.Username) == "table" then
            local displayName = ""

            if getgenv().nameDisplayMode == "Username" then
                displayName = player.Name
            elseif getgenv().nameDisplayMode == "DisplayName" then
                displayName = player.DisplayName
            elseif getgenv().nameDisplayMode == "Username (DisplayName)" then
                displayName = player.Name .. " (" .. player.DisplayName .. ")"
            elseif getgenv().nameDisplayMode == "Username (DisplayName) [UserID]" then
                displayName = player.Name .. " (" .. player.DisplayName .. ") [" .. player.UserId .. "]"
            end

            objects.Username.Position = Vector2.new(rootPosition.X, headPosition.Y - 15)
            objects.Username.Text = displayName
            objects.Username.Size = getgenv().nameTextSize
            objects.Username.Font = fontMap["SourceSans"]
            objects.Username.Color = getgenv().nameColor
            objects.Username.Outline = _G.OutlineEnabled
            objects.Username.Visible = true
        else
            if objects.Username and typeof(objects.Username) == "table" then
                objects.Username.Visible = false
            end
        end

        -- Update Distance ESP
        if _G.DistanceESPEnabled and objects.Distance and typeof(objects.Distance) == "table" and
           LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local distanceValue = (LocalPlayer.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
            local distanceText = math.floor(distanceValue) .. " studs"

            objects.Distance.Position = Vector2.new(rootPosition.X, footPosition.Y + 5)
            objects.Distance.Text = distanceText
            objects.Distance.Size = getgenv().distanceTextSize
            objects.Distance.Font = fontMap["SourceSans"]
            objects.Distance.Color = getgenv().distanceColor
            objects.Distance.Outline = _G.OutlineEnabled
            objects.Distance.Visible = true
        else
            if objects.Distance and typeof(objects.Distance) == "table" then
                objects.Distance.Visible = false
            end
        end

        -- Update Health Bar ESP
        if _G.HealthESPEnabled and objects.HealthBar and typeof(objects.HealthBar) == "table" then
            -- Fix: Ensure health and maxHealth are numbers
            local health = tonumber(humanoid.Health) or 0
            local maxHealth = tonumber(humanoid.MaxHealth) or 100
            if maxHealth <= 0 then maxHealth = 100 end -- Safety check

            local healthRatio = math.clamp(health / maxHealth, 0, 1)
            local barHeight = boxHeight * healthRatio

            objects.HealthBar.Position = Vector2.new(rootPosition.X - boxWidth / 2 - 6, headPosition.Y + (boxHeight - barHeight))
            objects.HealthBar.Size = Vector2.new(3, barHeight)
            objects.HealthBar.Color = getgenv().healthBarColor
            objects.HealthBar.Visible = true

            if _G.OutlineEnabled and objects.HealthBarOutline and typeof(objects.HealthBarOutline) == "table" then
                objects.HealthBarOutline.Position = Vector2.new(rootPosition.X - boxWidth / 2 - 6, headPosition.Y)
                objects.HealthBarOutline.Size = Vector2.new(3, boxHeight)
                objects.HealthBarOutline.Visible = true
            else
                if objects.HealthBarOutline and typeof(objects.HealthBarOutline) == "table" then
                    objects.HealthBarOutline.Visible = false
                end
            end
        else
            if objects.HealthBar and typeof(objects.HealthBar) == "table" then
                objects.HealthBar.Visible = false
            end
            if objects.HealthBarOutline and typeof(objects.HealthBarOutline) == "table" then
                objects.HealthBarOutline.Visible = false
            end
        end

        -- Update Weapon ESP
        if _G.WeaponESPEnabled and objects.Weapon and typeof(objects.Weapon) == "table" then
            local tool = character:FindFirstChildOfClass("Tool")
            if tool then
                objects.Weapon.Position = Vector2.new(rootPosition.X, footPosition.Y + 20)
                objects.Weapon.Text = tool.Name
                objects.Weapon.Size = getgenv().nameTextSize
                objects.Weapon.Font = fontMap["SourceSans"]
                objects.Weapon.Color = getgenv().weaponColor
                objects.Weapon.Outline = _G.OutlineEnabled
                objects.Weapon.Visible = true
            else
                objects.Weapon.Visible = false
            end
        else
            if objects.Weapon and typeof(objects.Weapon) == "table" then
                objects.Weapon.Visible = false
            end
        end

        -- Update Armor Bar ESP (Specific to Da Hood)
        if _G.ArmorESPEnabled and objects.ArmorBar and typeof(objects.ArmorBar) == "table" then
            local armorValue = 0

            -- For Da Hood, check for armor in different ways
            local dataFolder = player:FindFirstChild("DataFolder")
            if dataFolder then
                local information = dataFolder:FindFirstChild("Information")
                if information then
                    local armorSave = information:FindFirstChild("ArmorSave")
                    if armorSave and armorSave:IsA("IntValue") then
                        armorValue = armorSave.Value
                    end
                end
            end

            -- Alternative method if above doesn't work
            if armorValue == 0 then
                if character:FindFirstChild("BodyEffects") then
                    local armor = character.BodyEffects:FindFirstChild("Armor")
                    if armor and armor:IsA("NumberValue") then
                        armorValue = armor.Value
                    end
                end
            end

            -- Make sure armorValue is a number
            armorValue = tonumber(armorValue) or 0

            if armorValue > 0 then
                local armorRatio = math.clamp(armorValue / 130, 0, 1) -- Cap between 0 and 1
                local armorHeight = boxHeight * armorRatio

                objects.ArmorBar.Position = Vector2.new(rootPosition.X + boxWidth / 2 + 3, headPosition.Y + (boxHeight - armorHeight))
                objects.ArmorBar.Size = Vector2.new(3, armorHeight)
                objects.ArmorBar.Color = getgenv().armorBarColor
                objects.ArmorBar.Visible = true

                if _G.OutlineEnabled and objects.ArmorBarOutline and typeof(objects.ArmorBarOutline) == "table" then
                    objects.ArmorBarOutline.Position = Vector2.new(rootPosition.X + boxWidth / 2 + 3, headPosition.Y)
                    objects.ArmorBarOutline.Size = Vector2.new(3, boxHeight)
                    objects.ArmorBarOutline.Visible = true
                else
                    if objects.ArmorBarOutline and typeof(objects.ArmorBarOutline) == "table" then
                        objects.ArmorBarOutline.Visible = false
                    end
                end
            else
                objects.ArmorBar.Visible = false
                if objects.ArmorBarOutline and typeof(objects.ArmorBarOutline) == "table" then
                    objects.ArmorBarOutline.Visible = false
                end
            end
        else
            if objects.ArmorBar and typeof(objects.ArmorBar) == "table" then
                objects.ArmorBar.Visible = false
            end
            if objects.ArmorBarOutline and typeof(objects.ArmorBarOutline) == "table" then
                objects.ArmorBarOutline.Visible = false
            end
        end

        -- Update Penis ESP
        if _G.PenisESPEnabled and objects.PenisLine and typeof(objects.PenisLine) == "table" then
            local pelvis = character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso")
            if pelvis then
                local pelvisPosition = Camera:WorldToViewportPoint(pelvis.Position)
                local lookVector = rootPart.CFrame.LookVector
                local penisEndPosition = Camera:WorldToViewportPoint(pelvis.Position + lookVector * 2)

                objects.PenisLine.From = Vector2.new(pelvisPosition.X, pelvisPosition.Y)
                objects.PenisLine.To = Vector2.new(penisEndPosition.X, penisEndPosition.Y)
                objects.PenisLine.Color = getgenv().penisColor
                objects.PenisLine.Visible = true
            else
                objects.PenisLine.Visible = false
            end
        else
            if objects.PenisLine and typeof(objects.PenisLine) == "table" then
                objects.PenisLine.Visible = false
            end
        end
    end
end

-- Create a function to toggle ESP settings
function toggleESP(setting, value)
    if setting == "Main" then
        _G.ESPEnabled = value
    elseif setting == "Box" then
        _G.BoxESPEnabled = value
    elseif setting == "Name" then
        _G.NameESPEnabled = value
    elseif setting == "Health" then
        _G.HealthESPEnabled = value
    elseif setting == "Distance" then
        _G.DistanceESPEnabled = value
    elseif setting == "Weapon" then
        _G.WeaponESPEnabled = value
    elseif setting == "Armor" then
        _G.ArmorESPEnabled = value
    elseif setting == "Penis" then
        _G.PenisESPEnabled = value
    elseif setting == "Outline" then
        _G.OutlineEnabled = value
    elseif setting == "Glow" then
        _G.GlowEnabled = value
    elseif setting == "MaxDistance" then
        _G.MaxDistance = value
    end

    syncESPSettings()
    applyESP()
end

-- Error handling wrapper for creating ESP
local function safeCreateESP(player)
    local success, err = pcall(function()
        if player ~= LocalPlayer and player.Character then
            CreateESP(player)
        end
    end)

    if not success then
        warn("Error creating ESP for " .. player.Name .. ": " .. tostring(err))
    end
end

-- Player Added/Removed Events
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1) -- Wait for character to fully load
        safeCreateESP(player)
    end)

    -- In case the player already has a character
    if player.Character then
        task.wait(1)
        safeCreateESP(player)
    end
end)

Players.PlayerRemoving:Connect(DestroyESP)

-- Initialize ESP for existing players
for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        task.spawn(function() -- Use task.spawn to avoid blocking the main thread
            task.wait(1) -- Give time for characters to load
            safeCreateESP(player)
        end)
    end
end

-- Catch errors in UpdateESP
RunService.RenderStepped:Connect(function()
    local success, err = pcall(UpdateESP)
    if not success then
        warn("Error updating ESP: " .. tostring(err))
    end
end)

-- Initial sync of settings
syncESPSettings()
applyESP()

-- Return toggleESP function for external use
return toggleESP 
