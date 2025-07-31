local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

-- Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera
local localplayer = game.Players.LocalPlayer
local uis = game:GetService("UserInputService")

local wcamera = workspace.CurrentCamera
local runs = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local tweens = game:GetService("TweenService")
local TweenService = game:GetService("TweenService")
local scriptloading = true
local ACBYPASS_SYNC = false
local keybindlist = false
local keylist_gui 
local keylist_items = {}
local a1table
local cfgloading = false
local characterspawned = tick()
local aimresolvertime = tick()
local nojumptilt = false



-- Original functions
local instrelOGfunc = require(game.ReplicatedStorage.Modules.FPS).reload
local instrelMODfunc -- changed later

-- All variables table
allvars = allvars or {}
local aimresolverpos = localplayer.Character.HumanoidRootPart.CFrame

-- Free cam variables
getgenv().freeCam = false
getgenv().freeCamPart = nil
getgenv().originalCFrame = nil
local camera = workspace.CurrentCamera
local player = game.Players.LocalPlayer
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")

getgenv().MOVE_SPEED = 16
getgenv().LOOK_SENSITIVITY = 0.002
getgenv().FAST_SPEED_MULTIPLIER = 3

-- Camera rotation tracking
getgenv().cameraAngles = Vector2.new(0, 0)
getgenv().mouseConnection = nil
getgenv().cameraAngles = Vector2.new(0, 0)

getgenv().BeamTexture = {
    [1] = "rbxassetid://12781806168",
    [2] = "rbxassetid://12781741946"
}

-- Create a lookup table for the dropdown values (optional, for better names)
getgenv().beamTextureUI = {
    "Texture 1",
    "Texture 2"
}

allvars.Zestequip = false
allvars.instareload = false
allvars.noswaybool = false
allvars.viewmodoffset = false
allvars.viewmodX = 0
allvars.viewmodY = 0
allvars.viewmodZ = 0
allvars.aimfakewait = false

allvars.tracbool = false
allvars.resolvertimeout = 2
allvars.tracwait = 2
allvars.desyncbool = false
allvars.traccolor = Color3.fromRGB(255,255,255)
allvars.tractexture = nil

-- Hitmarker settings
allvars.hitmarkbool = false
allvars.hitmarkcolor = Color3.new(1, 0, 0) -- Red
allvars.hitmarkfade = 0.5 -- Fade time in seconds
allvars.camthirdp = false
getgenv().thirdpshow = false
allvars.camthirdpX = 2
allvars.camthirdpY = 2
allvars.camthirdpZ = 5
allvars.nofall = false
-- Tracer settings
allvars.tracbool = true
allvars.tracercolor3 = Color3.new(1, 1, 0)
allvars.tracertrans = 0.3
allvars.tracerwidth = 0.1
allvars.tracerfade = 0.3
allvars.resolvers = false
allvars.tracerbloom = true
allvars.usebeamtracer = true
allvars.nojumpcd = false
--["Bubble"]    = "rbxassetid://198598793",
--["Quake"]     = "rbxassetid://1455817260",
--["Among-Us"]  = "rbxassetid://7227567562",
--["Ding"]      = "rbxassetid://2868331684",
allvars.hitsoundbool = false
allvars.hitsoundhead = "Ding"
allvars.hitsoundbody = "Blackout"
local hitsoundlib = {
    ["TF2"]       = "rbxassetid://8255306220",
    ["Skeet"] = "rbxassetid://4817809188",
    ["Rust"]      = "rbxassetid://1255040462",
    ["Neverlose"] = "rbxassetid://8726881116",
    ["Minecraft"] = "rbxassetid://6361963422",
    ["Blackout"]  = "rbxassetid://3748776946",
    ["Ouz"]      = "rbxassetid://7151989073",
}
getgenv().hitsoundlibUI = {}
for i,v in hitsoundlib do
    table.insert(hitsoundlibUI, i)
end

local tractextures = {
    ["None"] = nil,
    ["Lighting"] = "http://www.roblox.com/asset/?id=131326755401058",
}

allvars.worldleaves = false
allvars.worldgrass = false
allvars.worldcloud = false

local terrainmats = {
    "Grass",
    "Sand",
    "Sandstone",
    "Mud",
    "Ground",
    "Rock",
    "Brick",
    "Cobblestone",
    "Concrete",
    "Glacier",
    "Asphalt",
    "Snow",
    "Basalt",
    "Salt",
    "Limestone",
    "Pavement",
    "LeafyGrass",
    "Ice",
    "Slate",
    "CrackedLava"
}

allvars.aimbool = false
allvars.aimbots = false
allvars.aimvischeck = false
allvars.aimdistcheck = false
allvars.aimbang = false
allvars.aimtrigger = false

allvars.undergroundResolver = false
getgenv().aimtarget = nil
getgenv().aimtargetpart = nil
getgenv().aimpretarget = nil
allvars.showfov = false
allvars.aimfovcolor = Color3.fromRGB(255,255,255)
allvars.showname = false
allvars.showhp = false
allvars.aimdynamicfov = false
allvars.aimpart = "Head"
getgenv().invisanim = Instance.new("Animation")
invisanim.AnimationId = "rbxassetid://15609995579"
getgenv().invisnum = 2.35
local invistrack

getgenv().desynctable = {}
getgenv().desyncvis = nil
allvars.desyncbool = false
allvars.invisbool = false
allvars.desyncPos = false
allvars.desynXp = 0
allvars.desynYp = 0
allvars.desynZp = 0
allvars.desyncOr = false
allvars.desynXo = 0
allvars.desynYo = 0
allvars.desynZo = 0
getgenv().visdesync = false
getgenv().desynccolor = Color3.fromRGB(255,0,0)
getgenv().desynctrans = 1
getgenv().blinkbool = false
getgenv().blinktemp = false
getgenv().blinkstop = false
getgenv().blinknoclip = false
getgenv().blinktable = {}
allvars.aimfov = 150
allvars.aimdistance = 800
allvars.aimchance = 100
allvars.predictionStrength = 1
local aimignoreparts = {}

local aimfovcircle = Drawing.new("Circle")
aimfovcircle.Visible = allvars.showfov
aimfovcircle.Radius = allvars.aimfov
aimfovcircle.Color = allvars.aimfovcolor
aimfovcircle.Thickness = 1
aimfovcircle.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y/2)
aimfovcircle.Filled = false
aimfovcircle.Transparency = 1

RunService.RenderStepped:Connect(function()
aimfovcircle.Visible = allvars.showfov and allvars.aimbool
aimfovcircle.Radius = allvars.aimfov
aimfovcircle.Color = allvars.aimfovcolor
aimfovcircle.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y/2)
end)

-- CamLock Variables
getgenv().camLockEnabled = false
getgenv().camLockTarget = nil
getgenv().smoothness = 0.5
getgenv().aimPart = "Head"
getgenv().fovRadius = 100
getgenv().showFovCircle = false
getgenv().fovCircle = nil
getgenv().prediction = 0.1
getgenv().wallCheck = false
getgenv().knockCheckEnabled = false
getgenv().nojumptilt = false
getgenv().a1table = nil
getgenv().joindetect = false
getgenv().leavedetect = false
allvars.doublejump = false
allvars.instaequip = false
getgenv().candbjump = false
getgenv().dbjumplast = 0
getgenv().dbjumpdelay = 0.2


-------------------double jump---------------------
uis.JumpRequest:Connect(function()
    if not allvars.doublejump then return end
    
    local ctime = tick()
    if ctime - dbjumplast < dbjumpdelay then return end
    
    local state = localplayer.Character.Humanoid:GetState()
    if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall then
        if candbjump then
            localplayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            candbjump = false
            dbjumplast = ctime
        end
    end
end)
localplayer.Character.Humanoid.StateChanged:Connect(function(_, state)
    if not allvars.doublejump then return end
    
    if state == Enum.HumanoidStateType.Jumping then
        candbjump = true
        dbjumplast = tick()
    elseif state == Enum.HumanoidStateType.Landed then
        candbjump = false
    end
end)
localplayer.CharacterAdded:Connect(function()
    task.wait(1.5)

    localplayer.Character.Humanoid.StateChanged:Connect(function(_, state)
        if not allvars.doublejump then return end
        
        if state == Enum.HumanoidStateType.Jumping then
            candbjump = true
            dbjumplast = tick()
        elseif state == Enum.HumanoidStateType.Landed then
            candbjump = false
        end
    end)
end)


--player logs--
game.Players.PlayerAdded:Connect(function(plr)
    if joindetect then
        Library:Notify(plr.Name .. " joined this server", 3, Color3.fromRGB(0,255,0))
    end
end)
game.Players.PlayerRemoving:Connect(function(plr)
    if leavedetect then
        Library:Notify(plr.Name .. " left this server", 3, Color3.fromRGB(255,0,0))
    end
end)

--upangle editor--
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)
mt.__namecall = newcclosure(function(self, ...)
    local Method = getnamecallmethod()
    local Args = {...}
    if Method == "FireServer" and self.Name == "UpdateTilt" then
        if allvars.upanglebool then
            Args[1] = allvars.upanglenum
            return oldNamecall(self, table.unpack(Args))
        elseif allvars.invisbool and allvars.desyncbool then
            Args[1] = 0.75
            return oldNamecall(self, table.unpack(Args))
        end
    end
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

--thirdperson fix + desync camera fix--
local mt = getrawmetatable(game)
local oldIndex = mt.__newindex
setreadonly(mt, false)
mt.__newindex = newcclosure(function(self, index, value)
    if tostring(self) == "Humanoid" and index == "CameraOffset" then
        local offset = Vector3.zero

        if allvars.desyncbool then
            if allvars.desyncPos then
                offset += Vector3.new(-allvars.desynXp, -allvars.desynYp, -allvars.desynZp)
            end
            if allvars.desyncOr then
                -- to make
            end
        end

        if allvars.camthirdp then
            offset += Vector3.new(allvars.camthirdpX, allvars.camthirdpY, allvars.camthirdpZ)
        end

        return oldIndex(self, index, offset)
    end
    return oldIndex(self, index, value)
end)
setreadonly(mt, true)
local meleeray
meleeray = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if not mforcehit then return meleeray(self, ...) end

    if method == "Raycast" and aimtargetpart ~= nil and debug.getinfo(5, "f").short_src == "ReplicatedStorage.Modules.FPS.Melee" then
        local tpart = aimtargetpart
        local tchar = tpart.Parent
        local npart = tchar:FindFirstChild(mhitpart)
        if not npart then return meleeray(self, ...) end
        if (npart.Position - localplayer.Character.Head.Position).Magnitude > 11 then return meleeray(self, ...) end
        
        return {
            Instance = npart,
            Position = npart.Position,
            Normal = Vector3.new(1, 0, 0),
            Material = npart.Material,
            Distance = (npart.Position - localplayer.Character.Head.Position).Magnitude
        }
    end

    return meleeray(self, ...)
end)
task.spawn(function() --underground users
while wait(0.1) do
    for i,v in ipairs(undergroundusers) do
        if not v or not v:FindFirstChild("Humanoid") or v.Humanoid.Health <= 0 then
            table.remove(undergroundusers, i)
            continue
        end
        local found = false
        for _, track in v.Humanoid.Animator:GetPlayingAnimationTracks() do
            if track.Animation.AnimationId == invisanim.AnimationId then
                found = true
                break
            end
        end
        if found == false then
            table.remove(undergroundusers, i)
            continue
        end
    end

    for i,v in game.Players:GetPlayers() do
        if not v.Character or not v.Character:FindFirstChild("Humanoid") or v.Character.Humanoid.Health <= 0 or v == localplayer then continue end
        for _, track in v.Character.Humanoid.Animator:GetPlayingAnimationTracks() do
            if track.Animation.AnimationId == invisanim.AnimationId then
                table.insert(undergroundusers,v.Character)
                break
            end
        end
    end
end
end)
runs.RenderStepped:Connect(function(delta) --model manipulation
if modelmanip then
    for i,v in ipairs(undergroundusers) do
        if not v or not v:FindFirstChild("Humanoid") or v.Humanoid.Health <= 0 or v == localplayer then 
            table.remove(undergroundusers,i)
            continue 
        end

        for _, track in v.Humanoid.Animator:GetPlayingAnimationTracks() do
            if track.Animation.AnimationId == invisanim.AnimationId then
                track:Stop()
                break
            end
        end
    end
end
end)



--if allvars.aimtrigger and aimtarget and not hasWallBetween(startPos, endPos, aimtarget) then    fpsrequired.action(getgenv().a1table, true)
--    wait()
--    fpsrequired.action(getgenv().a1table, false)
--end


function startnojumpcd()
    while allvars.nojumpcd do
        task.wait(0.01)
        if game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
            game.Players.LocalPlayer.Character.Humanoid:SetAttribute("JumpCooldown", tick())
        else
            wait(1)
        end
    end
end 


getgenv().whisperESPEnabled = true
getgenv().whisperColor = Color3.new(1, 0, 0) -- Red color for Whisper
getgenv().whisperBoxESPEnabled = true
getgenv().whisperNameESPEnabled = true
getgenv().whisperDistanceESPEnabled = true
getgenv().whisperHealthBarESP = true

-- Whisper ESP Objects storage
local WhisperESPObjects = {}

-- Function to completely destroy Whisper ESP objects
local function DestroyWhisperESP()
    if WhisperESPObjects.Box then WhisperESPObjects.Box:Remove() end
    if WhisperESPObjects.BoxOutline then WhisperESPObjects.BoxOutline:Remove() end
    if WhisperESPObjects.Name then WhisperESPObjects.Name:Remove() end
    if WhisperESPObjects.Distance then WhisperESPObjects.Distance:Remove() end
    if WhisperESPObjects.HealthBarBackground then WhisperESPObjects.HealthBarBackground:Remove() end
    if WhisperESPObjects.HealthBar then WhisperESPObjects.HealthBar:Remove() end
    if WhisperESPObjects.HealthBarOutline then WhisperESPObjects.HealthBarOutline:Remove() end
    WhisperESPObjects = {}
end

-- Function to create Whisper ESP
local function CreateWhisperESP()
    if not getgenv().whisperESPEnabled then return end
    
    DestroyWhisperESP()
    
    -- Create box ESP
    if getgenv().whisperBoxESPEnabled then
        WhisperESPObjects.Box = Drawing.new("Square")
        WhisperESPObjects.Box.Thickness = 1
        WhisperESPObjects.Box.Filled = false
        WhisperESPObjects.Box.Color = getgenv().whisperColor
        WhisperESPObjects.Box.Visible = false
        WhisperESPObjects.Box.ZIndex = 2
        
        -- Create box outline
        WhisperESPObjects.BoxOutline = Drawing.new("Square")
        WhisperESPObjects.BoxOutline.Thickness = 3
        WhisperESPObjects.BoxOutline.Filled = false
        WhisperESPObjects.BoxOutline.Color = Color3.new(0, 0, 0)
        WhisperESPObjects.BoxOutline.Visible = false
        WhisperESPObjects.BoxOutline.ZIndex = 1
    end
    
    -- Create name text if enabled
    if getgenv().whisperNameESPEnabled then
        WhisperESPObjects.Name = Drawing.new("Text")
        WhisperESPObjects.Name.Size = 14
        WhisperESPObjects.Name.Center = true
        WhisperESPObjects.Name.Color = getgenv().whisperColor
        WhisperESPObjects.Name.Visible = false
        WhisperESPObjects.Name.Outline = true
        WhisperESPObjects.Name.OutlineColor = Color3.new(0, 0, 0)
    end
    
    -- Create distance text if enabled
    if getgenv().whisperDistanceESPEnabled then
        WhisperESPObjects.Distance = Drawing.new("Text")
        WhisperESPObjects.Distance.Size = 14
        WhisperESPObjects.Distance.Center = true
        WhisperESPObjects.Distance.Color = getgenv().whisperColor
        WhisperESPObjects.Distance.Visible = false
        WhisperESPObjects.Distance.Outline = true
        WhisperESPObjects.Distance.OutlineColor = Color3.new(0, 0, 0)
    end
    
    -- Create health bar if enabled
    if getgenv().whisperHealthBarESP then
        WhisperESPObjects.HealthBarBackground = Drawing.new("Square")
        WhisperESPObjects.HealthBarBackground.Thickness = 1
        WhisperESPObjects.HealthBarBackground.Filled = true
        WhisperESPObjects.HealthBarBackground.Color = Color3.new(0.2, 0.2, 0.2)
        WhisperESPObjects.HealthBarBackground.Visible = false
        WhisperESPObjects.HealthBarBackground.ZIndex = 0

        WhisperESPObjects.HealthBar = Drawing.new("Square")
        WhisperESPObjects.HealthBar.Thickness = 1
        WhisperESPObjects.HealthBar.Filled = true
        WhisperESPObjects.HealthBar.Color = getgenv().whisperColor
        WhisperESPObjects.HealthBar.Visible = false
        WhisperESPObjects.HealthBar.ZIndex = 1

        WhisperESPObjects.HealthBarOutline = Drawing.new("Square")
        WhisperESPObjects.HealthBarOutline.Thickness = 1
        WhisperESPObjects.HealthBarOutline.Filled = false
        WhisperESPObjects.HealthBarOutline.Color = Color3.new(0, 0, 0)
        WhisperESPObjects.HealthBarOutline.Visible = false
        WhisperESPObjects.HealthBarOutline.ZIndex = 2
    end
end

-- Function to update Whisper ESP
local function UpdateWhisperESP()
    if not getgenv().whisperESPEnabled then 
        DestroyWhisperESP()
        return 
    end
    
    local localCharacter = LocalPlayer.Character
    if not localCharacter or not localCharacter:FindFirstChild("HumanoidRootPart") then 
        DestroyWhisperESP()
        return 
    end
    local localPosition = localCharacter.HumanoidRootPart.Position
    
    -- Check if Whisper exists
    local whisper = workspace:FindFirstChild("AiZones") and workspace.AiZones:FindFirstChild("Whisper") and workspace.AiZones.Whisper:FindFirstChild("Whisper")
    if not whisper or not whisper:FindFirstChild("HumanoidRootPart") then
        DestroyWhisperESP()
        return
    end
    
    -- Create ESP if it doesn't exist
    if not WhisperESPObjects.Box and getgenv().whisperBoxESPEnabled then
        CreateWhisperESP()
    end
    
    -- Calculate distance
    local distance = (localPosition - whisper.HumanoidRootPart.Position).Magnitude
    
    -- Convert position to screen space
    local whisperPosition, onScreen = Camera:WorldToViewportPoint(whisper.HumanoidRootPart.Position)
    
    if onScreen then
        -- Calculate box size based on distance
        local boxSize = Vector2.new(40, 60) * (1 - math.clamp(distance / 500, 0, 0.8))
        
        -- Update box ESP
        if WhisperESPObjects.Box then
            WhisperESPObjects.Box.Position = Vector2.new(whisperPosition.X - boxSize.X/2, whisperPosition.Y - boxSize.Y/2)
            WhisperESPObjects.Box.Size = boxSize
            WhisperESPObjects.Box.Color = getgenv().whisperColor
            WhisperESPObjects.Box.Visible = true
            
            WhisperESPObjects.BoxOutline.Position = WhisperESPObjects.Box.Position
            WhisperESPObjects.BoxOutline.Size = WhisperESPObjects.Box.Size
            WhisperESPObjects.BoxOutline.Visible = true
        end
        
        -- Update name ESP
        if WhisperESPObjects.Name then
            WhisperESPObjects.Name.Position = Vector2.new(whisperPosition.X, whisperPosition.Y - boxSize.Y/2 - 15)
            WhisperESPObjects.Name.Text = "Whisper"
            WhisperESPObjects.Name.Color = getgenv().whisperColor
            WhisperESPObjects.Name.Visible = true
        end
        
        -- Update distance ESP
        if WhisperESPObjects.Distance then
            WhisperESPObjects.Distance.Position = Vector2.new(whisperPosition.X, whisperPosition.Y + boxSize.Y/2 + 5)
            WhisperESPObjects.Distance.Text = string.format("%.1fm", distance * 0.28)
            WhisperESPObjects.Distance.Visible = true
            WhisperESPObjects.Distance.Color = getgenv().whisperColor
        end
        
        -- Update health bar ESP
        if WhisperESPObjects.HealthBar and whisper:FindFirstChildOfClass("Humanoid") then
            local humanoid = whisper:FindFirstChildOfClass("Humanoid")
            local healthRatio = humanoid.Health / humanoid.MaxHealth
            local barWidth = 3
            local barHeight = boxSize.Y * healthRatio
            
            -- Health bar background
            WhisperESPObjects.HealthBarBackground.Position = Vector2.new(whisperPosition.X - boxSize.X/2 - barWidth - 2, whisperPosition.Y - boxSize.Y/2)
            WhisperESPObjects.HealthBarBackground.Size = Vector2.new(barWidth, boxSize.Y)
            WhisperESPObjects.HealthBarBackground.Visible = true
            
            -- Health bar
            WhisperESPObjects.HealthBar.Position = Vector2.new(whisperPosition.X - boxSize.X/2 - barWidth - 2, whisperPosition.Y - boxSize.Y/2 + (boxSize.Y - barHeight))
            WhisperESPObjects.HealthBar.Size = Vector2.new(barWidth, barHeight)
            WhisperESPObjects.HealthBar.Visible = true
            
            -- Health bar outline
            WhisperESPObjects.HealthBarOutline.Position = WhisperESPObjects.HealthBarBackground.Position
            WhisperESPObjects.HealthBarOutline.Size = WhisperESPObjects.HealthBarBackground.Size
            WhisperESPObjects.HealthBarOutline.Visible = true
        end
    else
        -- Hide all ESP elements if off-screen
        if WhisperESPObjects.Box then WhisperESPObjects.Box.Visible = false end
        if WhisperESPObjects.BoxOutline then WhisperESPObjects.BoxOutline.Visible = false end
        if WhisperESPObjects.Name then WhisperESPObjects.Name.Visible = false end
        if WhisperESPObjects.Distance then WhisperESPObjects.Distance.Visible = false end
        if WhisperESPObjects.HealthBarBackground then WhisperESPObjects.HealthBarBackground.Visible = false end
        if WhisperESPObjects.HealthBar then WhisperESPObjects.HealthBar.Visible = false end
        if WhisperESPObjects.HealthBarOutline then WhisperESPObjects.HealthBarOutline.Visible = false end
    end
