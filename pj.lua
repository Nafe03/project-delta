if not LPH_OBFUSCATED then
    LPH_JIT            = function(f) return f end
    LPH_JIT_MAX        = function(f) return f end
    LPH_NO_VIRTUALIZE  = function(f) return f end
    LPH_NO_UPVALUES    = function(f) return function(...) return f(...) end end
    LPH_ENCSTR         = function(s) return s end
    LPH_ENCNUM         = function(n) return n end
    LPH_CRASH          = function() return print("DEBUG: CRASH CALLED") end
end

if not getgenv       then getgenv       = function() return _G end end
if not cloneref      then cloneref      = function(r) return r  end end
if not clonefunction then clonefunction = function(f) return f  end end
if not newcclosure   then newcclosure   = function(f) return f  end end
if not hookfunction  then hookfunction  = function(o, n) return o end end
if not hookmetamethod then hookmetamethod = function(o, m, n) return n end end
if not getrenv       then getrenv       = function() return {} end end
if not getsenv       then getsenv       = function(s) return {} end end
if not getnilinstances then getnilinstances = function() return {} end end

-- ── Services ──────────────────────────────────────────
local UILibrary       = loadstring(game:HttpGetAsync(
    "https://raw.githubusercontent.com/Nafe03/Zest-Hub/refs/heads/main/ui3.lua"))()

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting          = game:GetService("Lighting")
local TweenService      = game:GetService("TweenService")
local SoundService      = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local chr         = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local hum         = chr:WaitForChild("Humanoid")
local Camera      = workspace.CurrentCamera
SlowDown    = false
Spin        = false
local SpinSpeed   = 5
nofall      = false
noJumpCooldown = false
local root        = LocalPlayer.Character.HumanoidRootPart
random      = false
lastGrass    = nil
lastLeaves   = nil
Extrakt = workspace.NoCollision.ExitLocations
local DropedItems = workspace.DroppedItems
local WeaponFodler = game:GetService("ReplicatedStorage").RangedWeapons
local AmmoFolder = game:GetService("ReplicatedStorage").AmmoTypes
local gunModDirty = true  -- force first apply

-- ── Item ESP name lookup tables (built once at load) ──
local WeaponNames = {}
local AmmoNames   = {}
pcall(function()
    for _, c in pairs(WeaponFodler:GetChildren()) do WeaponNames[c.Name] = true end
end)
pcall(function()
    for _, c in pairs(AmmoFolder:GetChildren()) do AmmoNames[c.Name] = true end
end)

getgenv().ItemESP = getgenv().ItemESP or {
    WeaponESP    = false,
    AmmoESP      = false,
    JunkESP      = false,
    WeaponColor  = Color3.fromRGB(165, 127, 159),
    AmmoColor    = Color3.fromRGB(165, 127, 159),
    JunkColor    = Color3.fromRGB(165, 127, 159),
}
getgenv().PlayerWeaponESP = getgenv().PlayerWeaponESP or {
    Hip           = false,
    Prime         = false,
    Equipped      = false,
    EquippedMode  = "Text",   -- "Text" or "Image"
    HipColor      = Color3.fromRGB(165, 127, 159),
    PrimeColor    = Color3.fromRGB(165, 127, 159),
    EquippedColor = Color3.fromRGB(255, 220, 80),
}

getgenv().NPC = getgenv().NPC or {
    Enabled     = false,
    MaxDistance = 1000,
    Box         = { Enabled = false, Color = Color3.fromRGB(165,127,159), Thickness = 2, Filled = false, FillTransparency = 0.5 },
    HealthBar   = { Enabled = false, Width = 4 },
    HealthText  = { Enabled = false, Color = Color3.fromRGB(165,127,159), Size = 12 },
    Name        = { Enabled = false, Color = Color3.fromRGB(165,127,159), Size = 14, Outline = true },
    Highlight   = { Enabled = false, FillColor = Color3.fromRGB(165,127,159), OutlineColor = Color3.fromRGB(165,127,159), FillTransparency = 0.5, OutlineTransparency = 0 },
    Font        = Enum.Font.Arcade,
}


-- ── Third Person state ───────────────────────────────
local ThirdPerson       = false
local ThirdPersonDist   = 5
local ThirdPersonHeight = 2

-- ── FreeCam state ─────────────────────────────────────
local FreeCam       = false
local FreeCamSpeed  = 20
local FreeCamPos    = Vector3.new()
local FreeCamPitch  = 0
local FreeCamYaw    = 0
local FreeCamRender = nil
local FreeCamInput  = nil
local TargetFOV     = 70

local function enableFreeCam()
    Camera = workspace.CurrentCamera
    Camera.CameraType = Enum.CameraType.Scriptable
    FreeCamPos = Camera.CFrame.Position
    local _, yaw, _ = Camera.CFrame:ToEulerAnglesYXZ()
    FreeCamYaw   = yaw
    FreeCamPitch = 0
    UserInputService.MouseBehavior   = Enum.MouseBehavior.LockCenter
    UserInputService.MouseIconEnabled = false

    FreeCamInput = UserInputService.InputChanged:Connect(function(input)
        if not FreeCam then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            FreeCamYaw   = FreeCamYaw   - math.rad(input.Delta.X * 0.35)
            FreeCamPitch = math.clamp(
                FreeCamPitch - math.rad(input.Delta.Y * 0.35),
                math.rad(-89), math.rad(89)
            )
        end
    end)

    FreeCamRender = RunService.RenderStepped:Connect(function(dt)
        if not FreeCam then return end

        -- Re-enforce every frame so Roblox can't reset it
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

        local rotCF = CFrame.Angles(0, FreeCamYaw, 0) * CFrame.Angles(FreeCamPitch, 0, 0)
        local look  = rotCF.LookVector
        local right = rotCF.RightVector
        local up    = Vector3.new(0, 1, 0)
        local move  = Vector3.new()
        local speed = FreeCamSpeed * dt * (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 3 or 1)

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + look  end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - look  end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - right end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + right end
        if UserInputService:IsKeyDown(Enum.KeyCode.E) then move = move + up    end
        if UserInputService:IsKeyDown(Enum.KeyCode.Q) then move = move - up    end

        if move.Magnitude > 0 then
            FreeCamPos = FreeCamPos + move.Unit * speed
        end
        Camera = workspace.CurrentCamera
        Camera.CameraType = Enum.CameraType.Scriptable
        Camera.CFrame = CFrame.new(FreeCamPos) * rotCF
    end)
end

local function disableFreeCam()
    if FreeCamRender then FreeCamRender:Disconnect(); FreeCamRender = nil end
    if FreeCamInput  then FreeCamInput:Disconnect();  FreeCamInput  = nil end
    Camera = workspace.CurrentCamera
    if Camera then Camera.CameraType = Enum.CameraType.Custom end
    UserInputService.MouseBehavior    = Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled = true
end

-- ── Re-fetch chr/hum on respawn ───────────────────────
LocalPlayer.CharacterAdded:Connect(function(newChr)
    chr  = newChr
    hum  = newChr:WaitForChild("Humanoid")
    root = newChr:WaitForChild("HumanoidRootPart")
    if Spin then hum.AutoRotate = false end
end)

-- ── Global config ─────────────────────────────────────
getgenv().allvars = getgenv().allvars or {
    noswaybool = false, nojumptilt = false,
    viewmodoffset = false,
    viewmodX = 0,
    viewmodY = 0,
    viewmodZ = 0,
    NoBulletDrop = false,
    rapidfire = false, fastaim = false,
    alwaysauto = false, instahit = false,
    nodof = false, noaiming = false,
    fastReload = false, fastequip = false,
    extendedrange = false, instantreduction = false,
    upanglebool = false,
    upanglenum  = 0.75,
    norecoil = false,
    nobob    = false,
    adsfovbool = false,
}

getgenv().ESP = {
    Enabled = false, MaxDistance = 1000,
    Box       = { Enabled = false, Color = Color3.fromRGB(255,0,0),
                  Thickness = 2, Filled = false, FillTransparency = 0.5 },
    HealthBar = { Enabled = false, Width = 4 },
    HealthText= { Enabled = false, Color = Color3.fromRGB(255,255,255), Size = 12 },
    Name      = { Enabled = false, Color = Color3.fromRGB(255,255,255), Size = 14, Outline = true },
    Highlight = { Enabled = false,
                  FillColor = Color3.fromRGB(255,0,0),
                  OutlineColor = Color3.fromRGB(255,255,255),
                  FillTransparency = 0.5, OutlineTransparency = 0 },
    Font = Enum.Font.Arcade,
}

getgenv().World = {
    FogEnabled     = false, FogStart = 0, FogEnd = 100000,
    TimeEnabled    = false, TimeOfDay = 14,
    Brightness     = 2,
    Ambient        = Color3.fromRGB(138,138,138),
    OutdoorAmbient = Color3.fromRGB(138,138,138),
    RemoveGrass    = false,
    RemoveShadows  = false,
    RemoveClouds   = false,
    RemoveAtmo     = false,
    RemoveLeaves   = false,
    FOVEnabled     = false,
}

getgenv().Aimbot = {
    Enabled = false, SilentAim = false,
    FOV = 100, TargetPart = "Head",
    ShowFOV = false, FOVColor = Color3.fromRGB(255,255,255),
    HitChance = 100,
    WallCheck  = true,
    Prediction = false,
    TargetAI   = false,
    TargetLine = false,
    LiftScale  = 1,
    TargetLineColor = Color3.fromRGB(255, 80, 0),
    AutoShoot  = false,
    AutoShootRate = 0.12,
    InstantHit = false,
}

getgenv().BulletTracers = {
    Enabled = false, Color = Color3.fromRGB(255,0,0),
    TextureID = "rbxassetid://446111271",
    Transparency = 0, Size = 0.3, TimeAlive = 2, FadeTime = 0.3,
}

getgenv().HitSound = {
    Enabled = false, SoundID = "rbxassetid://4817809188", Volume = 1,
}

getgenv().GunMods = { InstantEquip = false }

getgenv().WeaponCham = getgenv().WeaponCham or {
    Enabled  = false,
    Material = "Neon",
    Color    = Color3.fromRGB(255, 100, 0),
}

getgenv().ArmCham = getgenv().ArmCham or {
    Enabled  = false,
    Material = "Neon",
    Color    = Color3.fromRGB(200, 150, 100),
}

-- ── Leaf MeshIDs ──────────────────────────────────────
local LEAF_MESHIDS = {
    ["rbxassetid://8140855690"] = true,
    ["rbxassetid://8140820446"] = true,
    ["rbxassetid://8140894531"] = true,
    ["rbxassetid://8140731110"] = true,
    ["rbxassetid://8140877161"] = true,
}

local FOLIAGE_ZONES = {
    "PrePlaced",
    "TreesZone1","TreesZone2","TreesZone3","TreesZone4","TreesZone5",
    "TreesZone6","TreesZone7","TreesZone8","TreesZone9","TreesZone10",
    "TreesZone11","TreesZone12","TreesZone13","TreesZone14","TreesZone15",
    "TreesZone16","TreesZone17","TreesZone18","TreesZone19","TreesZone20",
    "TreesZone21","TreesZone22","TreesZone23","TreesZone24",
}

local function applyLeaves(hide)
    local foliage = workspace:FindFirstChild("SpawnerZones")
        and workspace.SpawnerZones:FindFirstChild("Foliage")
    if not foliage then return end
    local want = hide and 1 or 0
    for _, zoneName in ipairs(FOLIAGE_ZONES) do
        local zone = foliage:FindFirstChild(zoneName)
        if not zone then continue end
        for _, obj in pairs(zone:GetChildren()) do
            if obj:IsA("Model") then
                -- Smart bush detection: any model whose name starts with "Bush"
                local isBush = obj.Name:sub(1, 4):lower() == "bush"
                for _, part in pairs(obj:GetDescendants()) do
                    if part:IsA("BasePart") then
                        local isLeafMesh = part:IsA("MeshPart") and LEAF_MESHIDS[part.MeshId]
                        if isLeafMesh or isBush then
                            if part.Transparency ~= want then
                                part.Transparency = want
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ── Module requires (all guarded) ─────────────────────
local BulletModule, FunctionLibrary, FireProjectile, ProjectileInflict, CamMod

pcall(function() BulletModule      = require(ReplicatedStorage.Modules.FPS.Bullet) end)
pcall(function() FunctionLibrary   = require(ReplicatedStorage.Modules:WaitForChild("FunctionLibraryExtension")) end)
pcall(function() FireProjectile    = ReplicatedStorage.Remotes.FireProjectile end)
pcall(function() ProjectileInflict = ReplicatedStorage.Remotes.ProjectileInflict end)
pcall(function() CamMod            = require(ReplicatedStorage.Modules.CameraSystem) end)

-- ── AimZoom — direct FOV override on RMB (like ADS FOV) ──
local AimZoomEnabled = false
local AimZoomFOV     = 40    -- raw FOV value when aiming (20–120)
local _aimZoomActive = false
local _aimZoomConn   = nil

