local License = "NIxO8e-OIS0GU-bdCNfb-T69hG7-DeMoc2-nlYu0B" --* Your License to use this script.
print(' KeyAuth Lua Example - https://github.com/mazk5145/')

-- Services
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Script Info
local LuaName = "KeyAuth Lua Example"
local initialized = false
local sessionid = ""

-- Application Info
local Name = "123"
local Ownerid = "FQ9KIiQtnA"
local APPVersion = "1.0"

-- Notify
StarterGui:SetCore("SendNotification", {
	Title = LuaName,
	Text = "Initializing Authentication...",
	Duration = 5
})

-- Init Request
local req = game:HttpGet('https://keyauth.win/api/1.1/?name=' .. Name .. '&ownerid=' .. Ownerid .. '&type=init&ver=' .. APPVersion)
if req == "KeyAuth_Invalid" then 
   print(" Error: Application not found.")
   StarterGui:SetCore("SendNotification", {
	   Title = LuaName,
	   Text = " Error: Application not found.",
	   Duration = 3
   })
   return false
end

local data = HttpService:JSONDecode(req)
if data.success == true then
   initialized = true
   sessionid = data.sessionid
elseif (data.message == "invalidver") then
   print(" Error: Wrong application version.")
   StarterGui:SetCore("SendNotification", {
	   Title = LuaName,
	   Text = " Error: Wrong application version.",
	   Duration = 3
   })
   return false
else
   print(" Error: " .. data.message)
   return false
end

-- License Auth
print("\n\n Licensing... \n")
local req = game:HttpGet('https://keyauth.win/api/1.1/?name=' .. Name .. '&ownerid=' .. Ownerid .. '&type=license&key=' .. License ..'&ver=' .. APPVersion .. '&sessionid=' .. sessionid)
local data = HttpService:JSONDecode(req)
if data.success == false then 
    StarterGui:SetCore("SendNotification", {
	    Title = LuaName,
	    Text = " Error: " .. data.message,
	    Duration = 5
    })
    return false
end

-- Print User Info
print(' Logged In!')
print(' User Data')
print(' Username: ' .. data.info.username)
print(' IP Address: ' .. data.info.ip)
print(' Created at: ' .. data.info.createdate)
print(' Last login at: ' .. data.info.lastlogin)

-- Success GUI Animation with Modern Loading Screen
-- Add blur
local blur = Instance.new("BlurEffect")
blur.Size = 0
blur.Parent = Lighting
TweenService:Create(blur, TweenInfo.new(1), { Size = 24 }):Play()

-- GUI
local screenGui = Instance.new("ScreenGui", PlayerGui)
screenGui.Name = "ZestHubWelcomeUI"
screenGui.ResetOnSpawn = false

-- Main Frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0.3, 0, 0.35, 0)
frame.Position = UDim2.new(0.35, 0, 0.325, 0)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
frame.BackgroundTransparency = 1
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 25)

-- Add stroke for modern look
local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(40, 40, 40)
stroke.Thickness = 2
stroke.Transparency = 1

TweenService:Create(frame, TweenInfo.new(0.8), { BackgroundTransparency = 0.05 }):Play()
TweenService:Create(stroke, TweenInfo.new(0.8), { Transparency = 0 }):Play()

-- Circular Progress Background
local progressBG = Instance.new("Frame")
progressBG.Size = UDim2.new(0, 120, 0, 120)
progressBG.Position = UDim2.new(0.5, -60, 0.3, -60)
progressBG.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
progressBG.BorderSizePixel = 0
progressBG.Parent = frame

local progressBGCorner = Instance.new("UICorner", progressBG)
progressBGCorner.CornerRadius = UDim.new(0.5, 0)

-- Progress Ring (Background Circle)
local progressRingBG = Instance.new("Frame")
progressRingBG.Size = UDim2.new(0, 100, 0, 100)
progressRingBG.Position = UDim2.new(0.5, -50, 0.5, -50)
progressRingBG.BackgroundTransparency = 1
progressRingBG.Parent = progressBG

local ringBGStroke = Instance.new("UIStroke", progressRingBG)
ringBGStroke.Color = Color3.fromRGB(40, 40, 40)
ringBGStroke.Thickness = 4

local ringBGCorner = Instance.new("UICorner", progressRingBG)
ringBGCorner.CornerRadius = UDim.new(0.5, 0)