end

-- Function to apply Whisper ESP settings
function applyWhisperESP()
    if not getgenv().whisperESPEnabled then
        DestroyWhisperESP()
        return
    end
    
    CreateWhisperESP()
end

RunService.RenderStepped:Connect(function()
    UpdateWhisperESP()
end)
-------------------LOOT ESP-----------------
-- Configuration
getgenv().lootESPEnabled = true
getgenv().lootColor = Color3.new(1, 0, 1) -- Default magenta color for loot
getgenv().lootMaxDistance = 500
getgenv().lootNameEnabled = true
getgenv().lootDistanceEnabled = true
getgenv().lootHighlightEnabled = false
getgenv().lootHighlightColor = Color3.new(1, 0, 1)

-- Loot ESP Objects storage
getgenv().LootESPObjects = {}
getgenv().LootHighlightObjects = {}

-- Function to completely destroy Loot ESP objects
local function DestroyLootESP(item)
    if LootESPObjects[item] then
        if LootESPObjects[item].Box then LootESPObjects[item].Box:Remove() end
        if LootESPObjects[item].BoxOutline then LootESPObjects[item].BoxOutline:Remove() end
        if LootESPObjects[item].Name then LootESPObjects[item].Name:Remove() end
        if LootESPObjects[item].Distance then LootESPObjects[item].Distance:Remove() end
        LootESPObjects[item] = nil
    end
    
    if LootHighlightObjects[item] then
        LootHighlightObjects[item]:Destroy()
        LootHighlightObjects[item] = nil
    end
end

-- Function to create Loot ESP
local function CreateLootESP(item)
    if not getgenv().lootESPEnabled then return end
    
    DestroyLootESP(item)
    
    getgenv().objects = {}
    
    -- Create box ESP
    objects.Box = Drawing.new("Square")
    objects.Box.Thickness = 1
    objects.Box.Filled = false
    objects.Box.Color = getgenv().lootColor
    objects.Box.Visible = false
    objects.Box.ZIndex = 2
    
    -- Create box outline
    objects.BoxOutline = Drawing.new("Square")
    objects.BoxOutline.Thickness = 3
    objects.BoxOutline.Filled = false
    objects.BoxOutline.Color = Color3.new(0, 0, 0)
    objects.BoxOutline.Visible = false
    objects.BoxOutline.ZIndex = 1
    
    -- Create name text if enabled
    if getgenv().lootNameEnabled then
        objects.Name = Drawing.new("Text")
        objects.Name.Size = 14
        objects.Name.Center = true
        objects.Name.Color = getgenv().lootColor
        objects.Name.Visible = false
        objects.Name.Outline = true
        objects.Name.OutlineColor = Color3.new(0, 0, 0)
    end
    
    -- Create distance text if enabled
    if getgenv().lootDistanceEnabled then
        objects.Distance = Drawing.new("Text")
        objects.Distance.Size = 14
        objects.Distance.Center = true
        objects.Distance.Color = getgenv().lootColor
        objects.Distance.Visible = false
        objects.Distance.Outline = true
        objects.Distance.OutlineColor = Color3.new(0, 0, 0)
    end
    
    LootESPObjects[item] = objects
    
    -- Create highlight if enabled
    if getgenv().lootHighlightEnabled then
        local highlight = Instance.new("Highlight")
        highlight.FillColor = getgenv().lootHighlightColor
        highlight.OutlineColor = Color3.new(0, 0, 0)
        highlight.FillTransparency = 0.8
        highlight.OutlineTransparency = 0.5
        highlight.Parent = item
        LootHighlightObjects[item] = highlight
    end
end

-- Function to update Loot ESP
local function UpdateLootESP()
    if not getgenv().lootESPEnabled then return end
    
    local localCharacter = LocalPlayer.Character
    if not localCharacter or not localCharacter:FindFirstChild("HumanoidRootPart") then return end
    local localPosition = localCharacter.HumanoidRootPart.Position
    
    -- Get all items in DroppedItems folder
    local droppedItems = workspace:FindFirstChild("DroppedItems")
    if not droppedItems then return end
    
    -- First pass: Remove ESP for items that no longer exist
    for item, _ in pairs(LootESPObjects) do
        if not item or not item.Parent or item.Parent ~= droppedItems then
            DestroyLootESP(item)
        end
    end
    
    -- Second pass: Update existing or create new ESP
    for _, item in pairs(droppedItems:GetChildren()) do
        -- Only process items with a primary part (visible in workspace)
        if item:IsA("Model") and item.PrimaryPart then
            -- Create ESP if it doesn't exist
            if not LootESPObjects[item] then
                CreateLootESP(item)
            end
            
            local objects = LootESPObjects[item]
            if not objects then return end
            
            -- Calculate distance
            local distance = (localPosition - item.PrimaryPart.Position).Magnitude
            
            -- Check max distance
            if distance > getgenv().lootMaxDistance then
                objects.Box.Visible = false
                objects.BoxOutline.Visible = false
                if objects.Name then objects.Name.Visible = false end
                if objects.Distance then objects.Distance.Visible = false end
                if LootHighlightObjects[item] then
                    LootHighlightObjects[item].Enabled = false
                end
                continue
            end
            
            -- Convert position to screen space
            local itemPosition, onScreen = Camera:WorldToViewportPoint(item.PrimaryPart.Position)
            
            if onScreen then
                -- Calculate box size based on distance (smaller when farther away)
                local boxSize = Vector2.new(30, 30) * (1 - math.clamp(distance / getgenv().lootMaxDistance, 0, 0.8))
                
                -- Update box ESP
                objects.Box.Position = Vector2.new(itemPosition.X - boxSize.X/2, itemPosition.Y - boxSize.Y/2)
                objects.Box.Size = boxSize
                objects.Box.Color = getgenv().lootColor
                objects.Box.Visible = true
                
                objects.BoxOutline.Position = objects.Box.Position
                objects.BoxOutline.Size = objects.Box.Size
                objects.BoxOutline.Visible = true
                
                -- Update name ESP
                if objects.Name then
                    objects.Name.Position = Vector2.new(itemPosition.X, itemPosition.Y - boxSize.Y/2 - 15)
                    objects.Name.Text = item.Name
					objects.Name.Color = getgenv().lootColor
                    objects.Name.Visible = true
                end
                
                -- Update distance ESP
                if objects.Distance then
                    objects.Distance.Position = Vector2.new(itemPosition.X, itemPosition.Y + boxSize.Y/2 + 5)
                    objects.Distance.Text = string.format("%.1fm", distance * 0.28) -- Convert to meters
                    objects.Distance.Visible = true
					objects.Distance.Color = getgenv().lootColor
                end
                
                -- Update highlight
                if LootHighlightObjects[item] then
                    LootHighlightObjects[item].Enabled = true
                end
            else
                -- Hide ESP if off-screen
                objects.Box.Visible = false
                objects.BoxOutline.Visible = false
                if objects.Name then objects.Name.Visible = false end
                if objects.Distance then objects.Distance.Visible = false end
                if LootHighlightObjects[item] then
                    LootHighlightObjects[item].Enabled = false
                end
            end
        end
    end
end

-- Function to apply Loot ESP settings
function applyLootESP()
    if not getgenv().lootESPEnabled then
        -- Destroy all Loot ESP when disabled
        for item, _ in pairs(LootESPObjects) do
            DestroyLootESP(item)
        end
        return
    end
    
    -- Create ESP for all existing items
    local droppedItems = workspace:FindFirstChild("DroppedItems")
    if droppedItems then
        for _, item in pairs(droppedItems:GetChildren()) do
            if item:IsA("Model") and item.PrimaryPart then
                CreateLootESP(item)
            end
        end
    end
end

-- Function to apply Loot Highlight settings
function applyLootHighlight()
    for item, _ in pairs(LootHighlightObjects) do
        if item and item.Parent then
            if getgenv().lootHighlightEnabled then
                LootHighlightObjects[item].Enabled = true
                LootHighlightObjects[item].FillColor = getgenv().lootHighlightColor
            else
                LootHighlightObjects[item].Enabled = false
            end
        end
    end
end

-- Track DroppedItems folder for changes
local function monitorDroppedItems()
    while wait(1) do
        local droppedItems = workspace:FindFirstChild("DroppedItems")
        if droppedItems then
            -- Set up connection for new items
            droppedItems.ChildAdded:Connect(function(item)
                if item:IsA("Model") and item.PrimaryPart then
                    CreateLootESP(item)
                end
            end)
            
            -- Set up connection for removed items
            droppedItems.ChildRemoved:Connect(function(item)
                DestroyLootESP(item)
            end)
            
            -- Break the loop once connections are set up
            break
        end
    end
end

-- Initialize Loot ESP
spawn(monitorDroppedItems)

-- Update Loot ESP on every frame
RunService.RenderStepped:Connect(function()
    UpdateLootESP()
end)

----------------------
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
getgenv().highlightFillTransparency = 0 -- NEW: Highlight fill transparency
getgenv().highlightOutlineTransparency = 1 -- NEW: Highlight outline transparency
getgenv().maxDistance = 1000
getgenv().maxDistanceEnabled = false