local function applyAimZoom(isAiming)
    if not AimZoomEnabled then return end
    if isAiming == _aimZoomActive then return end
    _aimZoomActive = isAiming
    local cam = workspace.CurrentCamera
    if not cam then return end
    local targetFov = isAiming and AimZoomFOV or (TargetFOV or BaseFov or 70)
    TweenService:Create(cam,
        TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { FieldOfView = targetFov }
    ):Play()
    -- Also push through CamMod if available so the game's camera system stays in sync
    if CamMod then
        pcall(function()
            local base = BaseFov or 70
            local divisor = isAiming and (base / AimZoomFOV) or 1
            CamMod:SetZoomTarget(divisor, isAiming, 0.12,
                Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end)
    end
end

-- Detect RMB (ADS) press / release
UserInputService.InputBegan:Connect(function(inp, gameProc)
    if gameProc then return end
    if inp.UserInputType == Enum.UserInputType.MouseButton2 then
        applyAimZoom(true)
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton2 then
        applyAimZoom(false)
    end
end)

-- ── ADS FOV ───────────────────────────────────────────
local currentZoomValue = 90
local itemslist = game.ReplicatedStorage:WaitForChild("ItemsList")

local function applyZoomToAllGuns()
    if not getgenv().allvars.adsfovbool then return end

    for _, v in pairs(itemslist:GetChildren()) do
        local mod = v:FindFirstChild("SettingsModule")
        if mod then
            local sett = require(mod)
            if sett and typeof(sett.FireModes) == "table" then
                sett.AimFOV  = currentZoomValue
                sett.ZoomFOV = currentZoomValue
                print(sett.ZoomFOV)
                print(sett.AimFOV)
            end
        end
    end
end

-- ── Hit sound ─────────────────────────────────────────
local function playHitSound()
    if not getgenv().HitSound.Enabled then return end
    local snd = Instance.new("Sound")
    snd.SoundId = getgenv().HitSound.SoundID
    snd.Volume  = getgenv().HitSound.Volume
    snd.Parent  = SoundService
    snd:Play()
    snd.Ended:Connect(function() snd:Destroy() end)
end

-- ── Bullet tracer ─────────────────────────────────────
local function CreateBulletTracer(startPos, endPos)
    if not getgenv().BulletTracers.Enabled then return end
    local bt = getgenv().BulletTracers

    local function makePart(pos)
        local p = Instance.new("Part")
        p.Anchored = true; p.CanCollide = false; p.Transparency = 1
        p.Size = Vector3.new(0.2,0.2,0.2); p.Material = Enum.Material.ForceField
        p.CanTouch = false; p.CanQuery = false; p.Massless = true
        p.Position = pos; p.Parent = workspace
        return p
    end

    local sp, ep = makePart(startPos), makePart(endPos)
    local a0 = Instance.new("Attachment", sp)
    local a1 = Instance.new("Attachment", ep)

    local beam = Instance.new("Beam")
    beam.Attachment0 = a0; beam.Attachment1 = a1
    beam.Parent = sp; beam.FaceCamera = true
    beam.Color = ColorSequence.new(bt.Color)
    beam.Texture = bt.TextureID; beam.LightEmission = 1
    beam.Transparency = NumberSequence.new(bt.Transparency)
    beam.Width0 = bt.Size; beam.Width1 = bt.Size

    task.delay(bt.TimeAlive, function()
        if beam and beam.Parent then
            TweenService:Create(beam,
                TweenInfo.new(bt.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { Width0 = 0, Width1 = 0 }):Play()
            task.wait(bt.FadeTime)
        end
        pcall(function() sp:Destroy() end)
        pcall(function() ep:Destroy() end)
    end)
end

-- ── FPS module hook ────────────────────────────────────
local a1table = nil
pcall(function()
    local fpsMod = require(ReplicatedStorage.Modules.FPS)
    local ogfunc = fpsMod.updateClient

    fpsMod.updateClient = function(a1, a2, a3)
        local r1, r2, r3 = ogfunc(a1, a2, a3)
        a1table = a1

        -- guard: some weapons (melee, thrown) have no springs table
        if not a1 or not a1.springs then return r1, r2, r3 end

        if getgenv().allvars.nojumptilt then
            if a1.springs.jumpCameraTilt then
                a1.springs.jumpCameraTilt.Position = Vector3.new(0,0,0)
            end
        end

        if getgenv().allvars.noswaybool then
            for _, k in ipairs({"sway","walkCycle","sprintCycle","strafeTilt","jumpTilt"}) do
                if a1.springs[k] then
                    a1.springs[k].Position = Vector3.new(0,0,0)
                    a1.springs[k].Speed = 0
                end
            end
        else
            for _, k in ipairs({"sway","walkCycle","sprintCycle","strafeTilt","jumpTilt"}) do
                if a1.springs[k] then
                    a1.springs[k].Speed = 4
                end
            end
        end

        if getgenv().allvars.viewmodoffset then
            local cf = CFrame.new(getgenv().allvars.viewmodX,
                                  getgenv().allvars.viewmodY,
                                  getgenv().allvars.viewmodZ)
            a1.weaponOffset    = cf; a1.sprintIdleOffset = cf
            a1.crouchOffset    = cf; a1.leanLeftOffset   = cf
            a1.leanRightOffset = cf
        end

        return r1, r2, r3
    end
end)


local function applyGunMods(gun)
    if not gun:FindFirstChild("SettingsModule") then return end
    local ok, sett = pcall(require, gun.SettingsModule)
    if not ok then return end

    local v = getgenv().allvars
    if v.rapidfire        then sett.FireRate = 0.01; sett.SemiAuto = false end
    if v.fastaim          then sett.AimInSpeed = 0.01; sett.AimOutSpeed = 0.01 end
    if v.noswaybool       then sett.swayMult = 0; sett.IdleSwayModifier = 0; sett.WalkSwayModifer = 0; sett.SprintSwayModifer = 0 end
    if v.alwaysauto       then sett.FireMode = "Auto"; sett.FireModes = {"Auto"}; sett.SemiAuto = false; sett.AutomaticFire = true end
    if v.instahit         then sett.BulletSpeed = 9999999; sett.BulletDrop = 0; sett.BulletGravity = 0 end
    if v.nodof            then sett.useDof = false end
    if v.noaiming         then sett.allowAiming = false end
    if v.fastReload       then sett.ReloadFadeIn = 0.01; sett.ReloadFadeOut = 0.01; sett.ReloadTime = 0.1 end
    if v.fastequip        then sett.EquipTValue = 0.01 end
    if v.extendedrange    then sett.ItemLength = 20; sett.Range = 9999 end
    if v.instantreduction then sett.ReductionStartTime = 0; sett.RecoilReduction = 100 end
    if v.adsfovbool       then
        sett.AimFOV  = currentZoomValue
        sett.ZoomFOV = currentZoomValue
    end
end

-- New reactive system (add this after all UI toggles)
local function updateAllGunMods()
    gunModDirty = true
end

-- Gun mod toggles call updateAllGunMods() via their Callbacks (set inline below)

-- One single heartbeat for gun mods (much lighter)
RunService.Heartbeat:Connect(function()
    if not gunModDirty then return end
    gunModDirty = false
    local itemsList = ReplicatedStorage:FindFirstChild("ItemsList")
    if itemsList then
        for _, item in ipairs(itemsList:GetChildren()) do
            applyGunMods(item)
        end
    end
end)

-- ═══════════════════════════════════════════════════════
-- NO RECOIL + NO WEAPON BOB — SpringV2 gc hook
-- ═══════════════════════════════════════════════════════
local function patchSpringTable(t)
    local oldShove  = t.shove
    local oldUpdate = t.update

    t.shove = function(...)
        if getgenv().allvars.norecoil then return end
        return oldShove(...)
    end

    t.update = function(...)
        if getgenv().allvars.norecoil or getgenv().allvars.nobob then
            return Vector3.zero
        end
        return oldUpdate(...)
    end
end

local function patchSpringCreator(t)
    local oldCreate = t.create
    t.create = function(...)
        local spring = oldCreate(...)
        patchSpringTable(spring)
        return spring
    end
end

local function hookSprings()
    if not getgc then return end
    for _, gc in ipairs(getgc(true)) do
        if type(gc) == "table" then
            if rawget(gc, "shove") and rawget(gc, "update") then
                pcall(patchSpringTable, gc)
            end
            if type(rawget(gc, "create")) == "function" then
                local ok, info = pcall(debug.getinfo, gc.create)
                if ok and info and info.short_src
                    and info.short_src:find("SpringV2") then
                    pcall(patchSpringCreator, gc)
                end
            end
        end
    end
end

task.spawn(function()
    hookSprings()
    task.wait(2)
    hookSprings()
end)

-- ── Main Heartbeat ────────────────────────────────────
RunService.Heartbeat:Connect(function()
    if random then
        getgenv().allvars.upanglenum = math.random() * 2 - 1
    end

    if noJumpCooldown and hum then
        hum.JumpHeight = 3.3
    end

    if nofall and hum then
        local state = hum:GetState()
        if (state == Enum.HumanoidStateType.Freefall
            or state == Enum.HumanoidStateType.FallingDown)
            and root and root.AssemblyLinearVelocity.Y < -30 then
            hum:ChangeState(Enum.HumanoidStateType.Landed)
        end
    end

    local lhum  = chr and chr:FindFirstChild("Humanoid")
    local lroot = chr and chr:FindFirstChild("HumanoidRootPart")

    if SlowDown and lhum and lhum.WalkSpeed < 16 then
        lhum.WalkSpeed = 16
    end

    if Spin and lroot then
        lroot.CFrame = lroot.CFrame * CFrame.Angles(0, math.rad(SpinSpeed), 0)
    end

    local itemsList = ReplicatedStorage:FindFirstChild("ItemsList")
    if not itemsList then return end
    for _, item in pairs(itemsList:GetChildren()) do applyGunMods(item) end
end)

-- ── AmmoTypes instahit ────────────────────────────────
RunService.Heartbeat:Connect(function()
    if not getgenv().allvars.instahit then return end
    local at = ReplicatedStorage:FindFirstChild("AmmoTypes")
    if not at then return end
    for _, ammo in pairs(at:GetChildren()) do
        if ammo:IsA("Folder") or ammo:IsA("Configuration") then
            if ammo:GetAttribute("MuzzleVelocity") then ammo:SetAttribute("MuzzleVelocity", 9999999) end
            if ammo:GetAttribute("ArmorPen")       then ammo:SetAttribute("ArmorPen", 999) end
        end
    end
end)

local savedDropValues = {}

RunService.Heartbeat:Connect(function()
    local at = ReplicatedStorage:FindFirstChild("AmmoTypes")
    if not at then return end

    if getgenv().allvars.NoBulletDrop then
        for _, ammo in pairs(at:GetChildren()) do
            if ammo:IsA("Folder") or ammo:IsA("Configuration") then
                if ammo:GetAttribute("ProjectileDrop") ~= nil then
                    if savedDropValues[ammo.Name] == nil then
                        savedDropValues[ammo.Name] = ammo:GetAttribute("ProjectileDrop")
                    end
                    ammo:SetAttribute("ProjectileDrop", 0)
                end
            end
        end
    else
        -- Restore saved originals
        for _, ammo in pairs(at:GetChildren()) do
            if ammo:IsA("Folder") or ammo:IsA("Configuration") then
                if savedDropValues[ammo.Name] ~= nil then
                    ammo:SetAttribute("ProjectileDrop", savedDropValues[ammo.Name])
                    savedDropValues[ammo.Name] = nil
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════
-- WORLD PERSISTENCE LOOP
-- ═══════════════════════════════════════════════════════
local _grassTimer  = 0
local _leavesTimer = 0

RunService.Heartbeat:Connect(function(dt)
    local w = getgenv().World

    if w.FogEnabled then
        Lighting.FogStart = w.FogStart
        Lighting.FogEnd   = w.FogEnd
    end
    if w.TimeEnabled then
        Lighting.ClockTime = w.TimeOfDay
    end
    Lighting.Brightness     = w.Brightness
    Lighting.Ambient        = w.Ambient
    Lighting.OutdoorAmbient = w.OutdoorAmbient

    -- Shadows — enforce every frame so game can't reset it
    Lighting.GlobalShadows = not w.RemoveShadows

    -- Atmosphere — enforce every frame so game can't reset it
    local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmo then
        if w.RemoveAtmo then
            if atmo.Density ~= 0 then atmo.Density = 0 end
            if atmo.Offset  ~= 0 then atmo.Offset  = 0 end
        else
            if atmo.Density ~= 0.34  then atmo.Density = 0.34  end
            if atmo.Offset  ~= 0.281 then atmo.Offset  = 0.281 end
        end
    end

    -- Clouds — enforce every frame so game can't reset it
    local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
    if clouds then
        local want = not w.RemoveClouds
        if clouds.Enabled ~= want then clouds.Enabled = want end
    end

    -- Grass — re-enforce on a 5s timer (sethiddenproperty is expensive)
    _grassTimer = _grassTimer - dt
    if _grassTimer <= 0 then
        _grassTimer = 5
        pcall(function()
            sethiddenproperty(workspace.Terrain, "Decoration", not w.RemoveGrass)
        end)
    end

    -- Leaves — re-enforce on a 3s timer so newly spawned trees also get caught.
    -- Checks current transparency so it only touches parts that need updating.
    _leavesTimer = _leavesTimer - dt
    if _leavesTimer <= 0 then
        _leavesTimer = 3
        if w.RemoveLeaves then
            task.spawn(applyLeaves, true)
        end
    end

    -- Track last value so toggling off still fires applyLeaves(false) once
    if w.RemoveLeaves ~= lastLeaves then
        lastLeaves = w.RemoveLeaves
        if not w.RemoveLeaves then
            task.spawn(applyLeaves, false)
        end
    end
end)

-- ── FOV persistence loop ──────────────────────────────
RunService.RenderStepped:Connect(function()
    if getgenv().World.FOVEnabled and not FreeCam then
        local cam = (CamMod and CamMod.u4) or Camera
        if cam.FieldOfView ~= TargetFOV then
            cam.FieldOfView = TargetFOV
        end
    end
end)

-- ═══════════════════════════════════════════════════════
-- SILENT AIM HELPERS
-- ═══════════════════════════════════════════════════════
local function solveQuadratic(A, B, C)
    local disc = B^2 - 4*A*C
    if disc < 0 then return nil, nil end
    local sq = math.sqrt(disc)
    return (-B - sq) / (2*A), (-B + sq) / (2*A)
end

local function getBallisticFlightTime(direction, gravity, speed)
    local r1, r2 = solveQuadratic(
        gravity:Dot(gravity) / 4,
        gravity:Dot(direction) - speed^2,
        direction:Dot(direction)
    )
    if r1 and r2 then
        if r1 > 0 and r1 < r2 then return math.sqrt(r1)
        elseif r2 > 0         then return math.sqrt(r2) end
    end
    return 0
end

local function projectileDrop(origin, targetPos, speed, acceleration)
    -- Force gravity to always point down regardless of whether the game stores
    -- ProjectileDrop as positive or negative. math.abs guarantees this.
    local gravY    = -math.abs(acceleration) * 2
    local gravity  = Vector3.new(0, gravY, 0)
    local t        = getBallisticFlightTime(targetPos - origin, gravity, speed)
    return 0.5 * gravity * t^2   -- always negative Y (downward drop)
end

local function predictPosition(targetPart, origin, speed, acceleration)
    -- Perfect iterative prediction: 15 passes, accounts for drag=0, gravity, and velocity.
    -- gravity is forced downward (negative Y) regardless of how the game stores acceleration.
    local gravity = Vector3.new(0, -math.abs(acceleration) * 2, 0)
    local pos     = targetPart.Position
    local vel     = targetPart.Velocity

    for _ = 1, 15 do
        local delta = pos - origin
        local t     = delta.Magnitude / math.max(speed, 1)
        -- Full kinematic position at time t
        pos = targetPart.Position + vel * t + 0.5 * gravity * (t * t)
    end
    return pos
end

-- ── Modern raycast params (created once, reused) ──────
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

-- Cached foliage folder so wall-check never trips on leaves/bushes
local _cachedFoliage = nil
local function getFoliage()
    if not _cachedFoliage or not _cachedFoliage.Parent then
        local sz = workspace:FindFirstChild("SpawnerZones")
        _cachedFoliage = sz and sz:FindFirstChild("Foliage") or nil
    end
    return _cachedFoliage
end

local function isVisible(origin, targetPart)
    local ignore = { Camera }
    if LocalPlayer.Character then table.insert(ignore, LocalPlayer.Character) end
    -- Exclude all foliage so leaves/bushes never block wall-check
    local fol = getFoliage()
    if fol then table.insert(ignore, fol) end
    rayParams.FilterDescendantsInstances = ignore
    local direction = targetPart.Position - origin
    -- Multi-pass: keep stepping through transparent parts (glass, meshes < 0.5 opacity)
    local offset = Vector3.new()
    for _ = 1, 6 do
        local result = workspace:Raycast(origin + offset, direction - offset, rayParams)
        if not result then return true end  -- nothing solid in the way
        local inst = result.Instance
        if inst:IsDescendantOf(targetPart.Parent) then return true end
        -- If the blocking part is semi-transparent, punch through it
        if inst.Transparency >= 0.3 then
            local extra = { inst }
            for _, e in ipairs(ignore) do table.insert(extra, e) end
            rayParams.FilterDescendantsInstances = extra
            ignore = extra
            offset = result.Position - origin + direction.Unit * 0.05
        else
            return false
        end
    end
    return false
end

-- ═══════════════════════════════════════════════════════
-- TARGET SYSTEM — runs on Heartbeat, NOT RenderStepped
-- ═══════════════════════════════════════════════════════
local BaseCameraFOV = 70   -- hoisted here so scanTarget + auto-shoot can use it
local cachedTarget  = nil

local function scanTarget()
    Camera = workspace.CurrentCamera
    if not Camera or not Camera.Parent then return nil end
    local camFOV = Camera.FieldOfView
    if not camFOV or camFOV == 0 then camFOV = BaseCameraFOV end
    local fovScale   = BaseCameraFOV / camFOV
    local effectiveFOV = getgenv().Aimbot.FOV * fovScale
    local best, bestDist = nil, effectiveFOV
    local mousePos = UserInputService:GetMouseLocation()
    local camPos   = Camera.CFrame.Position

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer or not player.Character then continue end
        local phum = player.Character:FindFirstChild("Humanoid")
        local part = player.Character:FindFirstChild(getgenv().Aimbot.TargetPart)
        if not phum or phum.Health <= 0 or not part then continue end

        -- No hard distance cap — uses your ESP MaxDistance setting
        if (part.Position - camPos).Magnitude > getgenv().ESP.MaxDistance then continue end

        local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end

        local dist = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
        if dist < bestDist then
            bestDist = dist
            best = part
        end
    end

    if getgenv().Aimbot.TargetAI then
        local aiZones = workspace:FindFirstChild("AiZones")
        if aiZones then
            for _, zone in pairs(aiZones:GetChildren()) do
                for _, model in pairs(zone:GetChildren()) do
                    if model.ClassName ~= "Model" then continue end
                    local nhum = model:FindFirstChildOfClass("Humanoid")
                    local part = model:FindFirstChild(getgenv().Aimbot.TargetPart)
                              or model:FindFirstChild("HumanoidRootPart")
                    if not nhum or nhum.Health <= 0 or not part then continue end
                    if (part.Position - camPos).Magnitude > getgenv().ESP.MaxDistance then continue end
                    local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if not onScreen then continue end
                    local dist = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
                    if dist < bestDist then bestDist = dist; best = part end
                end
            end
        end
    end

    if best and getgenv().Aimbot.WallCheck then
        if not isVisible(camPos, best) then
            best = nil
        end
    end

    return best
end

-- Target scanning throttled to every 4 frames — kills the FPS drop
local _scanFrame = 0
RunService.Heartbeat:Connect(function()
    if not getgenv().Aimbot.Enabled and not getgenv().Aimbot.AutoShoot then
        cachedTarget = nil
        return
    end
    _scanFrame = _scanFrame + 1
    if _scanFrame < 4 then return end
    _scanFrame = 0
    cachedTarget = scanTarget()
end)

local function getTarget()
    return cachedTarget
end

-- ── FOV circle ────────────────────────────────────────
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2; FOVCircle.NumSides = 64
FOVCircle.Filled = false; FOVCircle.Visible = false
FOVCircle.ZIndex = 999; FOVCircle.Transparency = 1
FOVCircle.Color = getgenv().Aimbot.FOVColor
FOVCircle.Radius = getgenv().Aimbot.FOV

local CurrentFOVRadius = getgenv().Aimbot.FOV
local TargetFOVRadius  = getgenv().Aimbot.FOV
local FOVSmoothSpeed   = 0.15
-- BaseCameraFOV = 70 is declared earlier, above scanTarget

local TargetLine = Drawing.new("Line")
TargetLine.Thickness    = 1.5
TargetLine.Color        = getgenv().Aimbot.TargetLineColor
TargetLine.Transparency = 1
TargetLine.Visible      = false

-- RenderStepped only does cheap drawing — no scanning
RunService.RenderStepped:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    local cam = workspace.CurrentCamera
    FOVCircle.Position = mousePos
    if cam and cam.FieldOfView and cam.FieldOfView ~= 0 then
        local fovScale = BaseCameraFOV / cam.FieldOfView
        TargetFOVRadius  = getgenv().Aimbot.FOV * fovScale
        CurrentFOVRadius = CurrentFOVRadius + (TargetFOVRadius - CurrentFOVRadius) * FOVSmoothSpeed
        FOVCircle.Radius = CurrentFOVRadius
    end
    FOVCircle.Visible = getgenv().Aimbot.ShowFOV
    FOVCircle.Color   = getgenv().Aimbot.FOVColor

    local showLine = getgenv().Aimbot.TargetLine and getgenv().Aimbot.Enabled
    if showLine then
        local target = cachedTarget
        if target then
            local sp, onScreen = Camera:WorldToViewportPoint(target.Position)
            if onScreen then
                TargetLine.From    = mousePos
                TargetLine.To      = Vector2.new(sp.X, sp.Y)
                TargetLine.Color   = getgenv().Aimbot.TargetLineColor
                TargetLine.Visible = true
            else
                TargetLine.Visible = false
            end
        else
            TargetLine.Visible = false
        end
    else
        TargetLine.Visible = false
    end
end)

local function predictPosition(targetPart, origin, speed)
    -- Only predict target movement (lead). Gravity/drop is handled separately below.
    local pos = targetPart.Position
    local vel = targetPart.Velocity or Vector3.new()

    for _ = 1, 12 do
        local delta = pos - origin
        local t = delta.Magnitude / math.max(speed, 10)
        pos = targetPart.Position + vel * t
    end
    return pos
end

-- Replace the entire silent aim bullet hook with this improved version:
if BulletModule then
    local oldBullet
    local hookOk = pcall(function()
        oldBullet = hookfunction(BulletModule.CreateBullet,
            function(idk, model, model2, model3, aimPart, idk2, ammoType, tick, recoilPattern)

            if getgenv().Aimbot.Enabled and getgenv().Aimbot.SilentAim then
                local target = getTarget()
                if target and target.Parent then
                    local ammoData        = ReplicatedStorage.AmmoTypes:FindFirstChild(ammoType)
                    local acceleration    = ammoData and ammoData:GetAttribute("ProjectileDrop") or -9.8
                    local projectileSpeed = ammoData and ammoData:GetAttribute("MuzzleVelocity") or 500

                    if ammoData then ammoData:SetAttribute("Drag", 0) end

                    local targetPos = target.Position

                    if getgenv().Aimbot.Prediction then
                        targetPos = predictPosition(target, aimPart.Position, projectileSpeed)
                    end

                    -- ── STRONGER LONG-RANGE DROP COMPENSATION ──
                    local g = math.abs(acceleration) * 2
                    local delta = targetPos - aimPart.Position
                    local flatDistance = delta.Magnitude
                    local t = flatDistance / math.max(projectileSpeed, 1)

                    local liftScale = getgenv().Aimbot.LiftScale or 1
                    local lift = 0.5 * g * (t * t) * liftScale

                    -- Extra upward boost for longer ranges (exactly what you asked for)
                    if t > 0.8 then
                        lift = lift * 1.18                     -- base extra lift
                        local extraT = (0.5 * g * t^2) / (projectileSpeed * 2) -- path curvature correction
                        lift = lift + 0.5 * g * (extraT * extraT) * liftScale
                    end

                    local liftedTarget = Vector3.new(targetPos.X, targetPos.Y + lift, targetPos.Z)
                    local fakeAimPart  = { CFrame = CFrame.new(aimPart.Position, liftedTarget) }

                    if math.random(1, 100) <= (getgenv().Aimbot.HitChance or 100) then
                        getgenv().aimtarget     = Players:GetPlayerFromCharacter(target.Parent)
                        getgenv().aimtargetpart = target

                        task.spawn(function()
                            if getgenv().BulletTracers.Enabled then
                                CreateBulletTracer(aimPart.Position, targetPos)
                            end
                            spawnHitEffect(targetPos)
                        end)

                        _inBullet = true
                        local r = oldBullet(idk, model, model2, model3, fakeAimPart, idk2, ammoType, tick, recoilPattern)
                        _inBullet = false
                        return r
                    end
                end
            end

            -- Normal shot tracer (unchanged)
            if getgenv().BulletTracers.Enabled then
                task.spawn(function()
                    local barrelPos = aimPart.Position
                    local lookDir   = aimPart.CFrame.LookVector
                    local rp = RaycastParams.new()
                    rp.FilterType = Enum.RaycastFilterType.Exclude
                    rp.FilterDescendantsInstances = { LocalPlayer.Character, workspace.CurrentCamera }
                    local result = workspace:Raycast(barrelPos, lookDir * 2000, rp)
                    local endPos = result and result.Position or (barrelPos + lookDir * 2000)
                    CreateBulletTracer(barrelPos, endPos)
                end)
            end

            _inBullet = true
            local r = oldBullet(idk, model, model2, model3, aimPart, idk2, ammoType, tick, recoilPattern)
            _inBullet = false
            return r
        end)
    end)

    if hookOk then print("[SA] bullet.CreateBullet hook OK (improved prediction)")
    else warn("[SA] bullet.CreateBullet hook FAILED") end
else
    warn("[SA] Could not require Bullet module — silent aim disabled")
end

-- ── Combined namecall hook ─────────────────────────────
-- _inBullet: true while CreateBullet is executing so the Raycast
-- intercept knows it came from FPS.Bullet without debug.getinfo
local _inBullet = false

if ProjectileInflict then
    local OldNamecall
    pcall(function()
        OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            if checkcaller() then return OldNamecall(self, ...) end

            local method = getnamecallmethod()
            local outerArgs = { ... }  -- capture varargs before xpcall

            local result = table.pack(xpcall(function()
                local args = outerArgs

                if method == "FireServer" and self.Name == "UpdateTilt" then
                    if getgenv().allvars.upanglebool then
                        args[1] = getgenv().allvars.upanglenum
                        return OldNamecall(self, table.unpack(args))
                    end
                end

                if method == "FireServer" and self == ProjectileInflict then
                    -- Real server-confirmed hit: play sound + hit effect.
                    -- This is the ONLY place hit sound fires, so it never double-plays.
                    task.spawn(function()
                        if getgenv().HitSound.Enabled then playHitSound() end
                        -- Show hit effect at the aimed target if we have one,
                        -- otherwise fall back to a screen-centre world estimate.
                        local tp = getgenv().aimtargetpart
                        if tp and tp.Parent then
                            spawnHitEffect(tp.Position)
                        end
                    end)
                end

                if getgenv().Aimbot.InstantHit
                    and method == "Raycast"
                    and _inBullet
                    and cachedTarget
                    and cachedTarget.Parent then
                    local args2 = outerArgs
                    args2[2] = (cachedTarget.Position - args2[1]).Unit * 9e4
                    return OldNamecall(self, table.unpack(args2))
                end

                return OldNamecall(self, table.unpack(args))
            end, function() end))

            if result[1] then
                return table.unpack(result, 2, result.n)
            end
            return OldNamecall(self, table.unpack(outerArgs))
        end))
    end)
    print("[ZestHub] Namecall hook OK")
