-- Define available themes
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local themes = {"cherry", "orange", "lemon", "lime", "raspberry"}
local currentThemeIndex = 4 -- Start with the 'lime' theme
local CheatTheme = themes[currentThemeIndex]

-- Load the UI and external scripts
local uiLoader = loadstring(game:HttpGet('https://raw.githubusercontent.com/topitbopit/dollarware/main/library.lua'))
local aimbotLoader = loadstring(game:HttpGet('https://raw.githubusercontent.com/Nafe03/project-delta/main/Aimbot.lua'))
local espLoader = loadstring(game:HttpGet('https://raw.githubusercontent.com/Nafe03/project-delta/refs/heads/main/EspEXE.lua'))

local ui

local function initializeUI(theme)
    if ui then
        ui:updateTheme(theme)
    else
        ui = uiLoader({
            rounding = false,
            theme = theme,
            smoothDragging = false
        })
    end

    ui.autoDisableToggles = true
end

-- Initialize UI with the default theme
initializeUI(CheatTheme)

-- Load Aimbot
_G.AimbotEnabled = false
_G.TeamCheck = false
_G.AimPart = "Head"
_G.PredictionAmount = 0

_G.CircleSides = 64
_G.CircleColor = Color3.fromRGB(255, 255, 255)
_G.CircleTransparency = 0.7
_G.CircleRadius = 80
_G.CircleFilled = false
_G.CircleVisible = true
_G.CircleThickness = 0
_G.UseCircle = true

Aimbot = aimbotLoader({
    _G.AimbotEnabled,
    _G.TeamCheck,
    _G.AimPart,
    _G.PredictionAmount,
    _G.CircleSides,
    _G.CircleColor,
    _G.CircleTransparency,
    _G.CircleRadius,
    _G.CircleFilled,
    _G.CircleVisible,
    _G.CircleThickness,
    _G.UseCircle
})

_G.HealthESPEnabled = false
_G.NameESPEnabled = false
_G.BoxESPEnabled = false
_G.DistanceESPEnabled = false

-- Load ESP
ESP = espLoader({
    _G.HealthESPEnabled,
    _G.NameESPEnabled,
    _G.BoxESPEnabled,
    _G.DistanceESPEnabled
})


local player = game.Players.LocalPlayer
local profileGui
local CheatGui
local dragEnabled = false
local profileRainbowEnabled = false
local cheatRainbowEnabled = false

-- Functions to create GUIs
local function createCheatGui()
    if CheatGui then CheatGui:Destroy() end

    CheatGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
    CheatGui.Name = "CheatGui"

    local cheatLabel = Instance.new("TextLabel", CheatGui)
    cheatLabel.Size = UDim2.new(0, 200, 0, 80)
    cheatLabel.Position = UDim2.new(0.5, -100, 0, 10)
    cheatLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    cheatLabel.TextSize = 34
    cheatLabel.Font = Enum.Font.SourceSansBold
    cheatLabel.BackgroundTransparency = 1

    -- Animate Cheat Label Text
    coroutine.wrap(function()
        local fullText = "Z E S T . H U B"
        local displayedText = ""
        while true do
            for i = 1, #fullText do
                displayedText = displayedText .. fullText:sub(i, i)
                cheatLabel.Text = displayedText
                wait(0.1)
            end
            wait(1)
            displayedText = ""
        end
    end)()

    -- Check TimeOfDay and update CheatLabel color
    game:GetService("RunService").RenderStepped:Connect(function()
        if game.Lighting.TimeOfDay == "18:00:00" or game.Lighting.TimeOfDay < "18:00:00" then
            cheatLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            cheatLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
        end
    end)

    if cheatRainbowEnabled then
        addRainbowOutlineToFrame(cheatLabel)
    end
end

