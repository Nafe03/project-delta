--// Cache
local select = select
local pcall, getgenv, next, Vector2, mathclamp, type, mousemoverel = select(1, pcall, getgenv, next, Vector2.new, math.clamp, type, mousemoverel or (Input and Input.MouseMove))

--// Preventing Multiple Processes
pcall(function()
	getgenv().Aimbot.Functions:Exit()
end)

--// Environment
getgenv().Aimbot = {}
local Environment = getgenv().Aimbot

--// Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--// Variables
local RequiredDistance, Typing, Running, Animation, ServiceConnections = 2000, false, false, nil, {}

--// Global Settings
_G.AimbotEnabled = true
_G.LegitAimbot = false
_G.TeamCheck = false
_G.HotKeyAimbot = Enum.KeyCode.Q -- Set your desired hotkey here (e.g., Enum.KeyCode.Q)
_G.AimPart = "Head"
_G.AirAimPart = "LowerTorso"
_G.Sensitivity = 0
_G.LegitSensitivity = 0.1
_G.PredictionAmount = 0
_G.AirPredictionAmount = 0
_G.BulletDropCompensation = 0
_G.DistanceAdjustment = false
_G.WallCheck = false
_G.PredictionMultiplier = 0.55
_G.FastTargetSpeedThreshold = 35
_G.DynamicSensitivity = true
_G.DamageAmount = 0
_G.HeadVerticalOffset = 0
_G.UseHeadOffset = false
_G.ToggleAimbot = false -- Add this line to enable/disable toggle mode
_G.DamageDisplay = false -- Enable/disable damage display
_G.VisibleHighlight = true -- For highlighting targets

-- Target Lock Info Settings
_G.AimbotLockInfo = true -- Enable/disable target info billboard

-- Target Strafe Settings
_G.TargetStrafe = false -- Toggle for target strafing
_G.StrafeDisten = math.pi * 5 -- Distance for strafing using math.pi
_G.StrafeSpeed = 2 -- Speed of strafing
_G.StrafeDirection = 1 -- 1 for clockwise, -1 for counter-clockwise
_G.StrafeHeight = 0 -- Height offset for strafing
_G.RandomPosTargetStrafe = false -- Enable random position target strafing

-- Silent Aim Settings
_G.SilentAim = false
_G.SilentAimHitChance = 100 -- Percentage chance to hit the target
_G.SilentAimRadius = 120 -- Radius for silent aim

-- Resolver Settings
_G.ResolverEnabled = true
_G.ResolverPrediction = 0.1 -- Adjust this value based on testing
_G.AntiLockDetectionThreshold = 50

-- FOV Circle Settings
_G.UseCircle = true
_G.CircleRadius = 120
_G.CircleColor = Color3.fromRGB(255, 255, 255)
_G.CircleThickness = 1
_G.CircleTransparency = 1
_G.CircleFilled = false

--// Script Settings
Environment.Settings = {
	Enabled = _G.AimbotEnabled,
	TeamCheck = _G.TeamCheck,
	AliveCheck = true,
	WallCheck = _G.WallCheck,
	Sensitivity = _G.Sensitivity,
	ThirdPerson = false,
	ThirdPersonSensitivity = 3,
	TriggerKey = _G.HotKeyAimbot.Name,
	Toggle = _G.ToggleAimbot,
	LockPart = _G.AimPart
}

Environment.FOVSettings = {
	Enabled = _G.UseCircle,
	Visible = true,
	Amount = _G.CircleRadius,
	Color = _G.CircleColor,
	LockedColor = Color3.fromRGB(255, 70, 70),
	Transparency = _G.CircleTransparency,
	Sides = 60,
	Thickness = _G.CircleThickness,
	Filled = _G.CircleFilled
}

Environment.FOVCircle = Drawing.new("Circle")

--// Functions
local function CancelLock()
	Environment.Locked = nil
	if Animation then Animation:Cancel() end
	Environment.FOVCircle.Color = Environment.FOVSettings.Color
end

