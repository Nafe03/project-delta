--!strict
-- UILibrary by YourName
-- Version: 1.0.0
-- GitHub: https://github.com/yourusername/uilibrary

local UILibrary = {}

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

-- Color conversion functions
local function HSVtoRGB(h, s, v)
    local r, g, b
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    
    local imod = i % 6
    if imod == 0 then
        r, g, b = v, t, p
    elseif imod == 1 then
        r, g, b = q, v, p
    elseif imod == 2 then
        r, g, b = p, v, t
    elseif imod == 3 then
        r, g, b = p, q, v
    elseif imod == 4 then
        r, g, b = t, p, v
    elseif imod == 5 then
        r, g, b = v, p, q
    end
    
    return r, g, b
end

local function RGBtoHSV(r, g, b)
    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local h, s, v = 0, 0, max
    
    local d = max - min
    s = max == 0 and 0 or d / max
    
    if max == min then
        h = 0
    else
        if max == r then
            h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then
            h = (b - r) / d + 2
        elseif max == b then
            h = (r - g) / d + 4
        end
        h = h / 6
    end
    
    return h, s, v
end

local function colorToHex(color)
    local r = math.floor(color.r * 255)
    local g = math.floor(color.g * 255)
    local b = math.floor(color.b * 255)
    return string.format("#%02X%02X%02X", r, g, b)
end