local function addRainbowOutlineToFrame(frame)
    local outline = Instance.new("UIStroke", frame)
    outline.Thickness = 2
    outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    outline.Transparency = 0
    local hue = 0
    game:GetService("RunService").RenderStepped:Connect(function()
        hue = (hue + 0.01) % 1
        outline.Color = Color3.fromHSV(hue, 1, 1)
    end)
end

local function createProfileDisplay()
    if profileGui then profileGui:Destroy() end

    profileGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
    profileGui.Name = "ProfileDisplay"

    local profileFrame = Instance.new("Frame", profileGui)
    profileFrame.Size = UDim2.new(0, 200, 0, 80)
    profileFrame.Position = UDim2.new(0, 10, 0, 10)
    profileFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    profileFrame.BackgroundTransparency = 0.5
    profileFrame.BorderSizePixel = 0
    profileFrame.Active = true

    local profilePicture = Instance.new("ImageLabel", profileFrame)
    profilePicture.Size = UDim2.new(0, 40, 0, 40)
    profilePicture.Position = UDim2.new(0, 5, 0, 25)
    profilePicture.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=420&h=420"
    profilePicture.BackgroundTransparency = 1

    local usernameLabel = Instance.new("TextLabel", profileFrame)
    usernameLabel.Size = UDim2.new(0, 100, 0, 20)
    usernameLabel.Position = UDim2.new(0, 50, 0, 25)
    usernameLabel.Text = player.Name
    usernameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    usernameLabel.TextSize = 14
    usernameLabel.Font = Enum.Font.SourceSansBold
    usernameLabel.BackgroundTransparency = 1

    local fpsLabel = Instance.new("TextLabel", profileFrame)
    fpsLabel.Size = UDim2.new(0, 100, 0, 20)
    fpsLabel.Position = UDim2.new(0, 50, 0, 45)
    fpsLabel.Text = "FPS: 0"
    fpsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    fpsLabel.TextSize = 14
    fpsLabel.Font = Enum.Font.SourceSans
    fpsLabel.BackgroundTransparency = 1

    local lastTick = tick()
    local frames = 0
    game:GetService("RunService").RenderStepped:Connect(function()
        frames = frames + 1
        if tick() - lastTick >= 1 then
            fpsLabel.Text = "FPS: " .. frames
            frames = 0
            lastTick = tick()
        end
    end)

    if profileRainbowEnabled then
        addRainbowOutlineToFrame(profileFrame)
    end

    -- Dragging logic
    profileFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and dragEnabled then
            dragToggle = true
            dragStart = input.Position
            startPos = profileFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragToggle = false
                end
            end)
        end
    end)

    profileFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragToggle then
            local delta = input.Position - dragStart
            profileFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Toggle GUI functions
local function toggleCreateCheatGui(enabled)
    if enabled then
        createCheatGui()
    elseif CheatGui then
        CheatGui:Destroy()
    end
end

local function toggleProfileDisplay(enabled)
    if enabled then
        createProfileDisplay()
    elseif profileGui then
        profileGui:Destroy()
    end
end

-- UI Window
local window = ui.newWindow({
    text = 'Zest.HUB',
    resize = true,
    size = Vector2.new(550, 376),
    position = nil
})

-- Example toggle functions for demonstration
toggleCreateCheatGui(true)
toggleProfileDisplay(true)


-- Menu 1 with ProfileDisplay toggles
local menu1 = window:addMenu({
    text = 'Settings'
})

local profileSection = menu1:addSection({
    text = 'Profile Display Settings',
    side = 'auto',
    showMinButton = true,
})

-- Toggle Profile Display
local profileToggle = profileSection:addToggle({
    text = 'Profile Display',
    state = false
})

profileToggle:bindToEvent('onToggle', function(newState)
    toggleProfileDisplay(newState)
    ui.notify({
        title = 'Profile Display',
        message = newState and 'Profile Display Enabled!' or 'Profile Display Disabled!',
        duration = 3
    })
end)

-- Toggle Draggable Profile Display
local dragToggle = profileSection:addToggle({
    text = 'Draggable Profile Display',
    state = dragEnabled
})