-- Create Window
local Window = Library:CreateWindow({
    Title = 'Zest Hub',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

-- Create Tabs	
local Tabs = {
    Main = Window:AddTab('Main'),
    Legit = Window:AddTab('Legit'),
    Visuals = Window:AddTab('Visual'),
    AntiAim = Window:AddTab('AntiAim'),
    Movement = Window:AddTab('Movement'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

local gunmods = Tabs.Main:AddLeftGroupbox('Gun Modifications')
local gunmods2 = Tabs.Main:AddRightGroupbox('Gun custom')
local Others = Tabs.Main:AddLeftGroupbox('Other')
local CamLockBox = Tabs.Legit:AddRightGroupbox('CamLock')
local espUI = Tabs.Visuals:AddLeftGroupbox('ESP')
local espUI2 = Tabs.Visuals:AddLeftGroupbox('LootEsp')
local WorldStuff = Tabs.Visuals:AddRightGroupbox('World')
local DesyncBox = Tabs.AntiAim:AddRightGroupbox('Antiaim')
local uhhh = Tabs.Movement:AddRightGroupbox('Movement')
local tracers = Tabs.Visuals:AddRightGroupbox('Tracers')
local aim = Tabs.Legit:AddLeftGroupbox('Silent aim')

    function getcurrentgun(plr)
    local char = plr.Character
    if not char then return nil, nil end
    local invchar = game.ReplicatedStorage.Players:FindFirstChild(game.Players.LocalPlayer.Name).Inventory
    if not invchar then return nil, nil end

    local gun = nil
    local gunname = nil
    local guninv = nil

    for _, desc in ipairs(char:GetChildren()) do
        if desc:IsA("Model") and desc:FindFirstChild("ItemRoot") and desc:FindFirstChild("Attachments") then
            gun = desc
            gunname = desc.Name
            guninv = invchar:FindFirstChild(gunname)
            break
        end
    end

    return gunname, gun, guninv
end
function getcurrentammo(gun)
    if not gun then return nil end
    local loadedfold = gun:FindFirstChild("LoadedAmmo", true)
    if not loadedfold then return nil end

    local loadedtable = loadedfold:GetChildren()
    local lastammo = loadedtable[#loadedtable]
    if not lastammo then return nil end
    
    local ammotype = lastammo:GetAttribute("AmmoType")
    if not ammotype then return nil end
    
    return game.ReplicatedStorage.AmmoTypes:FindFirstChild(ammotype)
end
function fetchgui(url)
    local attempts = 0
    while attempts < 5 do
        attempts = attempts + 1
        local success, result = nil, nil
        success, result = pcall(function()
            local str = nil
            task.spawn(function()
                str = tostring(game:HttpGet(url))
            end)
            task.wait(1)
            return str
        end)
        if success and result ~= nil then
            return result
        end
        wait(1)
    end
    return nil
end


-- Store current health values for smooth transitions
local currentHealthValues = {}
local currentArmorValues = {}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")





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
    cachedPlayers[player] = nil
end

local function SetupCharacterMonitoring(player)
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    if not CharacterConnections[player] then
        CharacterConnections[player] = {}
    end
    
    -- Clear existing connections
    DisconnectCharacterConnections(player)
    
    -- Add new connections
    local diedConnection = humanoid.Died:Connect(function()
        DestroyESP(player)
    end)
    
    local ancestryConnection = character.AncestryChanged:Connect(function(_, parent)
        if not parent then
            DestroyESP(player)
        end
    end)
    
    table.insert(CharacterConnections[player], diedConnection)
    table.insert(CharacterConnections[player], ancestryConnection)
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

local function CreateESP(player)
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
        objects.Username.Outline = getgenv().outlineEnabled
        objects.Username.OutlineColor = Color3.new(0, 0, 0)
    end

    if getgenv().studsESPEnabled then
        objects.Distance = Drawing.new("Text")
        objects.Distance.Size = getgenv().distanceTextSize
        objects.Distance.Center = true
        objects.Distance.Color = getgenv().distanceColor
        objects.Distance.Visible = false
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
    if character and character:FindFirstChildOfClass("Humanoid") then
        CreateESP(player)
    end
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

			local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then
            DestroyESP(player)
            continue
        end

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
                        objects.Username.Visible = true
                        objects.Username.Color = getgenv().nameColor
                        objects.Username.Outline = getgenv().outlineEnabled
                    end

                    -- Distance ESP
                    if getgenv().studsESPEnabled and objects.Distance then
                        -- Convert studs to meters (1 stud = 0.28 meters approximately)
                        local distanceInMeters = distance * 0.28
                        local distanceText = math.floor(distanceInMeters) .. "m"
                        objects.Distance.Position = Vector2.new(rootPosition.X, footPosition.Y + 5)
                        objects.Distance.Text = distanceText
                        objects.Distance.Size = getgenv().distanceTextSize
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
    -- Get the player's inventory from ReplicatedStorage
    local inv = game.ReplicatedStorage.Players:FindFirstChild(player.Name)
    if inv and inv:FindFirstChild("Inventory") then
        local inventory = inv.Inventory
        local inventoryItems = {}
        
        -- Get all items from inventory
        for _, item in pairs(inventory:GetChildren()) do
            table.insert(inventoryItems, item.Name)
        end
        
        -- Show inventory items if any exist
        if #inventoryItems > 0 then
            objects.Weapon.Position = Vector2.new(rootPosition.X, footPosition.Y + 20)
            objects.Weapon.Text = table.concat(inventoryItems, ", ") -- Join all items with commas
            objects.Weapon.Size = getgenv().nameTextSize
            objects.Weapon.Visible = true
            objects.Weapon.Color = getgenv().weaponColor
            objects.Weapon.Outline = getgenv().outlineEnabled
        else
            objects.Weapon.Visible = false
        end
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

function isonscreen(object)
    if not object or not object.Position then
        return false
    end
    local _, bool = wcamera:WorldToScreenPoint(object.Position)
    return bool
end

function isvisible(char, object)
    if not localplayer or not localplayer.Character or not localplayer.Character:FindFirstChild("HumanoidRootPart") then
       return false
    end

    if not char or not object or not object.Position then
        return false
    end

    if allvars.aimvischeck == false then
        return true
    end

    local origin = localplayer.Character.HumanoidRootPart.Position + Vector3.new(0, 1.5, 0)
    if allvars.desyncbool and desynctable and desynctable[3] and desynctable[3].Position then
        origin = desynctable[3].Position + Vector3.new(0, 1.5, 0)
    end
    local pos = object.Position
    local dir = pos - origin
    local dist = dir.Magnitude + 2500
    local penetrated = true
    dir = dir.Unit

    local params = RaycastParams.new()
    params.IgnoreWater = true
    params.CollisionGroup = "WeaponRay"
    params.FilterDescendantsInstances = {
        localplayer.Character,
        wcamera,
        globalist11,
        aimignoreparts,
    }

    local ray = workspace:Raycast(origin, dir * dist, params)
    if ray and ray.Instance and char and ray.Instance:IsDescendantOf(char) then
        return true
    elseif ray and ray.Instance and ray.Instance.Name ~= "Terrain" and not ray.Instance:GetAttribute("NoPen") then
        local armorpen4 = 10
        if globalammo then
            armorpen4 = globalammo:GetAttribute("ArmorPen") or 10
        end

        local FunctionLibraryExtension = require(game.ReplicatedStorage.Modules.FunctionLibraryExtension)
        local armorpen1, newpos2 = FunctionLibraryExtension.Penetration(FunctionLibraryExtension, ray.Instance, ray.Position, dir, armorpen4)
        if armorpen1 == nil or newpos2 == nil then
            return false
        end

        local neworigin = ray.Position + dir * 0.01
        local newray = workspace:Raycast(neworigin, dir * (dist - (neworigin - origin).Magnitude), params)
        if newray and newray.Instance and char and newray.Instance:IsDescendantOf(char) then
            return true
        end
    end

    return false
end

function isValidTarget(target)
    if not target then return false end

    local character = nil
    if target:IsA("Model") then
        character = target
    elseif target.Character then
        character = target.Character
    else
        return false
    end

    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not rootPart then return false end
    if humanoid.Health <= 0 then return false end -- Critical dead check

    return true
end

local fpsrequired = require(game.ReplicatedStorage.Modules.FPS)

runs.Heartbeat:Connect(function(delta)
    if not localplayer or not localplayer.Character or 
       not localplayer.Character:FindFirstChild("HumanoidRootPart") or 
       not localplayer.Character:FindFirstChild("Humanoid") then
        return
    end

    if choosetarget then
        choosetarget()
    end

    -- Trigger bot implementation
    if allvars.aimtrigger and aimtarget and getgenv().a1table then
        -- Check if target is in crosshair (within FOV)
        if aimtargetpart then
            local targetPos = aimtargetpart.Position
            local camera = workspace.CurrentCamera
            local screenPos, onScreen = camera:WorldToViewportPoint(targetPos)
            
            if onScreen then
                local center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
                local targetScreenPos = Vector2.new(screenPos.X, screenPos.Y)
                local distance = (center - targetScreenPos).Magnitude
                
                -- Check if target is within trigger FOV (smaller than aim FOV)
                local triggerFOV = allvars.aimfov * 0.5 -- Half of aim FOV
                if distance <= triggerFOV then
                    -- Check visibility if enabled
                    local shouldShoot = true
                    if allvars.aimvischeck then
                        shouldShoot = isvisible(aimtarget, aimtargetpart)
                    end
                    
                    -- Fire weapon if conditions are met
                    if shouldShoot then
                        fpsrequired.action(getgenv().a1table, true)
                        task.wait(0.05) -- Short delay between shots
                        fpsrequired.action(getgenv().a1table, false)
                    end
                end
            end
        end
    end
end)

function choosetarget()
    local cent = Vector2.new(wcamera.ViewportSize.X / 2, wcamera.ViewportSize.Y / 2)
    local cdist = math.huge
    local ctar = nil
    local cpart = nil
    local restar = nil
    local predist = math.huge

    local ammodistance = 999999999
    if allvars.aimdistcheck and globalammo then
        ammodistance = globalammo:GetAttribute("MuzzleVelocity")
    end

    local bparts = {
        "Head",
        "HeadTopHitBox",
        "FaceHitBox",
        "UpperTorso",
        "LowerTorso",
        "LeftUpperArm",
        "RightUpperArm",
        "LeftLowerArm",
        "RightLowerArm",
        "LeftHand",
        "RightHand",
        "LeftUpperLeg",
        "RightUpperLeg",
        "LeftLowerLeg",
        "RightLowerLeg",
        "LeftFoot",
        "RightFoot"
    }

    local function chooseTpart(charact)
        if allvars.aimpart == "Head" then
            return charact:FindFirstChild("Head")
        elseif allvars.aimpart == "HeadTop" then
            return charact:FindFirstChild("HeadTopHitBox")
        elseif allvars.aimpart == "Face" then
            return charact:FindFirstChild("FaceHitBox")
        elseif allvars.aimpart == "Torso" then
            return charact:FindFirstChild("UpperTorso")
        elseif allvars.aimpart == "Scripted" then
            local head = charact:FindFirstChild("Head")
            local upperTorso = charact:FindFirstChild("UpperTorso")
            if not isvisible(charact, head) then
                return upperTorso
            else
                return head
            end
        elseif allvars.aimpart == "Random" then
            return charact:FindFirstChild(bparts[math.random(1, #bparts)])
        end
    end

    if allvars.aimbots then --priority 2 (bots)
        for _, botfold in pairs(workspace.AiZones:GetChildren()) do
            for _, bot in pairs(botfold:GetChildren()) do
                if bot:IsA("Model") and bot:FindFirstChild("Humanoid") and bot.Humanoid.Health > 0 then
                    if allvars.friendlistbots then
                        if allvars.friendlistmode == "Blacklist" then 
                            if table.find(allvars.aimFRIENDLIST, bot.Name) ~= nil then
                                continue
                            end
                        elseif allvars.friendlistmode == "Whitelist" then 
                            if table.find(allvars.aimFRIENDLIST, bot.Name) == nil then
                                continue
                            end
                        end
                    end

                    local potroot = chooseTpart(bot)
                    if potroot and localplayer.Character and localplayer.Character.PrimaryPart then -- Fixed: Added PrimaryPart check
                        local spoint = wcamera:WorldToViewportPoint(potroot.Position)
                        local optpoint = Vector2.new(spoint.X, spoint.Y)
                        local dist = (optpoint - cent).Magnitude
                        
                        local betweendist = (localplayer.Character.PrimaryPart.Position - potroot.Position).Magnitude * 0.3336
                        local betweendistSTUDS = (localplayer.Character.PrimaryPart.Position - potroot.Position).Magnitude
                        if dist <= aimfovcircle.Radius and dist < cdist and betweendist < allvars.aimdistance and betweendistSTUDS < ammodistance and isonscreen(potroot) then
                            local canvis = isvisible(bot, potroot)
                            if canvis then
                                cdist = dist
                                ctar = bot
                                cpart = potroot
                            end
                            if dist < predist then
                                predist = dist
                                restar = bot
                            end
                        end
                    end
                end
            end
        end
    end

    for _, pottar in pairs(game.Players:GetPlayers()) do --priority 1 (players)
        if pottar ~= localplayer and pottar.Character and localplayer.Character and localplayer.Character.PrimaryPart ~= nil then -- Fixed: Added checks
            if allvars.friendlistmode == "Blacklist" then 
                if table.find(allvars.aimFRIENDLIST, pottar.Name) ~= nil then
                    continue
                end
            elseif allvars.friendlistmode == "Whitelist" then 
                if table.find(allvars.aimFRIENDLIST, pottar.Name) == nil then
                    continue
                end
            end

            local potroot = chooseTpart(pottar.Character)
            if potroot then
                local spoint = wcamera:WorldToViewportPoint(potroot.Position)
                local optpoint = Vector2.new(spoint.X, spoint.Y)
                local dist = (optpoint - cent).Magnitude
                
                local betweendist = (localplayer.Character.PrimaryPart.Position - potroot.Position).Magnitude * 0.3336
                local betweendistSTUDS = (localplayer.Character.PrimaryPart.Position - potroot.Position).Magnitude
                if dist <= aimfovcircle.Radius and dist < cdist and betweendist < allvars.aimdistance and betweendistSTUDS < ammodistance and isonscreen(potroot) then
                    local canvis = isvisible(pottar.Character, potroot)
                    if canvis then
                        cdist = dist
                        ctar = pottar
                        cpart = potroot
                    end
                    if dist < predist then
                        predist = dist
                        restar = pottar
                    end
                end
            end
        end
    end

    if ctar == nil then
        aimtarget = nil
        aimtargetpart = nil
        if restar then
            aimpretarget = restar
        else
            aimpretarget = nil
        end
    else
        aimtarget = ctar
        aimtargetpart = cpart
        aimpretarget = restar
    end
end

-- Snap Line Variables
local snapLineGui = nil
local snapLine = nil
local snapLineConnection = nil

-- Initialize Snap Line GUI
function initializeSnapLine()
    if snapLineGui then return end

    snapLineGui = Instance.new("ScreenGui")
    snapLineGui.Name = "SnapLineGUI"
    snapLineGui.ResetOnSpawn = false
    snapLineGui.IgnoreGuiInset = true
    snapLineGui.Parent = game:GetService("CoreGui")

    snapLine = Instance.new("Frame")
    snapLine.Name = "SnapLine"
    snapLine.BackgroundColor3 = allvars.snaplinecolor or Color3.new(1, 0, 0)
    snapLine.BorderSizePixel = 0
    snapLine.Size = UDim2.new(0, 2, 0, 0)
    snapLine.Position = UDim2.new(0, 0, 0, 0)
    snapLine.Visible = false
    snapLine.Parent = snapLineGui
end

-- Update Snap Line Function
function updateSnapLine()
    if not allvars.snaplinebool or not snapLine or not aimtarget or not aimtargetpart then
        if snapLine then
            snapLine.Visible = false
        end
        return
    end

    local camera = workspace.CurrentCamera
    if not camera then return end

    -- Get mouse position
    local mousePos = UserInputService:GetMouseLocation()
    
    -- Get target position on screen
    local targetPosition = aimtargetpart.Position
    local screenPoint, onScreen = camera:WorldToViewportPoint(targetPosition)

    if not onScreen then
        snapLine.Visible = false
        return
    end

    -- Calculate line properties from mouse to target
    local startX = mousePos.X
    local startY = mousePos.Y
    local endX = screenPoint.X
    local endY = screenPoint.Y
    
    -- Calculate line length and angle
    local deltaX = endX - startX
    local deltaY = endY - startY
    local distance = math.sqrt(deltaX^2 + deltaY^2)
    
    if distance < 5 then -- Too close to target
        snapLine.Visible = false
        return
    end

    -- Calculate line angle
    local angle = math.atan2(deltaY, deltaX)
    
    -- Position line from mouse to target
    snapLine.Size = UDim2.new(0, distance, 0, allvars.snaplinewidth or 2)
    snapLine.Position = UDim2.new(0, startX, 0, startY)
    snapLine.AnchorPoint = Vector2.new(0, 0.5)
    snapLine.Rotation = math.deg(angle)
    snapLine.Visible = true

    -- Update line color based on target health
    local targetHumanoid = nil
    if aimtarget:IsA("Model") and aimtarget:FindFirstChild("Humanoid") then
        targetHumanoid = aimtarget.Humanoid
    elseif aimtarget.Character and aimtarget.Character:FindFirstChild("Humanoid") then
        targetHumanoid = aimtarget.Character.Humanoid
    end

    if targetHumanoid then
        local healthPercent = targetHumanoid.Health / targetHumanoid.MaxHealth
        if healthPercent > 0.7 then
            snapLine.BackgroundColor3 = allvars.snaplinecolor or Color3.new(0, 1, 0) -- Green for healthy
        elseif healthPercent > 0.3 then
            snapLine.BackgroundColor3 = Color3.new(1, 1, 0) -- Yellow for injured
        else
            snapLine.BackgroundColor3 = Color3.new(1, 0, 0) -- Red for low health
        end
    else
        snapLine.BackgroundColor3 = allvars.snaplinecolor or Color3.new(1, 0, 0)
    end
end

-- Start Snap Line Updates
function startSnapLine()
    if snapLineConnection then return end

    initializeSnapLine()

    snapLineConnection = game:GetService("RunService").RenderStepped:Connect(function()
        updateSnapLine()
    end)
end

-- Stop Snap Line Updates
function stopSnapLine()
    if snapLineConnection then
        snapLineConnection:Disconnect()
        snapLineConnection = nil
    end

    if snapLine then
        snapLine.Visible = false
    end
end

function runhitmark(v140)
    if not allvars.hitmarkbool then return end

    local success, err = pcall(function()
        local hitpart = Instance.new("Part")
        hitpart.Name = "HitMarker"
        hitpart.Transparency = 1
        hitpart.CanCollide = false
        hitpart.CanQuery = false
        hitpart.CanTouch = false
        hitpart.Size = Vector3.new(0.1, 0.1, 0.1)
        hitpart.Anchored = true
        hitpart.Position = v140
        hitpart.Parent = workspace
        
        local hit = Instance.new("BillboardGui")
        hit.Name = "HitMarkerGUI"
        hit.AlwaysOnTop = true
        hit.Size = UDim2.new(0, 50, 0, 50)
        hit.StudsOffset = Vector3.new(0, 0, 0)
        hit.Adornee = hitpart
        hit.Parent = hitpart
        
        local hit_img = Instance.new("ImageLabel")
        hit_img.Name = "HitImage"
        hit_img.Image = "rbxassetid://13298929624"
        hit_img.BackgroundTransparency = 1
        hit_img.Size = UDim2.new(0, 150, 0, 150)
        hit_img.Position = UDim2.new(0.5, -75, 0.5, -75)
        hit_img.Visible = true
        hit_img.ImageColor3 = allvars.hitmarkcolor or Color3.new(1, 1, 1)
        hit_img.ImageTransparency = 0
        hit_img.Rotation = 0
        hit_img.Parent = hit
        
        local fadeTime = 1
        
        local tweenInfo = TweenInfo.new(fadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        local rotationTween = TweenInfo.new(fadeTime, Enum.EasingStyle.Linear)
        
        local fadeTween = game:GetService("TweenService"):Create(hit_img, tweenInfo, {
            ImageTransparency = 1
        })
        
        local rotTween = game:GetService("TweenService"):Create(hit_img, rotationTween, {
            Rotation = 360
        })
        
        fadeTween:Play()
        rotTween:Play()
        
        fadeTween.Completed:Connect(function()
            if hitpart and hitpart.Parent then
                hitpart:Destroy()
            end
        end)
    end)

    if not success then
        warn("Error in runhitmark: " .. tostring(err))
    end
end

local function playHitSound(hitType)
    if not allvars.hitsoundbool then return end
    
    local hitsoundlib = {
        ["Ding"] = "rbxassetid://131961136",
        ["Pop"] = "rbxassetid://198598793",
        ["Click"] = "rbxassetid://421058951"
    }
    
    hitType = hitType or ""
    local soundKey = allvars["hitsound" .. hitType] or "Ding"
    local soundId = hitsoundlib[soundKey] or hitsoundlib["Ding"]
    if not soundId then return end
    
    local success, err = pcall(function()
        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = math.min(math.max(allvars.hitsoundvolume or 0.5, 0), 1)
        sound.Parent = workspace
        sound:Play()
        
        game:GetService("Debris"):AddItem(sound, 3)
    end)
    
    if not success then
        warn("Hit sound error: " .. tostring(err))
    end
end

local function createAttachmentPart(position)
    local part = Instance.new("Part")
    part.Name = "TracerAttachment"
    part.Transparency = 1
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Size = Vector3.new(0.1, 0.1, 0.1)
    part.Anchored = true
    part.Position = position
    part.Parent = workspace
    
    local attachment = Instance.new("Attachment")
    attachment.Parent = part
    
    return part, attachment
end

function runBeamTracer(startPos, endPos)
    if not allvars or not allvars.tracbool then return end
    if not startPos or not endPos then return end

    local success, err = pcall(function()
        local startPart, startAttachment = createAttachmentPart(startPos)
        local endPart, endAttachment = createAttachmentPart(endPos)
        
        local beam = Instance.new("Beam")
        beam.Color = ColorSequence.new(allvars.tracercolor3 or Color3.new(1, 1, 0))
        beam.Transparency = NumberSequence.new(allvars.tracertrans or 0.3)
        beam.Width0 = allvars.tracerwidth or 0.2
        beam.Width1 = allvars.tracerwidth or 0.2
        beam.Texture = getgenv().beamtexture or getgenv().BeamTexture[2] or "rbxassetid://446111271"
        beam.Attachment0 = startAttachment
        beam.Attachment1 = endAttachment
        beam.FaceCamera = true
        beam.Parent = startPart
        
        local fadeTime = math.max(allvars.tracerfade or 0.3, 0.1)
        local startTime = tick()
        local initialTrans = allvars.tracertrans or 0.3
        local initialWidth = allvars.tracerwidth or 0.2
        
        local connection
        connection = game:GetService("RunService").Heartbeat:Connect(function()
            local elapsed = tick() - startTime
            local progress = math.min(elapsed / fadeTime, 1)
            
            local easedProgress = 1 - ((1 - progress) * (1 - progress))
            
            local currentTrans = initialTrans + (1 - initialTrans) * easedProgress
            local currentWidth = initialWidth * (1 - easedProgress)
            
            beam.Transparency = NumberSequence.new(math.min(math.max(currentTrans, 0), 1))
            beam.Width0 = math.max(currentWidth, 0)
            beam.Width1 = math.max(currentWidth, 0)
            
            if progress >= 1 then
                connection:Disconnect()
                if startPart and startPart.Parent then startPart:Destroy() end
                if endPart and endPart.Parent then endPart:Destroy() end
            end
        end)
        
        game:GetService("Debris"):AddItem(startPart, fadeTime + 1)
        game:GetService("Debris"):AddItem(endPart, fadeTime + 1)
    end)

    if not success then
        warn("Beam tracer error: " .. tostring(err))
    end
end

function runBeamTracerWidthOnly(startPos, endPos)
    if not allvars or not allvars.tracbool then return end
    if not startPos or not endPos then return end

    local success, err = pcall(function()
        local startPart, startAttachment = createAttachmentPart(startPos)
        local endPart, endAttachment = createAttachmentPart(endPos)
        
        local beam = Instance.new("Beam")
        beam.Color = ColorSequence.new(allvars.tracercolor3 or Color3.new(1, 1, 0))
        beam.Transparency = NumberSequence.new(allvars.tracertrans or 0.3)
        beam.Width0 = allvars.tracerwidth or 0.2
        beam.Width1 = allvars.tracerwidth or 0.2
        beam.Texture = getgenv().beamtexture or getgenv().BeamTexture[2] or "rbxassetid://446111271"
        beam.Attachment0 = startAttachment
        beam.Attachment1 = endAttachment
        beam.FaceCamera = true
        beam.Parent = startPart
        
        local fadeTime = math.max(allvars.tracerfade or 0.3, 0.1)
        local tweenInfo = TweenInfo.new(fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        
        local fadeTween = game:GetService("TweenService"):Create(beam, tweenInfo, {
            Width0 = 0,
            Width1 = 0
        })
        
        fadeTween:Play()
        
        fadeTween.Completed:Connect(function()
            if startPart and startPart.Parent then startPart:Destroy() end
            if endPart and endPart.Parent then endPart:Destroy() end
        end)
        
        game:GetService("Debris"):AddItem(startPart, fadeTime + 1)
        game:GetService("Debris"):AddItem(endPart, fadeTime + 1)
    end)

    if not success then
        warn("Width-only beam tracer error: " .. tostring(err))
    end
end

function runBeamTracerSimplest(startPos, endPos)
    if not allvars or not allvars.tracbool then return end
    if not startPos or not endPos then return end

    local success, err = pcall(function()
        local startPart, startAttachment = createAttachmentPart(startPos)
        local endPart, endAttachment = createAttachmentPart(endPos)
        
        local beam = Instance.new("Beam")
        beam.Color = ColorSequence.new(allvars.tracercolor3 or Color3.new(1, 1, 0))
        beam.Transparency = NumberSequence.new(allvars.tracertrans or 0.3)
        beam.Width0 = allvars.tracerwidth or 0.2
        beam.Width1 = allvars.tracerwidth or 0.2
        beam.Texture = getgenv().beamtexture or getgenv().BeamTexture[2] or "rbxassetid://446111271"
        beam.Attachment0 = startAttachment
        beam.Attachment1 = endAttachment
        beam.FaceCamera = true
        beam.Parent = startPart
        
        local fadeTime = math.max(allvars.tracerfade or 0.3, 0.1)
        game:GetService("Debris"):AddItem(startPart, fadeTime)
        game:GetService("Debris"):AddItem(endPart, fadeTime)
    end)

    if not success then
        warn("Simple beam tracer error: " .. tostring(err))
    end
end

function runCylinderTracer(startPos, endPos)
    if not allvars or not allvars.tracbool then return end
    if not startPos or not endPos then return end
    
    local success, err = pcall(function()
        local distance = (startPos - endPos).Magnitude
        if distance <= 0 then return end
        
        local tracer = Instance.new("Part")
        tracer.Name = "CylinderTracer"
        tracer.Shape = Enum.PartType.Cylinder
        tracer.Anchored = true
        tracer.CanCollide = false
        tracer.CanQuery = false
        tracer.CanTouch = false
        tracer.Material = Enum.Material.Neon
        tracer.Color = allvars.tracercolor3 or Color3.new(1, 1, 0)
        tracer.Transparency = allvars.tracertrans or 0.3
        
        local width = allvars.tracerwidth or 0.2
        tracer.Size = Vector3.new(distance, width, width)
        tracer.CFrame = CFrame.lookAt(startPos + (endPos - startPos) * 0.5, endPos)
        tracer.Parent = workspace
        
        local fadeTime = math.max(allvars.tracerfade or 0.3, 0.1)
        local startTime = tick()
        local initialTrans = allvars.tracertrans or 0.3
        local initialWidth = width
        
        local connection
        connection = game:GetService("RunService").Heartbeat:Connect(function()
            local elapsed = tick() - startTime
            local progress = math.min(elapsed / fadeTime, 1)
            
            if tracer and tracer.Parent then
                local easedProgress = 1 - ((1 - progress) * (1 - progress))
                tracer.Transparency = initialTrans + (1 - initialTrans) * easedProgress
                local currentWidth = initialWidth * (1 - easedProgress)
                tracer.Size = Vector3.new(distance, currentWidth, currentWidth)
            end
            
            if progress >= 1 then
                connection:Disconnect()
                if tracer and tracer.Parent then tracer:Destroy() end
            end
        end)
        
        game:GetService("Debris"):AddItem(tracer, fadeTime + 1)
    end)
    
    if not success then
        warn("Cylinder tracer error: " .. tostring(err))
    end
end

local function CreateTracer(startPos, endPos)
    if not allvars.tracbool then return end
    if not startPos or not endPos then 
        warn("CreateTracer: Invalid positions provided")
        return 
    end
    
    local tracerType = allvars.tracertype or "beam_performance"
    
    if tracerType == "beam_performance" then
        runBeamTracer(startPos, endPos)
    elseif tracerType == "beam_width" then
        runBeamTracerWidthOnly(startPos, endPos)
    elseif tracerType == "beam_simple" then
        runBeamTracerSimplest(startPos, endPos)
    elseif tracerType == "cylinder" then
        runCylinderTracer(startPos, endPos)
    else
        warn("Unknown tracer type: " .. tostring(tracerType))
        runBeamTracer(startPos, endPos)
    end
end

local aimogfunc = require(game.ReplicatedStorage.Modules.FPS.Bullet).CreateBullet
local aimmodfunc

aimmodfunc = function(prikol, p49, p50, p_u_51, aimpart, _, p52, p53, p54)
    local v_u_6 = game.ReplicatedStorage.Remotes.VisualProjectile
    local v_u_108 = 1
    local v_u_106 = 0
    local v_u_7 = game.ReplicatedStorage.Remotes.FireProjectile
    local target = aimtarget
    local target_part
    local v_u_4 = require(game.ReplicatedStorage.Modules:WaitForChild("FunctionLibraryExtension"))
    local v_u_103
    local v_u_114
    local v_u_16 = game.ReplicatedStorage.Players:FindFirstChild(localplayer.Name)
    local v_u_64 = v_u_16.Status.GameplayVariables:GetAttribute("EquipId")
    local v_u_13 = game.ReplicatedStorage:WaitForChild("VFX")
    local v_u_2 = require(game.ReplicatedStorage.Modules:WaitForChild("VFX"))
    local v3 = require(game.ReplicatedStorage.Modules:WaitForChild("UniversalTables"))
    local v_u_5 = game.ReplicatedStorage.Remotes.ProjectileInflict
    local v_u_10 = game:GetService("ReplicatedStorage")
    local v_u_12 = v_u_10:WaitForChild("RangedWeapons")
    local v_u_17 = game.ReplicatedStorage.Temp
    local v_u_56 = localplayer.Character
    local v135 = 500000
    local v_u_18 = v3.ReturnTable("GlobalIgnoreListProjectile")
    local v_u_115 = localplayer.Character.HumanoidRootPart.Position + Vector3.new(0, 1.5, 0)
    if allvars.desyncbool and desynctable[3] then
        v_u_115 = desynctable[3].Position + Vector3.new(0, 1.5, 0)
    end
    local hittick = tick()
    local v65 = v_u_10.AmmoTypes:FindFirstChild(p52)
    local v_u_74 = v65:GetAttribute("Pellets")
    local v60 = p50.ItemRoot
    local v61 = p49.ItemProperties
    local v62 = v_u_12:FindFirstChild(p49.Name)
    local v63 = v61:FindFirstChild("SpecialProperties")
    local v_u_66 = v63 and v63:GetAttribute("TracerColor") or v62:GetAttribute("ProjectileColor")
    local itemprop = require(v_u_16.Inventory:FindFirstChild(p49.Name).SettingsModule)
    local bulletspeed = 999999999
    local armorpen4 = v65:GetAttribute("ArmorPen")
    local tracerendpos = Vector3.zero
    local v79 = {
        ["x"] = {
            ["Value"] = 0
        },
        ["y"] = {
            ["Value"] = 0
        }
    }

    if v_u_56:FindFirstChild(p49.Name) then
        local v83 = 0.001 
        local v82 = 0.001
        local v81 = v61.Tool:GetAttribute("MuzzleDevice") or "Default"
        v_u_108 = math.random(-100000, 100000)
        
        if v61.Tool:GetAttribute("MuzzleDevice") or "Default" == "Suppressor" then
            if tick() - p53 < 0.8 then
                v_u_4:PlaySoundV2(v60.Sounds.FireSoundSupressed, v60.Sounds.FireSoundSupressed.TimeLength, v_u_17)
            else
                v_u_4:PlaySoundV2(v60.Sounds.FireSoundSupressed, v60.Sounds.FireSoundSupressed.TimeLength, v_u_17)
            end
        elseif tick() - p53 < 0.8 then
            v_u_4:PlaySoundV2(v60.Sounds.FireSound, v60.Sounds.FireSound.TimeLength, v_u_17)
        else
            v_u_4:PlaySoundV2(v60.Sounds.FireSound, v60.Sounds.FireSound.TimeLength, v_u_17)
        end
        
        local v_u_59
        if p_u_51.Item.Attachments:FindFirstChild("Front") then
            v_u_59 = p_u_51.Item.Attachments.Front:GetChildren()[1].Barrel
        else
            v_u_59 = p_u_51.Item.Barrel
        end

        if target ~= nil and aimtargetpart ~= nil then
            target_part = aimtargetpart
            v_u_103 = CFrame.new(v_u_115, target_part.Position).LookVector
            v_u_114 = v_u_103
        else
            target_part = aimpart
            v_u_103 = CFrame.new(v_u_115, localplayer:GetMouse().Hit.Position).LookVector
            v_u_114 = v_u_103
        end

        local function v185()
            local v_u_110 = RaycastParams.new()
            v_u_110.FilterType = Enum.RaycastFilterType.Exclude
            local v_u_111 = { v_u_56, p_u_51, v_u_18, aimignoreparts}
            v_u_110.FilterDescendantsInstances = v_u_111
            v_u_110.CollisionGroup = "WeaponRay"
            v_u_110.IgnoreWater = true

            v_u_106 = v_u_106 + 1

            local usethisvec = v_u_114

            if v_u_106 == 1 then
                task.spawn(function()
                    for i=1, allvars.multitaps or 1 do
                        if not v_u_7:InvokeServer(usethisvec, v_u_108, 0) then 
                            game.ReplicatedStorage.Modules.FPS.Binds.AdjustBullets:Fire(v_u_64, 1)
                        end
                    end
                end)
            elseif 1 < v_u_106 then
                for i=1, allvars.multitaps or 1 do
                    v_u_6:FireServer(usethisvec, v_u_108)
                end
            end

            local v_u_131 = nil
            local v_u_132 = 0
            local v_u_133 = 0

            local penetrated = false

            local function v184(p134)
                v_u_132 = v_u_132 + p134
                if true then
                    v_u_133 = v_u_133 + v_u_132
                    local v136 = workspace:Raycast(v_u_115, v_u_114 * v135, v_u_110)
                    local v137 = nil
                    local v138 = nil
                    local v139 = nil
                    local v140
                    if v136 then
                        v137 = v136.Instance
                        v140 = v136.Position
                        v138 = v136.Normal
                        v139 = v136.Material
                    else
                        v140 = v_u_115 + v_u_114 * v135
                    end

                    if v137 == nil then
                        if v_u_131 then v_u_131:Disconnect() end
                        return
                    end

                    tracerendpos = v140

                    local v171 = v_u_4:FindDeepAncestor(v137, "Model")
                    if v171 and v171:FindFirstChild("Humanoid") then
                        local ran = math.random(1, 100)
                        local ranbool = ran <= (allvars.aimchance or 100)
                        if ranbool then
                            local v175 = v137.CFrame:ToObjectSpace(CFrame.new(v140))

                            if target_part and penetrated == false then
                                v_u_5:FireServer(target_part, v175, v_u_108, hittick)
                            else
                                v_u_5:FireServer(v137, v175, v_u_108, hittick)
                            end
                        else
                            local v175 = v137.CFrame:ToObjectSpace(CFrame.new(v140))
                            v_u_5:FireServer(aimpart, v175, v_u_108, hittick)
                        end

                        task.spawn(function()
                            runhitmark(v140)
                        end)
                    elseif v137.Name == "Terrain" then
                        local v175 = v137.CFrame:ToObjectSpace(CFrame.new(v140))
                        v_u_5:FireServer(v137, v175, v_u_108, hittick)

                        v_u_2.Impact(v137, v140, v138, v139, v_u_114, "Ranged", true)

                        task.spawn(function()
                            runhitmark(v140)
                        end)
                    else
                        v_u_2.Impact(v137, v140, v138, v139, v_u_114, "Ranged", true)

                        task.spawn(function()
                            runhitmark(v140)
                        end)

                        local arg1, arg2, arg3 = v_u_4.Penetration(v_u_4, v137, v140, v_u_114, armorpen4)
                        if arg1 == nil or arg2 == nil then
                            local v175 = v137.CFrame:ToObjectSpace(CFrame.new(v140))
                            v_u_5:FireServer(v137, v175, v_u_108, hittick)
                            if v_u_131 then v_u_131:Disconnect() end
                            return
                        end

                        armorpen4 = arg1
                        if armorpen4 > 0 then
                            v_u_115 = arg2
                            v_u_2.Impact(unpack(arg3))
                            penetrated = true
                            return
                        end

                        if v_u_131 then v_u_131:Disconnect() end
                        return
                    end
                end

                if v_u_131 then v_u_131:Disconnect() end
                return
            end
            v_u_131 = game:GetService("RunService").RenderStepped:Connect(v184)
            return
        end

        if v_u_74 == nil then
            task.spawn(v185)
        else
            for i = 1, v_u_74 do
                task.spawn(v185)
            end
        end

        if allvars.tracbool then
            task.spawn(function()
                task.wait(0.05)
                if tracerendpos == Vector3.zero then return end
                CreateTracer(wcamera.ViewModel.Item.ItemRoot.Position, tracerendpos)
            end)
        end
        return v83, v82, v81, v79
    end
end

function setSnapLineSettings(settings)
    allvars = allvars or {}
    allvars.snaplinebool = settings.enabled or false
    allvars.snaplinecolor = settings.color or Color3.new(1, 0, 0)
    allvars.snaplinewidth = settings.width or 2

    if snapLine then
        snapLine.BackgroundColor3 = allvars.snaplinecolor
    end
end

function cleanupSnapLine()
    stopSnapLine()

    if snapLineGui then
        snapLineGui:Destroy()
        snapLineGui = nil
        snapLine = nil
    end
end

function toggleSnapLine()
    allvars.snaplinebool = not allvars.snaplinebool

    if allvars.snaplinebool then
        startSnapLine()
    else
        stopSnapLine()
    end
end

local thirdpshow = true

require(game.Players.LocalPlayer.PlayerScripts.PlayerModule.CameraModule.TransparencyController).Update = function(a1, a2)
    local v14_3_ = workspace
    local v14_2_ = v14_3_.CurrentCamera

    local setto = 0
    if allvars.camthirdp == false or thirdpshow == false then
        setto = 1
    end

    if v14_2_ then
        v14_3_ = a1.enabled
        if v14_3_ then
            local v14_6_ = v14_2_.Focus
            local v14_5_ = v14_6_.p
            local v14_7_ = v14_2_.CoordinateFrame
            v14_6_ = v14_7_.p
            local v14_4_ = v14_5_ - v14_6_
            v14_3_ = v14_4_.magnitude
            v14_5_ = 2
            v14_4_ = 0
            v14_5_ = 0.500000
            if v14_4_ < v14_5_ then
                v14_4_ = 0
            end
            v14_5_ = a1.lastTransparency
            if v14_5_ then
                v14_5_ = 1
                if v14_4_ < v14_5_ then
                    v14_5_ = a1.lastTransparency
                    v14_6_ = 0.950000
                    if v14_5_ < v14_6_ then
                        v14_6_ = a1.lastTransparency
                        v14_5_ = v14_4_ - v14_6_
                        v14_7_ = 2.800000
                        v14_6_ = v14_7_ * a2
                        local v14_9_ = -v14_6_
                        local v14_8_ = v14_5_
                        local v14_10_ = v14_6_
                        local clamp = math.clamp or function(val, min, max)
                            return math.min(math.max(val, min), max)
                        end
                        v14_7_ = clamp(v14_8_, v14_9_, v14_10_)
                        v14_5_ = v14_7_
                        v14_7_ = a1.lastTransparency
                        v14_4_ = v14_7_ + v14_5_
                    else
                        v14_5_ = true
                        a1.transparencyDirty = v14_5_
                    end
                else
                    v14_5_ = true
                    a1.transparencyDirty = v14_5_
                end
            else
                v14_5_ = true
                a1.transparencyDirty = v14_5_
            end
            
            v14_4_ = setto
            v14_5_ = a1.transparencyDirty
            if not v14_5_ then
                v14_5_ = a1.lastTransparency
                if v14_5_ ~= v14_4_ then
                    for v14_8_, v14_9_ in pairs(a1.cachedParts) do
                        v14_8_.LocalTransparencyModifier = setto
                    end
                    a1.transparencyDirty = false
                    a1.lastTransparency = setto
                end
            end
            
            for v14_8_, v14_9_ in pairs(a1.cachedParts) do
                v14_8_.LocalTransparencyModifier = setto
            end
            a1.transparencyDirty = false
            a1.lastTransparency = setto
        end
    end
end

-- Enhanced target distance calculation for snap line color coding
function getTargetDistance()
    if not aimtarget or not aimtargetpart or not localplayer.Character or not localplayer.Character:FindFirstChild("HumanoidRootPart") then
        return nil
    end

    local distance = (aimtargetpart.Position - localplayer.Character.HumanoidRootPart.Position).Magnitude
    return distance
end

-- Function to update snap line color based on distance
function updateSnapLineColorByDistance()
    if not snapLine then return end

    local distance = getTargetDistance()
    if not distance then return end

    -- Color coding based on distance
    if distance < 50 then
        snapLine.BackgroundColor3 = Color3.new(1, 0, 0) -- Red for close
    elseif distance < 100 then
        snapLine.BackgroundColor3 = Color3.new(1, 1, 0) -- Yellow for medium
    elseif distance < 200 then
        snapLine.BackgroundColor3 = Color3.new(0, 1, 0) -- Green for far
    else
        snapLine.BackgroundColor3 = Color3.new(0, 0, 1) -- Blue for very far
    end
end

-- Function to add target info display near snap line
function createTargetInfoDisplay()
    if not snapLineGui or not aimtarget then return end

    local existingInfo = snapLineGui:FindFirstChild("TargetInfo")
    if existingInfo then existingInfo:Destroy() end

    local targetInfo = Instance.new("TextLabel")
    targetInfo.Name = "TargetInfo"
    targetInfo.Size = UDim2.new(0, 200, 0, 50)
    targetInfo.Position = UDim2.new(0.5, -100, 0, 10)
    targetInfo.BackgroundTransparency = 0.7
    targetInfo.BackgroundColor3 = Color3.new(0, 0, 0)
    targetInfo.TextColor3 = Color3.new(1, 1, 1)
    targetInfo.TextScaled = true
    targetInfo.Font = Enum.Font.SourceSansBold
    targetInfo.Parent = snapLineGui

    -- Update target info
    local targetName = "Unknown"
    local targetHealth = "Unknown"
    local targetDistance = "Unknown"

    if aimtarget:IsA("Model") then
        targetName = aimtarget.Name
        if aimtarget:FindFirstChild("Humanoid") then
            targetHealth = math.floor(aimtarget.Humanoid.Health) .. "/" .. math.floor(aimtarget.Humanoid.MaxHealth)
        end
    elseif aimtarget.Name then
        targetName = aimtarget.Name
        if aimtarget.Character and aimtarget.Character:FindFirstChild("Humanoid") then
            targetHealth = math.floor(aimtarget.Character.Humanoid.Health) .. "/" .. math.floor(aimtarget.Character.Humanoid.MaxHealth)
        end
    end

    local distance = getTargetDistance()
    if distance then
        targetDistance = math.floor(distance) .. " studs"
    end

    targetInfo.Text = string.format("Target: %s\nHealth: %s\nDistance: %s", targetName, targetHealth, targetDistance)
end

-- Function to remove target info display
function removeTargetInfoDisplay()
    if snapLineGui then
        local existingInfo = snapLineGui:FindFirstChild("TargetInfo")
        if existingInfo then existingInfo:Destroy() end
    end
end

-- Enhanced update function that includes target info
local originalUpdateSnapLine = updateSnapLine
updateSnapLine = function()
    originalUpdateSnapLine()

    if allvars.snaplinebool and allvars.showtargetinfo and aimtarget and aimtargetpart then
        createTargetInfoDisplay()
        updateSnapLineColorByDistance()
    else
        removeTargetInfoDisplay()
    end
end

-- Fixed FOV Circle variables
local fovCircle = nil
local fovRadius = 100
local showFovCircle = false
local camLockEnabled = false
local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local aimPart = "Head"
local knockCheckEnabled = false

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

-- Store original function before modification
local instrelOGfunc = require(game.ReplicatedStorage.Modules.FPS).reload

local function instrelMODfunc()
    -- Empty function
end

-- Fixed equipment animation
workspace.Camera.ChildAdded:Connect(function(ch)
    if allvars.instaequip and ch:IsA("Model") then
        task.wait(0.015)
        local humanoid = ch:FindFirstChild("Humanoid")
        if humanoid and humanoid.Animator then
            for i,v in pairs(humanoid.Animator:GetPlayingAnimationTracks()) do
                if v.Animation and v.Animation.Name == "Equip" then
                    v:AdjustSpeed(15)
                    v.TimePosition = v.Length - 0.01
                end
            end
        end
    end
end)

local function applyGunMods(gun)
    if not gun:FindFirstChild("SettingsModule") then
        return
    end

    local sett = require(gun.SettingsModule)

    -- Apply rapid fire if enabled
    if allvars.rapidfire then
        sett.FireRate = 0.01  -- Much faster fire rate
        sett.SemiAuto = false  -- Ensure it's not semi-auto locked
    else
        -- Reset to reasonable defaults (you may need to adjust these)
        sett.FireRate = 0.1
    end

    -- Apply no recoil if enabled
    if allvars.norecoil then
        sett.MaxRecoil = 0
        sett.RecoilReductionMax = 0
        sett.RecoilTValueMax = 0
        sett.MaximumKickBack = 0
        -- Additional recoil settings for complete elimination
        sett.RecoilMax = 0
        sett.RecoilMin = 0
        sett.RecoilPattern = {}
        sett.CameraRecoil = 0
        sett.Spread = 0
        sett.SpreadReduction = 0
    else
        -- Reset to defaults
        sett.MaximumKickBack = 1
        sett.MaxRecoil = 4
        sett.RecoilReductionMax = 1
        sett.RecoilTValueMax = 5
        sett.Spread = 1
        sett.SpreadReduction = 1
    end

    -- Apply fast aim if enabled
    if allvars.fastaim then
        sett.AimInSpeed = 0.01  -- Almost instant
        sett.AimOutSpeed = 0.01  -- Almost instant
    else
        sett.AimInSpeed = 0.4
        sett.AimOutSpeed = 0.4
    end

    -- Apply no sway if enabled
    if allvars.noswaybool then
        sett.weaponOffset = CFrame.new(0, 0, 0)
        sett.sprintOffset = Vector3.new(0, 0, 0)
        sett.swayMult = 0
        sett.IdleSwayModifier = 0
        sett.WalkSwayModifer = 0
        sett.SprintSwayModifer = 0
    else
        sett.swayMult = 1
        sett.IdleSwayModifier = 8
        sett.WalkSwayModifer = 1
        sett.SprintSwayModifer = 1
    end

    -- Apply always auto mode if enabled
    if allvars.alwaysauto then
        sett.FireMode = "Auto"
        sett.FireModes = { "Auto" }
        sett.SemiAuto = false  -- Ensure semi-auto is disabled
        sett.AutomaticFire = true  -- Force automatic fire
    else
        -- Reset to allow both modes
        sett.FireModes = { "Auto", "Semi" }
        sett.SemiAuto = false  -- Let the gun decide its default
    end

    -- Apply instant hit modifications
    if allvars.instahit then
        sett.BulletSpeed = 9999999  -- Maximum bullet speed
        sett.BulletDrop = 0         -- No bullet drop
        sett.BulletGravity = 0      -- No gravity effect
    else
        -- Reset to reasonable defaults (adjust as needed)
        sett.BulletSpeed = 2000
        sett.BulletDrop = 1
        sett.BulletGravity = 1
    end

    -- Apply disable DOF if enabled
    if allvars.nodof then
        sett.useDof = false
    else
        sett.useDof = true
    end

    -- Apply disable aiming if enabled
    if allvars.noaiming then
        sett.allowAiming = false
    else
        sett.allowAiming = true
    end

    -- Apply fast reload if enabled
    if allvars.fastReload then
        sett.ReloadFadeIn = 0.01
        sett.ReloadFadeOut = 0.01
        sett.ReloadTime = 0.1  -- Add instant reload time
    else
        sett.ReloadFadeIn = 0.3
        sett.ReloadFadeOut = 0.3
        -- Reset reload time to default (adjust as needed)
    end

    -- Apply faster equip if enabled
    if allvars.fastequip then
        sett.EquipTValue = 0.01  -- Almost instant equip
    else
        sett.EquipTValue = 0.5  -- Normal equip speed
    end

    -- Apply extended range if enabled
    if allvars.extendedrange then
        sett.ItemLength = 20
        sett.Range = 9999  -- Extended range
    else
        sett.ItemLength = 6
        sett.Range = 300  -- Default range
    end

    -- Apply instant recoil reduction if enabled
    if allvars.instantreduction then
        sett.ReductionStartTime = 0
        sett.RecoilReduction = 100  -- Maximum reduction
    else
        sett.ReductionStartTime = 15
        sett.RecoilReduction = 1  -- Default reduction
    end
end


-- Function to modify ammunition for instant hit
local function applyAmmoMods()
if not allvars.instahit then
    return
end

local ammoTypes = game.ReplicatedStorage.AmmoTypes
if not ammoTypes then
    return
end

for _, ammo in pairs(ammoTypes:GetChildren()) do
    if ammo:IsA("Folder") or ammo:IsA("Configuration") then
        -- Set extremely high muzzle velocity for instant hit effect
        if ammo:GetAttribute("MuzzleVelocity") then
            ammo:SetAttribute("MuzzleVelocity", 9999999)
        end
        -- Increase armor penetration for better performance
        if ammo:GetAttribute("ArmorPen") then
            ammo:SetAttribute("ArmorPen", 999)
        end
    end
end
end

-- Hook into the bullet creation function for enhanced modifications
local aimogfunc = require(game.ReplicatedStorage.Modules.FPS.Bullet).CreateBullet
local original_aimmodfunc

local function enhanced_aimmodfunc(prikol, p49, p50, p_u_51, aimpart, _, p52, p53, p54)
if allvars.instahit then
    local v_u_10 = game:GetService("ReplicatedStorage")
    local v65 = v_u_10.AmmoTypes:FindFirstChild(p52)
    
    if v65 then
        local originalVelocity = v65:GetAttribute("MuzzleVelocity")
        v65:SetAttribute("MuzzleVelocity", 9999999)
        
        -- Restore original velocity after a short delay to avoid permanent changes
        task.spawn(function()
            wait(0.1)
            if originalVelocity then
                v65:SetAttribute("MuzzleVelocity", originalVelocity)
            end
        end)
    end
end

-- Apply zero recoil modifications
if allvars.norecoil then
    -- Override recoil values in the function parameters
    local v79 = {
        ["x"] = {
            ["Value"] = 0
        },
        ["y"] = {
            ["Value"] = 0
        }
    }
    
    -- Set recoil values to zero
    local v83 = 0
    local v82 = 0
    
    -- Return zero recoil values
    if original_aimmodfunc then
        local result1, result2, result3, result4 = original_aimmodfunc(prikol, p49, p50, p_u_51, aimpart, _, p52, p53, p54)
        return v83, v82, result3, v79
    end
end

-- Call original function if no modifications needed
if original_aimmodfunc then
    return original_aimmodfunc(prikol, p49, p50, p_u_51, aimpart, _, p52, p53, p54)
end
end

-- Hook the function if it exists
if aimmodfunc then
original_aimmodfunc = aimmodfunc
aimmodfunc = enhanced_aimmodfunc
end

-- Function to apply mods to all guns in inventory
local function applyToAllGuns()
if not localplayer then
    warn("LocalPlayer not found")
    return
end

local inv = game.ReplicatedStorage.Players:FindFirstChild(localplayer.Name)
if not inv then
    warn("Player inventory not found")
    return
end

inv = inv.Inventory
if not inv then
    warn("Inventory folder not found")
    return
end

for i, gun in pairs(inv:GetChildren()) do
    applyGunMods(gun)
end

-- Apply ammo modifications
applyAmmoMods()
end

-- Function to monitor equipped gun
local function monitorEquippedGun()
if not localplayer or not localplayer.Character then
    return
end

local equippedGun = localplayer.Character:FindFirstChildOfClass("Tool")
if equippedGun and equippedGun:FindFirstChild("SettingsModule") then
    applyGunMods(equippedGun)
end
end

-- Set up monitoring for equipped guns
local equippedConnection
local function setupEquippedMonitoring()
if equippedConnection then
    equippedConnection:Disconnect()
end

if not localplayer or not localplayer.Character then
    return
end

equippedConnection = localplayer.Character.ChildAdded:Connect(function(child)
    if child:IsA("Tool") and child:FindFirstChild("SettingsModule") then
        wait(0.1) -- Small delay to ensure the tool is fully loaded
        applyGunMods(child)
    end
end)
end

localplayer.CharacterAdded:Connect(function(character)
    characterspawned = tick()
    
    -- Wait for character to fully load
    character:WaitForChild("Humanoid")
    character:WaitForChild("HumanoidRootPart")
    
    -- Add small delay to ensure everything is properly initialized
    task.wait(0.1)
    
    if allvars.invisbool then
        for i, track in pairs(character.Humanoid.Animator:GetPlayingAnimationTracks()) do
            if track.Animation.AnimationId == "rbxassetid://15609995579" then
                track:Stop()
                track:Destroy()
            end
        end
        
        -- Load new animation
        invistrack = character.Humanoid.Animator:LoadAnimation(invisanim)
        if allvars.desyncbool then
            invistrack:Play(.01, 1, 0)
        end
    end
end)

-- Monitor character respawning
if localplayer then
localplayer.CharacterAdded:Connect(function(character)
    wait(1) -- Wait for character to fully load
    setupEquippedMonitoring()
end)

-- Initial setup if character already exists
if localplayer.Character then
    setupEquippedMonitoring()
end
end

-- === ORIGINAL TOGGLES ===
gunmods:AddToggle('Rapid Fire', {
Text = 'Rapid Fire',
Default = false,
Tooltip = 'Enables rapid fire (reequip gun if holding)',
Callback = function(v)
    allvars.rapidfire = v
    applyToAllGuns()
    monitorEquippedGun()
end
})

gunmods:AddToggle('No Recoil', {
Text = 'No Recoil',
Default = false,
Tooltip = 'Removes weapon recoil completely',
Callback = function(v)
    allvars.norecoil = v
    applyToAllGuns()
    monitorEquippedGun()
end
})

gunmods:AddToggle('Fast Aim', {
Text = 'Fast Aim',
Default = false,
Tooltip = 'Removes Aim speed',
Callback = function(v)
    allvars.fastaim = v
    applyToAllGuns()
    monitorEquippedGun()
end
})

gunmods:AddToggle('Instant Reload', {
Text = 'Instant Reload',
Default = false,
Tooltip = 'Enables instant reload',
Callback = function(v)
    allvars.instareload = v
    if v then 
        require(game.ReplicatedStorage.Modules.FPS).reload = instrelMODfunc
    else
        require(game.ReplicatedStorage.Modules.FPS).reload = instrelOGfunc
    end
end
})

gunmods:AddToggle('Instant Equip', {
Text = 'Instant Equip',
Default = false,
Tooltip = 'Enables instant equip',
Callback = function(v)
    allvars.Zestequip = v
end
})

gunmods:AddToggle('No Sway', {
Text = 'No sway',
Default = false,
Tooltip = 'Disables weapon sway',
Callback = function(v)
    allvars.noswaybool = v
    applyToAllGuns()
    monitorEquippedGun()
end
})
gunmods:AddToggle('Nojumptilt', {
    Text = 'No jump tilt',
    Default = false,
    Tooltip = 'Removes jump tilt',
    Callback = function(v)
        nojumptilt = v
    end
})
-- === NEW TOGGLES ===
gunmods:AddToggle('Instant Hit', {
Text = 'Instant Hit',
Default = false,
Tooltip = 'Makes bullets hit instantly with maximum velocity',
Callback = function(v)
    allvars.instahit = v
    applyToAllGuns()
    applyAmmoMods()
    monitorEquippedGun()
end
})

gunmods:AddToggle('Always Auto', {
Text = 'Always Auto',
Default = false,
Tooltip = 'Forces all weapons to auto fire mode',
Callback = function(v)
    allvars.alwaysauto = v
    applyToAllGuns()
    monitorEquippedGun()
end
})

gunmods:AddToggle('Instant Equip', {
    Text = 'Instant Equip',
    Default = false,
    Tooltip = 'Enables instant equip',
    Callback = function(v)
        allvars.instaequip = v
    end
})

-- HITMARKER SECTION
gunmods2:AddToggle('Hitmarker', {
    Text = 'Hitmarker',
    Default = false,
    Tooltip = 'Enables hitmarkers',
    Callback = function(v)
        allvars.hitmarkbool = v
    end
})

gunmods2:AddSlider('Hitmarker fade', {
    Text = 'Hitmarker Fade Time',
    Default = 2,
    Min = 0,
    Max = 10,
    Rounding = 1,
    Compact = false,
    Callback = function(c)
        allvars.hitmarkfade = c
    end
})

gunmods2:AddLabel('Hitmarker color'):AddColorPicker('HitmarkColorPick', {
    Default = Color3.new(1, 1, 1),
    Title = 'Hitmarker Color',
    Callback = function(a)
        allvars.hitmarkcolor = a
    end
})

-- HIT SOUNDS SECTION
gunmods2:AddToggle('HitSoundToggle', {
    Text = 'Enable Hit Sounds',
    Default = false,
    Callback = function(v)
        allvars.hitsoundbool = v
    end
})

gunmods2:AddDropdown('HeadHitSound', {
    Values = hitsoundlibUI,
    Default = allvars.hitsoundhead or "Ding",
    Multi = false,
    Text = 'Headshot Sound',
    Callback = function(v)
        allvars.hitsoundhead = v
    end
})

gunmods2:AddDropdown('BodyHitSound', {
    Values = hitsoundlibUI,
    Default = allvars.hitsoundbody or "Blackout",
    Multi = false,
    Text = 'Bodyshot Sound',
    Callback = function(v)
        allvars.hitsoundbody = v
    end
})

gunmods2:AddDropdown('BeamTexture', {
    Values = beamTextureUI,
    Default = getgenv().beamtexture or "Texture 2", -- Default to second texture
    Multi = false,
    Text = 'Beam Texture',
    Callback = function(v)
        local selectedIndex = nil
        for i, textureName in ipairs(beamTextureUI) do
            if textureName == v then
                selectedIndex = i
                break
            end
        end
            if selectedIndex then
            allvars.beamtexture = BeamTexture[selectedIndex]
        end
    end
})

gunmods2:AddToggle('TracerToggle', {
    Text = 'Enable Tracers',
    Default = false,
    Tooltip = 'Enables bullet tracers',
    Callback = function(v)
        allvars.tracbool = v
    end
})

gunmods2:AddDropdown('TracerType', {
    Values = {"Beam Tracer (Performance)", "Beam Width Only", "Simple Beam", "Cylinder Tracer"},
    Default = "Beam Tracer (Performance)",
    Multi = false,
    Text = 'Tracer Type',
    Tooltip = 'Select the type of tracer to use',
    Callback = function(v)
        if v == "Beam Tracer (Performance)" then
            allvars.tracertype = "beam_performance"
        elseif v == "Beam Width Only" then
            allvars.tracertype = "beam_width"
        elseif v == "Simple Beam" then
            allvars.tracertype = "beam_simple"
        elseif v == "Cylinder Tracer" then
            allvars.tracertype = "cylinder"
            allvars.usebeamtracer = false
        end
            if v ~= "Cylinder Tracer" then
            allvars.usebeamtracer = true
        end
    end
})

gunmods2:AddLabel('Tracer Color'):AddColorPicker('TracerColorPick', {
    Default = Color3.new(1, 1, 0), -- Default yellow
    Title = 'Tracer Color',
    Tooltip = 'Choose the color of your tracers',
    Callback = function(color)
        allvars.tracercolor3 = color
    end
})

gunmods2:AddSlider('TracerWidth', {
    Text = 'Tracer Width',
    Default = 0.2,
    Min = 0.05,
    Max = 1.0,
    Rounding = 2,
    Compact = false,
    Tooltip = 'Adjust the thickness of tracers',
    Callback = function(width)
        allvars.tracerwidth = width
    end
})

gunmods2:AddSlider('TracerTransparency', {
    Text = 'Tracer Transparency',
    Default = 0.3,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Compact = false,
    Tooltip = 'Adjust tracer transparency (0 = opaque, 1 = invisible)',
    Callback = function(trans)
        allvars.tracertrans = trans
    end
})

gunmods2:AddSlider('TracerFadeTime', {
    Text = 'Tracer Fade Time',
    Default = 0.3,
    Min = 0.1,
    Max = 2.0,
    Rounding = 1,
    Compact = false,
    Tooltip = 'How long tracers take to fade out',
    Callback = function(fade)
        allvars.tracerfade = fade
    end
})

gunmods2:AddToggle('TracerBloom', {
    Text = 'Tracer Bloom Effect',
    Default = false,
    Tooltip = 'Adds light emission to beam tracers',
    Callback = function(v)
        allvars.tracerbloom = v
    end
})

-- GUN CUSTOMIZATION SECTION
gunmods2:AddToggle('GunCustomToggle', {
    Text = 'Enable Gun Customization',
    Default = false,
    Tooltip = 'Enables gun material and color customization',
    Callback = function(v)
        allvars.guncustombool = v
        if not v then
            -- Reset gun appearance when disabled
            resetGunAppearance()
        end
    end
})

gunmods2:AddDropdown('GunMaterial', {
    Values = {"ForceField", "Neon"},
    Default = "ForceField",
    Multi = false,
    Text = 'Gun Material',
    Tooltip = 'Select the material for your gun',
    Callback = function(v)
        allvars.gunmaterial = v
        if allvars.guncustombool then
            applyGunCustomization()
        end
    end
})

gunmods2:AddLabel('Gun Color'):AddColorPicker('GunColorPick', {
    Default = Color3.new(1, 1, 1),
    Title = 'Gun Color',
    Tooltip = 'Choose the color of your gun',
    Callback = function(color)
        allvars.guncolor = color
        if allvars.guncustombool then
            applyGunCustomization()
        end
    end
})

-- Function to recursively find and process all parts
function processAllParts(parent, callback)
    for _, child in pairs(parent:GetChildren()) do
        if child:IsA("BasePart") then
            callback(child)
        end
        -- Recursively process children
        if #child:GetChildren() > 0 then
            processAllParts(child, callback)
        end
    end
end

-- Function to remove all SurfaceAppearance objects
function removeSurfaceAppearances(item)
    processAllParts(item, function(part)
        for _, child in pairs(part:GetChildren()) do
            if child:IsA("SurfaceAppearance") then
                child:Destroy()
            end
        end
    end)
end

-- Function to apply gun customization
function applyGunCustomization()
    local camera = workspace.Camera
    if not camera then return end
    
    local viewModel = camera:FindFirstChild("ViewModel")
    if not viewModel then return end
    
    local item = viewModel:FindFirstChild("Item")
    if not item then return end
    
    -- Remove all SurfaceAppearance objects
    removeSurfaceAppearances(item)
    
    -- Apply material and color to all parts
    processAllParts(item, function(part)
        if allvars.gunmaterial == "ForceField" then
            part.Material = Enum.Material.ForceField
        elseif allvars.gunmaterial == "Neon" then
            part.Material = Enum.Material.Neon
        end
        
        if allvars.guncolor then
            part.Color = allvars.guncolor
        end
    end)
end

-- Function to reset gun appearance (store original states)
local originalStates = {}

function storeOriginalStates(item)
    originalStates = {}
    processAllParts(item, function(part)
        originalStates[part] = {
            material = part.Material,
            color = part.Color,
            surfaceAppearances = {}
        }
        
        -- Store SurfaceAppearance objects
        for _, child in pairs(part:GetChildren()) do
            if child:IsA("SurfaceAppearance") then
                table.insert(originalStates[part].surfaceAppearances, child:Clone())
            end
        end
    end)
end

function resetGunAppearance()
    local camera = workspace.Camera
    if not camera then return end
    
    local viewModel = camera:FindFirstChild("ViewModel")
    if not viewModel then return end
    
    local item = viewModel:FindFirstChild("Item")
    if not item then return end
    
    -- Restore original states
    for part, state in pairs(originalStates) do
        if part and part.Parent then
            part.Material = state.material
            part.Color = state.color
            
            -- Remove current SurfaceAppearances and restore originals
            for _, child in pairs(part:GetChildren()) do
                if child:IsA("SurfaceAppearance") then
                    child:Destroy()
                end
            end
            
            for _, surfaceAppearance in pairs(state.surfaceAppearances) do
                surfaceAppearance:Clone().Parent = part
            end
        end
    end
end

-- Initialize original states when gun customization is first enabled
local hasStoredStates = false
local oldApplyFunction = applyGunCustomization

applyGunCustomization = function()
    local camera = workspace.Camera
    if not camera then return end
    
    local viewModel = camera:FindFirstChild("ViewModel")
    if not viewModel then return end
    
    local item = viewModel:FindFirstChild("Item")
    if not item then return end
    
    -- Store original states on first use
    if not hasStoredStates then
        storeOriginalStates(item)
        hasStoredStates = true
    end
    
    oldApplyFunction()
end

-- Auto-apply when new weapon is equipped
spawn(function()
    while wait(0.5) do
        if allvars.guncustombool then
            local camera = workspace.Camera
            if camera then
                local viewModel = camera:FindFirstChild("ViewModel")
                if viewModel then
                    local item = viewModel:FindFirstChild("Item")
                    if item then
                        -- Check if this is a new weapon (reset stored states)
                        local currentWeaponName = item.Name
                        if allvars.lastWeaponName ~= currentWeaponName then
                            hasStoredStates = false
                            allvars.lastWeaponName = currentWeaponName
                        end
                        
                        applyGunCustomization()
                    end
                end
            end
        end
    end
end)
allvars.showvisibility = false
allvars.showhealth = false

-- Function to create or get existing UI
getOrCreateUI = function(name, parent)
    existing = parent:FindFirstChild(name)
    if existing then
        return existing
    end
    
    ui = Instance.new("ScreenGui")
    ui.Name = name
    ui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ui.ResetOnSpawn = false -- This prevents UI from being destroyed on death
    ui.Parent = parent
    return ui
end

-- Create persistent UIs
visibilityUI = getOrCreateUI("VisibilityUI", game:GetService("CoreGui"))
targetItemsUI = getOrCreateUI("TargetItemsUI", game:GetService("CoreGui"))

-- Clear existing elements to prevent duplicates
visibilityUI:ClearAllChildren()
targetItemsUI:ClearAllChildren()

-- Create visibility label
visibilityLabel = Instance.new("TextLabel")
visibilityLabel.Name = "VisibilityLabel"
visibilityLabel.Parent = visibilityUI
visibilityLabel.BackgroundTransparency = 1
visibilityLabel.Position = UDim2.new(0.5, -50, 0.9, 0) -- Bottom center
visibilityLabel.Size = UDim2.new(0, 100, 0, 30)
visibilityLabel.Font = Enum.Font.GothamBold
visibilityLabel.TextColor3 = Color3.new(1, 1, 1)
visibilityLabel.TextSize = 14
visibilityLabel.Text = ""
visibilityLabel.Visible = false

-- Create health label (positioned under visibility label)
healthLabel = Instance.new("TextLabel")
healthLabel.Name = "HealthLabel"
healthLabel.Parent = visibilityUI
healthLabel.BackgroundTransparency = 1
healthLabel.Position = UDim2.new(0.5, -50, 0.93, 0) -- Just below visibility label
healthLabel.Size = UDim2.new(0, 100, 0, 30)
healthLabel.Font = Enum.Font.GothamBold
healthLabel.TextColor3 = Color3.new(1, 1, 1)
healthLabel.TextSize = 14
healthLabel.Text = ""
healthLabel.Visible = false

-- Modified hasWallBetween function that updates the visibility label
hasWallBetween = function(startPos, endPos, target)
    raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    -- Get current character references (handles respawning)
    filterInstances = {}
    if game.Players.LocalPlayer.Character then
        table.insert(filterInstances, game.Players.LocalPlayer.Character)
    end
    if target.Character then
        table.insert(filterInstances, target.Character)
    end
    raycastParams.FilterDescendantsInstances = filterInstances
    
    direction = (endPos - startPos)
    raycastResult = workspace:Raycast(startPos, direction, raycastParams)
    
    -- Update visibility label
    if raycastResult then
        visibilityLabel.Text = "Invisible"
        visibilityLabel.TextColor3 = Color3.new(1, 0, 0) -- Red
    else
        visibilityLabel.Text = "Visible"
        visibilityLabel.TextColor3 = Color3.new(0, 1, 0) -- Green
    end
    
    return raycastResult ~= nil, raycastResult
end

-- Function to update health display
updateHealthDisplay = function(target)
    if not target or not target:IsA("Player") or not target.Character then
        healthLabel.Text = ""
        return
    end
    
    humanoid = target.Character:FindFirstChild("Humanoid")
    if humanoid then
        currentHealth = math.floor(humanoid.Health)
        maxHealth = math.floor(humanoid.MaxHealth)
        healthLabel.Text = string.format("HP: %d/%d", currentHealth, maxHealth)
        
        -- Color code health
        healthPercent = currentHealth / maxHealth
        if healthPercent > 0.6 then
            healthLabel.TextColor3 = Color3.new(0, 1, 0) -- Green
        elseif healthPercent > 0.3 then
            healthLabel.TextColor3 = Color3.new(1, 1, 0) -- Yellow
        else
            healthLabel.TextColor3 = Color3.new(1, 0, 0) -- Red
        end
    else
        healthLabel.Text = ""
    end
end

-- Create item slots
createItemSlot = function(name, position)
    slot = Instance.new("Frame")
    slot.Name = name
    slot.Parent = targetItemsUI
    slot.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    slot.BackgroundTransparency = 0.15
    slot.BorderColor3 = Color3.fromRGB(0, 0, 0)
    slot.BorderSizePixel = 2
    slot.Position = position
    slot.Size = UDim2.new(0, 100, 0, 100)
    slot.Visible = false
    
    itemImage = Instance.new("ImageLabel")
    itemImage.Name = "ItemImage"
    itemImage.Parent = slot
    itemImage.BackgroundTransparency = 1
    itemImage.Position = UDim2.new(0.1, 0, 0.1, 0)
    itemImage.Size = UDim2.new(0.8, 0, 0.6, 0)
    itemImage.Image = ""
    
    itemName = Instance.new("TextLabel")
    itemName.Name = "ItemName"
    itemName.Parent = slot
    itemName.BackgroundTransparency = 1
    itemName.Position = UDim2.new(0, 0, 0.75, 0)
    itemName.Size = UDim2.new(0.85, 0, 0.2, 0)
    itemName.Font = Enum.Font.GothamBold
    itemName.TextColor3 = Color3.new(1, 1, 1)
    itemName.TextSize = 14
    itemName.Text = ""
    
    return slot
end

itemSlots = {
    createItemSlot("Item1", UDim2.new(0.36, 0, 0, 0)),
    createItemSlot("Item2", UDim2.new(0.457, 0, 0, 0)),
    createItemSlot("Item3", UDim2.new(0.555, 0, 0, 0))
}

getFirstThreeItems = function(inventory)
    items = {}
    for _, item in ipairs(inventory:GetChildren()) do
        if #items >= 3 then break end
        table.insert(items, item)
    end
    return items
end

updateTargetItems = function(target)
    for _, slot in ipairs(itemSlots) do
        slot.Visible = false
    end
    
    if not target or not target:IsA("Player") then return end
    
    targetInventory = game:GetService("ReplicatedStorage").Players:FindFirstChild(target.Name)
    if not targetInventory or not targetInventory:FindFirstChild("Inventory") then return end
    
    inventory = targetInventory.Inventory
    items = getFirstThreeItems(inventory)
    
    -- Display items
    for i, item in ipairs(items) do
        slot = itemSlots[i]
        itemImage = slot:FindFirstChild("ItemImage")
        itemName = slot:FindFirstChild("ItemName")
        
        itemName.Text = item.Name
        
        if item:FindFirstChild("ItemProperties") then
            itemIcon = item.ItemProperties:FindFirstChild("ItemIcon")
            if itemIcon and itemIcon:IsA("ImageLabel") then
                itemImage.Image = itemIcon.Image
            else
                itemImage.Image = ""
            end
        else
            itemImage.Image = ""
        end
        
        slot.Visible = true
    end
end

RunService.RenderStepped:Connect(function()
    visibilityLabel.Visible = allvars.aimbool and aimtarget ~= nil and allvars.showvisibility
    healthLabel.Visible = allvars.aimbool and aimtarget ~= nil and allvars.showhealth
    targetItemsUI.Enabled = allvars.aimbool and aimtarget ~= nil and allvars.showitems

    if allvars.aimbool and aimtarget ~= nil and allvars.showvisibility and aimtargetpart and game.Players.LocalPlayer.Character then
        startPos = workspace.CurrentCamera.CFrame.Position
        endPos = aimtargetpart.Position
        hasWallBetween(startPos, endPos, aimtarget)
    end
    
    if allvars.aimbool and aimtarget ~= nil and allvars.showhealth then
        updateHealthDisplay(aimtarget)
    end
    
    if allvars.aimbool and aimtarget ~= nil and allvars.showitems then
        if aimtarget:IsA("Player") then
            updateTargetItems(aimtarget)
        else
            for _, slot in ipairs(itemSlots) do
                slot.Visible = false
            end
        end
    end
end)

aim:AddToggle('ShowVisibility', {
    Text = 'Show Visibility',
    Default = false,
    Tooltip = 'Shows if target is visible or blocked by wall',
    Callback = function(v)
        allvars.showvisibility = v
    end
})

aim:AddToggle('ShowHealth', {
    Text = 'Show Health',
    Default = false,
    Tooltip = 'Shows the target\'s health',
    Callback = function(v)
        allvars.showhealth = v
    end
})

aim:AddToggle('ShowTargetItems', {
    Text = 'Show Target Items',
    Default = false,
    Tooltip = 'Shows the items in the target\'s inventory',
    Callback = function(v)
        allvars.showitems = v
    end
})

-- Toggle Silent Aim
aim:AddToggle('SilentAimToggle', {
Text = 'Silent Aim',
Default = false,
Tooltip = 'Enables silent aim',
Callback = function(v)
    allvars.aimbool = v
    if v then
        require(game.ReplicatedStorage.Modules.FPS.Bullet).CreateBullet = aimmodfunc
    else
        require(game.ReplicatedStorage.Modules.FPS.Bullet).CreateBullet = aimogfunc
    end
end
}):AddKeyPicker('SilentAimKeybind', {
Default = 'Y',
SyncToggleState = true,
Mode = 'Toggle',
Text = 'Silent Aim',
NoUI = false,
})

aim:AddToggle('SilentAimToggle2', {
Text = 'Target Ais',
Default = false,
Tooltip = 'Target Ais',
Callback = function(v)
    allvars.aimbots = v
end
})


-- Silent Aim Settings
aim:AddSlider('AimFOV', {
Text = 'Aim FOV',
Default = 150,
Min = 10,
Max = 500,
Rounding = 0,
Callback = function(v)
    allvars.aimfov = v
end
})

aim:AddSlider('AimDistance', {
Text = 'Max Distance (m)',
Default = 800,
Min = 50,
Max = 2000,
Rounding = 0,
Callback = function(v)
    allvars.aimdistance = v
end
})

aim:AddDropdown('AimPart', {
Values = {'Head', 'HumanoidRootPart', 'UpperTorso', 'LowerTorso'},
Default = 1,
Multi = false,
Text = 'Aim Part',
Callback = function(v)
    allvars.aimpart = v
end
})

aim:AddToggle('Prediction', {
Text = 'Prediction',
Default = false,
Tooltip = 'Predict target movement',
Callback = function(v)
    allvars.aimfakewait = v
end
})

aim:AddToggle('VisibilityCheck', {
Text = 'Visibility Check',
Default = true,
Tooltip = 'Only target visible players',
Callback = function(v)
    allvars.aimvischeck = v
end
})

aim:AddToggle('triggerBot', {
Text = 'triggerBot',
Default = false,
Tooltip = 'Yes',
Callback = function(v)
   allvars.aimtrigger = v
end
})
aim:AddToggle('DistanceCheck', {
Text = 'Distance Check',
Default = true,
Tooltip = 'Respect bullet drop/distance',
Callback = function(v)
    allvars.aimdistcheck = v
end
})



aim:AddToggle('ShowFOV', {
Text = 'Show FOV',
Default = true,
Tooltip = 'Show aim FOV circle',
Callback = function(v)
    allvars.showfov = v
end
})

aim:AddLabel('FOV Color'):AddColorPicker('FOVColor', {
Default = Color3.fromRGB(255, 255, 255),
Callback = function(v)
    allvars.aimfovcolor = v
end
})

-- Update target selection
runs.Heartbeat:Connect(function(delta)
if allvars.aimbool then
    choosetarget()
end
end)


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

CamLockBox:AddToggle('WallCheckToggle', {
    Text = 'Wall Check',
    Default = true,
    Callback = function(state)
        wallCheck = state
    end
})

CamLockBox:AddToggle('KnockCheckToggle', {
    Text = 'Knock Check',
    Default = true,
    Tooltip = 'Skip knocked out players (Da Hood)',
    Callback = function(state)
        knockCheckEnabled = state
    end
})

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

espUI2:AddToggle('LootESPEnabled', {
    Text = 'Loot ESP',
    Default = false,
    Tooltip = 'Enable ESP for loot items',
    Callback = function(value)
        getgenv().lootESPEnabled = value
        applyLootESP()
    end
})

espUI2:AddToggle('LootNameEnabled', {
    Text = 'Show Loot Names',
    Default = true,
    Tooltip = 'Show names of loot items',
    Callback = function(value)
        getgenv().lootNameEnabled = value
        applyLootESP()
    end
})

espUI2:AddToggle('LootDistanceEnabled', {
    Text = 'Show Loot Distance',
    Default = true,
    Tooltip = 'Show distance to loot items',
    Callback = function(value)
        getgenv().lootDistanceEnabled = value
        applyLootESP()
    end
})

espUI2:AddToggle('LootHighlightEnabled', {
    Text = 'Loot Highlight',
    Default = false,
    Tooltip = 'Highlight loot items in the world',
    Callback = function(value)
        getgenv().lootHighlightEnabled = value
        applyLootHighlight()
    end
})

espUI2:AddLabel("LootColor"):AddColorPicker('LootColor', {
    Title = 'Loot ESP Color',
    Default = Color3.new(1, 0, 1),
    Callback = function(value)
        getgenv().lootColor = value
    end
})

espUI2:AddLabel("LootHighlight"):AddColorPicker('LootHighlightColor', {
    Title = 'Loot Highlight Color',
    Default = Color3.new(1, 0, 1),
    Callback = function(value)
        getgenv().lootHighlightColor = value
        applyLootHighlight()
    end
})

espUI2:AddSlider('LootMaxDistance', {
    Text = 'Loot Max Distance',
    Default = 500,
    Min = 50,
    Max = 1000,
    Rounding = 0,
    Compact = false,
    Callback = function(value)
        getgenv().lootMaxDistance = value
    end
})


-- Variables to store connections and states
local timeConnection = nil
local ambientConnection = nil
local armsForceFieldConnection = nil
local fogConnection = nil
local atmosphereConnection = nil
local brightnessConnection = nil
local shadowConnection = nil
local bloomConnection = nil
local inventoryBlurConnection = nil

-- Store original values
local originalTimeOfDay = game:GetService("Lighting").TimeOfDay
local originalOutdoorAmbient = game:GetService("Lighting").OutdoorAmbient
local originalAmbient = game:GetService("Lighting").Ambient
local originalBrightness = game:GetService("Lighting").Brightness
local originalGlobalShadows = game:GetService("Lighting").GlobalShadows

-- Current state variables
local currentTimeOfDay = originalTimeOfDay
local currentOutdoorAmbient = originalOutdoorAmbient
local currentAmbient = originalAmbient
local currentBrightness = originalBrightness
local currentArmsColor = Color3.fromRGB(255, 255, 255)

-- Fog state variables
local fogRemoved = false
local originalFogSettings = {
    atmosphereOffset = game:GetService("Lighting").Atmosphere and game:GetService("Lighting").Atmosphere.Offset or 0.3,
    atmosphereDensity = game:GetService("Lighting").Atmosphere and game:GetService("Lighting").Atmosphere.Density or 0.3,
    fogEnd = game:GetService("Lighting").FogEnd,
    fogStart = game:GetService("Lighting").FogStart
}

-- Initialize allvars if not exists
if not allvars then
    allvars = {}
end

-- LIGHTING EFFECTS
WorldStuff:AddToggle('Remove SunRays', {
    Text = "Remove SunRays",
    Default = false,
    Callback = function(v)
        local sunRays = game:GetService("Lighting"):FindFirstChild("SunRays")
        if sunRays then
            sunRays.Enabled = not v
        end
    end
})

-- Enhanced fog removal with automatic protection
WorldStuff:AddToggle('Remove Fog', {
    Text = "Remove Fog",
    Default = false,
    Callback = function(v)
        fogRemoved = v
        local lighting = game:GetService("Lighting")
        
        if v then
            -- Remove fog
            if lighting.Atmosphere then
                lighting.Atmosphere.Offset = 0
                lighting.Atmosphere.Density = 0
            end
            lighting.FogEnd = 10000000
            lighting.FogStart = 1000000
            
            -- Auto-lock fog settings
            fogConnection = lighting.Changed:Connect(function(property)
                if fogRemoved then
                    if property == "FogEnd" and lighting.FogEnd < 10000000 then
                        lighting.FogEnd = 10000000
                    elseif property == "FogStart" and lighting.FogStart < 1000000 then
                        lighting.FogStart = 1000000
                    end
                end
            end)
            
            -- Monitor Atmosphere changes
            if lighting.Atmosphere then
                atmosphereConnection = lighting.Atmosphere.Changed:Connect(function(property)
                    if fogRemoved then
                        if property == "Offset" and lighting.Atmosphere.Offset > 0 then
                            lighting.Atmosphere.Offset = 0
                        elseif property == "Density" and lighting.Atmosphere.Density > 0 then
                            lighting.Atmosphere.Density = 0
                        end
                    end
                end)
            end
        else
            -- Restore fog and remove protection
            if lighting.Atmosphere then
                lighting.Atmosphere.Offset = originalFogSettings.atmosphereOffset
                lighting.Atmosphere.Density = originalFogSettings.atmosphereDensity
            end
            lighting.FogEnd = originalFogSettings.fogEnd
            lighting.FogStart = originalFogSettings.fogStart
            
            -- Disconnect fog protection
            if fogConnection then
                fogConnection:Disconnect()
                fogConnection = nil
            end
            if atmosphereConnection then
                atmosphereConnection:Disconnect()
                atmosphereConnection = nil
            end
        end
    end
})

WorldStuff:AddSlider("Brightness", {
    Text = "Brightness",
    Min = 0,
    Max = 10,
    Default = originalBrightness,
    Rounding = 1,
    Callback = function(value)
        currentBrightness = value
        game:GetService("Lighting").Brightness = value
        
        -- Auto-lock brightness when changed
        if brightnessConnection then
            brightnessConnection:Disconnect()
        end
        brightnessConnection = game:GetService("Lighting").Changed:Connect(function(property)
            if property == "Brightness" and game:GetService("Lighting").Brightness ~= currentBrightness then
                game:GetService("Lighting").Brightness = currentBrightness
            end
        end)
    end
})

WorldStuff:AddToggle("Shadows", {
    Text = "Shadows",
    Default = originalGlobalShadows,
    Callback = function(value)
        game:GetService("Lighting").GlobalShadows = value
        if value ~= originalGlobalShadows then
            if shadowConnection then
                shadowConnection:Disconnect()
            end
            shadowConnection = game:GetService("Lighting").Changed:Connect(function(property)
                if property == "GlobalShadows" and game:GetService("Lighting").GlobalShadows ~= value then
                    game:GetService("Lighting").GlobalShadows = value
                end
            end)
        else
            if shadowConnection then
                shadowConnection:Disconnect()
                shadowConnection = nil
            end
        end
    end
})

WorldStuff:AddToggle("Bloom", {
    Text = "Bloom",
    Default = game:GetService("Lighting").Bloom and game:GetService("Lighting").Bloom.Enabled or false,
    Callback = function(value)
        local bloom = game:GetService("Lighting"):FindFirstChild("Bloom")
        if bloom then
            bloom.Enabled = value
            
            -- Auto-lock bloom
            if bloomConnection then
                bloomConnection:Disconnect()
            end
            bloomConnection = bloom.Changed:Connect(function(property)
                if property == "Enabled" and bloom.Enabled ~= value then
                    bloom.Enabled = value
                end
            end)
        end
    end
})

WorldStuff:AddToggle("InventoryBlur", {
    Text = "InventoryBlur",
    Default = game:GetService("Lighting").InventoryBlur and game:GetService("Lighting").InventoryBlur.Enabled or false,
    Callback = function(value)
        local inventoryBlur = game:GetService("Lighting"):FindFirstChild("InventoryBlur")
        if inventoryBlur then
            inventoryBlur.Enabled = value
            
            -- Auto-lock inventory blur
            if inventoryBlurConnection then
                inventoryBlurConnection:Disconnect()
            end
            inventoryBlurConnection = inventoryBlur.Changed:Connect(function(property)
                if property == "Enabled" and inventoryBlur.Enabled ~= value then
                    inventoryBlur.Enabled = value
                end
            end)
        end
    end
})

-- TIME CONTROLS
WorldStuff:AddSlider("Time of Day", {
    Text = "Time of Day",
    Min = 0,
    Max = 24,
    Default = tonumber(string.match(originalTimeOfDay, "(%d+)")) or 12,
    Rounding = 1,
    Callback = function(value)
        currentTimeOfDay = string.format("%02d:00:00", value)
        game:GetService("Lighting").TimeOfDay = currentTimeOfDay
        
        -- Auto-lock time when changed
        if timeConnection then
            timeConnection:Disconnect()
        end
        timeConnection = game:GetService("Lighting").Changed:Connect(function(property)
            if property == "TimeOfDay" and game:GetService("Lighting").TimeOfDay ~= currentTimeOfDay then
                game:GetService("Lighting").TimeOfDay = currentTimeOfDay
            end
        end)
    end
})

-- AMBIENT LIGHTING CONTROLS
WorldStuff:AddLabel('OutdoorAmbient'):AddColorPicker('OutdoorAmbient', {
    Default = originalOutdoorAmbient,
    Title = 'OutdoorAmbient',
    Callback = function(Value)
        currentOutdoorAmbient = Value
        game:GetService("Lighting").OutdoorAmbient = Value
        
        -- Auto-lock outdoor ambient when changed
        if ambientConnection then
            ambientConnection:Disconnect()
        end
        ambientConnection = game:GetService("Lighting").Changed:Connect(function(property)
            if property == "OutdoorAmbient" and game:GetService("Lighting").OutdoorAmbient ~= currentOutdoorAmbient then
                game:GetService("Lighting").OutdoorAmbient = currentOutdoorAmbient
            end
        end)
    end
})

WorldStuff:AddLabel('Ambient'):AddColorPicker('Ambient', {
    Default = originalAmbient,
    Title = 'Ambient',
    Callback = function(Value)
        currentAmbient = Value
        game:GetService("Lighting").Ambient = Value
    end
})

-- ARMS CUSTOMIZATION
local function applyArmsForceField()
    local viewModel = workspace.Camera:FindFirstChild("ViewModel")
    if viewModel then
        local armParts = {
            viewModel:FindFirstChild("LeftHand"),
            viewModel:FindFirstChild("RightHand"),
            viewModel:FindFirstChild("LeftLowerArm"),
            viewModel:FindFirstChild("RightLowerArm"),
            viewModel:FindFirstChild("LeftUpperArm"),
            viewModel:FindFirstChild("RightUpperArm")
        }
        
        local Shirt = viewModel:FindFirstChild("WastelandShirt")
        if Shirt then
            Shirt:Destroy()
        end
        
        for _, part in pairs(armParts) do
            if part then
                part.Material = Enum.Material.ForceField
                part.Transparency = 0.7
                part.Color = currentArmsColor
            end
        end
    end
end

local function removeArmsForceField()
    local viewModel = workspace.Camera:FindFirstChild("ViewModel")
    if viewModel then
        local armParts = {
            viewModel:FindFirstChild("LeftHand"),
            viewModel:FindFirstChild("RightHand"),
            viewModel:FindFirstChild("LeftLowerArm"),
            viewModel:FindFirstChild("RightLowerArm"),
            viewModel:FindFirstChild("LeftUpperArm"),
            viewModel:FindFirstChild("RightUpperArm")
        }
        
        for _, part in pairs(armParts) do
            if part then
                part.Material = Enum.Material.Plastic
                part.Transparency = 0
                part.Color = Color3.fromRGB(255, 255, 255)
            end
        end
    end
end

local function updateArmsColor()
    local viewModel = workspace.Camera:FindFirstChild("ViewModel")
    if viewModel then
        local armParts = {
            viewModel:FindFirstChild("LeftHand"),
            viewModel:FindFirstChild("RightHand"),
            viewModel:FindFirstChild("LeftLowerArm"),
            viewModel:FindFirstChild("RightLowerArm"),
            viewModel:FindFirstChild("LeftUpperArm"),
            viewModel:FindFirstChild("RightUpperArm")
        }
        
        for _, part in pairs(armParts) do
            if part and part.Material == Enum.Material.ForceField then
                part.Color = currentArmsColor
            end
        end
    end
end

WorldStuff:AddToggle("Arms ForceField", {
    Text = "Arms ForceField",
    Default = false,	
    Callback = function(value)
        if value then 
            -- Enable and auto-protect arms
            applyArmsForceField()
            
            armsForceFieldConnection = workspace.Camera.ChildAdded:Connect(function(child)
                if child.Name == "ViewModel" then
                    wait(0.1)
                    applyArmsForceField()
                end
            end)
        else
            -- Disable and remove protection
            removeArmsForceField()
            
            if armsForceFieldConnection then
                armsForceFieldConnection:Disconnect()
                armsForceFieldConnection = nil
            end
        end
    end
})

WorldStuff:AddLabel('Arms Color'):AddColorPicker('ArmsColor', {
    Default = currentArmsColor,
    Title = 'Arms Color',
    Callback = function(Value)
        currentArmsColor = Value
        updateArmsColor()
    end
})

-- TERRAIN AND ENVIRONMENT
WorldStuff:AddToggle('Disable Grass', {
    Text = 'Disable Grass',
    Default = false,
    Tooltip = 'Disables grass rendering',
    Callback = function(v)
        allvars.worldgrass = v
        pcall(function()
            sethiddenproperty(workspace.Terrain, "Decoration", not v)
        end)
    end
})

WorldStuff:AddToggle('Disable Trees', {
    Text = 'Disable Trees',
    Default = false,
    Tooltip = 'Disable tree rendering',
    Callback = function(v)
        local spawnerZones = workspace:FindFirstChild("SpawnerZones")
        if spawnerZones then
            local trees = spawnerZones:FindFirstChild("Foliage")
            if trees then
                if v then
                    trees.Parent = game:GetService("ReplicatedStorage")
                else 
                    trees.Parent = spawnerZones
                end
            end
        end
    end
})

WorldStuff:AddToggle('No Clouds', {
    Text = 'No Clouds',
    Default = false,
    Tooltip = 'Disables clouds',
    Callback = function(v)
        allvars.worldcloud = v
        local clouds = workspace.Terrain:FindFirstChild("Clouds")
        if clouds then
            clouds.Enabled = not v
        end
    end
})

getgenv().FlightKeybind = Enum.KeyCode.X
getgenv().FlySpeed = 10
getgenv().FlightEnabled = false
getgenv().Flying = false

-- Long Neck settings
getgenv().LongNeckEnabled = false
getgenv().OriginalHipHeight = nil
getgenv().LongNeckHeight = 2

-- Enhanced movement settings
getgenv().NoClipEnabled = false
getgenv().SpeedEnabled = false
getgenv().WalkSpeed = 50
getgenv().JumpPowerEnabled = false
getgenv().JumpPower = 100

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

-- Long Neck Functions
local function EnableLongNeck()
local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
if humanoid then
    if getgenv().OriginalHipHeight == nil then
        getgenv().OriginalHipHeight = humanoid.HipHeight
    end
    humanoid.HipHeight = getgenv().LongNeckHeight
end
end

local function DisableLongNeck()
local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
if humanoid and getgenv().OriginalHipHeight then
    humanoid.HipHeight = getgenv().OriginalHipHeight
end
end

-- Flight Toggle
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

uhhh:AddToggle("LongNeckToggle", {
Text = "Long Neck",
Default = false,
Callback = function(state)
    getgenv().LongNeckEnabled = state
    if state then
        EnableLongNeck()
    else
        DisableLongNeck()
    end
end
}):AddKeyPicker("LongNeckKeybindPicker", {
Default = "C",
Text = "Long Neck",
Mode = "Toggle",
Callback = function(state)
    if UserInputService:GetFocusedTextBox() then return end
    getgenv().LongNeckEnabled = state
    if state then
        EnableLongNeck()
    else
        DisableLongNeck()
    end
end
})

-- Long Neck Height Slider
uhhh:AddSlider("LongNeckSlider", {
Text = "Long Neck Height",
Default = 2,
Min = 2,
Max = 3,
Rounding = 1,
Callback = function(value)
    getgenv().LongNeckHeight = value
    if getgenv().LongNeckEnabled then
        EnableLongNeck()
    end
end
})

uhhh:AddSlider("FlySpeedSlider", {
    Text = "Fly Speed",
    Default = 10,
    Min = 10,
    Max = 30,
    Rounding = 0,
    Callback = function(value)
        getgenv().FlySpeed = value
    end
})

uhhh:AddToggle('No Jump Cooldown', {
    Text = 'No Jump Cooldown',
    Default = false,
    Tooltip = 'Disables jump cooldown',
    Callback = function(v)
        allvars.nojumpcd = v
        startnojumpcd()
    end
})

uhhh:AddToggle('Double jump', {
    Text = 'Double jump',
    Default = false,
    Tooltip = 'Double jump',
    Callback = function(v)
        allvars.doublejump = v
    end
})



-- Improved resolver heartbeat
runs.Heartbeat:Connect(function(dt)
    if aimresolver and localplayer.Character and localplayer.Character.HumanoidRootPart then
        local char = localplayer.Character
        local hrp = char.HumanoidRootPart
        
        if not aimresolver_originalCF then
            aimresolver_originalCF = hrp.CFrame
            aimresolver_originalVel = hrp.AssemblyLinearVelocity
        end
        
        local mult = CFrame.new(0, -15, 0)
        if aimresolverhh then 
            mult = CFrame.new(0, 500, 0) 
        end
        
        hrp.CanCollide = false
        char.UpperTorso.CanCollide = false
        char.LowerTorso.CanCollide = false
        char.Head.CanCollide = false
        
        hrp.AssemblyLinearVelocity = -mult.Position
        char:PivotTo(aimresolverpos * mult)
    elseif aimresolver_originalCF then
        -- Restore original state when resolver ends
        local hrp = localplayer.Character.HumanoidRootPart
        hrp.CanCollide = true
        hrp.CFrame = aimresolver_originalCF
        hrp.AssemblyLinearVelocity = aimresolver_originalVel
        
        aimresolver_originalCF = nil
        aimresolver_originalVel = nil
    end
end)

uhhh:AddToggle('ActivateResolver',{
    Text = "Activate",
    Default = false,
   Tooltip = "Activates resolver",
    Callback = function(v)
       allvars.resolvers = v
    end
}):AddKeyPicker('ResolverToggle', {
    Default = 'P',
    Mode = 'Toggle', --Always, Toggle, Hold
    Text = 'Resolver',
    NoUI = false, 
})

uhhh:AddToggle('Desync', {
    Text = 'Desync',
    Default = false,
    Tooltip = 'Enables desync',
    Callback = function(v)
        allvars.desyncbool = v

        if v then
            desyncvis = Instance.new("Part", workspace)
            desyncvis.Name = "DesyncVisual"
            desyncvis.Anchored = true
            desyncvis.CanQuery = false
            desyncvis.CanCollide = false
            desyncvis.Size = Vector3.new(4,5,1)
            desyncvis.Color = desynccolor
            desyncvis.Material = Enum.Material.Neon
            desyncvis.Transparency = visdesync == true and 1 or desynctrans
            desyncvis.TopSurface = Enum.SurfaceType.Hinge
    
            while allvars.desyncbool do
                task.wait(0.01)
            end
    
            localplayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
    
            desyncvis:Destroy()
            desyncvis = nil
        end
    end
}):AddKeyPicker('H', {
    Default = 'H',
    Mode = 'Toggle',
    Text = 'Desync',
    NoUI = false,
})

runs.Heartbeat:Connect(function(delta) --desync
    if aimresolver then return end

    if allvars.desyncbool and localplayer.Character and localplayer.Character:FindFirstChild("HumanoidRootPart") then
        if localplayer.Character.Humanoid.Health <= 0 then return end
        if (tick() - characterspawned) < 1 then return end
    
        -- Store original position and velocity
        desynctable[1] = localplayer.Character.HumanoidRootPart.CFrame
        desynctable[2] = localplayer.Character.HumanoidRootPart.AssemblyLinearVelocity
        
        local cf = localplayer.Character.HumanoidRootPart.CFrame
        local posoffset, rotoffset, spoofedcf
        
        -- Determine which desync mode to use
        if allvars.invisbool and invistrack then 
            -- Underground mode (Force Underground toggle)
            invistrack:Stop()
            invistrack = localplayer.Character.Humanoid.Animator:LoadAnimation(invisanim)
            invistrack:Play(.01, 1, 0)
            invistrack.TimePosition = invisnum

            posoffset = Vector3.new(0, -2.55, 0)
            rotoffset = Vector3.new(90, 0, 0)
            
        elseif allvars.resolvers then 
            -- Resolver mode (deeper underground)
            if not invistrack then
                invistrack = localplayer.Character.Humanoid.Animator:LoadAnimation(invisanim)
            end
            invistrack:Stop()
            invistrack:Play(.01, 1, 0)
            invistrack.TimePosition = invisnum

            posoffset = Vector3.new(0, -6.55, 0)
            rotoffset = Vector3.new(90, 0, 0)
            
        else 
            -- Default desync mode
            posoffset = allvars.desyncPos and Vector3.new(allvars.desynXp, allvars.desynYp, allvars.desynZp) or Vector3.new(0, 0, 0)
            rotoffset = allvars.desyncOr and Vector3.new(allvars.desynXo, allvars.desynYo, allvars.desynZo) or Vector3.new(0, 0, 0)
        end
        
        -- Apply the desync transformation
        spoofedcf = cf
            * CFrame.new(posoffset) 
            * CFrame.Angles(math.rad(rotoffset.X), math.rad(rotoffset.Y), math.rad(rotoffset.Z))
        desynctable[3] = spoofedcf

        -- Perform the desync
        localplayer.Character.HumanoidRootPart.CFrame = spoofedcf
        runs.RenderStepped:Wait()
        localplayer.Character.HumanoidRootPart.CFrame = desynctable[1]
        localplayer.Character.HumanoidRootPart.AssemblyLinearVelocity = desynctable[2]
    end
end)
localplayer.CharacterAdded:Connect(function()
    characterspawned = tick()
    if allvars.invisbool then
        invistrack = localplayer.Character.Humanoid.Animator:LoadAnimation(invisanim)
        if allvars.desyncbool then
            invistrack:Play(.01, 1, 0)
        end
    end
end)
local camera = workspace.CurrentCamera
local originalFOV = camera.FieldOfView
local protectedFOV = originalFOV
local zoomEnabled = false
local connection

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local minWalkSpeed = 18
local noSlowdownEnabled = false
local walkSpeedConnection

-- Function to protect FOV from external changes
local function protectFOV()
    if connection then
        connection:Disconnect()
    end
    
    connection = camera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
        if camera.FieldOfView ~= protectedFOV then
            camera.FieldOfView = protectedFOV
        end
    end)
end

-- Function to handle zoom toggle
local function toggleZoom(enabled)
    zoomEnabled = enabled
    
    -- Always protect FOV regardless of zoom state
    protectFOV()
    
    if enabled then
        -- Zoom in (low FOV for seeing far away)
        protectedFOV = 20 -- Low FOV = zoomed in
        camera.FieldOfView = protectedFOV
    else
        -- Zoom out (back to normal FOV)
        protectedFOV = originalFOV
        camera.FieldOfView = originalFOV
    end
end

-- Function to protect walkspeed from going below minimum
local function protectWalkSpeed()
    if walkSpeedConnection then
        walkSpeedConnection:Disconnect()
    end
    
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            walkSpeedConnection = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                if noSlowdownEnabled and humanoid.WalkSpeed < minWalkSpeed then
                    humanoid.WalkSpeed = minWalkSpeed
                end
            end)
        end
    end
end

-- Function to toggle no slowdown
local function toggleNoSlowdown(enabled)
    noSlowdownEnabled = enabled
    
    if enabled then
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                -- Set initial walkspeed to minimum if it's below
                if humanoid.WalkSpeed < minWalkSpeed then
                    humanoid.WalkSpeed = minWalkSpeed
                end
                -- Start protecting walkspeed
                protectWalkSpeed()
            end
        end
    else
        -- Stop protecting walkspeed
        if walkSpeedConnection then
            walkSpeedConnection:Disconnect()
            walkSpeedConnection = nil
        end
    end
end

-- Complete FOV System with CameraSystem integration
local CameraSystem = require(game:GetService("ReplicatedStorage").Modules.CameraSystem)
local RunService = game:GetService("RunService")

-- FOV Variables
local baseFOV = 100
local zoomFOV = 15
local fovConnection = nil
local renderConnection = nil
local isZooming = false
local customFOVEnabled = true

-- Override the CameraSystem module functions
local originalSetZoomTarget = CameraSystem.SetZoomTarget
local originalSetSprintTarget = CameraSystem.SetSprintTarget
local originalSetDialogueTarget = CameraSystem.SetDialogueTarget

-- Function to apply custom FOV
local function applyCustomFOV()
    local targetFOV = isZooming and zoomFOV or baseFOV
    local camera = workspace.CurrentCamera
    if camera and customFOVEnabled then
        camera.FieldOfView = targetFOV
    end
end

-- Function to start aggressive FOV locking
local function startFOVLock()
    -- Stop existing connections
    if fovConnection then fovConnection:Disconnect() end
    if renderConnection then renderConnection:Disconnect() end
    
    if customFOVEnabled then
        -- Heartbeat connection for normal FOV enforcement
        fovConnection = RunService.Heartbeat:Connect(function()
            applyCustomFOV()
        end)
        
        -- RenderStepped connection for extra aggressive enforcement
        renderConnection = RunService.RenderStepped:Connect(function()
            applyCustomFOV()
        end)
    end
end

-- Function to stop FOV lock
local function stopFOVLock()
    if fovConnection then
        fovConnection:Disconnect()
        fovConnection = nil
    end
    if renderConnection then
        renderConnection:Disconnect()
        renderConnection = nil
    end
end

-- Function to toggle custom FOV system
local function toggleCustomFOV(enabled)
    customFOVEnabled = enabled
    
    if enabled then
        startFOVLock()
        
        -- Override CameraSystem functions to prevent game FOV changes
        CameraSystem.SetZoomTarget = function(self, p23, p24, p25, p26, p27)
            -- Do nothing - block game zoom FOV changes
        end
        
        CameraSystem.SetSprintTarget = function(self, p28, p29, p30, p31, p32)
            -- Do nothing - block game sprint FOV changes
        end
        
        CameraSystem.SetDialogueTarget = function(self, p33, p34, p35, p36, p37)
            -- Do nothing - block game dialogue FOV changes
        end
    else
        stopFOVLock()
        
        -- Restore original CameraSystem functions
        CameraSystem.SetZoomTarget = originalSetZoomTarget
        CameraSystem.SetSprintTarget = originalSetSprintTarget
        CameraSystem.SetDialogueTarget = originalSetDialogueTarget
    end
end

-- Function to toggle zoom
local function toggleZoom(enabled)
    isZooming = enabled
    if customFOVEnabled then
        applyCustomFOV()
    end
end

-- Initialize with custom FOV enabled
toggleCustomFOV(true)

-- Block the game's DefaultFOV attribute changes
local player = game.Players.LocalPlayer
local settings = game.ReplicatedStorage.Players:WaitForChild(player.Name):WaitForChild("Settings"):WaitForChild("GameplaySettings")

-- Override the attribute change signal
settings:GetAttributeChangedSignal("DefaultFOV"):Connect(function()
    if customFOVEnabled then
        -- Block the game's FOV change by immediately applying our custom FOV
        task.wait()
        applyCustomFOV()
    end
end)

-- === UI ELEMENTS ===

-- Custom FOV Enable/Disable Toggle
Others:AddToggle('Custom FOV', {
    Text = 'Custom FOV',
    Default = true,
    Tooltip = 'Enables custom FOV system (overrides game FOV completely)',
    Callback = function(v)
        toggleCustomFOV(v)
    end
})

-- Base FOV Slider
Others:AddSlider('FOV', {
    Text = 'FOV',
    Default = 100,
    Min = 10,
    Max = 120,
    Rounding = 0,
    Compact = false,
    Callback = function(c)
        baseFOV = c
        allvars.basefov = c
        if customFOVEnabled and not isZooming then
            applyCustomFOV()
        end
    end
})

-- Zoom FOV Slider
Others:AddSlider('Zoom FOV', {
    Text = 'Zoom FOV',
    Default = 15,
    Min = 0,
    Max = 50,
    Rounding = 0,
    Compact = false,
    Callback = function(c)
        zoomFOV = c
        allvars.zoomfov = c
        if customFOVEnabled and isZooming then
            applyCustomFOV()
        end
    end
})

-- Zoom Toggle
Others:AddToggle('Zoom', {
    Text = 'Zoom',
    Default = false,
    Tooltip = 'Activates zoom using Zoom FOV value',
    Callback = function(v)
        toggleZoom(v)
    end
}):AddKeyPicker('Zoom', {
    Default = 'Z',
    SyncToggleState = true,
    Mode = 'Toggle',
    Text = 'Zoom',
    NoUI = false,
})


-- Protect against camera changes
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if customFOVEnabled then
        task.wait()
        applyCustomFOV()
    end
end)

workspace.CurrentCamera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
    if customFOVEnabled then
        local targetFOV = isZooming and zoomFOV or baseFOV
        if workspace.CurrentCamera.FieldOfView ~= targetFOV then
            workspace.CurrentCamera.FieldOfView = targetFOV
        end
    end
end)



local ThirdPerson = {
    Enabled = false,
    Connection = nil
}

local function enableThirdPerson()
    -- Force settings
    player.CameraMode = Enum.CameraMode.Classic
    player.CameraMinZoomDistance = 0.5
    player.CameraMaxZoomDistance = 400
    
    -- Monitor and prevent first person
    ThirdPerson.Connection = player:GetPropertyChangedSignal("CameraMode"):Connect(function()
        if player.CameraMode == Enum.CameraMode.LockFirstPerson then
            player.CameraMode = Enum.CameraMode.Classic
        end
    end)
end

local function disableThirdPerson()
    if ThirdPerson.Connection then
        ThirdPerson.Connection:Disconnect()
        ThirdPerson.Connection = nil
    end
    -- Reset to default camera behavior
    player.CameraMode = Enum.CameraMode.Classic
end

-- Toggle setup
Others:AddToggle('ThirdPerson', {
    Text = 'Third Person BETA',
    Default = false,
    Tooltip = 'Forces third person camera view',
    Callback = function(state)
        ThirdPerson.Enabled = state
        if state then
            enableThirdPerson()
        else
            disableThirdPerson()
        end
    end
}):AddKeyPicker('F', {
    Default = 'J',
    Mode = 'Toggle',
    Text = 'ThirdPerson',
    NoUI = false,
})

Others:AddToggle('nofall', {
    Text = 'nofall',
    Default = false,
    Tooltip = 'Enables nofall',
    Callback = function(v)
        allvars.nofall = v
    end
})

-- New No Slowdown toggle
Others:AddToggle('No Slowdown', {
    Text = 'No Slowdown',
    Default = false,
    Tooltip = 'Prevents walkspeed from going below 18',
    Callback = function(v)
        toggleNoSlowdown(v)
    end
})

LocalPlayer.CharacterAdded:Connect(function()
    wait(1)
    getgenv().OriginalHipHeight = nil
    if getgenv().LongNeckEnabled then
        EnableLongNeck()
    end
    
    -- Re-enable no slowdown protection when character respawns
    if noSlowdownEnabled then
        wait(0.5) -- Small delay to ensure humanoid is loaded
        toggleNoSlowdown(true)
    end
end)

local originalFire
originalFire = hookfunction(game.ReplicatedStorage.Remotes.FireProjectile.InvokeServer, function(...)
    local args = {...}
    if Tracers.Enabled and args[2] then -- args[2] is direction vector
        local gunModel = LocalPlayer.Character:FindFirstChildOfClass("Model")
        if gunModel and gunModel:FindFirstChild("ItemRoot") then
            local startPos = gunModel.ItemRoot.Position
            local endPos = startPos + (args[2] * 500) -- Extend 500 studs
            
            -- Create tracer asynchronously
            task.spawn(CreateTracer, startPos, endPos)
        end
    end
    return originalFire(...)
end)

-- Network Desync Logic
RunService.Heartbeat:Connect(function(deltaTime)
    if networkDesync and networkDesync.enabled then
        networkDesync.networkTimer = networkDesync.networkTimer + deltaTime
        if networkDesync.networkTimer >= networkDesync.networkDelay then
            networkDesync.networkTimer = 0
            performNetworkDesync()
        end
    end
end)

-- Fake Position Logic
RunService.RenderStepped:Connect(function()
    -- Check if fakePosition exists and is enabled
    if fakePosition and fakePosition.enabled then
        applyFakePosition()
    end
end)

instrelMODfunc = function(a1,a2)
    local function aaa(a1)
        local v27_2_ = a1.weapon
        local v27_1_ = v27_2_.Attachments
        local v27_3_ = "Magazine"
        v27_1_ = v27_1_:FindFirstChild(v27_3_)
        if v27_1_ then
            local v27_4_ = a1.weapon
            v27_3_ = v27_4_.Attachments
            v27_2_ = v27_3_.Magazine
            v27_2_ = v27_2_:GetChildren()
            v27_1_ = v27_2_[-1]
            if v27_1_ then
                v27_2_ = v27_1_.ItemProperties
                v27_4_ = "LoadedAmmo"
                v27_2_ = v27_2_:GetAttribute(v27_4_)
                a1.Bullets = v27_2_
                v27_2_ = {}
                a1.BulletsList = v27_2_
                v27_3_ = v27_1_.ItemProperties
                v27_2_ = v27_3_.LoadedAmmo
                v27_3_ = v27_2_:GetChildren()
                local v27_6_ = 1
                v27_4_ = #v27_3_
                local v27_5_ = 1
                for v27_6_ = v27_6_, v27_4_, v27_5_ do
                    local v27_7_ = a1.BulletsList
                    local v27_10_ = v27_3_[v27_6_]
                    local v27_9_ = v27_10_.Name
                    local v27_8_ = tonumber
                    v27_8_ = v27_8_(v27_9_)
                    v27_9_ = {}
                    v27_10_ = v27_3_[v27_6_]
                    local v27_12_ = "AmmoType"
                    v27_10_ = v27_10_:GetAttribute(v27_12_)
                    v27_9_.AmmoType = v27_10_
                    v27_10_ = v27_3_[v27_6_]
                    v27_12_ = "Amount"
                    v27_10_ = v27_10_:GetAttribute(v27_12_)
                    v27_9_.Amount = v27_10_
                    v27_7_[v27_8_] = v27_9_
                end
            end
            v27_2_ = 0
            a1.movementModifier = v27_2_
            v27_2_ = a1.weapon
            if v27_2_ then
                v27_2_ = a1.movementModifier
                local v27_6_ = a1.weapon
                local v27_5_ = v27_6_.ItemProperties
                v27_4_ = v27_5_.Tool
                v27_6_ = "MovementModifer"
                v27_4_ = v27_4_:GetAttribute(v27_6_)
                v27_3_ = v27_4_ or 0.000000
                v27_2_ += v27_3_
                a1.movementModifier = v27_2_
                v27_2_ = a1.weapon
                v27_4_ = "Attachments"
                v27_2_ = v27_2_:FindFirstChild(v27_4_)
                if v27_2_ then
                    v27_3_ = a1.weapon
                    v27_2_ = v27_3_.Attachments
                    v27_2_ = v27_2_:GetChildren()
                    v27_5_ = 1
                    v27_3_ = #v27_2_
                    v27_4_ = 1
                    for v27_5_ = v27_5_, v27_3_, v27_4_ do
                        v27_6_ = v27_2_[v27_5_]
                        local v27_8_ = "StringValue"
                        v27_6_ = v27_6_:FindFirstChildOfClass(v27_8_)
                        if v27_6_ then
                            local v27_7_ = v27_6_.ItemProperties
                            local v27_9_ = "Attachment"
                            v27_7_ = v27_7_:FindFirstChild(v27_9_)
                            if v27_7_ then
                                v27_7_ = a1.movementModifier
                                local v27_10_ = v27_6_.ItemProperties
                                v27_9_ = v27_10_.Attachment
                                local v27_11_ = "MovementModifer"
                                v27_9_ = v27_9_:GetAttribute(v27_11_)
                                v27_8_ = v27_9_ or 0.000000
                                v27_7_ += v27_8_
                                a1.movementModifier = v27_7_
                            end
                        end
                        return
                    end
                end
            end
        end
        v27_2_ = a1.weapon
        v27_1_ = v27_2_.ItemProperties
        v27_3_ = "LoadedAmmo"
        v27_1_ = v27_1_:GetAttribute(v27_3_)
        a1.Bullets = v27_1_
        v27_1_ = {}
        a1.BulletsList = v27_1_
        v27_3_ = a1.weapon
        v27_2_ = v27_3_.ItemProperties
        v27_1_ = v27_2_.LoadedAmmo
        v27_2_ = v27_1_:GetChildren()
        local v27_5_ = 1
        v27_3_ = #v27_2_
        local v27_4_ = 1
        for v27_5_ = v27_5_, v27_3_, v27_4_ do
            local v27_6_ = a1.BulletsList
            local v27_9_ = v27_2_[v27_5_]
            local v27_8_ = v27_9_.Name
            local v27_7_ = tonumber
            v27_7_ = v27_7_(v27_8_)
            v27_8_ = {}
            v27_9_ = v27_2_[v27_5_]
            local v27_11_ = "AmmoType"
            v27_9_ = v27_9_:GetAttribute(v27_11_)
            v27_8_.AmmoType = v27_9_
            v27_9_ = v27_2_[v27_5_]
            v27_11_ = "Amount"
            v27_9_ = v27_9_:GetAttribute(v27_11_)
            v27_8_.Amount = v27_9_
            v27_6_[v27_7_] = v27_8_
        end
    end
    local v103_2_ = a1.viewModel
    if v103_2_ then
        local v103_3_ = a1.viewModel
        v103_2_ = v103_3_.Item
        local v103_4_ = "AmmoTypes"
        v103_2_ = v103_2_:FindFirstChild(v103_4_)
        if v103_2_ then
            local v103_5_ = a1.weapon
            v103_4_ = v103_5_.ItemProperties
            v103_3_ = v103_4_.AmmoType
            v103_2_ = v103_3_.Value
            v103_5_ = a1.viewModel
            v103_4_ = v103_5_.Item
            v103_3_ = v103_4_.AmmoTypes
            v103_3_ = v103_3_:GetChildren()
            local v103_6_ = 1
            v103_4_ = #v103_3_
            v103_5_ = 1
            for v103_6_ = v103_6_, v103_4_, v103_5_ do
                local v103_7_ = v103_3_[v103_6_]
                local v103_8_ = 1
                v103_7_.Transparency = v103_8_
            end
            v103_6_ = a1.viewModel
            v103_5_ = v103_6_.Item
            v103_4_ = v103_5_.AmmoTypes
            v103_6_ = v103_2_
            v103_4_ = v103_4_:FindFirstChild(v103_6_)
            v103_5_ = 0
            v103_4_.Transparency = v103_5_
            v103_5_ = a1.viewModel
            v103_4_ = v103_5_.Item
            v103_6_ = "AmmoTypes2"
            v103_4_ = v103_4_:FindFirstChild(v103_6_)
            if v103_4_ then
                v103_6_ = a1.viewModel
                v103_5_ = v103_6_.Item
                v103_4_ = v103_5_.AmmoTypes2
                v103_4_ = v103_4_:GetChildren()
                local v103_7_ = 1
                v103_5_ = #v103_4_
                v103_6_ = 1
                for v103_7_ = v103_7_, v103_5_, v103_6_ do
                    local v103_8_ = v103_4_[v103_7_]
                    local v103_9_ = 1
                    v103_8_.Transparency = v103_9_
                end
                v103_7_ = a1.viewModel
                v103_6_ = v103_7_.Item
                v103_5_ = v103_6_.AmmoTypes2
                v103_7_ = v103_2_
                v103_5_ = v103_5_:FindFirstChild(v103_7_)
                v103_6_ = 0
                v103_5_.Transparency = v103_6_
            end
        end
        v103_2_ = a1.reloading
        if v103_2_ == false then
            v103_2_ = a1.cancellingReload
            if v103_2_ == false then
                v103_2_ = a1.MaxAmmo
                v103_3_ = 0
                if v103_3_ < v103_2_ then
                    v103_3_ = true
                    local v103_6_ = 1
                    local v103_7_ = a1.CancelTables
                    v103_4_ = #v103_7_
                    local v103_5_ = 1
                    for v103_6_ = v103_6_, v103_4_, v103_5_ do
                        local v103_9_ = a1.CancelTables
                        local v103_8_ = v103_9_[v103_6_]
                        v103_7_ = v103_8_.Visible
                        if v103_7_ == true then
                            v103_3_ = false
                        else
                        end
                    end
                    v103_2_ = v103_3_
                    if v103_2_ then
                        v103_3_ = a1.clientAnimationTracks
                        v103_2_ = v103_3_.Inspect
                        if v103_2_ then
                            v103_3_ = a1.clientAnimationTracks
                            v103_2_ = v103_3_.Inspect
                            v103_2_:Stop()
                            v103_3_ = a1.serverAnimationTracks
                            v103_2_ = v103_3_.Inspect
                            v103_2_:Stop()
                            v103_4_ = a1.WeldedTool
                            v103_3_ = v103_4_.ItemRoot
                            v103_2_ = v103_3_.Sounds.Inspect
                            v103_2_:Stop()
                        end
                        v103_3_ = a1.settings
                        v103_2_ = v103_3_.AimWhileActing
                        if not v103_2_ then
                            v103_2_ = a1.isAiming
                            if v103_2_ then
                                v103_4_ = false
                                a1:aim(v103_4_)
                            end
                        end
                        
                        if a1.reloadType == "loadByHand" then
                            local count = a1.Bullets
                            local maxcount = a1.MaxAmmo

                            for i=count, maxcount do 
                                game.ReplicatedStorage.Remotes.Reload:InvokeServer(nil, 0.001, nil)
                            end

                            aaa(a1)
                        else
                            game.ReplicatedStorage.Remotes.Reload:InvokeServer(nil, 0.001, nil)

                            require(game.ReplicatedStorage.Modules.FPS).equip(a1, a1.weapon, nil)

                            aaa(a1)
                        end      
                    end
                end
            end
        end
    end
end

-- Initialize FOV Circle
createFovCircle()

do
    local mod = require(game.ReplicatedStorage.Modules.FPS)
    local ogfunc = mod.updateClient

    mod.updateClient = function(a1,a2,a3)
        arg1, arg2, arg3 = ogfunc(a1,a2,a3)
        
        a1table = a1

        if nojumptilt then
            a1.springs.jumpCameraTilt.Position = Vector3.new(0,0,0)
        end
        if allvars.noswaybool then
            a1.springs.sway.Position = Vector3.new(0,0,0)
            a1.springs.walkCycle.Position = Vector3.new(0,0,0)
            a1.springs.sprintCycle.Position = Vector3.new(0,0,0)
            a1.springs.strafeTilt.Position = Vector3.new(0,0,0)
            a1.springs.jumpTilt.Position = Vector3.new(0,0,0)
            a1.springs.sway.Speed = 0
            a1.springs.walkCycle.Speed = 0
            a1.springs.sprintCycle.Speed = 0
            a1.springs.strafeTilt.Speed = 0
            a1.springs.jumpTilt.Speed = 0
        else
            a1.springs.sway.Speed = 4
            a1.springs.walkCycle.Speed = 4
            a1.springs.sprintCycle.Speed = 4
            a1.springs.strafeTilt.Speed = 4
            a1.springs.jumpTilt.Speed = 4
        end
        if allvars.viewmodoffset then
            a1.sprintIdleOffset = CFrame.new(Vector3.new(allvars.viewmodX, allvars.viewmodY, allvars.viewmodZ))
            a1.weaponOffset = CFrame.new(Vector3.new(allvars.viewmodX, allvars.viewmodY, allvars.viewmodZ))
            a1.AimInSpeed = 9e9
        else
            a1.AimInSpeed = 0.4
        end

        return arg1, arg2, arg3
    end
end

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
                    
                    -- Get target position with distance-based prediction
                    local targetVelocity = Vector3.new(0, 0, 0)
                    if humanoid.RootPart then
                        targetVelocity = humanoid.RootPart.Velocity
                    end
                    
                    local distance = (targetPart.Position - currentCFrame.Position).Magnitude
                    
                    local adjustedPrediction
                    if distance <= 30 then
                        adjustedPrediction = 0
                    else
                        local distanceScale = math.min((distance - 20) / 190, 2.5) -- Scale from 0 to 2 between 10m-200m
                        adjustedPrediction = prediction * distanceScale
                    end
                    
                    local targetPosition = targetPart.Position + (targetVelocity * adjustedPrediction)
                    
                    -- Calculate Y elevation based on distance (0.1 per 150 meters)
                    local yElevation = (distance / 350) * 0.2
                    targetPosition = targetPosition + Vector3.new(0, yElevation, 0)
                    
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
end)

runs.Heartbeat:Connect(function(delta) --blink
    if blinkbool and localplayer.Character and localplayer.Character.HumanoidRootPart then
        local hrp = localplayer.Character.HumanoidRootPart

        if blinkstop and localplayer.Character.Humanoid.MoveDirection.Magnitude == 0 then return end
        if blinknoclip then
            localplayer.Character.HumanoidRootPart.CanCollide = false
            localplayer.Character.Head.CanCollide = false
            localplayer.Character.UpperTorso.CanCollide = false
            localplayer.Character.LowerTorso.CanCollide = false
            workspace.Gravity = 0.1
        end
        blinktable[1] = hrp.CFrame
        blinktable[2] = hrp.AssemblyLinearVelocity

        if aimresolver then return end

        if not blinktemp then
            hrp.Anchored = true
            blinktable[3] = hrp.CFrame
            runs.RenderStepped:Wait()
            hrp.Anchored = false
            hrp.CFrame = blinktable[1]
            hrp.AssemblyLinearVelocity = blinktable[2]
        else
            hrp.CFrame = blinktable[1]
        end
    elseif blinknoclip and localplayer.Character and localplayer.Character.HumanoidRootPart then
        localplayer.Character.HumanoidRootPart.CanCollide = true
        localplayer.Character.Head.CanCollide = true
        localplayer.Character.UpperTorso.CanCollide = true
        localplayer.Character.LowerTorso.CanCollide = true
    end
end)
runs.RenderStepped:Connect(function(delta) -- global fast
    if not localplayer.Character or not localplayer.Character:FindFirstChild("HumanoidRootPart") or not localplayer.Character:FindFirstChild("Humanoid") then
        return
    end


    if allvars.desyncbool and allvars.invisbool then
        if not aimresolver then
            local vel = localplayer.Character.HumanoidRootPart.AssemblyLinearVelocity
            local newvel = Vector3.new(vel.X, math.clamp(vel.Y, -99999, 19), vel.Z)
            localplayer.Character.HumanoidRootPart.AssemblyLinearVelocity = newvel
        end
    elseif invistrack then
        invistrack:Stop()
        invistrack:Destroy()
    end


    if desyncvis and desynctable[3] then
        desyncvis.CFrame = desynctable[3] * CFrame.new(0, -0.7, 0)
        localplayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    end


    --no swim--
    if noswim then
        localplayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
    else
        localplayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
    end
    


    --nofall method by ds: _hai_hai
    local humstate = localplayer.Character.Humanoid:GetState()
    if allvars.nofall and (humstate == Enum.HumanoidStateType.FallingDown or humstate == Enum.HumanoidStateType.Freefall) and localplayer.Character.HumanoidRootPart.AssemblyLinearVelocity.Y < -30 then 
        localplayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Landed)

        if allvars.instafall and aimresolver == false then 
            local rparams = RaycastParams.new()
            rparams.IgnoreWater = false
            rparams.FilterDescendantsInstances = {
                localplayer.Character
            }
            local fray = workspace:Raycast(localplayer.Character.HumanoidRootPart.Position, Vector3.new(0, -400, 0), rparams)
            if fray then
                localplayer.Character.HumanoidRootPart.CFrame = CFrame.new(fray.Position + Vector3.new(0, 3, 0))
            end
        end
    end


    local nil1, nil2, newglobalcurrentgun = getcurrentgun(localplayer)
    globalcurrentgun = newglobalcurrentgun
    globalammo = getcurrentammo(globalcurrentgun)


    if ACBYPASS_SYNC == true and allvars.changerbool then
        localplayer.Character.Humanoid.WalkSpeed = allvars.changerspeed
        localplayer.Character.Humanoid.JumpHeight = allvars.changerjump
        localplayer.Character.Humanoid.HipHeight = allvars.changerheight
        workspace.Gravity = allvars.changergrav
    end


    if charsemifly and localplayer.Character and ACBYPASS_SYNC == true then --semifly
        local hrp = localplayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local dir = Vector3.new(0, 0, 0)

		if uis:IsKeyDown(Enum.KeyCode.W) then
			dir += wcamera.CFrame.LookVector
		elseif uis:IsKeyDown(Enum.KeyCode.S) then
			dir -= wcamera.CFrame.LookVector
		end

		if uis:IsKeyDown(Enum.KeyCode.A) then
			dir -= wcamera.CFrame.RightVector
		elseif uis:IsKeyDown(Enum.KeyCode.D) then
			dir += wcamera.CFrame.RightVector
		end

		if uis:IsKeyDown(Enum.KeyCode.Space) then
			dir += Vector3.new(0, 1, 0)
		elseif uis:IsKeyDown(Enum.KeyCode.LeftShift) then
			dir -= Vector3.new(0, 1, 0)
		end

		local closest = fly_getclosestpoint()
		if closest then
			local d = (hrp.Position - closest).Magnitude
			if d > allvars.charsemiflydist then
				local ldir = (hrp.Position - closest).Unit * allvars.charsemiflydist
				local offset = fly_getoffset(ldir)
				hrp.CFrame = CFrame.new(closest + ldir - offset)
			else
				fly_move(dir * allvars.charsemiflyspeed * runs.RenderStepped:Wait(), delta)
			end
		else
			fly_move(dir * allvars.charsemiflyspeed * runs.RenderStepped:Wait(), delta)
		end
    end

    if allvars.aimdynamicfov then -- fov changer
        aimfovcircle.Radius = allvars.aimfov * (80 / wcamera.FieldOfView )
    else
        aimfovcircle.Radius = allvars.aimfov
    end

    aimfovcircle.Position = Vector2.new(wcamera.ViewportSize.X / 2, wcamera.ViewportSize.Y / 2)
    aimfovcircle.Color = allvars.aimfovcolor
    if scgui then
        scgui.Position = Window.Holder.Position + UDim2.new(0.16, 0, 0, 0)
        scgui.Visible = scbool and Window.Holder.Visible or false
    end
end)

LocalPlayer.CharacterAdded:Connect(function(character)
    if not fovCircle then
        createFovCircle()
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if camLockTarget == player then
        camLockTarget = nil
    end
end)

local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')

MenuGroup:AddButton('Unload', function() 
    if fovCircle then
        fovCircle:Remove()
    end
    Library:Unload() 
end)

MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { 
    Default = 'End', 
    NoUI = true, 
    Text = 'Menu keybind' 
})

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })

ThemeManager:SetFolder('EnhancedScript')
SaveManager:SetFolder('EnhancedScript/configs')

SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])

SaveManager:LoadAutoloadConfig()
