-- Made by Blissful#4992
local Players = game:service("Players")
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local Camera = game:service("Workspace").CurrentCamera
local RS = game:service("RunService")
local UIS = game:service("UserInputService")

repeat wait() until Player.Character ~= nil and Player.Character.PrimaryPart ~= nil

local LerpColorModule = loadstring(game:HttpGet("https://pastebin.com/raw/wRnsJeid"))()
local HealthBarLerp = LerpColorModule:Lerp(Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 255, 0))

local RadarInfo = {
    Position = Vector2.new(200, 200),
    Radius = 100,
    Scale = 1, -- Determinant factor on the effect of the relative position for the 2D integration
    RadarBack = Color3.fromRGB(10, 10, 10),
    RadarBorder = Color3.fromRGB(75, 75, 75),
    LocalPlayerDot = Color3.fromRGB(255, 255, 255),
    PlayerDot = Color3.fromRGB(60, 170, 255),
    Team = Color3.fromRGB(0, 255, 0),
    Enemy = Color3.fromRGB(255, 0, 0),
    Health_Color = true,
    Team_Check = true,
    Enabled = false -- Added to manage radar visibility
}

local RadarBackground
local RadarBorder
local LocalPlayerDot

-- Function to create a new circle drawing
local function NewCircle(Transparency, Color, Radius, Filled, Thickness)
    local c = Drawing.new("Circle")
    c.Transparency = Transparency
    c.Color = Color
    c.Visible = false
    c.Thickness = Thickness
    c.Position = Vector2.new(0, 0)
    c.Radius = Radius
    c.NumSides = math.clamp(Radius*55/100, 10, 75)
    c.Filled = Filled
    return c
end

-- Initialize Radar components
local function InitializeRadar()
    RadarBackground = NewCircle(0.9, RadarInfo.RadarBack, RadarInfo.Radius, true, 1)
    RadarBackground.Visible = true
    RadarBackground.Position = RadarInfo.Position

    RadarBorder = NewCircle(0.75, RadarInfo.RadarBorder, RadarInfo.Radius, false, 3)
    RadarBorder.Visible = true
    RadarBorder.Position = RadarInfo.Position

    LocalPlayerDot = NewCircle(1, RadarInfo.LocalPlayerDot, 6, true, 1)
    LocalPlayerDot.Position = RadarInfo.Position
    LocalPlayerDot.Visible = true

    for _, v in pairs(Players:GetChildren()) do
        if v.Name ~= Player.Name then
            PlaceDot(v)
        end
    end

    Players.PlayerAdded:Connect(function(v)
        if v.Name ~= Player.Name then
            PlaceDot(v)
        end
        LocalPlayerDot:Remove()
        LocalPlayerDot = NewCircle(1, RadarInfo.LocalPlayerDot, 6, true, 1)
        LocalPlayerDot.Position = RadarInfo.Position
        LocalPlayerDot.Visible = true
    end)

    -- Radar update loop
    coroutine.wrap(function()
        local c
        c = game:service("RunService").RenderStepped:Connect(function()
            if RadarInfo.Enabled then
                if LocalPlayerDot then
                    LocalPlayerDot.Color = RadarInfo.LocalPlayerDot
                    LocalPlayerDot.Position = RadarInfo.Position
                end
                RadarBackground.Position = RadarInfo.Position
                RadarBackground.Radius = RadarInfo.Radius
                RadarBackground.Color = RadarInfo.RadarBack

                RadarBorder.Position = RadarInfo.Position
                RadarBorder.Radius = RadarInfo.Radius
                RadarBorder.Color = RadarInfo.RadarBorder
            end
        end)
    end)()

    -- Draggable logic
    local inset = game:service("GuiService"):GetGuiInset()
    local dragging = false
    local offset = Vector2.new(0, 0)

    UIS.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and (Vector2.new(Mouse.X, Mouse.Y + inset.Y) - RadarInfo.Position).magnitude < RadarInfo.Radius then
            offset = RadarInfo.Position - Vector2.new(Mouse.X, Mouse.Y)
            dragging = true
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    coroutine.wrap(function()
        local dot = NewCircle(1, Color3.fromRGB(255, 255, 255), 3, true, 1)
        local c
        c = game:service("RunService").RenderStepped:Connect(function()
            if RadarInfo.Enabled then
                if (Vector2.new(Mouse.X, Mouse.Y + inset.Y) - RadarInfo.Position).magnitude < RadarInfo.Radius then
                    dot.Position = Vector2.new(Mouse.X, Mouse.Y + inset.Y)
                    dot.Visible = true
                else
                    dot.Visible = false
                end
                if dragging then
                    RadarInfo.Position = Vector2.new(Mouse.X, Mouse.Y) + offset
                end
            end
        end)
    end)()