dragToggle:bindToEvent('onToggle', function(newState)
    dragEnabled = newState
    ui.notify({
        title = 'Profile Display Drag',
        message = newState and 'Profile Display Drag Enabled!' or 'Profile Display Drag Disabled!',
        duration = 3
    })
end)

-- Toggle Rainbow Profile Outline
local profileRainbowToggle = profileSection:addToggle({
    text = 'Rainbow Profile Outline',
    state = profileRainbowEnabled
})

profileRainbowToggle:bindToEvent('onToggle', function(newState)
    profileRainbowEnabled = newState
    toggleProfileDisplay(false)
    toggleProfileDisplay(true)
    ui.notify({
        title = 'Rainbow Profile Outline',
        message = newState and 'Rainbow Profile Outline Enabled!' or 'Rainbow Profile Outline Disabled!',
        duration = 3
    })
end)

local cheatLabelSection = menu1:addSection({
    text = 'CheatLabel Settings',
    side = 'auto',
    showMinButton = true,
})

-- Toggle CheatLabel


-- Toggle Rainbow CheatLabel Outline
local cheatRainbowToggle = cheatLabelSection:addToggle({
    text = 'Rainbow CheatLabel Outline',
    state = cheatRainbowEnabled
})

cheatRainbowToggle:bindToEvent('onToggle', function(newState)
    cheatRainbowEnabled = newState
    toggleCreateCheatGui(false)
    toggleCreateCheatGui(true)
    ui.notify({
        title = 'Rainbow CheatLabel Outline',
        message = newState and 'Rainbow CheatLabel Outline Enabled!' or 'Rainbow CheatLabel Outline Disabled!',
        duration = 3
    })
end)

-- Visual Settings for theme switching
local themeSection = menu1:addSection({
    text = 'Visual Settings',
    side = 'auto',
    showMinButton = true,
})

-- Button to cycle through themes
themeSection:addButton({
    text = 'Switch Zest Theme',
    style = 'small'
}):bindToEvent('onClick', function()
    currentThemeIndex = currentThemeIndex % #themes + 1 -- Cycle to the next theme
    CheatTheme = themes[currentThemeIndex]
    initializeUI(CheatTheme) -- Update the UI with the new theme
    ui.notify({
        title = 'Zest Theme',
        message = 'Zest theme set to ' .. CheatTheme,
        duration = 3
    })
end)

-- Menu 2 (Aimbot Settings)
local menu2 = window:addMenu({
    text = 'Aimbot'
})

-- Aimbot Settings Section
do
    local section = menu2:addSection({
        text = 'Aimbot Settings',
        side = 'auto',
        showMinButton = true
    })

    local aimbotToggle = section:addToggle({
        text = 'Aimbot',
        state = _G.AimbotEnabled
    })

    local useFovCircleToggle = section:addToggle({
        text = 'useFovCircle',
        state = _G.UseCircle
    })

    useFovCircleToggle:bindToEvent('onToggle', function(newState)
        _G.UseCircle = newState

        ui.notify({
            title = 'UseCirclet',
            message = newState and 'UseCircle activated! Hold left mouse to aim.' or 'useFovCircle deactivated!',
            duration = 3
        })
    end)
    
    local CircleVisibleToggle = section:addToggle({
        text = 'CircleVisible',
        state = _G.CircleVisible
    })
    
    CircleVisibleToggle:bindToEvent('onToggle', function(newState)
        _G.CircleVisible = newState

        ui.notify({
            title = 'Aimbot',
            message = newState and 'CircleVisible activated!' or 'CircleVisible deactivated!',
            duration = 3
        })
    end)


    aimbotToggle:bindToEvent('onToggle', function(newState)
        _G.AimbotEnabled = newState

        ui.notify({
            title = 'Aimbot',
            message = newState and 'Aimbot activated! Hold left mouse to aim.' or 'Aimbot deactivated!',
            duration = 3
        })
    end)

    -- Add Team Check Toggle
    local teamCheckToggle = section:addToggle({
        text = 'Team Check',
        state = _G.TeamCheck
    })

    teamCheckToggle:bindToEvent('onToggle', function(newState)
        _G.TeamCheck = newState
        ui.notify({
            title = 'Team Check',
            message = newState and 'Team Check Enabled!' or 'Team Check Disabled!',
            duration = 3
        })
    end)

    -- Toggle Button to switch AimPart
    section:addButton({
        text = 'Switch Aim Part',
        style = 'small'
    }):bindToEvent('onClick', function()
        _G.AimPart = _G.AimPart == "Head" and "HumanoidRootPart" or "Head"
        ui.notify({
            title = 'Aim Part',
            message = 'Aim Part set to ' .. _G.AimPart,
            duration = 3
        })
    end)