else
    warn("[ZestHub] ProjectileInflict not found — namecall hook skipped")
end

-- ── Auto Shoot ────────────────────────────────────────
-- Simulates mouse1press/release so the game's own fire system runs normally.
-- Silent Aim (BulletModule hook) then redirects the bullet at the cached target.
-- Visibility is ALWAYS checked, regardless of the Aimbot WallCheck setting.
local _autoShootTimer  = 0
local _autoShootHeld   = false

local function autoShootFindTarget()
    Camera = workspace.CurrentCamera
    if not Camera or not Camera.Parent then return nil end
    local camFOV = Camera.FieldOfView
    if not camFOV or camFOV == 0 then camFOV = BaseCameraFOV end
    local fovScale     = BaseCameraFOV / camFOV
    local effectiveFOV = getgenv().Aimbot.FOV * fovScale
    local mousePos     = UserInputService:GetMouseLocation()
    local camPos       = Camera.CFrame.Position
    local best, bestDist = nil, effectiveFOV

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer or not player.Character then continue end
        local phum = player.Character:FindFirstChild("Humanoid")
        local part = player.Character:FindFirstChild(getgenv().Aimbot.TargetPart)
        if not phum or phum.Health <= 0 or not part then continue end
        if (part.Position - camPos).Magnitude > getgenv().ESP.MaxDistance then continue end
        local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        local dist = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
        if dist < bestDist and isVisible(camPos, part) then
            bestDist = dist
            best = part
        end
    end
    return best
end

RunService.Heartbeat:Connect(function(dt)
    if not getgenv().Aimbot.AutoShoot then
        -- Release if we were holding when toggled off
        if _autoShootHeld then
            pcall(mouse1release)
            _autoShootHeld = false
        end
        return
    end

    _autoShootTimer = _autoShootTimer - dt
    if _autoShootTimer > 0 then return end

    local target = autoShootFindTarget()

    if target then
        -- Simulate a click: press → small delay → release
        pcall(mouse1press)
        _autoShootHeld = true
        task.delay(0.065, function()
            pcall(mouse1release)
            _autoShootHeld = false
        end)
        _autoShootTimer = getgenv().Aimbot.AutoShootRate
    else
        -- No target — make sure mouse isn't stuck held
        if _autoShootHeld then
            pcall(mouse1release)
            _autoShootHeld = false
        end
        _autoShootTimer = 0.05  -- check again soon
    end
end)

-- ── Instant Equip ─────────────────────────────────────
workspace.Camera.ChildAdded:Connect(function(ch)
    if not getgenv().GunMods.InstantEquip or not ch:IsA("Model") then return end
    task.wait(0.015)
    local ih = ch:FindFirstChild("Humanoid")
    if ih and ih.Animator then
        for _, track in pairs(ih.Animator:GetPlayingAnimationTracks()) do
            if track.Animation and track.Animation.Name == "Equip" then
                track:AdjustSpeed(15)
                track.TimePosition = track.Length - 0.01
            end
        end
    end
end)

-- ── Weapon icon lookup (for Equipped Gun Image mode) ─────
local function getWeaponIcon(weaponName)
    local il = ReplicatedStorage:FindFirstChild("ItemsList")
    if not il then return nil end
    local item = il:FindFirstChild(weaponName)
    if not item then return nil end
    local props = item:FindFirstChild("ItemProperties")
    if not props then return nil end
    local icon = props:FindFirstChild("ItemIcon")
    if not icon then return nil end
    -- ItemIcon is an ImageLabel — read its .Image property
    return tostring(icon.Image)
end

-- ═══════════════════════════════════════════════════════
-- ESP SYSTEM
-- ═══════════════════════════════════════════════════════
local ESPScreenGui = Instance.new("ScreenGui")
ESPScreenGui.Name = "ESPScreenGui"
ESPScreenGui.ResetOnSpawn = false
ESPScreenGui.IgnoreGuiInset = true
ESPScreenGui.Parent = game:GetService("CoreGui")

local ESPObjects = {}
local ESPClass   = {}
ESPClass.__index = ESPClass

function ESPClass.new(player)
    local self = setmetatable({}, ESPClass)
    self.player = player
    self.box = {}; self.healthBar = {}; self.labels = {}; self.highlight = nil
    self:CreateUI()
    self:CreateHighlight()
    return self
end

function ESPClass:CreateUI()
    self.container = Instance.new("Frame")
    self.container.Name = self.player.Name .. "_ESP"
    self.container.Size = UDim2.new(0,100,0,100)
    self.container.BackgroundTransparency = 1
    self.container.BorderSizePixel = 0
    self.container.Parent = ESPScreenGui
    self:CreateBox()
    self:CreateHealthBar()
    self:CreateLabels()
end

function ESPClass:CreateBox()
    local box = Instance.new("Frame")
    box.BackgroundColor3 = getgenv().ESP.Box.Color
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Size = UDim2.new(1,0,1,0)
    box.Parent = self.container

    local stroke = Instance.new("UIStroke")
    stroke.Color = getgenv().ESP.Box.Color
    stroke.Thickness = getgenv().ESP.Box.Thickness
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = box

    self.box.frame  = box
    self.box.stroke = stroke
end

function ESPClass:CreateHealthBar()
    local cont = Instance.new("Frame")
    cont.Size = UDim2.new(0, getgenv().ESP.HealthBar.Width, 1, 4)
    cont.Position = UDim2.new(0,-8,0,-2)
    cont.BackgroundColor3 = Color3.fromRGB(20,20,20)
    cont.BackgroundTransparency = 0.3
    cont.BorderSizePixel = 0
    cont.Parent = self.container

    Instance.new("UIStroke", cont).Color = Color3.fromRGB(0,0,0)

    local gradFrame = Instance.new("Frame")
    gradFrame.Size = UDim2.new(1,0,1,0)
    gradFrame.BackgroundTransparency = 0
    gradFrame.BorderSizePixel = 0
    gradFrame.ZIndex = 1
    gradFrame.Parent = cont

    local grad = Instance.new("UIGradient")
    grad.Rotation = 90
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(255,0,0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,255,0)),
    })
    grad.Parent = gradFrame

    local mask = Instance.new("Frame")
    mask.Size = UDim2.new(1,0,0,0)
    mask.BackgroundColor3 = Color3.fromRGB(20,20,20)
    mask.BorderSizePixel = 0
    mask.ZIndex = 2
    mask.Parent = cont

    Instance.new("UICorner", cont).CornerRadius = UDim.new(0,2)

    self.healthBar.container = cont
    self.healthBar.gradient  = gradFrame
    self.healthBar.mask      = mask
end

function ESPClass:CreateLabels()
    local function label(name, size, color, pos, anchor, align)
        local l = Instance.new("TextLabel")
        l.Name = name
        l.BackgroundTransparency = 1
        l.Size = UDim2.new(1,40,0,size+4)
        l.Position = pos
        l.AnchorPoint = anchor or Vector2.new(0,0)
        l.TextColor3 = color
        l.TextSize = size
        l.Font = getgenv().ESP.Font
        l.TextStrokeTransparency = 0
        l.TextStrokeColor3 = Color3.fromRGB(0,0,0)
        l.TextXAlignment = align or Enum.TextXAlignment.Center
        l.Parent = self.container
        return l
    end

    self.labels.name = label("NameLabel", 14,
        getgenv().ESP.Name.Color,
        UDim2.new(0.5,0,0,-20), Vector2.new(0.5,1))
    self.labels.name.Text = self.player.Name

    self.labels.health = label("HealthText", 12,
        getgenv().ESP.HealthText.Color,
        UDim2.new(0,-35,0.5,0), Vector2.new(1,0.5),
        Enum.TextXAlignment.Right)
    self.labels.health.Size = UDim2.new(0,50,0,16)
    self.labels.health.Text = "100"

    self.labels.distance = label("DistLabel", 12,
        Color3.fromRGB(200,200,200),
        UDim2.new(0.5,0,1,5), Vector2.new(0.5,0))
    self.labels.distance.Size = UDim2.new(1,40,0,16)
    self.labels.distance.Text = "0m"

    -- Player Weapon ESP labels (shown above name label)
    self.labels.weaponHip = label("WeaponHipLabel", 12,
        Color3.fromRGB(165, 127, 159),
        UDim2.new(0.5, 0, 0, -36), Vector2.new(0.5, 1))
    self.labels.weaponHip.Text    = ""
    self.labels.weaponHip.Visible = false

    self.labels.weaponPrime = label("WeaponPrimeLabel", 12,
        Color3.fromRGB(165, 127, 159),
        UDim2.new(0.5, 0, 0, -52), Vector2.new(0.5, 1))
    self.labels.weaponPrime.Text    = ""
    self.labels.weaponPrime.Visible = false

    self.labels.weaponPrime2 = label("WeaponPrime2Label", 12,
        Color3.fromRGB(165, 127, 159),
        UDim2.new(0.5, 0, 0, -68), Vector2.new(0.5, 1))
    self.labels.weaponPrime2.Text    = ""
    self.labels.weaponPrime2.Visible = false

    -- Equipped Gun label (reads workspace[player].Holding)
    self.labels.weaponEquipped = label("WeaponEquippedLabel", 12,
        Color3.fromRGB(255, 220, 80),
        UDim2.new(0.5, 0, 1, 6), Vector2.new(0.5, 0))
    self.labels.weaponEquipped.Text    = ""
    self.labels.weaponEquipped.Visible = false

    -- Equipped Gun image (shown instead of text when Image mode is active)
    local eqImg = Instance.new("ImageLabel")
    eqImg.Name                   = "WeaponEquippedImage"
    eqImg.BackgroundTransparency = 1
    eqImg.Size                   = UDim2.new(0, 32, 0, 32)
    eqImg.Position               = UDim2.new(0.5, 0, 1, 6)
    eqImg.AnchorPoint            = Vector2.new(0.5, 0)
    eqImg.Image                  = ""
    eqImg.Visible                = false
    eqImg.Parent                 = self.container
    self.labels.weaponEquippedImage = eqImg
end

function ESPClass:CreateHighlight()
    if not self.player.Character then return end
    local hl = Instance.new("Highlight")
    hl.Adornee = self.player.Character
    hl.FillColor           = getgenv().ESP.Highlight.FillColor
    hl.OutlineColor        = getgenv().ESP.Highlight.OutlineColor
    hl.FillTransparency    = getgenv().ESP.Highlight.FillTransparency
    hl.OutlineTransparency = getgenv().ESP.Highlight.OutlineTransparency
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled   = getgenv().ESP.Highlight.Enabled
    hl.Parent    = self.player.Character
    self.highlight = hl