-- Progress Ring (Animated)
local progressRing = Instance.new("Frame")
progressRing.Size = UDim2.new(0, 100, 0, 100)
progressRing.Position = UDim2.new(0.5, -50, 0.5, -50)
progressRing.BackgroundTransparency = 1
progressRing.Rotation = -90
progressRing.Parent = progressBG

local ringStroke = Instance.new("UIStroke", progressRing)
ringStroke.Color = Color3.fromRGB(255, 255, 255)
ringStroke.Thickness = 4
ringStroke.Transparency = 0.3

local ringCorner = Instance.new("UICorner", progressRing)
ringCorner.CornerRadius = UDim.new(0.5, 0)

-- Create the progress effect using rotation
local spinning = true
local progress = 0
task.spawn(function()
	while spinning do
		progress = progress + 2
		if progress >= 360 then progress = 0 end
		
		-- Create a smooth rotation effect
		local rotationTween = TweenService:Create(progressRing, TweenInfo.new(0.1, Enum.EasingStyle.Linear), { 
			Rotation = -90 + progress 
		})
		rotationTween:Play()
		
		-- Pulse effect for the stroke
		local pulseTween = TweenService:Create(ringStroke, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Transparency = math.abs(math.sin(progress * 0.05)) * 0.3
		})
		pulseTween:Play()
		
		task.wait(0.02)
	end
end)

-- Loading Text
local loadingLabel = Instance.new("TextLabel")
loadingLabel.Size = UDim2.new(1, 0, 0.15, 0)
loadingLabel.Position = UDim2.new(0, 0, 0.7, 0)
loadingLabel.BackgroundTransparency = 1
loadingLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
loadingLabel.TextTransparency = 1
loadingLabel.TextScaled = true
loadingLabel.Font = Enum.Font.GothamMedium
loadingLabel.Text = "Loading..."
loadingLabel.Parent = frame

-- Animate loading text dots
task.spawn(function()
	local dots = ""
	while spinning do
		for i = 1, 3 do
			dots = dots .. "."
			loadingLabel.Text = "Loading" .. dots
			task.wait(0.5)
		end
		dots = ""
		loadingLabel.Text = "Loading"
		task.wait(0.3)
	end
end)

TweenService:Create(loadingLabel, TweenInfo.new(1), { TextTransparency = 0 }):Play()

-- Wait for loading simulation
task.wait(4)
spinning = false

-- Show completion
TweenService:Create(ringStroke, TweenInfo.new(0.5), { 
	Color = Color3.fromRGB(0, 255, 100),
	Transparency = 0
}):Play()

-- Welcome Text
local welcomeLabel = Instance.new("TextLabel")
welcomeLabel.Size = UDim2.new(1, 0, 0.2, 0)
welcomeLabel.Position = UDim2.new(0, 0, 0.8, 0)
welcomeLabel.BackgroundTransparency = 1
welcomeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
welcomeLabel.TextTransparency = 1
welcomeLabel.TextScaled = true
welcomeLabel.Font = Enum.Font.GothamBold
welcomeLabel.Text = "Welcome to ZestHub"
welcomeLabel.Parent = frame

-- Hide loading text and show welcome
TweenService:Create(loadingLabel, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
TweenService:Create(welcomeLabel, TweenInfo.new(1), { TextTransparency = 0 }):Play()

task.wait(2)

-- Fade out everything
TweenService:Create(frame, TweenInfo.new(1), { BackgroundTransparency = 1 }):Play()
TweenService:Create(stroke, TweenInfo.new(1), { Transparency = 1 }):Play()
TweenService:Create(welcomeLabel, TweenInfo.new(1), { TextTransparency = 1 }):Play()
TweenService:Create(ringStroke, TweenInfo.new(1), { Transparency = 1 }):Play()
TweenService:Create(ringBGStroke, TweenInfo.new(1), { Transparency = 1 }):Play()
TweenService:Create(blur, TweenInfo.new(1), { Size = 0 }):Play()

-- Cleanup
task.delay(2, function()
	screenGui:Destroy()
	blur:Destroy()
end)

-- Load your main script
loadstring(game:HttpGet("https://raw.githubusercontent.com/Nafe03/project-delta/refs/heads/main/1.lua"))()