-- Main UI creation function
function UILibrary.new(options)
    options = options or {}
    local player = Players.LocalPlayer
    local mouse = player:GetMouse()
    local Camera = workspace.CurrentCamera

    -- Default options
    local defaultOptions = {
        Name = "UI Library",
        ToggleKey = Enum.KeyCode.RightShift,
        CloseKey = Enum.KeyCode.X,
        DefaultColor = Color3.fromRGB(165, 127, 159),
        TextColor = Color3.fromRGB(200, 200, 200),
        BackgroundColor = Color3.fromRGB(5, 5, 5),
        TabHolderColor = Color3.fromRGB(8, 8, 8),
        GroupboxColor = Color3.fromRGB(10, 10, 10),
        Size = UDim2.new(0, 570, 0, 469),
        Position = UDim2.new(0.226, 0, 0.146, 0),
        Theme = "Dark",
        Watermark = true,
        WatermarkText = "UI Library v1.0.0"
    }
    
    for option, value in pairs(defaultOptions) do
        if options[option] == nil then
            options[option] = value
        end
    end

    -- Create main instances
    local ScreenGui = Instance.new("ScreenGui")
    local MainBackGround = Instance.new("Frame")
    local UICorner = Instance.new("UICorner")
    local TabHolder = Instance.new("Frame")
    local UICorner_2 = Instance.new("UICorner")
    local ContentFrame = Instance.new("Frame")
    local UICorner_3 = Instance.new("UICorner")

    ScreenGui.Name = options.Name
    ScreenGui.Parent = player:WaitForChild("PlayerGui")
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false

    MainBackGround.Name = "MainBackGround"
    MainBackGround.Parent = ScreenGui
    MainBackGround.BackgroundColor3 = options.BackgroundColor
    MainBackGround.BorderColor3 = Color3.fromRGB(10, 10, 10)
    MainBackGround.Position = options.Position
    MainBackGround.Size = options.Size
    UICorner.CornerRadius = UDim.new(0, 3)
    UICorner.Parent = MainBackGround

    TabHolder.Name = "TabHolder"
    TabHolder.Parent = MainBackGround
    TabHolder.BackgroundColor3 = options.TabHolderColor
    TabHolder.BorderColor3 = Color3.fromRGB(0, 0, 0)
    TabHolder.Position = UDim2.new(0, 0, 0, 0)
    TabHolder.Size = UDim2.new(0, 113, 0, options.Size.Y.Offset)
    UICorner_2.CornerRadius = UDim.new(0, 3)
    UICorner_2.Parent = TabHolder

    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.Parent = TabHolder
    TabListLayout.FillDirection = Enum.FillDirection.Vertical
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, 0)

    ContentFrame.Name = "ContentFrame"
    ContentFrame.Parent = MainBackGround
    ContentFrame.BackgroundColor3 = options.BackgroundColor
    ContentFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ContentFrame.Position = UDim2.new(0, 118, 0, 10)
    ContentFrame.Size = UDim2.new(0, options.Size.X.Offset - 128, 0, options.Size.Y.Offset - 20)
    UICorner_3.CornerRadius = UDim.new(0, 3)
    UICorner_3.Parent = ContentFrame

    -- Watermark
    if options.Watermark then
        local Watermark = Instance.new("TextLabel")
        Watermark.Name = "Watermark"
        Watermark.Parent = ScreenGui
        Watermark.BackgroundTransparency = 1
        Watermark.Position = UDim2.new(0, 10, 0, 10)
        Watermark.Size = UDim2.new(0, 200, 0, 20)
        Watermark.Font = Enum.Font.JosefinSans
        Watermark.Text = options.WatermarkText
        Watermark.TextColor3 = options.TextColor
        Watermark.TextSize = 14
        Watermark.TextXAlignment = Enum.TextXAlignment.Left
    end

    -- Tab Management
    local tabs = {}
    local currentTab = nil

    -- Window object
    local Window = {}
    Window.ActiveTab = nil
    Window.Theme = options.Theme
    Window.DefaultColor = options.DefaultColor
    Window.TextColor = options.TextColor

    function Window:AddTab(name)
        local TabButton = Instance.new("TextButton")
        local TabContent = Instance.new("ScrollingFrame")
        local TabHighlight = Instance.new("Frame")
        
        -- Create Left Container
        local LeftContainer = Instance.new("Frame")
        local LeftLayout = Instance.new("UIListLayout")
        
        -- Create Right Container
        local RightContainer = Instance.new("Frame")
        local RightLayout = Instance.new("UIListLayout")

        -- Tab Button
        TabButton.Name = name .. "Tab"
        TabButton.Parent = TabHolder
        TabButton.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
        TabButton.BackgroundTransparency = 1
        TabButton.BorderSizePixel = 0
        TabButton.Size = UDim2.new(1, 0, 0, 30)
        TabButton.Font = Enum.Font.JosefinSans
        TabButton.Text = name
        TabButton.TextColor3 = options.TextColor
        TabButton.TextTransparency = 0.5
        TabButton.TextSize = 14.000
        TabButton.TextXAlignment = Enum.TextXAlignment.Center

        TabHighlight.Parent = TabButton
        TabHighlight.BackgroundColor3 = options.DefaultColor
        TabHighlight.BorderSizePixel = 0
        TabHighlight.Position = UDim2.new(0, 0, 0, 0)
        TabHighlight.Size = UDim2.new(0, 3, 1, 0)
        TabHighlight.ZIndex = 2
        TabHighlight.Visible = false

        -- Tab Content
        TabContent.Name = name .. "Content"
        TabContent.Parent = ContentFrame
        TabContent.BackgroundTransparency = 1
        TabContent.Size = UDim2.new(1, 0, 1, 0)
        TabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
        TabContent.ScrollBarThickness = 4
        TabContent.ScrollBarImageColor3 = options.DefaultColor
        TabContent.Visible = false

        -- Left Container Setup
        LeftContainer.Name = "LeftContainer"
        LeftContainer.Parent = TabContent
        LeftContainer.BackgroundTransparency = 1
        LeftContainer.Position = UDim2.new(0, 10, 0, 1)
        LeftContainer.Size = UDim2.new(0.5, -15, 1, -20)
        
        LeftLayout.Parent = LeftContainer
        LeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
        LeftLayout.Padding = UDim.new(0, 10)
        LeftLayout.FillDirection = Enum.FillDirection.Vertical
        LeftLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        LeftLayout.VerticalAlignment = Enum.VerticalAlignment.Top

        -- Right Container Setup
        RightContainer.Name = "RightContainer"
        RightContainer.Parent = TabContent
        RightContainer.BackgroundTransparency = 1
        RightContainer.Position = UDim2.new(0.5, 5, 0, 1)
        RightContainer.Size = UDim2.new(0.5, -15, 1, -20)
        
        RightLayout.Parent = RightContainer
        RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
        RightLayout.Padding = UDim.new(0, 10)
        RightLayout.FillDirection = Enum.FillDirection.Vertical
        RightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        RightLayout.VerticalAlignment = Enum.VerticalAlignment.Top

        -- Function to update content size
        local function updateContentSize()
            local leftHeight = LeftLayout.AbsoluteContentSize.Y + 20
            local rightHeight = RightLayout.AbsoluteContentSize.Y + 20
            local maxHeight = math.max(leftHeight, rightHeight)
            TabContent.CanvasSize = UDim2.new(0, 0, 0, maxHeight)
        end

        -- Update content size when layouts change
        LeftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateContentSize)
        RightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateContentSize)

        -- Tab Object
        local tab = {
            Button = TabButton,
            Content = TabContent,
            Highlight = TabHighlight,
            LeftContainer = LeftContainer,
            RightContainer = RightContainer,
            Groupboxes = {},
            AddLeftGroupbox = function(self, name)
                return self:CreateGroupbox(name, "Left")
            end,
            AddRightGroupbox = function(self, name)
                return self:CreateGroupbox(name, "Right")
            end,
            CreateGroupbox = function(self, name, side)
                local GroupboxFrame = Instance.new("Frame")
                local GroupboxCorner = Instance.new("UICorner")
                local GroupboxTitle = Instance.new("TextLabel")
                local GroupboxContent = Instance.new("Frame")
                local GroupboxLayout = Instance.new("UIListLayout")

                GroupboxFrame.Name = name .. "Groupbox"
                GroupboxFrame.BackgroundColor3 = options.GroupboxColor
                GroupboxFrame.BorderColor3 = Color3.fromRGB(20, 20, 20)
                GroupboxFrame.BorderSizePixel = 1
                GroupboxFrame.Size = UDim2.new(1, 0, 0, 35)
                GroupboxFrame.LayoutOrder = #self.Groupboxes + 1

                -- Parent to correct container
                if side == "Left" then
                    GroupboxFrame.Parent = LeftContainer
                else
                    GroupboxFrame.Parent = RightContainer
                end

                GroupboxCorner.CornerRadius = UDim.new(0, 3)
                GroupboxCorner.Parent = GroupboxFrame

                GroupboxTitle.Name = "Title"
                GroupboxTitle.Parent = GroupboxFrame
                GroupboxTitle.BackgroundTransparency = 1
                GroupboxTitle.Position = UDim2.new(0, 5, 0, 5)
                GroupboxTitle.Size = UDim2.new(1, -10, 0, 20)
                GroupboxTitle.Font = Enum.Font.JosefinSans
                GroupboxTitle.Text = name
                GroupboxTitle.TextColor3 = options.DefaultColor
                GroupboxTitle.TextSize = 14
                GroupboxTitle.TextXAlignment = Enum.TextXAlignment.Left

                GroupboxContent.Name = "Content"
                GroupboxContent.Parent = GroupboxFrame
                GroupboxContent.BackgroundTransparency = 1
                GroupboxContent.Position = UDim2.new(0, 5, 0, 30)
                GroupboxContent.Size = UDim2.new(1, -10, 1, -35)

                GroupboxLayout.Parent = GroupboxContent
                GroupboxLayout.SortOrder = Enum.SortOrder.LayoutOrder
                GroupboxLayout.Padding = UDim.new(0, 5)

                local groupbox = {
                    Frame = GroupboxFrame,
                    Content = GroupboxContent,
                    Layout = GroupboxLayout,
                    Side = side,
                    Elements = {},
                    AddToggle = function(self, id, options)
                        options = options or {}
                        options.DefaultColor = options.DefaultColor or Window.DefaultColor
                        options.TextColor = options.TextColor or Window.TextColor
                        
                        local ToggleFrame = Instance.new("Frame")
                        local ToggleButton = Instance.new("TextButton")
                        local ToggleIndicator = Instance.new("Frame")
                        local ToggleIndicatorCorner = Instance.new("UICorner")
                        local ToggleText = Instance.new("TextLabel")
                        
                        -- Add gear icon for color picker if specified
                        local GearIcon = nil
                        if options.HasColorPicker then
                            GearIcon = Instance.new("TextButton")
                            GearIcon.Name = "GearIcon"
                            GearIcon.Parent = ToggleFrame
                            GearIcon.BackgroundTransparency = 0.8
                            GearIcon.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                            GearIcon.Position = UDim2.new(1, -15, 0.5, -7)
                            GearIcon.Size = UDim2.new(0, 14, 0, 14)
                            GearIcon.Font = Enum.Font.JosefinSans
                            GearIcon.Text = "⚙️"
                            GearIcon.TextSize = 12
                            GearIcon.TextColor3 = options.DefaultColor
                            GearIcon.Visible = true
                            GearIcon.AutoButtonColor = false
                            GearIcon.ZIndex = 2
                            
                            local gearCorner = Instance.new("UICorner")
                            gearCorner.CornerRadius = UDim.new(0, 3)
                            gearCorner.Parent = GearIcon
                        end
                    
                        ToggleFrame.Name = id .. "Toggle"
                        ToggleFrame.Parent = GroupboxContent
                        ToggleFrame.BackgroundTransparency = 1
                        ToggleFrame.Size = UDim2.new(1, 0, 0, 20)
                        ToggleFrame.LayoutOrder = #self.Elements + 1
                    
                        ToggleButton.Name = "Button"
                        ToggleButton.Parent = ToggleFrame
                        ToggleButton.BackgroundTransparency = 1
                        ToggleButton.Size = UDim2.new(1, 0, 1, 0)
                        ToggleButton.Text = ""
                    
                        ToggleIndicator.Name = "Indicator"
                        ToggleIndicator.Parent = ToggleFrame
                        ToggleIndicator.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                        ToggleIndicator.BorderColor3 = Color3.fromRGB(50, 50, 50)
                        ToggleIndicator.BorderSizePixel = 1
                        ToggleIndicator.Position = UDim2.new(0, 0, 0.5, -6)
                        ToggleIndicator.Size = UDim2.new(0, 12, 0, 12)
                    
                        ToggleIndicatorCorner.CornerRadius = UDim.new(0, 2)
                        ToggleIndicatorCorner.Parent = ToggleIndicator
                    
                        ToggleText.Name = "Text"
                        ToggleText.Parent = ToggleFrame
                        ToggleText.BackgroundTransparency = 1
                        ToggleText.Position = UDim2.new(0, 20, 0, 0)
                        ToggleText.Size = UDim2.new(1, -20, 1, 0)
                        ToggleText.Font = Enum.Font.JosefinSans
                        ToggleText.Text = options.Text or id
                        ToggleText.TextColor3 = options.TextColor  -- Now guaranteed to have a value
                        ToggleText.TextSize = 12
                        ToggleText.TextXAlignment = Enum.TextXAlignment.Left
                    
                        local toggled = options.Default or false
                    
                        local function updateToggle()
                            ToggleIndicator.BackgroundColor3 = toggled and options.DefaultColor or Color3.fromRGB(30, 30, 30)
                            if options.Callback then
                                options.Callback(toggled)
                            end
                        end
                    
                        ToggleButton.MouseButton1Click:Connect(function()
                            toggled = not toggled
                            updateToggle()
                        end)
                    
                        -- Color picker implementation
                        local colorPicker = nil
                        if options.HasColorPicker then
                            -- Create dedicated ScreenGui for color picker
                            local colorPickerScreenGui = Instance.new("ScreenGui")
                            colorPickerScreenGui.Name = "ColorPickerGui_" .. id
                            colorPickerScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
                            colorPickerScreenGui.ResetOnSpawn = false
                            colorPickerScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                            
                            -- Create main color picker window
                            local colorPickerWindow = Instance.new("Frame")
                            colorPickerWindow.Name = "ColorPickerWindow"
                            colorPickerWindow.Parent = colorPickerScreenGui
                            colorPickerWindow.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                            colorPickerWindow.BorderSizePixel = 0
                            colorPickerWindow.Position = UDim2.new(0.5, -150, 0.5, -175)
                            colorPickerWindow.Size = UDim2.new(0, 300, 0, 350)
                            colorPickerWindow.Visible = false
                            colorPickerWindow.ZIndex = 100
                            
                            local windowCorner = Instance.new("UICorner")
                            windowCorner.CornerRadius = UDim.new(0, 12)
                            windowCorner.Parent = colorPickerWindow
                            
                            -- Window title bar
                            local titleBar = Instance.new("Frame")
                            titleBar.Name = "TitleBar"
                            titleBar.Parent = colorPickerWindow
                            titleBar.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
                            titleBar.BorderSizePixel = 0
                            titleBar.Size = UDim2.new(1, 0, 0, 40)
                            titleBar.ZIndex = 101
                            
                            local titleCorner = Instance.new("UICorner")
                            titleCorner.CornerRadius = UDim.new(0, 12)
                            titleCorner.Parent = titleBar
                            
                            -- Fix title bar corners
                            local titleBarFix = Instance.new("Frame")
                            titleBarFix.Parent = titleBar
                            titleBarFix.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
                            titleBarFix.BorderSizePixel = 0
                            titleBarFix.Position = UDim2.new(0, 0, 0.6, 0)
                            titleBarFix.Size = UDim2.new(1, 0, 0.4, 0)
                            titleBarFix.ZIndex = 101
                            
                            local titleText = Instance.new("TextLabel")
                            titleText.Name = "TitleText"
                            titleText.Parent = titleBar
                            titleText.BackgroundTransparency = 1
                            titleText.Position = UDim2.new(0, 20, 0, 0)
                            titleText.Size = UDim2.new(1, -80, 1, 0)
                            titleText.Font = Enum.Font.SourceSansBold
                            titleText.Text = "Color Picker - " .. (options.Text or id)
                            titleText.TextColor3 = options.DefaultColor
                            titleText.TextSize = 16
                            titleText.TextXAlignment = Enum.TextXAlignment.Left
                            titleText.ZIndex = 102
                            
                            -- Close button
                            local closeButton = Instance.new("TextButton")
                            closeButton.Name = "CloseButton"
                            closeButton.Parent = titleBar
                            closeButton.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
                            closeButton.BorderSizePixel = 0
                            closeButton.Position = UDim2.new(1, -35, 0, 10)
                            closeButton.Size = UDim2.new(0, 20, 0, 20)
                            closeButton.Font = Enum.Font.SourceSansBold
                            closeButton.Text = "×"
                            closeButton.TextColor3 = Color3.new(1, 1, 1)
                            closeButton.TextSize = 14
                            closeButton.ZIndex = 102
                            closeButton.AutoButtonColor = false
                            
                            local closeButtonCorner = Instance.new("UICorner")
                            closeButtonCorner.CornerRadius = UDim.new(1, 0)
                            closeButtonCorner.Parent = closeButton
                            
                            -- Add hover effect for close button
                            closeButton.MouseEnter:Connect(function()
                                closeButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
                            end)
                            closeButton.MouseLeave:Connect(function()
                                closeButton.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
                            end)
                            
                            -- Content frame for color picker
                            local colorPickerFrame = Instance.new("Frame")
                            colorPickerFrame.Name = "ColorPickerFrame"
                            colorPickerFrame.Parent = colorPickerWindow
                            colorPickerFrame.BackgroundTransparency = 1
                            colorPickerFrame.Position = UDim2.new(0, 20, 0, 55)
                            colorPickerFrame.Size = UDim2.new(1, -40, 1, -75)
                            colorPickerFrame.ZIndex = 101
                            
                            -- Color preview with better styling
                            local colorPreview = Instance.new("Frame")
                            colorPreview.Name = "ColorPreview"
                            colorPreview.Parent = colorPickerFrame
                            colorPreview.BackgroundColor3 = Color3.new(1, 1, 1)
                            colorPreview.BorderSizePixel = 0
                            colorPreview.Position = UDim2.new(0, 0, 0, 0)
                            colorPreview.Size = UDim2.new(1, 0, 0, 35)
                            colorPreview.ZIndex = 101
                            
                            local previewCorner = Instance.new("UICorner")
                            previewCorner.CornerRadius = UDim.new(0, 8)
                            previewCorner.Parent = colorPreview
                            
                            -- Add subtle border to preview
                            local previewBorder = Instance.new("UIStroke")
                            previewBorder.Color = Color3.fromRGB(80, 80, 80)
                            previewBorder.Thickness = 1
                            previewBorder.Parent = colorPreview
                            
                            -- Saturation/Value box with better styling
                            local saturationValueBox = Instance.new("Frame")
                            saturationValueBox.Name = "SaturationValueBox"
                            saturationValueBox.Parent = colorPickerFrame
                            saturationValueBox.BackgroundColor3 = Color3.new(1, 0, 0)
                            saturationValueBox.BorderSizePixel = 0
                            saturationValueBox.Position = UDim2.new(0, 0, 0, 50)
                            saturationValueBox.Size = UDim2.new(0, 180, 0, 180)
                            saturationValueBox.ZIndex = 101
                            
                            local svCorner = Instance.new("UICorner")
                            svCorner.CornerRadius = UDim.new(0, 8)
                            svCorner.Parent = saturationValueBox
                            
                            local svBorder = Instance.new("UIStroke")
                            svBorder.Color = Color3.fromRGB(80, 80, 80)
                            svBorder.Thickness = 1
                            svBorder.Parent = saturationValueBox
                            
                            local saturationValueGradient1 = Instance.new("UIGradient")
                            saturationValueGradient1.Color = ColorSequence.new{
                                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                                ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))
                            }
                            saturationValueGradient1.Transparency = NumberSequence.new{
                                NumberSequenceKeypoint.new(0, 0),
                                NumberSequenceKeypoint.new(1, 1)
                            }
                            saturationValueGradient1.Parent = saturationValueBox
                            
                            local saturationValueGradient2 = Instance.new("UIGradient")
                            saturationValueGradient2.Color = ColorSequence.new{
                                ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
                                ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0))
                            }
                            saturationValueGradient2.Transparency = NumberSequence.new{
                                NumberSequenceKeypoint.new(0, 1),
                                NumberSequenceKeypoint.new(1, 0)
                            }
                            saturationValueGradient2.Rotation = 90
                            saturationValueGradient2.Parent = saturationValueBox
                            
                            local saturationValueButton = Instance.new("TextButton")
                            saturationValueButton.Name = "SaturationValueButton"
                            saturationValueButton.Parent = saturationValueBox
                            saturationValueButton.BackgroundColor3 = Color3.new(1, 1, 1)
                            saturationValueButton.BorderSizePixel = 0
                            saturationValueButton.Position = UDim2.new(0.5, -6, 0.5, -6)
                            saturationValueButton.Size = UDim2.new(0, 12, 0, 12)
                            saturationValueButton.Text = ""
                            saturationValueButton.ZIndex = 102
                            saturationValueButton.AutoButtonColor = false
                            
                            local svButtonCorner = Instance.new("UICorner")
                            svButtonCorner.CornerRadius = UDim.new(1, 0)
                            svButtonCorner.Parent = saturationValueButton
                            
                            local svButtonBorder = Instance.new("UIStroke")
                            svButtonBorder.Color = Color3.fromRGB(40, 40, 40)
                            svButtonBorder.Thickness = 2
                            svButtonBorder.Parent = saturationValueButton
                            
                            -- Hue slider with better styling
                            local hueSlider = Instance.new("Frame")
                            hueSlider.Name = "HueSlider"
                            hueSlider.Parent = colorPickerFrame
                            hueSlider.BackgroundColor3 = Color3.new(1, 1, 1)
                            hueSlider.BorderSizePixel = 0
                            hueSlider.Position = UDim2.new(0, 200, 0, 50)
                            hueSlider.Size = UDim2.new(0, 20, 0, 180)
                            hueSlider.ZIndex = 101
                            
                            local hueCorner = Instance.new("UICorner")
                            hueCorner.CornerRadius = UDim.new(0, 8)
                            hueCorner.Parent = hueSlider
                            
                            local hueBorder = Instance.new("UIStroke")
                            hueBorder.Color = Color3.fromRGB(80, 80, 80)
                            hueBorder.Thickness = 1
                            hueBorder.Parent = hueSlider
                            
                            local hueSliderGradient = Instance.new("UIGradient")
                            hueSliderGradient.Color = ColorSequence.new{
                                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                                ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 0, 255)),
                                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 0, 255)),
                                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                                ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 255, 0)),
                                ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 255, 0)),
                                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
                            }
                            hueSliderGradient.Rotation = 90
                            hueSliderGradient.Parent = hueSlider
                            
                            local hueSliderButton = Instance.new("TextButton")
                            hueSliderButton.Name = "HueSliderButton"
                            hueSliderButton.Parent = hueSlider
                            hueSliderButton.BackgroundColor3 = Color3.new(1, 1, 1)
                            hueSliderButton.BorderSizePixel = 0
                            hueSliderButton.Position = UDim2.new(0, -4, 0, 0)
                            hueSliderButton.Size = UDim2.new(1, 8, 0, 8)
                            hueSliderButton.Text = ""
                            hueSliderButton.ZIndex = 102
                            hueSliderButton.AutoButtonColor = false
                            
                            local hueButtonCorner = Instance.new("UICorner")
                            hueButtonCorner.CornerRadius = UDim.new(0, 4)
                            hueButtonCorner.Parent = hueSliderButton
                            
                            local hueButtonBorder = Instance.new("UIStroke")
                            hueButtonBorder.Color = Color3.fromRGB(40, 40, 40)
                            hueButtonBorder.Thickness = 2
                            hueButtonBorder.Parent = hueSliderButton
                            
                            -- RGB input fields with better styling
                            local rgbFrame = Instance.new("Frame")
                            rgbFrame.Name = "RGBFrame"
                            rgbFrame.Parent = colorPickerFrame
                            rgbFrame.BackgroundTransparency = 1
                            rgbFrame.Position = UDim2.new(0, 0, 0, 245)
                            rgbFrame.Size = UDim2.new(1, 0, 0, 50)
                            rgbFrame.ZIndex = 101
                            
                            local function createRGBInput(name, position)
                                local label = Instance.new("TextLabel")
                                label.Name = name .. "Label"
                                label.Parent = rgbFrame
                                label.BackgroundTransparency = 1
                                label.Position = position
                                label.Size = UDim2.new(0, 20, 0, 25)
                                label.Font = Enum.Font.SourceSansBold
                                label.Text = name .. ":"
                                label.TextColor3 = Color3.fromRGB(220, 220, 220)
                                label.TextSize = 14
                                label.TextXAlignment = Enum.TextXAlignment.Left
                                label.ZIndex = 102
                                
                                local input = Instance.new("TextBox")
                                input.Name = name .. "Input"
                                input.Parent = rgbFrame
                                input.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                                input.BorderSizePixel = 0
                                input.Position = UDim2.new(0, position.X.Offset + 25, 0, position.Y.Offset)
                                input.Size = UDim2.new(0, 45, 0, 25)
                                input.Font = Enum.Font.SourceSans
                                input.Text = "255"
                                input.TextColor3 = Color3.fromRGB(255, 255, 255)
                                input.TextSize = 14
                                input.TextXAlignment = Enum.TextXAlignment.Center
                                input.ZIndex = 102
                                
                                local inputCorner = Instance.new("UICorner")
                                inputCorner.CornerRadius = UDim.new(0, 6)
                                inputCorner.Parent = input
                                
                                local inputBorder = Instance.new("UIStroke")
                                inputBorder.Color = Color3.fromRGB(80, 80, 80)
                                inputBorder.Thickness = 1
                                inputBorder.Parent = input
                                
                                -- Add focus effects
                                input.Focused:Connect(function()
                                    inputBorder.Color = Color3.fromRGB(120, 120, 120)
                                end)
                                input.FocusLost:Connect(function()
                                    inputBorder.Color = Color3.fromRGB(80, 80, 80)
                                end)
                                
                                return input
                            end
                            
                            local rInput = createRGBInput("R", UDim2.new(0, 0, 0, 0))
                            local gInput = createRGBInput("G", UDim2.new(0, 0, 0, 27))
                            local bInput = createRGBInput("B", UDim2.new(0, 85, 0, 0))
                            
                            local hexLabel = Instance.new("TextLabel")
                            hexLabel.Name = "HexLabel"
                            hexLabel.Parent = rgbFrame
                            hexLabel.BackgroundTransparency = 1
                            hexLabel.Position = UDim2.new(0, 85, 0, 27)
                            hexLabel.Size = UDim2.new(0, 35, 0, 25)
                            hexLabel.Font = Enum.Font.SourceSansBold
                            hexLabel.Text = "Hex:"
                            hexLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
                            hexLabel.TextSize = 14
                            hexLabel.TextXAlignment = Enum.TextXAlignment.Left
                            hexLabel.ZIndex = 102
                            
                            local hexInput = Instance.new("TextBox")
                            hexInput.Name = "HexInput"
                            hexInput.Parent = rgbFrame
                            hexInput.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                            hexInput.BorderSizePixel = 0
                            hexInput.Position = UDim2.new(0, 125, 0, 27)
                            hexInput.Size = UDim2.new(0, 75, 0, 25)
                            hexInput.Font = Enum.Font.SourceSans
                            hexInput.Text = "#FFFFFF"
                            hexInput.TextColor3 = Color3.fromRGB(255, 255, 255)
                            hexInput.TextSize = 14
                            hexInput.TextXAlignment = Enum.TextXAlignment.Center
                            hexInput.ZIndex = 102
                            
                            local hexCorner = Instance.new("UICorner")
                            hexCorner.CornerRadius = UDim.new(0, 6)
                            hexCorner.Parent = hexInput
                            
                            local hexBorder = Instance.new("UIStroke")
                            hexBorder.Color = Color3.fromRGB(80, 80, 80)
                            hexBorder.Thickness = 1
                            hexBorder.Parent = hexInput
                            
                            -- Add focus effects for hex input
                            hexInput.Focused:Connect(function()
                                hexBorder.Color = Color3.fromRGB(120, 120, 120)
                            end)
                            hexInput.FocusLost:Connect(function()
                                hexBorder.Color = Color3.fromRGB(80, 80, 80)
                            end)
                            
                            -- Color picker logic
                            local currentColor = options.DefaultColor or Color3.new(1, 1, 1)
                            local hue = 0
                            local saturation = 0
                            local value = 1
                            
                            -- Update all UI elements
                            local function updateColor()
                                -- Convert HSV to RGB
                                local r, g, b = HSVtoRGB(hue, saturation, value)
                                currentColor = Color3.new(r, g, b)
                                
                                -- Update preview
                                colorPreview.BackgroundColor3 = currentColor
                                
                                -- Update saturation/value box background
                                saturationValueBox.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
                                
                                -- Update RGB inputs
                                rInput.Text = tostring(math.floor(currentColor.r * 255))
                                gInput.Text = tostring(math.floor(currentColor.g * 255))
                                bInput.Text = tostring(math.floor(currentColor.b * 255))
                                
                                -- Update hex input
                                hexInput.Text = colorToHex(currentColor)
                                
                                -- Update button positions
                                hueSliderButton.Position = UDim2.new(0, -4, 0, math.floor(hue * 172))
                                saturationValueButton.Position = UDim2.new(0, math.floor(saturation * 168), 0, math.floor((1 - value) * 168))
                                
                                -- Call callback
                                if options.ColorCallback then
                                    options.ColorCallback(currentColor)
                                end
                            end
                            
                            local function updateFromRGB(color)
                                hue, saturation, value = RGBtoHSV(color.r, color.g, color.b)
                                updateColor()
                            end
                            
                            -- Dragging logic
                            local hueDragging = false
                            local svDragging = false
                            local UserInputService = game:GetService("UserInputService")
                            
                            hueSliderButton.InputBegan:Connect(function(input)
                                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                    hueDragging = true
                                end
                            end)
                            
                            saturationValueButton.InputBegan:Connect(function(input)
                                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                    svDragging = true
                                end
                            end)
                            
                            UserInputService.InputChanged:Connect(function(input)
                                if input.UserInputType == Enum.UserInputType.MouseMovement then
                                    if hueDragging then
                                        local yPos = math.clamp(input.Position.Y - hueSlider.AbsolutePosition.Y, 0, 172)
                                        hue = yPos / 172
                                        updateColor()
                                    elseif svDragging then
                                        local xPos = math.clamp(input.Position.X - saturationValueBox.AbsolutePosition.X, 0, 168)
                                        local yPos = math.clamp(input.Position.Y - saturationValueBox.AbsolutePosition.Y, 0, 168)
                                        saturation = xPos / 168
                                        value = 1 - (yPos / 168)
                                        updateColor()
                                    end
                                end
                            end)
                            
                            UserInputService.InputEnded:Connect(function(input)
                                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                    hueDragging = false
                                    svDragging = false
                                end
                            end)
                            
                            -- Click handling for sliders
                            saturationValueBox.InputBegan:Connect(function(input)
                                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                    local xPos = math.clamp(input.Position.X - saturationValueBox.AbsolutePosition.X, 0, 168)
                                    local yPos = math.clamp(input.Position.Y - saturationValueBox.AbsolutePosition.Y, 0, 168)
                                    saturation = xPos / 168
                                    value = 1 - (yPos / 168)
                                    updateColor()
                                    svDragging = true
                                end
                            end)
                            
                            hueSlider.InputBegan:Connect(function(input)
                                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                    local yPos = math.clamp(input.Position.Y - hueSlider.AbsolutePosition.Y, 0, 172)
                                    hue = yPos / 172
                                    updateColor()
                                    hueDragging = true
                                end
                            end)
                            
                            -- RGB input handling
                            local function handleRGBInput()
                                local r = math.clamp(tonumber(rInput.Text) or 0, 0, 255) / 255
                                local g = math.clamp(tonumber(gInput.Text) or 0, 0, 255) / 255
                                local b = math.clamp(tonumber(bInput.Text) or 0, 0, 255) / 255
                                updateFromRGB(Color3.new(r, g, b))
                            end
                            
                            rInput.FocusLost:Connect(handleRGBInput)
                            gInput.FocusLost:Connect(handleRGBInput)
                            bInput.FocusLost:Connect(handleRGBInput)
                            
                            -- Hex input handling
                            hexInput.FocusLost:Connect(function()
                                local hex = hexInput.Text:gsub("#", "")
                                if hex:len() == 6 then
                                    local r = tonumber(hex:sub(1, 2), 16) / 255
                                    local g = tonumber(hex:sub(3, 4), 16) / 255
                                    local b = tonumber(hex:sub(5, 6), 16) / 255
                                    if r and g and b then
                                        updateFromRGB(Color3.new(r, g, b))
                                    end
                                end
                            end)
                            
                            -- Initialize with default color
                            if options.DefaultColor then
                                updateFromRGB(options.DefaultColor)
                            else
                                updateColor()
                            end
                            
                            -- Gear icon click handler
                            GearIcon.MouseButton1Click:Connect(function()
                                colorPickerWindow.Visible = not colorPickerWindow.Visible
                            end)
                            
                            -- Close button handler
                            closeButton.MouseButton1Click:Connect(function()
                                colorPickerWindow.Visible = false
                            end)
                            
                            -- Close when clicking outside
                            UserInputService.InputBegan:Connect(function(input)
                                if input.UserInputType == Enum.UserInputType.MouseButton1 and colorPickerWindow.Visible then
                                    local mousePos = UserInputService:GetMouseLocation()
                                    local windowPos = colorPickerWindow.AbsolutePosition
                                    local windowSize = colorPickerWindow.AbsoluteSize
                                    
                                    if mousePos.X < windowPos.X or mousePos.X > windowPos.X + windowSize.X or
                                       mousePos.Y < windowPos.Y or mousePos.Y > windowPos.Y + windowSize.Y then
                                        colorPickerWindow.Visible = false
                                    end
                                end
                            end)
                            
                            colorPicker = {
                                ScreenGui = colorPickerScreenGui,
                                Window = colorPickerWindow,
                                SetColor = function(color)
                                    updateFromRGB(color)
                                end,
                                GetColor = function()
                                    return currentColor
                                end,
                                Show = function()
                                    colorPickerWindow.Visible = true
                                end,
                                Hide = function()
                                    colorPickerWindow.Visible = false
                                end,
                                Destroy = function()
                                    colorPickerScreenGui:Destroy()
                                end
                            }
                        end
                    
                        updateToggle()

                        local element = {
                            Type = "Toggle",
                            Frame = ToggleFrame,
                            SetValue = function(value)
                                toggled = value
                                updateToggle()
                            end,
                            GetValue = function()
                                return toggled
                            end,
                            ColorPicker = colorPicker
                        }

                        table.insert(self.Elements, element)
                        self:UpdateSize()
                        return element
                    end,
                    AddSlider = function(self, id, options)
                        options = options or {}
    -- Ensure required properties have defaults
    options.DefaultColor = options.DefaultColor or Window.DefaultColor
    options.TextColor = options.TextColor or Window.TextColor
                        local SliderFrame = Instance.new("Frame")
                        local SliderText = Instance.new("TextLabel")
                        local SliderBackground = Instance.new("Frame")
                        local SliderBackgroundCorner = Instance.new("UICorner")
                        local SliderFill = Instance.new("Frame")
                        local SliderFillCorner = Instance.new("UICorner")
                        local SliderButton = Instance.new("TextButton")
                        local ValueLabel = Instance.new("TextLabel")

                        SliderFrame.Name = id .. "Slider"
                        SliderFrame.Parent = GroupboxContent
                        SliderFrame.BackgroundTransparency = 1
                        SliderFrame.Size = UDim2.new(1, 0, 0, 40)
                        SliderFrame.LayoutOrder = #self.Elements + 1

                        SliderText.Name = "Text"
    SliderText.Parent = SliderFrame
    SliderText.BackgroundTransparency = 1
    SliderText.Position = UDim2.new(0, 0, 0, 0)
    SliderText.Size = UDim2.new(1, -30, 0, 18)
    SliderText.Font = Enum.Font.JosefinSans
    SliderText.Text = options.Text or id
    SliderText.TextColor3 = options.TextColor -- Now guaranteed to have a value
    SliderText.TextSize = 12
    SliderText.TextXAlignment = Enum.TextXAlignment.Left

                        SliderBackground.Name = "Background"
                        SliderBackground.Parent = SliderFrame
                        SliderBackground.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                        SliderBackground.BorderColor3 = Color3.fromRGB(50, 50, 50)
                        SliderBackground.BorderSizePixel = 1
                        SliderBackground.Position = UDim2.new(0, 0, 0, 22)
                        SliderBackground.Size = UDim2.new(1, -30, 0, 15)

                        SliderBackgroundCorner.CornerRadius = UDim.new(0, 3)
                        SliderBackgroundCorner.Parent = SliderBackground

                        SliderFill.Name = "Fill"
                        SliderFill.Parent = SliderBackground
                        SliderFill.BackgroundColor3 = options.DefaultColor
                        SliderFill.BorderSizePixel = 0
                        SliderFill.Size = UDim2.new(0, 0, 1, 0)

                        SliderFillCorner.CornerRadius = UDim.new(0, 3)
                        SliderFillCorner.Parent = SliderFill

                        SliderButton.Name = "Button"
                        SliderButton.Parent = SliderBackground
                        SliderButton.BackgroundTransparency = 1
                        SliderButton.Size = UDim2.new(1, 0, 1, 0)
                        SliderButton.Text = ""

                        ValueLabel.Name = "Value"
                        ValueLabel.Parent = SliderFrame
                        ValueLabel.BackgroundTransparency = 1
                        ValueLabel.Position = UDim2.new(1, -25, 0, 0)
                        ValueLabel.Size = UDim2.new(0, 25, 0, 18)
                        ValueLabel.Font = Enum.Font.JosefinSans
                        ValueLabel.Text = tostring(options.Default or options.Min or 0)
                        ValueLabel.TextColor3 = options.DefaultColor
                        ValueLabel.TextSize = 10
                        ValueLabel.TextXAlignment = Enum.TextXAlignment.Right

                        local min = options.Min or 0
                        local max = options.Max or 100
                        local rounding = options.Rounding or 1
                        local value = options.Default or min
                        local dragging = false

                        local function updateSlider(input)
                            local sizeX = math.max(0, math.min(1, (input.Position.X - SliderBackground.AbsolutePosition.X) / SliderBackground.AbsoluteSize.X))
                            value = min + (max - min) * sizeX

                            if rounding == 1 then
                                value = math.floor(value)
                            elseif rounding == 2 then
                                value = math.floor(value * 10) / 10
                            elseif rounding == 3 then
                                value = math.floor(value * 100) / 100
                            end

                            SliderFill.Size = UDim2.new(sizeX, 0, 1, 0)
                            ValueLabel.Text = tostring(value)
                            if options.Callback then
                                options.Callback(value)
                            end
                        end

                        SliderButton.InputBegan:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                dragging = true
                                updateSlider(input)
                            end
                        end)

                        SliderButton.InputEnded:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                dragging = false
                            end
                        end)

                        UserInputService.InputChanged:Connect(function(input)
                            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                                updateSlider(input)
                            end
                        end)

                        local initialPercent = (value - min) / (max - min)
                        SliderFill.Size = UDim2.new(initialPercent, 0, 1, 0)
                        ValueLabel.Text = tostring(value)

                        local element = {
                            Type = "Slider",
                            Frame = SliderFrame,
                            SetValue = function(newValue)
                                value = math.max(min, math.min(max, newValue))
                                local percent = (value - min) / (max - min)
                                SliderFill.Size = UDim2.new(percent, 0, 1, 0)
                                ValueLabel.Text = tostring(value)
                            end,
                            GetValue = function()
                                return value
                            end
                        }

                        table.insert(self.Elements, element)
                        self:UpdateSize()
                        return element
                    end,
                    AddDropdown = function(self, id, options)
                        options = options or {}
    -- Ensure required properties have defaults
    options.DefaultColor = options.DefaultColor or Window.DefaultColor
    options.TextColor = options.TextColor or Window.TextColor
                        local DropdownFrame = Instance.new("Frame")
                        local DropdownText = Instance.new("TextLabel")
                        local DropdownButton = Instance.new("TextButton")
                        local DropdownButtonCorner = Instance.new("UICorner")
                        local DropdownArrow = Instance.new("TextLabel")
                        local DropdownList = Instance.new("Frame")
                        local DropdownListLayout = Instance.new("UIListLayout")
                        local DropdownListCorner = Instance.new("UICorner")

                        DropdownFrame.Name = id .. "Dropdown"
                        DropdownFrame.Parent = GroupboxContent
                        DropdownFrame.BackgroundTransparency = 1
                        DropdownFrame.Size = UDim2.new(1, 0, 0, 40)
                        DropdownFrame.LayoutOrder = #self.Elements + 1
                        DropdownFrame.ZIndex = 2

                        DropdownText.Name = "Text"
    DropdownText.Parent = DropdownFrame
    DropdownText.BackgroundTransparency = 1
    DropdownText.Position = UDim2.new(0, 0, 0, 0)
    DropdownText.Size = UDim2.new(1, 0, 0, 18)
    DropdownText.Font = Enum.Font.JosefinSans
    DropdownText.Text = options.Text or id
    DropdownText.TextColor3 = options.TextColor  -- Now guaranteed to have a value
    DropdownText.TextSize = 12
    DropdownText.TextXAlignment = Enum.TextXAlignment.Left

                        DropdownButton.Name = "Button"
                        DropdownButton.Parent = DropdownFrame
                        DropdownButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                        DropdownButton.BorderColor3 = Color3.fromRGB(50, 50, 50)
                        DropdownButton.Position = UDim2.new(0, 0, 0, 22)
                        DropdownButton.Size = UDim2.new(1, 0, 0, 18)
                        DropdownButton.Font = Enum.Font.JosefinSans
                        DropdownButton.Text = options.Values[1] or "Select..."
                        DropdownButton.TextColor3 = options.TextColor
                        DropdownButton.TextSize = 11
                        DropdownButton.TextXAlignment = Enum.TextXAlignment.Left
                        DropdownButton.TextTruncate = Enum.TextTruncate.AtEnd
                        DropdownButton.ZIndex = 2

                        DropdownButtonCorner.CornerRadius = UDim.new(0, 3)
                        DropdownButtonCorner.Parent = DropdownButton

                        DropdownArrow.Name = "Arrow"
                        DropdownArrow.Parent = DropdownButton
                        DropdownArrow.BackgroundTransparency = 1
                        DropdownArrow.Position = UDim2.new(1, -15, 0, 0)
                        DropdownArrow.Size = UDim2.new(0, 15, 1, 0)
                        DropdownArrow.Font = Enum.Font.JosefinSans
                        DropdownArrow.Text = "▼"
                        DropdownArrow.TextColor3 = options.DefaultColor
                        DropdownArrow.TextSize = 8

                        DropdownList.Name = "List"
                        DropdownList.Parent = DropdownFrame
                        DropdownList.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                        DropdownList.BorderColor3 = Color3.fromRGB(40, 40, 40)
                        DropdownList.BorderSizePixel = 1
                        DropdownList.Position = UDim2.new(0, 0, 0, 40)
                        DropdownList.Size = UDim2.new(1, 0, 0, 0)
                        DropdownList.Visible = false
                        DropdownList.ZIndex = 2

                        DropdownListCorner.CornerRadius = UDim.new(0, 2)
                        DropdownListCorner.Parent = DropdownList

                        DropdownListLayout.Parent = DropdownList
                        DropdownListLayout.SortOrder = Enum.SortOrder.LayoutOrder

                        local isOpen = false
                        local selectedValue = options.Values[1] or ""

                        for i, option in ipairs(options.Values) do
                            local OptionButton = Instance.new("TextButton")
                            local OptionButtonCorner = Instance.new("UICorner")

                            OptionButton.Name = "Option" .. i
                            OptionButton.Parent = DropdownList
                            OptionButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                            OptionButton.BorderSizePixel = 0
                            OptionButton.Size = UDim2.new(1, 0, 0, 18)
                            OptionButton.Font = Enum.Font.JosefinSans
                            OptionButton.Text = option
                            OptionButton.TextColor3 = options.TextColor
                            OptionButton.TextSize = 11
                            OptionButton.TextXAlignment = Enum.TextXAlignment.Left
                            OptionButton.ZIndex = 11

                            OptionButtonCorner.CornerRadius = UDim.new(0, 2)
                            OptionButtonCorner.Parent = OptionButton

                            OptionButton.MouseEnter:Connect(function()
                                OptionButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                            end)

                            OptionButton.MouseLeave:Connect(function()
                                OptionButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                            end)

                            OptionButton.MouseButton1Click:Connect(function()
                                selectedValue = option
                                DropdownButton.Text = option
                                DropdownList.Visible = false
                                isOpen = false
                                DropdownArrow.Text = "▼"
                                if options.Callback then
                                    options.Callback(option)
                                end
                            end)
                        end

                        DropdownButton.MouseButton1Click:Connect(function()
                            isOpen = not isOpen
                            DropdownList.Visible = isOpen
                            DropdownArrow.Text = isOpen and "▲" or "▼"
                            if isOpen then
                                DropdownList.Size = UDim2.new(1, 0, 0, #options.Values * 18)
                            end
                        end)

                        if options.Default then
                            selectedValue = options.Default
                            DropdownButton.Text = options.Default
                        end

                        local element = {
                            Type = "Dropdown",
                            Frame = DropdownFrame,
                            SetValue = function(value)
                                selectedValue = value
                                DropdownButton.Text = value
                            end,
                            GetValue = function()
                                return selectedValue
                            end
                        }

                        table.insert(self.Elements, element)
                        self:UpdateSize()
                        return element
                    end,
                    AddButton = function(self, id, options)
                        options = options or {}
    -- Ensure required properties have defaults
    options.DefaultColor = options.DefaultColor or Window.DefaultColor
    options.TextColor = options.TextColor or Window.TextColor
                        local ButtonFrame = Instance.new("Frame")
                        local Button = Instance.new("TextButton")
                        local ButtonCorner = Instance.new("UICorner")

                        ButtonFrame.Name = id .. "Button"
                        ButtonFrame.Parent = GroupboxContent
                        ButtonFrame.BackgroundTransparency = 1
                        ButtonFrame.Size = UDim2.new(1, 0, 0, 25)
                        ButtonFrame.LayoutOrder = #self.Elements + 1

                        Button.Name = "Button"
                        Button.Parent = ButtonFrame
                        Button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                        Button.BorderColor3 = Color3.fromRGB(50, 50, 50)
                        Button.Position = UDim2.new(0, 0, 0, 0)
                        Button.Size = UDim2.new(1, 0, 1, 0)
                        Button.Font = Enum.Font.JosefinSans
                        Button.Text = options.Text or id
                        Button.TextColor3 = options.TextColor
                        Button.TextSize = 12

                        ButtonCorner.CornerRadius = UDim.new(0, 3)
                        ButtonCorner.Parent = Button

                        Button.MouseEnter:Connect(function()
                            Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                        end)

                        Button.MouseLeave:Connect(function()
                            Button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                        end)

                        Button.MouseButton1Click:Connect(function()
                            if options.Callback then
                                options.Callback()
                            end
                        end)

                        local element = {
                            Type = "Button",
                            Frame = ButtonFrame,
                            Button = Button
                        }

                        table.insert(self.Elements, element)
                        self:UpdateSize()
                        return element
                    end,
                    AddLabel = function(self, id, options)
                        options = options or {}
    -- Ensure required properties have defaults
    options.DefaultColor = options.DefaultColor or Window.DefaultColor
    options.TextColor = options.TextColor or Window.TextColor
                        local LabelFrame = Instance.new("Frame")
                        local Label = Instance.new("TextLabel")

                        LabelFrame.Name = id .. "Label"
                        LabelFrame.Parent = GroupboxContent
                        LabelFrame.BackgroundTransparency = 1
                        LabelFrame.Size = UDim2.new(1, 0, 0, 20)
                        LabelFrame.LayoutOrder = #self.Elements + 1

                        Label.Name = "Label"
                        Label.Parent = LabelFrame
                        Label.BackgroundTransparency = 1
                        Label.Size = UDim2.new(1, 0, 1, 0)
                        Label.Font = Enum.Font.JosefinSans
                        Label.Text = options.Text or id
                        Label.TextColor3 = options.TextColor
                        Label.TextSize = 12
                        Label.TextXAlignment = Enum.TextXAlignment.Left

                        if options.Center then
                            Label.TextXAlignment = Enum.TextXAlignment.Center
                        end

                        local element = {
                            Type = "Label",
                            Frame = LabelFrame,
                            SetText = function(text)
                                Label.Text = text
                            end
                        }

                        table.insert(self.Elements, element)
                        self:UpdateSize()
                        return element
                    end,
                    AddTextBox = function(self, id, options)
                        options = options or {}
    -- Ensure required properties have defaults
    options.DefaultColor = options.DefaultColor or Window.DefaultColor
    options.TextColor = options.TextColor or Window.TextColor
                        local TextBoxFrame = Instance.new("Frame")
                        local TextBox = Instance.new("TextBox")
                        local TextBoxCorner = Instance.new("UICorner")

                        TextBoxFrame.Name = id .. "TextBox"
                        TextBoxFrame.Parent = GroupboxContent
                        TextBoxFrame.BackgroundTransparency = 1
                        TextBoxFrame.Size = UDim2.new(1, 0, 0, 25)
                        TextBoxFrame.LayoutOrder = #self.Elements + 1

                        TextBox.Name = "TextBox"
                        TextBox.Parent = TextBoxFrame
                        TextBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                        TextBox.BorderColor3 = Color3.fromRGB(50, 50, 50)
                        TextBox.Position = UDim2.new(0, 0, 0, 0)
                        TextBox.Size = UDim2.new(1, 0, 1, 0)
                        TextBox.Font = Enum.Font.JosefinSans
                        TextBox.PlaceholderText = options.Placeholder or "Enter text..."
                        TextBox.Text = options.Default or ""
                        TextBox.TextColor3 = options.TextColor
                        TextBox.TextSize = 12
                        TextBox.ClearTextOnFocus = options.ClearOnFocus or false

                        TextBoxCorner.CornerRadius = UDim.new(0, 3)
                        TextBoxCorner.Parent = TextBox

                        TextBox.FocusLost:Connect(function()
                            if options.Callback then
                                options.Callback(TextBox.Text)
                            end
                        end)

                        local element = {
                            Type = "TextBox",
                            Frame = TextBoxFrame,
                            SetText = function(text)
                                TextBox.Text = text
                            end,
                            GetText = function()
                                return TextBox.Text
                            end
                        }

                        table.insert(self.Elements, element)
                        self:UpdateSize()
                        return element
                    end,
                    UpdateSize = function(self)
                        local totalHeight = 35
                        for _, element in ipairs(self.Elements) do
                            totalHeight = totalHeight + element.Frame.Size.Y.Offset + 5
                        end
                        self.Frame.Size = UDim2.new(1, 0, 0, totalHeight)
                    end
                }

                table.insert(self.Groupboxes, groupbox)
                return groupbox
            end
        }

        TabButton.MouseButton1Click:Connect(function()
            for _, tabData in pairs(tabs) do
                tabData.Content.Visible = false
                tabData.Highlight.Visible = false
            end

            TabContent.Visible = true
            TabHighlight.Visible = true
            currentTab = tab
            Window.ActiveTab = tab
        end)

        tabs[name] = tab

        if not currentTab then
            TabContent.Visible = true
            TabHighlight.Visible = true
            currentTab = tab
            Window.ActiveTab = tab
        end

        return tab
    end

    -- Add destroy method to Window
    function Window:Destroy()
        ScreenGui:Destroy()
    end

    -- Add toggle visibility method
    function Window:ToggleVisibility()
        ScreenGui.Enabled = not ScreenGui.Enabled
    end

    -- Add set position method
    function Window:SetPosition(position)
        MainBackGround.Position = position
    end

    -- Add get position method
    function Window:GetPosition()
        return MainBackGround.Position
    end

    -- Add set size method
    function Window:SetSize(size)
        MainBackGround.Size = size
        TabHolder.Size = UDim2.new(0, 113, 0, size.Y.Offset)
        ContentFrame.Size = UDim2.new(0, size.X.Offset - 128, 0, size.Y.Offset - 20)
    end

    -- Add get size method
    function Window:GetSize()
        return MainBackGround.Size
    end

    return Window
end

return UILibrary