end

function ESPClass:UpdateHighlight()
    if not self.player.Character then return end
    if not self.highlight or self.highlight.Parent ~= self.player.Character then
        if self.highlight then self.highlight:Destroy() end
        self:CreateHighlight()
    end
    if self.highlight then
        local h = getgenv().ESP.Highlight
        self.highlight.Enabled             = h.Enabled and getgenv().ESP.Enabled
        self.highlight.FillColor           = h.FillColor
        self.highlight.OutlineColor        = h.OutlineColor
        self.highlight.FillTransparency    = h.FillTransparency
        self.highlight.OutlineTransparency = h.OutlineTransparency
    end
end

function ESPClass:Hide()
    self.container.Visible = false
    if self.highlight then self.highlight.Enabled = false end
    if self.labels.weaponHip    then self.labels.weaponHip.Visible    = false end
    if self.labels.weaponPrime  then self.labels.weaponPrime.Visible   = false end
    if self.labels.weaponPrime2 then self.labels.weaponPrime2.Visible  = false end
    if self.labels.weaponEquipped      then self.labels.weaponEquipped.Visible      = false end
    if self.labels.weaponEquippedImage then self.labels.weaponEquippedImage.Visible = false end
end

function ESPClass:Update()
    if not Camera or not Camera.Parent then Camera = workspace.CurrentCamera end
    if not getgenv().ESP.Enabled or not self.player.Character then self:Hide() return end

    local echar = self.player.Character
    local ehum  = echar:FindFirstChildOfClass("Humanoid")
    local eroot = echar:FindFirstChild("HumanoidRootPart")
    local head  = echar:FindFirstChild("Head")

    if not ehum or not eroot or not head or ehum.Health <= 0 then self:Hide() return end

    local dist = (eroot.Position - Camera.CFrame.Position).Magnitude
    if dist > getgenv().ESP.MaxDistance then self:Hide() return end

    local rootSP, _ = Camera:WorldToViewportPoint(eroot.Position)
    if rootSP.Z <= 0 then self:Hide() return end

    -- Use actual top-of-head and bottom-of-feet world positions for accurate
    -- screen-space sizing at ALL distances. The old code had a hard 20px minimum
    -- which made the box look huge relative to distant characters.
    local topWorld = head.Position + Vector3.new(0, 0.7, 0)           -- crown of head
    local botWorld = eroot.Position - Vector3.new(0, 2.8, 0)          -- near feet

    local topSP = Camera:WorldToViewportPoint(topWorld)
    local botSP = Camera:WorldToViewportPoint(botWorld)

    -- Make sure both ends are in front of the camera
    if topSP.Z <= 0 or botSP.Z <= 0 then self:Hide() return end

    local height = math.abs(topSP.Y - botSP.Y)
    local width  = height * 0.55   -- standard ~1:2 width:height ratio for upright characters

    -- Tiny floor just to avoid 0-size frames; no large minimum that inflates the box
    height = math.max(height, 4)
    width  = math.max(width,  4)

    -- Center the container on the midpoint between head and feet screen positions,
    -- not on the root (waist) which caused vertical drift at steep camera angles.
    local midX = (topSP.X + botSP.X) * 0.5
    local midY = (topSP.Y + botSP.Y) * 0.5

    self.container.Size     = UDim2.new(0, width, 0, height)
    self.container.Position = UDim2.new(0, midX - width * 0.5, 0, midY - height * 0.5)
    self.container.Visible  = true

    if getgenv().ESP.Box.Enabled then
        self.box.frame.Visible = true
        self.box.frame.BackgroundColor3 = getgenv().ESP.Box.Color
        self.box.frame.BackgroundTransparency =
            getgenv().ESP.Box.Filled and getgenv().ESP.Box.FillTransparency or 1
        self.box.stroke.Color     = getgenv().ESP.Box.Color
        self.box.stroke.Thickness = getgenv().ESP.Box.Thickness
        self.box.stroke.Enabled   = true
    else
        self.box.frame.Visible  = false
        self.box.stroke.Enabled = false
    end

    local hp = math.clamp(ehum.Health / ehum.MaxHealth, 0, 1)
    if getgenv().ESP.HealthBar.Enabled then
        self.healthBar.container.Visible = true
        self.healthBar.container.Size    = UDim2.new(0, getgenv().ESP.HealthBar.Width, 1, 4)
        self.healthBar.gradient.Visible  = true
        self.healthBar.mask.Visible      = true
        self.healthBar.mask.Size         = UDim2.new(1, 0, 1 - hp, 0)
    else
        self.healthBar.container.Visible = false
    end

    if getgenv().ESP.HealthText.Enabled then
        self.labels.health.Visible    = true
        self.labels.health.Text       = tostring(math.floor(ehum.Health))
        self.labels.health.TextColor3 = getgenv().ESP.HealthText.Color
        self.labels.health.TextSize   = getgenv().ESP.HealthText.Size
    else
        self.labels.health.Visible = false
    end

    if getgenv().ESP.Name.Enabled then
        self.labels.name.Visible    = true
        self.labels.name.TextColor3 = getgenv().ESP.Name.Color
        self.labels.name.TextSize   = getgenv().ESP.Name.Size
        self.labels.name.TextStrokeTransparency = getgenv().ESP.Name.Outline and 0 or 1
    else
        self.labels.name.Visible = false
    end

    self.labels.distance.Visible = true
    self.labels.distance.Text    = math.floor(dist) .. "m"

    -- ── Player Weapon ESP ────────────────────────────────
    local pwESP   = getgenv().PlayerWeaponESP
    local invRoot = ReplicatedStorage:FindFirstChild("Players")
    local plrNode = invRoot and invRoot:FindFirstChild(self.player.Name)
    local inv     = plrNode and plrNode:FindFirstChild("Inventory")

    if pwESP.Hip and inv then
        local found = nil
        for _, obj in pairs(inv:GetChildren()) do
            if obj:IsA("ObjectValue") and obj:GetAttribute("Slot") == "ItemHip1" then
                found = obj.Name; break
            end
        end
        if found then
            self.labels.weaponHip.Text      = "[Hip] " .. found
            self.labels.weaponHip.TextColor3 = pwESP.HipColor or Color3.fromRGB(165,127,159)
            self.labels.weaponHip.Visible   = true
        else
            self.labels.weaponHip.Visible = false
        end
    else
        self.labels.weaponHip.Visible = false
    end

    if pwESP.Prime and inv then
        local found1, found2 = nil, nil
        for _, obj in pairs(inv:GetChildren()) do
            if obj:IsA("ObjectValue") then
                local slot = obj:GetAttribute("Slot")
                if slot == "ItemBack1" then found1 = obj.Name
                elseif slot == "ItemBack2" then found2 = obj.Name end
            end
        end
        if found1 then
            self.labels.weaponPrime.Text       = "[Prime] " .. found1
            self.labels.weaponPrime.TextColor3 = pwESP.PrimeColor or Color3.fromRGB(165,127,159)
            self.labels.weaponPrime.Visible    = true
        else
            self.labels.weaponPrime.Visible = false
        end
        if found2 then
            self.labels.weaponPrime2.Text       = "[Prime2] " .. found2
            self.labels.weaponPrime2.TextColor3 = pwESP.PrimeColor or Color3.fromRGB(165,127,159)
            self.labels.weaponPrime2.Visible    = true
        else
            self.labels.weaponPrime2.Visible = false
        end
    else
        self.labels.weaponPrime.Visible = false
        if self.labels.weaponPrime2 then self.labels.weaponPrime2.Visible = false end
    end

    -- ── Equipped Gun ESP (workspace[player].Holding ObjectValue) ─────────
    if pwESP.Equipped then
        local wchar   = workspace:FindFirstChild(self.player.Name)
        local holding = wchar and wchar:FindFirstChild("Holding")
        local heldObj = holding and holding.Value
        local heldName = heldObj and heldObj.Name or nil

        if heldName then
            if pwESP.EquippedMode == "Image" then
                local icon = getWeaponIcon(heldName)
                if icon and icon ~= "" then
                    self.labels.weaponEquippedImage.Image   = icon
                    self.labels.weaponEquippedImage.Visible = true
                    self.labels.weaponEquipped.Visible      = false
                else
                    -- No icon found — fall back to text
                    self.labels.weaponEquipped.Text       = "[Gun] " .. heldName
                    self.labels.weaponEquipped.TextColor3 = pwESP.EquippedColor or Color3.fromRGB(255,220,80)
                    self.labels.weaponEquipped.Visible    = true
                    self.labels.weaponEquippedImage.Visible = false
                end
            else
                self.labels.weaponEquipped.Text       = "[Gun] " .. heldName
                self.labels.weaponEquipped.TextColor3 = pwESP.EquippedColor or Color3.fromRGB(255,220,80)
                self.labels.weaponEquipped.Visible    = true
                self.labels.weaponEquippedImage.Visible = false
            end
        else
            self.labels.weaponEquipped.Visible      = false
            self.labels.weaponEquippedImage.Visible = false
        end
    else
        self.labels.weaponEquipped.Visible      = false
        self.labels.weaponEquippedImage.Visible = false
    end

    self:UpdateHighlight()
end

function ESPClass:Destroy()
    if self.container then self.container:Destroy() end
    if self.highlight  then self.highlight:Destroy()  end
    setmetatable(self, nil)
end

local function CreateESP(player)
    if player == LocalPlayer or ESPObjects[player] then return end
    ESPObjects[player] = ESPClass.new(player)
end
local function RemoveESP(player)
    if ESPObjects[player] then ESPObjects[player]:Destroy(); ESPObjects[player] = nil end
end

RunService.Heartbeat:Connect(function()
    for player, obj in pairs(ESPObjects) do
        if player and player.Parent then obj:Update() else RemoveESP(player) end
    end
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            if getgenv().ESP.Enabled then RemoveESP(player); CreateESP(player) end
        end)
        if getgenv().ESP.Enabled then CreateESP(player) end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if getgenv().ESP.Enabled then RemoveESP(player); CreateESP(player) end
    end)
    if getgenv().ESP.Enabled then CreateESP(player) end
end)

Players.PlayerRemoving:Connect(RemoveESP)

-- ═══════════════════════════════════════════════════════
-- NPC ESP SYSTEM  (workspace.AiZones)
-- ═══════════════════════════════════════════════════════
local NPCScreenGui = Instance.new("ScreenGui")
NPCScreenGui.Name = "NPCScreenGui"
NPCScreenGui.ResetOnSpawn = false
NPCScreenGui.IgnoreGuiInset = true
NPCScreenGui.Parent = game:GetService("CoreGui")

local NPCObjects = {}   -- [model] = NPCObj
local NPCClass   = {}
NPCClass.__index = NPCClass

function NPCClass.new(model)
    local self = setmetatable({}, NPCClass)
    self.model = model
    self.box = {}; self.healthBar = {}; self.labels = {}; self.highlight = nil
    self:CreateUI()
    self:CreateHighlight()
    return self
end

function NPCClass:CreateUI()
    self.container = Instance.new("Frame")
    self.container.Name = self.model.Name .. "_NPC"
    self.container.Size = UDim2.new(0,100,0,100)
    self.container.BackgroundTransparency = 1
    self.container.BorderSizePixel = 0
    self.container.Parent = NPCScreenGui

    -- Box
    local box = Instance.new("Frame")
    box.BackgroundColor3 = getgenv().NPC.Box.Color
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Size = UDim2.new(1,0,1,0)
    box.Parent = self.container
    local stroke = Instance.new("UIStroke")
    stroke.Color = getgenv().NPC.Box.Color
    stroke.Thickness = getgenv().NPC.Box.Thickness
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = box
    self.box.frame = box; self.box.stroke = stroke

    -- Health bar
    local cont = Instance.new("Frame")
    cont.Size = UDim2.new(0, getgenv().NPC.HealthBar.Width, 1, 4)
    cont.Position = UDim2.new(0,-8,0,-2)
    cont.BackgroundColor3 = Color3.fromRGB(20,20,20)
    cont.BackgroundTransparency = 0.3
    cont.BorderSizePixel = 0
    cont.Parent = self.container
    Instance.new("UIStroke", cont).Color = Color3.fromRGB(0,0,0)
    local gradFrame = Instance.new("Frame")
    gradFrame.Size = UDim2.new(1,0,1,0)
    gradFrame.BackgroundTransparency = 0
    gradFrame.BorderSizePixel = 0
    gradFrame.ZIndex = 1
    gradFrame.Parent = cont
    local grad = Instance.new("UIGradient")
    grad.Rotation = 90
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(255,0,0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,255,0)),
    })
    grad.Parent = gradFrame
    local mask = Instance.new("Frame")
    mask.Size = UDim2.new(1,0,0,0)
    mask.BackgroundColor3 = Color3.fromRGB(20,20,20)
    mask.BorderSizePixel = 0
    mask.ZIndex = 2
    mask.Parent = cont
    Instance.new("UICorner", cont).CornerRadius = UDim.new(0,2)
    self.healthBar.container = cont
    self.healthBar.gradient  = gradFrame
    self.healthBar.mask      = mask

    -- Labels
    local function label(name, size, color, pos, anchor, align)
        local l = Instance.new("TextLabel")
        l.Name = name
        l.BackgroundTransparency = 1
        l.Size = UDim2.new(1,40,0,size+4)
        l.Position = pos
        l.AnchorPoint = anchor or Vector2.new(0,0)
        l.TextColor3 = color
        l.TextSize = size
        l.Font = getgenv().NPC.Font
        l.TextStrokeTransparency = 0
        l.TextStrokeColor3 = Color3.fromRGB(0,0,0)
        l.TextXAlignment = align or Enum.TextXAlignment.Center
        l.Parent = self.container
        return l
    end
    self.labels.name = label("NameLabel", 14,
        getgenv().NPC.Name.Color,
        UDim2.new(0.5,0,0,-20), Vector2.new(0.5,1))
    self.labels.name.Text = self.model.Name
    self.labels.health = label("HealthText", 12,
        getgenv().NPC.HealthText.Color,
        UDim2.new(0,-35,0.5,0), Vector2.new(1,0.5),
        Enum.TextXAlignment.Right)
    self.labels.health.Size = UDim2.new(0,50,0,16)
    self.labels.health.Text = "100"
    self.labels.distance = label("DistLabel", 12,
        Color3.fromRGB(200,200,200),
        UDim2.new(0.5,0,1,5), Vector2.new(0.5,0))
    self.labels.distance.Size = UDim2.new(1,40,0,16)
    self.labels.distance.Text = "0m"
end

function NPCClass:CreateHighlight()
    local hl = Instance.new("Highlight")
    hl.Adornee = self.model
    hl.FillColor           = getgenv().NPC.Highlight.FillColor
    hl.OutlineColor        = getgenv().NPC.Highlight.OutlineColor
    hl.FillTransparency    = getgenv().NPC.Highlight.FillTransparency
    hl.OutlineTransparency = getgenv().NPC.Highlight.OutlineTransparency
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled   = getgenv().NPC.Highlight.Enabled
    hl.Parent    = self.model
    self.highlight = hl
end

function NPCClass:UpdateHighlight()
    if not self.highlight or self.highlight.Parent ~= self.model then
        if self.highlight then self.highlight:Destroy() end
        self:CreateHighlight()
    end
    if self.highlight then
        local h = getgenv().NPC.Highlight
        self.highlight.Enabled             = h.Enabled and getgenv().NPC.Enabled
        self.highlight.FillColor           = h.FillColor
        self.highlight.OutlineColor        = h.OutlineColor
        self.highlight.FillTransparency    = h.FillTransparency
        self.highlight.OutlineTransparency = h.OutlineTransparency
    end
end

function NPCClass:Hide()
    self.container.Visible = false
    if self.highlight then self.highlight.Enabled = false end
end