do
    local section = menu2:addSection({
        text = 'Aimbot Slider Settings',
        side = 'auto',
        showMinButton = true
    })
    -- Aimbot FOV Slider
    section:addSlider({
        text = 'Aimbot FOV',
        min = 1,
        max = 1000,
        step = 1,
        val = _G.CircleRadius
    }, function(newValue)
        _G.CircleRadius = newValue
        print('Aimbot FOV:', newValue)
    end)


    -- Prediction Slider
    section:addSlider({
        text = 'Aimbot Prediction',
        min = 0,
        max = 10,
        step = 0.01,
        val = _G.PredictionAmount
    }, function(newValue)
        _G.PredictionAmount = newValue
        print('Aimbot Prediction:', newValue)
    end)

    section:addSlider({
        text = 'FOV Transparency',
        min = 0,
        max = 1,
        step = 0.1,
        val = _G.CircleTransparency
    }, function(newValue)
        _G.CircleTransparency = newValue
        print('FOV Transparency:', newValue)
    end)
end

-- Menu 5 (Anti-Aim and Fake Lag Settings)
local menu3 = window:addMenu({
    text = 'Exploit'
})

-- Anti-Aim Settings Section
do
    _G.AntiAimEnabled = false
    _G.JitterStrength = 50
    _G.BodyRotationAngle = 180
    _G.FlipInterval = 1
    _G.RandomizeAntiAim = false

    local section = menu3:addSection({
        text = 'Anti-Aim Settings',
        side = 'auto',
        showMinButton = true
    })

    -- Anti-Aim Toggle
    local antiAimToggle = section:addToggle({
        text = 'Anti-Aim',
        state = _G.AntiAimEnabled
    })

    antiAimToggle:bindToEvent('onToggle', function(newState)
        _G.AntiAimEnabled = newState
        if newState then
            startAntiAim()
        else
            stopAntiAim()
        end

        ui.notify({
            title = 'Anti-Aim',
            message = newState and 'Anti-Aim activated!' or 'Anti-Aim deactivated!',
            duration = 3
        })
    end)

    -- Jitter Strength Slider
    section:addSlider({
        text = 'Jitter Strength',
        min = 0,
        max = 100,
        step = 1,
        val = _G.JitterStrength
    }, function(newValue)
        _G.JitterStrength = newValue
    end)

    -- Body Rotation Angle Slider
    section:addSlider({
        text = 'Body Rotation Angle',
        min = 0,
        max = 360,
        step = 1,
        val = _G.BodyRotationAngle
    }, function(newValue)
        _G.BodyRotationAngle = newValue
    end)

    -- Flip Interval Slider
    section:addSlider({
        text = 'Flip Interval (sec)',
        min = 0.1,
        max = 5,
        step = 0.1,
        val = _G.FlipInterval
    }, function(newValue)
        _G.FlipInterval = newValue
    end)

    -- Anti-Aim Randomization Toggle
    section:addToggle({
        text = 'Randomize Anti-Aim',
        state = _G.RandomizeAntiAim
    }):bindToEvent('onToggle', function(newState)
        _G.RandomizeAntiAim = newState
    end)
