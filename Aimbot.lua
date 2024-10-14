local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Holding = false

_G.AimbotEnabled = false
_G.TeamCheck = false -- Only lock aim at enemy team members if true
_G.AimPart = "Head" -- Default aim part to lock on
_G.Sensitivity = 0.2 -- Sensitivity for the aimbot

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

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not _G.TeamCheck or (player.Team ~= LocalPlayer.Team) then
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
                    local humanoid = player.Character.Humanoid
                    if humanoid.Health > 0 then
                        local ScreenPoint = Camera:WorldToScreenPoint(player.Character[_G.AimPart].Position)
                        local VectorDistance = (Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2.new(ScreenPoint.X, ScreenPoint.Y)).Magnitude
                        
                        if VectorDistance < MaximumDistance then
                            Target = player
                            break -- Get the closest target and exit the loop
                        end
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
            local direction = (targetPosition - Camera.CFrame.Position).unit
            
            -- Move the mouse towards the target
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter -- Lock mouse to center for smoother aiming
            local targetScreenPosition = Camera:WorldToScreenPoint(targetPosition)
            local mouseX, mouseY = UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y
            UserInputService.MouseDelta = Vector2.new(targetScreenPosition.X - mouseX, targetScreenPosition.Y - mouseY) * _G.Sensitivity
        end
    end
end)