function NPCClass:Update()
    if not Camera or not Camera.Parent then Camera = workspace.CurrentCamera end
    if not getgenv().NPC.Enabled then self:Hide() return end
    if not self.model or not self.model.Parent then self:Hide() return end

    local nhum  = self.model:FindFirstChildOfClass("Humanoid")
    local nroot = self.model:FindFirstChild("HumanoidRootPart")
    local nhead = self.model:FindFirstChild("Head")

    if not nhum or not nroot or not nhead or nhum.Health <= 0 then self:Hide() return end

    local dist = (nroot.Position - Camera.CFrame.Position).Magnitude
    if dist > getgenv().NPC.MaxDistance then self:Hide() return end

    local rootSP, _ = Camera:WorldToViewportPoint(nroot.Position)
    if rootSP.Z <= 0 then self:Hide() return end

    local topWorld = nhead.Position + Vector3.new(0, 0.7, 0)
    local botWorld = nroot.Position - Vector3.new(0, 2.8, 0)
    local topSP = Camera:WorldToViewportPoint(topWorld)
    local botSP = Camera:WorldToViewportPoint(botWorld)
    if topSP.Z <= 0 or botSP.Z <= 0 then self:Hide() return end

    local height = math.max(math.abs(topSP.Y - botSP.Y), 4)
    local width  = math.max(height * 0.55, 4)
    local midX   = (topSP.X + botSP.X) * 0.5
    local midY   = (topSP.Y + botSP.Y) * 0.5

    self.container.Size     = UDim2.new(0, width, 0, height)
    self.container.Position = UDim2.new(0, midX - width * 0.5, 0, midY - height * 0.5)
    self.container.Visible  = true

    if getgenv().NPC.Box.Enabled then
        self.box.frame.Visible = true
        self.box.frame.BackgroundColor3 = getgenv().NPC.Box.Color
        self.box.frame.BackgroundTransparency =
            getgenv().NPC.Box.Filled and getgenv().NPC.Box.FillTransparency or 1
        self.box.stroke.Color     = getgenv().NPC.Box.Color
        self.box.stroke.Thickness = getgenv().NPC.Box.Thickness
        self.box.stroke.Enabled   = true
    else
        self.box.frame.Visible  = false
        self.box.stroke.Enabled = false
    end

    local hp = math.clamp(nhum.Health / nhum.MaxHealth, 0, 1)
    if getgenv().NPC.HealthBar.Enabled then
        self.healthBar.container.Visible = true
        self.healthBar.container.Size    = UDim2.new(0, getgenv().NPC.HealthBar.Width, 1, 4)
        self.healthBar.gradient.Visible  = true
        self.healthBar.mask.Visible      = true
        self.healthBar.mask.Size         = UDim2.new(1, 0, 1 - hp, 0)
    else
        self.healthBar.container.Visible = false
    end

    if getgenv().NPC.HealthText.Enabled then
        self.labels.health.Visible    = true
        self.labels.health.Text       = tostring(math.floor(nhum.Health))
        self.labels.health.TextColor3 = getgenv().NPC.HealthText.Color
        self.labels.health.TextSize   = getgenv().NPC.HealthText.Size
    else
        self.labels.health.Visible = false
    end

    if getgenv().NPC.Name.Enabled then
        self.labels.name.Visible    = true
        self.labels.name.TextColor3 = getgenv().NPC.Name.Color
        self.labels.name.TextSize   = getgenv().NPC.Name.Size
        self.labels.name.TextStrokeTransparency = getgenv().NPC.Name.Outline and 0 or 1
    else
        self.labels.name.Visible = false
    end

    self.labels.distance.Visible = true
    self.labels.distance.Text    = math.floor(dist) .. "m"

    self:UpdateHighlight()
end

function NPCClass:Destroy()
    if self.container then self.container:Destroy() end
    if self.highlight  then self.highlight:Destroy() end
    setmetatable(self, nil)
end

local function CreateNPC(model)
    if NPCObjects[model] then return end
    NPCObjects[model] = NPCClass.new(model)
end
local function RemoveNPC(model)
    if NPCObjects[model] then NPCObjects[model]:Destroy(); NPCObjects[model] = nil end
end

