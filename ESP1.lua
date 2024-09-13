-- ESP Script
local espEnabled = false

local function createESPBox(player)
    if player == game.Players.LocalPlayer then return end  -- Ignore local player

    local highlight = Instance.new("BoxHandleAdornment")
    highlight.Name = "ESPBox"
    highlight.Size = player.Character and player.Character:WaitForChild("HumanoidRootPart").Size + Vector3.new(1, 2, 1)
    highlight.Adornee = player.Character and player.Character:WaitForChild("HumanoidRootPart")
    highlight.AlwaysOnTop = true
    highlight.ZIndex = 5
    highlight.Color3 = Color3.fromRGB(255, 0, 0) -- Red color for ESP
    highlight.Transparency = 0.7
    highlight.Parent = game.Workspace

    -- Remove ESP when player leaves
    player.CharacterRemoving:Connect(function()
        if highlight then
            highlight:Destroy()
        end
    end)
end

local function enableESP()
    espEnabled = true
    for _, player in pairs(game.Players:GetPlayers()) do
        if player.Character then
            createESPBox(player)
        end
    end

    game.Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            if espEnabled then
                createESPBox(player)
            end
        end)
    end)
end

local function disableESP()
    espEnabled = false
    for _, v in pairs(game.Workspace:GetChildren()) do
        if v:IsA("BoxHandleAdornment") and v.Name == "ESPBox" then
            v:Destroy()
        end
    end
end

-- Toggle ESP with this function
function toggleESP(state)
    if state then
        enableESP()
    else
        disableESP()
    end
end
