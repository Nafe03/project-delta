local espEnabled = false
local espDistance = 1000
local espColor = Color3.fromRGB(128, 187, 219)
local defaultColor = Color3.fromRGB(0, 255, 255)
local nameESPEnabled = false

local function createESP(player)
    if not espEnabled then return end

    local espBox = Drawing.new("Square")
    espBox.Thickness = 2
    espBox.Transparency = 1
    espBox.Color = espColor

    local function updateESP()
        if espEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local rootPart = player.Character.HumanoidRootPart
            local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(rootPart.Position)
            if onScreen then
                espBox.Size = Vector2.new(50, 50)
                espBox.Position = Vector2.new(screenPos.X - 25, screenPos.Y - 25)
                espBox.Visible = true
            else
                espBox.Visible = false
            end
        else
            espBox.Visible = false
        end
    end

    game:GetService("RunService").RenderStepped:Connect(updateESP)
end

local function toggleESP(state)
    espEnabled = state
    if espEnabled then
        for _, player in pairs(game:GetService("Players"):GetPlayers()) do
            if player ~= game.Players.LocalPlayer then
                createESP(player)
            end
        end
        game:GetService("Players").PlayerAdded:Connect(function(player)
            if player ~= game.Players.LocalPlayer then
                createESP(player)
            end
        end)
    else
        for _, drawing in pairs(Drawing.GetAll()) do
            drawing:Remove()
        end
    end
end

return {
    toggleESP = toggleESP
}
