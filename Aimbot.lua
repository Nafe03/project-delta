local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Holding = false

_G.AimbotEnabled = false
_G.TeamCheck = false -- If set to true, only lock aim on enemy team members.
_G.AimPart = "Head" -- Default aim part
_G.Sensitivity = 0.2 -- How quickly the aimbot locks onto the target

_G.CircleSides = 64 -- Number of sides for the FOV circle
_G.CircleColor = Color3.fromRGB(255, 255, 255) -- Color of the FOV circle
_G.CircleTransparency = 0.7 -- Transparency of the circle
_G.CircleRadius = 80 -- Radius of the circle / FOV
_G.CircleFilled = false -- Whether the circle is filled
_G.CircleVisible = true -- Whether the circle is visible
_G.CircleThickness = 0 -- Thickness of the circle

local FOVCircle = Drawing.new("Circle")
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
FOVCircle.Radius = _G.CircleRadius
FOVCircle.Filled = _G.CircleFilled
FOVCircle.Color = _G.CircleColor
FOVCircle.Visible = _G.CircleVisible
FOVCircle.Transparency = _G.CircleTransparency
FOVCircle.NumSides = _G.CircleSides
FOVCircle.Thickness = _G.CircleThickness

local function GetClosestPlayer()
    local MaximumDistance = _G.CircleRadius
    local Target = nil

    for _, v in next, Players:GetPlayers() do
        if v.Name ~= LocalPlayer.Name then
            if _G.TeamCheck and v.Team == LocalPlayer.Team then
                continue
            end

            if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                local humanoid = v.Character:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    local ScreenPoint = Camera:WorldToScreenPoint(v.Character.HumanoidRootPart.Position)
                    local VectorDistance = (Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2.new(ScreenPoint.X, ScreenPoint.Y)).Magnitude

                    if VectorDistance < MaximumDistance then
                        Target = v
                    end
                end
            end
        end
    end

    return Target
end

UserInputService.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = true
    end
end)

UserInputService.InputEnded:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = false
    end
end)

RunService.RenderStepped:Connect(function()
    FOVCircle.Position = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
    FOVCircle.Radius = _G.CircleRadius
    FOVCircle.Filled = _G.CircleFilled
    FOVCircle.Color = _G.CircleColor
    FOVCircle.Visible = _G.CircleVisible
    FOVCircle.Transparency = _G.CircleTransparency
    FOVCircle.NumSides = _G.CircleSides
    FOVCircle.Thickness = _G.CircleThickness

    if Holding and _G.AimbotEnabled then
        local targetPlayer = GetClosestPlayer()
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild(_G.AimPart) then
            local targetPosition = targetPlayer.Character[_G.AimPart].Position
            local mousePos = UserInputService:GetMouseLocation()

            -- Calculate the direction from the mouse position to the target position
            local direction = (targetPosition - Camera.CFrame.Position).Unit

            -- Tween the mouse position towards the target
            TweenService:Create(Camera, TweenInfo.new(_G.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                CFrame = CFrame.new(Camera.CFrame.Position, targetPosition)
            }):Play()
        end
    end
end)