end

-- Fake Lag Settings Section
do
    _G.FakeLagEnabled = false
    _G.FakeLagAmount = 10

    local section = menu3:addSection({
        text = 'Fake Lag Settings',
        side = 'auto',
        showMinButton = true
    })

    -- Fake Lag Toggle
    local fakeLagToggle = section:addToggle({
        text = 'Fake Lag',
        state = _G.FakeLagEnabled
    })

    fakeLagToggle:bindToEvent('onToggle', function(newState)
        _G.FakeLagEnabled = newState
        if newState then
            startFakeLag()
        else
            stopFakeLag()
        end

        ui.notify({
            title = 'Fake Lag',
            message = newState and 'Fake Lag activated!' or 'Fake Lag deactivated!',
            duration = 3
        })
    end)

    -- Fake Lag Amount Slider
    section:addSlider({
        text = 'Fake Lag Amount',
        min = 0,
        max = 100,
        step = 0.01,
        val = _G.FakeLagAmount
    }, function(newValue)
        _G.FakeLagAmount = newValue
    end)
end
end

-- Anti-Aim Logic
local antiAimLoop
function startAntiAim()
    antiAimLoop = game:GetService("RunService").Heartbeat:Connect(function()
        if not _G.AntiAimEnabled then return end
        local player = game.Players.LocalPlayer
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local jitter = _G.JitterStrength * math.random(-1, 1)
            local angle = _G.BodyRotationAngle + jitter
            player.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(angle), 0)
            wait(_G.FlipInterval)
        end
    end)
end

function stopAntiAim()
    if antiAimLoop then
        antiAimLoop:Disconnect()
        antiAimLoop = nil
    end
end

-- Fake Lag Logic
local fakeLagLoop
function startFakeLag()
    fakeLagLoop = game:GetService("RunService").Heartbeat:Connect(function()
        if not _G.FakeLagEnabled then return end
        local player = game.Players.LocalPlayer
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.Anchored = true
            wait(_G.FakeLagAmount / 50)
            player.Character.HumanoidRootPart.Anchored = false
            wait(_G.FakeLagAmount / 20)
        end
    end)
end

game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.X then
        _G.FakeLagEnabled = not _G.FakeLagEnabled
        if _G.FakeLagEnabled then
            startFakeLag()
        else
            stopFakeLag()
        end
        ui.notify({
            title = 'Fake Lag',
            message = _G.FakeLagEnabled and 'Fake Lag Enabled!' or 'Fake Lag Disabled!',
            duration = 3
        })
    end
end)


function stopFakeLag()
    if fakeLagLoop then
        fakeLagLoop:Disconnect()
        fakeLagLoop = nil
        local player = game.Players.LocalPlayer
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.Anchored = false
        end
    end
end

local menu4 = window:addMenu({
    text = 'Visuals'
})

