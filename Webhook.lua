repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local webhookUrl = "webhook_url"

local hasRun = false

local function formatNumber(num)
    if not num or num == 0 then return "0" end
    local formatted = tostring(num)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

local function getClientData()
    local success, clientData = pcall(function()
        local modulePath = RS:WaitForChild("Modules"):WaitForChild("ClientData")
        if modulePath and modulePath:IsA("ModuleScript") then
            return require(modulePath)
        end
        return nil
    end)
    return success and clientData or nil
end

local function SendMessageEMBED(url, embed)
    local headers = {
        ["Content-Type"] = "application/json"
    }
    local data = {
        ["embeds"] = {
            {
                ["title"] = embed.title,
                ["description"] = embed.description,
                ["color"] = embed.color,
                ["fields"] = embed.fields,
                ["footer"] = embed.footer,
                ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%S.000Z")
            }
        }
    }
    local body = HttpService:JSONEncode(data)
    local response = request({
        Url = url,
        Method = "POST",
        Headers = headers,
        Body = body
    })
end

local initialClientData = nil

local function getRewards()
    local rewards = {}
    local ok, result = pcall(function()
        local endgameUI = LocalPlayer.PlayerGui:FindFirstChild("EndGameUI")
        if not endgameUI then 
            print("[Webhook] No EndGameUI found")
            return {} 
        end
        
        local rewardsHolder = endgameUI:FindFirstChild("BG")
        if rewardsHolder then
            rewardsHolder = rewardsHolder:FindFirstChild("Container")
            if rewardsHolder then
                rewardsHolder = rewardsHolder:FindFirstChild("Rewards")
                if rewardsHolder then
                    rewardsHolder = rewardsHolder:FindFirstChild("Holder")
                    if rewardsHolder then
                        print("[Webhook] Found rewards holder, checking children...")
                        for _, item in pairs(rewardsHolder:GetChildren()) do
                            if item:IsA("GuiObject") and not item:IsA("UIListLayout") then
                                local amountLabel = item:FindFirstChild("Amount")
                                local nameLabel = item:FindFirstChild("ItemName")
                                
                                if amountLabel and nameLabel then
                                    local amountText = amountLabel.Text
                                    local itemName = nameLabel.Text
                                    
                                    print("[Webhook] Found reward UI:", itemName, amountText)
                                    
                                    local cleanAmount = string.gsub(string.gsub(amountText, "x", ""), "+", "")
                                    cleanAmount = string.gsub(cleanAmount, ",", "")
                                    local amount = tonumber(cleanAmount)
                                    
                                    if amount and itemName and itemName ~= "" then
                                        table.insert(rewards, {
                                            name = itemName,
                                            amount = amount
                                        })
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        print("[Webhook] Total rewards found:", #rewards)
        return rewards
    end)
    
    if not ok then
        warn("[Webhook] Error getting rewards:", result)
    end
    
    return ok and result or {}
end

local function getMatchResult()
    local ok, time, map, result = pcall(function()
        local endgameUI = LocalPlayer.PlayerGui:FindFirstChild("EndGameUI")
        if not endgameUI then return "00:00:00", "Wave 0", "Unknown" end
        
        local container = endgameUI:FindFirstChild("BG")
        if container then
            container = container:FindFirstChild("Container")
            if container then
                local stats = container:FindFirstChild("Stats")
                if stats then
                    local resultText = stats:FindFirstChild("Result")
                    local timeText = stats:FindFirstChild("ElapsedTime")
                    local waveText = stats:FindFirstChild("EndWave")
                    
                    local result = resultText and resultText.Text or "Unknown"
                    local time = timeText and timeText.Text or "00:00:00"
                    local wave = waveText and waveText.Text or "0"
                    
                    if result:lower():find("win") or result:lower():find("victory") then
                        result = "VICTORY"
                    elseif result:lower():find("defeat") or result:lower():find("lose") or result:lower():find("loss") then
                        result = "DEFEAT"
                    end
                    
                    return time, wave, result
                end
            end
        end
        
        return "00:00:00", "0", "Unknown"
    end)
    
    if ok then
        return time, wave, result
    else
        return "00:00:00", "0", "Unknown"
    end
end

local function getMapInfo()
    local ok, name, difficulty = pcall(function()
        local map = workspace:FindFirstChild("Map")
        if not map then return "Unknown Map", "Unknown" end
        
        local mapName = map:FindFirstChild("MapName")
        local mapDifficulty = map:FindFirstChild("MapDifficulty")
        
        local name = mapName and mapName.Value or "Unknown Map"
        local difficulty = mapDifficulty and mapDifficulty.Value or "Unknown"
        
        return name, difficulty
    end)
    
    if ok then
        return name, difficulty
    else
        return "Unknown Map", "Unknown"
    end
end

local function sendGameCompletionWebhook()
    if hasRun then return end
    hasRun = true
    
    print("[Webhook] Sending game completion data...")
    
    local clientData = getClientData()
    if not clientData then
        warn("[Webhook] Failed to get ClientData")
        return
    end
    
    local rewards = getRewards()
    local matchTime, matchWave, matchResult = getMatchResult()
    local mapName, mapDifficulty = getMapInfo()
    
    local description = ""
    description = description .. "**Username:** ||" .. LocalPlayer.Name .. "||"
    description = description .. "\n**Level:** " .. (clientData.Level or 0) .. " [" .. formatNumber(clientData.EXP or 0) .. "/" .. formatNumber(clientData.MaxEXP or 0) .. "]"
    
    local playerStatsText = ""
    playerStatsText = playerStatsText .. "<:gold:1265957290251522089> " .. formatNumber(clientData.Gold or 0)
    playerStatsText = playerStatsText .. "\n<:jewel:1217525743408648253> " .. formatNumber(clientData.Jewels or 0)
    playerStatsText = playerStatsText .. "\n<:emerald:1389165843966984192> " .. formatNumber(clientData.Emeralds or 0)
    playerStatsText = playerStatsText .. "\n<:rerollshard:1426315987019501598> " .. formatNumber(clientData.Rerolls or 0)
    playerStatsText = playerStatsText .. "\n<:candybasket:1426304615284084827> " .. formatNumber(clientData.CandyBasket or 0)
    
    local rewardsText = ""
    if #rewards > 0 then
        for _, reward in ipairs(rewards) do
            local totalAmount = 0
            
            if clientData.Items and clientData.Items[reward.name] then
                totalAmount = clientData.Items[reward.name].Amount or 0
            elseif clientData[reward.name] then
                totalAmount = clientData[reward.name]
            end
            
            rewardsText = rewardsText .. "+" .. formatNumber(reward.amount) .. " " .. reward.name .. " [ Total: " .. formatNumber(totalAmount) .. " ]\n"
        end
    else
        rewardsText = "No rewards found"
    end
    
    local unitsText = ""
    if clientData.Slots then
        local slots = {"Slot1", "Slot2", "Slot3", "Slot4", "Slot5", "Slot6"}
        for _, slotName in ipairs(slots) do
            local slot = clientData.Slots[slotName]
            if slot and slot.Value then
                local level = slot.Level or 0
                local kills = formatNumber(slot.Kills or 0)
                local unitName = slot.Value
                unitsText = unitsText .. "[ " .. level .. " ] " .. unitName .. " = " .. kills .. " ⚔️\n"
            end
        end
    end
    
    local embed = {
        title = "Anime Last Stand",
        description = description or "N/A",
        color = 0x00ff00,
        fields = {
            {
                name = "Player Stats",
                value = (playerStatsText and playerStatsText ~= "") and playerStatsText or "N/A",
                inline = true
            },
            {
                name = "Rewards",
                value = (rewardsText and rewardsText ~= "") and rewardsText or "No rewards found",
                inline = true
            },
            {
                name = "Units",
                value = (unitsText and unitsText ~= "") and unitsText or "No units",
                inline = false
            },
            {
                name = "Match Result",
                value = (matchTime or "00:00:00") .. " - Wave " .. tostring(matchWave or "0") .. "\n" .. (mapName or "Unknown Map") .. (mapDifficulty and mapDifficulty ~= "Unknown" and " [" .. mapDifficulty .. "]" or "") .. " - " .. (matchResult or "Unknown"),
                inline = false
            }
        },
        footer = {
            text = "Halloween Hook"
        }
    }
    
    SendMessageEMBED(webhookUrl, embed)
    print("[Webhook] Game completion data sent!")
end

print("[Webhook] Monitoring for EndgameUI...")

LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
    if child.Name == "EndGameUI" then
        print("[Webhook] EndGameUI detected!")
        task.wait(2)
        sendGameCompletionWebhook()
    end
end)

LocalPlayer.PlayerGui.ChildRemoved:Connect(function(child)
    if child.Name == "EndGameUI" then
        print("[Webhook] EndGameUI removed, resetting...")
        hasRun = false
    end
end)

if LocalPlayer.PlayerGui:FindFirstChild("EndGameUI") then
    print("[Webhook] EndGameUI already exists!")
    task.wait(2)
    sendGameCompletionWebhook()
end
