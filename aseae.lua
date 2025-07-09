-- https://discord.gg/UgQAPcBtpy

local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()
local Window = Library:CreateWindow({ Title = '                     [ Zest.Hub | Beta V1.0 ]                    ', AutoShow = true, TabPadding = 5, MenuFadeTime = 0.2 })
local Tabs = { Main = Window:AddTab('Rage'), Legit = Window:AddTab('Legit'), Character = Window:AddTab('Character'), Visuals = Window:AddTab('World'), Misc = Window:AddTab('Misc'), Players = Window:AddTab('Players'), ['UI Settings'] = Window:AddTab('UI Settings') }
local GunMods = Tabs.Main:AddRightGroupbox('Gun Mods')
local KillAura = Tabs.Main:AddRightGroupbox('Combat')

local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')

local LocalPlayer = game:GetService('Players').LocalPlayer
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local lockedTarget = nil
local StickyAimEnabled = false
local HighlightEnabled = false
local TracerEnabled = true
local ViewTargetEnabled = false
local targetHitPart = "Head"
local targetToMouseTracer = true
local grabCheckEnabled = true
local koCheckEnabled = true
local friendCheckEnabled = false
local strafeEnabled = false
local strafeMode = "Orbit"
local strafeSpeed = 5
local strafeXOffset = 5
local predictMovementEnabled = false
local stompTargetEnabled = false
local lastPosition = nil
local oldPosition = nil
local Core = nil
local BodyVelocity = nil
local hiddenBulletsEnabled = false
local spectateStrafeEnabled = false
local AutoAmmoEnabled = false
local strafeWasEnabledBeforeAmmoBuy = false

local knockCheek = false
local spawnProtectionCheck = false
local defenseMode = false

local BulletBeamEnabled = false
local BulletBeamBrightness = 1
local BulletBeamColor = Color3.fromRGB(255, 255, 255)
local BulletBeamTransparency = 0.5
local predictionEnabled = false
local predictionValue = 0 -- Default prediction value, adjustable via slider
local showPredictionTracer = true
local predictionTracerColor = Color3.fromRGB(255, 255, 0) -- Yellow for prediction line
local PredicTvalue = 0.01


local strafeRandomDistance = 8


-- Desync Configuration
local desync = {
    enabled = false,
    toggleEnabled = false,
    mode = "Void",
    old_position = CFrame.new(),
    teleportPosition = Vector3.new(),
    networkDesyncEnabled = false,
    fakePositionEnabled = false
}

local SafeModeConfig = {
    enabled = false,
    lastHealth = 100,
    damageThreshold = 5, -- Minimum damage to trigger desync
    autoDisableTime = 3, -- Time in seconds to keep desync enabled after damage
    currentTimer = 0
}
if not getgenv().resolverData then
    getgenv().resolverData = {}
end
local resolverData = getgenv().resolverData

-- Resolver Configuration (make sure this is defined)
local ResolverConfig = {
    Enabled = true,
    Mode = "Advanced", -- "Basic", "Advanced", "Predictive", "Adaptive"
    Sensitivity = 1.0,
    AntiAimDetection = true,
    DebugMode = false,
    AdaptiveThreshold = 0.6 -- Hit rate threshold for adaptive mode
}

-- Resolver data storage
local resolverData = {}

-- Auto Equip Configuration
local AutoEquipConfig = {
    Enabled = false,
    WeaponType = "Revolver" -- Default weapon
}

game:GetService("TextChatService").ChatWindowConfiguration.Enabled = true

local tracer = Drawing.new("Line")
tracer.Visible = false
tracer.BorderSizePixel = 1
tracer.BorderColor3 = Color3.fromRGB(0, 0, 0)
tracer.Thickness = 1
tracer.Color = Color3.fromRGB(255, 255, 255)

function predictPosition(targetRoot, predictionMultiplier)
    if not targetRoot then return targetRoot.Position end
    if targetRoot.Velocity.Magnitude > 700 then
        return targetRoot.Position
    end
    return targetRoot.Position + (targetRoot.Velocity * predictionMultiplier)
end

local function onBulletFired(bullet)
    if not BulletTPEnabled or not lockedTarget or not lockedTarget.Character then
        return
    end

    local targetPart = lockedTarget.Character:FindFirstChild(targetHitPart)
    if not targetPart then
        return
    end

    local predictedPosition = predictPosition(targetPart, predictionMultiplier)
    bullet.CFrame = CFrame.new(bullet.Position, predictedPosition)
    bullet.Velocity = (predictedPosition - bullet.Position).Unit * bullet.Velocity.Magnitude
end

local function checkHealthForSafeMode()
    if not SafeModeConfig.enabled then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local currentHealth = humanoid.Health
    local healthDifference = SafeModeConfig.lastHealth - currentHealth
    
    -- Check if player took significant damage
    if healthDifference >= SafeModeConfig.damageThreshold and currentHealth > 0 then
        -- Player took damage, enable desync
        desync.toggleEnabled = true
        SafeModeConfig.currentTimer = SafeModeConfig.autoDisableTime
        
        -- Optional: Print debug message
        if ResolverConfig.DebugMode then
            print("[Safe Mode] Damage detected! Desync enabled for " .. SafeModeConfig.autoDisableTime .. " seconds")
        end
    end
    
    SafeModeConfig.lastHealth = currentHealth
end

local function updateSafeModeTimer(deltaTime)
    if SafeModeConfig.currentTimer > 0 then
        SafeModeConfig.currentTimer = SafeModeConfig.currentTimer - deltaTime
        
        if SafeModeConfig.currentTimer <= 0 then
            -- Safe period over, disable desync
            if SafeModeConfig.enabled then
                desync.toggleEnabled = false
                if ResolverConfig.DebugMode then
                    print("[Safe Mode] Safe period over, desync disabled")
                end
            end
        end
    end
end

local SafeModeConnection
local SafeModeTimerConnection

LocalPlayer.CharacterAdded:Connect(function(character)
    if SafeModeConfig.enabled then
        -- Wait for humanoid to load
        character:WaitForChild("Humanoid")
        SafeModeConfig.lastHealth = character.Humanoid.Health
        SafeModeConfig.currentTimer = 0
        desync.toggleEnabled = false
    end
end)

-- Enhanced Auto Equip Configuration with Double Equip
AutoEquipConfig = {
    Enabled = false,
    WeaponType = "Revolver",
    DoubleEquipEnabled = false,
    PrimaryWeapon = "Revolver",
    SecondaryWeapon = "Glock"
}

maddieplsnomad = false

-- UI GROUPBOXES
local TargetingGroup = Tabs.Main:AddLeftGroupbox('Targeting')
local safe = Tabs.Main:AddLeftGroupbox('Safe')
local BulletGroup = Tabs.Main:AddLeftGroupbox('Bullet')
local Target = Tabs.Main:AddLeftGroupbox('Target')

-- =============================================================================
-- TOGGLES SECTION
-- =============================================================================

TargetingGroup:AddToggle("StickyAim", {
    Text = "Rage Aim",
    Default = false,
    Callback = function(Value)
        StickyAimEnabled = Value
        if not Value then
            lockedTarget = nil
            workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
            targetHighlight.Enabled = false
            tracer.Visible = false
        end
    end
}):AddKeyPicker("StickyAimKeybind", {
    Default = "C",
    NoUI = false,
    Text = "Rage Aim",
    Mode = "Toggle",
    Callback = function()
        if UserInputService:GetFocusedTextBox() then return end
        if lockedTarget then
            lockedTarget = nil
            workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
            targetHighlight.Enabled = false
            tracer.Visible = false
        if autoEquipTool then
            LocalPlayer.Character.Humanoid:UnequipTools()
        end
        else
            local camera = workspace.CurrentCamera
            local mouseLocation = UserInputService:GetMouseLocation()
            local closestTarget, closestDistance = nil, math.huge
            for _, otherPlayer in ipairs(Players:GetPlayers()) do
                if otherPlayer ~= LocalPlayer and otherPlayer.Character and otherPlayer.Character:FindFirstChild(targetHitPart) then
                    local bodyEffects = otherPlayer.Character:FindFirstChild("BodyEffects")
                    local isKO = bodyEffects and bodyEffects:FindFirstChild("K.O") and bodyEffects["K.O"].Value
                    local isGrabbed = otherPlayer.Character:FindFirstChild("GRABBING_CONSTRAINT")
                    if (not grabCheckEnabled or not isGrabbed) and
                       (not friendCheckEnabled or not LocalPlayer:IsFriendsWith(otherPlayer.UserId)) then
                        local targetPart = otherPlayer.Character[targetHitPart]
                        local screenPosition, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                        if onScreen then
                            local distance = (Vector2.new(screenPosition.X, screenPosition.Y) - mouseLocation).Magnitude
                            if distance < closestDistance then
                                closestTarget = otherPlayer
                                closestDistance = distance
                            end
                        end
                    end
                end
            end
            if closestTarget then
                lockedTarget = closestTarget
            end
        end
    end
})

TargetingGroup:AddToggle("look at", {
    Text = "Look At Target",
    Default = false,
    Callback = function(value)
        lookat = value
        if not value and getgenv().LookAtConnection then
            getgenv().LookAtConnection:Disconnect()
            getgenv().LookAtConnection = nil
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.AutoRotate = true
            end
        end
    end
})

TargetingGroup:AddToggle("prediction", {
    Text = "prediction",
    Default = false,
    Callback = function(value)
        predictionEnabled = value
    end
})

TargetingGroup:AddToggle("ViewTarget", {
    Text = "spectate",
    Default = false,
    Callback = function(Value)
        maddieplsnomad = Value
        if not Value then
            ViewTargetEnabled = false
            workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
        end
    end
}):AddKeyPicker("ViewTargetKeybind", {
    Default = "B",
    NoUI = false,
    Text = "spectate",
    Mode = "Toggle",
    Callback = function()
        if not maddieplsnomad or UserInputService:GetFocusedTextBox() then return end
        ViewTargetEnabled = not ViewTargetEnabled
        if ViewTargetEnabled and lockedTarget then
            workspace.CurrentCamera.CameraSubject = lockedTarget.Character
        else
            workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
        end
    end
})

TargetingGroup:AddToggle("StompTarget", {
    Text = "Stomp Target",
    Default = false,
    Callback = function(Value)
        stompTargetEnabled = Value
    end
})

TargetingGroup:AddToggle("KnockCheek", {
    Text = "Knock Check",
    Default = false,
    Callback = function(Value)
        knockCheek = Value
    end
})

TargetingGroup:AddToggle("SpawnProtectionCheck", {
    Text = "Spawn Protection Check",
    Default = false,
    Callback = function(Value)
        spawnProtectionCheck = Value
    end
})

TargetingGroup:AddToggle("HiddenBullets", {
    Text = "WallBang | Beta",
    Default = false,
    Callback = function(Value)
        hiddenBulletsEnabled = Value
    end
})

TargetingGroup:AddToggle("AutoAmmo", {
    Text = "Auto Ammo",
    Default = false,
    Callback = function(Value)
        AutoAmmoEnabled = Value
    end
})

TargetingGroup:AddToggle('AutoEquipEnabled', {
    Text = 'Auto Equip',
    Default = false,
    Callback = function(value)
        AutoEquipConfig.Enabled = value
    end
})

TargetingGroup:AddDropdown('AutoEquipWeapon', {
    Text = 'Primary Weapon',
    Values = {"Revolver", "Rifle", "LMG", "Shotgun", "SMG", "AK47", "AR", "Glock", "Silencer", "Flintlock"},
    Default = "Revolver",
    Callback = function(value)
        AutoEquipConfig.WeaponType = value
        AutoEquipConfig.PrimaryWeapon = value
    end
})



TargetingGroup:AddToggle('DoubleEquipEnabled', {
    Text = 'Double Equip Mode',
    Default = false,
    Callback = function(value)
        AutoEquipConfig.DoubleEquipEnabled = value
    end
})

TargetingGroup:AddDropdown('SecondaryWeapon', {
    Text = 'Secondary Weapon',
    Values = {"Revolver", "Rifle", "LMG", "Shotgun", "SMG", "AK47", "AR", "Glock", "Silencer", "Flintlock"},
    Default = "Glock",
    Callback = function(value)
        AutoEquipConfig.SecondaryWeapon = value
    end
})

safe:AddToggle("Safe Mode", {
    Text = "Safe Mode",
    Default = false,
    Callback = function(Value)
        SafeModeConfig.enabled = Value
        
        if Value then
            -- Initialize health tracking
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("Humanoid") then
                SafeModeConfig.lastHealth = character.Humanoid.Health
            end
            
            -- Connect health monitoring
            SafeModeConnection = RunService.Heartbeat:Connect(function()
                checkHealthForSafeMode()
            end)
            
            -- Connect timer for auto-disable
            SafeModeTimerConnection = RunService.Heartbeat:Connect(function(deltaTime)
                updateSafeModeTimer(deltaTime)
            end)
            
            if ResolverConfig.DebugMode then
                print("[Safe Mode] Enabled - Monitoring for damage")
            end
        else
            -- Disable safe mode
            if SafeModeConnection then
                SafeModeConnection:Disconnect()
                SafeModeConnection = nil
            end
            
            if SafeModeTimerConnection then
                SafeModeTimerConnection:Disconnect()
                SafeModeTimerConnection = nil
            end
            
            -- Reset desync if it was enabled by safe mode
            desync.enabled = false
            SafeModeConfig.currentTimer = 0
            
            if ResolverConfig.DebugMode then
                print("[Safe Mode] Disabled")
            end
        end
    end
})

BulletGroup:AddToggle("BulletBeam", {
    Text = "Custom Bullet Beam",
    Default = false,
    Callback = function(Value)
        game.ReplicatedStorage.GunBeam.Enabled = Value
    end
})

Target:AddToggle("StrafeToggle", {
    Text = "Target Strafe",
    Default = false,
    Callback = function(Value)
        strafeEnabled = Value
        if not Value then
            if Core then
                Core:Destroy()
                Core = nil
            end
            if BodyVelocity then
                BodyVelocity:Destroy()
                BodyVelocity = nil
            end
            if oldPosition then
                LocalPlayer.Character.HumanoidRootPart.CFrame = oldPosition
                oldPosition = nil
            end
            workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
        end
    end
}):AddKeyPicker("StrafeKeybind", {
    Default = "N",
    NoUI = false,
    Text = "Strafe",
    Mode = "Toggle",
    Callback = function()
        if UserInputService:GetFocusedTextBox() then return end
        strafeEnabled = not strafeEnabled

        if strafeEnabled then
            Library:Notify("Strafe Enabled ZestHub.lol $")
        else
            Library:Notify("Strafe Disabled ZestHub.lol $")
        end

        if not strafeEnabled then
            if Core then
                Core:Destroy()
                Core = nil
            end
            if BodyVelocity then
                BodyVelocity:Destroy()
                BodyVelocity = nil
            end
            if oldPosition then
                LocalPlayer.Character.HumanoidRootPart.CFrame = oldPosition
                oldPosition = nil
            end
            workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
        end
    end
})

Target:AddToggle("SpectateStrafe", {
    Text = "Spectate Strafe",
    Default = false,
    Callback = function(Value)
        spectateStrafeEnabled = Value
        if not Value then
            workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
        end
    end
})

Target:AddSlider("StrafeRandomDistance", {
    Text = "Random Distance",
    Default = 8,
    Min = 1,
    Max = 30,
    Rounding = 1,
    Callback = function(Value)
        strafeRandomDistance = Value
    end
})


Target:AddToggle("PredictMovement", {
    Text = "predict movement",
    Default = false,
    Callback = function(Value)
        predictMovementEnabled = Value
    end
})

-- =============================================================================
-- SLIDERS SECTION
-- =============================================================================

TargetingGroup:AddSlider("predictionValue", {
    Text = "predictionValue",
    Default = 0,
    Min = 0,
    Max = 20,
    Rounding = 2,
    Callback = function(Value)
        predictionValue = Value
    end
})

safe:AddSlider("SafeModeDamageThreshold", {
    Text = "Damage Threshold",
    Default = 5,
    Min = 1,
    Max = 50,
    Rounding = 1,
    Compact = false,
    Callback = function(Value)
        SafeModeConfig.damageThreshold = Value
    end
})

safe:AddSlider("SafeModeAutoDisableTime", {
    Text = "Auto Disable Time",
    Default = 3,
    Min = 1,
    Max = 10,
    Rounding = 1,
    Compact = false,
    Callback = function(Value)
        SafeModeConfig.autoDisableTime = Value
    end
})

BulletGroup:AddSlider("BulletBeamBrightness", {
    Text = "Brightness",
    Default = 1,
    Min = 0,    
    Max = 100,
    Rounding = 1,
    Callback = function(Value)
        game.ReplicatedStorage.GunBeam.Brightness = Value
    end
})

BulletGroup:AddSlider("BulletBeamWidth", {
    Text = "Width",
    Default = 1,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        game.ReplicatedStorage.GunBeam.Width1 = Value
    end
})

Target:AddSlider("StrafeSpeed", {
    Text = "Speed units",
    Default = 5,
    Min = 1,
    Max = 20,
    Rounding = 1,
    Callback = function(Value)
        strafeSpeed = Value
    end
})

Target:AddSlider("StrafeXOffset", {
    Text = "z offset",
    Default = 5,
    Min = 1,
    Max = 20,
    Rounding = 1,
    Callback = function(Value)
        strafeXOffset = Value
    end
})

Target:AddSlider("StrafePredictionDistance", {
    Text = "movement prediction",
    Default = 0.3,
    Min = 0.1,
    Max = 10,
    Rounding = 1,
    Callback = function(Value)
        PredicTvalue = Value
    end
})

-- =============================================================================
-- DROPDOWNS SECTION
-- =============================================================================

TargetingGroup:AddDropdown("hp", {
    Text = "Hit Part",
    Values = {"Head", "HumanoidRootPart", "UpperTorso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"},
    Default = "Head",
    Callback = function(Value)
        targetHitPart = Value
    end
})



Target:AddDropdown("StrafeMode", {
    Text = "Strafe Mode",
    Values = {"Orbit", "Random"},
    Default = "Orbit",
    Callback = function(Value)
        strafeMode = Value
    end
})

local function getCurrentGun()
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if tool then
        return tool.Name
    end
    return nil
end

local function getAllEquippedTools()
    local equippedTools = {}
    if LocalPlayer.Character then
        for _, child in pairs(LocalPlayer.Character:GetChildren()) do
            if child:IsA("Tool") then
                table.insert(equippedTools, child)
            end
        end
    end
    return equippedTools
end

local function getAmmoCount(gunName)
    local inventory = LocalPlayer.DataFolder.Inventory
    local ammo = inventory:FindFirstChild(gunName)
    if ammo then
        return tonumber(ammo.Value) or 0
    end
    return 0
end

local function buyAmmo(gunName)
    local ShopFolder = Workspace:WaitForChild("Ignored"):WaitForChild("Shop")
    local AmmoMap = {
        ["[Revolver]"] = "12 [Revolver Ammo] - $55",
        ["[AUG]"] = "90 [AUG Ammo] - $87",
        ["[LMG]"] = "200 [LMG Ammo] - $328",
        ["[Rifle]"] = "5 [Rifle Ammo] - $273",
        ["[Flintlock]"] = "6 [Flintlock Ammo] - $163"
    }

    local ammoItemName = AmmoMap[gunName]
    if not ammoItemName then return end

    local ammoItem = ShopFolder:FindFirstChild(ammoItemName)
    if not ammoItem then return end

    local oldPosition = LocalPlayer.Character.HumanoidRootPart.CFrame
    local currentTool = LocalPlayer.Character:FindFirstChildOfClass("Tool")

    if currentTool then
        currentTool.Parent = LocalPlayer.Backpack
    end

    LocalPlayer.Character.HumanoidRootPart.CFrame = ammoItem.Head.CFrame * CFrame.new(0, 3.2, 0)

    local clickDetector = ammoItem:FindFirstChild("ClickDetector")
    if clickDetector then
        for i = 1, 5 do
            fireclickdetector(clickDetector)
            task.wait(0)
        end
    end

    if currentTool then
        currentTool.Parent = LocalPlayer.Character
    end

    LocalPlayer.Character.HumanoidRootPart.CFrame = oldPosition
end

local function checkAmmoAndBuy()
    if not AutoAmmoEnabled then return end

    local gunName = getCurrentGun()
    if not gunName then return end

    local ammoCount = getAmmoCount(gunName)
    if ammoCount <= 0 then
        strafeWasEnabledBeforeAmmoBuy = strafeEnabled
        strafeEnabled = false
        if Core then
            Core:Destroy()
            Core = nil
        end
        if BodyVelocity then
            BodyVelocity:Destroy()
            BodyVelocity = nil
        end

        buyAmmo(gunName)

        if strafeWasEnabledBeforeAmmoBuy then
            strafeEnabled = true
        end
    end
end

-- Helper function to find weapon with alternative names
local function findWeaponInBackpack(weaponType)
    local backpack = LocalPlayer.Backpack
    if not backpack then return nil end
    
    -- Try exact name first
    local weapon = backpack:FindFirstChild(weaponType)
    if weapon then return weapon end
    
    -- Try alternative names for Da Hood weapons
    local alternativeNames = {
        ["Revolver"] = {"[Revolver]", "Revolver", "Rev"},
        ["Rifle"] = {"[Rifle]", "Rifle", "Sniper"},
        ["LMG"] = {"[LMG]", "LMG", "Machine Gun"},
        ["Shotgun"] = {"[Shotgun]", "Shotgun", "Double-Barrel SG"},
        ["SMG"] = {"[SMG]", "SMG", "Sub Machine Gun"},
        ["AK47"] = {"[AK47]", "AK47", "AK-47"},
        ["AR"] = {"[AR]", "AR", "Assault Rifle"},
        ["Glock"] = {"[Glock]", "Glock", "Pistol"},
        ["Silencer"] = {"[Silencer]", "Silencer", "Suppressed Pistol"},
        ["Flintlock"] = {"[Flintlock]"}
    }
    
    local alternatives = alternativeNames[weaponType]
    if alternatives then
        for _, altName in pairs(alternatives) do
            weapon = backpack:FindFirstChild(altName)
            if weapon then
                return weapon
            end
        end
    end
    
    return nil
end

-- Check if weapon is already equipped
local function isWeaponEquipped(weaponType)
    local character = LocalPlayer.Character
    if not character then return false end
    
    local alternativeNames = {
        ["Revolver"] = {"[Revolver]", "Revolver", "Rev"},
        ["Rifle"] = {"[Rifle]", "Rifle", "Sniper"},
        ["LMG"] = {"[LMG]", "LMG", "Machine Gun"},
        ["Shotgun"] = {"[Shotgun]", "Shotgun", "Double-Barrel SG"},
        ["SMG"] = {"[SMG]", "SMG", "Sub Machine Gun"},
        ["AK47"] = {"[AK47]", "AK47", "AK-47"},
        ["AR"] = {"[AR]", "AR", "Assault Rifle"},
        ["Glock"] = {"[Glock]", "Glock", "Pistol"},
        ["Silencer"] = {"[Silencer]", "Silencer", "Suppressed Pistol"},
        ["Flintlock"] = {"[Flintlock]"}
    }
    
    -- Check exact name first
    if character:FindFirstChild(weaponType) then
        return true
    end
    
    -- Check alternative names
    local alternatives = alternativeNames[weaponType]
    if alternatives then
        for _, altName in pairs(alternatives) do
            if character:FindFirstChild(altName) then
                return true
            end
        end
    end
    
    return false
end

-- Track the previous target state to detect changes
local previousTargetState = false
local hasUnequippedOnce = false

-- Enhanced Auto Equip Function with one-time unequip
local function autoEquipWeapon()
    if not AutoEquipConfig.Enabled then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local backpack = LocalPlayer.Backpack
    if not backpack then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- Check current target state
    local currentTargetState = (lockedTarget and lockedTarget.Character) and true or false
    
    -- Detect target state changes
    local targetJustLocked = currentTargetState and not previousTargetState
    local targetJustUnlocked = not currentTargetState and previousTargetState
    
    if currentTargetState then
        -- TARGET IS LOCKED - EQUIP WEAPON(S)
        hasUnequippedOnce = false -- Reset the unequip flag when target is locked
        
        if AutoEquipConfig.DoubleEquipEnabled then
            -- DOUBLE EQUIP MODE - Equip both primary and secondary
            
            local primaryEquipped = isWeaponEquipped(AutoEquipConfig.PrimaryWeapon)
            local secondaryEquipped = isWeaponEquipped(AutoEquipConfig.SecondaryWeapon)
            
            -- Equip primary weapon if not already equipped
            if not primaryEquipped then
                local primaryWeapon = findWeaponInBackpack(AutoEquipConfig.PrimaryWeapon)
                if primaryWeapon then
                    primaryWeapon.Parent = character
                    wait(0.1) -- Small delay between equips
                end
            end
            
            -- Equip secondary weapon if not already equipped
            if not secondaryEquipped then
                local secondaryWeapon = findWeaponInBackpack(AutoEquipConfig.SecondaryWeapon)
                if secondaryWeapon then
                    secondaryWeapon.Parent = character
                    wait(0.1)
                end
            end
            
        else
            -- SINGLE EQUIP MODE - Equip only primary weapon
            
            -- Check if already holding the desired weapon
            if isWeaponEquipped(AutoEquipConfig.WeaponType) then
                previousTargetState = currentTargetState
                return -- Already equipped the correct weapon
            end
            
            -- Look for the weapon in backpack
            local targetWeapon = findWeaponInBackpack(AutoEquipConfig.WeaponType)
            
            -- If weapon is found in backpack, equip it
            if targetWeapon then
                -- Unequip current tool first if holding one
                local currentTool = character:FindFirstChildOfClass("Tool")
                if currentTool then
                    currentTool.Parent = backpack
                    wait(0.1) -- Small delay to ensure unequipping completes
                end
                
                -- Equip the target weapon
                humanoid:EquipTool(targetWeapon)
                
                -- Alternative method if humanoid equip doesn't work
                if targetWeapon.Parent == backpack then
                    targetWeapon.Parent = character
                end
            end
        end
        
    elseif targetJustUnlocked and not hasUnequippedOnce then
        -- TARGET JUST UNLOCKED - UNEQUIP WEAPON(S) ONE TIME ONLY
        
        local weaponNames = {
            "[Revolver]", "Revolver", "Rev",
            "[Rifle]", "Rifle", "Sniper",
            "[LMG]", "LMG", "Machine Gun",
            "[Shotgun]", "Shotgun", "Double-Barrel SG",
            "[SMG]", "SMG", "Sub Machine Gun",
            "[AK47]", "AK47", "AK-47",
            "[AR]", "AR", "Assault Rifle",
            "[Glock]", "Glock", "Pistol",
            "[Silencer]", "Silencer", "Suppressed Pistol",
            "[Flintlock]", "Flintlock"
        }
        
        if AutoEquipConfig.DoubleEquipEnabled then
            -- DOUBLE EQUIP MODE - Unequip both weapons once
            
            for _, tool in pairs(character:GetChildren()) do
                if tool:IsA("Tool") then
                    for _, weaponName in pairs(weaponNames) do
                        if tool.Name == weaponName then
                            tool.Parent = backpack
                            wait(0.05) -- Small delay between unequips
                            break
                        end
                    end
                end
            end
            
        else
            -- SINGLE EQUIP MODE - Unequip single weapon once
            
            local currentTool = character:FindFirstChildOfClass("Tool")
            if currentTool then
                -- Check if the current tool is one of the weapons we auto-equip
                for _, weaponName in pairs(weaponNames) do
                    if currentTool.Name == weaponName then
                        currentTool.Parent = backpack
                        break
                    end
                end
            end
        end
        
        hasUnequippedOnce = true -- Mark that we've unequipped once
    end
    
    -- Update previous target state
    previousTargetState = currentTargetState
    
    return false -- Weapon not found or no action needed
end

-- Enhanced version with debug notifications (optional)
local function autoEquipWeaponWithDebug()
    if not AutoEquipConfig.Enabled then return end
    
    local character = LocalPlayer.Character
    if not character then 
        print("Auto Equip: No character found")
        return 
    end
    
    local backpack = LocalPlayer.Backpack
    if not backpack then 
        print("Auto Equip: No backpack found")
        return 
    end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then 
        print("Auto Equip: No humanoid found")
        return 
    end
    
    -- Check current target state
    local currentTargetState = (lockedTarget and lockedTarget.Character) and true or false
    
    -- Detect target state changes
    local targetJustLocked = currentTargetState and not previousTargetState
    local targetJustUnlocked = not currentTargetState and previousTargetState
    
    if currentTargetState then
        -- TARGET IS LOCKED - EQUIP WEAPON(S)
        hasUnequippedOnce = false -- Reset the unequip flag when target is locked
        
        if AutoEquipConfig.DoubleEquipEnabled then
            if targetJustLocked then
                print("Auto Equip: Target just locked - Double equip mode")
            end
            
            local primaryEquipped = isWeaponEquipped(AutoEquipConfig.PrimaryWeapon)
            local secondaryEquipped = isWeaponEquipped(AutoEquipConfig.SecondaryWeapon)
            
            -- Equip primary weapon if not already equipped
            if not primaryEquipped then
                local primaryWeapon = findWeaponInBackpack(AutoEquipConfig.PrimaryWeapon)
                if primaryWeapon then
                    print("Auto Equip: Equipping primary weapon: " .. primaryWeapon.Name)
                    primaryWeapon.Parent = character
                    wait(0.1)
                else
                    print("Auto Equip: Primary weapon not found in backpack")
                end
            end
            
            -- Equip secondary weapon if not already equipped
            if not secondaryEquipped then
                local secondaryWeapon = findWeaponInBackpack(AutoEquipConfig.SecondaryWeapon)
                if secondaryWeapon then
                    print("Auto Equip: Equipping secondary weapon: " .. secondaryWeapon.Name)
                    secondaryWeapon.Parent = character
                    wait(0.1)
                else
                    print("Auto Equip: Secondary weapon not found in backpack")
                end
            end
            
        else
            if targetJustLocked then
                print("Auto Equip: Target just locked - Single equip mode")
            end
            
            -- Check if already holding the desired weapon
            if isWeaponEquipped(AutoEquipConfig.WeaponType) then
                if targetJustLocked then
                    print("Auto Equip: Already holding " .. AutoEquipConfig.WeaponType)
                end
                previousTargetState = currentTargetState
                return -- Already equipped the correct weapon
            end
            
            -- Look for the weapon in backpack
            local targetWeapon = findWeaponInBackpack(AutoEquipConfig.WeaponType)
            
            -- If weapon is found, equip it
            if targetWeapon then
                print("Auto Equip: Equipping " .. targetWeapon.Name)
                
                -- Unequip current tool first if holding one
                local currentTool = character:FindFirstChildOfClass("Tool")
                if currentTool then
                    print("Auto Equip: Unequipping " .. currentTool.Name)
                    currentTool.Parent = backpack
                    wait(0.1)
                end
                
                -- Equip the target weapon
                humanoid:EquipTool(targetWeapon)
                
                -- Alternative method if humanoid equip doesn't work
                if targetWeapon.Parent == backpack then
                    targetWeapon.Parent = character
                end
                
                print("Auto Equip: Successfully equipped " .. targetWeapon.Name)
            else
                print("Auto Equip: Weapon " .. AutoEquipConfig.WeaponType .. " not found in backpack")
            end
        end
        
    elseif targetJustUnlocked and not hasUnequippedOnce then
        -- TARGET JUST UNLOCKED - UNEQUIP WEAPON(S) ONE TIME ONLY
        
        print("Auto Equip: Target just unlocked - Unequipping weapons once")
        
        local weaponNames = {
            "[Revolver]", "Revolver", "Rev",
            "[Rifle]", "Rifle", "Sniper",
            "[LMG]", "LMG", "Machine Gun",
            "[Shotgun]", "Shotgun", "Double-Barrel SG",
            "[SMG]", "SMG", "Sub Machine Gun",
            "[AK47]", "AK47", "AK-47",
            "[AR]", "AR", "Assault Rifle",
            "[Glock]", "Glock", "Pistol",
            "[Silencer]", "Silencer", "Suppressed Pistol",
            "[Flintlock]", "Flintlock"
        }
        
        if AutoEquipConfig.DoubleEquipEnabled then
            local weaponsUnequipped = 0
            for _, tool in pairs(character:GetChildren()) do
                if tool:IsA("Tool") then
                    for _, weaponName in pairs(weaponNames) do
                        if tool.Name == weaponName then
                            print("Auto Equip: Unequipping " .. tool.Name)
                            tool.Parent = backpack
                            weaponsUnequipped = weaponsUnequipped + 1
                            wait(0.05)
                            break
                        end
                    end
                end
            end
            print("Auto Equip: Unequipped " .. weaponsUnequipped .. " weapons")
            
        else
            local currentTool = character:FindFirstChildOfClass("Tool")
            if currentTool then
                -- Check if the current tool is one of the weapons we auto-equip
                for _, weaponName in pairs(weaponNames) do
                    if currentTool.Name == weaponName then
                        print("Auto Equip: Unequipping " .. currentTool.Name)
                        currentTool.Parent = backpack
                        break
                    end
                end
            end
        end
        
        hasUnequippedOnce = true -- Mark that we've unequipped once
        print("Auto Equip: Marked as unequipped once - won't auto-unequip again until next target lock")
    end
    
    -- Update previous target state
    previousTargetState = currentTargetState
    
    return false
end

-- Run the auto equip function in a loop
spawn(function()
    while wait(0.1) do -- Check every 0.1 seconds
        if AutoEquipConfig.Enabled then
            autoEquipWeapon()
        end
    end
end)

getgenv().hitsounds = {
    ["Bubble"] = "rbxassetid://6534947588",
    ["Lazer"] = "rbxassetid://130791043",
    ["Pick"] = "rbxassetid://1347140027",
    ["Pop"] = "rbxassetid://198598793",
    ["Rust"] = "rbxassetid://1255040462",
    ["Sans"] = "rbxassetid://3188795283",
    ["Fart"] = "rbxassetid://130833677",
    ["Big"] = "rbxassetid://5332005053",
    ["Vine"] = "rbxassetid://5332680810",
    ["UwU"] = "rbxassetid://8679659744",
    ["Bruh"] = "rbxassetid://4578740568",
    ["Skeet"] = "rbxassetid://5633695679",
    ["Neverlose"] = "rbxassetid://6534948092",
    ["Fatality"] = "rbxassetid://6534947869",
    ["Bonk"] = "rbxassetid://5766898159",
    ["Minecraft"] = "rbxassetid://5869422451",
    ["Gamesense"] = "rbxassetid://4817809188",
    ["RIFK7"] = "rbxassetid://9102080552",
    ["Bamboo"] = "rbxassetid://3769434519",
    ["Crowbar"] = "rbxassetid://546410481",
    ["Weeb"] = "rbxassetid://6442965016",
    ["Beep"] = "rbxassetid://8177256015",
    ["Bambi"] = "rbxassetid://8437203821",
    ["Stone"] = "rbxassetid://3581383408",
    ["Old Fatality"] = "rbxassetid://6607142036",
    ["Click"] = "rbxassetid://8053704437",
    ["Ding"] = "rbxassetid://7149516994",
    ["Snow"] = "rbxassetid://6455527632",
    ["Laser"] = "rbxassetid://7837461331",
    ["Mario"] = "rbxassetid://2815207981",
    ["Steve"] = "rbxassetid://4965083997",
    ["Call of Duty"] = "rbxassetid://5952120301",
    ["Bat"] = "rbxassetid://3333907347",
    ["TF2 Critical"] = "rbxassetid://296102734",
    ["Saber"] = "rbxassetid://8415678813",
    ["Baimware"] = "rbxassetid://3124331820",
    ["Osu"] = "rbxassetid://7149255551",
    ["TF2"] = "rbxassetid://2868331684",
    ["Slime"] = "rbxassetid://6916371803",
    ["Among Us"] = "rbxassetid://5700183626",
    ["One"] = "rbxassetid://7380502345"
}
getgenv().selectedHitsound = "Bubble"
getgenv().hitsoundEnabled = false
getgenv().hitsoundVolume = 1

function playHitsound()
    if getgenv().hitsoundEnabled then
        local sound = Instance.new("Sound")
        sound.SoundId = getgenv().hitsounds[getgenv().selectedHitsound]
        sound.Volume = getgenv().hitsoundVolume
        sound.Parent = workspace
        sound:Play()
        sound.Ended:Connect(function()
            sound:Destroy()
        end)
    end
end

GunMods:AddToggle('srtoggle', {
    Text = 'stretch res',
    Default = false,
    Callback = function(state)
	    	getgenv().hitsoundEnabled = state
    end
})

GunMods:AddSlider('stoggle', {
    Text = 'Stretch Res',
    Default = 1,
    Min = 0.2,
    Max = 1,
    Rounding = 1,
    Callback = function(value)
        getgenv().Resolution = {
            [" "] = value
        }
    end
})

GunMods:AddToggle('hstoggle', {
    Text = 'Hitsounds',
    Default = false,
    Callback = function(state)
	
	getgenv().Resolution = {
        [" "] = 1
}



local Camera = workspace.CurrentCamera
if getgenv().gg_scripters == nil then
    game:GetService("RunService").RenderStepped:Connect(
        function()
            Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, getgenv().Resolution[" "], 0, 0, 0, 1)
        end
    )
end
getgenv().gg_scripters = " "
    end
})

GunMods:AddDropdown('hs', {
    Text = 'Select Hitsound',
    Values = {"Bubble", "Lazer", "Pick", "Pop", "Gamesense", "Skeet", "Fart", "Big", "Vine", "UwU", "Bruh", "Skeet", "Neverlose", "Fatality", "Bonk", "Minecraft", "RIFK7", "Bamboo", "Crowbar", "Weeb", "Beep", "Bambi", "Stone", "Old Fatality", "Click", "Ding", "Snow", "Laser", "Mario", "Steve", "Call of Duty", "Bat", "TF2 Critical", "Saber", "Baimware", "Osu", "TF2", "Slime", "Among Us", "One"},
    Default = "Bubble",
    Callback = function(value)
        getgenv().selectedHitsound = value
    end
})

GunMods:AddSlider('hsvolume', {
    Text = 'Volume',
    Default = 1,
    Min = 1,
    Max = 5,
    Rounding = 2,
    Callback = function(value)
        getgenv().hitsoundVolume = value
    end
})


-- Enhanced Da Hood HvH Script - Supreme Combat System
-- Advanced targeting, prediction, and evasion for competitive HvH

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Global variables
getgenv().lastHealth = {}


-- Enhanced Billboard Damage Indicator Configuration
local DamageIndicatorConfig = {
    Enabled = true,
    Duration = 2.0,
    MaxSize = 28,
    MinSize = 14,
    FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
    CriticalDamageThreshold = 25,
    
    -- Enhanced Colors
    RegularColor = Color3.fromRGB(255, 255, 255),
    CriticalColor = Color3.fromRGB(255, 20, 20),
    HealColor = Color3.fromRGB(50, 255, 100),
    HeadshotColor = Color3.fromRGB(255, 215, 0), -- Gold for headshots
    
    -- Enhanced Animation
    RiseDistance = 8,
    RandomOffset = 3,
    PopScale = 1.5,
    
    -- Improved Physics
    Gravity = 0.15,
    InitialVelocity = {
        X = {Min = -2, Max = 2},
        Y = {Min = 4, Max = 7},
        Z = {Min = -2, Max = 2}
    }
}

-- Enhanced Hit Effect Configuration
local HitEffectConfig = {
    Enabled = true,
    Type = "Mark",
    Scale = 1.2,
    
    Effects = {
        Mark = {
            Texture = "rbxassetid://446111271",
            Lifetime = 1.5,
            StartSize = 2.5,
            EndSize = 0.3,
            StartTransparency = 0,
            EndTransparency = 1,
            Color = Color3.fromRGB(255, 0, 0),
            ZOffset = 0.25
        },
        Splat = {
            Texture = "rbxassetid://2008463015",
            Lifetime = 2.0,
            StartSize = 3.0,
            EndSize = 2.5,
            StartTransparency = 0,
            EndTransparency = 1,
            Color = Color3.fromRGB(200, 0, 0),
            ZOffset = 0.25
        },
        Spark = {
            Texture = "rbxassetid://5208651835",
            Lifetime = 1.2,
            StartSize = 2.0,
            EndSize = 0.1,
            StartTransparency = 0,
            EndTransparency = 1,
            Color = Color3.fromRGB(255, 255, 150),
            ZOffset = 0.25
        },
        Ring = {
            Texture = "rbxassetid://3270017025",
            Lifetime = 1.0,
            StartSize = 0.2,
            EndSize = 5.0,
            StartTransparency = 0,
            EndTransparency = 1,
            Color = Color3.fromRGB(255, 100, 100),
            ZOffset = 0.25
        },
        Ripple = {
            Texture = "rbxassetid://2092248396",
            Lifetime = 1.5,
            StartSize = 6.0,
            EndSize = 25.0,
            StartTransparency = 0,
            EndTransparency = 1,
            Color = Color3.fromRGB(255, 150, 150),
            ZOffset = 0.25
        }
    }
}

-- Enhanced Visual Target Strafe Configuration
local VisualTargetStrafeConfig = {
    Enabled = false,
    OrbitSpeed = 2.5,
    OrbitDistance = 12,
    OrbitHeight = 1,
    CloneTransparency = 0.3,
    ReturnOnKO = true
}

-- Create enhanced containers
local DamageIndicators = Instance.new("Folder")
DamageIndicators.Name = "DamageIndicators"
DamageIndicators.Parent = game.CoreGui

local HitEffects = Instance.new("Folder")
HitEffects.Name = "HitEffects"
HitEffects.Parent = game.CoreGui

-- Enhanced variables
local playerClone = nil
local originalCharacter = nil
local cloneHumanoid = nil
local visualTargetStrafeActive = false
local visualTargetStrafeConnection = nil
local defenseTarget = nil
local defenseConnection = nil
local lastPlayerHealth = nil

-- Create enhanced tracer
local tracer = Drawing.new("Line")
tracer.Visible = false
tracer.Color = Color3.fromRGB(255, 0, 100)
tracer.Thickness = 2
tracer.Transparency = 0.8

-- Enhanced damage indicator with better animations and effects
local function createDamageIndicator(character, damageAmount, isHeadshot)
    if not DamageIndicatorConfig.Enabled or not character or damageAmount == 0 then return end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "DamageIndicator"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 120, 0, 50)
    billboard.StudsOffset = Vector3.new(
        math.random(-DamageIndicatorConfig.RandomOffset, DamageIndicatorConfig.RandomOffset),
        3.5,
        math.random(-DamageIndicatorConfig.RandomOffset, DamageIndicatorConfig.RandomOffset)
    )
    billboard.LightInfluence = 0
    billboard.MaxDistance = 100000
    billboard.Adornee = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
    billboard.Parent = DamageIndicators
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "DamageText"
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Text = tostring(math.abs(math.floor(damageAmount)))
    textLabel.FontFace = DamageIndicatorConfig.FontFace
    textLabel.TextSize = DamageIndicatorConfig.MaxSize
    textLabel.TextStrokeTransparency = 0.1
    textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    textLabel.Parent = billboard
    
    -- Enhanced color determination
    if damageAmount < 0 then
        textLabel.TextColor3 = DamageIndicatorConfig.HealColor
        textLabel.Text = "+" .. textLabel.Text
    elseif isHeadshot then
        textLabel.TextColor3 = DamageIndicatorConfig.HeadshotColor
        textLabel.TextSize = DamageIndicatorConfig.MaxSize * 1.4
        textLabel.Text = "💀 " .. textLabel.Text
    elseif damageAmount >= DamageIndicatorConfig.CriticalDamageThreshold then
        textLabel.TextColor3 = DamageIndicatorConfig.CriticalColor
        textLabel.TextSize = DamageIndicatorConfig.MaxSize * 1.3
        textLabel.Text = "⚡ " .. textLabel.Text
    else
        textLabel.TextColor3 = DamageIndicatorConfig.RegularColor
    end
    
    -- Enhanced shadow with glow effect
    local shadowText = textLabel:Clone()
    shadowText.Name = "ShadowText"
    shadowText.TextColor3 = Color3.new(0, 0, 0)
    shadowText.TextTransparency = 0.3
    shadowText.TextStrokeTransparency = 1
    shadowText.ZIndex = 1
    shadowText.Position = UDim2.new(0, 3, 0, 3)
    shadowText.Parent = billboard
    
    -- Enhanced animation system
    local startTime = tick()
    local initialScale = DamageIndicatorConfig.PopScale
    local velocity = Vector3.new(
        math.random(DamageIndicatorConfig.InitialVelocity.X.Min, DamageIndicatorConfig.InitialVelocity.X.Max),
        math.random(DamageIndicatorConfig.InitialVelocity.Y.Min, DamageIndicatorConfig.InitialVelocity.Y.Max),
        math.random(DamageIndicatorConfig.InitialVelocity.Z.Min, DamageIndicatorConfig.InitialVelocity.Z.Max)
    )
    local initialOffset = billboard.StudsOffset
    
    textLabel.TextSize = DamageIndicatorConfig.MaxSize * initialScale
    shadowText.TextSize = textLabel.TextSize
    
    local connection
    connection = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        local alpha = math.clamp(elapsed / DamageIndicatorConfig.Duration, 0, 1)
        
        velocity = Vector3.new(
            velocity.X * 0.98,
            velocity.Y - DamageIndicatorConfig.Gravity,
            velocity.Z * 0.98
        )
        
        local newOffset = initialOffset + velocity * (elapsed * 0.6)
        billboard.StudsOffset = newOffset
        
        if alpha < 0.2 then
            local scaleAlpha = alpha / 0.2
            local currentScale = initialScale * (1 - scaleAlpha) + 1 * scaleAlpha
            textLabel.TextSize = DamageIndicatorConfig.MaxSize * currentScale
            shadowText.TextSize = textLabel.TextSize
            textLabel.TextTransparency = 0
            shadowText.TextTransparency = 0.3
        elseif alpha < 0.6 then
            textLabel.TextSize = DamageIndicatorConfig.MaxSize
            shadowText.TextSize = textLabel.TextSize
            textLabel.TextTransparency = 0
            shadowText.TextTransparency = 0.3
        else
            local fadeAlpha = (alpha - 0.6) / 0.4
            local sizeAlpha = math.min(1, fadeAlpha * 2)
            textLabel.TextSize = DamageIndicatorConfig.MaxSize * (1 - sizeAlpha) + DamageIndicatorConfig.MinSize * sizeAlpha
            shadowText.TextSize = textLabel.TextSize
            textLabel.TextTransparency = fadeAlpha
            shadowText.TextTransparency = 0.3 + (fadeAlpha * 0.7)
        end
        
        if alpha >= 1 then
            connection:Disconnect()
            billboard:Destroy()
        end
    end)
end


-- Enhanced defense mode with better targeting
local function startDefenseMode(attacker)
    if not attacker or not attacker.Character then return end
    
    defenseTarget = attacker
    print("🛡️ Defense mode activated! Targeting: " .. attacker.Name)
    
    if defenseConnection then
        defenseConnection:Disconnect()
    end
    
    defenseConnection = RunService.RenderStepped:Connect(function()
        if not defenseTarget or not defenseTarget.Character or not defenseTarget.Character:FindFirstChild("HumanoidRootPart") then
            stopDefenseMode()
            return
        end
        
        local targetRoot = defenseTarget.Character.HumanoidRootPart
        local playerRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        if not playerRoot then return end
        
        -- Enhanced orbital movement with unpredictable patterns
        local time = tick()
        local angle = time * 4 + math.sin(time * 2) * 0.5
        local orbitDistance = 12 + math.sin(time * 3) * 3
        local height = 2 + math.cos(time * 1.5) * 1
        
        local offset = Vector3.new(
            math.cos(angle) * orbitDistance,
            height,
            math.sin(angle) * orbitDistance
        )
        
        playerRoot.CFrame = CFrame.new(targetRoot.Position + offset, targetRoot.Position)
        
        -- Enhanced shooting with prediction
        local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool and tool:FindFirstChild("Handle") then
            local targetPart = defenseTarget.Character:FindFirstChild("Head") or defenseTarget.Character:FindFirstChild("HumanoidRootPart")
            if targetPart then
                -- Predict target movement
                local targetVelocity = targetRoot.Velocity
                local predictedPosition = targetPart.Position + (targetVelocity * 0.2)
                
                for i = 1, 8 do
                    ReplicatedStorage.MainEvent:FireServer(
                        "ShootGun",
                        tool.Handle,
                        tool.Handle.Position,
                        predictedPosition,
                        targetPart,
                        (predictedPosition - tool.Handle.Position).Unit
                    )
                end
            end
        end
        
        -- Check if target is eliminated
        local bodyEffects = defenseTarget.Character:FindFirstChild("BodyEffects")
        if bodyEffects then
            local isKO = bodyEffects:FindFirstChild("K.O") and bodyEffects["K.O"].Value
            local humanoid = defenseTarget.Character:FindFirstChild("Humanoid")
            
            if isKO or (humanoid and humanoid.Health <= 0) then
                print("✅ Target eliminated! Defense mode deactivated.")
                stopDefenseMode()
            end
        end
    end)
end

local function stopDefenseMode()
    defenseTarget = nil
    if defenseConnection or defenseMode then
        defenseConnection:Disconnect()
        defenseConnection = nil
    end
end

-- Enhanced damage detection with attacker identification
local function detectDamageAndAttacker()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Humanoid") then return end
    
    local humanoid = LocalPlayer.Character.Humanoid
    local currentHealth = humanoid.Health
    
    if not lastPlayerHealth then
        lastPlayerHealth = currentHealth
        return
    end
    
    if currentHealth < lastPlayerHealth then
        local damageTaken = lastPlayerHealth - currentHealth
        print("🩸 Took " .. damageTaken .. " damage!")
        
        -- Enhanced attacker detection
        local closestAttacker = nil
        local closestDistance = math.huge
        local currentTime = tick()
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local distance = (player.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                
                if distance < 120 and distance < closestDistance then
                    local tool = player.Character:FindFirstChildOfClass("Tool")
                    local bodyEffects = player.Character:FindFirstChild("BodyEffects")
                    local isKO = bodyEffects and bodyEffects:FindFirstChild("K.O") and bodyEffects["K.O"].Value
                    
                    if tool and not isKO then
                        closestDistance = distance
                        closestAttacker = player
                    end
                end
            end
        end
        
        if closestAttacker and defenseMode then
            startDefenseMode(closestAttacker)
        end
    end
    
    lastPlayerHealth = currentHealth
end

local function predictPosition1(targetRoot, predictionTime)
    if not targetRoot then return Vector3.new() end
    
    local velocity = targetRoot.Velocity
    local currentPos = targetRoot.Position
    
    -- Da Hood specific movement threshold (players move at ~16 walkspeed)
    local isMoving = velocity.Magnitude > 3 -- Da Hood movement threshold
    
    if not isMoving then
        -- If not moving, return current position (no prediction needed)
        return currentPos
    end
    
    -- Da Hood players don't fall much due to spawn mechanics, minimal gravity
    local acceleration = Vector3.new(0, 0, 0)
    if velocity.Y < -10 then -- Only apply gravity if actually falling fast
        acceleration = Vector3.new(0, -workspace.Gravity * 0.2, 0) -- Minimal gravity for Da Hood
    end
    
    -- Reduced prediction for Da Hood's faster movement
    local predictedVelocity = velocity + (acceleration * predictionTime * 0.04)
    
    return currentPos + (predictedVelocity * predictionTime)
end

-- DA HOOD OPTIMIZED: Enhanced prediction system with proper movement detection
local function predictPosition1(targetRoot, predictionTime)
    if not targetRoot then return Vector3.new() end
    
    local velocity = targetRoot.Velocity
    local currentPos = targetRoot.Position
    
    -- Da Hood specific movement threshold (players move at ~16 walkspeed)
    local isMoving = velocity.Magnitude > 3 -- Da Hood movement threshold
    
    if not isMoving then
        -- If not moving, return current position (no prediction needed)
        return currentPos
    end
    
    -- Da Hood players don't fall much due to spawn mechanics, minimal gravity
    local acceleration = Vector3.new(0, 0, 0)
    if velocity.Y < -10 then -- Only apply gravity if actually falling fast
        acceleration = Vector3.new(0, -workspace.Gravity * 0.2, 0) -- Minimal gravity for Da Hood
    end
    
    -- Reduced prediction for Da Hood's faster movement
    local predictedVelocity = velocity + (acceleration * predictionTime * 0.04)
    
    return currentPos + (predictedVelocity * predictionTime)
end

-- DA HOOD OPTIMIZED: Wall check specifically for Da Hood map structures
local function checkIfBehindWall(playerPosition, targetPosition)
    local rayDirection = (targetPosition - playerPosition).Unit
    local rayDistance = (targetPosition - playerPosition).Magnitude
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    -- Da Hood specific filtering - exclude all players and their accessories
    local filterInstances = {}
    
    -- Add all players and their stuff to filter
    for _, player in pairs(game.Players:GetPlayers()) do
        if player.Character then
            table.insert(filterInstances, player.Character)
        end
    end
    
    -- Da Hood specific: Filter out common non-wall objects
    for _, obj in pairs(workspace:GetChildren()) do
        -- Filter out dropped items, tools, cash, etc.
        if obj.Name == "Ignored" or 
           obj.Name == "Filter" or
           obj.Name:find("Cash") or
           obj.Name:find("Tool") or
           obj.Name:find("Handle") or
           obj:IsA("Tool") or
           obj:IsA("Hat") or
           obj:IsA("Accessory") then
            table.insert(filterInstances, obj)
        elseif obj:IsA("Part") then
            -- Filter out small objects that aren't walls
            local size = obj.Size
            if size.X < 4 and size.Y < 4 and size.Z < 4 then
                table.insert(filterInstances, obj)
            end
        end
    end
    
    rayParams.FilterDescendantsInstances = filterInstances
    
    -- Cast ray to check for walls
    local rayResult = workspace:Raycast(playerPosition, rayDirection * rayDistance, rayParams)
    
    if rayResult then
        local hitPart = rayResult.Instance
        
        if hitPart and hitPart.Parent then
            -- Da Hood specific wall detection
            local partSize = hitPart.Size
            local partName = hitPart.Name:lower()
            local parentName = hitPart.Parent.Name:lower()
            
            -- Check if it's a Da Hood building/wall
            local isDaHoodWall = false
            
            -- Size-based detection (Da Hood buildings are generally large)
            if partSize.Magnitude > 15 then
                isDaHoodWall = true
            end
            
            -- Material-based detection (Da Hood uses these materials for buildings)
            if hitPart.Material == Enum.Material.Concrete or 
               hitPart.Material == Enum.Material.Brick or
               hitPart.Material == Enum.Material.Cobblestone or
               hitPart.Material == Enum.Material.Asphalt or
               hitPart.Material == Enum.Material.Pavement then
                isDaHoodWall = true
            end
            
            -- Name-based detection (Da Hood building parts)
            if partName:find("wall") or 
               partName:find("building") or
               partName:find("house") or
               partName:find("store") or
               partName:find("shop") or
               partName:find("apartment") or
               partName:find("hood") or
               parentName:find("building") or
               parentName:find("house") or
               parentName:find("store") then
                isDaHoodWall = true
            end
            
            -- Da Hood specific: Check if part is anchored (buildings are anchored)
            if hitPart.Anchored and partSize.Magnitude > 10 then
                isDaHoodWall = true
            end
            
            return isDaHoodWall
        end
    end
    
    return false
end

-- Placeholder functions (need to be defined elsewhere in your script)
local function playHitsound() end
local function checkAmmoAndBuy() end

-- Initialize last health and K.O tracking
if not getgenv().lastHealth then
    getgenv().lastHealth = {}
end
if not getgenv().lastKOStatus then
    getgenv().lastKOStatus = {}
end

-- Fake Body System Variables
local fakeBodyEnabled = false
local realBody = nil
local fakeBody = nil
local fakeBodyConnection = nil

-- Create prediction tracer
local predictionTracer = Drawing.new("Line")
predictionTracer.Thickness = 2
predictionTracer.Color = predictionTracerColor
predictionTracer.BorderSizePixel = 1
predictionTracer.BorderColor3 = Color3.fromRGB(0, 0, 0)
predictionTracer.Transparency = 0.8
predictionTracer.Visible = false

-- Create Fake Body System
local function createFakeBody()
    if fakeBody then
        destroyFakeBody()
    end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    -- Store real body reference
    realBody = character
    
    -- Create fake body
    fakeBody = Instance.new("Model")
    fakeBody.Name = LocalPlayer.Name .. "_Fake"
    fakeBody.Parent = workspace
    
    -- Clone all parts from real body to fake body
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") or part:IsA("Accessory") or part:IsA("Tool") then
            local clonedPart = part:Clone()
            clonedPart.Parent = fakeBody
            
            -- Make fake body transparent
            if clonedPart:IsA("BasePart") then
                clonedPart.Transparency = 1
                clonedPart.CanCollide = false
            elseif clonedPart:IsA("Accessory") and clonedPart:FindFirstChild("Handle") then
                clonedPart.Handle.Transparency = 1
                clonedPart.Handle.CanCollide = false
            end
        elseif part:IsA("Humanoid") then
            -- Clone humanoid for fake body
            local fakeHumanoid = part:Clone()
            fakeHumanoid.Parent = fakeBody
            fakeHumanoid.PlatformStand = true
        end
    end
    
    -- Set camera to fake body
    local fakeHumanoid = fakeBody:FindFirstChild("Humanoid")
    if fakeHumanoid then
        Camera.CameraSubject = fakeHumanoid
    end
    
    -- Make real body invisible but keep collision for shooting
    for _, part in pairs(realBody:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.Transparency = 1
        elseif part:IsA("Accessory") and part:FindFirstChild("Handle") then
            part.Handle.Transparency = 1
        end
    end
    
    -- Keep real body's HumanoidRootPart semi-transparent for reference
    if realBody:FindFirstChild("HumanoidRootPart") then
        realBody.HumanoidRootPart.Transparency = 0.9
    end
end

local function destroyFakeBody()
    if fakeBody then
        fakeBody:Destroy()
        fakeBody = nil
    end
    
    if realBody then
        -- Restore real body visibility
        for _, part in pairs(realBody:GetChildren()) do
            if part:IsA("BasePart") then
                part.Transparency = 0
            elseif part:IsA("Accessory") and part:FindFirstChild("Handle") then
                part.Handle.Transparency = 0
            end
        end
        
        -- Restore camera to real body
        local realHumanoid = realBody:FindFirstChild("Humanoid")
        if realHumanoid then
            Camera.CameraSubject = realHumanoid
        end
    end
    
    realBody = nil
end

local function updateFakeBodyPosition()
    if not fakeBody or not realBody then return end
    
    local fakeRoot = fakeBody:FindFirstChild("HumanoidRootPart")
    local realRoot = realBody:FindFirstChild("HumanoidRootPart")
    
    if fakeRoot and realRoot then
        -- Keep fake body at a safe position (underground or far away)
        fakeRoot.CFrame = CFrame.new(realRoot.Position + Vector3.new(0, -50, 0))
    end
end

local function calculatePrediction(targetRoot, predictionTime)
    if not targetRoot then return targetRoot and targetRoot.Position or Vector3.new() end
    
    local velocity = targetRoot.Velocity
    local isMoving = velocity.Magnitude > 2.5 -- Da Hood movement threshold
    
    -- If not moving, return current position
    if not isMoving then
        return targetRoot.Position
    end
    
    -- Get base prediction optimized for Da Hood
    local basePrediction = predictPosition1(targetRoot, predictionTime or predictionValue or 0.04)
    
    -- Apply resolver if enabled (optimized for Da Hood anti-aim)
    if ResolverConfig and ResolverConfig.Enabled then
        local character = targetRoot.Parent
        local player = Players:GetPlayerFromCharacter(character)
        
        if player then
            -- Initialize resolver data
            if initializeResolverData then
                initializeResolverData(player)
            end
            
            -- Detect anti-aim patterns (common in Da Hood)
            if ResolverConfig.AntiAimDetection and detectAntiAim then
                detectAntiAim(player)
            end
            
            -- Apply resolver offset (optimized for Da Hood)
            if calculateResolverOffset then
                local resolverOffset = calculateResolverOffset(player, targetRoot)
                basePrediction = basePrediction + (resolverOffset * 0.3) -- Reduced for Da Hood
            end
            
            -- Debug information
            if ResolverConfig.DebugMode then
                local data = resolverData[player.Name]
                if data then
                    print(string.format("Da Hood Resolver: %s | Pattern: %s | Moving: %s", 
                        player.Name, 
                        data.movementPattern or "Unknown", 
                        tostring(isMoving)
                    ))
                end
            end
        end
    end
    
    return basePrediction
end

local function getTargetPosition(targetCharacter, targetPart)
    local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return targetPart.Position end
    
    -- Check if prediction should be applied
    if predictionEnabled then
        local velocity = targetRoot.Velocity
        local isMoving = velocity.Magnitude > 2.5 -- Da Hood optimized threshold
        
        if isMoving then
            -- Da Hood optimized prediction time
            local predTime = predictionValue or PredicTvalue or 0.04
            local predictedRootPosition = calculatePrediction(targetRoot, predTime)
            
            -- Calculate offset from root to target part
            local offset = targetPart.Position - targetRoot.Position
            return predictedRootPosition + offset
        end
    end
    
    -- Return current position if not moving or prediction disabled
    return targetPart.Position
end


local function checkWallForShooting(playerPosition, targetPosition)
    local rayDirection = (targetPosition - playerPosition).Unit
    local rayDistance = (targetPosition - playerPosition).Magnitude
    
    -- Create precise ray parameters for Da Hood shooting
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    -- Only filter out characters and their accessories
    local filterInstances = {}
    for _, player in pairs(game.Players:GetPlayers()) do
        if player.Character then
            table.insert(filterInstances, player.Character)
        end
    end
    
    -- Da Hood: Also filter out cash, dropped items
    for _, obj in pairs(workspace:GetChildren()) do
        if obj.Name:find("Cash") or obj.Name:find("MoneyPrinter") or obj:IsA("Tool") then
            table.insert(filterInstances, obj)
        end
    end
    
    rayParams.FilterDescendantsInstances = filterInstances
    
    -- Single precise ray for Da Hood shooting
    local rayResult = workspace:Raycast(playerPosition, rayDirection * rayDistance, rayParams)
    
    if rayResult then
        local hitPart = rayResult.Instance
        
        -- Check if the hit part is a significant obstacle in Da Hood
        if hitPart and hitPart.CanCollide then
            local partSize = hitPart.Size
            local partName = hitPart.Name:lower()
            
            -- Da Hood specific wall detection for shooting
            local isShootingObstacle = false
            
            -- Large objects are definitely walls
            if partSize.Magnitude > 12 then
                isShootingObstacle = true
            end
            
            -- Da Hood building materials
            if hitPart.Material == Enum.Material.Concrete or
               hitPart.Material == Enum.Material.Brick or
               hitPart.Material == Enum.Material.Cobblestone then
                isShootingObstacle = true
            end
            
            -- Da Hood building names
            if partName:find("building") or 
               partName:find("wall") or 
               partName:find("house") or
               partName:find("store") or
               hitPart.Parent.Name:lower():find("building") then
                isShootingObstacle = true
            end
            
            -- Anchored large parts in Da Hood are usually buildings
            if hitPart.Anchored and partSize.Magnitude > 8 and hitPart.Transparency < 0.8 then
                isShootingObstacle = true
            end
            
            return isShootingObstacle
        end
    end
    
    return false
end



-- Initialize resolver data for players
local function initializeResolverData(player)
    if not resolverData[player.Name] then
        resolverData[player.Name] = {
            lastPositions = {},
            velocityHistory = {},
            movementPattern = "Normal",
            antiAimDetected = false,
            lastResolveTime = 0,
            missCount = 0,
            hitCount = 0,
            adaptiveMode = "Standard",
            predictedOffset = Vector3.new(),
            desyncAmount = 0
        }
    end
end

-- Detect anti-aim patterns
local function detectAntiAim(player)
    local data = resolverData[player.Name]
    if not data then return false end
    
    local character = player.Character
    if not character then return false end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end
    
    -- Store position history
    table.insert(data.lastPositions, {
        position = humanoidRootPart.Position,
        time = tick(),
        velocity = humanoidRootPart.Velocity
    })
    
    -- Keep only last 10 positions
    if #data.lastPositions > 10 then
        table.remove(data.lastPositions, 1)
    end
    
    -- Analyze movement patterns
    if #data.lastPositions >= 5 then
        local velocityChanges = 0
        local rapidDirectionChanges = 0
        
        for i = 2, #data.lastPositions do
            local current = data.lastPositions[i]
            local previous = data.lastPositions[i - 1]
            
            -- Check for rapid velocity changes (anti-aim indicator)
            local velocityDiff = (current.velocity - previous.velocity).Magnitude
            if velocityDiff > 50 then -- Threshold for rapid change
                velocityChanges = velocityChanges + 1
            end
            
            -- Check for direction changes
            if i >= 3 then
                local prevPrev = data.lastPositions[i - 2]
                local dir1 = (current.position - previous.position).Unit
                local dir2 = (previous.position - prevPrev.position).Unit
                
                local dot = dir1:Dot(dir2)
                if dot < -0.5 then -- Sharp direction change
                    rapidDirectionChanges = rapidDirectionChanges + 1
                end
            end
        end
        
        -- Determine if anti-aim is detected
        data.antiAimDetected = (velocityChanges >= 3 or rapidDirectionChanges >= 2)
        
        if data.antiAimDetected then
            data.movementPattern = "AntiAim"
        elseif velocityChanges >= 2 then
            data.movementPattern = "Evasive"
        else
            data.movementPattern = "Normal"
        end
    end
    
    return data.antiAimDetected
end

-- Calculate resolver offset based on movement pattern
local function calculateResolverOffset(player, targetPart)
    local data = resolverData[player.Name]
    if not data then return Vector3.new() end
    
    local character = player.Character
    if not character then return Vector3.new() end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return Vector3.new() end
    
    local currentVelocity = humanoidRootPart.Velocity
    local currentTime = tick()
    
    -- Basic resolver - simple velocity prediction
    if ResolverConfig.Mode == "Basic" then
        local predictionTime = 0.1 + (ResolverConfig.Sensitivity * 0.1)
        return currentVelocity * predictionTime
    
    -- Advanced resolver - pattern-based prediction
    elseif ResolverConfig.Mode == "Advanced" then
        if data.movementPattern == "AntiAim" then
            -- For anti-aim, try to resolve to center mass
            local offset = Vector3.new()
            
            -- Calculate desync amount
            if #data.lastPositions >= 3 then
                local recent = data.lastPositions[#data.lastPositions]
                local older = data.lastPositions[#data.lastPositions - 2]
                local velocityPattern = recent.velocity - older.velocity
                
                -- Counter anti-aim by predicting opposite movement
                offset = -velocityPattern * 0.3 * ResolverConfig.Sensitivity
            end
            
            return offset
            
        elseif data.movementPattern == "Evasive" then
            -- For evasive movement, predict based on velocity history
            local avgVelocity = Vector3.new()
            local count = 0
            
            for i = math.max(1, #data.lastPositions - 3), #data.lastPositions do
                if data.lastPositions[i] then
                    avgVelocity = avgVelocity + data.lastPositions[i].velocity
                    count = count + 1
                end
            end
            
            if count > 0 then
                avgVelocity = avgVelocity / count
                return avgVelocity * 0.15 * ResolverConfig.Sensitivity
            end
        end
        
        -- Default to velocity prediction
        return currentVelocity * 0.1 * ResolverConfig.Sensitivity
    
    -- Predictive resolver - advanced prediction with acceleration
    elseif ResolverConfig.Mode == "Predictive" then
        if #data.lastPositions >= 3 then
            local current = data.lastPositions[#data.lastPositions]
            local previous = data.lastPositions[#data.lastPositions - 1]
            
            -- Calculate acceleration
            local acceleration = (current.velocity - previous.velocity) / math.max(current.time - previous.time, 0.01)
            
            -- Predict future position with acceleration
            local predictionTime = 0.1 + (ResolverConfig.Sensitivity * 0.1)
            local predictedVelocity = currentVelocity + (acceleration * predictionTime)
            local predictedOffset = predictedVelocity * predictionTime
            
            -- Apply anti-aim counter if detected
            if data.antiAimDetected then
                -- Try to resolve jitter by averaging recent positions
                local avgPosition = Vector3.new()
                local recentCount = math.min(3, #data.lastPositions)
                
                for i = #data.lastPositions - recentCount + 1, #data.lastPositions do
                    avgPosition = avgPosition + data.lastPositions[i].position
                end
                avgPosition = avgPosition / recentCount
                
                -- Offset towards average position
                local currentPos = humanoidRootPart.Position
                local centerOffset = (avgPosition - currentPos) * 0.5 * ResolverConfig.Sensitivity
                
                return predictedOffset + centerOffset
            end
            
            return predictedOffset
        end
    
    -- Adaptive resolver - switches methods based on performance
    elseif ResolverConfig.Mode == "Adaptive" then
        -- Track hit/miss ratio to adapt resolver method
        local hitRate = data.hitCount / math.max(1, data.hitCount + data.missCount)
        
        -- Switch resolver method based on performance
        if hitRate < ResolverConfig.AdaptiveThreshold then
            if data.adaptiveMode == "Standard" then
                data.adaptiveMode = "AntiAim"
            elseif data.adaptiveMode == "AntiAim" then
                data.adaptiveMode = "Predictive"
            else
                data.adaptiveMode = "Standard"
            end
        end
        
        -- Apply selected adaptive method
        if data.adaptiveMode == "AntiAim" then
            -- Anti-aim resolver
            return -currentVelocity * 0.2 * ResolverConfig.Sensitivity
        elseif data.adaptiveMode == "Predictive" then
            -- Predictive resolver
            return currentVelocity * 0.15 * ResolverConfig.Sensitivity
        else
            -- Standard resolver
            return currentVelocity * 0.1 * ResolverConfig.Sensitivity
        end
    end
    
    return Vector3.new()
end

local function calculatePrediction(targetRoot, predictionTime)
    if not targetRoot then return targetRoot and targetRoot.Position or Vector3.new() end
    
    -- Get base prediction
    local basePrediction = predictPosition1(targetRoot, predictionTime or predictionValue or 0.04)
    
    -- Apply resolver if enabled
    if ResolverConfig.Enabled then
        local character = targetRoot.Parent
        local player = Players:GetPlayerFromCharacter(character)
        
        if player then
            -- Initialize resolver data
            initializeResolverData(player)
            
            -- Detect anti-aim patterns
            if ResolverConfig.AntiAimDetection then
                detectAntiAim(player)
            end
            
            -- Apply resolver offset
            local resolverOffset = calculateResolverOffset(player, targetRoot)
            basePrediction = basePrediction + resolverOffset
            
            -- Debug information
            if ResolverConfig.DebugMode then
                local data = resolverData[player.Name]
                print(string.format("Resolver: %s | Pattern: %s | AntiAim: %s", 
                    player.Name, 
                    data.movementPattern, 
                    tostring(data.antiAimDetected)
                ))
            end
        end
    end
    
    return basePrediction
end

-- Track shot results for adaptive resolver
local function trackShotResult(player, hit)
    if not ResolverConfig.Enabled then return end
    
    local data = resolverData[player.Name]
    if not data then return end
    
    if hit then
        data.hitCount = data.hitCount + 1
    else
        data.missCount = data.missCount + 1
    end
    
    -- Reset counts periodically to allow adaptation
    local totalShots = data.hitCount + data.missCount
    if totalShots > 50 then
        data.hitCount = math.floor(data.hitCount * 0.8)
        data.missCount = math.floor(data.missCount * 0.8)
    end
end

-- Clean up resolver data when players leave
game.Players.PlayerRemoving:Connect(function(player)
    if resolverData[player.Name] then
        resolverData[player.Name] = nil
    end
end)

-- Visual Bullet Tracer System
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- Bullet tracer configuration
local BulletTracerConfig = {
    Enabled = true,
    Color = Color3.fromRGB(255, 255, 0), -- Neon yellow
    Size = Vector3.new(0.1, 0.1, 0.1),
    Speed = 0.1, -- Time it takes to travel (seconds)
    Lifetime = 2, -- How long the tracer stays visible after reaching target
    Material = Enum.Material.Neon,
    Shape = Enum.PartType.Cylinder, -- Can be Ball, Block, or Cylinder
    Trail = true, -- Add trail effect
    TrailColor = Color3.fromRGB(255, 200, 0),
    TrailTransparency = 0.5
}

-- Function to create visual bullet tracer
local function createBulletTracer(startPosition, endPosition, tool)
    if not BulletTracerConfig.Enabled then return end
    
    -- Create the bullet part
    local bullet = Instance.new("Part")
    bullet.Name = "BulletTracer"
    bullet.Size = BulletTracerConfig.Size
    bullet.Material = BulletTracerConfig.Material
    bullet.Color = BulletTracerConfig.Color
    bullet.Shape = BulletTracerConfig.Shape
    bullet.Anchored = true
    bullet.CanCollide = false
    bullet.CastShadow = false
    bullet.Position = startPosition
    bullet.Parent = workspace
    
    -- Add trail effect if enabled
    local trail
    if BulletTracerConfig.Trail then
        trail = Instance.new("Trail")
        trail.Color = ColorSequence.new(BulletTracerConfig.TrailColor)
        trail.Transparency = NumberSequence.new(BulletTracerConfig.TrailTransparency)
        trail.Lifetime = 0.5
        trail.MinLength = 0
        trail.FaceCamera = true
        
        -- Create attachments for the trail
        local attachment0 = Instance.new("Attachment")
        local attachment1 = Instance.new("Attachment")
        attachment0.Position = Vector3.new(0, 0, 0)
        attachment1.Position = Vector3.new(0, 0, 0)
        attachment0.Parent = bullet
        attachment1.Parent = bullet
        
        trail.Attachment0 = attachment0
        trail.Attachment1 = attachment1
        trail.Parent = bullet
    end
    
    -- Calculate direction and distance
    local direction = (endPosition - startPosition).Unit
    local distance = (endPosition - startPosition).Magnitude
    
    -- Create tween info
    local tweenInfo = TweenInfo.new(
        BulletTracerConfig.Speed,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out,
        0,
        false,
        0
    )
    
    -- Create the movement tween
    local moveTween = TweenService:Create(bullet, tweenInfo, {
        Position = endPosition,
        CFrame = CFrame.lookAt(endPosition, endPosition + direction)
    })
    
    -- Start the tween
    moveTween:Play()
    
    -- Clean up when tween completes
    moveTween.Completed:Connect(function()
        -- Optional: Add impact effect at target
        local impactEffect = Instance.new("Explosion")
        impactEffect.Position = endPosition
        impactEffect.BlastRadius = 2
        impactEffect.BlastPressure = 0
        impactEffect.Visible = false -- Only sound effect
        impactEffect.Parent = workspace
        
        -- Fade out the bullet
        local fadeInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local fadeTween = TweenService:Create(bullet, fadeInfo, {
            Transparency = 1,
            Size = Vector3.new(0, 0, 0)
        })
        
        fadeTween:Play()
        fadeTween.Completed:Connect(function()
            bullet:Destroy()
        end)
    end)
    
    -- Backup cleanup in case something goes wrong
    Debris:AddItem(bullet, BulletTracerConfig.Lifetime + BulletTracerConfig.Speed)
end

-- Modified shooting system with visual tracers
RunService.RenderStepped:Connect(function()
    if defenseMode then
        detectDamageAndAttacker()
    end
    
    checkAmmoAndBuy()
    
    -- Update fake body position if enabled
    if fakeBodyEnabled and strafeEnabled then
        updateFakeBodyPosition()
    end

    -- AUTO EQUIP/UNEQUIP SYSTEM - Now handles both equip and unequip
    if AutoEquipConfig.Enabled then
        spawn(function() -- Use spawn to prevent blocking the main loop
            autoEquipWeapon() -- This now handles both equip when targeting and unequip when not targeting
        end)
    end

    if lockedTarget and lockedTarget.Character then        
        local targetPart = lockedTarget.Character:FindFirstChild(targetHitPart) or lockedTarget.Character:FindFirstChild("Head")
        local bodyEffects = lockedTarget.Character:FindFirstChild("BodyEffects")
        local isKO = bodyEffects and bodyEffects:FindFirstChild("K.O") and bodyEffects["K.O"].Value
        local isGrabbed = lockedTarget.Character:FindFirstChild("GRABBING_CONSTRAINT")
        local isForceField = lockedTarget.Character:FindFirstChild("ForceField")
        
        -- LOOK AT TARGET FUNCTIONALITY - FIXED ROTATION DIRECTION
        if lookat and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character:FindFirstChild("Humanoid") then
            local targetRoot = lockedTarget.Character:FindFirstChild("HumanoidRootPart")
            local playerRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            
            if targetRoot and playerRoot and not getgenv().Flying then
                -- Disable auto rotate
                LocalPlayer.Character.Humanoid.AutoRotate = false
                
                -- Calculate direction to target (only Y rotation for looking left/right)
                local targetPosition = targetRoot.Position
                local playerPosition = playerRoot.Position
                local direction = (targetPosition - playerPosition)
                
                -- FIXED: Calculate Y rotation angle to look at target (reversed direction)
                local lookAngle = math.atan2(-direction.X, -direction.Z)
                
                -- Apply rotation to look at target
                playerRoot.CFrame = CFrame.new(playerPosition) * CFrame.Angles(0, lookAngle, 0)
            end
        elseif not lookat and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            -- Restore auto rotate when look at is disabled
            LocalPlayer.Character.Humanoid.AutoRotate = true
        end
        
        -- PREDICTION LIMITS CONFIGURATION (only used when prediction is enabled)
        local maxPredictionDistance = 30 -- Maximum distance prediction can go (studs)
        local maxPredictionTime = 0.25 -- Maximum prediction time (seconds)
        local velocityThreshold = 80 -- If velocity is above this, limit prediction more
        
        -- FIXED spawn protection check for Da Hood
        local hasSpawnProtection = false
        if spawnProtectionCheck and bodyEffects then
            if isForceField then
                local spawnProtect = bodyEffects:FindFirstChild("SpawnProtect")
                if spawnProtect then
                    -- Handle both BoolValue and NumberValue types
                    if spawnProtect:IsA("BoolValue") then
                        hasSpawnProtection = spawnProtect.Value
                    elseif spawnProtect:IsA("NumberValue") then
                        hasSpawnProtection = spawnProtect.Value > 0
                    elseif spawnProtect:IsA("IntValue") then
                        hasSpawnProtection = spawnProtect.Value > 0
                    end
                end
            end
        end
        
        local currentTool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        local isHoldingRifle = currentTool and currentTool.Name == "Rifle"
        
        -- FIXED: shouldStopShooting now respects spawnProtectionCheck toggle
        local shouldStopShooting = false
        if knockCheek and isKO then
            shouldStopShooting = true
        end
        -- Only check for ForceField if spawnProtectionCheck is enabled
        if spawnProtectionCheck and isForceField and not isHoldingRifle then
            shouldStopShooting = true
        end

        if not fakeBodyEnabled then
            if ViewTargetEnabled then
                Camera.CameraSubject = lockedTarget.Character
            elseif spectateStrafeEnabled and strafeEnabled then
                Camera.CameraSubject = lockedTarget.Character:FindFirstChild("Head")
            end
        end

        -- FIXED STRAFE SYSTEM - Now properly sends HumanoidRootPart for Da Hood
        if strafeEnabled and targetPart and not isGrabbed then
            local targetRoot = lockedTarget.Character:FindFirstChild("HumanoidRootPart")
            local targetPosition = targetRoot.Position -- Default to current position
            
            if fakeBodyEnabled and not fakeBody then
                createFakeBody()
            elseif not fakeBodyEnabled and fakeBody then
                destroyFakeBody()
            end

            if predictionEnabled then
                local predTime = PredicTvalue or predictionValue or 0.03
                
                local targetVelocity = targetRoot.AssemblyLinearVelocity or targetRoot.Velocity or Vector3.new(0, 0, 0)
                local speed = targetVelocity.Magnitude
                
                if speed > velocityThreshold then
                    predTime = math.min(predTime, maxPredictionTime * 0.35)
                else
                    predTime = math.min(predTime, maxPredictionTime)
                end
                
                local predictedPos = calculatePrediction(targetRoot, predTime)
                local predictionDistance = (predictedPos - targetRoot.Position).Magnitude
                
                if predictionDistance > maxPredictionDistance then
                    local direction = (predictedPos - targetRoot.Position).Unit
                    predictedPos = targetRoot.Position + (direction * maxPredictionDistance)
                end
                
                targetPosition = predictedPos
            end

            local playerBody = realBody or LocalPlayer.Character
            local playerRoot = playerBody and playerBody:FindFirstChild("HumanoidRootPart")

            if playerRoot then
                if strafeMode == "Orbit" then
                    -- FIXED: Proper Da Hood strafe using HumanoidRootPart
                    local time = tick()
                    local angle = time * strafeSpeed + math.sin(time * 2) * 0.3
                    local distance = strafeXOffset + math.sin(time * 1.5) * 3
                    local height = -0.1 + math.cos(time * 2) * 1
                    
                    local offset = Vector3.new(
                        math.cos(angle) * distance,
                        height,
                        math.sin(angle) * distance
                    )
                    
                    -- Calculate the orbit position around target
                    local newPosition = targetPosition + offset
                    
                    -- FIXED: Directly teleport HumanoidRootPart for Da Hood compatibility
                    playerRoot.CFrame = CFrame.lookAt(newPosition, targetPosition)
                    
                elseif strafeMode == "Random" then
                    -- FIXED: Random strafe with customizable distance
                    local offset = Vector3.new(
                        math.random(-strafeRandomDistance, strafeRandomDistance), 
                        math.random(-strafeRandomDistance/2, strafeRandomDistance/2), -- Reduced Y range
                        math.random(-strafeRandomDistance, strafeRandomDistance)
                    )
                    
                    -- Calculate random position around target
                    local randomPosition = targetPosition + offset
                    
                    -- FIXED: Direct HumanoidRootPart teleportation for Da Hood
                    playerRoot.CFrame = CFrame.lookAt(randomPosition, targetPosition)
                    
                    -- Add slight delay for random strafe to prevent too rapid movement
                    wait(0.1)
                end
            end
        else
            -- Destroy fake body when not strafing
            if fakeBody then
                destroyFakeBody()
            end
        end

        local humanoid = lockedTarget.Character:FindFirstChild("Humanoid")
        if humanoid then
            -- Initialize health tracking for this target
            if not getgenv().lastHealth[lockedTarget.Name] then
                getgenv().lastHealth[lockedTarget.Name] = humanoid.Health
            end
            
            -- Initialize K.O status tracking for this target
            if getgenv().lastKOStatus[lockedTarget.Name] == nil then
                getgenv().lastKOStatus[lockedTarget.Name] = isKO or false
            end
            
            -- Check for K.O status change (became K.O)
            if isKO and not getgenv().lastKOStatus[lockedTarget.Name] then
                Library:Notify("Knocked " .. lockedTarget.Name .. "!", 3)
                getgenv().lastKOStatus[lockedTarget.Name] = true
            elseif not isKO and getgenv().lastKOStatus[lockedTarget.Name] then
                -- Target got revived/unko'd
                getgenv().lastKOStatus[lockedTarget.Name] = false
            end
            
            -- Damage calculation and effects
            local damageDealt = getgenv().lastHealth[lockedTarget.Name] - humanoid.Health
            
            if damageDealt > 0 and lockedTarget then
                -- Check if it was a headshot
                local isHeadshot = targetHitPart == "Head" or (targetPart and targetPart.Name == "Head")
                
                -- Use new skeleton effect instead of old hit effect
                trackShotResult(lockedTarget, true) -- Hit
                createDamageIndicator(lockedTarget.Character, damageDealt, isHeadshot)
                playHitsound(lockedTarget.Character, damageDealt)
            end
            
            -- Update last health
            getgenv().lastHealth[lockedTarget.Name] = humanoid.Health
        end

        -- FIXED: Tracer with conditional prediction
        if TracerEnabled and targetPart then
            tracer.Visible = true
            local targetScreenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
            
            -- FIXED: Only calculate prediction tracer when predictionEnabled is true
            local predictedPosition = targetPart.Position -- Default to current position
            if predictionEnabled then
                local targetRoot = lockedTarget.Character:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    -- Calculate velocity and apply limits
                    local targetVelocity = targetRoot.AssemblyLinearVelocity or targetRoot.Velocity or Vector3.new(0, 0, 0)
                    local speed = targetVelocity.Magnitude
                    
                    -- Get prediction time and limit it
                    local predTime = PredicTvalue or predictionValue or 0.04
                    if speed > velocityThreshold then
                        predTime = math.min(predTime, maxPredictionTime * 0.4)
                    else
                        predTime = math.min(predTime, maxPredictionTime)
                    end
                    
                    -- Calculate and limit prediction
                    local rawPrediction = getTargetPosition(lockedTarget.Character, targetPart)
                    local predictionDistance = (rawPrediction - targetPart.Position).Magnitude
                    
                    if predictionDistance > maxPredictionDistance then
                        local direction = (rawPrediction - targetPart.Position).Unit
                        predictedPosition = targetPart.Position + (direction * maxPredictionDistance)
                    else
                        predictedPosition = rawPrediction
                    end
                end
            end
            local predictedScreenPos, predictedOnScreen = Camera:WorldToViewportPoint(predictedPosition)
            
            local endScreenPos

            if targetToMouseTracer then
                endScreenPos = UserInputService:GetMouseLocation()
            else
                -- Use fake body position if available, otherwise real body
                local referenceBody = fakeBody or LocalPlayer.Character
                local rootPart = referenceBody and referenceBody:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    local rootScreenPos, rootOnScreen = Camera:WorldToViewportPoint(rootPart.Position)
                    if rootOnScreen then
                        endScreenPos = Vector2.new(rootScreenPos.X, rootScreenPos.Y)
                    end
                end
            end

            -- Update regular tracer
            if onScreen and endScreenPos then
                tracer.From = Vector2.new(targetScreenPos.X, targetScreenPos.Y)
                tracer.To = endScreenPos
            else
                tracer.Visible = false
            end
            
            -- Update prediction tracer (only show when prediction is enabled)
            if showPredictionTracer and predictionEnabled and predictedOnScreen and endScreenPos then
                predictionTracer.Visible = true
                predictionTracer.From = Vector2.new(predictedScreenPos.X, predictedScreenPos.Y)
                predictionTracer.To = endScreenPos
            else
                predictionTracer.Visible = false
            end
        else
            tracer.Visible = false
            predictionTracer.Visible = false
        end
    
        -- ENHANCED RAGE MODE SHOOTING with VISUAL BULLET TRACERS
        if not shouldStopShooting and (not defenseMode or StickyAimEnabled) then
            -- Use real body for shooting (the invisible one doing the strafing)
            local shootingBody = realBody or LocalPlayer.Character
            
            if shootingBody and targetPart then
                local bestTargetPart = lockedTarget.Character:FindFirstChild("Head") or targetPart
                local playerRoot = shootingBody and shootingBody:FindFirstChild("HumanoidRootPart")
                local playerPosition = playerRoot and playerRoot.Position
                
                -- FIXED: Use prediction only when predictionEnabled is true
                local aimPosition
                if predictionEnabled then
                    aimPosition = getTargetPosition(lockedTarget.Character, bestTargetPart)
                else
                    aimPosition = bestTargetPart.Position -- Use current position without prediction
                end
                
                local directVector = (aimPosition - playerPosition).Unit
                
                -- IMPROVED WALLBANG SYSTEM - Better wall detection
                local function hasWallBetween(startPos, endPos, target)
                    local raycastParams = RaycastParams.new()
                    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, target.Character}
                    
                    -- Add fake body to filter if it exists
                    if fakeBody then
                        table.insert(raycastParams.FilterDescendantsInstances, fakeBody)
                    end
                    
                    local direction = (endPos - startPos)
                    local raycastResult = workspace:Raycast(startPos, direction, raycastParams)
                    
                    return raycastResult ~= nil, raycastResult
                end
                
                -- NEW: Get all equipped weapons instead of just one
                local equippedWeapons = {}
                for _, child in pairs(shootingBody:GetChildren()) do
                    if child:IsA("Tool") and child:FindFirstChild("Handle") then
                        table.insert(equippedWeapons, child)
                    end
                end
                
                -- NEW: Shoot with all equipped weapons
                for _, tool in pairs(equippedWeapons) do
                    local handle = tool:FindFirstChild("Handle")
                    if handle then
                        local handlePosition = playerPosition or handle.Position
                        
                        -- Fire multiple shots per frame for rage mode
                        for i = 1, 3 do -- Increased from 2 to 3 for better hit rate
                            if hiddenBulletsEnabled then
                                -- Check if there's a wall between player and target
                                local wallBetween, wallResult = hasWallBetween(handlePosition, aimPosition, lockedTarget)
                                
                                local shotOrigin, shotTarget
                                
                                if wallBetween and wallResult then
                                    -- IMPROVED WALLBANG LOGIC - Multiple methods
                                    local wallbangMethod = math.random(1, 5)
                                    
                                    if wallbangMethod == 1 then
                                        -- Method 1: Shoot from above
                                        shotOrigin = handlePosition + Vector3.new(0, math.random(25, 40), 0)
                                        shotTarget = aimPosition + Vector3.new(0, math.random(5, 15), 0)
                                    elseif wallbangMethod == 2 then
                                        -- Method 2: Shoot from the side
                                        local sideOffset = Vector3.new(math.random(-30, 30), math.random(10, 20), math.random(-30, 30))
                                        shotOrigin = handlePosition + sideOffset
                                        shotTarget = aimPosition + Vector3.new(math.random(-8, 8), math.random(-8, 8), math.random(-8, 8))
                                    elseif wallbangMethod == 3 then
                                        -- Method 3: Teleport bullets (shoot from near target)
                                        local teleportOffset = Vector3.new(math.random(-35, 35), math.random(-35, 35), math.random(-35, 35))
                                        shotOrigin = aimPosition + teleportOffset
                                        shotTarget = aimPosition
                                    elseif wallbangMethod == 4 then
                                        -- Method 4: Wall reflection simulation
                                        local wallNormal = wallResult.Normal
                                        local reflectionOffset = wallNormal * math.random(20, 35)
                                        shotOrigin = handlePosition + reflectionOffset
                                        shotTarget = aimPosition - reflectionOffset
                                    else
                                        -- Method 5: Underground/through floor
                                        shotOrigin = handlePosition + Vector3.new(0, math.random(-25, -10), 0)
                                        shotTarget = aimPosition + Vector3.new(0, math.random(-15, -5), 0)
                                    end
                                    
                                    -- Additional randomization for better bypass
                                    local randomOffset = Vector3.new(
                                        math.random(-5, 5),
                                        math.random(-5, 5), 
                                        math.random(-5, 5)
                                    )
                                    shotTarget = shotTarget + randomOffset
                                    
                                else
                                    -- Direct shot when no wall
                                    shotOrigin = handle.Position
                                    shotTarget = aimPosition
                                end
                                
                                -- CREATE VISUAL BULLET TRACER
                                createBulletTracer(shotOrigin, shotTarget, tool)
                                
                                -- Fire the shot
                                ReplicatedStorage.MainEvent:FireServer(
                                    "ShootGun",
                                    handle,
                                    shotOrigin,
                                    shotTarget,
                                    bestTargetPart,
                                    directVector
                                )
                            else
                                -- CREATE VISUAL BULLET TRACER for direct shots
                                createBulletTracer(handle.Position, aimPosition, tool)
                                
                                -- Direct shot approach - aimPosition will be predicted or current based on predictionEnabled
                                ReplicatedStorage.MainEvent:FireServer(
                                    "ShootGun",
                                    handle,
                                    handle.Position,
                                    aimPosition,
                                    bestTargetPart,
                                    directVector 
                                )
                            end
                        end
                    end
                end
            end
        end
    else
        tracer.Visible = false
        predictionTracer.Visible = false
        -- Clean up fake body when no target
        if fakeBody then
            destroyFakeBody()
        end
        -- Restore auto rotate when no target and look at was enabled
        if lookat and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.AutoRotate = true
        end
    end
end)

-- Clean up tracking when players leave
game.Players.PlayerRemoving:Connect(function(player)
    if getgenv().lastHealth[player.Name] then
        getgenv().lastHealth[player.Name] = nil
    end
    if getgenv().lastKOStatus[player.Name] then
        getgenv().lastKOStatus[player.Name] = nil
    end
end)

-- Clean up fake body when player dies or character resets
LocalPlayer.CharacterRemoving:Connect(function()
    if fakeBody then
        destroyFakeBody()
    end
end)

-- IMPROVED: Function to check if target is behind a wall with better detection
function checkIfBehindWall(playerPosition, targetPosition)
    -- Cast ray from player to target (targetPosition should already be predicted if enabled)
    local rayDirection = (targetPosition - playerPosition).Unit
    local rayDistance = (targetPosition - playerPosition).Magnitude
    
    -- Create ray parameters
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    -- Exclude player and target from ray
    local filterInstances = {realBody or LocalPlayer.Character}
    if lockedTarget and lockedTarget.Character then
        table.insert(filterInstances, lockedTarget.Character)
    end
    if fakeBody then
        table.insert(filterInstances, fakeBody)
    end
    rayParams.FilterDescendantsInstances = filterInstances
    
    -- Cast main ray
    local mainRayResult = workspace:Raycast(playerPosition, rayDirection * rayDistance, rayParams)
    
    -- Cast additional rays with slight offsets for better detection
    local offsetRays = {}
    for i = 1, 3 do
        local offset = Vector3.new(
            math.random(-2, 2),
            math.random(-2, 2),
            math.random(-2, 2)
        )
        local offsetRay = workspace:Raycast(playerPosition + offset, rayDirection * rayDistance, rayParams)
        table.insert(offsetRays, offsetRay)
    end
    
    -- Return true if main ray or any offset ray hits a wall
    if mainRayResult then
        return true, mainRayResult
    end
    
    for _, ray in pairs(offsetRays) do
        if ray then
            return true, ray
        end
    end
    
    return false, nil
end
-- Hit Effect UI elements
-- This should be integrated with your existing GUI framework
-- Here's the dropdown and slider implementation:

GunMods:AddDropdown('HitEffects', {
    Text = 'Hit Effect Type',
    Values = {"Mark", "Splat", "Spark", "Ring", "Ripple"},
    Default = "Mark",
    Callback = function(value)
        HitEffectConfig.Type = value
    end
})

GunMods:AddSlider('HitEffectScale', {
    Text = 'Hit Effect Size',
    Default = 1,
    Min = 0.5,
    Max = 30,
    Rounding = 1,
    Callback = function(value)
        HitEffectConfig.Scale = value
    end
})

-- Add toggle for enabling/disabling hit effects
GunMods:AddToggle('HitEffectEnabled', {
    Text = 'Hit Effects',
    Default = true,
    Callback = function(value)
        HitEffectConfig.Enabled = value
    end
})


local Resolver = Tabs.Main:AddRightGroupbox('Resolver')

Resolver:AddToggle('ResolverEnabled', {
    Text = 'Resolver',
    Default = false,
    Callback = function(value)
        ResolverConfig.Enabled = value
        if value then
            Library:Notify("Resolver Enabled - Advanced Target Resolution Active", 3)
        else
            Library:Notify("Resolver Disabled", 2)
        end
    end
})

Resolver:AddDropdown('ResolverMode', {
    Text = 'Resolver Mode',
    Values = {"Basic", "Advanced", "Predictive", "Adaptive"},
    Default = "Advanced",
    Callback = function(value)
        ResolverConfig.Mode = value
        Library:Notify("Resolver Mode: " .. value, 2)
    end
})

Resolver:AddSlider('ResolverSensitivity', {
    Text = 'Resolver Sensitivity',
    Default = 0.5,
    Min = 0.1,
    Max = 1.0,
    Rounding = 1,
    Callback = function(value)
        ResolverConfig.Sensitivity = value
    end
})

Resolver:AddToggle('AntiAimDetection', {
    Text = 'Anti-Aim Detection',
    Default = true,
    Callback = function(value)
        ResolverConfig.AntiAimDetection = value
    end
})

Resolver:AddToggle('ResolverDebug', {
    Text = 'Resolver Debug',
    Default = false,
    Callback = function(value)
        ResolverConfig.DebugMode = value
    end
})



local killSayEnabled = false
local killSayMessages = {
    "is a free script and u die to it..", 
    "Must be hard without", 
    "Why aim when does it for you?",
    "Bros not on ZestHub.lol already 😂",
    "Cant be me icl",
    "cant win a hvh? maybe try ",
    "if u wanna win hop in",
    "hey come on if u cant win",
    "how to win a hvh?"
}

TargetingGroup:AddToggle("killsay", { 
    Text = "Kill Say", 
    Default = false,
    Callback = function(Value)
        killSayEnabled = Value
    end
})

local currentTarget = nil -- Track current target to detect changes

task.spawn(function()
    while true do
        if stompTargetEnabled and lockedTarget and lockedTarget ~= LocalPlayer then
            -- Check if target changed and clear old position
            if currentTarget ~= lockedTarget then
                lastPosition = nil -- Clear old position when switching targets
                currentTarget = lockedTarget -- Update current target
            end
            
            local character = lockedTarget.Character
            if character then
                local bodyEffects = character:FindFirstChild("BodyEffects")
                local isKO = bodyEffects and bodyEffects:FindFirstChild("K.O") and bodyEffects["K.O"].Value
                local isSDeath = bodyEffects and bodyEffects:FindFirstChild("SDeath") and bodyEffects["SDeath"].Value

                if isKO and not isSDeath then
                    local upperTorso = character:FindFirstChild("UpperTorso")
                    if upperTorso then
                        local humanoidRootPart = LocalPlayer.Character:WaitForChild("HumanoidRootPart")
                        if not lastPosition then
                            lastPosition = humanoidRootPart.Position
                        end
                        humanoidRootPart.CFrame = CFrame.new(upperTorso.Position + Vector3.new(0, 3, 0))
                        RunService.RenderStepped:Wait()
                    end
                elseif isSDeath and lastPosition then
                    if killSayEnabled then
                        local message = killSayMessages[math.random(1, #killSayMessages)]
                        game.ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(message, "All")
                    end
                    local humanoidRootPart = LocalPlayer.Character:WaitForChild("HumanoidRootPart")
                    while (humanoidRootPart.Position - lastPosition).Magnitude > 5 do
                        humanoidRootPart.CFrame = CFrame.new(lastPosition)
                        task.wait()
                    end
                    lastPosition = nil -- Clear position after returning
                end
            else
                -- Character doesn't exist, clear position and return if needed
                if lastPosition then
                    local humanoidRootPart = LocalPlayer.Character:WaitForChild("HumanoidRootPart")
                    while (humanoidRootPart.Position - lastPosition).Magnitude > 5 do
                        humanoidRootPart.CFrame = CFrame.new(lastPosition)
                        task.wait()
                    end
                    lastPosition = nil -- Clear position after returning
                end
            end
            ReplicatedStorage.MainEvent:FireServer("Stomp")
        else
            -- If stomp is disabled or no target, clear everything
            lastPosition = nil
            currentTarget = nil
        end
        task.wait(0)
    end
end)


local StarterGui = game:GetService("StarterGui")
local RapidFireEnabled = false
local hyperFireEnabled = false
local modifiedTools = {}

local function rapidfire(tool)
    if not tool or not tool:FindFirstChild("GunScript") or modifiedTools[tool] then return end

    for _, v in ipairs(getconnections(tool.Activated)) do
        local funcinfo = debug.getinfo(v.Function)
        for i = 1, funcinfo.nups do
            local c, n = debug.getupvalue(v.Function, i)
            if type(c) == "number" then
                debug.setupvalue(v.Function, i, 0.0000000000001)
            end
        end
    end

    modifiedTools[tool] = true
end


local function updateHyperFire()
    for _, obj in ipairs(game:GetDescendants()) do
        if obj.Name == "ToleranceCooldown" and obj:IsA("ValueBase") then
            obj.Value = 0 
        end
    end
end

GunMods:AddToggle("HyperFireToggle", {
    Text = "Rapid Fire",
    Default = false,
    Callback = function(Value)
        hyperFireEnabled = Value
        updateHyperFire()
    end
})

game.DescendantAdded:Connect(function(obj)
    if obj.Name == "ToleranceCooldown" and obj:IsA("ValueBase") then
        obj.Value = hyperFireEnabled and 0 or 3
    end
end)

RunService.RenderStepped:Connect(function()
    if hyperFireEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        local character = LocalPlayer.Character
        if character then
            local tool = character:FindFirstChildOfClass("Tool")
            if tool and tool:FindFirstChild("Ammo") then
                tool:Activate()
            end
        end
    end
end)

local HBE = Tabs.Main:AddRightGroupbox('HBE')

local size = 10
local hitboxColor = Color3.new(0, 1, 1)
local visualizeHitbox = false
local hitboxExpanderEnabled = false
local Client = game.Players.LocalPlayer
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

HBE:AddToggle('HitboxExpanderToggle', {
    Text = 'Hitbox Expander',
    Default = false,
    Callback = function(state)
        hitboxExpanderEnabled = state
        if not state then
            for _, Player in pairs(Players:GetPlayers()) do
                if Player ~= Client and Player.Character then
                    resetCharacter(Player.Character)
                end
            end
        end
    end,
}):AddKeyPicker("FlightKeybindPicker", {
    Default = "L",
    Text = "Hitbox",
    Mode = "Toggle",
    Callback = function(state)
        if UserInputService:GetFocusedTextBox() then return end
        hitboxExpanderEnabled = state
        if not state then
            for _, Player in pairs(Players:GetPlayers()) do
                if Player ~= Client and Player.Character then
                    resetCharacter(Player.Character)
                end
            end
        end
    end
})

HBE:AddSlider('HitboxSizeSlider', {
    Text = 'Hitbox Size',
    Default = 10,
    Min = 10,
    Max = 50,
    Rounding = 0,
    Callback = function(value)
        size = value
    end,
})

HBE:AddToggle('VisualizerToggle', {
    Text = 'Visualize',
    Default = false,
    Callback = function(state)
        visualizeHitbox = state
        if not state then
            for _, Player in pairs(Players:GetPlayers()) do
                if Player ~= Client and Player.Character then
                    removeVisuals(Player.Character)
                end
            end
        end
    end,
}):AddColorPicker('HitboxColorPicker', {
    Text = 'Hitbox Color',
    Default = Color3.new(0, 1, 1),
    Callback = function(color)
        hitboxColor = color
    end,
})

local function removeVisuals(Character)
    if not Character then return end
    local HRP = Character:FindFirstChild("HumanoidRootPart")
    if HRP then
        local outline = HRP:FindFirstChild("HitboxOutline")
        if outline then outline:Destroy() end
        local glow = HRP:FindFirstChild("HitboxGlow")
        if glow then glow:Destroy() end
    end
end

local function resetCharacter(Character)
    if not Character then return end
    local HRP = Character:FindFirstChild("HumanoidRootPart")
    if HRP then
        -- Reset HRP size to default (2, 1, 2)
        HRP.Size = Vector3.new(2, 1, 2)
        HRP.Transparency = 1
        HRP.CanCollide = true
        removeVisuals(Character)
    end
end

local function handleCharacter(Character)
    if not Character or not hitboxExpanderEnabled then
        resetCharacter(Character)
        return
    end
    local HRP = Character:FindFirstChild("HumanoidRootPart") or Character:WaitForChild("HumanoidRootPart", 5)
    if not HRP then return end

    HRP.Size = Vector3.new(size, size, size)
    HRP.Transparency = 1
    HRP.CanCollide = false

    if visualizeHitbox then
        local outline = HRP:FindFirstChild("HitboxOutline")
        if not outline then
            outline = Instance.new("BoxHandleAdornment")
            outline.Name = "HitboxOutline"
            outline.Adornee = HRP
            outline.Size = HRP.Size
            outline.Transparency = 0.8
            outline.ZIndex = 10
            outline.AlwaysOnTop = true
            outline.Color3 = hitboxColor
            outline.Parent = HRP

            local glow = Instance.new("BoxHandleAdornment")
            glow.Name = "HitboxGlow"
            glow.Adornee = HRP
            glow.Size = HRP.Size + Vector3.new(0.1, 0.1, 0.1)
            glow.Transparency = 0.9
            glow.ZIndex = 9
            glow.AlwaysOnTop = true
            glow.Color3 = hitboxColor
            glow.Parent = HRP
        else
            outline.Size = HRP.Size
            outline.Color3 = hitboxColor
            local glow = HRP:FindFirstChild("HitboxGlow")
            if glow then
                glow.Size = HRP.Size + Vector3.new(0.1, 0.1, 0.1)
                glow.Color3 = hitboxColor
            end
        end
    else
        removeVisuals(Character)
    end
end

local function handlePlayer(Player)
    if Player == Client then return end
    Player.CharacterAdded:Connect(function(Character)
        Character:WaitForChild("HumanoidRootPart")
        handleCharacter(Character)
    end)
    if Player.Character then
        handleCharacter(Player.Character)
    end
end

for _, Player in pairs(Players:GetPlayers()) do
    handlePlayer(Player)
end

Players.PlayerAdded:Connect(handlePlayer)

RunService.Heartbeat:Connect(function()
    if not hitboxExpanderEnabled then
        for _, Player in pairs(Players:GetPlayers()) do
            if Player ~= Client and Player.Character then
                resetCharacter(Player.Character)
            end
        end
        return
    end
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= Client and Player.Character then
            handleCharacter(Player.Character)
        end
    end
end)

local CamLockBox = Tabs.Legit:AddRightGroupbox('CamLock')
local TriggerBox = Tabs.Legit:AddLeftGroupbox('Trigger Bot')

-- Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

-- Variables
local camLockEnabled = false
local camLockTarget = nil
local smoothness = 0.5
local aimPart = "Head"
local fovRadius = 100
local showFovCircle = true
local fovCircle = nil

-- Trigger Bot Variables
local triggerEnabled = false
local triggerDelay = 0.05
local triggerHitChance = 95
local lastTriggerTime = 0
local knockCheckEnabled = true -- NEW: Toggle for knock check

-- Misc Variables
local antiAimEnabled = false
local legitSpeedEnabled = false
local legitSpeed = 16

-- FOV Circle Creation
local function createFovCircle()
    if fovCircle then
        fovCircle:Remove()
    end
    
    fovCircle = Drawing.new("Circle")
    fovCircle.Color = Color3.fromRGB(255, 255, 255)
    fovCircle.Thickness = 2
    fovCircle.NumSides = 64
    fovCircle.Radius = fovRadius
    fovCircle.Filled = false
    fovCircle.Transparency = 0.7
    fovCircle.Visible = showFovCircle
    
    -- Center the circle on screen
    local screenSize = Camera.ViewportSize
    fovCircle.Position = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
end

-- Update FOV Circle
local function updateFovCircle()
    if fovCircle then
        local screenSize = Camera.ViewportSize
        fovCircle.Position = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
        fovCircle.Radius = fovRadius
        fovCircle.Visible = showFovCircle and camLockEnabled
    end
end

-- Get target part based on selection
local function getTargetPart(character)
    local part = character:FindFirstChild(aimPart)
    if not part and aimPart == "HumanoidRootPart" then
        part = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
    end
    return part
end

-- Check if target is within FOV
local function isWithinFOV(screenPos, center)
    local distance = (Vector2.new(center.X, center.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
    return distance <= fovRadius
end

-- FIXED: Updated K.O check function for Da Hood
local function isPlayerKnockedOut(player)
    if not player or not player.Character then return true end
    
    local character = player.Character
    local humanoid = character:FindFirstChild("Humanoid")
    
    if not humanoid then return true end
    
    -- Check if player is knocked out (Da Hood specific)
    local bodyEffects = character:FindFirstChild("BodyEffects")
    if bodyEffects then
        local koValue = bodyEffects:FindFirstChild("K.O")
        if koValue then
            -- Check if it's a BoolValue and get its Value, or if it's already a boolean
            if typeof(koValue) == "Instance" and koValue:IsA("BoolValue") then
                return koValue.Value == true
            elseif typeof(koValue.Value) == "boolean" then
                return koValue.Value == true
            end
        end
    end
    
    -- Backup health check
    if humanoid.Health <= 0 then return true end
    
    return false
end

local function getClosestPlayer()
    local closestPlayer = nil
    local closestDistance = math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local character = player.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                -- Apply knock check only if enabled
                if knockCheckEnabled and isPlayerKnockedOut(player) then
                    continue
                end
                
                local targetPart = getTargetPart(character)
                if targetPart then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local screenPosVec = Vector2.new(screenPos.X, screenPos.Y)
                        
                        if isWithinFOV(screenPosVec, screenCenter) then
                            local distance = (screenCenter - screenPosVec).Magnitude
                            if distance < closestDistance then
                                closestDistance = distance
                                closestPlayer = player
                            end
                        end
                    end
                end
            end
        end
    end

    return closestPlayer
end

-- Wall check function
local function hasWallBetween(startPos, endPos, target)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, target.Character}
    
    local raycastResult = workspace:Raycast(startPos, (endPos - startPos), raycastParams)
    return raycastResult ~= nil
end

-- FIXED: Updated canTrigger function
local function canTrigger()
    if not triggerEnabled then return false end
    if tick() - lastTriggerTime < triggerDelay then return false end
    
    -- Hit chance check
    if math.random(1, 100) > triggerHitChance then return false end
    
    local target = Mouse.Target
    if not target then return false end
    
    local character = target.Parent
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    
    local player = Players:GetPlayerFromCharacter(character)
    if not player or player == LocalPlayer then return false end
    
    -- Apply knock check only if enabled
    if knockCheckEnabled and isPlayerKnockedOut(player) then 
        return false 
    end
    
    -- Check if targeting valid parts
    local validParts = {"Head", "UpperTorso", "LowerTorso", "Torso", "HumanoidRootPart"}
    local isValidPart = false
    for _, part in pairs(validParts) do
        if target.Name == part then
            isValidPart = true
            break
        end
    end
    
    return isValidPart
end

local function triggerShoot()
    if canTrigger() then
        lastTriggerTime = tick()
        mouse1click()
    end
end

-- Anti-Aim function (subtle movement)
local function applyAntiAim()
    if not antiAimEnabled or not LocalPlayer.Character then return end
    
    local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        local currentTime = tick()
        local offset = math.sin(currentTime * 5) * 0.1
        humanoidRootPart.CFrame = humanoidRootPart.CFrame * CFrame.Angles(0, math.rad(offset), 0)
    end
end

-- CamLock UI
CamLockBox:AddToggle('CamLockToggle', {
    Text = 'CamLock',
    Default = false,
    Callback = function(state)
        camLockEnabled = state
        if not state then
            camLockTarget = nil
        end
    end,
}):AddKeyPicker('CamLockKeybind', {
    Default = 'Q',
    Text = 'CamLock',
    Mode = 'Toggle',
    Callback = function()
        if UserInputService:GetFocusedTextBox() then return end
        if not camLockEnabled then return end

        if camLockTarget then
            camLockTarget = nil
        else
            camLockTarget = getClosestPlayer()
        end
    end,
})

CamLockBox:AddDropdown('AimPartDropdown', {
    Values = {'Head', 'HumanoidRootPart', 'UpperTorso', 'LowerTorso'},
    Default = 1,
    Multi = false,
    Text = 'Aim Part',
    Callback = function(Value)
        aimPart = Value
    end
})

CamLockBox:AddSlider('SmoothnessSlider', {
    Text = 'Smoothness',
    Default = 0.5,
    Min = 0.1,
    Max = 1,
    Rounding = 2,
    Compact = false,
    Callback = function(Value)
        smoothness = Value
    end
})

CamLockBox:AddSlider('FOVSlider', {
    Text = 'FOV Radius',
    Default = 100,
    Min = 50,
    Max = 500,
    Rounding = 0,
    Compact = false,
    Callback = function(Value)
        fovRadius = Value
    end
})

CamLockBox:AddToggle('FOVCircleToggle', {
    Text = 'Show FOV Circle',
    Default = true,
    Callback = function(state)
        showFovCircle = state
    end
})

CamLockBox:AddLabel('FOV Circle Color'):AddColorPicker('FOVColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Title = 'FOV Circle Color',
    Transparency = 0.3,
    Callback = function(Value)
        if fovCircle then
            fovCircle.Color = Value
        end
    end
})

local prediction = 0.1
CamLockBox:AddSlider('PredictionSlider', {
    Text = 'Prediction',
    Default = 0.1,
    Min = 0,
    Max = 0.5,
    Rounding = 3,
    Compact = false,
    Callback = function(Value)
        prediction = Value
    end
})

local wallCheck = true
CamLockBox:AddToggle('WallCheckToggle', {
    Text = 'Wall Check',
    Default = true,
    Callback = function(state)
        wallCheck = state
    end
})

-- Trigger Bot UI
TriggerBox:AddToggle('TriggerToggle', {
    Text = 'Trigger Bot',
    Default = false,
    Callback = function(state)
        triggerEnabled = state
    end,
}):AddKeyPicker('TriggerKeybind', {
    Default = 'T',
    Text = 'Trigger Bot',
    Mode = 'Toggle'
})

TriggerBox:AddSlider('TriggerDelaySlider', {
    Text = 'Trigger Delay (ms)',
    Default = 50,
    Min = 1,
    Max = 200,
    Rounding = 0,
    Compact = false,
    Callback = function(Value)
        triggerDelay = Value / 1000
    end
})

TriggerBox:AddSlider('HitChanceSlider', {
    Text = 'Hit Chance (%)',
    Default = 95,
    Min = 60,
    Max = 100,
    Rounding = 0,
    Compact = false,
    Callback = function(Value)
        triggerHitChance = Value
    end
})

-- NEW: Knock Check Toggle for Trigger Bot
TriggerBox:AddToggle('KnockCheckToggle', {
    Text = 'Knock Check',
    Default = true,
    Tooltip = 'Skip knocked out players (Da Hood)',
    Callback = function(state)
        knockCheckEnabled = state
    end
})

-- Initialize FOV Circle
createFovCircle()

-- Main render loop
RunService.RenderStepped:Connect(function()
    updateFovCircle()
    
    -- CamLock Logic
    if camLockEnabled and camLockTarget then
        local character = camLockTarget.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                -- Apply knock check for camlock too if enabled
                if knockCheckEnabled and isPlayerKnockedOut(camLockTarget) then
                    camLockTarget = nil
                    return
                end
                
                local targetPart = getTargetPart(character)
                if targetPart then
                    local currentCFrame = Camera.CFrame
                    
                    -- Get target position with prediction
                    local targetVelocity = Vector3.new(0, 0, 0)
                    if humanoid.RootPart then
                        targetVelocity = humanoid.RootPart.Velocity
                    end
                    
                    local targetPosition = targetPart.Position + (targetVelocity * prediction)
                    
                    -- Wall check
                    if wallCheck and hasWallBetween(currentCFrame.Position, targetPosition, camLockTarget) then
                        camLockTarget = nil
                        return
                    end
                    
                    -- Calculate smooth look direction
                    local lookVector = (targetPosition - currentCFrame.Position).Unit
                    local currentLookVector = currentCFrame.LookVector
                    local smoothedLookVector = currentLookVector:Lerp(lookVector, smoothness)
                    
                    -- Update camera CFrame
                    Camera.CFrame = CFrame.new(currentCFrame.Position, currentCFrame.Position + smoothedLookVector)
                else
                    camLockTarget = nil
                end
            else
                camLockTarget = nil
            end
        else
            camLockTarget = nil
        end
    end
    
    -- Trigger Bot Logic
    if triggerEnabled then
        triggerShoot()
    end
    
    -- Anti-Aim Logic
    if antiAimEnabled then
        applyAntiAim()
    end
end)

-- Handle character respawn for legit speed
LocalPlayer.CharacterAdded:Connect(function(character)
    if legitSpeedEnabled then
        character:WaitForChild("Humanoid").WalkSpeed = legitSpeed
    end
end)

-- Cleanup functions
Players.PlayerRemoving:Connect(function(player)
    if camLockTarget == player then
        camLockTarget = nil
    end
end)

-- Clean up FOV circle when needed
spawn(function()
    while true and fovCircle do
        wait(1)
        if not fovCircle then break end
    end
end)

-- Brutal Da Hood Kill Aura
-- Enhanced for maximum effectiveness

getgenv().settings = {
    range = 300,                -- Increased maximum range
    targetPriority = "closest", -- Options: "closest", "lowestHealth", "highestBounty"
    autoEquipGun = true,        -- Auto equips gun when needed
    autoReload = true,          -- Auto reloads when ammo is low
    autoRevive = true,         -- Auto revives yourself if knocked
    antiStompProtection = true, -- Prevents you from being stomped
    antiGrab = true,           -- Prevents you from being grabbed
    hitParts = {               -- Target multiple body parts
        "Head",                -- Headshots for maximum damage
        "UpperTorso",          -- Backup hitbox
        "LowerTorso",          -- Additional hitbox
        "HumanoidRootPart"     -- Core hitbox
    },
    visualizerOptions = {
        enabled = false,
        thickness = 0.15,
        material = Enum.Material.Neon,
        color = Color3.new(1, 0, 0),
        rainbow = false,       -- Rainbow effect
        pulse = true,          -- Pulsing effect
    },
    sounds = {
        hitSound = true,
        hitSoundId = "rbxassetid://6607204501", -- Headshot sound
        killSound = true,
        killSoundId = "rbxassetid://5043539486", -- Kill sound
    },
    performance = {
        optimizeRendering = true, -- Reduces lag
        refreshRate = 0.01,      -- How often to check for targets (lower = more aggressive)
    },
    targetFilters = {
        ignoreCrewMembers = true,
        ignoreFriends = true,
        ignoreWhitelisted = true,
        targetEnemies = true,    -- Actively target people who damaged you
    }
}

getgenv().whitelist = {}
getgenv().enemyList = {}

-- Initialize visualization tracer
getgenv().tracer = Instance.new("Part")
getgenv().tracer.Size = Vector3.new(settings.visualizerOptions.thickness, settings.visualizerOptions.thickness, settings.visualizerOptions.thickness)
getgenv().tracer.Material = settings.visualizerOptions.material
getgenv().tracer.Color = settings.visualizerOptions.color
getgenv().tracer.Transparency = 1
getgenv().tracer.Anchored = true
getgenv().tracer.CanCollide = false
getgenv().tracer.Parent = workspace

-- Initialize status variables
getgenv().enabled = false
getgenv().active = false
getgenv().visualizeEnabled = settings.visualizerOptions.enabled
getgenv().silentEnabled = true
getgenv().rainbowEnabled = settings.visualizerOptions.rainbow
getgenv().lastHealth = {}
getgenv().kills = 0

-- Create hit sound
local hitSound = Instance.new("Sound")
hitSound.SoundId = settings.sounds.hitSoundId
hitSound.Volume = 1
hitSound.Parent = game:GetService("SoundService")

local killSound = Instance.new("Sound")
killSound.SoundId = settings.sounds.killSoundId
killSound.Volume = 1
killSound.Parent = game:GetService("SoundService")

-- Utility Functions
local function playHitSound()
    if settings.sounds.hitSound then
        hitSound:Play()
    end
end

local function playKillSound()
    if settings.sounds.killSound then
        killSound:Play()
    end
end

local function isPlayerKnocked(player)
    if workspace:FindFirstChild("Players") and 
       workspace.Players:FindFirstChild(player.Name) and 
       workspace.Players:FindFirstChild(player.Name):FindFirstChild("BodyEffects") and 
       workspace.Players:FindFirstChild(player.Name).BodyEffects:FindFirstChild("K.O") then
        return workspace.Players:FindFirstChild(player.Name).BodyEffects["K.O"].Value
    end
    return false
end

local function isLocalPlayerKnocked()
    return isPlayerKnocked(game.Players.LocalPlayer)
end

local function getGun()
    for _, tool in pairs(game.Players.LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool:FindFirstChild("GunScript") then
            return tool
        end
    end
    
    -- Check if already equipped
    if game.Players.LocalPlayer.Character then
        for _, tool in pairs(game.Players.LocalPlayer.Character:GetChildren()) do
            if tool:IsA("Tool") and tool:FindFirstChild("GunScript") then
                return tool
            end
        end
    end
    
    return nil
end

local function equipBestGun()
    if not settings.autoEquipGun then return end
    
    local gun = getGun()
    if gun and gun.Parent == game.Players.LocalPlayer.Backpack then
        game.Players.LocalPlayer.Character.Humanoid:EquipTool(gun)
        return true
    elseif gun and gun.Parent == game.Players.LocalPlayer.Character then
        return true
    end
    return false
end

local function autoRevive()
    if not settings.autoRevive or not isLocalPlayerKnocked() then return end
    
    -- Auto revive logic
    game.ReplicatedStorage.MainEvent:FireServer("GetUpNow")
    task.wait(0.5)
end

local function antiStomp()
    if not settings.antiStompProtection then return end
    
    if isLocalPlayerKnocked() then
        -- Reset character to prevent stomp
        game.Players.LocalPlayer.Character:BreakJoints()
    end
end

local function antiGrab()
    if not settings.antiGrab then return end
    
    -- Check for grabbing constraint
    if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("GRABBING_CONSTRAINT") then
        game.Players.LocalPlayer.Character.GRABBING_CONSTRAINT:Destroy()
    end
end

local function getClosestTarget()
    local closest = math.huge
    local target = nil

    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer and 
           not getgenv().whitelist[player.Name] and 
           player.Character and 
           player.Character:FindFirstChild("Head") and 
           not player.Character:FindFirstChild("GRABBING_CONSTRAINT") and
           not isPlayerKnocked(player) then
            
            -- Check crew members
            if settings.targetFilters.ignoreCrewMembers then
                local playerCrew = player:FindFirstChild("DataFolder") and player.DataFolder:FindFirstChild("Information") and player.DataFolder.Information:FindFirstChild("Crew")
                local localCrew = game.Players.LocalPlayer:FindFirstChild("DataFolder") and game.Players.LocalPlayer.DataFolder:FindFirstChild("Information") and game.Players.LocalPlayer.DataFolder.Information:FindFirstChild("Crew")
                
                if playerCrew and localCrew and playerCrew.Value == localCrew.Value and localCrew.Value ~= "" then
                    continue
                end
            end
            
            -- Check friends
            if settings.targetFilters.ignoreFriends and game.Players.LocalPlayer:IsFriendsWith(player.UserId) then
                continue
            end
            
            local dist = (game.Players.LocalPlayer.Character.HumanoidRootPart.Position - player.Character.Head.Position).Magnitude
            if dist < closest and dist <= getgenv().settings.range then
                closest = dist
                target = player
            end
        end
    end

    return target, closest
end

local function getLowestHealthTarget()
    local lowestHealth = math.huge
    local target = nil

    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer and 
           not getgenv().whitelist[player.Name] and 
           player.Character and 
           player.Character:FindFirstChild("Head") and 
           player.Character:FindFirstChild("Humanoid") and
           not player.Character:FindFirstChild("GRABBING_CONSTRAINT") and 
           not isPlayerKnocked(player) then
            
            local dist = (game.Players.LocalPlayer.Character.HumanoidRootPart.Position - player.Character.Head.Position).Magnitude
            if dist <= getgenv().settings.range and player.Character.Humanoid.Health < lowestHealth then
                lowestHealth = player.Character.Humanoid.Health
                target = player
            end
        end
    end

    return target
end

local function getTargetBasedOnPriority()
    if settings.targetPriority == "closest" then
        return getClosestTarget()
    elseif settings.targetPriority == "lowestHealth" then
        return getLowestHealthTarget()
    else
        return getClosestTarget() -- Default to closest
    end
end

local function updateRainbowColor()
    if not getgenv().rainbowEnabled then return end
    
    local hue = tick() % 10 / 10
    getgenv().tracer.Color = Color3.fromHSV(hue, 1, 1)
end

local function updatePulse()
    if not settings.visualizerOptions.pulse then return end
    
    local size = 0.1 + math.abs(math.sin(tick() * 5)) * 0.1
    getgenv().tracer.Size = Vector3.new(size, size, getgenv().tracer.Size.Z)
end

getgenv().range = 250

getgenv().whitelist = {}


getgenv().tracer = Instance.new("Part")
getgenv().tracer.Size = Vector3.new(0.2, 0.2, 0.2)
getgenv().tracer.Material = Enum.Material.Neon
getgenv().tracer.Color = Color3.new(1, 0, 0)
getgenv().tracer.Transparency = 1
getgenv().tracer.Anchored = true
getgenv().tracer.CanCollide = false
getgenv().tracer.Parent = workspace

getgenv().enabled = false
getgenv().active = false
getgenv().visualizeEnabled = false
getgenv().silentEnabled = false
getgenv().lastHealth = {}

KillAura:AddToggle('MainToggle', {
    Text = 'Kill Aura',
    Default = false,
    Callback = function(state)
        getgenv().enabled = state
        if not state then
            getgenv().active = false
            getgenv().tracer.Transparency = 1
        end
    end
}):AddKeyPicker('Keybind', {
    Default = 'K',
    Text = 'kill aura',
    Mode = 'Toggle',
    Callback = function(state)
        if not getgenv().enabled or UserInputService:GetFocusedTextBox() then return end
        getgenv().active = state
    end
})

KillAura:AddSlider("Range", {
    Text = "Range",
    Default = 250,
    Min = 10,
    Max = 250,
    Rounding = 1,
    Callback = function(value)
        getgenv().range = value
    end
})

KillAura:AddToggle('Visualizer', {
    Text = 'Visualize',
    Default = false,
    Callback = function(state)
        getgenv().visualizeEnabled = state
    end
}):AddColorPicker('VisualizerColor', {
    Text = 'Visualizer Color',
    Default = Color3.new(1, 0, 0),
    Callback = function(value)
        getgenv().tracer.Color = value
    end
})

KillAura:AddToggle('Silent', {
    Text = 'Silent',
    Default = false,
    Callback = function(state)
        getgenv().silentEnabled = state
    end
})

KillAura:AddInput('wlb', {
    Default = '',
    Numeric = false,
    Finished = false,
    Text = 'Add/Remove Player',
    Tooltip = 'Type a name or display name to add/remove from whitelist',
    Placeholder = 'Player Name',
    Callback = function(input)
        for _, player in pairs(game.Players:GetPlayers()) do
            if player.Name == input or player.DisplayName == input then
                if getgenv().whitelist[player.Name] then
                    getgenv().whitelist[player.Name] = nil
                    Library:Notify(player.Name .. " removed from whitelist.", 2)
                else
                    getgenv().whitelist[player.Name] = true
                    Library:Notify(player.Name .. " added to whitelist.", 2)
                end
                return
            end
        end
        Library:Notify("Player not found.", 2)
    end,
    Autocomplete = function(input)
        local suggestions = {}
        for _, player in pairs(game.Players:GetPlayers()) do
            if string.find(string.lower(player.Name), string.lower(input)) or string.find(string.lower(player.DisplayName), string.lower(input)) then
                table.insert(suggestions, player.Name .. " (" .. player.DisplayName .. ")")
            end
        end
        return suggestions
    end
})



task.spawn(function()
    while true do
        if getgenv().active and getgenv().enabled and game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool") and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool"):FindFirstChild("Handle") then
            if workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild(game.Players.LocalPlayer.Name) and workspace.Players:FindFirstChild(game.Players.LocalPlayer.Name):FindFirstChild("BodyEffects") and workspace.Players:FindFirstChild(game.Players.LocalPlayer.Name).BodyEffects:FindFirstChild("K.O") and workspace.Players:FindFirstChild(game.Players.LocalPlayer.Name).BodyEffects["K.O"].Value then
                task.wait()
            else
                local closest = math.huge
                target = nil

                for _, player in pairs(game.Players:GetPlayers()) do
                    if player ~= game.Players.LocalPlayer and not getgenv().whitelist[player.Name] and player.Character and player.Character:FindFirstChild("Head") and not player.Character:FindFirstChild("GRABBING_CONSTRAINT") then
                        if workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild(player.Name) and workspace.Players:FindFirstChild(player.Name):FindFirstChild("BodyEffects") and workspace.Players:FindFirstChild(player.Name).BodyEffects:FindFirstChild("K.O") and not workspace.Players:FindFirstChild(player.Name).BodyEffects["K.O"].Value then
                            local dist = (game.Players.LocalPlayer.Character.HumanoidRootPart.Position - player.Character.Head.Position).Magnitude
                            if dist < closest and dist <= getgenv().range then
                                closest = dist
                                target = player
                            end
                        end
                    end
                end

                if target and target.Character and target.Character:FindFirstChild("Head") then
                    if getgenv().visualizeEnabled then
                        getgenv().tracer.Transparency = 0
                        getgenv().tracer.Size = Vector3.new(0.2, 0.2, (game.Players.LocalPlayer.Character.HumanoidRootPart.Position - target.Character.Head.Position).Magnitude)
                        getgenv().tracer.CFrame = CFrame.lookAt(game.Players.LocalPlayer.Character.HumanoidRootPart.Position, target.Character.Head.Position) * CFrame.new(0, 0, -getgenv().tracer.Size.Z / 2)
                    else
                        getgenv().tracer.Transparency = 1
                    end

                    local humanoid = target.Character:FindFirstChild("Humanoid")
                    if humanoid then
                        if not getgenv().lastHealth[target.Name] then
                            getgenv().lastHealth[target.Name] = humanoid.Health
                        end
                        if humanoid.Health < getgenv().lastHealth[target.Name] then
                            playHitsound()
                        end
                        getgenv().lastHealth[target.Name] = humanoid.Health
                    end

                    if getgenv().silentEnabled then
                        game.ReplicatedStorage.MainEvent:FireServer(
                            "ShootGun",
                            game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool"):FindFirstChild("Handle"),
                            game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool"):FindFirstChild("Handle").CFrame.Position - Vector3.new(0, 12, 0),
                            target.Character.Head.Position - Vector3.new(0, 12, 0),
                            target.Character.Head,
                            Vector3.new(0, 0, -1)
                    )
                    else
                        game.ReplicatedStorage.MainEvent:FireServer("ShootGun", game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool"):FindFirstChild("Handle"), game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool"):FindFirstChild("Handle").CFrame.Position, target.Character.Head.Position, target.Character.Head, Vector3.new(0, 0, -1))
                    end
                else
                    getgenv().tracer.Transparency = 1
                end
            end
        else
            getgenv().tracer.Transparency = 1
        end
        task.wait()
    end
end)


-- Configuration
getgenv().espEnabled = true
getgenv().espColor = Color3.new(1, 1, 1)
getgenv().boxESPEnabled = false
getgenv().boxStyle = "Normal"
getgenv().boxFilled = false -- NEW: Box fill option
getgenv().boxTransparency = 0.65 -- NEW: Box transparency
getgenv().nameESPEnabled = false
getgenv().nameColor = Color3.new(1, 1, 1)
getgenv().nameDisplayMode = "Username"
getgenv().nameTextSize = 14
getgenv().textStyle = "SourceSans"
getgenv().studsESPEnabled = false
getgenv().distanceColor = Color3.new(1, 1, 1)
getgenv().distanceTextSize = 14
getgenv().healthBarESP = false
getgenv().healthBarColor = Color3.new(0, 1, 0)
getgenv().healthBarBackground = Color3.new(0.2, 0.2, 0.2)
getgenv().weaponESPEnabled = false
getgenv().weaponColor = Color3.new(1, 1, 1)
getgenv().armorBarESP = false
getgenv().armorBarColor = Color3.new(0, 0, 1)
getgenv().armorBarBackground = Color3.new(0.2, 0.2, 0.2)
getgenv().outlineEnabled = false
getgenv().penisESPEnabled = false
getgenv().penisColor = Color3.new(1, 0, 0)
getgenv().healthSmoothness = 0.1
getgenv().highlightEnabled = false
getgenv().highlightFillColor = Color3.new(1, 1, 1)
getgenv().highlightOutlineColor = Color3.new(0, 0, 0)
getgenv().highlightFillTransparency = 0.8 -- NEW: Highlight fill transparency
getgenv().highlightOutlineTransparency = 0.5 -- NEW: Highlight outline transparency


-- NEW: Max distance setting
getgenv().maxDistance = 1000
getgenv().maxDistanceEnabled = false

-- Store current health values for smooth transitions
local currentHealthValues = {}
local currentArmorValues = {}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

local fontMap = {
    ["SourceSans"] = 0,
    ["SourceSansBold"] = 1,
    ["SourceSansItalic"] = 2,
    ["SourceSansLight"] = 3,
    ["SourceSansSemibold"] = 4,
    ["Gotham"] = 5,
    ["GothamBold"] = 6,
    ["GothamMedium"] = 7,
    ["GothamSemibold"] = 8,
    ["Minecraft"] = 9,
    ["MinecraftBold"] = 10
}

-- ESP Objects storage
local ESPObjects = {}
local HighlightObjects = {}
local CharacterConnections = {}
local Camera = workspace.CurrentCamera

-- Optimized: Cache frequently accessed objects
local cachedPlayers = {}
local updateCounter = 0
local UPDATE_FREQUENCY = 2 -- Update every 2 frames for better performance

-- Function to completely destroy ESP objects
local function DestroyESPObjects(objects)
    if objects.Box then objects.Box:Remove() end
    if objects.BoxOutline then objects.BoxOutline:Remove() end
    if objects.BoxFilled then objects.BoxFilled:Remove() end -- NEW: Destroy filled box
    if objects.CornerBox then
        for _, corner in pairs(objects.CornerBox) do
            corner:Remove()
        end
    end
    if objects.Username then objects.Username:Remove() end
    if objects.Distance then objects.Distance:Remove() end
    if objects.HealthBarBackground then objects.HealthBarBackground:Remove() end
    if objects.HealthBar then objects.HealthBar:Remove() end
    if objects.HealthBarOutline then objects.HealthBarOutline:Remove() end
    if objects.Weapon then objects.Weapon:Remove() end
    if objects.ArmorBarBackground then objects.ArmorBarBackground:Remove() end
    if objects.ArmorBar then objects.ArmorBar:Remove() end
    if objects.ArmorBarOutline then objects.ArmorBarOutline:Remove() end
    if objects.PenisLine then objects.PenisLine:Remove() end
end

-- Function to create highlight for a player (IMPROVED)
local function CreateHighlight(player)
    if HighlightObjects[player] then
        HighlightObjects[player]:Destroy()
        HighlightObjects[player] = nil
    end
    
    local character = player.Character
    if character and getgenv().highlightEnabled then
        local highlight = Instance.new("Highlight")
        highlight.FillColor = getgenv().highlightFillColor
        highlight.OutlineColor = getgenv().highlightOutlineColor
        highlight.FillTransparency = getgenv().highlightFillTransparency
        highlight.OutlineTransparency = getgenv().highlightOutlineTransparency
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = character
        HighlightObjects[player] = highlight
    end
end

-- Function to destroy highlight for a player
local function DestroyHighlight(player)
    if HighlightObjects[player] then
        HighlightObjects[player]:Destroy()
        HighlightObjects[player] = nil
    end
end

-- Function to create corner box elements
local function CreateCornerBox()
    local corners = {}
    for i = 1, 8 do
        local corner = Drawing.new("Line")
        corner.Thickness = 2
        corner.Color = getgenv().espColor
        corner.Visible = false
        corner.ZIndex = 1
        table.insert(corners, corner)
    end
    return corners
end

-- Function to update corner box
local function UpdateCornerBox(corners, position, size)
    local x, y = position.X, position.Y
    local w, h = size.X, size.Y
    local cornerLength = math.min(w, h) * 0.25
    
    -- Top-left corner
    corners[1].From = Vector2.new(x, y)
    corners[1].To = Vector2.new(x + cornerLength, y)
    corners[2].From = Vector2.new(x, y)
    corners[2].To = Vector2.new(x, y + cornerLength)
    
    -- Top-right corner
    corners[3].From = Vector2.new(x + w, y)
    corners[3].To = Vector2.new(x + w - cornerLength, y)
    corners[4].From = Vector2.new(x + w, y)
    corners[4].To = Vector2.new(x + w, y + cornerLength)
    
    -- Bottom-left corner
    corners[5].From = Vector2.new(x, y + h)
    corners[5].To = Vector2.new(x + cornerLength, y + h)
    corners[6].From = Vector2.new(x, y + h)
    corners[6].To = Vector2.new(x, y + h - cornerLength)
    
    -- Bottom-right corner
    corners[7].From = Vector2.new(x + w, y + h)
    corners[7].To = Vector2.new(x + w - cornerLength, y + h)
    corners[8].From = Vector2.new(x + w, y + h)
    corners[8].To = Vector2.new(x + w, y + h - cornerLength)
end

-- Function to disconnect character connections
local function DisconnectCharacterConnections(player)
    if CharacterConnections[player] then
        for _, connection in pairs(CharacterConnections[player]) do
            if connection then
                connection:Disconnect()
            end
        end
        CharacterConnections[player] = nil
    end
end

-- Function to destroy ESP for a player (OPTIMIZED)
local function DestroyESP(player)
    if ESPObjects[player] then
        DestroyESPObjects(ESPObjects[player])
        ESPObjects[player] = nil
        currentHealthValues[player] = nil
        currentArmorValues[player] = nil
    end
    DestroyHighlight(player)
    DisconnectCharacterConnections(player)
    
    -- Remove from cached players
    cachedPlayers[player] = nil
end

-- Function to setup character monitoring
local function SetupCharacterMonitoring(player)
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    if not CharacterConnections[player] then
        CharacterConnections[player] = {}
    end
    
    local diedConnection = humanoid.Died:Connect(function()
        DestroyHighlight(player)
    end)
    
    local ancestryConnection = character.AncestryChanged:Connect(function()
        if not character.Parent then
            DestroyHighlight(player)
        end
    end)
    
    table.insert(CharacterConnections[player], diedConnection)
    table.insert(CharacterConnections[player], ancestryConnection)
end

-- Function to create ESP for a player (OPTIMIZED WITH FILLED BOX)
local function CreateESP(player)
    -- Only create ESP if enabled
    if not getgenv().espEnabled then
        return
    end
    
    DestroyESP(player)

    local objects = {}
    
    -- Only create objects that are enabled
    if getgenv().boxESPEnabled then
        -- Create filled box first (behind everything)
        if getgenv().boxFilled then
            objects.BoxFilled = Drawing.new("Square")
            objects.BoxFilled.Thickness = 1
            objects.BoxFilled.Filled = true
            objects.BoxFilled.Color = getgenv().espColor
            objects.BoxFilled.Transparency = getgenv().boxTransparency
            objects.BoxFilled.Visible = false
            objects.BoxFilled.ZIndex = 0
        end
        
        -- Create the main box outline
        objects.Box = Drawing.new("Square")
        objects.Box.Thickness = 1
        objects.Box.Filled = false
        objects.Box.Color = getgenv().espColor
        objects.Box.Visible = false
        objects.Box.ZIndex = 2

        -- Always create an outline for the border effect
        objects.BoxOutline = Drawing.new("Square")
        objects.BoxOutline.Thickness = 3  -- Thicker for border effect
        objects.BoxOutline.Filled = false
        objects.BoxOutline.Color = Color3.new(0, 0, 0)  -- Black border
        objects.BoxOutline.Visible = false
        objects.BoxOutline.ZIndex = 1

        if getgenv().boxStyle == "Corners" then
            objects.CornerBox = CreateCornerBox()
        end
    end

    if getgenv().nameESPEnabled then
        objects.Username = Drawing.new("Text")
        objects.Username.Size = getgenv().nameTextSize
        objects.Username.Center = true
        objects.Username.Color = getgenv().nameColor
        objects.Username.Visible = false
        objects.Username.Font = fontMap[getgenv().textStyle] or fontMap["SourceSans"]
        objects.Username.Outline = getgenv().outlineEnabled
        objects.Username.OutlineColor = Color3.new(0, 0, 0)
    end

    if getgenv().studsESPEnabled then
        objects.Distance = Drawing.new("Text")
        objects.Distance.Size = getgenv().distanceTextSize
        objects.Distance.Center = true
        objects.Distance.Color = getgenv().distanceColor
        objects.Distance.Visible = false
        objects.Distance.Font = fontMap[getgenv().textStyle] or fontMap["SourceSans"]
        objects.Distance.Outline = getgenv().outlineEnabled
        objects.Distance.OutlineColor = Color3.new(0, 0, 0)
    end

    if getgenv().healthBarESP then
        objects.HealthBarBackground = Drawing.new("Square")
        objects.HealthBarBackground.Thickness = 1
        objects.HealthBarBackground.Filled = true
        objects.HealthBarBackground.Color = getgenv().healthBarBackground
        objects.HealthBarBackground.Visible = false
        objects.HealthBarBackground.ZIndex = 0

        objects.HealthBar = Drawing.new("Square")
        objects.HealthBar.Thickness = 1
        objects.HealthBar.Filled = true
        objects.HealthBar.Color = getgenv().healthBarColor
        objects.HealthBar.Visible = false
        objects.HealthBar.ZIndex = 1

        -- Always create health bar outline for border effect
        objects.HealthBarOutline = Drawing.new("Square")
        objects.HealthBarOutline.Thickness = 1
        objects.HealthBarOutline.Filled = false
        objects.HealthBarOutline.Color = Color3.new(0, 0, 0)
        objects.HealthBarOutline.Visible = false
        objects.HealthBarOutline.ZIndex = 2
    end

    if getgenv().weaponESPEnabled then
        objects.Weapon = Drawing.new("Text")
        objects.Weapon.Size = getgenv().nameTextSize
        objects.Weapon.Center = true
        objects.Weapon.Color = getgenv().weaponColor
        objects.Weapon.Visible = false
        objects.Weapon.Font = fontMap[getgenv().textStyle] or fontMap["SourceSans"]
        objects.Weapon.Outline = getgenv().outlineEnabled
        objects.Weapon.OutlineColor = Color3.new(0, 0, 0)
    end

    if getgenv().armorBarESP then
        objects.ArmorBarBackground = Drawing.new("Square")
        objects.ArmorBarBackground.Thickness = 1
        objects.ArmorBarBackground.Filled = true
        objects.ArmorBarBackground.Color = getgenv().armorBarBackground
        objects.ArmorBarBackground.Visible = false
        objects.ArmorBarBackground.ZIndex = 0

        objects.ArmorBar = Drawing.new("Square")
        objects.ArmorBar.Thickness = 1
        objects.ArmorBar.Filled = true
        objects.ArmorBar.Color = getgenv().armorBarColor
        objects.ArmorBar.Visible = false
        objects.ArmorBar.ZIndex = 1

        -- Always create armor bar outline for border effect
        objects.ArmorBarOutline = Drawing.new("Square")
        objects.ArmorBarOutline.Thickness = 1
        objects.ArmorBarOutline.Filled = false
        objects.ArmorBarOutline.Color = Color3.new(0, 0, 0)
        objects.ArmorBarOutline.Visible = false
        objects.ArmorBarOutline.ZIndex = 2
    end

    if getgenv().penisESPEnabled then
        objects.PenisLine = Drawing.new("Line")
        objects.PenisLine.Thickness = 2
        objects.PenisLine.Color = getgenv().penisColor
        objects.PenisLine.Visible = false
        objects.PenisLine.ZIndex = 1
    end

    ESPObjects[player] = objects
    
    -- Initialize smooth health values
    currentHealthValues[player] = 100
    currentArmorValues[player] = 0
    
    -- Create highlight if enabled
    if getgenv().highlightEnabled then
        CreateHighlight(player)
    end
    
    -- Setup character monitoring
    SetupCharacterMonitoring(player)
    
    -- Cache player data
    cachedPlayers[player] = {
        character = player.Character,
        lastUpdate = tick()
    }
end

-- Function to handle character respawn
local function OnCharacterAdded(player, character)
    wait(0.5)
    CreateESP(player)
end

local function UpdateESP()
    updateCounter = updateCounter + 1
    
    -- Skip updates for performance (update every nth frame)
    if updateCounter % UPDATE_FREQUENCY ~= 0 then
        return
    end
    
    if not getgenv().espEnabled then
        return
    end
    
    -- Cache LocalPlayer position for distance calculations
    local localCharacter = LocalPlayer.Character
    if not localCharacter or not localCharacter:FindFirstChild("HumanoidRootPart") then
        return
    end
    local localPosition = localCharacter.HumanoidRootPart.Position

    for player, objects in pairs(ESPObjects) do
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") and player ~= LocalPlayer then
            local rootPart = character.HumanoidRootPart
            local humanoid = character:FindFirstChildOfClass("Humanoid")

            if humanoid and humanoid.Health > 0 then
                -- Calculate distance first for max distance check
                local distance = (localPosition - rootPart.Position).Magnitude
                
                -- NEW: Check max distance
                if getgenv().maxDistanceEnabled and distance > getgenv().maxDistance then
                    -- Hide all ESP elements if beyond max distance
                    for _, obj in pairs(objects) do
                        if type(obj) == "table" then
                            for _, corner in pairs(obj) do
                                corner.Visible = false
                            end
                        elseif obj then
                            obj.Visible = false
                        end
                    end
                    continue
                end
                
                local rootPosition, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                
                if onScreen then
                    local headPosition = Camera:WorldToViewportPoint(rootPart.Position + Vector3.new(0, 3, 0))
                    local footPosition = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))
                    
                    local boxHeight = math.abs(headPosition.Y - footPosition.Y)
                    local boxWidth = boxHeight / 2
                    local barWidth = 3

                    -- IMPROVED Box ESP with filled option
                    if getgenv().boxESPEnabled and objects.Box then
                        if getgenv().boxStyle == "Normal" then
                            local boxPos = Vector2.new(rootPosition.X - boxWidth / 2, headPosition.Y)
                            local boxSize = Vector2.new(boxWidth, boxHeight)
                            
                            -- Draw filled box first (if enabled)
                            if getgenv().boxFilled and objects.BoxFilled then
                                objects.BoxFilled.Position = boxPos
                                objects.BoxFilled.Size = boxSize
                                objects.BoxFilled.Color = getgenv().espColor
                                objects.BoxFilled.Transparency = getgenv().boxTransparency
                                objects.BoxFilled.Visible = true
                            end
                            
                            -- Draw the black border outline
                            objects.BoxOutline.Position = boxPos
                            objects.BoxOutline.Size = boxSize
                            objects.BoxOutline.Color = Color3.new(0, 0, 0)
                            objects.BoxOutline.Visible = true
                            
                            -- Draw the main colored box outline on top
                            objects.Box.Position = boxPos
                            objects.Box.Size = boxSize
                            objects.Box.Color = getgenv().espColor
                            objects.Box.Visible = true
                            
                            if objects.CornerBox then
                                for _, corner in pairs(objects.CornerBox) do
                                    corner.Visible = false
                                end
                            end
                        elseif getgenv().boxStyle == "Corners" and objects.CornerBox then
                            objects.Box.Visible = false
                            objects.BoxOutline.Visible = false
                            if objects.BoxFilled then
                                objects.BoxFilled.Visible = false
                            end
                            
                            UpdateCornerBox(objects.CornerBox, Vector2.new(rootPosition.X - boxWidth / 2, headPosition.Y), Vector2.new(boxWidth, boxHeight))
                            for _, corner in pairs(objects.CornerBox) do
                                corner.Color = getgenv().espColor
                                corner.Visible = true
                            end
                        end
                    end

                    -- Name ESP
                    if getgenv().nameESPEnabled and objects.Username then
                        local displayName
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
                        objects.Username.Font = fontMap[getgenv().textStyle] or fontMap["SourceSans"]
                        objects.Username.Visible = true
                        objects.Username.Color = getgenv().nameColor
                        objects.Username.Outline = getgenv().outlineEnabled
                    end

                    -- Distance ESP
                    if getgenv().studsESPEnabled and objects.Distance then
                        local distanceText = math.floor(distance) .. " studs"
                        objects.Distance.Position = Vector2.new(rootPosition.X, footPosition.Y + 5)
                        objects.Distance.Text = distanceText
                        objects.Distance.Size = getgenv().distanceTextSize
                        objects.Distance.Font = fontMap[getgenv().textStyle] or fontMap["SourceSans"]
                        objects.Distance.Visible = true
                        objects.Distance.Color = getgenv().distanceColor
                        objects.Distance.Outline = getgenv().outlineEnabled
                    end

                    -- FIXED: Health Bar ESP with proper border
                    if getgenv().healthBarESP and objects.HealthBar then
                        local targetHealthRatio = humanoid.Health / humanoid.MaxHealth
                        
                        if not currentHealthValues[player] then
                            currentHealthValues[player] = targetHealthRatio
                        else
                            currentHealthValues[player] = currentHealthValues[player] + (targetHealthRatio - currentHealthValues[player]) * getgenv().healthSmoothness
                        end
                        
                        local healthRatio = currentHealthValues[player]
                        local barHeight = boxHeight * healthRatio
                        local barX = rootPosition.X - boxWidth / 1.9 - barWidth - 1
                        
                        -- Health bar background
                        objects.HealthBarBackground.Position = Vector2.new(barX, headPosition.Y)
                        objects.HealthBarBackground.Size = Vector2.new(barWidth, boxHeight)
                        objects.HealthBarBackground.Color = getgenv().healthBarBackground
                        objects.HealthBarBackground.Visible = true
                        
                        -- Health bar foreground
                        objects.HealthBar.Position = Vector2.new(barX, headPosition.Y + (boxHeight - barHeight))
                        objects.HealthBar.Size = Vector2.new(barWidth, barHeight)
                        objects.HealthBar.Color = getgenv().healthBarColor
                        objects.HealthBar.Visible = true

                        -- Health bar outline (border)
                        if objects.HealthBarOutline then
                            objects.HealthBarOutline.Position = Vector2.new(barX, headPosition.Y)
                            objects.HealthBarOutline.Size = Vector2.new(barWidth, boxHeight)
                            objects.HealthBarOutline.Color = Color3.new(0, 0, 0)
                            objects.HealthBarOutline.Visible = true
                        end
                    end

                    -- Weapon ESP
                    if getgenv().weaponESPEnabled and objects.Weapon then
                        local tool = character:FindFirstChildOfClass("Tool")
                        if tool then
                            objects.Weapon.Position = Vector2.new(rootPosition.X, footPosition.Y + 20)
                            objects.Weapon.Text = tool.Name
                            objects.Weapon.Size = getgenv().nameTextSize
                            objects.Weapon.Font = fontMap[getgenv().textStyle] or fontMap["SourceSans"]
                            objects.Weapon.Visible = true
                            objects.Weapon.Color = getgenv().weaponColor
                            objects.Weapon.Outline = getgenv().outlineEnabled
                        else
                            objects.Weapon.Visible = false
                        end
                    end

                    -- FIXED: Armor Bar ESP with proper border
                    if getgenv().armorBarESP and objects.ArmorBar then
                        local dataFolder = player:FindFirstChild("DataFolder")
                        local armorRatio = 0
                        
                        if dataFolder then
                            local information = dataFolder:FindFirstChild("Information")
                            if information then
                                local armorSave = information:FindFirstChild("ArmorSave")
                                if armorSave then
                                    armorRatio = armorSave.Value / 130
                                end
                            end
                        end
                        
                        if not currentArmorValues[player] then
                            currentArmorValues[player] = armorRatio
                        else
                            currentArmorValues[player] = currentArmorValues[player] + (armorRatio - currentArmorValues[player]) * getgenv().healthSmoothness
                        end
                        
                        local smoothArmorRatio = currentArmorValues[player]
                        local armorHeight = boxHeight * smoothArmorRatio
                        local armorX = rootPosition.X - boxWidth / 1.9 - barWidth - barWidth - 3
                        
                        -- Armor bar background
                        objects.ArmorBarBackground.Position = Vector2.new(armorX, headPosition.Y)
                        objects.ArmorBarBackground.Size = Vector2.new(barWidth, boxHeight)
                        objects.ArmorBarBackground.Color = getgenv().armorBarBackground
                        objects.ArmorBarBackground.Visible = true
                        
                        -- Armor bar foreground
                        objects.ArmorBar.Position = Vector2.new(armorX, headPosition.Y + (boxHeight - armorHeight))
                        objects.ArmorBar.Size = Vector2.new(barWidth, armorHeight)
                        objects.ArmorBar.Color = getgenv().armorBarColor
                        objects.ArmorBar.Visible = true
                    
                        -- Armor bar outline (border)
                        if objects.ArmorBarOutline then
                            objects.ArmorBarOutline.Position = Vector2.new(armorX, headPosition.Y)
                            objects.ArmorBarOutline.Size = Vector2.new(barWidth, boxHeight)
                            objects.ArmorBarOutline.Color = Color3.new(0, 0, 0)
                            objects.ArmorBarOutline.Visible = true
                        end
                    end

                    -- Penis ESP
                    if getgenv().penisESPEnabled and objects.PenisLine then
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
                    end
                    
                    -- Update highlight if it doesn't exist but should
                    if getgenv().highlightEnabled and not HighlightObjects[player] then
                        CreateHighlight(player)
                    end
                else
                    -- Hide all ESP elements if off-screen
                    for _, obj in pairs(objects) do
                        if type(obj) == "table" then
                            for _, corner in pairs(obj) do
                                corner.Visible = false
                            end
                        elseif obj then
                            obj.Visible = false
                        end
                    end
                end
            else
                -- Character is dead, destroy highlight
                DestroyHighlight(player)
            end
        end
    end
end

-- OPTIMIZED: Function to apply ESP settings with proper cleanup
function applyESP()
    if not getgenv().espEnabled then
        -- Destroy all ESP when disabled
        for player, _ in pairs(ESPObjects) do
            DestroyESP(player)
            task.wait()
        end
        return
    end
    
    -- Recreate ESP for all players when enabled
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            CreateESP(player)
            task.wait()
        end
    end
end

-- Function to apply highlight settings (IMPROVED)
function applyHighlight()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if getgenv().highlightEnabled and player.Character then
                CreateHighlight(player)
            else
                DestroyHighlight(player)
            end
            task.wait()
        end
    end
end

-- Player Added/Removed Events
Players.PlayerAdded:Connect(function(player)
    local function onCharacterAdded(character)
        OnCharacterAdded(player, character)
    end
    
    if player.Character then
        onCharacterAdded(player.Character)
    end
    
    player.CharacterAdded:Connect(onCharacterAdded)
end)

Players.PlayerRemoving:Connect(function(player)
    DestroyESP(player)
end)

-- Initialize ESP for existing players
for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESP(player)
        
        player.CharacterAdded:Connect(function(character)
            OnCharacterAdded(player, character)
        end)
    end
    task.wait()
end

-- Update ESP on every frame
RunService.RenderStepped:Connect(function()
    UpdateESP()
    task.wait()
end)

-- UI for ESP Settings
local espUI = Tabs.Visuals:AddLeftGroupbox('ESP')

-- TOGGLES SECTION
espUI:AddToggle("ESPEnabled", {
    Text = "Enable ESP",
    Default = false,
    Callback = function(value)
        getgenv().espEnabled = value
        applyESP()
    end
})

espUI:AddToggle("MaxDistanceEnabled", {
    Text = "Max Distance",
    Default = false,
    Callback = function(value)
        getgenv().maxDistanceEnabled = value
    end
})

espUI:AddToggle("BoxESPEnabled", {
    Text = "Box ESP",
    Default = false,
    Callback = function(value)
        getgenv().boxESPEnabled = value
        applyESP()
    end
}):AddColorPicker("ESPColor", {
    Text = "Box Color",
    Default = getgenv().espColor,
    Callback = function(value)
        getgenv().espColor = value
        applyESP()
    end
})

espUI:AddToggle("BoxFillEnable", {
    Text = "Box Fill",
    Default = false,
    Callback = function(value)
        getgenv().boxFilled = value
        applyESP()
    end
})

espUI:AddToggle("HighlightEnabled", {
    Text = "Player Highlight",
    Default = false,
    Callback = function(value)
        getgenv().highlightEnabled = value
        applyHighlight()
    end
}):AddColorPicker("HighlightFillColor", {
    Text = "Fill Color",
    Default = getgenv().highlightFillColor,
    Callback = function(value)
        getgenv().highlightFillColor = value
        applyHighlight()
    end
})

espUI:AddLabel("Highlight Outline"):AddColorPicker("HighlightOutlineColor", {
    Default = getgenv().highlightOutlineColor,
    Callback = function(value)
        getgenv().highlightOutlineColor = value
        applyHighlight()
    end
})

espUI:AddToggle("name", {
    Text = "Names",
    Default = false,
    Callback = function(value)
        getgenv().nameESPEnabled = value
        applyESP()
    end
}):AddColorPicker("NameColor", {
    Text = "Name Color",
    Default = getgenv().nameColor,
    Callback = function(value)
        getgenv().nameColor = value
        applyESP()
    end
})

espUI:AddToggle("HealthBarESP", {
    Text = "Health Bar",
    Default = false,
    Callback = function(value)
        getgenv().healthBarESP = value
        applyESP()
    end
}):AddColorPicker("HealthBarColor", {
    Text = "Health Bar Color",
    Default = getgenv().healthBarColor,
    Callback = function(value)
        getgenv().healthBarColor = value
        applyESP()
    end
})

espUI:AddLabel("Health Bar Background"):AddColorPicker("HealthBarBgColor", {
    Default = getgenv().healthBarBackground,
    Callback = function(value)
        getgenv().healthBarBackground = value
        applyESP()
    end
})

espUI:AddToggle("StudsESPEnabled", {
    Text = "Distance",
    Default = false,
    Callback = function(value)
        getgenv().studsESPEnabled = value
        applyESP()
    end
}):AddColorPicker("DistanceColor", {
    Text = "Distance Color",
    Default = getgenv().distanceColor,
    Callback = function(value)
        getgenv().distanceColor = value
        applyESP()
    end
})

espUI:AddToggle("WeaponESPEnabled", {
    Text = "Weapon ESP",
    Default = false,
    Callback = function(value)
        getgenv().weaponESPEnabled = value
        applyESP()
    end
}):AddColorPicker("WeaponColor", {
    Text = "Weapon Color",
    Default = getgenv().weaponColor,
    Callback = function(value)
        getgenv().weaponColor = value
        applyESP()
    end
})

espUI:AddToggle("ArmorBarESP", {
    Text = "Armor Bar",
    Default = false,
    Callback = function(value)
        getgenv().armorBarESP = value
        applyESP()
    end
}):AddColorPicker("ArmorBarColor", {
    Text = "Armor Bar Color",
    Default = getgenv().armorBarColor,
    Callback = function(value)
        getgenv().armorBarColor = value
        applyESP()
    end
})

espUI:AddLabel("Armor Bar Background"):AddColorPicker("ArmorBarBgColor", {
    Default = getgenv().armorBarBackground,
    Callback = function(value)
        getgenv().armorBarBackground = value
        applyESP()
    end
})

espUI:AddToggle("OutlineEnabled", {
    Text = "Outline",
    Default = false,
    Callback = function(value)
        getgenv().outlineEnabled = value
        applyESP()
    end
})

espUI:AddToggle("PenisESPEnabled", {
    Text = "Penis ESP",
    Default = false,
    Callback = function(value)
        getgenv().penisESPEnabled = value
        applyESP()
    end
}):AddColorPicker("PenisColor", {
    Text = "Penis Color",
    Default = getgenv().penisColor,
    Callback = function(value)
        getgenv().penisColor = value
        applyESP()
    end
})

-- SLIDERS SECTION
espUI:AddSlider("MaxDistance", {
    Text = "Max Distance (Studs)",
    Min = 100,
    Max = 5000,
    Default = 1000,
    Rounding = 0,
    Callback = function(value)
        getgenv().maxDistance = value
    end
})

espUI:AddSlider("boxFillTransparency", {
    Text = "boxFillTransparency",
    Min = 0,
    Max = 1,
    Default = 0.65,
    Rounding = 2,
    Callback = function(value)
        getgenv().boxTransparency = value
    end
})

espUI:AddSlider("HealthSmoothness", {
    Text = "Health Smoothness",
    Min = 0.01,
    Max = 0.5,
    Default = 0.1,
    Rounding = 2,
    Callback = function(value)
        getgenv().healthSmoothness = value
    end
})

-- DROPDOWNS SECTION
espUI:AddDropdown("BoxStyle", {
    Text = "Box Style",
    Values = {"Normal", "Corners"},
    Default = "Normal",
    Callback = function(value)
        getgenv().boxStyle = value
        applyESP()
    end
})

espUI:AddDropdown("NameDisplayMode", {
    Text = "Name Mode",
    Values = {"Username", "DisplayName", "Username (DisplayName)", "Username (DisplayName) [UserID]"},
    Default = "Username",
    Callback = function(value)
        getgenv().nameDisplayMode = value
        applyESP()
    end
})

espUI:AddDropdown("TextStyle", {
    Text = "Text Style",
    Values = {"SourceSans", "SourceSansBold", "SourceSansItalic", "SourceSansLight", "SourceSansSemibold", "Gotham", "GothamBold", "GothamMedium", "GothamSemibold", "Minecraft", "MinecraftBold"},
    Default = "SourceSans",
    Callback = function(value)
        getgenv().textStyle = value
        applyESP()
    end
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local HudUi = Tabs.Visuals:AddLeftGroupbox('Hud Changer')

-- HUD Variables (keeping your original HUD functionality)
local defaultTextHP = " Health "
local defaultTextArmor = "                   Armor"
local defaultTextEnergy = "Dark Energy              "

local defaultColorHP = Color3.new(0.941176, 0.031373, 0.819608)
local defaultColorArmor = Color3.new(0.376471, 0.031373, 0.933333)
local defaultColorEnergy = Color3.new(0.768627, 0.039216, 0.952941)

local textHP, textArmor, textEnergy = defaultTextHP, defaultTextArmor, defaultTextEnergy
local colorHP, colorArmor, colorEnergy = defaultColorHP, defaultColorArmor, defaultColorEnergy
local toggleHP, toggleArmor, toggleEnergy = false, false, false

-- Crosshair Spin Variables
local spinEnabled = false
local spinSpeed = 1
local spinConnection = nil
local currentRotation = 0

-- Get the crosshair GUI path
local function getCrosshairGui()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local mainGui = playerGui:WaitForChild("MainScreenGui")
    return mainGui:WaitForChild("Aim")
end

-- HUD update function (your original skibiditoilet function)
local function updateHUD()
    local player = game.Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local gui = playerGui:WaitForChild("MainScreenGui").Bar
    
    if toggleHP then
        gui.HP.TextLabel.Text = textHP
        gui.HP.bar.BackgroundColor3 = colorHP
    end
    
    if toggleArmor then
        gui.Armor.TextLabel.Text = textArmor
        gui.Armor.bar.BackgroundColor3 = colorArmor
    end
    
    if toggleEnergy then
        gui.Energy.TextLabel.Text = textEnergy
        gui.Energy.bar.BackgroundColor3 = colorEnergy
    end
end

-- Function to apply rotation to the crosshair
local function applyCrosshairRotation(aimGui, rotation)
    if not aimGui then return end
    
    -- Directly rotate the entire Aim GUI
    aimGui.Rotation = rotation
end

-- Function to start/stop spinning
local function updateSpin()
    -- Disconnect existing connection
    if spinConnection then
        spinConnection:Disconnect()
        spinConnection = nil
    end
    
    if spinEnabled then
        -- Start spinning
        spinConnection = RunService.Heartbeat:Connect(function(deltaTime)
            if spinEnabled then
                currentRotation = currentRotation + (spinSpeed * 360 * deltaTime)
                if currentRotation >= 360 then
                    currentRotation = currentRotation - 360
                end
                
                -- Apply rotation to crosshair
                local success, aimGui = pcall(getCrosshairGui)
                if success and aimGui then
                    applyCrosshairRotation(aimGui, currentRotation)
                end
            end
        end)
    else
        -- Reset rotation when disabled
        currentRotation = 0
        local success, aimGui = pcall(getCrosshairGui)
        if success and aimGui then
            aimGui.Rotation = 0
        end
    end
end

-- HUD Controls (keeping your original HUD functionality)
HudUi:AddToggle('ToggleHP', {
    Text = 'Customize Health',
    Default = false,
    Callback = function(state)
        toggleHP = state
        updateHUD()
    end
}):AddColorPicker('ColorHP', {
    Text = 'Health Color',
    Default = defaultColorHP,
    Callback = function(value)
        if toggleHP then 
            colorHP = value 
            updateHUD() 
        end
    end
})

HudUi:AddInput('TextHP', {
    Text = 'Health Text',
    Default = defaultTextHP,
    Callback = function(value)
        if toggleHP then 
            textHP = value 
            updateHUD() 
        end
    end
})

HudUi:AddToggle('ToggleArmor', {
    Text = 'Customize Armor',
    Default = false,
    Callback = function(state)
        toggleArmor = state
        updateHUD()
    end
}):AddColorPicker('ColorArmor', {
    Text = 'Armor Color',
    Default = defaultColorArmor,
    Callback = function(value)
        if toggleArmor then 
            colorArmor = value 
            updateHUD() 
        end
    end
})

HudUi:AddInput('TextArmor', {
    Text = 'Armor Text',
    Default = defaultTextArmor,
    Callback = function(value)
        if toggleArmor then 
            textArmor = value 
            updateHUD() 
        end
    end
})

HudUi:AddToggle('ToggleEnergy', {
    Text = 'Customize Energy',
    Default = false,
    Callback = function(state)
        toggleEnergy = state
        updateHUD()
    end
}):AddColorPicker('ColorEnergy', {
    Text = 'Energy Color',
    Default = defaultColorEnergy,
    Callback = function(value)
        if toggleEnergy then 
            colorEnergy = value 
            updateHUD() 
        end
    end
})

HudUi:AddInput('TextEnergy', {
    Text = 'Energy Text',
    Default = defaultTextEnergy,
    Callback = function(value)
        if toggleEnergy then 
            textEnergy = value 
            updateHUD() 
        end
    end
})

-- Crosshair Spin Controls (simplified and focused)
HudUi:AddToggle('SpinToggle', {
    Text = 'Spin Crosshair',
    Default = false,
    Callback = function(state)
        spinEnabled = state
        updateSpin()
    end
})

HudUi:AddSlider('SpinSpeed', {
    Text = 'Spin Speed',
    Min = 0.1,
    Max = 5,
    Default = 1,
    Rounding = 1,
    Callback = function(value)
        spinSpeed = value
    end
})

-- Character respawn handling
local player = game.Players.LocalPlayer

player.CharacterAdded:Connect(function()
    if toggleHP or toggleArmor or toggleEnergy then
        player:WaitForChild("PlayerGui")
        skibiditoilet()
    end
    
    spawn(function()
        wait(2)
        storeOriginalPositions()
        if crosshairEnabled then
            updateCrosshair()
        end
    end)
end)

-- Handle camera viewport changes
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    if crosshairEnabled then
        -- Just let the heartbeat connection handle it
    end
end)

-- Clean up when player leaves
player.AncestryChanged:Connect(function()
    if not player.Parent then
        if crosshairConnection then crosshairConnection:Disconnect() end
        if spinConnection then spinConnection:Disconnect() end
        if mouseConnection then mouseConnection:Disconnect() end
        customCrosshairGui:Destroy()
    end
end)

-- Initialize on script load
spawn(function()
    wait(1)
    storeOriginalPositions()
end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local Auras = Tabs.Visuals:AddRightGroupbox("Self")
utility = utility or {}

local Settings = {
    Visuals = {
        SelfESP = {
            Trail = {
                Color = Color3.fromRGB(255, 110, 0),
                Color2 = Color3.fromRGB(255, 0, 0),
                LifeTime = 1.6,
                Width = 0.1
            },
            Aura = {
                Color = Color3.fromRGB(152, 0, 252)
            },
            Footsteps = {
                Enabled = false,
                Style = "Energy Pulse", -- Options: "Energy Pulse", "Fire Steps", "Ice Crystals", "Electric Sparks", "Divine Light"
                Color = Color3.fromRGB(0, 255, 255),
                Color2 = Color3.fromRGB(0, 150, 255),
                Lifetime = 2,
                Size = 0.5,
                SpawnRate = 0.3,
                FadeTime = 1.5,
                Intensity = 0.5,
            }
        }
    }
}

-- Trail function (keeping original)
utility.trail_character = function(Bool)
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    if Bool then
        if not humanoidRootPart:FindFirstChild("BlaBla") then
            local BlaBla = Instance.new("Trail", humanoidRootPart)
            BlaBla.Name = "BlaBla"
            humanoidRootPart.Material = Enum.Material.Neon

            local attachment0 = Instance.new("Attachment", humanoidRootPart)
            attachment0.Position = Vector3.new(0, 1, 0)

            local attachment1 = Instance.new("Attachment", humanoidRootPart)
            attachment1.Position = Vector3.new(0, -1, 0)

            BlaBla.Attachment0 = attachment0
            BlaBla.Attachment1 = attachment1
            BlaBla.Color = ColorSequence.new(Settings.Visuals.SelfESP.Trail.Color, Settings.Visuals.SelfESP.Trail.Color2)
            BlaBla.Lifetime = Settings.Visuals.SelfESP.Trail.LifeTime
            BlaBla.Transparency = NumberSequence.new(0, 0)
            BlaBla.LightEmission = 0.2
            BlaBla.Brightness = 10
            BlaBla.WidthScale = NumberSequence.new{
                NumberSequenceKeypoint.new(0, Settings.Visuals.SelfESP.Trail.Width),
                NumberSequenceKeypoint.new(1, 0)
            }
        end
    else
        for _, child in ipairs(humanoidRootPart:GetChildren()) do
            if child:IsA("Trail") and child.Name == 'BlaBla' then
                child:Destroy()
            end
        end
    end
end

-- Enhanced Multiple Footstep Systems
local footprints = {}
local lastFootprintTime = 0
local lastFootRight = false

-- Energy Pulse Footsteps
local function createEnergyPulseFootstep(footPosition, isRightFoot)
    local footprint = Instance.new("Part")
    footprint.Anchored = true
    footprint.CanCollide = false
    footprint.Transparency = 1
    footprint.Size = Vector3.new(2, 0.1, 2) * Settings.Visuals.SelfESP.Footsteps.Size
    footprint.Position = footPosition + Vector3.new(0, 0.05, 0)
    footprint.Material = Enum.Material.Neon
    footprint.Parent = workspace.Terrain
    
    local attachment = Instance.new("Attachment", footprint)
    
    -- Central energy burst
    local burst = Instance.new("ParticleEmitter", attachment)
    burst.Lifetime = NumberRange.new(0.8, 1.2)
    burst.SpreadAngle = Vector2.new(360, 360)
    burst.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.3, 0.2),
        NumberSequenceKeypoint.new(1, 1)
    })
    burst.LightEmission = 1
    burst.Color = ColorSequence.new(Settings.Visuals.SelfESP.Footsteps.Color)
    burst.Speed = NumberRange.new(5, 12)
    burst.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(0.5, 1),
        NumberSequenceKeypoint.new(1, 0)
    })
    burst.Rate = 100
    burst.EmissionDirection = Enum.NormalId.Top
    burst.VelocityInheritance = 0
    burst.Texture = "rbxassetid://8997386535"
    
    -- Shockwave ring
    local shockwave = Instance.new("ParticleEmitter", attachment)
    shockwave.Lifetime = NumberRange.new(1.5, 2)
    shockwave.SpreadAngle = Vector2.new(0, 0)
    shockwave.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(0.8, 0.8),
        NumberSequenceKeypoint.new(1, 1)
    })
    shockwave.LightEmission = 0.8
    shockwave.Color = ColorSequence.new(Settings.Visuals.SelfESP.Footsteps.Color2)
    shockwave.Speed = NumberRange.new(0)
    shockwave.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.3, 8),
        NumberSequenceKeypoint.new(1, 12)
    })
    shockwave.Rate = 5
    shockwave.Texture = "rbxassetid://3358479745"
    
    local pointLight = Instance.new("PointLight", footprint)
    pointLight.Color = Settings.Visuals.SelfESP.Footsteps.Color
    pointLight.Range = 5
    pointLight.Brightness = 2
    
    -- Stop emitting after short burst
    wait(0.1)
    burst.Enabled = false
    shockwave.Enabled = false
    
    table.insert(footprints, {
        instance = footprint,
        creationTime = tick(),
        lifetime = Settings.Visuals.SelfESP.Footsteps.Lifetime
    })
    
    return footprint
end

-- Fire Steps
local function createFireFootstep(footPosition, isRightFoot)
    local footprint = Instance.new("Part")
    footprint.Anchored = true
    footprint.CanCollide = false
    footprint.Transparency = 1
    footprint.Size = Vector3.new(1.5, 0.1, 2) * Settings.Visuals.SelfESP.Footsteps.Size
    footprint.Position = footPosition + Vector3.new(0, 0.05, 0)
    footprint.Parent = workspace.Terrain
    
    local attachment = Instance.new("Attachment", footprint)
    
    -- Fire flames
    local fire = Instance.new("ParticleEmitter", attachment)
    fire.Lifetime = NumberRange.new(1, 2)
    fire.SpreadAngle = Vector2.new(45, 45)
    fire.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(0.7, 0.8),
        NumberSequenceKeypoint.new(1, 1)
    })
    fire.LightEmission = 0.5
    fire.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 165, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 0))
    })
    fire.Speed = NumberRange.new(2, 5)
    fire.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(0.5, 0.8),
        NumberSequenceKeypoint.new(1, 0)
    })
    fire.Rate = 50
    fire.EmissionDirection = Enum.NormalId.Top
    fire.Acceleration = Vector3.new(0, 5, 0)
    fire.Texture = "rbxassetid://241650934"
    
    -- Embers
    local embers = Instance.new("ParticleEmitter", attachment)
    embers.Lifetime = NumberRange.new(2, 3)
    embers.SpreadAngle = Vector2.new(80, 80)
    embers.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.8, 0.5),
        NumberSequenceKeypoint.new(1, 1)
    })
    embers.LightEmission = 1
    embers.Color = ColorSequence.new(Color3.fromRGB(255, 100, 0))
    embers.Speed = NumberRange.new(1, 3)
    embers.Size = NumberSequence.new(0.1, 0.05)
    embers.Rate = 20
    embers.Texture = "rbxassetid://241685484"
    
    wait(0.2)
    fire.Enabled = false
    embers.Enabled = false
    
    table.insert(footprints, {
        instance = footprint,
        creationTime = tick(),
        lifetime = Settings.Visuals.SelfESP.Footsteps.Lifetime
    })
    
    return footprint
end

-- Ice Crystal Steps
local function createIceFootstep(footPosition, isRightFoot)
    local footprint = Instance.new("Part")
    footprint.Anchored = true
    footprint.CanCollide = false
    footprint.Transparency = 1
    footprint.Size = Vector3.new(2, 0.1, 2) * Settings.Visuals.SelfESP.Footsteps.Size
    footprint.Position = footPosition + Vector3.new(0, 0.05, 0)
    footprint.Parent = workspace.Terrain
    
    local attachment = Instance.new("Attachment", footprint)
    
    -- Ice crystals
    local crystals = Instance.new("ParticleEmitter", attachment)
    crystals.Lifetime = NumberRange.new(2, 3)
    crystals.SpreadAngle = Vector2.new(60, 60)
    crystals.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(0.5, 0.1),
        NumberSequenceKeypoint.new(1, 1)
    })
    crystals.LightEmission = 0.8
    crystals.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 200, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
    })
    crystals.Speed = NumberRange.new(1, 4)
    crystals.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(0.3, 0.5),
        NumberSequenceKeypoint.new(1, 0.1)
    })
    crystals.Rate = 30
    crystals.Texture = "rbxassetid://8997386535"
    crystals.RotSpeed = NumberRange.new(-50, 50)
    
    -- Frost mist
    local mist = Instance.new("ParticleEmitter", attachment)
    mist.Lifetime = NumberRange.new(1.5, 2.5)
    mist.SpreadAngle = Vector2.new(90, 90)
    mist.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.8),
        NumberSequenceKeypoint.new(0.5, 0.6),
        NumberSequenceKeypoint.new(1, 1)
    })
    mist.LightEmission = 0.3
    mist.Color = ColorSequence.new(Color3.fromRGB(200, 230, 255))
    mist.Speed = NumberRange.new(0.5, 2)
    mist.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 2),
        NumberSequenceKeypoint.new(1, 3)
    })
    mist.Rate = 15
    mist.Texture = "rbxassetid://241650934"
    
    wait(0.3)
    crystals.Enabled = false
    mist.Enabled = false
    
    table.insert(footprints, {
        instance = footprint,
        creationTime = tick(),
        lifetime = Settings.Visuals.SelfESP.Footsteps.Lifetime
    })
    
    return footprint
end

-- Electric Spark Steps
local function createElectricFootstep(footPosition, isRightFoot)
    local footprint = Instance.new("Part")
    footprint.Anchored = true
    footprint.CanCollide = false
    footprint.Transparency = 1
    footprint.Size = Vector3.new(1.5, 0.1, 1.5) * Settings.Visuals.SelfESP.Footsteps.Size
    footprint.Position = footPosition + Vector3.new(0, 0.05, 0)
    footprint.Parent = workspace.Terrain
    
    local attachment = Instance.new("Attachment", footprint)
    
    -- Lightning bolts
    local lightning = Instance.new("ParticleEmitter", attachment)
    lightning.Lifetime = NumberRange.new(0.3, 0.6)
    lightning.SpreadAngle = Vector2.new(360, 360)
    lightning.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.5, 0.3),
        NumberSequenceKeypoint.new(1, 1)
    })
    lightning.LightEmission = 1
    lightning.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 200, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
    })
    lightning.Speed = NumberRange.new(0)
    lightning.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 2),
        NumberSequenceKeypoint.new(0.5, 3),
        NumberSequenceKeypoint.new(1, 1)
    })
    lightning.Rate = 80
    lightning.Texture = "rbxassetid://1084955012"
    lightning.Rotation = NumberRange.new(-180, 180)
    
    -- Electric sparks
    local sparks = Instance.new("ParticleEmitter", attachment)
    sparks.Lifetime = NumberRange.new(0.5, 1)
    sparks.SpreadAngle = Vector2.new(360, 360)
    sparks.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.8, 0.5),
        NumberSequenceKeypoint.new(1, 1)
    })
    sparks.LightEmission = 1
    sparks.Color = ColorSequence.new(Color3.fromRGB(0, 255, 255))
    sparks.Speed = NumberRange.new(3, 8)
    sparks.Size = NumberSequence.new(0.1, 0.05)
    sparks.Rate = 60
    sparks.Texture = "rbxassetid://241685484"
    
    wait(0.15)
    lightning.Enabled = false
    sparks.Enabled = false
    
    table.insert(footprints, {
        instance = footprint,
        creationTime = tick(),
        lifetime = Settings.Visuals.SelfESP.Footsteps.Lifetime
    })
    
    return footprint
end

-- Divine Light Steps
local function createDivineFootstep(footPosition, isRightFoot)
    local footprint = Instance.new("Part")
    footprint.Anchored = true
    footprint.CanCollide = false
    footprint.Transparency = 1
    footprint.Size = Vector3.new(2.5, 0.1, 2.5) * Settings.Visuals.SelfESP.Footsteps.Size
    footprint.Position = footPosition + Vector3.new(0, 0.05, 0)
    footprint.Parent = workspace.Terrain
    
    local attachment = Instance.new("Attachment", footprint)
    
    -- Divine rays
    local rays = Instance.new("ParticleEmitter", attachment)
    rays.Lifetime = NumberRange.new(2, 3)
    rays.SpreadAngle = Vector2.new(15, 15)
    rays.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(0.5, 0.1),
        NumberSequenceKeypoint.new(1, 1)
    })
    rays.LightEmission = 1
    rays.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 200)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 100))
    })
    rays.Speed = NumberRange.new(3, 8)
    rays.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(0.3, 1.5),
        NumberSequenceKeypoint.new(1, 0.2)
    })
    rays.Rate = 25
    rays.EmissionDirection = Enum.NormalId.Top
    rays.Texture = "rbxassetid://8997386535"
    
    -- Holy circle
    local circle = Instance.new("ParticleEmitter", attachment)
    circle.Lifetime = NumberRange.new(1.5, 2)
    circle.SpreadAngle = Vector2.new(0, 0)
    circle.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(0.8, 0.6),
        NumberSequenceKeypoint.new(1, 1)
    })
    circle.LightEmission = 0.9
    circle.Color = ColorSequence.new(Color3.fromRGB(255, 255, 150))
    circle.Speed = NumberRange.new(0)
    circle.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.3, 6),
        NumberSequenceKeypoint.new(1, 8)
    })
    circle.Rate = 3
    circle.Texture = "rbxassetid://3358479745"
    circle.RotSpeed = NumberRange.new(10, 30)
    
    wait(0.2)
    rays.Enabled = false
    circle.Enabled = false
    
    table.insert(footprints, {
        instance = footprint,
        creationTime = tick(),
        lifetime = Settings.Visuals.SelfESP.Footsteps.Lifetime
    })
    
    return footprint
end

local footstepCreators = {
    ["Energy Pulse"] = createEnergyPulseFootstep,
    ["Fire Steps"] = createFireFootstep,
    ["Ice Crystals"] = createIceFootstep,
    ["Electric Sparks"] = createElectricFootstep,
    ["Divine Light"] = createDivineFootstep
}

local function manageFootprints()
    local currentTime = tick()
    local i = 1
    
    while i <= #footprints do
        local footprintData = footprints[i]
        local age = currentTime - footprintData.creationTime
        
        if age >= footprintData.lifetime then
            if footprintData.instance and footprintData.instance.Parent then
                footprintData.instance:Destroy()
            end
            table.remove(footprints, i)
        else
            i = i + 1
        end
    end
end

local function updateFootprints()
    if not Settings.Visuals.SelfESP.Footsteps.Enabled then return end
    
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart or humanoid:GetState() == Enum.HumanoidStateType.Dead then return end
    
    if humanoid.MoveDirection.Magnitude > 0.1 and humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
        local currentTime = tick()
        
        if currentTime - lastFootprintTime >= Settings.Visuals.SelfESP.Footsteps.SpawnRate then
            lastFootprintTime = currentTime
            lastFootRight = not lastFootRight
            
            local forward = rootPart.CFrame.LookVector
            local right = rootPart.CFrame.RightVector
            
            local footOffset = right * (lastFootRight and 0.3 or -0.3) + forward * (lastFootRight and -0.1 or 0.1)
            local footPosition = (rootPart.Position + footOffset) - Vector3.new(0, 3, 0)
            
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {character}
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            
            local rayResult = workspace:Raycast(footPosition + Vector3.new(0, 2, 0), Vector3.new(0, -10, 0), rayParams)
            
            if rayResult then
                local creator = footstepCreators[Settings.Visuals.SelfESP.Footsteps.Style]
                if creator then
                    creator(rayResult.Position, lastFootRight)
                end
            end
        end
    end
    
    manageFootprints()
end

local footprintConnection = nil

local function toggleFootprints(enabled)
    Settings.Visuals.SelfESP.Footsteps.Enabled = enabled
    
    if enabled then
        if not footprintConnection then
            footprintConnection = RunService.Heartbeat:Connect(updateFootprints)
        end
    else
        if footprintConnection then
            footprintConnection:Disconnect()
            footprintConnection = nil
        end
        
        for _, footprintData in ipairs(footprints) do
            if footprintData.instance and footprintData.instance.Parent then
                footprintData.instance:Destroy()
            end
        end
        footprints = {}
    end
end

-- ENHANCED FULL BODY ENERGY AURA - Multi-layered like in your image

local function createEnhancedFullBodyAura(character)
    local bodyParts = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}
    local auraEffects = {}
    
    for _, partName in ipairs(bodyParts) do
        local part = character:FindFirstChild(partName)
        if part then
            -- Main attachment
            local attachment = Instance.new("Attachment")
            attachment.Name = "EnhancedFullBodyAura"
            attachment.Parent = part
            
            -- Layer 1: Inner Energy Core
            local innerCore = Instance.new("ParticleEmitter", attachment)
            innerCore.Name = "InnerCore"
            innerCore.Lifetime = NumberRange.new(1.5, 2.5)
            innerCore.SpreadAngle = Vector2.new(360, 360)
            innerCore.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.6),
                NumberSequenceKeypoint.new(0.3, 0.2),
                NumberSequenceKeypoint.new(0.7, 0.4),
                NumberSequenceKeypoint.new(1, 1)
            })
            innerCore.LightEmission = 1
            innerCore.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(0.5, Settings.Visuals.SelfESP.Aura.Color),
                ColorSequenceKeypoint.new(1, Settings.Visuals.SelfESP.Aura.Color)
            })
            innerCore.Speed = NumberRange.new(0.5, 1.5)
            innerCore.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.2),
                NumberSequenceKeypoint.new(0.5, 0.6),
                NumberSequenceKeypoint.new(1, 0.1)
            })
            innerCore.Rate = 25
            innerCore.LockedToPart = false
            innerCore.Texture = "rbxassetid://8997386535"
            innerCore.RotSpeed = NumberRange.new(-20, 20)
            innerCore.Acceleration = Vector3.new(0, 0.5, 0)
            
            -- Layer 2: Energy Wisps
            local wisps = Instance.new("ParticleEmitter", attachment)
            wisps.Name = "EnergyWisps"
            wisps.Lifetime = NumberRange.new(2, 3)
            wisps.SpreadAngle = Vector2.new(180, 180)
            wisps.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.8),
                NumberSequenceKeypoint.new(0.3, 0.3),
                NumberSequenceKeypoint.new(0.7, 0.5),
                NumberSequenceKeypoint.new(1, 1)
            })
            wisps.LightEmission = 0.9
            wisps.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Settings.Visuals.SelfESP.Aura.Color),
                ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(0.7, Settings.Visuals.SelfESP.Aura.Color),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
            })
            wisps.Speed = NumberRange.new(1, 3)
            wisps.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.4),
                NumberSequenceKeypoint.new(0.3, 1.2),
                NumberSequenceKeypoint.new(0.8, 0.8),
                NumberSequenceKeypoint.new(1, 0)
            })
            wisps.Rate = 20
            wisps.LockedToPart = false
            wisps.Texture = "rbxassetid://10558425570"
            wisps.RotSpeed = NumberRange.new(50, 100)
            wisps.Acceleration = Vector3.new(0, 0.2, 0)
            
            -- Layer 3: Electric Arcs
            local arcs = Instance.new("ParticleEmitter", attachment)
            arcs.Name = "ElectricArcs"
            arcs.Lifetime = NumberRange.new(0.5, 1)
            arcs.SpreadAngle = Vector2.new(360, 360)
            arcs.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(0.5, 0.3),
                NumberSequenceKeypoint.new(1, 1)
            })
            arcs.LightEmission = 1
            arcs.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(0.5, Settings.Visuals.SelfESP.Aura.Color),
                ColorSequenceKeypoint.new(1, Settings.Visuals.SelfESP.Aura.Color)
            })
            arcs.Speed = NumberRange.new(2, 6)
            arcs.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.8),
                NumberSequenceKeypoint.new(0.5, 1.5),
                NumberSequenceKeypoint.new(1, 0.2)
            })
            arcs.Rate = 15
            arcs.Texture = "rbxassetid://1084955012"
            arcs.Rotation = NumberRange.new(-180, 180)
            
            -- Layer 4: Outer Glow Particles
            local outerGlow = Instance.new("ParticleEmitter", attachment)
            outerGlow.Name = "OuterGlow"
            outerGlow.Lifetime = NumberRange.new(3, 4)
            outerGlow.SpreadAngle = Vector2.new(90, 90)
            outerGlow.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.9),
                NumberSequenceKeypoint.new(0.2, 0.6),
                NumberSequenceKeypoint.new(0.5, 0.3),
                NumberSequenceKeypoint.new(0.8, 0.7),
                NumberSequenceKeypoint.new(1, 1)
            })
            outerGlow.LightEmission = 0.8
            outerGlow.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Settings.Visuals.SelfESP.Aura.Color),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(1, Settings.Visuals.SelfESP.Aura.Color)
            })
            outerGlow.Speed = NumberRange.new(0.3, 1)
            outerGlow.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1.5),
                NumberSequenceKeypoint.new(0.5, 2.5),
                NumberSequenceKeypoint.new(1, 0.5)
            })
            outerGlow.Rate = 12
            outerGlow.LockedToPart = false
            outerGlow.Texture = "rbxassetid://241650934"
            outerGlow.RotSpeed = NumberRange.new(-10, 10)
            
            -- Layer 5: Sparkling Effects
            local sparkles = Instance.new("ParticleEmitter", attachment)
            sparkles.Name = "Sparkles"
            sparkles.Lifetime = NumberRange.new(1, 2)
            sparkles.SpreadAngle = Vector2.new(360, 360)
            sparkles.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(0.5, 0.2),
                NumberSequenceKeypoint.new(1, 1)
            })
            sparkles.LightEmission = 1
            sparkles.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(0.3, Settings.Visuals.SelfESP.Aura.Color),
                ColorSequenceKeypoint.new(0.7, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(1, Settings.Visuals.SelfESP.Aura.Color)
            })
            sparkles.Speed = NumberRange.new(3, 8)
            sparkles.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.1),
                NumberSequenceKeypoint.new(0.5, 0.2),
                NumberSequenceKeypoint.new(1, 0.05)
            })
            sparkles.Rate = 30
            sparkles.Texture = "rbxassetid://241685484"
            sparkles.Acceleration = Vector3.new(0, 1, 0)
            
            -- Add intense glow to body part
            part.Material = Enum.Material.Neon
            part.Color = Settings.Visuals.SelfESP.Aura.Color
            
            -- Add PointLight for enhanced glow
            local bodyLight = Instance.new("PointLight", part)
            bodyLight.Name = "AuraLight"
            bodyLight.Color = Settings.Visuals.SelfESP.Aura.Color
            bodyLight.Range = 8
            bodyLight.Brightness = 3
            
            table.insert(auraEffects, {
                part = part, 
                attachment = attachment, 
                light = bodyLight,
                originalColor = part.Color,
                originalMaterial = part.Material
            })
        end
    end
    
    return auraEffects
end

-- Full Body Aura1 Effect
local function createFullBodyAura1(character)
    local bodyParts = {
        "Head",
        "UpperTorso", 
        "LowerTorso",
        "LeftUpperArm",
        "LeftLowerArm", 
        "LeftHand",
        "RightUpperArm",
        "RightLowerArm",
        "RightHand",
        "LeftUpperLeg",
        "LeftLowerLeg",
        "LeftFoot",
        "RightUpperLeg", 
        "RightLowerLeg",
        "RightFoot"
    }
    
    local effects = {}
    
    -- Create Aura1 on all body parts
    for _, partName in ipairs(bodyParts) do
        local part = character:FindFirstChild(partName)
        if part then
            local attachment = Instance.new("Attachment")
            attachment.Name = "FullBodyAura1_" .. partName
            attachment.Parent = part
            
            local Aura1 = Instance.new("ParticleEmitter", attachment)
            Aura1.Name = "Aura1"

            -- Appearance
            Aura1.Brightness = 3.635
            Aura1.Color = ColorSequence.new(Settings.Visuals.SelfESP.Aura.Color)
            Aura1.LightEmission = 0.6
            Aura1.LightInfluence = 0
            Aura1.Orientation = Enum.ParticleOrientation.FacingCamera
            Aura1.Size = NumberSequence.new(1)
            Aura1.Squash = NumberSequence.new(0)
            Aura1.Texture = "rbxassetid://13410359900"
            Aura1.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1)
            })
            Aura1.ZOffset = -1.05

            -- Emission
            Aura1.EmissionDirection = Enum.NormalId.Top
            Aura1.Enabled = true
            Aura1.Lifetime = NumberRange.new(0, 1)
            Aura1.Rate = 10
            Aura1.Rotation = NumberRange.new(-360, 360)
            Aura1.RotSpeed = NumberRange.new(-30, 30)
            Aura1.Speed = NumberRange.new(0.2)
            Aura1.SpreadAngle = Vector2.new(5, 5)

            -- EmitterShape
            Aura1.Shape = Enum.ParticleEmitterShape.Box
            Aura1.ShapeInOut = Enum.ParticleEmitterShapeInOut.InAndOut
            Aura1.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume

            -- Flipbook
            Aura1.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid8x8
            Aura1.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
            Aura1.FlipbookStartRandom = false

            -- Motion
            Aura1.Acceleration = Vector3.new(0, 0, 0)
            
            table.insert(effects, {
                attachment = attachment,
                part = part,
                originalColor = part.Color,
                originalMaterial = part.Material
            })
        end
    end
    
    return effects
end

-- Full Body Aura2 Effect (New Enhanced Version)
local function createFullBodyAura2(character)
    local bodyParts = {
        "Head",
        "UpperTorso", 
        "LowerTorso",
        "LeftUpperArm",
        "LeftLowerArm", 
        "LeftHand",
        "RightUpperArm",
        "RightLowerArm",
        "RightHand",
        "LeftUpperLeg",
        "LeftLowerLeg",
        "LeftFoot",
        "RightUpperLeg", 
        "RightLowerLeg",
        "RightFoot"
    }
    
    local effects = {}
    
    -- Create Aura2 on all body parts
    for _, partName in ipairs(bodyParts) do
        local part = character:FindFirstChild(partName)
        if part then
            local attachment = Instance.new("Attachment")
            attachment.Name = "FullBodyAura2_" .. partName
            attachment.Parent = part
            
            local Aura2 = Instance.new("ParticleEmitter", attachment)
            Aura2.Name = "Aura2"

            -- Appearance (Enhanced from your reference)
            Aura2.Brightness = 2
            Aura2.Color = ColorSequence.new(Settings.Visuals.SelfESP.Aura.Color)
            Aura2.LightEmission = 0.5
            Aura2.LightInfluence = 0
            Aura2.Orientation = Enum.ParticleOrientation.FacingCamera
            Aura2.Size = NumberSequence.new(1.1)
            Aura2.Squash = NumberSequence.new(0)
            Aura2.Texture = "rbxassetid://1687645505"
            Aura2.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(0.5, 0.3),
                NumberSequenceKeypoint.new(1, 1)
            })
            Aura2.ZOffset = -2

            -- Emission (Based on your reference settings)
            Aura2.EmissionDirection = Enum.NormalId.Top
            Aura2.Enabled = true
            Aura2.Lifetime = NumberRange.new(1)
            Aura2.Rate = 20
            Aura2.Rotation = NumberRange.new(-360, 360)
            Aura2.RotSpeed = NumberRange.new(0)
            Aura2.Speed = NumberRange.new(0.001)
            Aura2.SpreadAngle = Vector2.new(0, 0)

            -- EmitterShape
            Aura2.Shape = Enum.ParticleEmitterShape.Box
            Aura2.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
            Aura2.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume

            -- Flipbook
            Aura2.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
            Aura2.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
            Aura2.FlipbookStartRandom = false

            -- Motion
            Aura2.Acceleration = Vector3.new(0, 0, 0)
            Aura2.Drag = 0
            Aura2.LockedToPart = true
            Aura2.TimeScale = 1
            Aura2.VelocityInheritance = 0
            Aura2.WindAffectsDrag = false
            
            table.insert(effects, {
                attachment = attachment,
                part = part,
                originalColor = part.Color,
                originalMaterial = part.Material
            })
        end
    end
    
    return effects
end

-- Cosmic Vortex (Enhanced with more layers)
local function createEnhancedCosmicVortex(character)
    local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
    if not torso then return end
    
    local effects = {}
    
    -- Main torso attachment for the main vortex effects
    local mainAttachment = Instance.new("Attachment")
    mainAttachment.Name = "EnhancedCosmicVortex_Main"
    mainAttachment.Parent = torso
    
    -- Layer 1: Main Vortex (only on torso)
    local vortex = Instance.new("ParticleEmitter", mainAttachment)
    vortex.Name = "MainVortex"
    vortex.Lifetime = NumberRange.new(4, 6)
    vortex.SpreadAngle = Vector2.new(5, 5)
    vortex.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.1, 0.2),
        NumberSequenceKeypoint.new(0.5, 0.1),
        NumberSequenceKeypoint.new(0.9, 0.3),
        NumberSequenceKeypoint.new(1, 1)
    })
    vortex.LightEmission = 1
    vortex.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 100)),
        ColorSequenceKeypoint.new(0.3, Settings.Visuals.SelfESP.Aura.Color),
        ColorSequenceKeypoint.new(0.7, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Settings.Visuals.SelfESP.Aura.Color)
    })
    vortex.Speed = NumberRange.new(0)
    vortex.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 10),
        NumberSequenceKeypoint.new(0.3, 15),
        NumberSequenceKeypoint.new(0.7, 18),
        NumberSequenceKeypoint.new(1, 12)
    })
    vortex.Rate = 4
    vortex.LockedToPart = true
    vortex.Texture = "rbxassetid://10558425570"
    vortex.RotSpeed = NumberRange.new(120, 180)
    vortex.Rotation = NumberRange.new(0, 360)

    -- Layer 2: Energy Rings
    local rings = Instance.new("ParticleEmitter", mainAttachment)
    rings.Name = "EnergyRings"
    rings.Lifetime = NumberRange.new(6, 8)
    rings.SpreadAngle = Vector2.new(20, 20)
    rings.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.1, 0.4),
        NumberSequenceKeypoint.new(0.5, 0.1),
        NumberSequenceKeypoint.new(0.9, 0.6),
        NumberSequenceKeypoint.new(1, 1)
    })
    rings.LightEmission = 0.9
    rings.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Settings.Visuals.SelfESP.Aura.Color),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 200, 255)),
        ColorSequenceKeypoint.new(1, Settings.Visuals.SelfESP.Aura.Color)
    })
    rings.Speed = NumberRange.new(0.2, 0.5)
    rings.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 8),
        NumberSequenceKeypoint.new(0.3, 12),
        NumberSequenceKeypoint.new(0.7, 16),
        NumberSequenceKeypoint.new(1, 10)
    })
    rings.Rate = 3
    rings.LockedToPart = false
    rings.Texture = "rbxassetid://3358479745"
    rings.RotSpeed = NumberRange.new(30, 60)
    
    -- Layer 3: Cosmic Lightning
    local cosmicLightning = Instance.new("ParticleEmitter", mainAttachment)
    cosmicLightning.Name = "CosmicLightning"
    cosmicLightning.Lifetime = NumberRange.new(0.3, 0.8)
    cosmicLightning.SpreadAngle = Vector2.new(360, 360)
    cosmicLightning.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.3, 0.1),
        NumberSequenceKeypoint.new(0.7, 0.4),
        NumberSequenceKeypoint.new(1, 1)
    })
    cosmicLightning.LightEmission = 1
    cosmicLightning.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 100, 255)),
        ColorSequenceKeypoint.new(1, Settings.Visuals.SelfESP.Aura.Color)
    })
    cosmicLightning.Speed = NumberRange.new(0)
    cosmicLightning.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 6),
        NumberSequenceKeypoint.new(0.5, 10),
        NumberSequenceKeypoint.new(1, 4)
    })
    cosmicLightning.Rate = 15
    cosmicLightning.Texture = "rbxassetid://1084955012"
    cosmicLightning.Rotation = NumberRange.new(-180, 180)
    
    -- Layer 4: Stellar Particles
    local stars = Instance.new("ParticleEmitter", mainAttachment)
    stars.Name = "StellarParticles"
    stars.Lifetime = NumberRange.new(3, 5)
    stars.SpreadAngle = Vector2.new(360, 360)
    stars.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.8),
        NumberSequenceKeypoint.new(0.2, 0.3),
        NumberSequenceKeypoint.new(0.8, 0.5),
        NumberSequenceKeypoint.new(1, 1)
    })
    stars.LightEmission = 1
    stars.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 200, 100)),
        ColorSequenceKeypoint.new(0.7, Settings.Visuals.SelfESP.Aura.Color),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 100, 255))
    })
    stars.Speed = NumberRange.new(1, 4)
    stars.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(0.5, 0.8),
        NumberSequenceKeypoint.new(1, 0.1)
    })
    stars.Rate = 25
    stars.Texture = "rbxassetid://241685484"
    stars.Acceleration = Vector3.new(0, 0.5, 0)
    
    -- Apply material and color changes to torso only
    torso.Material = Enum.Material.ForceField
    torso.Color = Settings.Visuals.SelfESP.Aura.Color
    
    -- Enhanced lighting
    local vortexLight = Instance.new("PointLight", torso)
    vortexLight.Name = "VortexLight"
    vortexLight.Color = Settings.Visuals.SelfESP.Aura.Color
    vortexLight.Range = 15
    vortexLight.Brightness = 5
    
    -- Add main attachment to effects
    table.insert(effects, {
        attachment = mainAttachment,
        torso = torso,
        light = vortexLight,
        originalColor = torso.Color,
        originalMaterial = torso.Material
    })
    
    return effects
end

local currentAuraEffects = {}

local function applyAura(auraType)
    local character = player.Character
    if not character then return end
    
    -- Clean up existing effects
    for _, effect in ipairs(currentAuraEffects) do
        if effect.attachment and effect.attachment.Parent then
            effect.attachment:Destroy()
        end
        if effect.light and effect.light.Parent then
            effect.light:Destroy()
        end
        if effect.part and effect.originalMaterial then
            effect.part.Material = effect.originalMaterial
            effect.part.Color = effect.originalColor
        end
        if effect.torso and effect.originalMaterial then
            effect.torso.Material = effect.originalMaterial
            effect.torso.Color = effect.originalColor
        end
    end
    currentAuraEffects = {}
    
    if not getgenv().auraEnabled then return end
    
    if auraType == "Enhanced Full Body Energy" then
        currentAuraEffects = createEnhancedFullBodyAura(character)
    elseif auraType == "Enhanced Cosmic Vortex" then
        local effects = createEnhancedCosmicVortex(character)
        if effects then
            currentAuraEffects = effects
        end
    elseif auraType == "Zesty Aura" then
        local effects = createFullBodyAura1(character)
        if effects then
            currentAuraEffects = effects
        end
    elseif auraType == "Full Body Aura2" then
        local effects = createFullBodyAura2(character)
        if effects then
            currentAuraEffects = effects
        end
    end
end

local function onCharacterAdded(character)
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    if getgenv().trailEnabled then
        utility.trail_character(true)
    end
    
    if getgenv().auraEnabled then
        applyAura(getgenv().selectedAura or "Enhanced Full Body Energy")
    end
    
    if getgenv().footprintsEnabled then
        toggleFootprints(true)
    end
end

player.CharacterAdded:Connect(onCharacterAdded)

if player.Character then 
    onCharacterAdded(player.Character) 
end

-- UI Elements
Auras:AddToggle("TrailToggle", {
    Text = "Trail",
    Default = false,
    Callback = function(state)
        getgenv().trailEnabled = state
        utility.trail_character(state)
    end
}):AddColorPicker("TrailColor", {
    Text = "Trail Color",
    Default = Settings.Visuals.SelfESP.Trail.Color,
    Callback = function(color)
        Settings.Visuals.SelfESP.Trail.Color = color
        if getgenv().trailEnabled then
            utility.trail_character(false)
            utility.trail_character(true)
        end
    end
}):AddColorPicker("TrailColor2", {
    Text = "Trail Color 2",
    Default = Settings.Visuals.SelfESP.Trail.Color2,
    Callback = function(color)
        Settings.Visuals.SelfESP.Trail.Color2 = color
        if getgenv().trailEnabled then
            utility.trail_character(false)
            utility.trail_character(true)
        end
    end
})

Auras:AddSlider("TrailLifetime", {
    Text = "Trail Lifetime",
    Default = 1.6,
    Min = 0.1,
    Max = 5,
    Rounding = 1,
    Callback = function(value)
        Settings.Visuals.SelfESP.Trail.LifeTime = value
        if getgenv().trailEnabled then
            utility.trail_character(false)
            utility.trail_character(true)
        end
    end
})

Auras:AddToggle("FootprintsToggle", {
    Text = "Footprints",
    Default = false,
    Callback = function(state)
        getgenv().footprintsEnabled = state
        toggleFootprints(state)
    end
}):AddColorPicker("FootprintColor", {
    Text = "Footprint Color",
    Default = Settings.Visuals.SelfESP.Footsteps.Color,
    Callback = function(color)
        Settings.Visuals.SelfESP.Footsteps.Color = color
    end
})

Auras:AddDropdown("FootprintStyle", {
    Text = "Footprint Style",
    Values = {"Energy Pulse", "Fire Steps", "Ice Crystals", "Electric Sparks", "Divine Light"},
    Default = "Energy Pulse",
    Callback = function(selected)
        Settings.Visuals.SelfESP.Footsteps.Style = selected
    end
})

Auras:AddSlider("FootprintSpeed", {
    Text = "Footprint Speed",
    Default = 0.3,
    Min = 0.1,
    Max = 2,
    Rounding = 1,
    Callback = function(value)
        Settings.Visuals.SelfESP.Footsteps.SpawnRate = value
    end
})

Auras:AddToggle("AuraToggle", {
    Text = "Auras",
    Default = false,
    Callback = function(state)
        getgenv().auraEnabled = state
        applyAura(getgenv().selectedAura or "Enhanced Full Body Energy")
    end
}):AddColorPicker("AuraColor", {
    Text = "Aura Color",
    Default = Settings.Visuals.SelfESP.Aura.Color,
    Callback = function(color)
        Settings.Visuals.SelfESP.Aura.Color = color
        if getgenv().auraEnabled then
            applyAura(getgenv().selectedAura or "Enhanced Full Body Energy")
        end
    end
})

-- Updated Aura Type Dropdown with Full Body Aura2
Auras:AddDropdown("AuraType", {
    Text = "Select Aura",
    Values = {"Enhanced Full Body Energy", "Enhanced Cosmic Vortex", "Zesty Aura", "Full Body Aura2"},
    Default = "Enhanced Full Body Energy",
    Callback = function(selected)
        getgenv().selectedAura = selected
        if getgenv().auraEnabled then
            applyAura(selected)
        end
    end
})

-- Body Material Dropdown
Auras:AddDropdown("BodyMaterial", {
    Text = "Body Material",
    Values = {"Neon", "ForceField"},
    Default = "Neon",
    Callback = function(selected)
        local player = game.Players.LocalPlayer
        if player and player.Character then
            local bodyParts = {
                "Head",
                "UpperTorso", 
                "LowerTorso",
                "LeftUpperArm",
                "LeftLowerArm", 
                "LeftHand",
                "RightUpperArm",
                "RightLowerArm",
                "RightHand",
                "LeftUpperLeg",
                "LeftLowerLeg",
                "LeftFoot",
                "RightUpperLeg", 
                "RightLowerLeg",
                "RightFoot"
            }
            
            -- Apply selected material to all body parts
            for _, partName in pairs(bodyParts) do
                local part = player.Character:FindFirstChild(partName)
                if part then
                    if selected == "Neon" then
                        part.Material = Enum.Material.Neon
                    elseif selected == "ForceField" then
                        part.Material = Enum.Material.ForceField
                    end
                end
            end
            
            -- Store the selection in settings if you have a settings table
            if Settings and Settings.Visuals and Settings.Visuals.SelfESP then
                Settings.Visuals.SelfESP.BodyMaterial = selected
            end
        end
    end
})

Auras:AddToggle("BodyMaterialToggle", {
    Text = "Enable Body Material",
    Default = false,
    Callback = function(state)
        getgenv().bodyMaterialEnabled = state
        local player = game.Players.LocalPlayer
        if player and player.Character then
            local bodyParts = {
                "Head",
                "UpperTorso", 
                "LowerTorso",
                "LeftUpperArm",
                "LeftLowerArm", 
                "LeftHand",
                "RightUpperArm",
                "RightLowerArm",
                "RightHand",
                "LeftUpperLeg",
                "LeftLowerLeg",
                "LeftFoot",
                "RightUpperLeg", 
                "RightLowerLeg",
                "RightFoot"
            }

            for _, partName in pairs(bodyParts) do
                local part = player.Character:FindFirstChild(partName)
                if part then
                    if state then
                        local selectedMaterial = getgenv().selectedBodyMaterial or Settings.Visuals.SelfESP.BodyMaterial or "Neon"
                        if selectedMaterial == "Neon" then
                            part.Material = Enum.Material.Neon
                        elseif selectedMaterial == "ForceField" then
                            part.Material = Enum.Material.ForceField
                        end
                        part.Color = Settings.Visuals.SelfESP.BodyMaterialColor or Color3.fromRGB(255, 255, 255)
                    else
                        part.Material = Enum.Material.Plastic
                    end
                end
            end
        end
    end
}):AddColorPicker("BodyMaterialColor", {
    Text = "Body Material Color",
    Default = Settings.Visuals.SelfESP.BodyMaterialColor or Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        Settings.Visuals.SelfESP.BodyMaterialColor = color
        if getgenv().bodyMaterialEnabled then
            local player = game.Players.LocalPlayer
            if player and player.Character then
                for _, partName in pairs({
                    "Head", "UpperTorso", "LowerTorso",
                    "LeftUpperArm", "LeftLowerArm", "LeftHand",
                    "RightUpperArm", "RightLowerArm", "RightHand",
                    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
                    "RightUpperLeg", "RightLowerLeg", "RightFoot"
                }) do
                    local part = player.Character:FindFirstChild(partName)
                    if part then
                        part.Color = color
                    end
                end
            end
        end
    end
})

-- Initialize with current character if exists
if player.Character then
    onCharacterAdded(player.Character) 
end

local targetstuffyh = Tabs.Visuals:AddLeftGroupbox('target visuals')

targetstuffyh:AddToggle("TracerToggle", {
    Text = "Draw Tracer",
    Default = false,
    Callback = function(Value)
        TracerEnabled = Value
        if not Value then
            tracer.Visible = false
        end
    end
}):AddColorPicker('HitboxColorPicker', {
    Text = '',
    Default = Color3.new(0, 1, 1),
    Callback = function(color)
        tracer.Color = color
    end,
})

targetstuffyh:AddDropdown("TracerMode", {
    Text = "Tracer Mode",
    Values = {"Mouse", "HumanoidRootPart"},
    Default = "Mouse",
    Callback = function(Value)
        targetToMouseTracer = (Value == "Mouse")
    end
})

-- Environment Setup
getgenv().envt = Tabs.Visuals:AddRightGroupbox("Environment")
getgenv().Lighting = game:GetService("Lighting")

-- Default Lighting Properties
getgenv().DefaultFogStart = Lighting.FogStart
getgenv().DefaultFogEnd = Lighting.FogEnd
getgenv().DefaultFogColor = Lighting.FogColor
getgenv().DefaultAmbient = Lighting.Ambient
getgenv().DefaultTechnology = Lighting.Technology.Name
getgenv().DefaultBrightness = Lighting.Brightness
getgenv().DefaultExposure = Lighting.ExposureCompensation
getgenv().DefaultColorShift_Top = Lighting.ColorShift_Top
getgenv().DefaultColorShift_Bottom = Lighting.ColorShift_Bottom
getgenv().DefaultGlobalShadows = Lighting.GlobalShadows
getgenv().DefaultClockTime = Lighting.ClockTime
getgenv().DefaultGeographicLatitude = Lighting.GeographicLatitude
getgenv().DefaultBloom = Lighting:FindFirstChild("Bloom") ~= nil
getgenv().DefaultBlur = Lighting:FindFirstChild("Blur") ~= nil
getgenv().DefaultColorCorrection = Lighting:FindFirstChild("ColorCorrection") ~= nil
getgenv().DefaultSunRays = Lighting:FindFirstChild("SunRays") ~= nil

------------------------------------------------------------
-- TIME SETTINGS
------------------------------------------------------------
envt:AddToggle('CustomTime', {
    Text = 'Custom Time',
    Default = false,
    Callback = function(Value)
        getgenv().CustomTimeEnabled = Value
        if Value then
            if not getgenv().TimeConnection then
                getgenv().TimeConnection = game:GetService("RunService").Heartbeat:Connect(function()
                    if getgenv().TimeCycle then
                        local osc = (math.sin(tick() * (getgenv().TimeCycleSpeed or 1) / 10) + 1) / 2
                        Lighting.ClockTime = osc * 24
                    else
                        Lighting.ClockTime = getgenv().ClockTime or DefaultClockTime
                    end
                end)
            end
        else
            if getgenv().TimeConnection then
                getgenv().TimeConnection:Disconnect()
                getgenv().TimeConnection = nil
            end
            Lighting.ClockTime = DefaultClockTime
        end
    end
})

envt:AddToggle('TimeCycle', {
    Text = 'Time Cycle',
    Default = false,
    Callback = function(Value)
        getgenv().TimeCycle = Value
    end
})

envt:AddSlider('TimeCycleSpeed', {
    Text = 'Cycle Speed',
    Default = 1,
    Min = 0.1,
    Max = 10,
    Rounding = 1,
    Callback = function(Value)
        getgenv().TimeCycleSpeed = Value
    end
})

envt:AddSlider('ClockTime', {
    Text = 'Clock Time',
    Default = DefaultClockTime,
    Min = 0,
    Max = 24,
    Rounding = 1,
    Callback = function(Value)
        getgenv().ClockTime = Value
        if getgenv().CustomTimeEnabled and not getgenv().TimeCycle then
            Lighting.ClockTime = Value
        end
    end
})

------------------------------------------------------------
-- WEATHER EFFECTS
------------------------------------------------------------
local weatherConfigs = {
    Rain = {
        texture = "rbxassetid://118641183",
        sound = "rbxassetid://238895410",
        color = Color3.fromRGB(173, 216, 230),
        size = NumberSequence.new(0.4),
        lifetime = NumberRange.new(5, 100),
        speed = NumberRange.new(1, 1),
        acceleration = Vector3.new(0, -50, 0),
        spreadAngle = Vector2.new(0, 0),
        transparency = NumberSequence.new(0)
    },
    Snow = {
        texture = "rbxassetid://118641183",
        sound = "rbxassetid://1835560035",
        color = Color3.fromRGB(255, 255, 255),
        size = NumberSequence.new(0.3),
        lifetime = NumberRange.new(8, 15),
        speed = NumberRange.new(0.5, 2),
        acceleration = Vector3.new(0, -10, 0),
        spreadAngle = Vector2.new(45, 45),
        transparency = NumberSequence.new(0)
    },
    Sakura = {
        texture = "rbxassetid://243160943",
        sound = "rbxassetid://626777433",
        color = Color3.fromRGB(255, 182, 193),
        size = NumberSequence.new(0.6),
        lifetime = NumberRange.new(10, 20),
        speed = NumberRange.new(0.2, 1),
        acceleration = Vector3.new(0, -5, 0),
        spreadAngle = Vector2.new(80, 80),
        transparency = NumberSequence.new(0)
    }
}

-- Weather globals
getgenv().CurrentWeatherType = "Rain"
getgenv().WeatherIntensity = 200
getgenv().WeatherVolume = 0.5

envt:AddDropdown('WeatherType', {
    Text = 'Weather Type',
    Values = {'Rain', 'Snow', 'Sakura'},
    Default = 1,
    Callback = function(Value)
        getgenv().CurrentWeatherType = Value
        if getgenv().WeatherActive and workspace:FindFirstChild("WeatherEffect") then
            workspace.WeatherEffect:Destroy()
            if getgenv().WeatherFollowConnection then
                getgenv().WeatherFollowConnection:Disconnect()
            end
            createWeatherEffect(Value)
        end
    end
})

envt:AddToggle('WeatherToggle', {
    Text = 'Weather Effect',
    Default = false,
    Callback = function(Value)
        getgenv().WeatherActive = Value
        if Value then
            createWeatherEffect(getgenv().CurrentWeatherType)
        else
            if workspace:FindFirstChild("WeatherEffect") then
                workspace.WeatherEffect:Destroy()
            end
            if getgenv().WeatherFollowConnection then
                getgenv().WeatherFollowConnection:Disconnect()
                getgenv().WeatherFollowConnection = nil
            end
        end
    end
})

envt:AddSlider('WeatherIntensity', {
    Text = 'Weather Intensity',
    Default = 200,
    Min = 50,
    Max = 1000,
    Rounding = 1,
    Callback = function(Value)
        getgenv().WeatherIntensity = Value
        if getgenv().WeatherParticle then
            getgenv().WeatherParticle.Rate = Value
        end
    end
})

envt:AddSlider('WeatherVolume', {
    Text = 'Weather Volume',
    Default = 0.5,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        getgenv().WeatherVolume = Value
        if getgenv().WeatherSound then
            getgenv().WeatherSound.Volume = Value
        end
    end
})

function createWeatherEffect(weatherType)
    local config = weatherConfigs[weatherType]
    if not config then return end

    local weatherPart = Instance.new("Part")
    weatherPart.Name = "WeatherEffect"
    weatherPart.Anchored = true
    weatherPart.CanCollide = false
    weatherPart.Transparency = 1
    weatherPart.Size = Vector3.new(500, 1, 500)
    weatherPart.Parent = workspace

    local emitter = Instance.new("ParticleEmitter")
    emitter.Parent = weatherPart
    emitter.Texture = config.texture
    emitter.Color = ColorSequence.new(config.color)
    emitter.Size = config.size
    emitter.Lifetime = config.lifetime
    emitter.Rate = getgenv().WeatherIntensity
    emitter.Speed = config.speed
    emitter.SpreadAngle = config.spreadAngle
    emitter.Acceleration = config.acceleration
    emitter.Transparency = config.transparency
    emitter.EmissionDirection = Enum.NormalId.Bottom

    local sound = Instance.new("Sound")
    sound.Name = "WeatherSound"
    sound.SoundId = config.sound
    sound.Volume = getgenv().WeatherVolume
    sound.Looped = true
    sound.Parent = weatherPart
    sound:Play()

    getgenv().WeatherParticle = emitter
    getgenv().WeatherSound = sound
    getgenv().WeatherPart = weatherPart

    getgenv().WeatherFollowConnection = game:GetService("RunService").Heartbeat:Connect(function()
        local root = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local yOffset = weatherType == "Sakura" and 30 or 50
            weatherPart.CFrame = CFrame.new(root.Position + Vector3.new(0, yOffset, 0))
        end
    end)
end

------------------------------------------------------------
-- FOG SETTINGS
------------------------------------------------------------
envt:AddToggle('FogToggle', {
    Text = 'Fog Changer',
    Default = false,
    Callback = function(Value)
        if Value then
            Lighting.FogStart = getgenv().FogStart or DefaultFogStart
            Lighting.FogEnd = getgenv().FogEnd or DefaultFogEnd
        else
            Lighting.FogStart = DefaultFogStart
            Lighting.FogEnd = DefaultFogEnd
            Lighting.FogColor = DefaultFogColor
        end
    end
}):AddColorPicker('FogColor', {
    Default = DefaultFogColor,
    Title = 'Fog Color',
    Callback = function(Value)
        Lighting.FogColor = Value
    end
})

envt:AddSlider('FogStart', {
    Text = 'Fog Start',
    Default = DefaultFogStart,
    Min = 0,
    Max = 1000,
    Rounding = 1,
    Callback = function(Value)
        getgenv().FogStart = Value
        Lighting.FogStart = Value
    end
})

envt:AddSlider('FogEnd', {
    Text = 'Fog End',
    Default = DefaultFogEnd,
    Min = 10,
    Max = 10000,
    Rounding = 1,
    Callback = function(Value)
        getgenv().FogEnd = Value
        Lighting.FogEnd = Value
    end
})

------------------------------------------------------------
-- AMBIENT, LIGHT & SHADOW
------------------------------------------------------------
envt:AddToggle('AmbientToggle', {
    Text = 'Ambient',
    Default = false,
    Callback = function(Value)
        Lighting.Ambient = Value and (getgenv().AmbientColor or DefaultAmbient) or DefaultAmbient
    end
}):AddColorPicker('AmbientColor', {
    Default = DefaultAmbient,
    Title = 'Ambient Color',
    Callback = function(Value)
        getgenv().AmbientColor = Value
        Lighting.Ambient = Value
    end
})

envt:AddDropdown('LightingTech', {
    Text = 'Technology',
    Values = {'Voxel', 'Compatibility', 'ShadowMap', 'Future'},
    Default = table.find({'Voxel', 'Compatibility', 'ShadowMap', 'Future'}, DefaultTechnology),
    Callback = function(Value)
        Lighting.Technology = Enum.Technology[Value]
    end
})

envt:AddToggle('GlobalShadows', {
    Text = 'Global Shadows',
    Default = DefaultGlobalShadows,
    Callback = function(Value)
        Lighting.GlobalShadows = Value
    end
})

envt:AddSlider('Brightness', {
    Text = 'Brightness',
    Default = DefaultBrightness,
    Min = 0,
    Max = 10,
    Rounding = 2,
    Callback = function(Value)
        Lighting.Brightness = Value
    end
})

envt:AddSlider('Exposure', {
    Text = 'Exposure',
    Default = DefaultExposure,
    Min = -3,
    Max = 3,
    Rounding = 2,
    Callback = function(Value)
        Lighting.ExposureCompensation = Value
    end
})

------------------------------------------------------------
-- COLOR SHIFT
------------------------------------------------------------
envt:AddToggle('ColorShiftToggle', {
    Text = 'Color Shift',
    Default = false,
    Callback = function(Value)
        Lighting.ColorShift_Top = Value and (getgenv().ColorShift_Top or DefaultColorShift_Top) or DefaultColorShift_Top
        Lighting.ColorShift_Bottom = Value and (getgenv().ColorShift_Bottom or DefaultColorShift_Bottom) or DefaultColorShift_Bottom
    end
})

envt:AddLabel('Color Shift Top'):AddColorPicker('ColorShiftTop', {
    Default = DefaultColorShift_Top,
    Title = 'Top Color',
    Callback = function(Value)
        getgenv().ColorShift_Top = Value
        Lighting.ColorShift_Top = Value
    end
})

envt:AddLabel('Color Shift Bottom'):AddColorPicker('ColorShiftBottom', {
    Default = DefaultColorShift_Bottom,
    Title = 'Bottom Color',
    Callback = function(Value)
        getgenv().ColorShift_Bottom = Value
        Lighting.ColorShift_Bottom = Value
    end
})


-- Post Processing Effects
getgenv().postfx = Tabs.Visuals:AddLeftGroupbox("Post Processing")

-- Bloom Effect
postfx:AddToggle('BloomToggle', {
    Text = 'Bloom Effect',
    Default = DefaultBloom,
    Callback = function(Value)
        if Value then
            if not Lighting:FindFirstChild("Bloom") then
                local bloom = Instance.new("BloomEffect")
                bloom.Name = "Bloom"
                bloom.Intensity = getgenv().BloomIntensity or 1
                bloom.Size = getgenv().BloomSize or 24
                bloom.Threshold = getgenv().BloomThreshold or 2
                bloom.Parent = Lighting
            end
        else
            if Lighting:FindFirstChild("Bloom") then
                Lighting.Bloom:Destroy()
            end
        end
    end
})

postfx:AddSlider('BloomIntensity', {
    Text = 'Bloom Intensity',
    Default = 1,
    Min = 0,
    Max = 5,
    Rounding = 2,
    Callback = function(Value)
        getgenv().BloomIntensity = Value
        if Lighting:FindFirstChild("Bloom") then
            Lighting.Bloom.Intensity = Value
        end
    end
})

postfx:AddSlider('BloomSize', {
    Text = 'Bloom Size',
    Default = 24,
    Min = 0,
    Max = 50,
    Rounding = 1,
    Callback = function(Value)
        getgenv().BloomSize = Value
        if Lighting:FindFirstChild("Bloom") then
            Lighting.Bloom.Size = Value
        end
    end
})

postfx:AddSlider('BloomThreshold', {
    Text = 'Bloom Threshold',
    Default = 2,
    Min = 0,
    Max = 5,
    Rounding = 2,
    Callback = function(Value)
        getgenv().BloomThreshold = Value
        if Lighting:FindFirstChild("Bloom") then
            Lighting.Bloom.Threshold = Value
        end
    end
})

-- Blur Effect
postfx:AddToggle('BlurToggle', {
    Text = 'Blur Effect',
    Default = DefaultBlur,
    Callback = function(Value)
        if Value then
            if not Lighting:FindFirstChild("Blur") then
                local blur = Instance.new("BlurEffect")
                blur.Name = "Blur"
                blur.Size = getgenv().BlurSize or 5
                blur.Parent = Lighting
            end
        else
            if Lighting:FindFirstChild("Blur") then
                Lighting.Blur:Destroy()
            end
        end
    end
})

postfx:AddSlider('BlurSize', {
    Text = 'Blur Size',
    Default = 5,
    Min = 0,
    Max = 25,
    Rounding = 1,
    Callback = function(Value)
        getgenv().BlurSize = Value
        if Lighting:FindFirstChild("Blur") then
            Lighting.Blur.Size = Value
        end
    end
})

-- Color Correction
postfx:AddToggle('ColorCorrectionToggle', {
    Text = 'Color Correction',
    Default = DefaultColorCorrection,
    Callback = function(Value)
        if Value then
            if not Lighting:FindFirstChild("ColorCorrection") then
                local cc = Instance.new("ColorCorrectionEffect")
                cc.Name = "ColorCorrection"
                cc.Brightness = getgenv().CCBrightness or 0
                cc.Contrast = getgenv().CCContrast or 0
                cc.Saturation = getgenv().CCSaturation or 0
                cc.TintColor = getgenv().CCTintColor or Color3.fromRGB(255, 255, 255)
                cc.Parent = Lighting
            end
        else
            if Lighting:FindFirstChild("ColorCorrection") then
                Lighting.ColorCorrection:Destroy()
            end
        end
    end
})

postfx:AddSlider('CCBrightness', {
    Text = 'CC Brightness',
    Default = 0,
    Min = -1,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        getgenv().CCBrightness = Value
        if Lighting:FindFirstChild("ColorCorrection") then
            Lighting.ColorCorrection.Brightness = Value
        end
    end
})

postfx:AddSlider('CCContrast', {
    Text = 'CC Contrast',
    Default = 0,
    Min = -1,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        getgenv().CCContrast = Value
        if Lighting:FindFirstChild("ColorCorrection") then
            Lighting.ColorCorrection.Contrast = Value
        end
    end
})

postfx:AddSlider('CCSaturation', {
    Text = 'CC Saturation',
    Default = 0,
    Min = -1,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        getgenv().CCSaturation = Value
        if Lighting:FindFirstChild("ColorCorrection") then
            Lighting.ColorCorrection.Saturation = Value
        end
    end
})

postfx:AddLabel('CC Tint Color'):AddColorPicker('CCTintColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Title = 'Tint Color',
    Callback = function(Value)
        getgenv().CCTintColor = Value
        if Lighting:FindFirstChild("ColorCorrection") then
            Lighting.ColorCorrection.TintColor = Value
        end
    end
})

-- Sun Rays
postfx:AddToggle('SunRaysToggle', {
    Text = 'Sun Rays',
    Default = DefaultSunRays,
    Callback = function(Value)
        if Value then
            if not Lighting:FindFirstChild("SunRays") then
                local sunrays = Instance.new("SunRaysEffect")
                sunrays.Name = "SunRays"
                sunrays.Intensity = getgenv().SunRaysIntensity or 0.25
                sunrays.Spread = getgenv().SunRaysSpread or 1
                sunrays.Parent = Lighting
            end
        else
            if Lighting:FindFirstChild("SunRays") then
                Lighting.SunRays:Destroy()
            end
        end
    end
})

postfx:AddSlider('SunRaysIntensity', {
    Text = 'Sun Rays Intensity',
    Default = 0.25,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        getgenv().SunRaysIntensity = Value
        if Lighting:FindFirstChild("SunRays") then
            Lighting.SunRays.Intensity = Value
        end
    end
})

postfx:AddSlider('SunRaysSpread', {
    Text = 'Sun Rays Spread',
    Default = 1,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        getgenv().SunRaysSpread = Value
        if Lighting:FindFirstChild("SunRays") then
            Lighting.SunRays.Spread = Value
        end
    end
})

-- World Appearance
getgenv().world = Tabs.Visuals:AddLeftGroupbox("World Appearance")

-- Atmosphere Effect
world:AddToggle('AtmosphereToggle', {
    Text = 'Custom Atmosphere',
    Default = false,
    Callback = function(Value)
        if Value then
            if not Lighting:FindFirstChild("Atmosphere") then
                local atmosphere = Instance.new("Atmosphere")
                atmosphere.Name = "Atmosphere"
                atmosphere.Density = getgenv().AtmoDensity or 0.3
                atmosphere.Offset = getgenv().AtmoOffset or 0
                atmosphere.Color = getgenv().AtmoColor or Color3.fromRGB(199, 199, 199)
                atmosphere.Decay = getgenv().AtmoDecay or Color3.fromRGB(106, 112, 125)
                atmosphere.Glare = getgenv().AtmoGlare or 0
                atmosphere.Haze = getgenv().AtmoHaze or 0
                atmosphere.Parent = Lighting
            end
        else
            if Lighting:FindFirstChild("Atmosphere") then
                Lighting.Atmosphere:Destroy()
            end
        end
    end
})

world:AddSlider('AtmoDensity', {
    Text = 'Atmosphere Density',
    Default = 0.3,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        getgenv().AtmoDensity = Value
        if Lighting:FindFirstChild("Atmosphere") then
            Lighting.Atmosphere.Density = Value
        end
    end
})

world:AddSlider('AtmoOffset', {
    Text = 'Atmosphere Offset',
    Default = 0,
    Min = -1,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        getgenv().AtmoOffset = Value
        if Lighting:FindFirstChild("Atmosphere") then
            Lighting.Atmosphere.Offset = Value
        end
    end
})

world:AddLabel('Atmosphere Color'):AddColorPicker('AtmoColor', {
    Default = Color3.fromRGB(199, 199, 199),
    Title = 'Color',
    Callback = function(Value)
        getgenv().AtmoColor = Value
        if Lighting:FindFirstChild("Atmosphere") then
            Lighting.Atmosphere.Color = Value
        end
    end
})

world:AddLabel('Atmosphere Decay'):AddColorPicker('AtmoDecay', {
    Default = Color3.fromRGB(106, 112, 125),
    Title = 'Decay',
    Callback = function(Value)
        getgenv().AtmoDecay = Value
        if Lighting:FindFirstChild("Atmosphere") then
            Lighting.Atmosphere.Decay = Value
        end
    end
})

world:AddSlider('AtmoGlare', {
    Text = 'Atmosphere Glare',
    Default = 0,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        getgenv().AtmoGlare = Value
        if Lighting:FindFirstChild("Atmosphere") then
            Lighting.Atmosphere.Glare = Value
        end
    end
})

world:AddSlider('AtmoHaze', {
    Text = 'Atmosphere Haze',
    Default = 0,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(Value)
        getgenv().AtmoHaze = Value
        if Lighting:FindFirstChild("Atmosphere") then
            Lighting.Atmosphere.Haze = Value
        end
    end
})



-- Function to modify character body
function ModifyCharacterBody(character)
    -- Store original properties if not already stored
    if not getgenv().OriginalBodyProperties then
        getgenv().OriginalBodyProperties = {}
    end
    
    -- Store original clothing if not already stored
    if not getgenv().OriginalClothing then
        getgenv().OriginalClothing = {
            Shirt = character:FindFirstChildOfClass("Shirt"),
            Pants = character:FindFirstChildOfClass("Pants"),
            TShirt = character:FindFirstChildOfClass("ShirtGraphic")
        }
    end
    
    local material = getgenv().SelectedMaterial or Enum.Material.ForceField
    local color = getgenv().SelectedColor or Color3.new(1, 1, 1)
    local transparency = getgenv().BodyTransparency or 0
    
    -- Go through all parts in the character
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            -- Store original properties if not already stored
            if not getgenv().OriginalBodyProperties[part] then
                getgenv().OriginalBodyProperties[part] = {
                    Material = part.Material,
                    Color = part.Color,
                    Transparency = part.Transparency,
                    TextureID = part.TextureID
                }
            end
            
            -- Apply modifications
            part.Material = material
            part.Color = color
            part.Transparency = transparency
            part.TextureID = "" -- Remove texture
        end
    end
    
    -- Remove clothing
    local shirt = character:FindFirstChildOfClass("Shirt")
    local pants = character:FindFirstChildOfClass("Pants")
    local tshirt = character:FindFirstChildOfClass("ShirtGraphic")
    
    if shirt then shirt.Parent = nil end
    if pants then pants.Parent = nil end
    if tshirt then tshirt.Parent = nil end
end

-- Function to restore original body properties
function RestoreCharacterBody(character)
    if not getgenv().OriginalBodyProperties then return end
    
    -- Restore original properties
    for part, originalProps in pairs(getgenv().OriginalBodyProperties) do
        if part and part:IsDescendantOf(character) then
            part.Material = originalProps.Material
            part.Color = originalProps.Color
            part.Transparency = originalProps.Transparency
            part.TextureID = originalProps.TextureID
        end
    end
    
    -- Restore original clothing
    if getgenv().OriginalClothing then
        if getgenv().OriginalClothing.Shirt and getgenv().OriginalClothing.Shirt.Parent == nil then
            getgenv().OriginalClothing.Shirt.Parent = character
        end
        
        if getgenv().OriginalClothing.Pants and getgenv().OriginalClothing.Pants.Parent == nil then
            getgenv().OriginalClothing.Pants.Parent = character
        end
        
        if getgenv().OriginalClothing.TShirt and getgenv().OriginalClothing.TShirt.Parent == nil then
            getgenv().OriginalClothing.TShirt.Parent = character
        end
    end
    
    -- Clear the stored properties
    getgenv().OriginalBodyProperties = nil
    getgenv().OriginalClothing = nil
end

getgenv().dhSpecific = Tabs.Visuals:AddLeftGroupbox("Da Hood Elements")

-- Gun Texture Remover
dhSpecific:AddToggle('GunTextureRemover', {
    Text = 'Remove Gun Textures',
    Default = false,
    Callback = function(Value)
        getgenv().RemoveGunTextures = Value
        
        if Value then
            -- Initialize connection to modify guns
            if not getgenv().GunTextureConnection then
                getgenv().GunTextureConnection = game:GetService("RunService").Heartbeat:Connect(function()
                    local player = game.Players.LocalPlayer
                    if player.Character then
                        -- Find equipped gun
                        for _, tool in pairs(player.Character:GetChildren()) do
                            if tool:IsA("Tool") and tool:FindFirstChild("GunScript") then
                                -- It's a gun, modify it
                                -- Specifically target Default and Handle parts
                                local defaultPart = tool:FindFirstChild("Default")
                                local handlePart = tool:FindFirstChild("Handle")
                                
                                -- Process Default part if it exists - THIS IS THE MOST IMPORTANT PART
                                if defaultPart and defaultPart:IsA("BasePart") then
                                    defaultPart.TextureID = ""
                                    defaultPart.Material = getgenv().GunMaterial or Enum.Material.SmoothPlastic
                                    -- Apply color if enabled
                                    if getgenv().GunColor and getgenv().UseGunColor ~= false then
                                        defaultPart.Color = getgenv().GunColor
                                    end
                                    
                                    -- Clear all textures and decals in Default part
                                    for _, child in pairs(defaultPart:GetChildren()) do
                                        if child:IsA("Decal") or child:IsA("Texture") then
                                            child.Texture = ""
                                            child.TextureId = ""
                                        end
                                    end
                                end
                                
                                -- Process Handle part if it exists
                                if handlePart and handlePart:IsA("BasePart") then
                                    handlePart.Material = getgenv().GunMaterial or Enum.Material.SmoothPlastic
                                    -- Apply color if enabled
                                    if getgenv().GunColor and getgenv().UseGunColor ~= false then
                                        handlePart.Color = getgenv().GunColor
                                    end
                                    
                                    -- Clear all textures and decals in Handle part
                                    for _, child in pairs(handlePart:GetChildren()) do
                                        if child:IsA("Decal") or child:IsA("Texture") then
                                            child.Texture = ""
                                        end
                                    end
                                end
                                
                                -- Process all parts as a fallback
                                for _, part in pairs(tool:GetDescendants()) do
                                    if part:IsA("BasePart") then
                                        -- Remove texture ID
                                        if part:FindFirstChild("Texture") and part.Texture:IsA("Texture") then
                                            part.Texture.TextureId = ""
                                        end
                                        
                                        -- Remove decals
                                        for _, decal in pairs(part:GetChildren()) do
                                            if decal:IsA("Decal") or decal:IsA("Texture") then
                                                decal.Texture = ""
                                                decal.TextureId = ""
                                            end
                                        end
                                        
                                        -- Apply material
                                        part.Material = getgenv().GunMaterial or Enum.Material.SmoothPlastic
                                        
                                        -- Apply color if enabled
                                        if getgenv().GunColor and getgenv().UseGunColor ~= false then
                                            part.Color = getgenv().GunColor
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        else
            -- Disconnect
            if getgenv().GunTextureConnection then
                getgenv().GunTextureConnection:Disconnect()
                getgenv().GunTextureConnection = nil
                
                -- Reset gun appearance
                local player = game.Players.LocalPlayer
                if player.Character then
                    for _, tool in pairs(player.Character:GetChildren()) do
                        if tool:IsA("Tool") and tool:FindFirstChild("GunScript") then
                            for _, part in pairs(tool:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    -- Reset Default part if it exists
                                    local defaultPart = tool:FindFirstChild("Default")
                                    if defaultPart and defaultPart:IsA("BasePart") then
                                        defaultPart.Material = Enum.Material.SmoothPlastic
                                        -- Reset color
                                        defaultPart.Color = Color3.new(1, 1, 1) -- White/default
                                    end
                                    
                                    -- Reset Handle part if it exists
                                    local handlePart = tool:FindFirstChild("Handle")
                                    if handlePart and handlePart:IsA("BasePart") then
                                        handlePart.Material = Enum.Material.SmoothPlastic
                                        -- Reset color
                                        handlePart.Color = Color3.new(1, 1, 1) -- White/default
                                    end
                                    
                                    -- Reset all parts as fallback
                                    part.Material = Enum.Material.SmoothPlastic
                                    -- Reset color
                                    part.Color = Color3.new(1, 1, 1) -- White/default
                                    
                                    -- Restore textures (let the game handle default textures)
                                    for _, decal in pairs(part:GetChildren()) do
                                        if decal:IsA("Decal") or decal:IsA("Texture") then
                                            -- The game will likely re-apply proper textures on re-equip
                                            -- This just clears our modifications
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
})

dhSpecific:AddDropdown('GunMaterial', {
    Text = 'Gun Material',
    Values = {'Neon', 'ForceField', 'Glass', 'SmoothPlastic', 'Metal', 'Diamond', 'Foil'},
    Default = 3, -- SmoothPlastic
    Callback = function(Value)
        getgenv().GunMaterial = Enum.Material[Value]
    end
})

-- Add direct gun color modifier function for ease of use
local function ModifyEquippedGun()
    local player = game.Players.LocalPlayer
    if player and player.Character then
        for _, tool in pairs(player.Character:GetChildren()) do
            if tool:IsA("Tool") and tool:FindFirstChild("GunScript") then
                -- Focus especially on the Default part
                local defaultPart = tool:FindFirstChild("Default")
                if defaultPart and defaultPart:IsA("BasePart") then
                    defaultPart.Material = getgenv().GunMaterial or Enum.Material.SmoothPlastic
                    if getgenv().UseGunColor ~= false and getgenv().GunColor then
                        defaultPart.Color = getgenv().GunColor
                    end
                end
                
                -- Process other parts
                for _, part in pairs(tool:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Material = getgenv().GunMaterial or Enum.Material.SmoothPlastic
                        if getgenv().UseGunColor ~= false and getgenv().GunColor then
                            part.Color = getgenv().GunColor
                        end
                    end
                end
            end
        end
    end
end

dhSpecific:AddLabel('Gun Color'):AddColorPicker('GunColor', {
    Default = Color3.fromRGB(0, 255, 255),
    Title = 'Gun Color',
    Callback = function(Value)
        getgenv().GunColor = Value
        
        -- Apply color immediately if texture removal is enabled
        if getgenv().RemoveGunTextures then
            ModifyEquippedGun()
        end
    end
})

-- Add toggle for enabling/disabling custom gun color
dhSpecific:AddToggle('UseGunColor', {
    Text = 'Use Custom Gun Color',
    Default = true,
    Callback = function(Value)
        getgenv().UseGunColor = Value
        
        -- If disabled, reset colors to default if texture removal is active
        if not Value and getgenv().RemoveGunTextures then
            local player = game.Players.LocalPlayer
            if player and player.Character then
                for _, tool in pairs(player.Character:GetChildren()) do
                    if tool:IsA("Tool") and tool:FindFirstChild("GunScript") then
                        -- Reset Default part specifically
                        local defaultPart = tool:FindFirstChild("Default")
                        if defaultPart and defaultPart:IsA("BasePart") then
                            defaultPart.Color = Color3.new(1, 1, 1) -- Reset to white/default
                        end
                        
                        -- Reset other parts
                        for _, part in pairs(tool:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.Color = Color3.new(1, 1, 1) -- Reset to white/default
                            end
                        end
                    end
                end
            end
        elseif Value and getgenv().RemoveGunTextures then
            ModifyEquippedGun() -- Re-apply settings
        end
    end
})

dhSpecific:AddToggle('RainbowGun', {
    Text = 'Rainbow Gun',
    Default = false,
    Callback = function(Value)
        getgenv().RainbowGun = Value
    end
})

dhSpecific:AddSlider('GunTransparency', {
    Text = 'Gun Transparency',
    Default = 0,
    Min = 0,
    Max = 0.9,
    Rounding = 2,
    Callback = function(Value)
        getgenv().GunTransparency = Value
    end
})

dhSpecific:AddToggle('GunTrails', {
    Text = 'Gun Trails',
    Default = false,
    Callback = function(Value)
        getgenv().GunTrails = Value
        
        -- Remove existing trails if disabled
        if not Value then
            local player = game.Players.LocalPlayer
            if player.Character then
                for _, tool in pairs(player.Character:GetChildren()) do
                    if tool:IsA("Tool") and tool:FindFirstChild("GunScript") then
                        for _, part in pairs(tool:GetDescendants()) do
                            if part:IsA("BasePart") then
                                if part:FindFirstChild("GunTrail") then
                                    part.GunTrail:Destroy()
                                end
                                if part:FindFirstChild("TrailAttachment1") then
                                    part.TrailAttachment1:Destroy()
                                end
                                if part:FindFirstChild("TrailAttachment2") then
                                    part.TrailAttachment2:Destroy()
                                end
                            end
                        end
                    end
                end
            end
        end
    end
})

dhSpecific:AddLabel('Gun Trail Color'):AddColorPicker('GunTrailColor', {
    Default = Color3.fromRGB(0, 255, 255),
    Title = 'Trail Color',
    Callback = function(Value)
        getgenv().GunTrailColor = Value
        
        -- Update existing trails
        if getgenv().GunEffectsEnabled and getgenv().GunTrails then
            local player = game.Players.LocalPlayer
            if player.Character then
                for _, tool in pairs(player.Character:GetChildren()) do
                    if tool:IsA("Tool") and tool:FindFirstChild("GunScript") then
                        for _, part in pairs(tool:GetDescendants()) do
                            if part:IsA("BasePart") and part:FindFirstChild("GunTrail") then
                                part.GunTrail.Color = ColorSequence.new(Value)
                            end
                        end
                    end
                end
            end
        end
    end
})

-- Bullet Tracers
dhSpecific:AddToggle('BulletTracers', {
    Text = 'Bullet Tracers',
    Default = false,
    Callback = function(Value)
        getgenv().BulletTracersEnabled = Value
        
        -- Need to hook into the remote event that fires when bullets are shot
        if Value then
            if not getgenv().TracerHook then
                -- This assumes Da Hood uses a remote to handle bullets
                -- You'd need to identify the proper remote name
                local remote = game:GetService("ReplicatedStorage"):FindFirstChild("ShootEvent") or 
                               game:GetService("ReplicatedStorage"):FindFirstChild("ShootBullet") or
                               game:GetService("ReplicatedStorage"):FindFirstChild("Bullet")
                
                if remote and remote:IsA("RemoteEvent") then
                    getgenv().OldFireServer = getgenv().OldFireServer or remote.FireServer
                    
                    remote.FireServer = function(self, ...)
                        local args = {...}
                        -- Create tracer (assuming args[2] is position and args[3] is direction)
                        if args[2] and args[3] and typeof(args[2]) == "Vector3" and typeof(args[3]) == "Vector3" then
                            local startPos = args[2]
                            local endPos = args[2] + args[3] * 300 -- Extend direction
                            
                            -- Create beam
                            local beam = Instance.new("Part")
                            beam.Name = "BulletTracer"
                            beam.Anchored = true
                            beam.CanCollide = false
                            beam.Material = Enum.Material.Neon
                            beam.Transparency = 0.3
                            beam.Color = getgenv().TracerColor or Color3.fromRGB(255, 0, 0)
                            beam.Parent = workspace
                            
                            -- Position and size
                            local distance = (endPos - startPos).Magnitude
                            beam.Size = Vector3.new(0.1, 0.1, distance)
                            beam.CFrame = CFrame.new(startPos, endPos) * CFrame.new(0, 0, -distance/2)
                            
                            -- Animate and remove
                            spawn(function()
                                for i = 1, 10 do
                                    beam.Transparency = beam.Transparency + 0.07
                                    wait(0.03)
                                end
                                beam:Destroy()
                            end)
                        end
                        
                        return getgenv().OldFireServer(self, ...)
                    end
                end
            end
        else
            -- Restore original function
            local remote = game:GetService("ReplicatedStorage"):FindFirstChild("ShootEvent") or 
                           game:GetService("ReplicatedStorage"):FindFirstChild("ShootBullet") or
                           game:GetService("ReplicatedStorage"):FindFirstChild("Bullet")
            
            if remote and getgenv().OldFireServer then
                remote.FireServer = getgenv().OldFireServer
                getgenv().OldFireServer = nil
                getgenv().TracerHook = false
            end
        end
    end
})

dhSpecific:AddLabel('Tracer Color'):AddColorPicker('TracerColor', {
    Default = Color3.fromRGB(255, 0, 0),
    Title = 'Tracer Color',
    Callback = function(Value)
        getgenv().TracerColor = Value
    end
})

getgenv().cframeSpeedEnabled = false
getgenv().cframeSpeedKeybindActive = false
getgenv().cframeSpeed = 10
getgenv().noSlowdownEnabled = false
getgenv().noJumpCooldownEnabled = false


local uhhh = Tabs.Character:AddLeftGroupbox('Movement')

uhhh:AddToggle('CFrameSpeedToggle', {
    Text = 'cframe',
    Default = false,
    Callback = function(state)
        getgenv().cframeSpeedEnabled = state
        if not state then getgenv().cframeSpeedKeybindActive = false end
    end,
}):AddKeyPicker('CFrameSpeedKeybind', {
    Default = 'T',
    Text = 'Cframe',
    Mode = 'Toggle',
    Callback = function(state)
        if game:GetService("UserInputService"):GetFocusedTextBox() then return end
        if getgenv().cframeSpeedEnabled then getgenv().cframeSpeedKeybindActive = state end
    end,
})

uhhh:AddSlider('CFrameSpeedSlider', {
    Text = 'CFrame Speed',
    Default = 10,
    Min = 1,
    Max = 200,
    Rounding = 1,
    Callback = function(value)
        getgenv().cframeSpeed = value
    end,
})

uhhh:AddToggle('NoSlowdownToggle', {
    Text = 'No Slowdown',
    Default = false,
    Callback = function(state)
        getgenv().noSlowdownEnabled = state
    end,
})

uhhh:AddToggle('NoJumpCooldownToggle', {
    Text = 'No Jump Cooldown',
    Default = false,
    Callback = function(state)
        getgenv().noJumpCooldownEnabled = state
    end,
})

-- No Slowdown & No Jump Cooldown Handler
game:GetService('RunService').Heartbeat:Connect(function()
    local player = game.Players.LocalPlayer
    local character = player.Character
    local humanoid = character and character:FindFirstChild('Humanoid')
    
    if humanoid then
        -- No Slowdown - Keep WalkSpeed at minimum 16
        if getgenv().noSlowdownEnabled then
            if humanoid.WalkSpeed < 16 then
                humanoid.WalkSpeed = 16
            end
        end
        
        -- No Jump Cooldown - Keep JumpPower at exactly 50
        if getgenv().noJumpCooldownEnabled then
            if humanoid.JumpPower ~= 50 then
                humanoid.JumpPower = 50
            end
        end
    end
end)

game:GetService('RunService').RenderStepped:Connect(function()
    local player = game.Players.LocalPlayer
    local humanoid = player.Character and player.Character:FindFirstChild('Humanoid')
    if not humanoid then return end
end)

task.spawn(function()
    while task.wait(0) do
        local player = game.Players.LocalPlayer
        local character = player.Character
        local humanoid = character and character:FindFirstChild("Humanoid")
        if getgenv().cframeSpeedEnabled and getgenv().cframeSpeedKeybindActive and character and humanoid and humanoid.MoveDirection.Magnitude > 0 then
            character:TranslateBy(humanoid.MoveDirection * getgenv().cframeSpeed * task.wait() * 3)
        end
    end
end)


getgenv().FlightKeybind = Enum.KeyCode.X
getgenv().FlySpeed = 50
getgenv().FlightEnabled = false
getgenv().Flying = false

local function CreateCore()
    if workspace:FindFirstChild("Core") then workspace.Core:Destroy() end
    local Core = Instance.new("Part")
    Core.Name = "Core"
    Core.Size = Vector3.new(0.05, 0.05, 0.05)
    Core.CanCollide = false
    Core.Transparency = 1
    Core.Parent = workspace
    local Weld = Instance.new("Weld", Core)
    Weld.Part0 = Core
    Weld.Part1 = LocalPlayer.Character.HumanoidRootPart
    Weld.C0 = CFrame.new(0, 0, 0)
    return Core
end

local function StartFly()
    if getgenv().Flying then return end
    getgenv().Flying = true
    LocalPlayer.Character:FindFirstChildOfClass("Humanoid").PlatformStand = true
    local Core = CreateCore()
    local BV = Instance.new("BodyVelocity", Core)
    BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    BV.Velocity = Vector3.zero
    local BG = Instance.new("BodyGyro", Core)
    BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    BG.P = 9e4
    BG.CFrame = Core.CFrame
    RunService.RenderStepped:Connect(function()
        if not getgenv().Flying then return end
        local camera = workspace.CurrentCamera
        local moveDirection = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDirection = moveDirection + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDirection = moveDirection - Vector3.new(0, 1, 0) end
        BV.Velocity = moveDirection * getgenv().FlySpeed
        BG.CFrame = camera.CFrame
    end)
end

local function StopFly()
    if not getgenv().Flying then return end
    getgenv().Flying = false
    LocalPlayer.Character:FindFirstChildOfClass("Humanoid").PlatformStand = false
    if workspace:FindFirstChild("Core") then workspace.Core:Destroy() end
end

uhhh:AddToggle("FlightToggle", {
    Text = "Flight",
    Default = false,
    Callback = function(state)
        getgenv().FlightEnabled = state
        if not state then StopFly() end
    end
}):AddKeyPicker("FlightKeybindPicker", {
    Default = "X",
    Text = "Flight",
    Mode = "Toggle",
    Callback = function(state)
        if UserInputService:GetFocusedTextBox() then return end
        if state and getgenv().FlightEnabled then
            StartFly()
        else
            StopFly()
        end
    end
})

uhhh:AddSlider("FlySpeedSlider", {
    Text = "Fly Speed",
    Default = 50,
    Min = 10,
    Max = 5000,
    Rounding = 0,
    Callback = function(value)
        getgenv().FlySpeed = value
    end
})

getgenv().SpinbotEnabled = false
getgenv().SpinSpeed = 10

local function toggleSpinbot(state)
    if state then
        if not getgenv().SpinConnection then
            getgenv().SpinConnection = game:GetService("RunService").RenderStepped:Connect(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and not getgenv().Flying then
                    LocalPlayer.Character.Humanoid.AutoRotate = false
                    LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(getgenv().SpinSpeed), 0)
                end
            end)
        end
    else
        if getgenv().SpinConnection then
            getgenv().SpinConnection:Disconnect()
            getgenv().SpinConnection = nil
        end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.AutoRotate = true
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    if getgenv().SpinbotEnabled then
        toggleSpinbot(true)
    end
end)

uhhh:AddToggle('SpinbotToggle', {
    Text = 'Spinbot',
    Default = false,
    Callback = function(state)
        getgenv().SpinbotEnabled = state
        toggleSpinbot(state)
    end,
}):AddKeyPicker('SpinbotKeybind', {
    Default = 'N',
    Text = 'Spinbot',
    Mode = 'Toggle',
    Callback = function(state)
        if not UserInputService:GetFocusedTextBox() and getgenv().SpinbotEnabled then
            toggleSpinbot(state)
        end
    end,
})

uhhh:AddSlider('SpinSpeedSlider', {
    Text = 'Spin Speed',
    Default = 10,
    Min = 1,
    Max = 50,
    Rounding = 1,
    Callback = function(value)
        getgenv().SpinSpeed = value
    end,
})

local AnimationSpeed = 1

-- Animation objects
local FlossAnimation = Instance.new("Animation")
FlossAnimation.AnimationId = "rbxassetid://10714340543"

local DanceAnimation = Instance.new("Animation")
DanceAnimation.AnimationId = "rbxassetid://15609995579" -- Elton John Heart Skip dance

local OtherDanceAnimation = Instance.new("Animation")
OtherDanceAnimation.AnimationId = "rbxassetid://3189773368" -- Default dance animation

local OrangeJusticeAnimation = Instance.new("Animation")
OrangeJusticeAnimation.AnimationId = "rbxassetid://4265725525" -- Orange Justice

local DabAnimation = Instance.new("Animation")
DabAnimation.AnimationId = "rbxassetid://3361948183" -- Dab

local RobotAnimation = Instance.new("Animation")
RobotAnimation.AnimationId = "rbxassetid://616136790" -- Robot

local TwerkAnimation = Instance.new("Animation")
TwerkAnimation.AnimationId = "rbxassetid://5918726674" -- Twerk

local GriddyAnimation = Instance.new("Animation")
GriddyAnimation.AnimationId = "rbxassetid://11444443576" -- Griddy

local RenegadeAnimation = Instance.new("Animation")
RenegadeAnimation.AnimationId = "rbxassetid://4049037604" -- Renegade

local WormAnimation = Instance.new("Animation")
WormAnimation.AnimationId = "rbxassetid://4049037604" -- The Worm

local ThrillerAnimation = Instance.new("Animation")
ThrillerAnimation.AnimationId = "rbxassetid://616163682" -- Thriller

-- Custom dance animation (dynamically created)
local CustomAnimation = Instance.new("Animation")

-- Animation tracks
local flossAnimationTrack
local danceAnimationTrack
local otherDanceAnimationTrack
local orangeJusticeAnimationTrack
local robotAnimationTrack
local twerkAnimationTrack
local griddyAnimationTrack
local renegadeAnimationTrack
local wormAnimationTrack
local thrillerAnimationTrack
local customAnimationTrack

-- Persistent dance state (survives character resets)
local currentDance = "None"
local currentAnimationTrack = nil
local persistentDanceEnabled = false
local customDanceId = ""

local function loadAnimationTracks(character)
    local humanoid = character:WaitForChild("Humanoid")
    
    -- Load all animation tracks
    flossAnimationTrack = humanoid:LoadAnimation(FlossAnimation)
    flossAnimationTrack.Looped = true
    flossAnimationTrack.Priority = Enum.AnimationPriority.Action
    
    danceAnimationTrack = humanoid:LoadAnimation(DanceAnimation)
    danceAnimationTrack.Looped = true
    danceAnimationTrack.Priority = Enum.AnimationPriority.Action
    
    otherDanceAnimationTrack = humanoid:LoadAnimation(OtherDanceAnimation)
    otherDanceAnimationTrack.Looped = true
    otherDanceAnimationTrack.Priority = Enum.AnimationPriority.Action
    
    orangeJusticeAnimationTrack = humanoid:LoadAnimation(OrangeJusticeAnimation)
    orangeJusticeAnimationTrack.Looped = true
    orangeJusticeAnimationTrack.Priority = Enum.AnimationPriority.Action
    
    robotAnimationTrack = humanoid:LoadAnimation(RobotAnimation)
    robotAnimationTrack.Looped = true
    robotAnimationTrack.Priority = Enum.AnimationPriority.Action
    
    twerkAnimationTrack = humanoid:LoadAnimation(TwerkAnimation)
    twerkAnimationTrack.Looped = true
    twerkAnimationTrack.Priority = Enum.AnimationPriority.Action
    
    griddyAnimationTrack = humanoid:LoadAnimation(GriddyAnimation)
    griddyAnimationTrack.Looped = true
    griddyAnimationTrack.Priority = Enum.AnimationPriority.Action
    
    renegadeAnimationTrack = humanoid:LoadAnimation(RenegadeAnimation)
    renegadeAnimationTrack.Looped = true
    renegadeAnimationTrack.Priority = Enum.AnimationPriority.Action
    
    wormAnimationTrack = humanoid:LoadAnimation(WormAnimation)
    wormAnimationTrack.Looped = true
    wormAnimationTrack.Priority = Enum.AnimationPriority.Action
    
    thrillerAnimationTrack = humanoid:LoadAnimation(ThrillerAnimation)
    thrillerAnimationTrack.Looped = true
    thrillerAnimationTrack.Priority = Enum.AnimationPriority.Action
    
    -- Load custom animation track if ID is set
    if customDanceId ~= "" then
        CustomAnimation.AnimationId = "rbxassetid://" .. customDanceId
        customAnimationTrack = humanoid:LoadAnimation(CustomAnimation)
        customAnimationTrack.Looped = true
        customAnimationTrack.Priority = Enum.AnimationPriority.Action
    end
    
    -- Auto-resume dance after character loads (with slight delay for stability)
    if currentDance ~= "None" and persistentDanceEnabled then
        task.wait(1) -- Increased wait time for better stability
        playSelectedDance(currentDance)
    end
end

local function stopAllDances()
    local tracks = {
        flossAnimationTrack,
        danceAnimationTrack,
        otherDanceAnimationTrack,
        orangeJusticeAnimationTrack,
        robotAnimationTrack,
        twerkAnimationTrack,
        griddyAnimationTrack,
        renegadeAnimationTrack,
        wormAnimationTrack,
        thrillerAnimationTrack,
        customAnimationTrack
    }
    
    for _, track in pairs(tracks) do
        if track then
            track:Stop()
        end
    end
    currentAnimationTrack = nil
end

local function playSelectedDance(danceName)
    stopAllDances()
    
    local danceMap = {
        ["Floss Dance"] = flossAnimationTrack,
        ["Heart Skip Dance"] = danceAnimationTrack,
        ["Default Dance"] = otherDanceAnimationTrack,
        ["Orange Justice"] = orangeJusticeAnimationTrack,
        ["Robot"] = robotAnimationTrack,
        ["Twerk"] = twerkAnimationTrack,
        ["Zesty"] = griddyAnimationTrack,
        ["Renegade"] = renegadeAnimationTrack,
        ["Shake"] = wormAnimationTrack,
        ["Thriller"] = thrillerAnimationTrack,
        ["Custom Dance"] = customAnimationTrack
    }
    
    local selectedTrack = danceMap[danceName]
    if selectedTrack then
        selectedTrack:Play()
        selectedTrack:AdjustSpeed(AnimationSpeed)
        currentAnimationTrack = selectedTrack
    end
end

local function updateCustomDance(id)
    customDanceId = id
    if customDanceId ~= "" then
        CustomAnimation.AnimationId = "rbxassetid://" .. customDanceId
        
        -- Reload custom animation track for current character
        if game:GetService("Players").LocalPlayer.Character then
            local humanoid = game:GetService("Players").LocalPlayer.Character:FindFirstChild("Humanoid")
            if humanoid then
                if customAnimationTrack then
                    customAnimationTrack:Stop()
                end
                customAnimationTrack = humanoid:LoadAnimation(CustomAnimation)
                customAnimationTrack.Looped = true
                customAnimationTrack.Priority = Enum.AnimationPriority.Action
            end
        end
    end
end

-- Character connection events - this ensures dance continues after reset/death
game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function(character)
    loadAnimationTracks(character)
end)

-- Load animations for current character if it exists
if game:GetService("Players").LocalPlayer.Character then
    loadAnimationTracks(game:GetService("Players").LocalPlayer.Character)
end

-- UI Components (assuming stutz and Tabs are defined elsewhere)
local stutz = Tabs.Character:AddRightGroupbox('Misc')

-- Custom dance ID input
stutz:AddInput('CustomDanceID', {
    Default = '',
    Numeric = true,
    Finished = false,
    Text = 'Custom Dance ID',
    Tooltip = 'Enter animation ID (numbers only, rbxassetid:// will be added automatically)',
    Placeholder = 'Animation ID',
    Callback = function(input)
        local id = tostring(input):gsub("%D", "") -- Remove non-numeric characters
        if id ~= "" then
            updateCustomDance(id)
            Library:Notify("Custom dance ID set to: " .. id, 2)
        else
            customDanceId = ""
            customAnimationTrack = nil
            Library:Notify("Custom dance ID cleared", 2)
        end
    end
})

-- Dance selection dropdown (now includes Custom Dance option)
stutz:AddDropdown("DanceDropdown", {
    Values = {
        "None", 
        "Floss Dance", 
        "Heart Skip Dance", 
        "Default Dance",
        "Orange Justice",
        "Robot",
        "Twerk",
        "Zesty",
        "Renegade",
        "Shake",
        "Thriller",
        "Custom Dance"
    },
    Default = 1, -- "None"
    Multi = false,
    Text = "Dance Selection",
    Callback = function(value)
        currentDance = value
        if value == "None" then
            persistentDanceEnabled = false
            stopAllDances()
        elseif value == "Custom Dance" and customDanceId == "" then
            Library:Notify("Please set a custom dance ID first!", 2)
        else
            persistentDanceEnabled = true
            playSelectedDance(value)
        end
    end
})

-- Animation speed slider
stutz:AddSlider("AnimationSpeedSlider", {
    Text = 'Animation Speed',
    Default = 1,
    Min = 0.1,
    Max = 36,
    Rounding = 1,
    Compact = false,
    Callback = function(Value)
        AnimationSpeed = Value
        if currentAnimationTrack and currentAnimationTrack.IsPlaying then
            currentAnimationTrack:AdjustSpeed(AnimationSpeed)
        end
    end
})
stutz:AddToggle("NoClipToggle", {
    Text = "NoClip",
    Default = false,
    Callback = function(state)
        noClipEnabled = state
    end
}):AddKeyPicker("NoClipKeybindPicker", {
    Default = "J",
    Text = "NoClip",
    Mode = "Toggle",
    Callback = function(state)
        if noClipEnabled then
            local character = game:GetService("Players").LocalPlayer.Character
            if character then
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") and not part.Name:match("Arm") and not part.Name:match("Leg") then
                        part.CanCollide = state
                    end
                end
            end
        end
    end
})


local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer

-- Create desync setback part
local desync_setback = Instance.new("Part")
desync_setback.Name = "Desync Setback"
desync_setback.Parent = workspace
desync_setback.Size = Vector3.new(2, 2, 1)
desync_setback.CanCollide = false
desync_setback.Anchored = true
desync_setback.Transparency = 1

-- Main configuration variables
local desync = {
    enabled = false,
    mode = "Void",
    teleportPosition = Vector3.new(0, 0, 0),
    old_position = nil,
    voidSpamActive = false,
    toggleEnabled = false
}

local fakeLag = {
    enabled = false,
    intensity = 5,
    toggleEnabled = false,
    positions = {},
    maxPositions = 30,
    updateTimer = 0,
    updateInterval = 0.1  -- Base interval, adjusted by intensity
}

-- Helper functions
function resetCamera()
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            workspace.CurrentCamera.CameraSubject = humanoid
        end
    end
end

function toggleDesync(state)
    desync.enabled = state
    if desync.enabled then
        workspace.CurrentCamera.CameraSubject = desync_setback
        Library:Notify("Desync Enabled '" .. desync.mode .. "' ZestHub.lol $", 2)
    else
        resetCamera()
        Library:Notify("Desync Disabled '" .. desync.mode .. "' ZestHub.lol $", 2)
    end
end

function setDesyncMode(mode)
    desync.mode = mode
end

function toggleFakeLag(state)
    fakeLag.enabled = state
    if fakeLag.enabled then
        Library:Notify("Fake Lag Enabled (Intensity: " .. fakeLag.intensity .. ") ZestHub.lol $", 2)
        -- Clear position history when enabling
        fakeLag.positions = {}
    else
        Library:Notify("Fake Lag Disabled ZestHub.lol $", 2)
        -- Reset character position when disabling if needed
        if LocalPlayer.Character and #fakeLag.positions > 0 then
            local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                rootPart.CFrame = fakeLag.positions[1]
            end
            fakeLag.positions = {}
        end
    end
end

-- Enhanced Da Hood Desync & Fake Lag System with True Network Desync and Fake Position
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = game.Players.LocalPlayer



-- Fake Lag Configuration
local fakeLag = {
    enabled = false,
    toggleEnabled = false,
    intensity = 5,
    positions = {},
    updateTimer = 0,
    updateInterval = 0.125,
    maxPositions = 15
}

-- Network Desync Configuration
local networkDesync = {
    enabled = false,
    lastNetworkPosition = Vector3.new(),
    networkDelay = 0.5,
    networkTimer = 0,
    savedCFrames = {}
}

-- Fake Position Configuration
local fakePosition = {
    enabled = false,
    fakeOffset = Vector3.new(0, -50, 0),
    visualPosition = Vector3.new(),
    realPosition = Vector3.new()
}

-- Create desync setback part
local desync_setback = Instance.new("Part")
desync_setback.Name = "DesyncSetback"
desync_setback.Anchored = true
desync_setback.CanCollide = false
desync_setback.Transparency = 1
desync_setback.Size = Vector3.new(4, 6, 4)
desync_setback.Parent = workspace

-- Functions
function toggleDesync(state)
    desync.enabled = state
    if state then
        print("Desync enabled with method:", desync.mode)
    else
        print("Desync disabled")
        -- Reset position when disabled
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            workspace.CurrentCamera.CameraSubject = LocalPlayer.Character.Humanoid
        end
    end
end

function toggleFakeLag(state)
    fakeLag.enabled = state
    if state then
        print("Fake Lag enabled with intensity:", fakeLag.intensity)
        fakeLag.positions = {}
    else
        print("Fake Lag disabled")
        fakeLag.positions = {}
    end
end

function toggleNetworkDesync(state)
    networkDesync.enabled = state
    if state then
        print("Network Desync enabled")
        networkDesync.savedCFrames = {}
    else
        print("Network Desync disabled")
    end
end

function toggleFakePosition(state)
    fakePosition.enabled = state
    if state then
        print("Fake Position enabled")
    else
        print("Fake Position disabled")
    end
end

function setDesyncMode(mode)
    desync.mode = mode
    print("Desync mode set to:", mode)
end

-- Network Desync Function (True Network Manipulation)
function performNetworkDesync()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local rootPart = LocalPlayer.Character.HumanoidRootPart
    local currentCFrame = rootPart.CFrame
    
    -- Store real position
    table.insert(networkDesync.savedCFrames, 1, currentCFrame)
    
    -- Limit stored positions
    if #networkDesync.savedCFrames > 10 then
        table.remove(networkDesync.savedCFrames)
    end
    
    -- Send fake network data to server
    pcall(function()
        if ReplicatedStorage:FindFirstChild("MainEvent") then
            -- Create fake movement data
            local fakePosition = currentCFrame.Position + Vector3.new(
                math.random(-100, 100),
                math.random(-100, 100),
                math.random(-100, 100)
            )
            
            -- Send multiple conflicting position updates to desync network
            for i = 1, 3 do
                ReplicatedStorage.MainEvent:FireServer("UpdatePosition", fakePosition)
                wait(0.01)
            end
        end
    end)
end

-- Fake Position Function
function applyFakePosition()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local rootPart = LocalPlayer.Character.HumanoidRootPart
    fakePosition.realPosition = rootPart.Position
    
    -- Apply visual fake position
    fakePosition.visualPosition = fakePosition.realPosition + fakePosition.fakeOffset
    
    -- Manipulate visual appearance while keeping hitbox in real position
    pcall(function()
        -- Create visual deception
        local fakeRoot = rootPart:Clone()
        fakeRoot.Name = "FakeRoot"
        fakeRoot.Parent = workspace
        fakeRoot.CFrame = CFrame.new(fakePosition.visualPosition)
        fakeRoot.Transparency = 0.5
        
        -- Remove fake after short time
        game:GetService("Debris"):AddItem(fakeRoot, 0.1)
    end)
end

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// LocalPlayer
local LocalPlayer = Players.LocalPlayer

--// Core Variables
local fakeLag = {
    enabled = false,
    interval = 0.45, -- delay in seconds (the higher, the more "lag")
    duration = 0.15, -- time frozen
    timer = 0,
    teleporting = false,
    offset = Vector3.new(50, 0, 0), -- fake position offset
}

--// UI Setup
local FakeLagBox = Tabs.Character:AddRightGroupbox("Fake Lag/Pos (Da Hood)")

FakeLagBox:AddToggle("FakeLagToggle", {
    Text = "Enable Fake Lag Pos",
    Default = false,
    Callback = function(state)
        fakeLag.enabled = state
        if not state then
            Library:Notify("Fake Lag Disabled")
        else
            Library:Notify("Fake Lag Enabled")
        end
    end,
}):AddKeyPicker("FakeLagKeybind", {
    Default = "H",
    Text = "Fake Lag Hotkey",
    Mode = "Toggle",
    Callback = function()
        if not UserInputService:GetFocusedTextBox() then
            Toggles.FakeLagToggle:SetState(not Toggles.FakeLagToggle.Value)
        end
    end,
})

FakeLagBox:AddSlider("LagDelaySlider", {
    Text = "Lag Delay",
    Default = 0.45,
    Min = 0.1,
    Max = 1,
    Rounding = 2,
    Callback = function(value)
        fakeLag.interval = value
    end
})

FakeLagBox:AddSlider("OffsetDist", {
    Text = "Offset Distance",
    Default = 50,
    Min = 10,
    Max = 100,
    Rounding = 1,
    Callback = function(value)
        fakeLag.offset = Vector3.new(value, 0, 0)
    end
})

--// Main Fake Lag Logic
RunService.Heartbeat:Connect(function(dt)
    if not fakeLag.enabled or not LocalPlayer.Character then return end

    local char = LocalPlayer.Character
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    fakeLag.timer += dt

    if fakeLag.timer >= fakeLag.interval and not fakeLag.teleporting then
        fakeLag.teleporting = true
        fakeLag.timer = 0

        -- Save real position
        local realCF = root.CFrame

        -- Fake offset position
        local fakePos = realCF.Position + fakeLag.offset

        -- Move to fake position
        root.CFrame = CFrame.new(fakePos)

        -- Fake server call (used in Da Hood)
        pcall(function()
            ReplicatedStorage.MainEvent:FireServer("TeleportDetect", fakePos)
        end)

        -- Wait (duration = how long you're "lagged")
        task.delay(fakeLag.duration, function()
            if not fakeLag.enabled then return end

            -- Return to real position
            root.CFrame = realCF

            fakeLag.teleporting = false
        end)
    end
end)



-- UI Components
local DesyncBox = Tabs.Character:AddRightGroupbox("Anti Aim")

DesyncBox:AddToggle('DesyncToggle', {
    Text = 'Anti Aim',
    Default = false,
    Callback = function(state)
        desync.toggleEnabled = state
        if state then
            Library:Notify("Anti Aim Enabled ZestHub.lol $" .. desync.mode)
        else
            Library:Notify("Anti Aim Disabled ZestHub.lol $" .. desync.mode)
            toggleDesync(false)
        end
    end,
}):AddKeyPicker('DesyncKeybind', {
    Default = 'V',
    Text = 'Desync',
    Mode = 'Toggle',
    Callback = function(state)
        if not desync.toggleEnabled or UserInputService:GetFocusedTextBox() then return end
        toggleDesync(not desync.enabled)

        -- Notification logic when keybind is pressed
        if desync.enabled then
            Library:Notify("Anti Aim Enabled ZestHub.lol $" .. desync.mode)
        else
            Library:Notify("Anti Aim Disabled ZestHub.lol $" .. desync.mode)
        end
    end,
})


-- Network Desync Toggle
--DesyncBox:AddToggle('NetworkDesyncToggle', {
--    Text = 'Network Desync',
--    Default = false,
--    Callback = function(state)
--        toggleNetworkDesync(state)
--    end,
--}):AddKeyPicker('NetworkDesyncKeybind', {
--    Default = 'N',
--    Text = 'Network Desync',
--    Mode = 'Toggle',
--})

-- Fake Position Toggle
--DesyncBox:AddToggle('FakePositionToggle', {
--    Text = 'Fake Position',
--    Default = false,
--    Callback = function(state)
--        toggleFakePosition(state)
--    end,
--}):AddKeyPicker('FakePositionKeybind', {
--    Default = 'F',
--    Text = 'Fake Position',
--    Mode = 'Toggle',
--})

-- Desync Method Dropdown
DesyncBox:AddDropdown('DesyncMethodDropdown', {
    Values = {"Destroy Cheaters", "Underground", "Void Spam", "Void", "Rotation", "Network Chaos"},
    Default = "Void",
    Multi = false,
    Text = 'Method',
    Callback = function(selected)
        setDesyncMode(selected)
    end
})

-- Fake Position Offset Sliders
--DesyncBox:AddSlider('FakePositionX', {
--    Text = 'Fake Offset X',
--   Default = 0,
--    Min = -100,
--    Max = 100,
--    Rounding = 1,
--    Compact = false,
--    Callback = function(value)
--        fakePosition.fakeOffset = Vector3.new(value, fakePosition.fakeOffset.Y, fakePosition.fakeOffset.Z)
--    end
--})

--DesyncBox:AddSlider('FakePositionY', {
--    Text = 'Fake Offset Y',
--    Default = -50,
--    Min = -100,
 --   Max = 100,
 --   Rounding = 1,
 --   Compact = false,
 --   Callback = function(value)
 ---       fakePosition.fakeOffset = Vector3.new(fakePosition.fakeOffset.X, value, fakePosition.fakeOffset.Z)
--end
--})


-- Main Desync Logic
RunService.Heartbeat:Connect(function()
    if desync.enabled and LocalPlayer.Character then
        local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            desync.old_position = rootPart.CFrame

            if desync.mode == "Destroy Cheaters" then
                desync.teleportPosition = Vector3.new(11223344556677889900, 1, 1)

            elseif desync.mode == "Underground" then
                desync.teleportPosition = rootPart.Position - Vector3.new(0, 12, 0)

            elseif desync.mode == "Void Spam" then
                desync.teleportPosition = math.random(1, 2) == 1 and desync.old_position.Position or Vector3.new(
                    math.random(10000, 50000),
                    math.random(10000, 50000),
                    math.random(10000, 50000)
                )

            elseif desync.mode == "Void" then
                desync.teleportPosition = Vector3.new(
                    rootPart.Position.X + math.random(-444444, 444444),
                    rootPart.Position.Y + math.random(-444444, 444444),
                    rootPart.Position.Z + math.random(-44444, 44444)
                )
                
            elseif desync.mode == "Network Chaos" then
                -- Advanced network manipulation
                desync.teleportPosition = Vector3.new(
                    rootPart.Position.X + math.random(-999999, 999999),
                    rootPart.Position.Y + math.random(-999999, 999999),
                    rootPart.Position.Z + math.random(-999999, 999999)
                )
            end

            if desync.mode ~= "Rotation" then
                rootPart.CFrame = CFrame.new(desync.teleportPosition)
                workspace.CurrentCamera.CameraSubject = desync_setback

                RunService.RenderStepped:Wait()

                desync_setback.CFrame = desync.old_position * CFrame.new(0, rootPart.Size.Y / 2 + 0.5, 0)
                rootPart.CFrame = desync.old_position
            end
        end
    end
end)

-- Network Desync Logic
RunService.Heartbeat:Connect(function(deltaTime)
    if networkDesync.enabled then
        networkDesync.networkTimer = networkDesync.networkTimer + deltaTime
        
        if networkDesync.networkTimer >= networkDesync.networkDelay then
            networkDesync.networkTimer = 0
            performNetworkDesync()
        end
    end
end)

-- Fake Position Logic
RunService.RenderStepped:Connect(function()
    if fakePosition.enabled then
        applyFakePosition()
    end
end)

-- Enhanced Fake Lag Logic
RunService.Heartbeat:Connect(function(deltaTime)
    if not fakeLag.enabled or not LocalPlayer.Character then return end
    
    local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    -- Store current position
    if #fakeLag.positions == 0 then
        table.insert(fakeLag.positions, rootPart.CFrame)
    end
    
    -- Update timer
    fakeLag.updateTimer = fakeLag.updateTimer + deltaTime
    
    -- Check if it's time to update positions
    if fakeLag.updateTimer >= fakeLag.updateInterval then
        fakeLag.updateTimer = 0
        
        -- Store new position
        table.insert(fakeLag.positions, 1, rootPart.CFrame)
        
        -- Limit stored positions based on intensity
        while #fakeLag.positions > fakeLag.maxPositions do
            table.remove(fakeLag.positions)
        end
        
        -- Apply enhanced lag effect
        local lagIndex = math.ceil(#fakeLag.positions * (0.6 + (fakeLag.intensity * 0.04)))
        if fakeLag.positions[lagIndex] then
            rootPart.CFrame = fakeLag.positions[lagIndex]
            
            -- Add network confusion
            if networkDesync.enabled then
                pcall(function()
                    ReplicatedStorage.MainEvent:FireServer("ConfuseNetwork", rootPart.Position)
                end)
            end
        end
    end
end)

-- Compatibility and Priority System
RunService.RenderStepped:Connect(function()
    -- Priority: Network Desync > Fake Position > Regular Desync > Fake Lag
    if networkDesync.enabled and desync.enabled and LocalPlayer.Character then
        local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            -- Combine network desync with regular desync for maximum chaos
            if #networkDesync.savedCFrames > 0 then
                table.insert(fakeLag.positions, 1, networkDesync.savedCFrames[1])
            end
        end
    end
    
    -- Maintain fake lag positions even with other systems active
    if fakeLag.enabled and (desync.enabled or networkDesync.enabled) and LocalPlayer.Character then
        local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if rootPart and desync.old_position then
            table.insert(fakeLag.positions, 1, desync.old_position)
            
            -- Limit stored positions
            while #fakeLag.positions > fakeLag.maxPositions do
                table.remove(fakeLag.positions)
            end
        end
    end
end)

-- Ensure both systems can work together or independently
local function disableConflictingFeatures()
    if fakeLag.enabled and desync.enabled then
        -- If the user enables both, show a notification but allow both to run
        -- The render step connection will handle compatibility
        Library:Notify("Using both Fake Lag and Desync simultaneously - Desync will take priority", 3)
    end
end

-- Hook into the toggle callbacks to check for conflicts
local oldDesyncCallback = Toggles.DesyncToggle.Callback
Toggles.DesyncToggle.Callback = function(state)
    oldDesyncCallback(state)
    disableConflictingFeatures()
end

local oldFakeLagCallback = Toggles.FakeLagToggle.Callback
Toggles.FakeLagToggle.Callback = function(state)
    oldFakeLagCallback(state)
    disableConflictingFeatures()
end

local antifling = nil

stutz:AddToggle("AntiflingToggle", {
    Text = "Antifling",
    Default = false,
    Callback = function(state)
        if state then
            antifling = game:GetService("RunService").Stepped:Connect(function()
                for _, player in pairs(game:GetService("Players"):GetPlayers()) do
                    if player ~= game.Players.LocalPlayer and player.Character then
                        for _, v in pairs(player.Character:GetDescendants()) do
                            if v:IsA("BasePart") then
                                v.CanCollide = false
                            end
                        end
                    end
                end
            end)
        else
            if antifling then
                antifling:Disconnect()
                antifling = nil
            end
        end
    end
})


getgenv().RemoveShootAnimationsEnabled = false
getgenv().ShootAnimationIds = {
    ["rbxassetid://2807049953"] = true, 
    ["rbxassetid://2809413000"] = true, 
    ["rbxassetid://2809419094"] = true,  
    ["rbxassetid://507768375"] = true,
    ["rbxassetid://507755388"] = true,
    ["rbxassetid://2807049953"] = true,
    ["rbxassetid://2877910736"] = true 
}

getgenv().StopAnimationTracks = function(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
            if getgenv().ShootAnimationIds[track.Animation.AnimationId] then
                track:Stop()
            end
        end
    end
end

getgenv().MonitorCharacter = function(character)
    character.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("AnimationTrack") and getgenv().RemoveShootAnimationsEnabled then
            if getgenv().ShootAnimationIds[descendant.Animation.AnimationId] then
                descendant:Stop()
            end
        end
    end)
end

getgenv().MonitorPlayers = function()
    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        local character = player.Character or player.CharacterAdded:Wait()
        getgenv().StopAnimationTracks(character)
        getgenv().MonitorCharacter(character)

        player.CharacterAdded:Connect(function(newCharacter)
            getgenv().StopAnimationTracks(newCharacter)
            getgenv().MonitorCharacter(newCharacter)
        end)
    end

    game:GetService("Players").PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            getgenv().StopAnimationTracks(character)
            getgenv().MonitorCharacter(character)
        end)
    end)
end

getgenv().MonitorAnimations = function()
    game:GetService("RunService").RenderStepped:Connect(function()
        if getgenv().RemoveShootAnimationsEnabled then
            for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
                local character = player.Character
                if character then
                    getgenv().StopAnimationTracks(character)
                end
            end
        end
    end)
end

GunMods:AddToggle("AntiflingToggle", {
    Text = "remove shoot animations",
    Default = false,
    Callback = function(enabled)
        getgenv().RemoveShootAnimationsEnabled = enabled
        if enabled then
            getgenv().MonitorPlayers()
            task.spawn(getgenv().MonitorAnimations)
        end
    end
})


-- Enhanced Da Hood Kick Script (keeping original structure)
getgenv().Test = false
getgenv().SoundId = "6899466638"
getgenv().ToolEnabled = false
getgenv().KickForce = 800 -- Customizable kick force
getgenv().JumpForce = 800 -- Customizable vertical force
getgenv().AnimSpeed = 3.4 -- Animation speed multiplier
getgenv().CooldownTime = 1.4 -- Time before kick can be used again

-- Better tool creation with more features
getgenv().CreateTool = function()
    -- Clean up any existing tool first
    getgenv().RemoveTool()
    
    -- Create the tool
    getgenv().Tool = Instance.new("Tool")
    getgenv().Tool.RequiresHandle = false
    getgenv().Tool.Name = "[Kick]"
    getgenv().Tool.TextureId = "rbxassetid://483225199"
    
    -- Create the animation
    getgenv().Animation = Instance.new("Animation")
    getgenv().Animation.AnimationId = "rbxassetid://2788306916"
    
    -- Cooldown system
    getgenv().OnCooldown = false
    
    -- Tool activation with improvements
    getgenv().Tool.Activated:Connect(function()
        -- Don't allow spamming
        if getgenv().OnCooldown then return end
        getgenv().OnCooldown = true
        
        -- Activate kick
        getgenv().Test = true
        
        -- Better player reference caching
        getgenv().Player = game.Players.LocalPlayer
        getgenv().Character = getgenv().Player.Character or getgenv().Player.CharacterAdded:Wait()
        getgenv().Humanoid = getgenv().Character:FindFirstChild("Humanoid")
        
        -- Play animation if humanoid exists
        if getgenv().Humanoid then
            getgenv().AnimationTrack = getgenv().Humanoid:LoadAnimation(getgenv().Animation)
            getgenv().AnimationTrack:AdjustSpeed(getgenv().AnimSpeed)
            getgenv().AnimationTrack:Play()
        end
        
        -- Wait before playing sound
        task.wait(0.6)
        
        -- Sound handling with improved error checking
        getgenv().Boombox = game.Players.LocalPlayer.Backpack:FindFirstChild("[Boombox]")
        if getgenv().Boombox then
            -- Use boombox if available
            getgenv().Boombox.Parent = game.Players.LocalPlayer.Character
            pcall(function() -- Added error handling
                game:GetService("ReplicatedStorage").MainEvent:FireServer("Boombox", tonumber(getgenv().SoundId))
            end)
            getgenv().Boombox.RequiresHandle = false
            getgenv().Boombox.Parent = game.Players.LocalPlayer.Backpack
            
            -- Stop boombox sound after delay
            task.wait(1)
            pcall(function() -- Added error handling
                game:GetService("ReplicatedStorage").MainEvent:FireServer("BoomboxStop")
            end)
        else
            -- Fallback to workspace sound
            getgenv().Sound = Instance.new("Sound", workspace)
            getgenv().Sound.SoundId = "rbxassetid://" .. getgenv().SoundId
            getgenv().Sound:Play()
            
            -- Stop and clean up sound
            task.wait(1)
            getgenv().Sound:Stop()
            getgenv().Sound:Destroy() -- Added proper cleanup
        end
        
        -- End kick after delay
        task.wait(1.4)
        getgenv().Test = false
        
        -- Reset cooldown after delay
        task.delay(getgenv().CooldownTime, function()
            getgenv().OnCooldown = false
        end)
    end)
    
    -- Parent tool to backpack
    getgenv().Tool.Parent = game.Players.LocalPlayer:WaitForChild("Backpack")
end

-- Improved tool removal with better error handling
getgenv().RemoveTool = function()
    getgenv().Player = game.Players.LocalPlayer
    getgenv().Tool = getgenv().Player.Backpack:FindFirstChild("[Kick]") or 
                    (getgenv().Player.Character and getgenv().Player.Character:FindFirstChild("[Kick]"))
    if getgenv().Tool then 
        getgenv().Tool:Destroy() 
    end
end

-- Optimized heartbeat connection with better vector handling
game:GetService("RunService").Heartbeat:Connect(function()
    if getgenv().Test then
        -- Better character reference without creating new variables each time
        local character = game.Players.LocalPlayer.Character
        if not character then return end
        
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        -- Store original velocity
        local originalVelocity = rootPart.Velocity
        
        -- Apply customizable kick force
        local lookVec = rootPart.CFrame.LookVector
        rootPart.Velocity = Vector3.new(
            lookVec.X * getgenv().KickForce, 
            getgenv().JumpForce, 
            lookVec.Z * getgenv().KickForce
        )
        
        -- Reset velocity after one frame
        game:GetService("RunService").RenderStepped:Wait()
        rootPart.Velocity = originalVelocity
    end
end)

-- Hotkey support (optional)
getgenv().HotkeyEnabled = true
getgenv().Hotkey = Enum.KeyCode.K

game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if getgenv().HotkeyEnabled and input.KeyCode == getgenv().Hotkey and getgenv().Tool then
        -- Simulate tool activation when hotkey is pressed
        if not getgenv().OnCooldown then
            -- Fire the same code that would run when the tool is activated
            getgenv().Tool.Activated:Fire()
        end
    end
end)

-- Check if UI library exists and set up UI accordingly
if Tabs then
    local stuffs = Tabs.Misc:AddRightGroupbox("Enhanced Kick")
    
    -- Main toggle
    stuffs:AddToggle("ToolToggle", {
        Text = "Pqnd4 kick",
        Default = false,
        Callback = function(state)
            getgenv().ToolEnabled = state
            if state then 
                getgenv().CreateTool() 
            else 
                getgenv().RemoveTool() 
            end
        end
    })
    
    -- Kick force slider
    stuffs:AddSlider("KickForce", {
        Text = "Kick Force",
        Default = 800,
        Min = 100,
        Max = 2000,
        Rounding = 0,
        Callback = function(value)
            getgenv().KickForce = value
        end
    })
    
    -- Jump force slider
    stuffs:AddSlider("JumpForce", {
        Text = "Jump Force",
        Default = 800,
        Min = 100,
        Max = 2000,
        Rounding = 0,
        Callback = function(value)
            getgenv().JumpForce = value
        end
    })
end

game.Players.LocalPlayer.CharacterAdded:Connect(function()
    if getgenv().ToolEnabled then task.wait(1) getgenv().CreateTool() end
end)



local Modifications = Tabs.Misc:AddRightGroupbox("Modifications")

local antiStompActive = false
local flashbackActive = false
local lastPosition = nil

local function startAntiStomp()
    local RunService = game:GetService("RunService")

    local function checkAndKill()
        local chr = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hum = chr:WaitForChild("Humanoid", 5)
        local bodyEffects = chr:WaitForChild("BodyEffects", 5)

        if not bodyEffects or not hum then
            warn("BodyEffects or Humanoid not found in the character!")
            return
        end

        local koValue = bodyEffects:WaitForChild("K.O", 5)
        if not koValue then
            warn("K.O value not found!")
            return
        end

        local connection
        connection = RunService.Heartbeat:Connect(function()
            if not antiStompActive then
                connection:Disconnect()
                return
            end

            if koValue.Value == true and hum.Health > 0 then
                if flashbackActive then
                    lastPosition = chr:GetPrimaryPartCFrame()
                end
                hum.Health = 0
            end
        end)
    end

    checkAndKill()

    LocalPlayer.CharacterAdded:Connect(function(newCharacter)
        if antiStompActive then
            checkAndKill()

            if flashbackActive and lastPosition then
                local rootPart = newCharacter:WaitForChild("HumanoidRootPart", 5)
                if rootPart then
                    while (rootPart.Position - lastPosition.Position).Magnitude > 5 do
                        rootPart.CFrame = lastPosition
                        task.wait()
                    end
                end
                lastPosition = nil
            end
        end
    end)
end

Modifications:AddToggle('AntiStomp', {
    Text = 'AntiStomp',
    Default = false,
    Callback = function(state)
        antiStompActive = state
        if state then
            startAntiStomp()
        end
    end,
})

Modifications:AddToggle('Flashback', {
    Text = 'Flashback',
    Default = false,
    Callback = function(state)
        flashbackActive = state
    end,
})

getgenv().XZQW_ENABLED = false
getgenv().HIDE_ANIMATIONS = false
getgenv().YRWL_Connection___ = {}
getgenv().BlockedAnimations = {
    "rbxassetid://2788289281",
    "rbxassetid://507766388",
    "rbxassetid://2788292075",
    "rbxassetid://278829075",
    "rbxassetid://4798175381",
    "rbxassetid://2953512033",
    "rbxassetid://2788309982",
    "rbxassetid://2788312709",
    "rbxassetid://2788313790",
    "rbxassetid://2788316350",
    "rbxassetid://2788315673",
    "rbxassetid://2788314837"
}


ReplicatedStorage:WaitForChild("ClientAnimations").Block.AnimationId = "rbxassetid://0"

local function startAutoBlock()
    table.insert(getgenv().YRWL_Connection___, RunService.Stepped:Connect(function()
        if getgenv().XZQW_ENABLED then
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("BodyEffects") then
                local bodyEffects = character.BodyEffects
                if bodyEffects:FindFirstChild("Block") then
                    bodyEffects.Block:Destroy()
                end
                local tool = character:FindFirstChildWhichIsA("Tool")
                if tool and tool:FindFirstChild("Ammo") then
                    ReplicatedStorage.MainEvent:FireServer("Block", false)
                else
                    ReplicatedStorage.MainEvent:FireServer("Block", true)
                    wait()
                    ReplicatedStorage.MainEvent:FireServer("Block", false)
                end
            end
        end
    end))
end

local function stopAutoBlock()
    for _, connection in ipairs(getgenv().YRWL_Connection___) do
        connection:Disconnect()
    end
    table.clear(getgenv().YRWL_Connection___)
end

local function startHidingAnimations()
    RunService:BindToRenderStep("Hide - Block", 0, function()
        if getgenv().HIDE_ANIMATIONS then
            local character = LocalPlayer.Character
            if character then
                local humanoid = character:FindFirstChildWhichIsA("Humanoid")
                if humanoid then
                    for _, animationTrack in pairs(humanoid:GetPlayingAnimationTracks()) do
                        if table.find(getgenv().BlockedAnimations, animationTrack.Animation.AnimationId) then
                            animationTrack:Stop()
                        end
                    end
                end
            end
        end
    end)
end

local function stopHidingAnimations()
    RunService:UnbindFromRenderStep("Hide - Block")
end

local RightGroupbox = Tabs.Character:AddRightGroupbox('Auto Block Settings')

RightGroupbox:AddToggle('AutoBlock', {
    Text = 'God Block',
    Default = false,

    Callback = function(state)
        getgenv().XZQW_ENABLED = state
        if state then
            startAutoBlock()
        else
            stopAutoBlock()
        end
    end,
})

local Depbox = RightGroupbox:AddDependencyBox()

Depbox:AddToggle('HideAnimations', {
    Text = 'Hide Animations',
    Default = false,

    Callback = function(state)
        getgenv().HIDE_ANIMATIONS = state
        if state then
            startHidingAnimations()
        else
            stopHidingAnimations()
        end
    end,
})

Depbox:SetupDependencies({
    { Toggles.AutoBlock, true }
})

CASH_AURA_ENABLED = false
COOLDOWN = 0.2
CASH_AURA_RANGE = 17

function GetCash()
    local Found = {}
    local Drop = workspace:FindFirstChild("Ignored") and workspace.Ignored:FindFirstChild("Drop")
    
    if Drop then
        for _, v in pairs(Drop:GetChildren()) do 
            if v.Name == "MoneyDrop" then 
                local Pos = v:GetAttribute("OriginalPos") or v.Position
                
                if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and 
                   (Pos - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= CASH_AURA_RANGE then
                    table.insert(Found, v)
                end
            end
        end
    end
    
    return Found
end

function CashAura()
    while CASH_AURA_ENABLED do
        local Cash = GetCash()
        
        for _, v in pairs(Cash) do
            local clickDetector = v:FindFirstChildOfClass("ClickDetector")
            if clickDetector then
                fireclickdetector(clickDetector)
            end
        end
        
        task.wait(COOLDOWN)
    end
end

Modifications:AddToggle('Cash_Aura_Toggle', {
    Text = 'Cash Aura',
    Default = false,
    Callback = function(Value)
        CASH_AURA_ENABLED = Value
        if CASH_AURA_ENABLED then
            task.spawn(CashAura)
        end
    end
})

local autoReloadEnabled = false
local reloadMethod = "Normal"
local safeReloadEnabled = false

function startAutoReload()
    _G.Connection = game:GetService("RunService").RenderStepped:Connect(function()
        if not autoReloadEnabled then
            _G.Connection:Disconnect()
            return
        end
        
        local character = game.Players.LocalPlayer.Character
        if not character then return end
        
        -- NEW: Get ALL equipped tools instead of just one
        local equippedTools = {}
        for _, child in pairs(character:GetChildren()) do
            if child:IsA("Tool") and child:FindFirstChild("Ammo") then
                table.insert(equippedTools, child)
            end
        end
        
        -- NEW: Check each equipped weapon for reload needs
        for _, tool in pairs(equippedTools) do
            local ammo = tool:FindFirstChild("Ammo")
            
            if ammo and ammo.Value <= (reloadMethod == "Rifle" and 1 or 0) then
                -- Safe Reload functionality - you stay grounded, others see you in air
                if safeReloadEnabled then
                    local rootPart = character:FindFirstChild("HumanoidRootPart")
                    
                    if rootPart then
                        -- Store your actual ground position
                        local groundPosition = rootPart.CFrame
                        
                        -- Create Network Chaos position for other players to see
                        local airPosition = CFrame.new(
                            groundPosition.Position.X + math.random(-999999, 999999),
                            groundPosition.Position.Y + math.random(-999999, 999999),
                            groundPosition.Position.Z + math.random(-999999, 999999)
                        )
                        
                        -- Apply the desync effect
                        rootPart.CFrame = airPosition
                        
                        -- Set camera subject to maintain your view on ground
                        workspace.CurrentCamera.CameraSubject = character:FindFirstChild("Humanoid")
                        
                        -- Wait for network update
                        game:GetService("RunService").RenderStepped:Wait()
                        
                        -- Snap back to ground position (you see yourself on ground)
                        rootPart.CFrame = groundPosition
                        
                        -- Brief delay to ensure network registers the air position
                        task.wait(0.05) -- Reduced delay since we're reloading multiple weapons
                    end
                end
                
                -- Reload this specific weapon
                game:GetService("ReplicatedStorage").MainEvent:FireServer("Reload", tool)
                
                -- Small delay between reloading multiple weapons to prevent spam
                task.wait(0.1)
            end
        end
        
        -- Only do the main reload delay if we actually reloaded something
        if #equippedTools > 0 then
            local needsReload = false
            for _, tool in pairs(equippedTools) do
                local ammo = tool:FindFirstChild("Ammo")
                if ammo and ammo.Value <= (reloadMethod == "Rifle" and 1 or 0) then
                    needsReload = true
                    break
                end
            end
            
            if needsReload then
                task.wait(3.7) -- Main reload cooldown
            end
        end
    end)
end

-- Enhanced version with better reload timing for multiple weapons
function startAutoReloadEnhanced()
    _G.Connection = game:GetService("RunService").RenderStepped:Connect(function()
        if not autoReloadEnabled then
            _G.Connection:Disconnect()
            return
        end
        
        local character = game.Players.LocalPlayer.Character
        if not character then return end
        
        -- Get ALL equipped tools with ammo
        local toolsNeedingReload = {}
        for _, child in pairs(character:GetChildren()) do
            if child:IsA("Tool") and child:FindFirstChild("Ammo") then
                local ammo = child:FindFirstChild("Ammo")
                if ammo and ammo.Value <= (reloadMethod == "Rifle" and 1 or 0) then
                    table.insert(toolsNeedingReload, child)
                end
            end
        end
        
        -- If no tools need reloading, exit early
        if #toolsNeedingReload == 0 then
            return
        end
        
        -- Apply safe reload desync once for all weapons
        if safeReloadEnabled then
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            
            if rootPart then
                -- Store your actual ground position
                local groundPosition = rootPart.CFrame
                
                -- Create Network Chaos position for other players to see
                local airPosition = CFrame.new(
                    groundPosition.Position.X + math.random(-999999, 999999),
                    groundPosition.Position.Y + math.random(-999999, 999999),
                    groundPosition.Position.Z + math.random(-999999, 999999)
                )
                
                -- Apply the desync effect
                rootPart.CFrame = airPosition
                
                -- Set camera subject to maintain your view on ground
                workspace.CurrentCamera.CameraSubject = character:FindFirstChild("Humanoid")
                
                -- Wait for network update
                game:GetService("RunService").RenderStepped:Wait()
                
                -- Snap back to ground position (you see yourself on ground)
                rootPart.CFrame = groundPosition
                
                -- Brief delay to ensure network registers the air position
                task.wait(0.05)
            end
        end
        
        -- Reload all weapons that need it
        for i, tool in pairs(toolsNeedingReload) do
            game:GetService("ReplicatedStorage").MainEvent:FireServer("Reload", tool)
            
            -- Small staggered delay between multiple weapon reloads
            if i < #toolsNeedingReload then
                task.wait(0.05)
            end
        end
        
        -- Main reload cooldown after all weapons are reloaded
        task.wait(3.7)
    end)
end

-- Auto Reload Toggle
Modifications:AddToggle('Auto Reload', {
    Text = 'Auto Reload (All Weapons)',
    Default = false,
    Callback = function(state)
        autoReloadEnabled = state
        _G.AutoReloadEnabled = state
        if state then
            startAutoReloadEnhanced() -- Use the enhanced version
        end
    end,
})

-- Safe Reload Toggle
Modifications:AddToggle('SafeReload', {
    Text = 'Safe Reload (Ground/Air Desync)',
    Default = false,
    Callback = function(state)
        safeReloadEnabled = state
        _G.SafeReloadEnabled = state
        if state then
            Library:Notify("Safe Reload: Network Chaos desync during reload", 3)
        end
    end,
})

-- Reload Method Dropdown  
Modifications:AddDropdown('MyDropdown', {
    Values = { 'Normal', 'Rifle'},
    Default = "Normal",
    Multi = false,
    Text = 'Reload Method',
    Callback = function(selected)
        reloadMethod = selected
    end
})



local AutoBuy = Tabs.Misc:AddLeftGroupbox("Shop")
local Workspace = game:GetService("Workspace")

local ShopFolder = Workspace:WaitForChild("Ignored"):WaitForChild("Shop")
local SelectedItem, Debounce = nil, false
local AutoBuyOnRespawn = false
local AmmoBuyCount = 0

local ShopItems = {
    "[Taco] - $2",
    "[Hamburger] - $5",
    "[Revolver] - $1421",
    "12 [Revolver Ammo] - $55",
    "90 [AUG Ammo] - $87",
    "[AUG] - $2131",
    "[Rifle] - $1694",
    "[LMG] - $4098",
    "200 [LMG Ammo] - $328",
    "6 [Flintlock Ammo] - $163",
    "[Flintlock] - $1421",

}

AutoBuy:AddDropdown('Shop_Dropdown', {
    Values = ShopItems,
    Default = 1,
    Multi = false,
    Text = 'Select an Item',
    Callback = function(Value)
        SelectedItem = Value
    end
})

local function GetCharacterRoot()
    local Character = LocalPlayer.Character
    return Character and Character:FindFirstChild("HumanoidRootPart")
end

local function GetEquippedTool()
    local Character = LocalPlayer.Character
    if Character then
        return Character:FindFirstChildOfClass("Tool")
    end
    return nil
end

local function ReequipTool(tool)
    if tool and tool.Parent == LocalPlayer.Backpack then
        tool.Parent = LocalPlayer.Character
    end
end

local function BuyItem(ItemName)
    if not ItemName or Debounce then return end
    Debounce = true

    local wasDesyncEnabled = desync.enabled
    if wasDesyncEnabled then
        toggleDesync(false)
        task.wait(0.1)
    end

    local RootPart = GetCharacterRoot()
    if not RootPart then 
        Library:Notify("[ERROR] No HumanoidRootPart found!", 3)
        Debounce = false
        return
    end

    -- Store the currently equipped tool
    local EquippedTool = GetEquippedTool()

    local ItemModel = ShopFolder:FindFirstChild(ItemName)
    if ItemModel then
        local ClickDetector = ItemModel:FindFirstChildOfClass("ClickDetector")
        if ClickDetector then
            local OriginalPosition = RootPart.CFrame

            RootPart.CFrame = CFrame.new(ItemModel.Head.Position + Vector3.new(0, 3, 0))
            task.wait(0.2)

            fireclickdetector(ClickDetector)

            Library:Notify("Purchased: " .. ItemName, 3)

            RootPart.CFrame = OriginalPosition
            
            -- Re-equip the tool after teleporting back
            if EquippedTool then
                task.wait(0.1) -- Small delay to ensure teleport is complete
                ReequipTool(EquippedTool)
            end
        else
            Library:Notify("[ERROR] ClickDetector not found in " .. ItemName, 3)
        end
    else
        Library:Notify("[ERROR] Item not found: " .. ItemName, 3)
    end

    if wasDesyncEnabled then
        task.wait(0.2)
        toggleDesync(true)
    end

    Debounce = false
end

local function BuyAmmo()
    if not SelectedItem or Debounce then return end

    local AmmoMap = {
        ["[Revolver] - $1421"] = "12 [Revolver Ammo] - $55",
        ["[AUG] - $2131"] = "90 [AUG Ammo] - $87",
        ["[LMG] - $4098"] = "200 [LMG Ammo] - $328",
        ["[Rifle] - $1694"] = "5 [Rifle Ammo] - $273",
        ["[Flintlock] - $1421"] = "6 [Flintlock Ammo] - $163", 
    }

    local AmmoItem = AmmoMap[SelectedItem]
    if AmmoItem then
        BuyItem(AmmoItem)
    else
        Library:Notify("[ERROR] No ammo available.", 3)
    end
end

local function AutoBuyOnRespawnHandler()
    if not AutoBuyOnRespawn or not SelectedItem then return end

    local originalStrafeState = strafeEnabled
    
    if strafeEnabled then
        strafeEnabled = false
    end

    BuyItem(SelectedItem)

    task.wait(0.2) -- Wait for buy operation to complete

    if AmmoBuyCount < 3 then
        for i = 1, 3 do
            BuyAmmo()
            task.wait(0.5)
        end
        AmmoBuyCount = 3
    end
    
    strafeEnabled = originalStrafeState

    task.wait(0.1)
end

local localplayer = game:GetService("Players").LocalPlayer

localplayer.CharacterAdded:Connect(function()
    if localplayer:Backpack():FindFirstChild(SelectedItem) then
        Library:Notify("You have " .. SelectedItem, " in your backpack")
    else
        BuyItem(SelectedItem)
    end
end)

AutoBuy:AddToggle('AutoBuyOnRespawn', {
    Text = 'Auto Buy on Respawn',
    Default = false,
    Callback = function(state)
        AutoBuyOnRespawn = state
        AmmoBuyCount = 0
    end
})

local buy = AutoBuy:AddButton({
    Text = 'Buy Item',
    Func = function()
        local originalStrafe = strafeEnabled

        if strafeEnabled then
            strafeEnabled = false
        end
        
        BuyItem(SelectedItem)
        
        task.wait(0.2) -- Wait for buy operation to complete
        
        strafeEnabled = originalStrafe
        
        -- Additional wait to ensure it sticks
        task.wait(0.1)
    end,
    DoubleClick = false,
    Tooltip = 'Buys the selected item'
})

buy:AddButton({
    Text = 'Buy Ammo',
    Func = function()
        local originalStrafe = strafeEnabled

        if strafeEnabled then
            strafeEnabled = false
        end

        BuyAmmo()

        task.wait(0.2)
        
        strafeEnabled = originalStrafe

        task.wait(0.1)

    end,
    DoubleClick = false,
    Tooltip = 'Buys ammo for the selected weapon'
})

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    ShopFolder = Workspace:WaitForChild("Ignored"):WaitForChild("Shop")
    AutoBuyOnRespawnHandler()
end)

Modifications:AddToggle('AntiVoid', {
    Text = 'Anti Void',
    Default = false,

    Callback = function(immatouchyoumaddie)
		if immatouchyoumaddie then
			workspace.FallenPartsDestroyHeight = -math.huge
		else
			Workspace.FallenPartsDestroyHeight = -50
		end
    end,
})

getgenv().autoArmorEnabled = false
getgenv().autoFArmorEnabled = false
getgenv().armorThreshold = 75
getgenv().fArmorThreshold = 75

local player = game:GetService("Players").LocalPlayer
local dataFolder = player:WaitForChild("DataFolder")
local infoFolder = dataFolder:WaitForChild("Information")

local armorInfo = infoFolder:FindFirstChild("ArmorSave")
local fireArmorInfo = infoFolder:FindFirstChild("FireArmorSave")

local armorShop = workspace.Ignored.Shop["[High-Medium Armor] - $2513"]
local fireArmorShop = workspace.Ignored.Shop["[Fire Armor] - $2623"]

local armorClickDetector = armorShop:FindFirstChild("ClickDetector")
local fireArmorClickDetector = fireArmorShop:FindFirstChild("ClickDetector")

local checkArmorRunning = false
local lastArmorBuyTime = 0
local lastFireArmorBuyTime = 0
local cooldown = 0.5  -- Cooldown in seconds between purchases

-- Optional fallbacks
local strafeEnabled = getgenv().strafeEnabled or false
local desync = getgenv().desync or { enabled = false }
local function toggleDesync(val)
    if desync and typeof(desync.enabled) == "boolean" then
        desync.enabled = val
    end
end

local function canBuyArmor()
    local character = player.Character
    if not character then return false end
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid and humanoid.Health <= 1 then return false end

    local bodyEffects = character:FindFirstChild("BodyEffects")
    local isKO = bodyEffects and bodyEffects:FindFirstChild("K.O") and bodyEffects["K.O"].Value
    return not isKO
end

local function teleportAndBuy(shop, clickDetector)
    local character = player.Character
    if not character or not character.PrimaryPart then return end

    local originalStrafe = strafeEnabled
    if originalStrafe then strafeEnabled = false end

    local originalCFrame = character.PrimaryPart.CFrame
    task.wait(0.1)

    -- Teleport slightly above the shop
    character:SetPrimaryPartCFrame(shop.Head.CFrame * CFrame.new(0, 3.1, 0))
    task.wait(0.2)

    fireclickdetector(clickDetector)
    task.wait(0.3) -- Allow some time to register

    character:SetPrimaryPartCFrame(originalCFrame)
    if originalStrafe then strafeEnabled = true end
end

local function buyArmor()
    if not (armorInfo and getgenv().autoArmorEnabled and canBuyArmor()) then return end
    local value = tonumber(armorInfo.Value) or 100
    if value >= getgenv().armorThreshold then return end

    if tick() - lastArmorBuyTime < cooldown then return end
    lastArmorBuyTime = tick()

    local wasDesync = desync.enabled
    if wasDesync then toggleDesync(false) end

    teleportAndBuy(armorShop, armorClickDetector)

    if wasDesync then toggleDesync(true) end
end

local function buyFireArmor()
    if not (fireArmorInfo and getgenv().autoFArmorEnabled and canBuyArmor()) then return end
    local value = tonumber(fireArmorInfo.Value) or 100
    if value >= getgenv().fArmorThreshold then return end

    if tick() - lastFireArmorBuyTime < cooldown then return end
    lastFireArmorBuyTime = tick()

    local wasDesync = desync.enabled
    if wasDesync then toggleDesync(false) end

    teleportAndBuy(fireArmorShop, fireArmorClickDetector)

    if wasDesync then toggleDesync(true) end
end

local function checkArmor()
    if checkArmorRunning then return end
    checkArmorRunning = true
    while task.wait(0.2) do
        if not getgenv().autoArmorEnabled and not getgenv().autoFArmorEnabled then
            continue
        end

        pcall(buyArmor)
        pcall(buyFireArmor)
    end
end

-- Start loop 
task.spawn(checkArmor)

player.CharacterAdded:Connect(function()
    task.wait(1)
    -- Stop any existing checkArmor loop
    checkArmorRunning = false
    task.wait(0.2)
    -- Start new checkArmor loop
    task.spawn(checkArmor)
end)

-- Start initial checkArmor loop
task.spawn(checkArmor)

-- UI Components
Modifications:AddToggle('AutoArmorToggle', {
    Text = 'Auto Armor',
    Default = false,
    Callback = function(state)
        getgenv().autoArmorEnabled = state
    end,
})

Modifications:AddSlider('ArmorThresholdSlider', {
    Text = 'Armor Threshold',
    Default = 75,
    Min = 1,
    Max = 130,
    Rounding = 0,
    Callback = function(value)
        getgenv().armorThreshold = value
    end,
})

Modifications:AddToggle('AutoFArmorToggle', {
    Text = 'Auto Fire Armor',
    Default = false,
    Callback = function(state)
        getgenv().autoFArmorEnabled = state
    end,
})

Modifications:AddSlider('FArmorThresholdSlider', {
    Text = 'Fire Armor Threshold',
    Default = 75,
    Min = 1,
    Max = 130,
    Rounding = 0,
    Callback = function(value)
        getgenv().fArmorThreshold = value
    end,
})

Modifications:AddToggle("AntiSitToggle", {
    Text = "Anti Sit",
    Default = false,
    Callback = function(state)
        getgenv().antiSitEnabled = state
        for _, seat in ipairs(workspace:GetDescendants()) do
            if seat:IsA("Seat") or seat:IsA("VehicleSeat") then
                seat.CanTouch = not state
            end
        end

        workspace.DescendantAdded:Connect(function(seat)
            if getgenv().antiSitEnabled and (seat:IsA("Seat") or seat:IsA("VehicleSeat")) then
                seat.CanTouch = false
            end
        end)
    end
})

getgenv().AntiRPGDesyncEnabled, getgenv().GrenadeDetectionEnabled, getgenv().AntiRPGDesyncLoop = false, false, nil
local RunService, Workspace, LocalPlayer = game:GetService("RunService"), game.Workspace, game.Players.LocalPlayer

local function IsThreatNear(threatName)
    local Threat = Workspace:FindFirstChild("Ignored") and Workspace.Ignored:FindFirstChild(threatName)
    local HRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    return Threat and HRP and (Threat.Position - HRP.Position).Magnitude < 16
end

local function StartThreatDetection()
    if getgenv().AntiRPGDesyncLoop then return end

    getgenv().AntiRPGDesyncLoop = RunService.PostSimulation:Connect(function()
        local HRP, Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"), LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if not HRP or not Humanoid then return end

        local RPGThreat = Workspace.Ignored:FindFirstChild("Model") and Workspace.Ignored.Model:FindFirstChild("Launcher")
        local GrenadeThreat = IsThreatNear("Handle")

        if (getgenv().AntiRPGDesyncEnabled and RPGThreat or getgenv().GrenadeDetectionEnabled and GrenadeThreat) then
            local Offset = Vector3.new(math.random(-100, 100), math.random(50, 150), math.random(-100, 100))
            Humanoid.CameraOffset = -Offset
            local OldCFrame = HRP.CFrame
            HRP.CFrame = CFrame.new(HRP.CFrame.Position + Offset)
            RunService.RenderStepped:Wait()
            HRP.CFrame = OldCFrame
        end
    end)

    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        if getgenv().AntiRPGDesyncEnabled or getgenv().GrenadeDetectionEnabled then StartThreatDetection() end
    end)
end

local function StopThreatDetection()
    if getgenv().AntiRPGDesyncLoop then
        getgenv().AntiRPGDesyncLoop:Disconnect()
        getgenv().AntiRPGDesyncLoop = nil
    end
end

Modifications:AddToggle('RPGDetection', {
    Text = 'RPG detection',
    Default = false,
    Callback = function(state)
        getgenv().AntiRPGDesyncEnabled = state
        if state or getgenv().GrenadeDetectionEnabled then StartThreatDetection() else StopThreatDetection() end
    end,
})

Modifications:AddToggle('GrenadeDetection', {
    Text = 'grenade detection',
    Default = false,
    Callback = function(state)
        getgenv().GrenadeDetectionEnabled = state
        if state or getgenv().AntiRPGDesyncEnabled then StartThreatDetection() else StopThreatDetection() end
    end,
})

local webhook = Modifications:AddButton('Redeem Codes', function()
    local codes = {
        "Jellyfish",
        "Arcane",           -- 250,000 Da Hood Cash (NEW)
        "Samurai",          -- 250,000 Da Hood Cash (NEW)
        "HOUSE",            -- 100,000 Da Hood Cash
        "Sushi",            -- Da Hood Cash (amount unspecified)
        "50MDHC",           -- 5 Da Hood Cash
        "Watch",            -- 200,000 Da Hood Cash
        "Duck",             -- 200,000 Da Hood Cash
        "SHRIMP",           -- 300,000 Da Hood Cash
        "VIP",              -- 300,000 Da Hood Cash
        "2025",             -- 200,000 Da Hood Cash
        "THANKSGIVING24",   -- 240,000 Da Hood Cash
        "DACARNIVAL",       -- 400,000 Da Hood Cash
        "HALLOWEEN2024",    -- 500,000 Da Hood Cash
        "RUBY",             -- 250,000 Da Hood Cash
        "pumpkins2023",     -- 250,000 Da Hood Cash
        "TRADEME!",         -- 100,000 Da Hood Cash
        "DAUP"              -- (unknown value)
    }
   local mainEvent = game:GetService("ReplicatedStorage"):WaitForChild("MainEvent") or nil

   for _, code in pairs(codes) do
       mainEvent:FireServer("EnterPromoCode", code)
       Library:Notify("Trying code: " .. code .. " ZestHub.lol | Private", 5)
       task.wait(4.2)
   end
end)

webhook:AddButton('Force Reset', function()
    game.Players.LocalPlayer.Character.Humanoid.Health = 0
end)

Modifications:AddButton('Chat Spy', function()
    enabled = true --chat "/spy" to toggle!
    spyOnMyself = true --if true will check your messages too
    public = false --if true will chat the logs publicly (fun, risky)
    publicItalics = true --if true will use /me to stand out
    privateProperties = { --customize private logs
        Color = Color3.fromRGB(0,255,255); 
        Font = Enum.Font.SourceSansBold;
        TextSize = 18;
    }
    
    
    local StarterGui = game:GetService("StarterGui")
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() or Players.LocalPlayer
    local saymsg = game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents"):WaitForChild("SayMessageRequest")
    local getmsg = game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents"):WaitForChild("OnMessageDoneFiltering")
    local instance = (_G.chatSpyInstance or 0) + 1
    _G.chatSpyInstance = instance
    
    local function onChatted(p,msg)
        if _G.chatSpyInstance == instance then
            if p==player and msg:lower():sub(1,4)=="/spy" then
                enabled = not enabled
                wait(0.3)
                privateProperties.Text = "{SPY "..(enabled and "EN" or "DIS").."ABLED}"
                StarterGui:SetCore("ChatMakeSystemMessage",privateProperties)
            elseif enabled and (spyOnMyself==true or p~=player) then
                msg = msg:gsub("[\n\r]",''):gsub("\t",' '):gsub("[ ]+",' ')
                local hidden = true
                local conn = getmsg.OnClientEvent:Connect(function(packet,channel)
                    if packet.SpeakerUserId==p.UserId and packet.Message==msg:sub(#msg-#packet.Message+1) and (channel=="All" or (channel=="Team" and public==false and Players[packet.FromSpeaker].Team==player.Team)) then
                        hidden = false
                    end
                end)
                wait(1)
                conn:Disconnect()
                if hidden and enabled then
                    if public then
                        saymsg:FireServer((publicItalics and "/me " or '').."{SPY} [".. p.Name .."]: "..msg,"All")
                    else
                        privateProperties.Text = "{SPY} [".. p.Name .."]: "..msg
                        StarterGui:SetCore("ChatMakeSystemMessage",privateProperties)
                    end
                end
            end
        end
    end
    
    for _,p in ipairs(Players:GetPlayers()) do
        p.Chatted:Connect(function(msg) onChatted(p,msg) end)
    end
    Players.PlayerAdded:Connect(function(p)
        p.Chatted:Connect(function(msg) onChatted(p,msg) end)
    end)
    privateProperties.Text = "{SPY "..(enabled and "EN" or "DIS").."ABLED}"
    StarterGui:SetCore("ChatMakeSystemMessage",privateProperties)
    if not player.PlayerGui:FindFirstChild("Chat") then wait(3) end
    local chatFrame = player.PlayerGui.Chat.Frame
    chatFrame.ChatChannelParentFrame.Visible = true
    chatFrame.ChatBarParentFrame.Position = chatFrame.ChatChannelParentFrame.Position+UDim2.new(UDim.new(),chatFrame.ChatChannelParentFrame.Size.Y)
    
end)


local flashbackBox = Tabs.Misc:AddRightGroupbox("Detection")
local antiModEnabled, checkModFriendsEnabled, groupCheckEnabled = false, false, false
local antiModMethod = "Notify"


local modList = {
    163721789, 15427717, 201454243, 822999, 63794379, 17260230, 28357488,
    93101606, 8195210, 89473551, 16917269, 85989579, 1553950697, 476537893,
    155627580, 31163456, 7200829, 25717070, 201454243, 15427717, 63794379,
    16138978, 60660789, 17260230, 16138978, 1161411094, 9125623, 11319153,
    34758833, 194109750, 35616559, 1257271138, 28885841, 23558830, 25717070,
    4255947062, 29242182, 2395613299, 3314981799, 3390225662, 2459178,
    2846299656, 2967502742, 7001683347, 7312775547, 328566086, 170526279,
    99356639, 352087139, 6074834798, 2212830051, 3944434729, 5136267958,
    84570351, 542488819, 1830168970, 3950637598, 1962396833
}

local groupIDs = {10604500, 17215700}

local function detectModerators()
    while antiModEnabled do
        task.wait(1)
        for _, player in ipairs(Players:GetPlayers()) do
            if table.find(modList, player.UserId) then
                local message = "⚠️ MODERATOR DETECTED: " .. player.DisplayName .. " (" .. player.Name .. ")"
                if antiModMethod == "Notify" then
                    Library:Notify(message, 3)
                else
                    game.Players.LocalPlayer:Kick("🚨 " .. message)
                end
            end

            if groupCheckEnabled then
                for _, groupID in ipairs(groupIDs) do
                    local success, isInGroup = pcall(function() return player:IsInGroup(groupID) end)
                    if success and isInGroup then
                        local roleName = "Unknown Role"
                        pcall(function()
                            roleName = player:GetRoleInGroup(groupID)
                        end)

                        local groupMessage = "⚠️ [" .. roleName .. "] JOINED: " .. player.DisplayName .. " (" .. player.Name .. ")"
                        if antiModMethod == "Notify" then
                            Library:Notify(groupMessage, 3)
                        else
                            game.Players.LocalPlayer:Kick("🚨 " .. groupMessage)
                        end
                    end
                end
            end
        end
    end
end

local function checkFriendsWithMods()
    while checkModFriendsEnabled do
        task.wait(1)
        for _, player in ipairs(Players:GetPlayers()) do
            pcall(function()
                for _, friend in pairs(player:GetFriendsAsync():GetCurrentPage()) do
                    if table.find(modList, friend.Id) then
                        local friendMessage = "⚠️ " .. player.DisplayName .. " (" .. player.Name .. ") is friends with a Moderator!"
                        Library:Notify(friendMessage, 4)
                        break
                    end
                end
            end)
        end
    end
end

local AntiModToggle = flashbackBox:AddToggle("AntiModToggle", {
    Text = "Mod Detection",
    Default = false,
    Callback = function(Value)
        antiModEnabled = Value
        Library:Notify(antiModEnabled and "✅ Anti-Mod Enabled" or "⚠️ Anti-Mod Disabled", 3)
        if antiModEnabled then task.spawn(detectModerators) end
    end
})

local AntiModDepbox = flashbackBox:AddDependencyBox()
AntiModDepbox:SetupDependencies({ { AntiModToggle, true } })

AntiModDepbox:AddDropdown("AntiModMethod", {
    Values = {"Notify", "Kick"},
    Default = "Notify",
    Multi = false,
    Text = "Anti-Mod Method",
    Callback = function(Value)
        antiModMethod = Value
        Library:Notify("ℹ️ Anti-Mod Method set to: " .. antiModMethod, 3)
    end
})

AntiModDepbox:AddToggle("CheckModFriends", {
    Text = "Friended Checking",
    Tooltip = "Detects if any player is friends with a Moderator",
    Default = false,
    Callback = function(Value)
        checkModFriendsEnabled = Value
        Library:Notify(checkModFriendsEnabled and "✅ Checking for Mod Friends Enabled" or "⚠️ Checking for Mod Friends Disabled", 3)
        if checkModFriendsEnabled then task.spawn(checkFriendsWithMods) end
    end
})

local GroupCheckDepbox = AntiModDepbox:AddDependencyBox()
GroupCheckDepbox:SetupDependencies({ { AntiModToggle, true } })

GroupCheckDepbox:AddToggle("GroupCheck", {
    Text = "Group Role Checking",
    Tooltip = "Detects if any player is in the restricted groups",
    Default = false,
    Callback = function(Value)
        groupCheckEnabled = Value
        Library:Notify(groupCheckEnabled and "✅ Group Membership Check Enabled" or "⚠️ Group Membership Check Disabled", 3)
        if groupCheckEnabled then task.spawn(detectModerators) end
    end
})

local LeftGroupBox = Tabs.Misc:AddLeftGroupbox("Animation")

local KeepOnDeath = false

local AnimationOptions = {
    ["Idle1"] = "http://www.roblox.com/asset/?id=180435571",
    ["Idle2"] = "http://www.roblox.com/asset/?id=180435792",
    ["Walk"] = "http://www.roblox.com/asset/?id=180426354",
    ["Run"] = "http://www.roblox.com/asset/?id=180426354",
    ["Jump"] = "http://www.roblox.com/asset/?id=125750702",
    ["Climb"] = "http://www.roblox.com/asset/?id=180436334",
    ["Fall"] = "http://www.roblox.com/asset/?id=180436148"
}

local AnimationSets = {
    ["Default"] = {
        idle1 = "http://www.roblox.com/asset/?id=180435571",
        idle2 = "http://www.roblox.com/asset/?id=180435792",
        walk = "http://www.roblox.com/asset/?id=180426354",
        run = "http://www.roblox.com/asset/?id=180426354",
        jump = "http://www.roblox.com/asset/?id=125750702",
        climb = "http://www.roblox.com/asset/?id=180436334",
        fall = "http://www.roblox.com/asset/?id=180436148"
    },
    ["Ninja"] = {
        idle1 = "http://www.roblox.com/asset/?id=656117400",
        idle2 = "http://www.roblox.com/asset/?id=656118341",
        walk = "http://www.roblox.com/asset/?id=656121766",
        run = "http://www.roblox.com/asset/?id=656118852",
        jump = "http://www.roblox.com/asset/?id=656117878",
        climb = "http://www.roblox.com/asset/?id=656114359",
        fall = "http://www.roblox.com/asset/?id=656115606"
    },
    ["Superhero"] = {
        idle1 = "http://www.roblox.com/asset/?id=616111295",
        idle2 = "http://www.roblox.com/asset/?id=616113536",
        walk = "http://www.roblox.com/asset/?id=616122287",
        run = "http://www.roblox.com/asset/?id=616117076",
        jump = "http://www.roblox.com/asset/?id=616115533",
        climb = "http://www.roblox.com/asset/?id=616104706",
        fall = "http://www.roblox.com/asset/?id=616108001"
    },
    ["Robot"] = {
        idle1 = "http://www.roblox.com/asset/?id=616088211",
        idle2 = "http://www.roblox.com/asset/?id=616089559",
        walk = "http://www.roblox.com/asset/?id=616095330",
        run = "http://www.roblox.com/asset/?id=616091570",
        jump = "http://www.roblox.com/asset/?id=616090535",
        climb = "http://www.roblox.com/asset/?id=616086039",
        fall = "http://www.roblox.com/asset/?id=616087089"
    },
    ["Cartoon"] = {
        idle1 = "http://www.roblox.com/asset/?id=742637544",
        idle2 = "http://www.roblox.com/asset/?id=742638445",
        walk = "http://www.roblox.com/asset/?id=742640026",
        run = "http://www.roblox.com/asset/?id=742638842",
        jump = "http://www.roblox.com/asset/?id=742637942",
        climb = "http://www.roblox.com/asset/?id=742636889",
        fall = "http://www.roblox.com/asset/?id=742637151"
    },
    ["Catwalk"] = {
        idle1 = "http://www.roblox.com/asset/?id=133806214992291",
        idle2 = "http://www.roblox.com/asset/?id=94970088341563",
        walk = "http://www.roblox.com/asset/?id=109168724482748",
        run = "http://www.roblox.com/asset/?id=81024476153754",
        jump = "http://www.roblox.com/asset/?id=116936326516985",
        climb = "http://www.roblox.com/asset/?id=119377220967554",
        fall = "http://www.roblox.com/asset/?id=92294537340807"
    },
    ["Zombie"] = {
        idle1 = "http://www.roblox.com/asset/?id=616158929",
        idle2 = "http://www.roblox.com/asset/?id=616160636",
        walk = "http://www.roblox.com/asset/?id=616168032",
        run = "http://www.roblox.com/asset/?id=616163682",
        jump = "http://www.roblox.com/asset/?id=616161997",
        climb = "http://www.roblox.com/asset/?id=616156119",
        fall = "http://www.roblox.com/asset/?id=616157476"
    },
    ["Mage"] = {
        idle1 = "http://www.roblox.com/asset/?id=707742142",
        idle2 = "http://www.roblox.com/asset/?id=707855907",
        walk = "http://www.roblox.com/asset/?id=707897309",
        run = "http://www.roblox.com/asset/?id=707861613",
        jump = "http://www.roblox.com/asset/?id=707853694",
        climb = "http://www.roblox.com/asset/?id=707826056",
        fall = "http://www.roblox.com/asset/?id=707829716"
    },
    ["Pirate"] = {
        idle1 = "http://www.roblox.com/asset/?id=750785693",
        idle2 = "http://www.roblox.com/asset/?id=750782770",
        walk = "http://www.roblox.com/asset/?id=750785693",
        run = "http://www.roblox.com/asset/?id=750782770",
        jump = "http://www.roblox.com/asset/?id=750782770",
        climb = "http://www.roblox.com/asset/?id=750782770",
        fall = "http://www.roblox.com/asset/?id=750782770"
    },
    ["Knight"] = {
        idle1 = "http://www.roblox.com/asset/?id=657595757",
        idle2 = "http://www.roblox.com/asset/?id=657568135",
        walk = "http://www.roblox.com/asset/?id=657552124",
        run = "http://www.roblox.com/asset/?id=657564596",
        jump = "http://www.roblox.com/asset/?id=657560148",
        climb = "http://www.roblox.com/asset/?id=657556206",
        fall = "http://www.roblox.com/asset/?id=657552124"
    },
    ["Vampire"] = {
        idle1 = "http://www.roblox.com/asset/?id=1083465857",
        idle2 = "http://www.roblox.com/asset/?id=1083465857",
        walk = "http://www.roblox.com/asset/?id=1083465857",
        run = "http://www.roblox.com/asset/?id=1083465857",
        jump = "http://www.roblox.com/asset/?id=1083465857",
        climb = "http://www.roblox.com/asset/?id=1083465857",
        fall = "http://www.roblox.com/asset/?id=1083465857"
    },
    ["Bubbly"] = {
        idle1 = "http://www.roblox.com/asset/?id=910004836",
        idle2 = "http://www.roblox.com/asset/?id=910009958",
        walk = "http://www.roblox.com/asset/?id=910034870",
        run = "http://www.roblox.com/asset/?id=910025107",
        jump = "http://www.roblox.com/asset/?id=910016857",
        climb = "http://www.roblox.com/asset/?id=910009958",
        fall = "http://www.roblox.com/asset/?id=910009958"
    },
    ["Elder"] = {
        idle1 = "http://www.roblox.com/asset/?id=845386501",
        idle2 = "http://www.roblox.com/asset/?id=845397899",
        walk = "http://www.roblox.com/asset/?id=845403856",
        run = "http://www.roblox.com/asset/?id=845386501",
        jump = "http://www.roblox.com/asset/?id=845386501",
        climb = "http://www.roblox.com/asset/?id=845386501",
        fall = "http://www.roblox.com/asset/?id=845386501"
    },
    ["Toy"] = {
        idle1 = "http://www.roblox.com/asset/?id=782841498",
        idle2 = "http://www.roblox.com/asset/?id=782841498",
        walk = "http://www.roblox.com/asset/?id=782841498",
        run = "http://www.roblox.com/asset/?id=782841498",
        jump = "http://www.roblox.com/asset/?id=782841498",
        climb = "http://www.roblox.com/asset/?id=782841498",
        fall = "http://www.roblox.com/asset/?id=782841498"
    }
}

local function applyCustomAnimations(character)
    if not character then return end

    local Animate = character:FindFirstChild("Animate")
    if not Animate then return end

    local ClonedAnimate = Animate:Clone()

    ClonedAnimate.idle.Animation1.AnimationId = AnimationOptions["Idle1"]
    ClonedAnimate.idle.Animation2.AnimationId = AnimationOptions["Idle2"]
    ClonedAnimate.walk.WalkAnim.AnimationId = AnimationOptions["Walk"]
    ClonedAnimate.run.RunAnim.AnimationId = AnimationOptions["Run"]
    ClonedAnimate.jump.JumpAnim.AnimationId = AnimationOptions["Jump"]
    ClonedAnimate.climb.ClimbAnim.AnimationId = AnimationOptions["Climb"]
    ClonedAnimate.fall.FallAnim.AnimationId = AnimationOptions["Fall"]

    Animate:Destroy()
    ClonedAnimate.Parent = character
end

LocalPlayer.CharacterAdded:Connect(function(character)
    if KeepOnDeath then
        task.wait(1)
        applyCustomAnimations(character)
    end
end)

local animationNames = {"Default", "Ninja", "Superhero", "Robot", "Cartoon", "Catwalk", "Zombie", "Mage", "Pirate", "Knight", "Vampire", "Bubbly", "Elder", "Toy"}

LeftGroupBox:AddDropdown("Idle1Dropdown", {
    Values = animationNames,
    Default = 0,
    Multi = false,
    Text = "Idle1",
    Callback = function(Value)
        AnimationOptions["Idle1"] = AnimationSets[Value].idle1
        applyCustomAnimations(LocalPlayer.Character)
    end
})

LeftGroupBox:AddDropdown("Idle2Dropdown", {
    Values = animationNames,
    Default = 0,
    Multi = false,
    Text = "Idle2",
    Callback = function(Value)
        AnimationOptions["Idle2"] = AnimationSets[Value].idle2
        applyCustomAnimations(LocalPlayer.Character)
    end
})

LeftGroupBox:AddDropdown("WalkDropdown", {
    Values = animationNames,
    Default = 0,
    Multi = false,
    Text = "Walk",
    Callback = function(Value)
        AnimationOptions["Walk"] = AnimationSets[Value].walk
        applyCustomAnimations(LocalPlayer.Character)
    end
})

LeftGroupBox:AddDropdown("RunDropdown", {
    Values = animationNames,
    Default = 0,
    Multi = false,
    Text = "Run",
    Callback = function(Value)
        AnimationOptions["Run"] = AnimationSets[Value].run
        applyCustomAnimations(LocalPlayer.Character)
    end
})

LeftGroupBox:AddDropdown("JumpDropdown", {
    Values = animationNames,
    Default = 0,
    Multi = false,
    Text = "Jump",
    Callback = function(Value)
        AnimationOptions["Jump"] = AnimationSets[Value].jump
        applyCustomAnimations(LocalPlayer.Character)
    end
})

LeftGroupBox:AddDropdown("ClimbDropdown", {
    Values = animationNames,
    Default = 0,
    Multi = false,
    Text = "Climb",
    Callback = function(Value)
        AnimationOptions["Climb"] = AnimationSets[Value].climb
        applyCustomAnimations(LocalPlayer.Character)
    end
})

LeftGroupBox:AddDropdown("FallDropdown", {
    Values = animationNames,
    Default = 0,
    Multi = false,
    Text = "Fall",
    Callback = function(Value)
        AnimationOptions["Fall"] = AnimationSets[Value].fall
        applyCustomAnimations(LocalPlayer.Character)
    end
})

LeftGroupBox:AddToggle("MyToggle", {
    Text = "Keep On Death",
    Default = false,
    Tooltip = "Keeps the animation after respawning",
    Callback = function(Value)
        KeepOnDeath = Value
    end
})

getgenv().SelectedTarget = nil
getgenv().SelectedTeleportType = "unsafe"
getgenv().PlayerList = {}
getgenv().groupIDs = {10604500, 17215700}
getgenv().autoKillEnabled = false
getgenv().orbitStompEnabled = false
getgenv().lastPosition = nil
getgenv().strafeEnabled = false
getgenv().AutoAmmoEnabled = false
getgenv().oldPosition = nil
getgenv().invisiblePart = nil
getgenv().isActionRunning = false -- To track if an action is running

function updatePlayerList()
    getgenv().PlayerList = {}
    for _, player in ipairs(Players:GetPlayers()) do
        table.insert(getgenv().PlayerList, player.Name)
    end
    if getgenv().TargetDropdown then
        getgenv().TargetDropdown:SetValues(getgenv().PlayerList)
    end
end

updatePlayerList()

Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(updatePlayerList)

function knockTarget(targetPlayer)
    local character = targetPlayer.Character
    local humanoid = character:FindFirstChild("Humanoid")
    local bodyEffects = character:FindFirstChild("BodyEffects")
    
    if not bodyEffects or not humanoid then
        warn("BodyEffects or Humanoid not found in the character!")
        return
    end
    
    local koValue = bodyEffects:WaitForChild("K.O", 5)
    if not koValue then
        warn("K.O value not found!")
        return
    end
    
    local oldPosition = LocalPlayer.Character.HumanoidRootPart.Position
    
    task.spawn(function()
        while not koValue.Value and getgenv().isActionRunning do
            local targetPosition = character.HumanoidRootPart.Position
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(targetPosition + Vector3.new(0, -20, 0))
            
            local tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
            if tool and tool:FindFirstChild("Ammo") then
                ReplicatedStorage.MainEvent:FireServer("ShootGun", tool:FindFirstChild("Handle"), tool:FindFirstChild("Handle").CFrame.Position, character.Head.Position, character.Head, Vector3.new(0, 0, -1))
            end
            
            task.wait()
        end
        
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(oldPosition)
    end)
end


function bringTarget(targetPlayer)
    getgenv().character = targetPlayer.Character
    if not getgenv().character then return end
    
    getgenv().humanoid = getgenv().character:FindFirstChild("Humanoid")
    getgenv().bodyEffects = getgenv().character:FindFirstChild("BodyEffects")
    if not getgenv().bodyEffects or not getgenv().humanoid then return end
    
    getgenv().koValue = getgenv().bodyEffects:FindFirstChild("K.O")
    if not getgenv().koValue then return end

    getgenv().localCharacter = LocalPlayer.Character
    if not getgenv().localCharacter then return end

    getgenv().humanoidRootPart = getgenv().localCharacter:FindFirstChild("HumanoidRootPart")
    if not getgenv().humanoidRootPart then return end
    
    getgenv().oldPosition = getgenv().humanoidRootPart.Position
    getgenv().isActionRunning = true

    task.spawn(function()
        while not getgenv().koValue.Value and getgenv().isActionRunning do
            getgenv().targetPosition = getgenv().character:FindFirstChild("HumanoidRootPart") and getgenv().character.HumanoidRootPart.Position or nil
            if getgenv().targetPosition then
                getgenv().humanoidRootPart.CFrame = CFrame.new(getgenv().targetPosition + Vector3.new(0, -20, 0))
            end
            
            getgenv().tool = getgenv().localCharacter:FindFirstChildWhichIsA("Tool")
            if getgenv().tool and getgenv().tool:FindFirstChild("Ammo") then
                game:GetService("ReplicatedStorage").MainEvent:FireServer(
                    "ShootGun",
                    getgenv().tool:FindFirstChild("Handle"),
                    getgenv().tool:FindFirstChild("Handle").CFrame.Position,
                    getgenv().character.Head.Position,
                    getgenv().character.Head,
                    Vector3.new(0, 0, -1)
                )
            end

            task.wait()
        end
        
        repeat
            if getgenv().koValue.Value then
                getgenv().isActionRunning = false
                getgenv().humanoidRootPart.CFrame = CFrame.new(getgenv().oldPosition)
                return
            end

            getgenv().upperTorso = getgenv().character:FindFirstChild("UpperTorso")
            if getgenv().upperTorso then
                getgenv().humanoidRootPart.CFrame = CFrame.new(getgenv().upperTorso.Position + Vector3.new(0, 3, 0))
                game:GetService("RunService").RenderStepped:Wait()
            end
            
            game:GetService("ReplicatedStorage"):WaitForChild("MainEvent"):FireServer("Grabbing", false)
            task.wait(0.1)
        until getgenv().character:FindFirstChild("GRABBING_CONSTRAINT")
        task.wait(0.2)

        getgenv().humanoidRootPart.CFrame = CFrame.new(getgenv().oldPosition)
    end)
end

function stompTarget(targetPlayer)
    getgenv().character = targetPlayer.Character
    getgenv().humanoid = getgenv().character:FindFirstChild("Humanoid")
    getgenv().bodyEffects = getgenv().character:FindFirstChild("BodyEffects")
    
    if not getgenv().bodyEffects or not getgenv().humanoid then
        warn("BodyEffects or Humanoid not found in the character!")
        return
    end
    
    getgenv().koValue = getgenv().bodyEffects:WaitForChild("K.O", 5)
    getgenv().sDeathValue = getgenv().bodyEffects:WaitForChild("SDeath", 5)
    if not getgenv().koValue or not getgenv().sDeathValue then
        warn("K.O or SDeath value not found!")
        return
    end
    
    getgenv().oldPosition = LocalPlayer.Character.HumanoidRootPart.Position
    
    task.spawn(function()
        while not getgenv().koValue.Value and getgenv().isActionRunning do
            getgenv().targetPosition = getgenv().character.HumanoidRootPart.Position
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(getgenv().targetPosition + Vector3.new(0, -20, 0))
            
            getgenv().tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
            if getgenv().tool and getgenv().tool:FindFirstChild("Ammo") then
                ReplicatedStorage.MainEvent:FireServer("ShootGun", getgenv().tool:FindFirstChild("Handle"), getgenv().tool:FindFirstChild("Handle").CFrame.Position, getgenv().character.Head.Position, getgenv().character.Head, Vector3.new(0, 0, -1))
            end
            
            task.wait()
        end
        
        while not getgenv().sDeathValue.Value and getgenv().isActionRunning do
            getgenv().upperTorso = getgenv().character:FindFirstChild("UpperTorso")
            if getgenv().upperTorso then
                getgenv().humanoidRootPart = LocalPlayer.Character:WaitForChild("HumanoidRootPart")
                getgenv().humanoidRootPart.CFrame = CFrame.new(getgenv().upperTorso.Position + Vector3.new(0, 3, 0))
                RunService.RenderStepped:Wait()
            end
            ReplicatedStorage.MainEvent:FireServer("Stomp")
            task.wait()
        end
        
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(getgenv().oldPosition)
    end)
end

function voidTarget(targetPlayer)
    getgenv().character = targetPlayer.Character
    if not getgenv().character then return end
    
    getgenv().humanoid = getgenv().character:FindFirstChild("Humanoid")
    getgenv().bodyEffects = getgenv().character:FindFirstChild("BodyEffects")
    if not getgenv().bodyEffects or not getgenv().humanoid then return end
    
    getgenv().koValue = getgenv().bodyEffects:FindFirstChild("K.O")
    if not getgenv().koValue then return end

    getgenv().localCharacter = LocalPlayer.Character
    if not getgenv().localCharacter then return end

    getgenv().humanoidRootPart = getgenv().localCharacter:FindFirstChild("HumanoidRootPart")
    if not getgenv().humanoidRootPart then return end
    
    getgenv().oldPosition = getgenv().humanoidRootPart.Position
    getgenv().isActionRunning = true

    task.spawn(function()
        while not getgenv().koValue.Value and getgenv().isActionRunning do
            getgenv().targetPosition = getgenv().character:FindFirstChild("HumanoidRootPart") and getgenv().character.HumanoidRootPart.Position or nil
            if getgenv().targetPosition then
                getgenv().humanoidRootPart.CFrame = CFrame.new(getgenv().targetPosition + Vector3.new(0, -20, 0))
            end
            
            getgenv().tool = getgenv().localCharacter:FindFirstChildWhichIsA("Tool")
            if getgenv().tool and getgenv().tool:FindFirstChild("Ammo") then
                game:GetService("ReplicatedStorage").MainEvent:FireServer(
                    "ShootGun",
                    getgenv().tool:FindFirstChild("Handle"),
                    getgenv().tool:FindFirstChild("Handle").CFrame.Position,
                    getgenv().character.Head.Position,
                    getgenv().character.Head,
                    Vector3.new(0, 0, -1)
                )
            end

            task.wait()
        end
        
        repeat
            getgenv().upperTorso = getgenv().character:FindFirstChild("UpperTorso")
            if getgenv().upperTorso then
                getgenv().humanoidRootPart.CFrame = CFrame.new(getgenv().upperTorso.Position + Vector3.new(0, 3, 0))
                game:GetService("RunService").RenderStepped:Wait()
            end
            
            game:GetService("ReplicatedStorage"):WaitForChild("MainEvent"):FireServer("Grabbing", false)
            task.wait(0.2)
        until getgenv().character:FindFirstChild("GRABBING_CONSTRAINT")

        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-1000, 10000, -1000)
        task.wait(0.3)
        game:GetService("ReplicatedStorage"):WaitForChild("MainEvent"):FireServer("Grabbing", false)
        task.wait(0.2)
        getgenv().humanoidRootPart.CFrame = CFrame.new(getgenv().oldPosition)
    end)
end

function stopAllActions()
    getgenv().isActionRunning = false
    if getgenv().oldPosition then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(getgenv().oldPosition)
    end
    Library:Notify("All actions stopped.", 5)
end

getgenv().Services = {
    Players = game:GetService("Players"),
    LocalPlayer = game:GetService("Players").LocalPlayer
}

getgenv().PlayerInfo = Tabs.Players:AddLeftGroupbox('Player Info')

PlayerInfo:AddToggle('view', {
    Text = 'View',
    Default = false,
    Callback = function(state)
        if state and getgenv().SelectedTarget then
            local targetPlayer = Services.Players:FindFirstChild(getgenv().SelectedTarget)
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Humanoid") then
                workspace.CurrentCamera.CameraSubject = targetPlayer.Character.Humanoid
            end
        else
            workspace.CurrentCamera.CameraSubject = Services.LocalPlayer.Character.Humanoid
        end
    end,
})

PlayerInfo:AddButton('Teleport', function()
    local targetPlayer = Services.Players:FindFirstChild(getgenv().SelectedTarget)
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        Services.LocalPlayer.Character.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame
    end
end)

PlayerInfo:AddDropdown('teleportType', {
    Values = { 'safe', 'unsafe' },
    Default = 'unsafe',
    Multi = false,
    Text = 'Teleport Type',
    Callback = function(value)
        getgenv().SelectedTeleportType = value
    end,
})

getgenv().TargetDropdown = PlayerInfo:AddDropdown('yepyep', {
    SpecialType = 'Player',
    Text = 'Select a Player',
    Tooltip = 'Select a player to perform actions on.',
    Callback = function(value)
        getgenv().SelectedTarget = value
    end,
})

PlayerInfo:AddInput('playerSearch', {
    Text = 'Search Player',
    Tooltip = 'Type to search for a player.',
    Callback = function(value)
        local matches = {}
        value = string.lower(value)

        for _, player in ipairs(Services.Players:GetPlayers()) do
            local playerName = string.lower(player.Name)
            local displayName = string.lower(player.DisplayName)

            if string.find(playerName, value) or string.find(displayName, value) then
                table.insert(matches, player.Name) -- Use actual username
            end
        end

        options.yepyep:SetValue(matches)

        if #matches == 1 then
            Options.myPlayerDropdown:SetValue(matches[1])
            getgenv().SelectedTarget = matches[1]
        end
    end,
})


getgenv().PlayerActions = Tabs.Players:AddRightGroupbox('Player Actions')

getgenv().PlayerActions:AddDropdown('actionType', {
    Values = { 'Knock', 'Bring', 'Stomp', 'Void' },
    Default = 'Knock',
    Multi = false,
    Text = 'action',
    Callback = function(value)
        getgenv().SelectedAction = value
    end,
})

getgenv().PlayerActions:AddButton('Execute Action', function()
    local targetPlayer = Players:FindFirstChild(getgenv().SelectedTarget)
    if targetPlayer and targetPlayer.Character then
        local tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
        if tool and tool:FindFirstChild("Ammo") then
            getgenv().isActionRunning = true
            getgenv().oldPosition = LocalPlayer.Character.HumanoidRootPart.Position
            
            if getgenv().SelectedAction == "Knock" then
                knockTarget(targetPlayer)
            elseif getgenv().SelectedAction == "Bring" then
                bringTarget(targetPlayer)
            elseif getgenv().SelectedAction == "Stomp" then
                stompTarget(targetPlayer)
            elseif getgenv().SelectedAction == "Void" then
                voidTarget(targetPlayer)
            end
        else
            Library:Notify("Equip a tool to use this function. | ZestHub.lol", 5)
        end
    end
end)

PlayerActions:AddToggle("AutoKill", {
    Text = "Auto Kill",
    Default = false,
    Callback = function(State)
        getgenv().autoKillEnabled = State
        while getgenv().autoKillEnabled and getgenv().SelectedTarget do
            local targetPlayer = Players:FindFirstChild(getgenv().SelectedTarget)
            if targetPlayer and targetPlayer.Character then
                stompTarget(targetPlayer)
            end
            task.wait()
        end
    end
})

getgenv().PlayerActions:AddButton('Stop', function()
    stopAllActions()
end)

getgenv().AllPlayerActions = Tabs.Players:AddRightGroupbox('All Player Actions')

getgenv().ShopFolder = Workspace:WaitForChild("Ignored"):WaitForChild("Shop")
getgenv().OriginalPosition = nil
getgenv().KillAllEnabled = false
getgenv().StompAllEnabled = false
getgenv().CurrentTarget = nil

getgenv().BuyItem = function(itemName)
    -- Unequip all tools before buying
    for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
        if tool:IsA("Tool") then
            tool.Parent = LocalPlayer.Backpack
        end
    end

    for _, item in pairs(getgenv().ShopFolder:GetChildren()) do
        if item.Name == itemName then
            local itemHead = item:FindFirstChild("Head")
            if itemHead then
                LocalPlayer.Character.HumanoidRootPart.CFrame = itemHead.CFrame + Vector3.new(0, 3.2, 0)
                task.wait(0.1) -- Reduced wait time for faster execution
                fireclickdetector(item:FindFirstChild("ClickDetector"))
            end
            break
        end
    end
end

getgenv().EquipLMG = function()
    -- Check for LMG in both Backpack and Character
    for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
        if tool.Name == "[LMG]" then
            tool.Parent = LocalPlayer.Character
            return tool
        end
    end
    for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
        if tool.Name == "[LMG]" then
            return tool
        end
    end
    return nil
end

getgenv().ShootPlayer = function(target, tool)
    if not tool:FindFirstChild("Handle") then return end
    local targetHead = target.Character:FindFirstChild("Head")
    if not targetHead then return end
    ReplicatedStorage.MainEvent:FireServer("ShootGun", tool.Handle, tool.Handle.CFrame.Position, targetHead.Position, targetHead, Vector3.new(0, 0, -1))
end

getgenv().IsKnockedOut = function(target)
    local bodyEffects = target.Character:FindFirstChild("BodyEffects")
    if not bodyEffects then return false end
    local koValue = bodyEffects:FindFirstChild("K.O")
    return koValue and koValue.Value
end

getgenv().HasForcefield = function(target)
    return target.Character and target.Character:FindFirstChild("ForceField")
end

getgenv().IsGrabbing = function(target)
    return target.Character and target.Character:FindFirstChild("GRABBING_CONSTRAINT")
end

getgenv().IsTooFar = function(target)
    local distance = (LocalPlayer.Character.HumanoidRootPart.Position - target.Character.HumanoidRootPart.Position).Magnitude
    return distance > 10000
end

getgenv().KillAllPlayers = function()
    getgenv().OriginalPosition = LocalPlayer.Character.HumanoidRootPart.CFrame

    -- Unequip all tools before buying
    for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
        if tool:IsA("Tool") then
            tool.Parent = LocalPlayer.Backpack
        end
    end

    while not (LocalPlayer.Backpack:FindFirstChild("[LMG]") or LocalPlayer.Character:FindFirstChild("[LMG]")) do
        getgenv().BuyItem("[LMG] - $4098")
        task.wait(0.2) -- Reduced wait time for faster execution
    end

    for i = 1, 5 do
        getgenv().BuyItem("200 [LMG Ammo] - $328")
        task.wait(0) -- Reduced wait time for faster execution
    end

    local lmgTool = getgenv().EquipLMG()
    if not lmgTool then return end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if getgenv().HasForcefield(player) or getgenv().IsKnockedOut(player) or getgenv().IsGrabbing(player) or getgenv().IsTooFar(player) then
                continue
            end

            getgenv().CurrentTarget = player
            workspace.CurrentCamera.CameraSubject = player.Character.Humanoid

            while not getgenv().IsKnockedOut(player) and getgenv().KillAllEnabled do
                LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame - Vector3.new(0, 20, 0)
                getgenv().ShootPlayer(player, lmgTool)
                task.wait(0) -- Reduced wait time for faster execution
            end

            if not getgenv().KillAllEnabled then break end
        end
    end

    if getgenv().OriginalPosition then
        LocalPlayer.Character.HumanoidRootPart.CFrame = getgenv().OriginalPosition
    end

    workspace.CurrentCamera.CameraSubject = LocalPlayer.Character.Humanoid
    getgenv().CurrentTarget = nil

    if getgenv().StompAllEnabled then
        getgenv().StompAllPlayers()
    end
end

getgenv().StompAllPlayers = function()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local character = player.Character
            local humanoid = character:FindFirstChild("Humanoid")
            local bodyEffects = character:FindFirstChild("BodyEffects")

            if not bodyEffects or not humanoid then
                continue
            end

            local koValue = bodyEffects:FindFirstChild("K.O")
            local sDeathValue = bodyEffects:FindFirstChild("SDeath")

            if not koValue or not sDeathValue then
                continue
            end

            if koValue.Value and not sDeathValue.Value then
                while not sDeathValue.Value and getgenv().StompAllEnabled do
                    if not koValue.Value or getgenv().IsGrabbing(player) then
                        break -- Stop stomping if K.O is lost or player is grabbed
                    end

                    local upperTorso = character:FindFirstChild("UpperTorso")
                    if upperTorso then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(upperTorso.Position + Vector3.new(0, 3, 0))
                        RunService.RenderStepped:Wait()
                    end
                    ReplicatedStorage.MainEvent:FireServer("Stomp")
                    task.wait(0) -- Reduced wait time for faster execution
                end
            end
        end
    end
end

getgenv().AllPlayerActions:AddToggle("KillAllToggle", {
    Text = "Kill All",
    Default = false,
    Callback = function(value)
        getgenv().KillAllEnabled = value
        if value then
            getgenv().KillAllPlayers()
        else
            if getgenv().OriginalPosition then
                LocalPlayer.Character.HumanoidRootPart.CFrame = getgenv().OriginalPosition
            end
            workspace.CurrentCamera.CameraSubject = LocalPlayer.Character.Humanoid
        end
    end
})

getgenv().AllPlayerActions:AddToggle("StompAllToggle", {
    Text = "Stomp All",
    Default = false,
    Callback = function(value)
        getgenv().StompAllEnabled = value
        if value and not getgenv().KillAllEnabled then
            getgenv().StompAllPlayers()
        end
    end
})

getgenv().serenity = {}
getgenv().AutoShootEnabled = false

function isPlayerInSerenity(playerName)
    for _, name in pairs(getgenv().serenity) do
        if name == playerName then
            return true
        end
    end
    return false
end

function findPlayerByName(playerName)
    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        if player.Name:lower() == playerName:lower() then
            return player
        end
    end
    return nil
end

function togglePlayerInSerenity(playerName)
    local player = findPlayerByName(playerName)
    
    if not player then
        Library:Notify("Player not found in the game!", 5)
        return
    end

    if isPlayerInSerenity(playerName) then
        for i, name in pairs(getgenv().serenity) do
            if name == playerName then
                table.remove(getgenv().serenity, i)
                break
            end
        end
        Library:Notify(playerName .. " has been removed from Serenity Mode", 5)
    else
        table.insert(getgenv().serenity, playerName)
        Library:Notify(playerName .. " has been added to Serenity Mode", 5)
    end
end

function autoEquipTool()
    local player = game.Players.LocalPlayer
    local backpack = player:FindFirstChild("Backpack")
    if not backpack then return nil end

    local bestTool = nil

    -- Prioritize tools named "Rifle" or "Aug"
    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and tool:FindFirstChild("Ammo") then
            local toolName = tool.Name:lower()
            if toolName == "rifle" or toolName == "aug" then
                bestTool = tool
                break
            elseif not bestTool then
                bestTool = tool -- Fallback if no prioritized tool is found
            end
        end
    end

    if bestTool then
        bestTool.Parent = player.Character -- Equip the tool
        Library:Notify("Equipped tool: " .. bestTool.Name, 3)
        
        -- Wait until the tool is fully equipped
        repeat task.wait() until player.Character:FindFirstChildOfClass("Tool") == bestTool

        return bestTool
    end

    Library:Notify("No tool with Ammo found!", 3)
    return nil
end

getgenv().ShootPlayer = function(target, tool)
    if not tool or not tool:FindFirstChild("Handle") then return end
    local targetHead = target.Character and target.Character:FindFirstChild("Head")
    if not targetHead then return end
    
    -- Fire the shot
    game:GetService("ReplicatedStorage").MainEvent:FireServer("ShootGun", tool.Handle, tool.Handle.CFrame.Position, targetHead.Position, targetHead, Vector3.new(0, 0, -1))
end

getgenv().playerTextBox = AllPlayerActions:AddInput('PlayerTextBox', {
    Text = 'Serenity Mode',
    Tooltip = 'This will add a player to a table and if they go near you, it will automatically shoot them.',
    Default = '',
    Finished = true,
    Callback = function(Value)
        if Value and Value ~= "" then
            togglePlayerInSerenity(Value)
        end
    end
})

getgenv().autoShootToggle = AllPlayerActions:AddToggle('AutoShootToggle', {
    Text = 'Auto Shoot',
    Tooltip = 'Automatically shoots players in the Serenity table within 250 studs',
    Default = false,
    Callback = function(Value)
        getgenv().AutoShootEnabled = Value

        if Value then
            while getgenv().AutoShootEnabled do
                local character = game.Players.LocalPlayer.Character
                local rootPart = character and character:FindFirstChild("HumanoidRootPart")

                if rootPart then
                    for _, targetPlayerName in pairs(getgenv().serenity) do
                        local targetPlayer = game:GetService("Players"):FindFirstChild(targetPlayerName)
                        if targetPlayer and targetPlayer.Character then
                            local targetHead = targetPlayer.Character:FindFirstChild("Head")
                            if targetHead then
                                local distance = (rootPart.Position - targetHead.Position).Magnitude
                                
                                if distance <= 250 then
                                    local tool = character:FindFirstChildOfClass("Tool")

                                    if not tool then
                                        tool = autoEquipTool()
                                    end

                                    if tool then
                                        getgenv().ShootPlayer(targetPlayer, tool)
                                    end
                                end
                            end
                        end
                    end
                end
                task.wait(0)
            end
        end
    end
})


MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu keybind' })
Library.ToggleKeybind = Options.MenuKeybind

MenuGroup:AddToggle('KeybindListToggle', {
    Text = 'Show Keybind List',
    Default = false,
    Callback = function(state)
        Library.KeybindFrame.Visible = state
    end
})

getgenv().vu = game:GetService("VirtualUser")
getgenv().isAntiAfkEnabled = false
getgenv().antiAfkConnection = nil

MenuGroup:AddToggle('AntiAFKToggle', {
    Text = 'Anti-AFK',
    Default = false,
    Callback = function(state)
        getgenv().isAntiAfkEnabled = state
        if getgenv().isAntiAfkEnabled then
            getgenv().antiAfkConnection = game:GetService("Players").LocalPlayer.Idled:Connect(function()
                getgenv().vu:CaptureController()
                getgenv().vu:ClickButton2(Vector2.new())
            end)
        else
            if getgenv().antiAfkConnection then
                getgenv().antiAfkConnection:Disconnect()
                getgenv().antiAfkConnection = nil
            end
        end
    end
})


MenuGroup:AddButton('Copy Job ID', function()
    setclipboard(game.JobId)
end)

MenuGroup:AddButton('Copy JS Join Script', function()
    local jsScript = 'Roblox.GameLauncher.joinGameInstance(' .. game.PlaceId .. ', "' .. game.JobId .. '")'
    setclipboard(jsScript)
end)

MenuGroup:AddInput('JobIdInput', {
    Default = '',
    Numeric = false,
    Finished = true,
    Text = '..JobId..',
    Tooltip = 'Enter a Job ID to join a specific server',
    Placeholder = 'Enter Job ID here',
    Callback = function(Value)
        game:GetService('TeleportService'):TeleportToPlaceInstance(game.PlaceId, Value, game:GetService('Players').LocalPlayer)
    end
})


MenuGroup:AddButton('Rejoin Server', function()
    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, game.Players.LocalPlayer)
end)



ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('Zesty')
SaveManager:SetFolder('Zesty/configs')
SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])
SaveManager:LoadAutoloadConfig()

Library:SetWatermarkVisibility(true)

local StatsService = game:GetService("Stats")
local MarketplaceService = game:GetService("MarketplaceService")

local FrameTimer = tick()
local FrameCounter = 0
local FPS = 9999
local StartTime = tick()

local function getExecutor()
    if syn then return "Synapse X"
    elseif secure_call then return "ScriptWare"
    elseif identifyexecutor then return identifyexecutor()
    else return "Unknown" end
end

local function getGameName(placeId)
    local success, result = pcall(function()
        return MarketplaceService:GetProductInfo(placeId).Name
    end)
    return success and result or "Unknown Game"
end

local WatermarkConnection = RunService.RenderStepped:Connect(function()
    FrameCounter += 1
    if (tick() - FrameTimer) >= 1 then
        FPS = FrameCounter
        FrameTimer = tick()
        FrameCounter = 0
    end

    local Ping = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue())
    local Executor = getExecutor()
    local Uptime = math.floor(tick() - StartTime)
    local UptimeFormatted = string.format("%02d:%02d", math.floor(Uptime / 60), Uptime % 60)
    local GameName = getGameName(game.PlaceId)

    --local Player = game:GetService("Players").LocalPlayer
    --if Executor == "Xeno" then
    --   Player:Kick("Xeno is not supported")
    --end

    Library:SetWatermark(("[ ZestHub.lol ] | $ Beta $ |  %s | %s (%d) | Uptime: %s | FPS %d | %d ms"):format(
        Executor, GameName, game.PlaceId, UptimeFormatted, math.floor(FPS), Ping
    ))
end)



Library:OnUnload(function()
    WatermarkConnection:Disconnect()
    print('Unloaded!')
    Library.Unloaded = true
end)
