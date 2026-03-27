-- Executor Script for Force Rebirth System
-- This script can be executed in any executor that supports Luau/Lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Function to execute the rebirth command
local function ExecuteForceRebirth(players, speed)
    -- Load the RebirthSystem module if available
    local System = nil
    
    -- Try to find the RebirthSystem module
    local modulePath = game:GetService("ServerScriptService"):FindFirstChild("Modules")
    if modulePath and modulePath:FindFirstChild("RebirthSystem") then
        System = require(modulePath.RebirthSystem)
    else
        -- Alternative: Try to find it in other locations
        local possiblePaths = {
            game:GetService("ReplicatedStorage"):FindFirstChild("Modules"),
            game:GetService("ServerStorage"):FindFirstChild("Modules"),
            game:GetService("Workspace"):FindFirstChild("Modules")
        }
        
        for _, path in pairs(possiblePaths) do
            if path and path:FindFirstChild("RebirthSystem") then
                System = require(path.RebirthSystem)
                break
            end
        end
    end
    
    -- If System module not found, try to create a fallback
    if not System then
        warn("RebirthSystem module not found! Using fallback method.")
        System = {
            ForceRebirth = function(player)
                -- Fallback: Try common rebirth methods
                local success = false
                
                -- Method 1: Check for leaderstats and rebirth value
                local leaderstats = player:FindFirstChild("leaderstats")
                if leaderstats then
                    local rebirths = leaderstats:FindFirstChild("Rebirths")
                    local level = leaderstats:FindFirstChild("Level")
                    local prestige = leaderstats:FindFirstChild("Prestige")
                    
                    if rebirths then
                        rebirths.Value = rebirths.Value + 1
                        success = true
                    end
                    
                    if level then
                        level.Value = 0
                    end
                    
                    if prestige then
                        -- Some games use prestige as rebirth
                        prestige.Value = prestige.Value + 1
                        success = true
                    end
                end
                
                -- Method 2: Check for player data
                local playerData = player:FindFirstChild("Data")
                if playerData then
                    local rebirths = playerData:FindFirstChild("Rebirths")
                    if rebirths then
                        rebirths.Value = rebirths.Value + 1
                        success = true
                    end
                end
                
                -- Method 3: Fire remote events if available
                local remote = game:GetService("ReplicatedStorage"):FindFirstChild("RebirthRemote")
                if remote then
                    remote:FireServer()
                    success = true
                end
                
                if not success then
                    warn("Could not force rebirth for player: " .. player.Name)
                else
                    print("Successfully forced rebirth for: " .. player.Name)
                end
            end
        }
    end
    
    -- Force rebirth for all specified players
    local successCount = 0
    local failedPlayers = {}
    
    for _, player in pairs(players) do
        local success = pcall(function()
            System.ForceRebirth(player)
        end)
        
        if success then
            successCount = successCount + 1
            print("Forced rebirth for: " .. player.Name)
        else
            table.insert(failedPlayers, player.Name)
            warn("Failed to force rebirth for: " .. player.Name)
        end
    end
    
    -- Return results
    local result = {
        Success = true,
        Message = "Success",
        ProcessedPlayers = successCount,
        TotalPlayers = #players,
        FailedPlayers = failedPlayers
    }
    
    print(string.format("Force rebirth completed: %d/%d players processed", successCount, #players))
    
    if #failedPlayers > 0 then
        result.Message = "Partial success: Some players failed"
    end
    
    return result
end

-- Function to get all players or specific players
local function GetPlayers(playerNames)
    if not playerNames or #playerNames == 0 then
        -- Get all players
        return Players:GetPlayers()
    else
        -- Get specific players by name
        local playersList = {}
        for _, name in pairs(playerNames) do
            local player = Players:FindFirstChild(name)
            if player then
                table.insert(playersList, player)
            else
                warn("Player not found: " .. name)
            end
        end
        return playersList
    end
end

-- Function to create GUI for easy execution (optional)
local function CreateGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ForceRebirthGUI"
    screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 200)
    frame.Position = UDim2.new(0.5, -150, 0.5, -100)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Text = "Force Rebirth Executor"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = frame
    
    local playerList = Instance.new("TextBox")
    playerList.Size = UDim2.new(1, -20, 0, 60)
    playerList.Position = UDim2.new(0, 10, 0, 40)
    playerList.PlaceholderText = "Enter player names (comma-separated) or leave blank for all players"
    playerList.TextColor3 = Color3.fromRGB(255, 255, 255)
    playerList.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    playerList.TextXAlignment = Enum.TextXAlignment.Left
    playerList.TextYAlignment = Enum.TextYAlignment.Top
    playerList.ClearTextOnFocus = false
    playerList.Parent = frame
    
    local executeBtn = Instance.new("TextButton")
    executeBtn.Size = UDim2.new(1, -20, 0, 40)
    executeBtn.Position = UDim2.new(0, 10, 0, 110)
    executeBtn.Text = "Execute Force Rebirth"
    executeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    executeBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
    executeBtn.Parent = frame
    
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 30)
    status.Position = UDim2.new(0, 0, 0, 160)
    status.Text = "Ready"
    status.TextColor3 = Color3.fromRGB(200, 200, 200)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.Gotham
    status.TextSize = 12
    status.Parent = frame
    
    executeBtn.MouseButton1Click:Connect(function()
        local playerNames = {}
        if playerList.Text ~= "" then
            for _, name in pairs(string.split(playerList.Text, ",")) do
                table.insert(playerNames, string.gsub(name, "^%s*(.-)%s*$", "%1"))
            end
        end
        
        local players = GetPlayers(playerNames)
        if #players > 0 then
            local result = ExecuteForceRebirth(players, 1)
            status.Text = result.Message
        else
            status.Text = "No players found!"
        end
    end)
end

-- Main execution
local args = {...}

-- Check if running with arguments
if #args > 0 then
    -- Execute with provided arguments
    local playerNames = {}
    for i = 1, #args do
        table.insert(playerNames, args[i])
    end
    
    local players = GetPlayers(playerNames)
    if #players > 0 then
        local result = ExecuteForceRebirth(players, 1)
        if result.Success then
            print(result.Message)
            return result.Message
        end
    else
        warn("No players found to execute rebirth on")
        return "No players found"
    end
else
    -- Interactive mode with GUI
    print("Force Rebirth Executor Loaded!")
    print("Usage: ExecuteForceRebirth(players, speed)")
    print("Example: ExecuteForceRebirth(game.Players:GetPlayers(), 1)")
    print("Or use the GUI that appears")
    
    -- Create GUI if LocalPlayer exists
    pcall(function()
        if game:GetService("Players").LocalPlayer then
            CreateGUI()
        end
    end)
    
    -- Return the function for manual execution
    return {
        Execute = ExecuteForceRebirth,
        GetPlayers = GetPlayers,
        ForceRebirth = function(playerName)
            local player = Players:FindFirstChild(playerName)
            if player then
                return ExecuteForceRebirth({player}, 1)
            else
                warn("Player not found: " .. playerName)
                return nil
            end
        end,
        ForceAllRebirth = function()
            return ExecuteForceRebirth(Players:GetPlayers(), 1)
        end
    }
end
