-- esp.lua (Place this on GitHub)

local esp_settings = {
    textsize = 8,
    colour = {255, 255, 255}
}

local espObjects = {} -- Track created ESP objects

local function createESP(player)
    if not player.Character or not player.Character:FindFirstChild("Head") then return end

    local gui = Instance.new("BillboardGui")
    local esp = Instance.new("TextLabel", gui)

    gui.Name = "CrackedESP"
    gui.ResetOnSpawn = false
    gui.AlwaysOnTop = true
    gui.LightInfluence = 0
    gui.Size = UDim2.new(1.75, 0, 1.75, 0)

    esp.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    esp.Text = "{" .. player.Name .. "}"
    esp.Size = UDim2.new(0.0001, 0.00001, 0.0001, 0.00001)
    esp.BorderSizePixel = 0
    esp.Font = Enum.Font.GothamSemibold
    esp.TextSize = esp_settings.textsize
    esp.TextColor3 = Color3.fromRGB(esp_settings.colour[1], esp_settings.colour[2], esp_settings.colour[3])

    gui.Parent = player.Character.Head
    espObjects[player.UserId] = gui
end

local function removeESP(player)
    if espObjects[player.UserId] then
        espObjects[player.UserId]:Destroy()
        espObjects[player.UserId] = nil
    end
end

local function updateESP()
    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        if player ~= game:GetService("Players").LocalPlayer then
            if not player.Character.Head:FindFirstChild("CrackedESP") then
                createESP(player)
            end
        end
    end
end

local espEnabled = false

local function toggleESP(state)
    espEnabled = state
    if espEnabled then
        updateESP()
        game:GetService("RunService").RenderStepped:Connect(updateESP)
    else
        for _, player in pairs(game:GetService("Players"):GetPlayers()) do
            removeESP(player)
        end
        game:GetService("RunService").RenderStepped:Disconnect(updateESP)
    end
end

return {
    toggleESP = toggleESP
}