-- Update loop — also discovers new AIs that spawn after script loads
local _npcScanTimer = 0
RunService.Heartbeat:Connect(function(dt)
    -- Update all existing NPC ESP objects, prune dead ones
    for model, obj in pairs(NPCObjects) do
        if model and model.Parent then
            obj:Update()
        else
            RemoveNPC(model)
        end
    end

    if not getgenv().NPC.Enabled then return end

    -- Re-scan AiZones every 2s to pick up newly spawned AIs
    _npcScanTimer = _npcScanTimer - dt
    if _npcScanTimer > 0 then return end
    _npcScanTimer = 2

    local aiZones = workspace:FindFirstChild("AiZones")
    if not aiZones then return end
    for _, zone in pairs(aiZones:GetChildren()) do
        for _, model in pairs(zone:GetChildren()) do
            if model:IsA("Model") and model:FindFirstChildOfClass("Humanoid") then
                if not NPCObjects[model] then
                    CreateNPC(model)
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════
-- DROPPED ITEM ESP
-- ═══════════════════════════════════════════════════════
local ItemESPLabels = {}

local function getItemCategory(item)
    if WeaponNames[item.Name] then return "weapon"
    elseif AmmoNames[item.Name] then return "ammo"
    else return "junk" end
end

local function createItemLabel(item)
    if ItemESPLabels[item] then return end
    local lbl = Drawing.new("Text")
    lbl.Size         = 14
    lbl.Font         = Drawing.Fonts.UI
    lbl.Outline      = true
    lbl.OutlineColor = Color3.fromRGB(0, 0, 0)
    lbl.Center       = true
    lbl.Visible      = false
    ItemESPLabels[item] = lbl
end

local function removeItemLabel(item)
    local lbl = ItemESPLabels[item]
    if lbl then
        pcall(function() lbl:Remove() end)
        ItemESPLabels[item] = nil
    end
end

-- Initial population + dynamic add/remove
for _, item in ipairs(DropedItems:GetChildren()) do
    createItemLabel(item)
end

DropedItems.ChildAdded:Connect(createItemLabel)
DropedItems.ChildRemoved:Connect(removeItemLabel)

-- Clean & fast update loop (only existing items, no GetChildren spam)
RunService.RenderStepped:Connect(function()
    local cam = workspace.CurrentCamera
    if not cam then return end

    local iesp = getgenv().ItemESP
    local anyActive = iesp.WeaponESP or iesp.AmmoESP or iesp.JunkESP

    for item, lbl in pairs(ItemESPLabels) do
        if not item or not item.Parent then
            removeItemLabel(item)
            continue
        end

        local cat = getItemCategory(item)
        local show = (cat == "weapon" and iesp.WeaponESP)
                  or (cat == "ammo"   and iesp.AmmoESP)
                  or (cat == "junk"   and iesp.JunkESP)

        if show then
            local part = item:IsA("BasePart") and item or item:FindFirstChildOfClass("BasePart")
            if not part then
                for _, desc in pairs(item:GetDescendants()) do
                    if desc:IsA("BasePart") then part = desc; break end
                end
            end
            if part then
                local sp, onScreen = cam:WorldToViewportPoint(part.Position + Vector3.new(0, 2.5, 0))
                if onScreen and sp.Z > 0 then
                    lbl.Text     = item.Name
                    lbl.Position = Vector2.new(sp.X, sp.Y)
                    lbl.Color    = cat == "weapon" and (iesp.WeaponColor or Color3.fromRGB(165,127,159))
                                or cat == "ammo"   and (iesp.AmmoColor   or Color3.fromRGB(165,127,159))
                                or                     (iesp.JunkColor   or Color3.fromRGB(165,127,159))
                    lbl.Visible  = true
                else
                    lbl.Visible = false
                end
            end
        else
            lbl.Visible = false
        end
    end
end)

-- ═══════════════════════════════════════════════════════
-- WEAPON CHAM SYSTEM
-- ═══════════════════════════════════════════════════════
local _chamOriginals = {}   -- [part] = { Material, Color, surfaceAppearances }
local _chamApplied   = false

local function getChamEnum()
    local m = getgenv().WeaponCham.Material
    if m == "ForceField" then return Enum.Material.ForceField end
    return Enum.Material.Neon
end

local function getWeaponItem()
    local cam = workspace:FindFirstChild("Camera") or workspace.CurrentCamera
    if not cam then return nil end
    local vm = cam:FindFirstChild("ViewModel")
    if not vm then return nil end
    return vm:FindFirstChild("Item")
end

local function applyWeaponChams()
    local item = getWeaponItem()
    if not item then return end

    local mat   = getChamEnum()
    local color = getgenv().WeaponCham.Color

    for _, part in pairs(item:GetDescendants()) do
        if not part:IsA("BasePart") then continue end
        if part.Transparency == 1    then continue end

        -- Save original state once per part (clears on removeWeaponChams)
        if not _chamOriginals[part] then
            local sas = {}
            for _, child in pairs(part:GetChildren()) do
                if child:IsA("SurfaceAppearance") then
                    table.insert(sas, child)
                end
            end
            _chamOriginals[part] = {
                Material           = part.Material,
                Color              = part.Color,
                surfaceAppearances = sas,
            }
        end

        -- Apply cham
        pcall(function()
            part.Material = mat
            part.Color    = color
        end)

        -- Hide SurfaceAppearances by deparenting them
        for _, sa in pairs(_chamOriginals[part].surfaceAppearances) do
            pcall(function()
                if sa.Parent then sa.Parent = nil end
            end)
        end
    end
    _chamApplied = true
end

local function removeWeaponChams()
    for part, data in pairs(_chamOriginals) do
        pcall(function()
            if part and part.Parent then
                part.Material = data.Material
                part.Color    = data.Color
                for _, sa in pairs(data.surfaceAppearances) do
                    if sa and not sa.Parent then
                        sa.Parent = part
                    end
                end
            end
        end)
    end
    _chamOriginals = {}
    _chamApplied   = false
end

-- Heartbeat: continuously apply chams so they survive weapon switches
RunService.Heartbeat:Connect(function()
    if not getgenv().WeaponCham.Enabled then
        if _chamApplied then removeWeaponChams() end
        return
    end
    applyWeaponChams()
end)

-- ═══════════════════════════════════════════════════════
-- ARM CHAM SYSTEM  (6 arm parts + Clothing ShirtTemplate)
-- Targets: RightUpperArm, RightLowerArm, LeftUpperArm,
--          LeftLowerArm, RightHand, LeftHand
-- Hides the shirt texture by blanking ShirtTemplate (saved
-- and restored when the cham is disabled).
-- ═══════════════════════════════════════════════════════
local ARM_PART_NAMES = {
    "RightUpperArm", "RightLowerArm",
    "LeftUpperArm",  "LeftLowerArm",
    "RightHand",     "LeftHand",
}

local _armChamOriginals   = {}    -- [partName] = { Material, Color }
local _armChamApplied     = false
local _savedShirtTemplate = nil   -- Clothing.ShirtTemplate saved value

local function getArmChamEnum()
    local m = getgenv().ArmCham.Material
    if m == "ForceField" then return Enum.Material.ForceField end
    return Enum.Material.Neon
end

local function getViewModel()
    local cam = workspace.CurrentCamera
    if not cam then return nil end
    return cam:FindFirstChild("ViewModel")
end

local function applyArmChams()
    local vm = getViewModel()
    if not vm then return end

    local mat   = getArmChamEnum()
    local color = getgenv().ArmCham.Color

    -- Save + blank the ShirtTemplate so the skin texture disappears cleanly
    local clothing = vm:FindFirstChild("Clothing")
    if clothing then
        if _savedShirtTemplate == nil then
            -- save only once; nil means "not yet saved"
            _savedShirtTemplate = clothing.ShirtTemplate
        end
        pcall(function() clothing.ShirtTemplate = "" end)
    end

    -- Apply material + color to every arm part
    for _, partName in ipairs(ARM_PART_NAMES) do
        local part = vm:FindFirstChild(partName)
        if not part or not part:IsA("BasePart") then continue end
        if part.Transparency == 1 then continue end

        -- Save original values the first time we touch this part
        if not _armChamOriginals[partName] then
            _armChamOriginals[partName] = {
                Material = part.Material,
                Color    = part.Color,
            }
        end

        pcall(function()
            part.Material = mat
            part.Color    = color
        end)
    end

    _armChamApplied = true
end

local function removeArmChams()
    local vm = getViewModel()

    -- Restore ShirtTemplate
    if _savedShirtTemplate ~= nil then
        if vm then
            local clothing = vm:FindFirstChild("Clothing")
            if clothing then
                pcall(function() clothing.ShirtTemplate = _savedShirtTemplate end)
            end
        end
        _savedShirtTemplate = nil
    end

    -- Restore arm part materials and colors
    if vm then
        for partName, data in pairs(_armChamOriginals) do
            local part = vm:FindFirstChild(partName)
            if part and part:IsA("BasePart") then
                pcall(function()
                    part.Material = data.Material
                    part.Color    = data.Color
                end)
            end
        end
    end

    _armChamOriginals = {}
    _armChamApplied   = false
end

-- Heartbeat: keep arm chams alive across weapon switches / respawns
RunService.Heartbeat:Connect(function()
    if not getgenv().ArmCham.Enabled then
        if _armChamApplied then removeArmChams() end
        return
    end
    applyArmChams()
end)

-- ═══════════════════════════════════════════════════════
-- SKYBOX SYSTEM
-- ═══════════════════════════════════════════════════════
local Sky = Lighting:FindFirstChildOfClass("Sky")
if not Sky then
    Sky = Instance.new("Sky", Lighting)
end
local OriginalSkyboxData = {
    SkyboxBk = Sky.SkyboxBk, SkyboxDn = Sky.SkyboxDn,
    SkyboxFt = Sky.SkyboxFt, SkyboxLf = Sky.SkyboxLf,
    SkyboxRt = Sky.SkyboxRt, SkyboxUp = Sky.SkyboxUp,
}
local SkyBoxes = {
    ["Standard"]    = OriginalSkyboxData,
    ["Among Us"]    = { SkyboxBk="rbxassetid://5752463190",SkyboxDn="rbxassetid://5752463190",SkyboxFt="rbxassetid://5752463190",SkyboxLf="rbxassetid://5752463190",SkyboxRt="rbxassetid://5752463190",SkyboxUp="rbxassetid://5752463190" },
    ["Doge"]        = { SkyboxBk="rbxassetid://159713165",SkyboxDn="rbxassetid://159713165",SkyboxFt="rbxassetid://5752463190",SkyboxLf="rbxassetid://5752463190",SkyboxRt="rbxassetid://159713165",SkyboxUp="rbxassetid://159713165" },
    ["Spongebob"]   = { SkyboxBk="rbxassetid://277099484",SkyboxDn="rbxassetid://277099500",SkyboxFt="rbxassetid://277099554",SkyboxLf="rbxassetid://277099531",SkyboxRt="rbxassetid://277099589",SkyboxUp="rbxassetid://277101591" },
    ["Deep Space"]  = { SkyboxBk="rbxassetid://159248188",SkyboxDn="rbxassetid://159248183",SkyboxFt="rbxassetid://159248187",SkyboxLf="rbxassetid://159248173",SkyboxRt="rbxassetid://159248192",SkyboxUp="rbxassetid://159248176" },
    ["Winter"]      = { SkyboxBk="rbxassetid://510645155",SkyboxDn="rbxassetid://510645130",SkyboxFt="rbxassetid://510645179",SkyboxLf="rbxassetid://510645117",SkyboxRt="rbxassetid://510645146",SkyboxUp="rbxassetid://510645195" },
    ["Clouded Sky"] = { SkyboxBk="rbxassetid://252760981",SkyboxDn="rbxassetid://252763035",SkyboxFt="rbxassetid://252761439",SkyboxLf="rbxassetid://252760980",SkyboxRt="rbxassetid://252760986",SkyboxUp="rbxassetid://252762652" },
    ["Night Sky"]   = { SkyboxBk="rbxassetid://159454299",SkyboxDn="rbxassetid://159454296",SkyboxFt="rbxassetid://159454293",SkyboxLf="rbxassetid://159454286",SkyboxRt="rbxassetid://159454300",SkyboxUp="rbxassetid://159454288" },
    ["Bluesky"]     = { SkyboxBk="rbxassetid://276045503",SkyboxDn="rbxassetid://276045640",SkyboxFt="rbxassetid://276045513",SkyboxLf="rbxassetid://276045489",SkyboxRt="rbxassetid://276045525",SkyboxUp="rbxassetid://276045547" },
}
local function applySkybox(name)
    local data = SkyBoxes[name] or OriginalSkyboxData
    for face, asset in pairs(data) do Sky[face] = asset end
end

-- ═══════════════════════════════════════════════════════
-- SMOOTH CROSSHAIR (follows mouse with lerp)
-- ═══════════════════════════════════════════════════════
local crosshairEnabled = false
local crosshairColor   = Color3.fromRGB(255, 255, 255)
local crosshairSize    = 8
local crosshairThick   = 1.5
local crosshairGap     = 4
local crosshairSmooth  = 0.25  -- 0=instant, 1=never arrives

local crosshairPos = UserInputService:GetMouseLocation()

-- 4 lines: top, bottom, left, right
local crossLines = {}
for i = 1, 4 do
    local l = Drawing.new("Line")
    l.Thickness = crosshairThick
    l.Color     = crosshairColor
    l.Transparency = 1
    l.Visible   = false
    crossLines[i] = l
end

RunService.RenderStepped:Connect(function()
    if not crosshairEnabled then
        for _, l in ipairs(crossLines) do l.Visible = false end
        return
    end

    local mouse  = UserInputService:GetMouseLocation()
    crosshairPos = crosshairPos:Lerp(mouse, 1 - crosshairSmooth)
    local cx, cy = crosshairPos.X, crosshairPos.Y

    -- top
    crossLines[1].From = Vector2.new(cx,              cy - crosshairGap - crosshairSize)
    crossLines[1].To   = Vector2.new(cx,              cy - crosshairGap)
    -- bottom
    crossLines[2].From = Vector2.new(cx,              cy + crosshairGap)
    crossLines[2].To   = Vector2.new(cx,              cy + crosshairGap + crosshairSize)
    -- left
    crossLines[3].From = Vector2.new(cx - crosshairGap - crosshairSize, cy)
    crossLines[3].To   = Vector2.new(cx - crosshairGap,                  cy)
    -- right
    crossLines[4].From = Vector2.new(cx + crosshairGap,                  cy)
    crossLines[4].To   = Vector2.new(cx + crosshairGap + crosshairSize,  cy)

    for _, l in ipairs(crossLines) do
        l.Color     = crosshairColor
        l.Thickness = crosshairThick
        l.Visible   = true
    end
end)

-- ═══════════════════════════════════════════════════════
-- HIT EFFECT — spinning crosshair at bullet impact point
-- ═══════════════════════════════════════════════════════
local hitEffectEnabled = true
local hitEffectColor   = Color3.fromRGB(255, 60, 60)
local hitEffectSize    = 14
local hitEffectDur     = 0.45   -- seconds to live
local hitEffectThick   = 1.8

local function spawnHitEffect(worldPos)
    if not hitEffectEnabled then return end
    local sp, onScreen = Camera:WorldToViewportPoint(worldPos)
    if not onScreen or sp.Z <= 0 then return end

    local sx, sy = sp.X, sp.Y
    local lines  = {}
    for i = 1, 4 do
        local l = Drawing.new("Line")
        l.Thickness    = hitEffectThick
        l.Color        = hitEffectColor
        l.Transparency = 1
        l.Visible      = true
        lines[i]       = l
    end

    local angle   = 0
    local elapsed = 0
    local conn
    conn = RunService.RenderStepped:Connect(function(dt)
        elapsed = elapsed + dt
        if elapsed >= hitEffectDur then
            for _, l in ipairs(lines) do l:Remove() end
            conn:Disconnect()
            return
        end

        -- Fade out
        local alpha = 1 - (elapsed / hitEffectDur)
        -- Spin
        angle = angle + 360 * dt * 3   -- 3 full spins per second

        -- Update screen position (follow world point if possible)
        local nsp, nos = Camera:WorldToViewportPoint(worldPos)
        if nos and nsp.Z > 0 then sx, sy = nsp.X, nsp.Y end

        for i, l in ipairs(lines) do
            local a = math.rad(angle + (i - 1) * 90)
            local inner = hitEffectSize * 0.3
            local outer = hitEffectSize * (0.3 + alpha * 0.7)
            l.From = Vector2.new(sx + math.cos(a) * inner, sy + math.sin(a) * inner)
            l.To   = Vector2.new(sx + math.cos(a) * outer, sy + math.sin(a) * outer)
            l.Color        = hitEffectColor
            l.Transparency = alpha
        end
    end)
end

-- ═══════════════════════════════════════════════════════
-- ELEMENT REGISTRY  (auto-captures every Add* return)
-- Wrap groupbox methods so every element is stored by id
-- ═══════════════════════════════════════════════════════
local _reg = {}   -- [id] = { elem, type }

local function _wrap(group)
    local orig_toggle    = group.AddToggle
    local orig_slider    = group.AddSlider
    local orig_dropdown  = group.AddDropdown
    local orig_colorpick = group.AddColorPicker
    local orig_label     = group.AddLabel
    local orig_keypicker = group.AddKeyPicker

    group.AddToggle = function(self, id, opts)
        local e = orig_toggle(self, id, opts)
        -- store both Callback and ColorCallback so applySnapshot can re-fire them
        _reg[id] = { elem = e, kind = "Toggle", cb = opts and opts.Callback, colorCb = opts and opts.ColorCallback }
        return e
    end
    group.AddSlider = function(self, id, opts)
        local e = orig_slider(self, id, opts)
        -- store Callback so applySnapshot can re-fire it (SetValue doesn't call it)
        _reg[id] = { elem = e, kind = "Slider", cb = opts and opts.Callback }
        return e
    end
    group.AddDropdown = function(self, id, opts)
        local e = orig_dropdown(self, id, opts)
        -- store Callback so applySnapshot can re-fire it if SetValue doesn't
        _reg[id] = { elem = e, kind = "Dropdown", cb = opts and opts.Callback }
        return e
    end
    -- Track standalone color pickers added directly on a groupbox
    if orig_colorpick then
        group.AddColorPicker = function(self, id, opts)
            local e = orig_colorpick(self, id, opts)
            _reg[id] = { elem = e, kind = "ColorPicker", cb = opts and opts.Callback }
            return e
        end
    end
    -- Track keybinds so they are saved/loaded with configs
    if orig_keypicker then
        group.AddKeyPicker = function(self, id, opts)
            local e = orig_keypicker(self, id, opts)
            _reg[id] = { elem = e, kind = "KeyPicker", cb = opts and opts.Callback }
            return e
        end
    end
    -- Wrap AddLabel so chained :AddColorPicker("id", {...}) is also tracked
    if orig_label then
        group.AddLabel = function(self, text)
            local lbl = orig_label(self, text)
            if lbl and lbl.AddColorPicker then
                local origLblCP = lbl.AddColorPicker
                lbl.AddColorPicker = function(lself, id, opts)
                    local e = origLblCP(lself, id, opts)
                    _reg[id] = { elem = e, kind = "ColorPicker", cb = opts and opts.Callback }
                    return e
                end
            end
            return lbl
        end
    end
    return group
end

-- Wrap AddLeftGroupbox / AddRightGroupbox on a tab
local function _wrapTab(tab)
    local origL = tab.AddLeftGroupbox
    local origR = tab.AddRightGroupbox
    tab.AddLeftGroupbox = function(self, name)
        return _wrap(origL(self, name))
    end
    tab.AddRightGroupbox = function(self, name)
        return _wrap(origR(self, name))
    end
    return tab
end

local Window = UILibrary.new({
    Name          = "ZestHub",
    ToggleKey     = Enum.KeyCode.RightShift,
    CloseKey      = Enum.KeyCode.X,
    DefaultColor  = Color3.fromRGB(165, 127, 159),
    TextColor     = Color3.fromRGB(200, 200, 200),
    Size          = UDim2.new(0, 570, 0, 469),
    Position      = UDim2.new(0.226, 0, 0.146, 0),
    Watermark     = true,
    WatermarkText = "ZestHub",
})

-- Wrap AddTab so every tab auto-wraps its groupboxes
local _origAddTab = Window.AddTab
Window.AddTab = function(self, name)
    return _wrapTab(_origAddTab(self, name))
end

-- ── Combat Tab ────────────────────────────────────────
local CombatTab = Window:AddTab("Combat")
local AimLeft   = CombatTab:AddLeftGroupbox("Aimbot")
local AimRight  = CombatTab:AddRightGroupbox("Settings")

AimLeft:AddToggle("AimbotToggle", {
    Text = "Enable Aimbot", Default = false,
    Callback = function(v) getgenv().Aimbot.Enabled = v end,
})

AimLeft:AddToggle("SilentAimToggle", {
    Text = "Silent Aim", Default = false,
    Callback = function(v) getgenv().Aimbot.SilentAim = v end,
})
AimRight:AddSlider("LiftScaleSlider", {
    Text = "Bullet Drop Compensation", Min = 0, Max = 10, Default = 1, Rounding = 2,
    Callback = function(v) getgenv().Aimbot.LiftScale = v end,
})
AimLeft:AddToggle("ShowFOVToggle", {
    Text = "Show FOV Circle", Default = false,
    HasColorPicker = true,
    Callback      = function(v) getgenv().Aimbot.ShowFOV  = v end,
    ColorCallback = function(c) getgenv().Aimbot.FOVColor = c end,
})
AimLeft:AddToggle("WallCheckToggle", {
    Text = "Wall Check", Default = true,
    Callback = function(v) getgenv().Aimbot.WallCheck = v end,
})
AimLeft:AddToggle("PredictionToggle", {
    Text = "Prediction (lead targets)", Default = true,
    Callback = function(v) getgenv().Aimbot.Prediction = v end,
})
AimLeft:AddToggle("TargetAIToggle", {
    Text = "Target AI", Default = false,
    Tooltip = "Also target NPC/AI models in workspace",
    Callback = function(v) getgenv().Aimbot.TargetAI = v end,
})
AimLeft:AddToggle("TargetLineToggle", {
    Text = "Target Line", Default = false,
    HasColorPicker = true,
    Callback      = function(v) getgenv().Aimbot.TargetLine = v end,
    ColorCallback = function(c)
        getgenv().Aimbot.TargetLineColor = c
        TargetLine.Color = c
    end,
})
AimLeft:AddToggle("AutoShootToggle", {
    Text = "Auto Shoot", Default = false,
    Callback = function(v) getgenv().Aimbot.AutoShoot = v end,
})
AimLeft:AddToggle("InstantHitToggle", {
    Text = "Instant Hit", Default = false,
    Tooltip = "Redirects bullet raycasts straight at target — needs a target in FOV",
    Callback = function(v) getgenv().Aimbot.InstantHit = v end,
})
AimLeft:AddSlider("AutoShootRateSlider", {
    Text = "Auto Shoot Rate (s)", Min = 0.05, Max = 1, Default = 0.12, Rounding = 2,
    Callback = function(v) getgenv().Aimbot.AutoShootRate = v end,
})
AimLeft:AddSlider("FOVSlider", {
    Text = "FOV Size", Min = 1, Max = 500, Default = 100, Rounding = 1,
    Callback = function(v) getgenv().Aimbot.FOV = v end,
})
AimLeft:AddSlider("HitChanceSlider", {
    Text = "Hit Chance %", Min = 1, Max = 100, Default = 100, Rounding = 1,
    Callback = function(v) getgenv().Aimbot.HitChance = v end,
})

AimRight:AddDropdown("TargetPartDropdown", {
    Text = "Target Part",
    Values = {"Head","HumanoidRootPart","Torso","UpperTorso"},
    Default = 1,
    Callback = function(v) getgenv().Aimbot.TargetPart = v end,
})
AimRight:AddToggle("InstantEquipToggle", {
    Text = "Instant Equip", Default = false,
    Callback = function(v) getgenv().GunMods.InstantEquip = v end,
})
AimRight:AddToggle("BulletTracersToggle", {
    Text = "Bullet Tracers", Default = false,
    HasColorPicker = true,
    Callback      = function(v) getgenv().BulletTracers.Enabled = v end,
    ColorCallback = function(c) getgenv().BulletTracers.Color   = c end,
})
AimRight:AddSlider("TracerSizeSlider", {
    Text = "Tracer Size", Min = 0.1, Max = 2, Default = 0.3, Rounding = 2,
    Callback = function(v) getgenv().BulletTracers.Size = v end,
})
AimRight:AddSlider("TracerTimeSlider", {
    Text = "Tracer Duration", Min = 0.5, Max = 5, Default = 2, Rounding = 1,
    Callback = function(v) getgenv().BulletTracers.TimeAlive = v end,
})

-- ── Visuals Tab ───────────────────────────────────────
local VisualsTab     = Window:AddTab("Visuals")
local ESPGroup       = VisualsTab:AddLeftGroupbox("ESP")
local HighlightGroup = VisualsTab:AddRightGroupbox("Highlight")

ESPGroup:AddToggle("ESPMasterToggle", {
    Text = "Enable ESP", Default = false,
    Callback = function(v)
        getgenv().ESP.Enabled = v
        if v then
            for _, p in ipairs(Players:GetPlayers()) do CreateESP(p) end
        else
            for p in pairs(ESPObjects) do RemoveESP(p) end
        end
    end,
})
ESPGroup:AddSlider("ESPDistSlider", {
    Text = "Max Distance", Min = 100, Max = 5000, Default = 1000, Rounding = 0,
    Callback = function(v) getgenv().ESP.MaxDistance = v end,
})
ESPGroup:AddToggle("ESPBoxToggle", {
    Text = "Box", Default = false,
    HasColorPicker = true,
    Callback      = function(v) getgenv().ESP.Box.Enabled = v end,
    ColorCallback = function(c) getgenv().ESP.Box.Color   = c end,
})
ESPGroup:AddToggle("ESPHealthBarToggle", {
    Text = "Health Bar", Default = false,
    Callback = function(v) getgenv().ESP.HealthBar.Enabled = v end,
})
ESPGroup:AddToggle("ESPHealthTextToggle", {
    Text = "Health Text", Default = false,
    HasColorPicker = true,
    Callback      = function(v) getgenv().ESP.HealthText.Enabled = v end,
    ColorCallback = function(c) getgenv().ESP.HealthText.Color   = c end,
})
ESPGroup:AddToggle("ESPNameToggle", {
    Text = "Name", Default = false,
    HasColorPicker = true,
    Callback      = function(v) getgenv().ESP.Name.Enabled = v end,
    ColorCallback = function(c) getgenv().ESP.Name.Color   = c end,
})

HighlightGroup:AddToggle("HighlightToggle", {
    Text = "Enable Highlight", Default = false,
    HasColorPicker = true,
    Callback      = function(v) getgenv().ESP.Highlight.Enabled   = v end,
    ColorCallback = function(c) getgenv().ESP.Highlight.FillColor = c end,
})
HighlightGroup:AddToggle("HighlightOutlineToggle", {
    Text = "Outline Color", Default = false,
    HasColorPicker = true,
    Callback      = function(v) getgenv().ESP.Highlight.OutlineTransparency = v and 0 or 1 end,
    ColorCallback = function(c) getgenv().ESP.Highlight.OutlineColor = c end,
})
HighlightGroup:AddSlider("HLFillTrans", {
    Text = "Fill Transparency", Min = 0, Max = 1, Default = 0.5, Rounding = 2,
    Callback = function(v) getgenv().ESP.Highlight.FillTransparency = v end,
})
HighlightGroup:AddSlider("HLOutlineTrans", {
    Text = "Outline Transparency", Min = 0, Max = 1, Default = 0, Rounding = 2,
    Callback = function(v) getgenv().ESP.Highlight.OutlineTransparency = v end,
})

-- ── NPC ESP ───────────────────────────────────────────
local NPCGroup      = VisualsTab:AddLeftGroupbox("NPC ESP")
local NPCHLGroup    = VisualsTab:AddRightGroupbox("NPC Highlight")

NPCGroup:AddToggle("NPCMasterToggle", {
    Text = "Enable NPC ESP", Default = false,
    Callback = function(v)
        getgenv().NPC.Enabled = v
        if not v then
            for model in pairs(NPCObjects) do RemoveNPC(model) end
        end
    end,
})
NPCGroup:AddSlider("NPCDistSlider", {
    Text = "Max Distance", Min = 100, Max = 5000, Default = 1000, Rounding = 0,
    Callback = function(v) getgenv().NPC.MaxDistance = v end,
})
NPCGroup:AddToggle("NPCBoxToggle", {
    Text = "Box", Default = false,
    HasColorPicker = true,
    Callback      = function(v) getgenv().NPC.Box.Enabled = v end,
    ColorCallback = function(c) getgenv().NPC.Box.Color   = c end,
})
NPCGroup:AddToggle("NPCHealthBarToggle", {
    Text = "Health Bar", Default = false,
    Callback = function(v) getgenv().NPC.HealthBar.Enabled = v end,
})
NPCGroup:AddToggle("NPCHealthTextToggle", {
    Text = "Health Text", Default = false,
    HasColorPicker = true,
    Callback      = function(v) getgenv().NPC.HealthText.Enabled = v end,
    ColorCallback = function(c) getgenv().NPC.HealthText.Color   = c end,
})
NPCGroup:AddToggle("NPCNameToggle", {
    Text = "Name", Default = false,
    HasColorPicker = true,
    Callback      = function(v) getgenv().NPC.Name.Enabled = v end,
    ColorCallback = function(c) getgenv().NPC.Name.Color   = c end,
})

NPCHLGroup:AddToggle("NPCHighlightToggle", {
    Text = "Enable Highlight", Default = false,
    HasColorPicker = true,
    Callback      = function(v) getgenv().NPC.Highlight.Enabled   = v end,
    ColorCallback = function(c) getgenv().NPC.Highlight.FillColor = c end,
})
NPCHLGroup:AddToggle("NPCHLOutlineToggle", {
    Text = "Outline Color", Default = false,
    HasColorPicker = true,
    Callback      = function(v) getgenv().NPC.Highlight.OutlineTransparency = v and 0 or 1 end,
    ColorCallback = function(c) getgenv().NPC.Highlight.OutlineColor = c end,
})
NPCHLGroup:AddSlider("NPCHLFillTrans", {
    Text = "Fill Transparency", Min = 0, Max = 1, Default = 0.5, Rounding = 2,
    Callback = function(v) getgenv().NPC.Highlight.FillTransparency = v end,
})
NPCHLGroup:AddSlider("NPCHLOutlineTrans", {
    Text = "Outline Transparency", Min = 0, Max = 1, Default = 0, Rounding = 2,
    Callback = function(v) getgenv().NPC.Highlight.OutlineTransparency = v end,
})

-- ── Dropped Item ESP ──────────────────────────────────
local ItemESPGroup    = VisualsTab:AddLeftGroupbox("Dropped Item ESP")
local PlayerWepGroup  = VisualsTab:AddRightGroupbox("Player Weapon ESP")

ItemESPGroup:AddToggle("ItemWeaponESPToggle", {
    Text          = "Weapon ESP",
    Default       = false,
    HasColorPicker = true,
    Tooltip       = "Show name on dropped weapons",
    Callback      = function(v) getgenv().ItemESP.WeaponESP = v end,
    ColorCallback = function(c) getgenv().ItemESP.WeaponColor = c end,
})
ItemESPGroup:AddToggle("ItemAmmoESPToggle", {
    Text          = "Ammo ESP",
    Default       = false,
    HasColorPicker = true,
    Tooltip       = "Show name on dropped ammo",
    Callback      = function(v) getgenv().ItemESP.AmmoESP = v end,
    ColorCallback = function(c) getgenv().ItemESP.AmmoColor = c end,
})
ItemESPGroup:AddToggle("ItemJunkESPToggle", {
    Text          = "Junk ESP",
    Default       = false,
    HasColorPicker = true,
    Tooltip       = "Show name on all other dropped items",
    Callback      = function(v) getgenv().ItemESP.JunkESP = v end,
    ColorCallback = function(c) getgenv().ItemESP.JunkColor = c end,
})

PlayerWepGroup:AddToggle("PlayerWepHipToggle", {
    Text          = "Weapon Hip  [ItemHip1]",
    Default       = false,
    HasColorPicker = true,
    Tooltip       = "Show player's hip-slot weapon above their ESP box",
    Callback      = function(v) getgenv().PlayerWeaponESP.Hip = v end,
    ColorCallback = function(c) getgenv().PlayerWeaponESP.HipColor = c end,
})
PlayerWepGroup:AddToggle("PlayerWepPrimeToggle", {
    Text          = "Weapon Prime  [ItemBack1/2]",
    Default       = false,
    HasColorPicker = true,
    Tooltip       = "Show player's back/primary weapon above their ESP box",
    Callback      = function(v) getgenv().PlayerWeaponESP.Prime = v end,
    ColorCallback = function(c) getgenv().PlayerWeaponESP.PrimeColor = c end,
})

PlayerWepGroup:AddToggle("PlayerWepEquippedToggle", {
    Text          = "Equipped Gun  [Holding]",
    Default       = false,
    HasColorPicker = true,
    Tooltip       = "Show the gun each player is currently holding (workspace.Player.Holding)",
    Callback      = function(v) getgenv().PlayerWeaponESP.Equipped = v end,
    ColorCallback = function(c) getgenv().PlayerWeaponESP.EquippedColor = c end,
})

PlayerWepGroup:AddDropdown("EquippedDisplayMode", {
    Text    = "Equipped Display Mode",
    Values  = { "Text", "Image" },
    Default = 1,
    Tooltip = "Text = weapon name   |   Image = icon from ReplicatedStorage.ItemsList",
    Callback = function(v)
        getgenv().PlayerWeaponESP.EquippedMode = v
    end,
})

local ChamGroup = VisualsTab:AddLeftGroupbox("Weapon Cham")

ChamGroup:AddToggle("WeaponChamToggle", {
    Text           = "Enable Weapon Cham",
    Default        = false,
    HasColorPicker = true,
    Callback = function(v)
        getgenv().WeaponCham.Enabled = v
        if not v then removeWeaponChams() end
    end,
    ColorCallback = function(c)
        getgenv().WeaponCham.Color = c
        -- Re-apply immediately so the color updates live
        if getgenv().WeaponCham.Enabled then
            removeWeaponChams()
            applyWeaponChams()
        end
    end,
})

ChamGroup:AddDropdown("WeaponChamMaterial", {
    Text    = "Material",
    Values  = { "Neon", "ForceField" },
    Default = 1,
    Callback = function(v)
        getgenv().WeaponCham.Material = v
        -- Re-apply immediately so the material updates live
        if getgenv().WeaponCham.Enabled then
            removeWeaponChams()
            applyWeaponChams()
        end
    end,
})

-- ── Arm Cham ──────────────────────────────────────────
local ArmChamGroup = VisualsTab:AddRightGroupbox("Arm Cham")

ArmChamGroup:AddToggle("ArmChamToggle", {
    Text           = "Enable Arm Cham",
    Default        = false,
    HasColorPicker = true,
    Callback = function(v)
        getgenv().ArmCham.Enabled = v
        if not v then removeArmChams() end
    end,
    ColorCallback = function(c)
        getgenv().ArmCham.Color = c
        -- Live-update color while enabled
        if getgenv().ArmCham.Enabled then
            _armChamOriginals = {}   -- force re-save so restore stays correct
            applyArmChams()
        end
    end,
})

ArmChamGroup:AddDropdown("ArmChamMaterial", {
    Text    = "Material",
    Values  = { "Neon", "ForceField" },
    Default = 1,
    Callback = function(v)
        getgenv().ArmCham.Material = v
        -- Live-update material while enabled
        if getgenv().ArmCham.Enabled then
            removeArmChams()
            applyArmChams()
        end
    end,
})


-- ── Misc Tab ──────────────────────────────────────────
local MiscTab      = Window:AddTab("Misc")
local GunModsGroup = MiscTab:AddLeftGroupbox("Gun Mods")
local HitFXGroup   = MiscTab:AddRightGroupbox("Hit Effects")
local PlayerMisc   = MiscTab:AddLeftGroupbox("Player")
local replicatestorage = game:GetService("ReplicatedStorage")

PlayerMisc:AddToggle("NoJumpCooldownToggle", {
    Text = "No Jump Cooldown", Default = false,
    Callback = function(v) noJumpCooldown = v end,
})
PlayerMisc:AddToggle("Nofall", {
    Text = "Nofall", Default = false,
    Callback = function(v) nofall = v end,
})
PlayerMisc:AddToggle("NoSlowdownToggle", {
    Text = "No Slowdown", Default = false,
    Callback = function(v) SlowDown = v end,
})
PlayerMisc:AddToggle("AntiAimSpinToggle", {
    Text = "AntiAim Spin", Default = false,
    Callback = function(v)
        Spin = v
        local lhum = chr and chr:FindFirstChild("Humanoid")
        if lhum then lhum.AutoRotate = not v end
    end,
})
GunModsGroup:AddToggle("FastAim", {
    Text = "Fast Aim", Default = false,
    Callback = function(v) getgenv().allvars.fastaim = v end,
})
PlayerMisc:AddSlider("SpinSpeedSlider", {
    Text = "Spin Speed", Min = 1, Max = 25, Default = 5, Rounding = 1,
    Callback = function(v) SpinSpeed = v end,
})
PlayerMisc:AddToggle("UpAngleToggle", {
    Text = "Anti Aim Up Angle", Default = false,
    Callback = function(v) getgenv().allvars.upanglebool = v end,
})
PlayerMisc:AddSlider("UpAngleSlider", {
    Text = "Up Angle Value", Min = -1, Max = 1, Default = 0.75, Rounding = 2,
    Callback = function(v) getgenv().allvars.upanglenum = v end,
})
PlayerMisc:AddToggle("RandomUp", {
    Text = "Random Up Angle", Default = false,
    Callback = function(v) random = v end,
})

GunModsGroup:AddToggle("NoSwayToggle", {
    Text = "No Sway", Default = false,
    Callback = function(v) getgenv().allvars.noswaybool = v end,
})
GunModsGroup:AddToggle("NoJumpTilt", {
    Text = "No Jump Tilt", Default = false,
    Callback = function(v) getgenv().allvars.nojumptilt = v end,
})


GunModsGroup:AddToggle("NoRecoilToggle", {
    Text = "No Recoil", Default = false,
    Callback = function(v)
        getgenv().allvars.norecoil = v
        if v then task.spawn(hookSprings) end
    end,
})
-- At the top, after services (add this once)
local originalAccuracy = {}
local ammoFolder = ReplicatedStorage:WaitForChild("AmmoTypes")

pcall(function()
    for _, ammo in ipairs(ammoFolder:GetChildren()) do
        if ammo:GetAttribute("AccuracyDeviation") then
            originalAccuracy[ammo.Name] = ammo:GetAttribute("AccuracyDeviation")
        end
    end
end)


GunModsGroup:AddToggle('No Spread', {
    Text = 'No Spread', 
    Default = false, 
    Callback = function(value)
        if value then
            for _, v in ipairs(ammoFolder:GetChildren()) do
                if v:GetAttribute("AccuracyDeviation") then
                    v:SetAttribute("AccuracyDeviation", 0)
                end
            end
        else
            -- Restore originals
            for _, v in ipairs(ammoFolder:GetChildren()) do
                if originalAccuracy[v.Name] then
                    v:SetAttribute("AccuracyDeviation", originalAccuracy[v.Name])
                end
            end
        end
    end
})

GunModsGroup:AddToggle("NoDropToggle", {
    Text = "No Bullet Drop", Default = false,
    Callback = function(v)
        getgenv().allvars.NoBulletDrop = v
    end,
})

GunModsGroup:AddToggle("NoWeaponBobToggle", {
    Text = "No Weapon Bob", Default = false,
    Callback = function(v)
        getgenv().allvars.nobob = v
        if v then task.spawn(hookSprings) end
    end,
})

HitFXGroup:AddToggle("HitSoundToggle", {
    Text = "Hit Sound", Default = false,
    Callback = function(v) getgenv().HitSound.Enabled = v end,
})
HitFXGroup:AddDropdown("HitSoundSelect", {
    Values = {"Neverlose","Gamesense","Bubble","Bameware","Bell","Rust"},
    Default = 1, Multi = false, Text = "Sound Type",
    Callback = function(v)
        local ids = {
            Neverlose = "rbxassetid://97643101798871",
            Gamesense  = "rbxassetid://4817809188",
            Bubble     = "rbxassetid://6534947588",
            Bameware   = "rbxassetid://6607339542",
            Bell       = "rbxassetid://6534947240",
            Rust       = "rbxassetid://5043539486",
        }
        getgenv().HitSound.SoundID = ids[v] or ids.Gamesense
    end,
})
HitFXGroup:AddSlider("HitSoundVol", {
    Text = "Volume", Min = 0, Max = 2, Default = 1, Rounding = 1,
    Callback = function(v) getgenv().HitSound.Volume = v end,
})
HitFXGroup:AddToggle("ViewmodelOffsetToggle", {
    Text = "Viewmodel Offset", Default = false,
    Callback = function(v) getgenv().allvars.viewmodoffset = v end,
})

HitFXGroup:AddSlider('viewmodel_x', { Text = 'X', Default = 0, Min = -5, Max = 5, Rounding = 2, Compact = true,
    Callback = function(v) getgenv().allvars.viewmodX = v end,
})
HitFXGroup:AddSlider('viewmodel_y', { Text = 'Y', Default = 0, Min = -5, Max = 5, Rounding = 2, Compact = true,
    Callback = function(v) getgenv().allvars.viewmodY = v end,
})
HitFXGroup:AddSlider('viewmodel_z', { Text = 'Z', Default = 0, Min = -5, Max = 5, Rounding = 2, Compact = true,
    Callback = function(v) getgenv().allvars.viewmodZ = v end,
})
-- (Camera is already declared at the top of the script — no re-declaration needed)
local storedC0 = {}
local currentViewmodel = nil

local function cacheOriginalC0s(vm)
    if not vm then return end
    local hrp = vm:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    storedC0 = {}
    for _, jointName in ipairs({"LeftUpperArm", "RightUpperArm", "ItemRoot", "Motor6D"}) do
        local joint = hrp:FindFirstChild(jointName)
        if joint and joint.C0 then
            storedC0[jointName] = joint.C0
        end
    end
end

local function vmpos(vm)
    if not vm then return end
    if vm ~= currentViewmodel then
        currentViewmodel = vm
        cacheOriginalC0s(vm)
    end
    local hrp = vm:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local vec = Vector3.new(
        getgenv().allvars.viewmodX,
        getgenv().allvars.viewmodY,
        getgenv().allvars.viewmodZ
    )
    for jointName, baseC0 in pairs(storedC0) do
        local joint = hrp:FindFirstChild(jointName)
        if joint and baseC0 then
            joint.C0 = baseC0 + vec
        end
    end
end

task.spawn(function()
    while task.wait(0.03) do
        local vm = Camera:FindFirstChild("ViewModel") or Camera:FindFirstChildOfClass("Model")
        if vm then
            vmpos(vm)
        else
            currentViewmodel = nil
            storedC0 = {}
        end
    end
end)

-- ── World Tab ─────────────────────────────────────────
local WorldTab   = Window:AddTab("World")
local EnvGroup   = WorldTab:AddLeftGroupbox("Environment")
local LightGroup = WorldTab:AddRightGroupbox("Lighting")
local CamGroup   = WorldTab:AddRightGroupbox("Camera")

EnvGroup:AddToggle("FogToggle", {
    Text = "Custom Fog", Default = false,
    Callback = function(v)
        getgenv().World.FogEnabled = v
        if not v then Lighting.FogStart = 0; Lighting.FogEnd = 100000 end
    end,
})
EnvGroup:AddSlider("FogStartSlider", { Text="Fog Start", Min=0, Max=1000,   Default=0,      Rounding=0, Callback=function(v) getgenv().World.FogStart = v end })
EnvGroup:AddSlider("FogEndSlider",   { Text="Fog End",   Min=0, Max=100000, Default=100000, Rounding=0, Callback=function(v) getgenv().World.FogEnd   = v end })
EnvGroup:AddToggle("TimeToggle", {
    Text = "Custom Time", Default = false,
    Callback = function(v) getgenv().World.TimeEnabled = v end,
})
EnvGroup:AddSlider("TimeSlider", { Text="Time of Day", Min=0, Max=24, Default=14, Rounding=1, Callback=function(v) getgenv().World.TimeOfDay = v end })
EnvGroup:AddToggle("RemoveGrassToggle", {
    Text = "Remove Grass", Default = false,
    Callback = function(v)
        getgenv().World.RemoveGrass = v
        if not v then pcall(function() sethiddenproperty(workspace.Terrain, "Decoration", true) end) end
    end,
})
EnvGroup:AddToggle("RemoveShadowsToggle", {
    Text = "Remove Shadows", Default = false,
    Callback = function(v)
        getgenv().World.RemoveShadows = v
        if not v then Lighting.GlobalShadows = true end
    end,
})
EnvGroup:AddToggle("RemoveLeavesToggle", {
    Text = "Remove Leaves", Default = false,
    Callback = function(v)
        getgenv().World.RemoveLeaves = v
        task.spawn(applyLeaves, v)
    end,
})
EnvGroup:AddToggle("RemoveCloudsToggle", {
    Text = "Remove Clouds", Default = false,
    Callback = function(v) getgenv().World.RemoveClouds = v end,
})
EnvGroup:AddToggle("RemoveAtmosphereToggle", {
    Text = "Remove Atmosphere", Default = false,
    Callback = function(v)
        getgenv().World.RemoveAtmo = v
        if not v then
            local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
            if atmo then atmo.Density = 0.34; atmo.Offset = 0.281 end
        end
    end,
})

LightGroup:AddSlider("BrightnessSlider", { Text="Brightness", Min=0, Max=10, Default=2, Rounding=1, Callback=function(v) getgenv().World.Brightness = v end })

LightGroup:AddToggle("Remove SunRay", {
    Text = "Remove SunRay", 
    Default = false,
    Callback = function(v)
        local Lighting = game:GetService("Lighting")
        local rays = Lighting:FindFirstChild("SunRays") or Lighting:FindFirstChild("Rays")
        if rays then rays.Enabled = v end
    end,
})

-- ── Third Person camera state (declared before UI so closures can capture) ──
local _3pYaw    = 0
local _3pPitch  = math.rad(-10)   -- slight downward default tilt
local _3pInput  = nil

-- Make the local character body parts visible/invisible for third/first person
local function setLocalCharVisibility(visible)
    local char = LocalPlayer.Character
    if not char then return end
    local modifier = visible and 0 or 1
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.LocalTransparencyModifier = modifier
        end
    end
end

local function enable3P()
    -- Initialise yaw from current camera so it doesn't snap
    Camera = workspace.CurrentCamera
    if Camera then
        local _, cy, _ = Camera.CFrame:ToEulerAnglesYXZ()
        _3pYaw = cy
    end
    UserInputService.MouseBehavior    = Enum.MouseBehavior.LockCenter
    UserInputService.MouseIconEnabled = false
    setLocalCharVisibility(true)
    if _3pInput then _3pInput:Disconnect() end
    _3pInput = UserInputService.InputChanged:Connect(function(inp)
        if not ThirdPerson or FreeCam then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement then
            _3pYaw   = _3pYaw   - math.rad(inp.Delta.X * 0.35)
            _3pPitch = math.clamp(
                _3pPitch - math.rad(inp.Delta.Y * 0.35),
                math.rad(-75), math.rad(35)
            )
        end
    end)
end

local function disable3P()
    if _3pInput then _3pInput:Disconnect(); _3pInput = nil end
    UserInputService.MouseBehavior    = Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled = true
    setLocalCharVisibility(false)
    if not FreeCam then
        Camera = workspace.CurrentCamera
        if Camera then Camera.CameraType = Enum.CameraType.Custom end
    end
end

-- Third person render loop — runs after camera priority so it overrides normally
RunService:BindToRenderStep("ZH_ThirdPerson", Enum.RenderPriority.Camera.Value + 1, function()
    if not ThirdPerson or FreeCam then return end
    Camera = workspace.CurrentCamera
    if not Camera then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Keep mouse locked every frame (game can reset it)
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    Camera.CameraType = Enum.CameraType.Scriptable

    -- Keep character body visible every frame (game resets LocalTransparencyModifier)
    local char2 = LocalPlayer.Character
    if char2 then
        for _, part in pairs(char2:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart"
                and part.LocalTransparencyModifier ~= 0 then
                part.LocalTransparencyModifier = 0
            end
        end
    end

    -- Orbit pivot: character hip + height offset
    local pivot = hrp.Position + Vector3.new(0, ThirdPersonHeight, 0)

    -- Build camera CFrame from our own yaw/pitch — independent of game camera
    local orbitCF  = CFrame.new(pivot)
                   * CFrame.Angles(0, _3pYaw, 0)
                   * CFrame.Angles(_3pPitch, 0, 0)
    local backward = -orbitCF.LookVector
    local idealPos = pivot + backward * ThirdPersonDist

    -- Wall-push: raycast from pivot to ideal camera position
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local excl = { char }
    local fol = getFoliage()
    if fol then table.insert(excl, fol) end
    rp.FilterDescendantsInstances = excl
    local ray = workspace:Raycast(pivot, idealPos - pivot, rp)
    -- Pull camera 0.25 studs in front of any wall hit to avoid clipping
    local finalPos = ray and (ray.Position + (pivot - idealPos).Unit * 0.25) or idealPos

    Camera.CFrame = CFrame.new(finalPos, pivot)
end)

-- ── Camera Group ──────────────────────────────────────
CamGroup:AddKeyPicker("FreeCamKey", {
    Default  = Enum.KeyCode.F,
    Mode     = "Toggle",
    Text     = "Free Cam Keybind",
    Callback = function(v)
        FreeCam = v
        if v then enableFreeCam() else disableFreeCam() end
        -- keep the toggle in sync
        local tog = _reg["FreeCamToggle"]
        if tog and tog.elem and tog.elem.SetValue then
            tog.elem.SetValue(v)
        end
    end,
})
CamGroup:AddToggle("FreeCamToggle", {
    Text = "Free Cam", Default = false,
    Tooltip = "WASD=move | Q/E=down/up | Shift=fast | Mouse=look",
    Callback = function(v)
        FreeCam = v
        if v then enableFreeCam() else disableFreeCam() end
    end,
})
CamGroup:AddSlider("FreeCamSpeedSlider", {
    Text = "Cam Speed", Min = 5, Max = 200, Default = 20, Rounding = 0,
    Callback = function(v) FreeCamSpeed = v end,
})
CamGroup:AddToggle("FOVToggle", {
    Text = "Custom FOV", Default = false,
    Callback = function(v) getgenv().World.FOVEnabled = v end,
})
CamGroup:AddSlider("FovSlider", {
    Text = "FOV", Min = 30, Max = 120, Default = 70, Rounding = 1,
    Callback = function(v)
        TargetFOV = v
        if getgenv().World.FOVEnabled then
            local cam = (CamMod and CamMod.u4) or Camera
            cam.FieldOfView = v
        end
    end,
})

CamGroup:AddToggle("AimZoomToggle", {
    Text    = "insta Aim",
    Default = false,
    Tooltip = "Instant Aim",
    Callback = function(v)
        AimZoomEnabled = v
        if not v and _aimZoomActive then
            -- Restore FOV immediately when toggled off mid-aim
            _aimZoomActive = false
            local cam = workspace.CurrentCamera
            if cam then
                TweenService:Create(cam,
                    TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    { FieldOfView = TargetFOV or BaseFov or 70 }
                ):Play()
            end
            if CamMod then
                pcall(function()
                    CamMod:SetZoomTarget(1, false, 0.12,
                        Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                end)
            end
        end
    end,
})

CamGroup:AddSlider("AimZoomFOVSlider", {
    Text     = "Aim Zoom",
    Min      = 5,
    Max      = 120,
    Default  = 40,
    Rounding = 0,
    Tooltip  = "FOV when holding",
    Callback = function(v) AimZoomFOV = v end,
})

-- ── Third Person ──────────────────────────────────────
_3pKeyElem = CamGroup:AddKeyPicker("ThirdPersonKey", {
    Default  = Enum.KeyCode.V,
    Mode     = "Toggle",
    Text     = "Third Person",
    Callback = function(v)
        ThirdPerson = v
        if v then
            enable3P()
        else
            disable3P()
        end
        -- keep the UI toggle in sync
        local tog = _reg["ThirdPersonToggle"]
        if tog and tog.elem and tog.elem.SetValue then tog.elem.SetValue(v) end
    end,
})
CamGroup:AddToggle("ThirdPersonToggle", {
    Text    = "Third Person (Toggle)",
    Default = false,
    Callback = function(v)
        ThirdPerson = v
        if v then enable3P() else disable3P() end
    end,
})
CamGroup:AddSlider("ThirdPersonDistSlider", {
    Text = "3P Distance", Min = 1, Max = 20, Default = 5, Rounding = 1,
    Callback = function(v) ThirdPersonDist = v end,
})
CamGroup:AddSlider("ThirdPersonHeightSlider", {
    Text = "3P Height", Min = -5, Max = 5, Default = 2, Rounding = 1,
    Callback = function(v) ThirdPersonHeight = v end,
})

-- ── Skybox Tab ────────────────────────────────────────
local SkyTab   = Window:AddTab("Skybox")
local SkyGroup = SkyTab:AddLeftGroupbox("Skybox")

SkyGroup:AddDropdown("SkyboxDropdown", {
    Text   = "Select Sky",
    Values = { "Standard","Among Us","Doge","Spongebob","Deep Space","Winter","Clouded Sky","Night Sky","Bluesky" },
    Default = 1,
    Callback = function(v) applySkybox(v) end,
})

-- ── Crosshair + Hit Effect Tab ────────────────────────
local FXTab        = Window:AddTab("Crosshair")
local CrossGroup   = FXTab:AddLeftGroupbox("Crosshair")
local HitFXGroupFX = FXTab:AddRightGroupbox("Hit Effect")

CrossGroup:AddToggle("CrosshairEnable", {
    Text = "Enable Crosshair", Default = false,
    HasColorPicker = true,
    Callback      = function(v) crosshairEnabled = v end,
    ColorCallback = function(c)
        crosshairColor = c
        for _, l in ipairs(crossLines) do l.Color = c end
    end,
})
CrossGroup:AddSlider("CrosshairSize", {
    Text = "Size", Min = 2, Max = 40, Default = 8, Rounding = 0,
    Callback = function(v) crosshairSize = v end,
})
CrossGroup:AddSlider("CrosshairGap", {
    Text = "Gap", Min = 0, Max = 20, Default = 4, Rounding = 0,
    Callback = function(v) crosshairGap = v end,
})
CrossGroup:AddSlider("CrosshairThick", {
    Text = "Thickness", Min = 1, Max = 5, Default = 2, Rounding = 1,
    Callback = function(v)
        crosshairThick = v
        for _, l in ipairs(crossLines) do l.Thickness = v end
    end,
})
CrossGroup:AddSlider("CrosshairSmooth", {
    Text = "Smoothness", Min = 0, Max = 0.95, Default = 0.25, Rounding = 2,
    Callback = function(v) crosshairSmooth = v end,
})

HitFXGroupFX:AddToggle("HitEffectToggle", {
    Text = "Spinning Hit Effect", Default = true,
    HasColorPicker = true,
    Callback      = function(v) hitEffectEnabled = v end,
    ColorCallback = function(c) hitEffectColor   = c end,
})
HitFXGroupFX:AddSlider("HitEffectSize", {
    Text = "Size", Min = 5, Max = 40, Default = 14, Rounding = 0,
    Callback = function(v) hitEffectSize = v end,
})
HitFXGroupFX:AddSlider("HitEffectDur", {
    Text = "Duration", Min = 0.1, Max = 1, Default = 0.45, Rounding = 2,
    Callback = function(v) hitEffectDur = v end,
})


-- ═══════════════════════════════════════════════════════
-- CONFIG SYSTEM  — reads directly from the UI registry
-- Saves/loads every Toggle, Slider, Dropdown + ColorPickers
-- ═══════════════════════════════════════════════════════
local HttpService = game:GetService("HttpService")
local CFG_FOLDER  = "ZestHub"
local CFG_SUB     = "ZestHub/configs"
for _, p in ipairs({ CFG_FOLDER, CFG_SUB }) do
    if not isfolder(p) then makefolder(p) end
end

local function c3hex(c)
    return string.format("%02x%02x%02x",
        math.round(c.R*255), math.round(c.G*255), math.round(c.B*255))
end

-- Snapshot every registered element
local function buildSnapshot()
    local snap = {}
    for id, entry in pairs(_reg) do
        local e, kind = entry.elem, entry.kind
        if kind == "Toggle" then
            local val = e.GetValue and e.GetValue() or false
            local col = e.ColorPicker and e.ColorPicker.GetColor and e.ColorPicker.GetColor()
            snap[id] = { k="T", v=val, c = col and c3hex(col) or nil }
        elseif kind == "Slider" then
            snap[id] = { k="S", v = e.GetValue and e.GetValue() or 0 }
        elseif kind == "Dropdown" then
            snap[id] = { k="D", v = e.GetValue and e.GetValue() or "" }
        elseif kind == "ColorPicker" then
            -- standalone color pickers (AmbientPicker, OutdoorPicker, etc.)
            local col = e.GetColor and e.GetColor()
            if col then snap[id] = { k="C", c = c3hex(col) } end
        elseif kind == "KeyPicker" then
            -- save keybind: store the KeyCode name and current mode
            local key  = e.GetValue and e.GetValue()
            local mode = e.GetMode  and e.GetMode()
            if key then
                snap[id] = { k="K", v=key.Name, m=mode or "Toggle" }
            end
        end
    end
    return snap
end

-- Apply a snapshot — fires every element's Callback automatically
local function applySnapshot(snap)
    for id, data in pairs(snap) do
        local entry = _reg[id]
        if not entry then continue end
        local e = entry.elem
        if data.k == "T" then
            local val = data.v == true
            if e.SetValue then e.SetValue(val) end
            -- belt-and-suspenders: fire cb directly in case SetValue didn't
            if entry.cb then pcall(entry.cb, val) end
            if data.c and e.ColorPicker and e.ColorPicker.SetColor then
                local ok, col = pcall(Color3.fromHex, Color3, data.c)
                if ok and col then
                    -- SetColor fires the ColorCallback internally via updateColor();
                    -- we only call colorCb separately if it is a DIFFERENT function
                    -- (i.e. the picker's updateColor won't reach it).
                    e.ColorPicker.SetColor(col)
                    if entry.colorCb then pcall(entry.colorCb, col) end
                end
            end
        elseif data.k == "S" then
            local val = tonumber(data.v) or 0
            if e.SetValue then e.SetValue(val) end
            -- Slider SetValue never fires Callback, so always fire manually
            if entry.cb then pcall(entry.cb, val) end
        elseif data.k == "D" then
            if e.SetValue and data.v and data.v ~= "" then
                e.SetValue(data.v)
                if entry.cb then pcall(entry.cb, data.v) end
            end
        elseif data.k == "C" then
            if data.c then
                local ok, col = pcall(Color3.fromHex, Color3, data.c)
                if ok and col then
                    if e.SetColor then e.SetColor(col) end
                    if entry.cb then pcall(entry.cb, col) end
                end
            end
        elseif data.k == "K" then
            -- Restore keybind: parse the saved KeyCode name back to an enum value
            if data.v and data.v ~= "" then
                local ok, kc = pcall(function() return Enum.KeyCode[data.v] end)
                if ok and kc then
                    if e.SetKey  then pcall(e.SetKey,  kc) end
                    if data.m and e.SetMode then pcall(e.SetMode, data.m) end
                end
            end
        end
    end
end

local function cfgPath(name) return CFG_SUB.."/"..name..".json" end

local function listConfigs()
    local out = {}
    for _, f in ipairs(listfiles(CFG_SUB)) do
        if f:sub(-5) == ".json" then
            local n = f:match("[/\\]([^/\\]+)%.json$")
            if n then table.insert(out, n) end
        end
    end
    return out
end

local function saveConfig(name)
    if not name or name:gsub(" ","") == "" then return false, "empty name" end
    local ok, enc = pcall(HttpService.JSONEncode, HttpService, buildSnapshot())
    if not ok then return false, "encode error" end
    writefile(cfgPath(name), enc)
    return true
end

local function loadConfig(name)
    if not name then return false, "no name" end
    if not isfile(cfgPath(name)) then return false, "not found" end
    local ok, dec = pcall(HttpService.JSONDecode, HttpService, readfile(cfgPath(name)))
    if not ok then return false, "decode error" end
    applySnapshot(dec)
    return true
end

local function deleteConfig(name)
    if isfile(cfgPath(name)) then delfile(cfgPath(name)); return true end
    return false
end

local function getAutoload()
    local p = CFG_SUB.."/autoload.txt"
    return isfile(p) and readfile(p) or nil
end
local function setAutoload(name)
    writefile(CFG_SUB.."/autoload.txt", name or "")
end

-- Auto-load 1 second after start so all hooks are settled
task.spawn(function()
    task.wait(1)
    local auto = getAutoload()
    if auto and auto ~= "" then
        local ok = loadConfig(auto)
        print(ok and ("[Config] Auto-loaded: "..auto) or "[Config] Auto-load failed")
    end
end)

-- ── Config Tab ────────────────────────────────────────
local CfgTab   = Window:AddTab("Config")
local CfgLeft  = CfgTab:AddLeftGroupbox("Actions")
local CfgRight = CfgTab:AddRightGroupbox("Configs")

local _cfgList    = listConfigs()
local _cfgSel     = nil
local _cfgDropRef = nil
local _cfgSelLbl  = nil  -- label showing what's selected

-- Right: static dropdown (values fixed at creation) + refresh rebuilds via label
_cfgDropRef = CfgRight:AddDropdown("CfgListDrop", {
    Text     = "Select Config",
    Values   = #_cfgList > 0 and _cfgList or {"(no configs yet)"},
    Default  = 1,
    Callback = function(v)
        -- ignore the placeholder
        if v == "(no configs yet)" then _cfgSel = nil return end
        _cfgSel = v
        if _cfgSelLbl then
            _cfgSelLbl.SetText("Selected: " .. v)
        end
    end,
})

_cfgSelLbl = CfgRight:AddLabel("Selected: none")

-- Refresh rebuilds by recreating the dropdown isn't possible in ui2,
-- so we print the list to console and tell the user to re-run the script
-- OR just show in label. Best we can do without SetValues:
CfgRight:AddButton("CfgRefreshBtn", {
    Text = "Refresh (re-run to update list)",
    Callback = function()
        _cfgList = listConfigs()
        local names = table.concat(_cfgList, ", ")
        print("[Config] " .. #_cfgList .. " configs: " .. (names ~= "" and names or "none"))
    end,
})

local _autoLbl = CfgRight:AddLabel("Autoload: " .. (getAutoload() or "none"))

-- Left: actions
CfgLeft:AddButton("CfgSaveNewBtn", {
    Text = "Save New Config",
    Callback = function()
        local name = "config_" .. os.date("%m%d_%H%M%S")
        local ok, err = saveConfig(name)
        if ok then
            _cfgList = listConfigs()
            -- Update selected to the just-saved one
            _cfgSel = name
            if _cfgSelLbl then _cfgSelLbl.SetText("Selected: " .. name) end
            print("[Config] Saved: " .. name)
        else
            warn("[Config] " .. tostring(err))
        end
    end,
})

CfgLeft:AddButton("CfgLoadBtn", {
    Text = "Load Selected",
    Callback = function()
        if not _cfgSel then warn("[Config] Select a config first") return end
        local ok, err = loadConfig(_cfgSel)
        if ok then print("[Config] Loaded: " .. _cfgSel)
        else warn("[Config] " .. tostring(err)) end
    end,
})

CfgLeft:AddButton("CfgOverwriteBtn", {
    Text = "Overwrite Selected",
    Callback = function()
        if not _cfgSel then warn("[Config] Select a config first") return end
        local ok, err = saveConfig(_cfgSel)
        if ok then print("[Config] Overwritten: " .. _cfgSel)
        else warn("[Config] " .. tostring(err)) end
    end,
})

CfgLeft:AddButton("CfgDeleteBtn", {
    Text = "Delete Selected",
    Callback = function()
        if not _cfgSel then warn("[Config] Select a config first") return end
        deleteConfig(_cfgSel)
        print("[Config] Deleted: " .. _cfgSel)
        _cfgSel = nil
        _cfgList = listConfigs()
        if _cfgSelLbl then _cfgSelLbl.SetText("Selected: none") end
    end,
})

CfgLeft:AddButton("CfgAutoloadBtn", {
    Text = "Set as Autoload",
    Callback = function()
        if not _cfgSel then warn("[Config] Select a config first") return end
        setAutoload(_cfgSel)
        _autoLbl.SetText("Autoload: " .. _cfgSel)
        print("[Config] Autoload → " .. _cfgSel)
    end,
})

CfgLeft:AddButton("CfgClearAutoBtn", {
    Text = "Clear Autoload",
    Callback = function()
        setAutoload("")
        _autoLbl.SetText("Autoload: none")
        print("[Config] Autoload cleared")
    end,
})

LightGroup:AddLabel("Ambient Color"):AddColorPicker("AmbientPicker", {
    Default  = Color3.fromRGB(138,138,138),
    Callback = function(c) getgenv().World.Ambient = c end,
})
LightGroup:AddLabel("Outdoor Ambient"):AddColorPicker("OutdoorPicker", {
    Default  = Color3.fromRGB(138,138,138),
    Callback = function(c) getgenv().World.OutdoorAmbient = c end,
})

print("[ZestHub] Loaded!")