-- Visual Settings Section
do
    local section = menu4:addSection({
        text = 'Visual Settings',
        side = 'auto',
        showMinButton = true
    })

    -- Brightness Slider
    section:addSlider({
        text = 'Brightness',
        min = 0,
        max = 100,
        step = 0.1,
        val = game.Lighting.Brightness
    }, function(newValue)
        game.Lighting.Brightness = newValue
        print('Brightness:', newValue)
    end):setTooltip('Adjust the world brightness')

    -- Fog Color Picker
    section:addColorPicker({
        text = 'Fog Color',
        color = game.Lighting.FogColor
    }, function(newColor)
        game.Lighting.FogColor = newColor
        print('Fog Color changed:', newColor)
    end):setTooltip('Adjust the fog color')

    -- Light Color Picker
    section:addColorPicker({
        text = 'Light Color',
        color = game.Lighting.ColorShift_Top
    }, function(newColor)
        game.Lighting.ColorShift_Top = newColor
        game.Lighting.ColorShift_Bottom = newColor
        print('Light Color changed:', newColor)
    end):setTooltip('Change the lighting color for the environment')

    -- Fog Start Distance Slider
    section:addSlider({
        text = 'Fog Start',
        min = 0,
        max = 1000,
        step = 1,
        val = game.Lighting.FogStart
    }, function(newValue)
        game.Lighting.FogStart = newValue
        print('Fog Start Distance:', newValue)
    end):setTooltip('Adjust the distance where fog starts')

    -- Fog End Distance Slider
    section:addSlider({
        text = 'Fog End',
        min = 500,
        max = 10000,
        step = 50,
        val = game.Lighting.FogEnd
    }, function(newValue)
        game.Lighting.FogEnd = newValue
        print('Fog End Distance:', newValue)
    end):setTooltip('Adjust the distance where fog ends')

    -- Time of Day Slider
    section:addSlider({
        text = 'Time of Day',
        min = 0,
        max = 24,
        step = 0.1,
        val = game.Lighting.TimeOfDay
    }, function(newValue)
        game.Lighting.TimeOfDay = tostring(newValue)
        print('Time of Day:', newValue)
    end):setTooltip('Adjust the in-game time of day')

    -- Outdoor Ambient Color Picker
    section:addColorPicker({
        text = 'Outdoor Ambient Color',
        color = game.Lighting.OutdoorAmbient
    }, function(newColor)
        game.Lighting.OutdoorAmbient = newColor
        print('Outdoor Ambient Color changed:', newColor)
    end):setTooltip('Adjust the outdoor ambient color')

    -- Shadow Softness Slider
    section:addSlider({
        text = 'Shadow Softness',
        min = 0,
        max = 1,
        step = 0.01,
        val = game.Lighting.ShadowSoftness
    }, function(newValue)
        game.Lighting.ShadowSoftness = newValue
        print('Shadow Softness:', newValue)
    end):setTooltip('Adjust the softness of shadows')

    -- Exposure Compensation Slider
    section:addSlider({
        text = 'Exposure Compensation',
        min = -5,
        max = 5,
        step = 0.1,
        val = game.Lighting.ExposureCompensation
    }, function(newValue)
        game.Lighting.ExposureCompensation = newValue
        print('Exposure Compensation:', newValue)
    end):setTooltip('Adjust the exposure compensation for lighting')

    -- Ambient Color Picker
    section:addColorPicker({
        text = 'Ambient Color',
        color = game.Lighting.Ambient
    }, function(newColor)
        game.Lighting.Ambient = newColor
        print('Ambient Color changed:', newColor)
    end):setTooltip('Change the overall ambient light color')

    -- Global Shadows Toggle
    section:addToggle({
        text = 'Global Shadows',
        state = game.Lighting.GlobalShadows
    }):bindToEvent('onToggle', function(newState)
        game.Lighting.GlobalShadows = newState
        ui.notify({
            title = 'Global Shadows',
            message = newState and 'Shadows Enabled!' or 'Shadows Disabled!',
            duration = 3
        })
    end):setTooltip('Toggle global shadows on/off')

    -- Remove Grass Toggle
    section:addToggle({
        text = 'Remove Grass',
        state = false -- Default state, change if needed
    }):bindToEvent('onToggle', function(newState)
        -- Logic to remove grass
        if newState then
            for _, v in pairs(workspace:GetChildren()) do
                if v:IsA("Part") and v.Name == "Grass" then
                    v.Transparency = 1 -- Hide grass by making it transparent
                end
            end
            ui.notify({
                title = 'Remove Grass',
                message = 'Grass removed!',
                duration = 3
            })
        else
            for _, v in pairs(workspace:GetChildren()) do
                if v:IsA("Part") and v.Name == "Grass" then
                    v.Transparency = 0 -- Restore grass visibility
                end
            end
            ui.notify({
                title = 'Remove Grass',
                message = 'Grass restored!',
                duration = 3
            })
        end
    end):setTooltip('Toggle to remove or restore grass in the environment')