local function GetClosestPlayer()
	if not Environment.Locked then
		RequiredDistance = (Environment.FOVSettings.Enabled and Environment.FOVSettings.Amount or 2000)

		for _, v in next, Players:GetPlayers() do
			if v ~= LocalPlayer then
				if v.Character and v.Character:FindFirstChild(Environment.Settings.LockPart) and v.Character:FindFirstChildOfClass("Humanoid") then
					if Environment.Settings.TeamCheck and v.Team == LocalPlayer.Team then continue end
					if Environment.Settings.AliveCheck and v.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then continue end
					if Environment.Settings.WallCheck and #(Camera:GetPartsObscuringTarget({v.Character[Environment.Settings.LockPart].Position}, v.Character:GetDescendants())) > 0 then continue end

					local Vector, OnScreen = Camera:WorldToViewportPoint(v.Character[Environment.Settings.LockPart].Position)
					local Distance = (Vector2(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2(Vector.X, Vector.Y)).Magnitude

					if Distance < RequiredDistance and OnScreen then
						RequiredDistance = Distance
						Environment.Locked = v
					end
				end
			end
		end
	elseif (Vector2(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2(Camera:WorldToViewportPoint(Environment.Locked.Character[Environment.Settings.LockPart].Position).X, Camera:WorldToViewportPoint(Environment.Locked.Character[Environment.Settings.LockPart].Position).Y)).Magnitude > RequiredDistance then
		CancelLock()
	end
end

--// Typing Check
ServiceConnections.TypingStartedConnection = UserInputService.TextBoxFocused:Connect(function()
	Typing = true
end)

ServiceConnections.TypingEndedConnection = UserInputService.TextBoxFocusReleased:Connect(function()
	Typing = false
end)

--// Main
local function Load()
	ServiceConnections.RenderSteppedConnection = RunService.RenderStepped:Connect(function()
		if Environment.FOVSettings.Enabled and Environment.Settings.Enabled then
			Environment.FOVCircle.Radius = Environment.FOVSettings.Amount
			Environment.FOVCircle.Thickness = Environment.FOVSettings.Thickness
			Environment.FOVCircle.Filled = Environment.FOVSettings.Filled
			Environment.FOVCircle.NumSides = Environment.FOVSettings.Sides
			Environment.FOVCircle.Color = Environment.FOVSettings.Color
			Environment.FOVCircle.Transparency = Environment.FOVSettings.Transparency
			Environment.FOVCircle.Visible = Environment.FOVSettings.Visible
			Environment.FOVCircle.Position = Vector2(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
		else
			Environment.FOVCircle.Visible = false
		end

		if Running and Environment.Settings.Enabled then
			GetClosestPlayer()

			if Environment.Locked then
				if Environment.Settings.ThirdPerson then
					Environment.Settings.ThirdPersonSensitivity = mathclamp(Environment.Settings.ThirdPersonSensitivity, 0.1, 5)

					local Vector = Camera:WorldToViewportPoint(Environment.Locked.Character[Environment.Settings.LockPart].Position)
					mousemoverel((Vector.X - UserInputService:GetMouseLocation().X) * Environment.Settings.ThirdPersonSensitivity, (Vector.Y - UserInputService:GetMouseLocation().Y) * Environment.Settings.ThirdPersonSensitivity)
				else
					if Environment.Settings.Sensitivity > 0 then
						Animation = TweenService:Create(Camera, TweenInfo.new(Environment.Settings.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = CFrame.new(Camera.CFrame.Position, Environment.Locked.Character[Environment.Settings.LockPart].Position)})
						Animation:Play()
					else
						Camera.CFrame = CFrame.new(Camera.CFrame.Position, Environment.Locked.Character[Environment.Settings.LockPart].Position)
					end
				end

			Environment.FOVCircle.Color = Environment.FOVSettings.LockedColor

			end
		end
	end)

	ServiceConnections.InputBeganConnection = UserInputService.InputBegan:Connect(function(Input)
		if not Typing then
			pcall(function()
				if Input.KeyCode == Enum.KeyCode[Environment.Settings.TriggerKey] then
					if Environment.Settings.Toggle then
						Running = not Running

						if not Running then
							CancelLock()
						end
					else
						Running = true
					end
				end
			end)

			pcall(function()
				if Input.UserInputType == Enum.UserInputType[Environment.Settings.TriggerKey] then
					if Environment.Settings.Toggle then
						Running = not Running

						if not Running then
							CancelLock()
						end
					else
						Running = true
					end
				end
			end)
		end
	end)

	ServiceConnections.InputEndedConnection = UserInputService.InputEnded:Connect(function(Input)
		if not Typing then
			if not Environment.Settings.Toggle then
				pcall(function()
					if Input.KeyCode == Enum.KeyCode[Environment.Settings.TriggerKey] then
						Running = false; CancelLock()
					end
				end)

				pcall(function()
					if Input.UserInputType == Enum.UserInputType[Environment.Settings.TriggerKey] then
						Running = false; CancelLock()
					end
				end)
			end
		end
	end)
end

--// Functions
Environment.Functions = {}

function Environment.Functions:Exit()
	for _, v in next, ServiceConnections do
		v:Disconnect()
	end

	if Environment.FOVCircle.Remove then Environment.FOVCircle:Remove() end

	getgenv().Aimbot.Functions = nil
	getgenv().Aimbot = nil

	Load = nil; GetClosestPlayer = nil; CancelLock = nil
end

function Environment.Functions:Restart()
	for _, v in next, ServiceConnections do
		v:Disconnect()
	end

	Load()
end

function Environment.Functions:ResetSettings()
	Environment.Settings = {
		Enabled = _G.AimbotEnabled,
		TeamCheck = _G.TeamCheck,
		AliveCheck = true,
		WallCheck = _G.WallCheck,
		Sensitivity = _G.Sensitivity,
		ThirdPerson = false,
		ThirdPersonSensitivity = 3,
		TriggerKey = _G.HotKeyAimbot.Name,
		Toggle = _G.ToggleAimbot,
		LockPart = _G.AimPart
	}

	Environment.FOVSettings = {
		Enabled = _G.UseCircle,
		Visible = true,
		Amount = _G.CircleRadius,
		Color = _G.CircleColor,
		LockedColor = Color3.fromRGB(255, 70, 70),
		Transparency = _G.CircleTransparency,
		Sides = 60,
		Thickness = _G.CircleThickness,
		Filled = _G.CircleFilled
	}
end

--// Load
Load()