end

-- Function to enable the radar
local function EnableRadar()
    RadarInfo.Enabled = true
    InitializeRadar()
end

-- Function to disable the radar
local function DisableRadar()
    RadarInfo.Enabled = false
    if RadarBackground then
        RadarBackground.Visible = false
    end
    if RadarBorder then
        RadarBorder.Visible = false
    end
    if LocalPlayerDot then
        LocalPlayerDot.Visible = false
    end
    -- Clear existing dots
    for _, v in pairs(Players:GetChildren()) do
        if v.Name ~= Player.Name then
            local dot = v.Character:FindFirstChildOfClass("Drawing")
            if dot then
                dot:Remove()
            end
        end
    end
end

-- Toggle radar visibility based on external trigger
local function ToggleRadar(state)
    if state then
        EnableRadar()
    else
        DisableRadar()
    end
end

-- Usage Example
-- ToggleRadar(true)  -- To enable radar
-- ToggleRadar(false) -- To disable radar

-- PlaceDot function
local function PlaceDot(plr)
    local PlayerDot = NewCircle(1, RadarInfo.PlayerDot, 3, true, 1)

    local function Update()
        local c
        c = game:service("RunService").RenderStepped:Connect(function()
            if RadarInfo.Enabled then
                local char = plr.Character
                if char and char:FindFirstChildOfClass("Humanoid") and char.PrimaryPart ~= nil and char:FindFirstChildOfClass("Humanoid").Health > 0 then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    local scale = RadarInfo.Scale
                    local relx, rely = GetRelative(char.PrimaryPart.Position)
                    local newpos = RadarInfo.Position - Vector2.new(relx * scale, rely * scale)

                    if (newpos - RadarInfo.Position).magnitude < RadarInfo.Radius-2 then
                        PlayerDot.Radius = 3
                        PlayerDot.Position = newpos
                        PlayerDot.Visible = true
                    else
                        local dist = (RadarInfo.Position - newpos).magnitude
                        local calc = (RadarInfo.Position - newpos).unit * (dist - RadarInfo.Radius)
                        local inside = Vector2.new(newpos.X + calc.X, newpos.Y + calc.Y)
                        PlayerDot.Radius = 2
                        PlayerDot.Position = inside
                        PlayerDot.Visible = true
                    end

                    PlayerDot.Color = RadarInfo.PlayerDot
                    if RadarInfo.Team_Check then
                        if plr.TeamColor == Player.TeamColor then
                            PlayerDot.Color = RadarInfo.Team
                        else
                            PlayerDot.Color = RadarInfo.Enemy
                        end
                    end

                    if RadarInfo.Health_Color then
                        PlayerDot.Color = HealthBarLerp(hum.Health / hum.MaxHealth)
                    end
                else
                    PlayerDot.Visible = false
                    if Players:FindFirstChild(plr.Name) == nil then
                        PlayerDot:Remove()
                        c:Disconnect()
                    end
                end
            end
        end)
    end
    coroutine.wrap(Update)()
end