end

local menu6 = window:addMenu({
    text = 'ESP Settings'
})

local espSection = menu6:addSection({
    text = 'ESP Toggles',
    side = 'auto',
    showMinButton = true,
})

-- Toggle Health ESP
local healthToggle = espSection:addToggle({
    text = 'Health ESP',
    state = _G.HealthESPEnabled
})

healthToggle:bindToEvent('onToggle', function(newState)
    _G.HealthESPEnabled = newState
    ui.notify({
        title = 'Health ESP',
        message = newState and 'Health ESP Enabled!' or 'Health ESP Disabled!',
        duration = 3
    })
end)

-- Toggle Name ESP
local nameToggle = espSection:addToggle({
    text = 'Name ESP',
    state = _G.NameESPEnabled
})

nameToggle:bindToEvent('onToggle', function(newState)
    _G.NameESPEnabled = newState
    ui.notify({
        title = 'Name ESP',
        message = newState and 'Name ESP Enabled!' or 'Name ESP Disabled!',
        duration = 3
    })
end)

-- Toggle Box ESP
local boxToggle = espSection:addToggle({
    text = 'Box ESP',
    state = _G.BoxESPEnabled
})

boxToggle:bindToEvent('onToggle', function(newState)
    _G.BoxESPEnabled = newState
    ui.notify({
        title = 'Box ESP',
        message = newState and 'Box ESP Enabled!' or 'Box ESP Disabled!',
        duration = 3
    })
end)

-- Toggle Distance ESP
local distanceToggle = espSection:addToggle({
    text = 'Distance ESP',
    state = _G.DistanceESPEnabled
})

distanceToggle:bindToEvent('onToggle', function(newState)
    _G.DistanceESPEnabled = newState
    ui.notify({
        title = 'Distance ESP',
        message = newState and 'Distance ESP Enabled!' or 'Distance ESP Disabled!',
        duration = 3
    })
end)

-- Menu 3 (Miscellaneous)
local menu3 = window:addMenu({
    text = 'Misc'
})

-- Free Cam Feature in Misc Menu
do
    -- Free Cam Toggle State
    _G.FreeCamEnabled = false

    local section = menu3:addSection({
        text = 'Free Cam',
        side = 'auto',
        showMinButton = true
    })

    -- Free Cam Toggle
    local freeCamToggle = section:addToggle({
        text = 'Free Cam Mode',
        state = _G.FreeCamEnabled
    })

    -- Toggle Function for Free Cam Mode
    freeCamToggle:bindToEvent('onToggle', function(newState)
        _G.FreeCamEnabled = newState
        if newState then
            startFreeCam()
        else
            stopFreeCam()
        end

        ui.notify({
            title = 'Free Cam',
            message = newState and 'Free Cam Mode Activated!' or 'Free Cam Mode Deactivated!',
            duration = 3
        })
    end)

    -- Hotkey to Toggle Free Cam Mode (e.g., F key)
    game:GetService("UserInputService").InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.F then
            _G.FreeCamEnabled = not _G.FreeCamEnabled
            if _G.FreeCamEnabled then
                startFreeCam()
            else
                stopFreeCam()
            end
            ui.notify({
                title = 'Free Cam',
                message = _G.FreeCamEnabled and 'Free Cam Enabled!' or 'Free Cam Disabled!',
                duration = 3
            })
        end
    end)
end

-- Free Cam Logic
local function startFreeCam()
    local camera = game.Workspace.CurrentCamera
    camera.CameraType = Enum.CameraType.Scriptable

    -- Add controls here for moving camera, for example using WASD keys
    -- This part would need to handle user inputs for directional movement
    -- and update the camera CFrame based on input.
end

local function stopFreeCam()
    local camera = game.Workspace.CurrentCamera
    camera.CameraType = Enum.CameraType.Custom
    camera.CFrame = game.Players.LocalPlayer.Character.Head.CFrame -- Reset camera to player
end
