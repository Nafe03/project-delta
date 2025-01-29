-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Local Player Info
local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ESP Settings
_G.ESPEnabled = true
_G.HealthESPEnabled = true
_G.NameESPEnabled = true
_G.BoxESPEnabled = true
_G.SkeletonESP = true
_G.DistanceESPEnabled = false
_G.ShowAmmo = true

_G.BoxColor = Color3.fromRGB(255, 255, 255)
_G.NameColor = Color3.fromRGB(255, 255, 255)
_G.AmmoColor = Color3.fromRGB(255, 255, 255)
_G.SkeletonColor = Color3.fromRGB(255, 255, 255)

-- Active ESP Storage
local activeESP = {}

-- Function to check if a model represents a player
local function isPlayerModel(model)
    local rootPart = model:FindFirstChild("HumanoidRootPart")
    
    -- If the model has no Humanoid, add one
    if not model:FindFirstChild("Humanoid") then
        local humanoid = Instance.new("Humanoid")
        humanoid.Parent = model
    end
    
    return rootPart ~= nil
end

-- Function to Create Name ESP
local function CreateNameESP(model)
    local nameTag = Drawing.new("Text")
    nameTag.Size = 20
    nameTag.Center = true
    nameTag.Outline = true
    nameTag.Color = _G.NameColor
    nameTag.Font = 3
    nameTag.Visible = false
    return nameTag
end

-- Function to Draw ESP Box
local function DrawESPBox(model)
    local rootPart = model:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Filled = false
    box.Color = _G.BoxColor
    box.Visible = false

    local nameTag = CreateNameESP(model)

    local connection
    connection = RunService.RenderStepped:Connect(function()
        if model and model.Parent and rootPart then
            local rootPos = rootPart.Position
            local screenPos, onScreen = Camera:WorldToViewportPoint(rootPos)

            if onScreen then
                local size = Vector2.new(3700 / screenPos.Z, 4700 / screenPos.Z)
                local boxPosition = Vector2.new(screenPos.X - size.X / 2, screenPos.Y - size.Y / 2)

                box.Size = size
                box.Position = boxPosition
                box.Color = _G.BoxColor
                box.Visible = _G.BoxESPEnabled

                nameTag.Position = Vector2.new(screenPos.X, boxPosition.Y - 20)
                nameTag.Text = model.Name
                nameTag.Color = _G.NameColor
                nameTag.Visible = _G.NameESPEnabled
            else
                box.Visible = false
                nameTag.Visible = false
            end
        else
            box.Visible = false
            nameTag.Visible = false
        end
    end)

    model.AncestryChanged:Connect(function(_, parent)
        if not parent then
            box:Remove()
            nameTag:Remove()
            if connection then
                connection:Disconnect()
            end
        end
    end)

    return box, nameTag, connection
end

-- Apply ESP to Models
local function applyESP(model)
    if not isPlayerModel(model) then return end

    if activeESP[model] then
        activeESP[model].box:Remove()
        activeESP[model].nameTag:Remove()
        activeESP[model].updateConnection:Disconnect()
        activeESP[model] = nil
    end

    local box, nameTag, connection = DrawESPBox(model)
    activeESP[model] = { box = box, nameTag = nameTag, updateConnection = connection }
end

-- Initialize ESP for all models in Workspace
for _, model in ipairs(Workspace:GetChildren()) do
    applyESP(model)
end

-- Handle new models being added
Workspace.ChildAdded:Connect(function(model)
    applyESP(model)
end)

-- Handle models being removed
Workspace.ChildRemoved:Connect(function(model)
    if activeESP[model] then
        activeESP[model].box:Remove()
        activeESP[model].nameTag:Remove()
        activeESP[model].updateConnection:Disconnect()
        activeESP[model] = nil
    end
end)
