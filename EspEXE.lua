local espEnabled = false
local espDistance = 1000
local espColor = Color3.fromRGB(128, 187, 219)
local defaultColor = Color3.fromRGB(0, 255, 255)
local nameESPEnabled = true  -- Set to true to enable name ESP

-- Function to create ESP for a player
local function createESP(player)
    if not espEnabled then return end

    -- Create the box for player ESP
    local espBox = Drawing.new("Square")
    espBox.Thickness = 2
    espBox.Transparency = 1
    espBox.Color = espColor

    -- Create the text for player name ESP
    local nameText = Drawing.new("Text")
    nameText.Size = 14
    nameText.Color = defaultColor
    nameText.Center = true
    nameText.Outline = true
    nameText.OutlineColor = Color3.new(0, 0, 0) -- Black outline for better visibility

    -- Create the text for player health ESP
    local healthText = Drawing.new("Text")
    healthText.Size = 14
    healthText.Color = defaultColor
    healthText.Center = true
    healthText.Outline = true
    healthText.OutlineColor = Color3.new(0, 0, 0) -- Black outline for better visibility

    -- Function to update ESP visuals
    local function updateESP()
        if espEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local rootPart = player.Character.HumanoidRootPart
            local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(rootPart.Position)

            if onScreen then
                -- Update the ESP box
                espBox.Size = Vector2.new(50, 50)
                espBox.Position = Vector2.new(screenPos.X - 25, screenPos.Y - 25)
                espBox.Visible = true

                -- Update the player name text
                nameText.Position = Vector2.new(screenPos.X, screenPos.Y - 30) -- Above the box
                nameText.Text = player.Name
                nameText.Visible = nameESPEnabled

                -- Update the player health text
                if player.Character:FindFirstChild("Humanoid") then
                    local health = player.Character.Humanoid.Health
                    local maxHealth = player.Character.Humanoid.MaxHealth
                    healthText.Position = Vector2.new(screenPos.X, screenPos.Y - 15) -- Above the box
                    healthText.Text = "Health: " .. math.floor(health) .. "/" .. math.floor(maxHealth)
                    healthText.Visible = true
                else
                    healthText.Visible = false
                end
            else
                espBox.Visible = false
                nameText.Visible = false
                healthText.Visible = false
            end
        else
            espBox.Visible = false
            nameText.Visible = false
            healthText.Visible = false
        end
    end

    -- Connect the update function to RenderStepped
    game:GetService("RunService").RenderStepped:Connect(updateESP)

    -- Return the ESP components for cleanup if needed
    return {
        espBox = espBox,
        nameText = nameText,
        healthText = healthText
    }
end

-- Function to toggle ESP on or off
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
        -- Remove all drawings if ESP is disabled
        for _, drawing in pairs(Drawing.GetAll()) do
            drawing:Remove()
        end
    end
end

return {
    toggleESP = toggleESP
}
