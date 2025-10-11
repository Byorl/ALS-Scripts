repeat task.wait() until game:IsLoaded()

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local CONFIG_FOLDER = "ALSHalloweenEvent"
local CONFIG_FILE = "config.json"

local function getConfigPath()
    return CONFIG_FOLDER .. "/" .. CONFIG_FILE
end

local function loadConfig()
    if not isfolder(CONFIG_FOLDER) then
        makefolder(CONFIG_FOLDER)
    end
    
    local configPath = getConfigPath()
    if isfile(configPath) then
        local success, result = pcall(function()
            return HttpService:JSONDecode(readfile(configPath))
        end)
        if success then
            return result
        end
    end
    
    return {
        toggles = {},
        inputs = {},
        dropdowns = {},
        abilities = {}
    }
end

local function saveConfig(config)
    if not isfolder(CONFIG_FOLDER) then
        makefolder(CONFIG_FOLDER)
    end
    
    local configPath = getConfigPath()
    local success = pcall(function()
        writefile(configPath, HttpService:JSONEncode(config))
    end)
    return success
end

getgenv().Config = loadConfig()

getgenv().AutoEventEnabled = false
getgenv().AutoAbilitiesEnabled = false
getgenv().CardSelectionEnabled = false
getgenv().WebhookEnabled = false
getgenv().SeamlessLimiterEnabled = false
getgenv().BingoEnabled = false
getgenv().CapsuleEnabled = false
getgenv().RemoveEnemiesEnabled = false
getgenv().WebhookURL = getgenv().Config.inputs.WebhookURL or ""
getgenv().UnitAbilities = {}

local Window = Fluent:CreateWindow({
    Title = "ALS Halloween Event",
    SubTitle = "Anime Last Stand Script",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    AutoEvent = Window:AddTab({ Title = "Auto Event", Icon = "calendar" }),
    AutoAbility = Window:AddTab({ Title = "Auto Ability", Icon = "zap" }),
    CardSelection = Window:AddTab({ Title = "Card Selection", Icon = "layers" }),
    Webhook = Window:AddTab({ Title = "Webhook", Icon = "send" }),
    SeamlessFix = Window:AddTab({ Title = "Seamless Fix", Icon = "refresh-cw" }),
    Event = Window:AddTab({ Title = "Event", Icon = "grid" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "sliders" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

local CandyCards = {
    ["Weakened Resolve I"] = 13,
    ["Weakened Resolve II"] = 11,
    ["Weakened Resolve III"] = 4,
    ["Fog of War I"] = 12,
    ["Fog of War II"] = 10,
    ["Fog of War III"] = 5,
    ["Lingering Fear I"] = 6,
    ["Lingering Fear II"] = 2,
    ["Power Reversal I"] = 14,
    ["Power Reversal II"] = 9,
    ["Greedy Vampire's"] = 8,
    ["Hellish Gravity"] = 3,
    ["Deadly Striker"] = 7,
    ["Critical Denial"] = 1,
    ["Trick or Treat Coin Flip"] = 15
}

local DevilSacrifice = {
    ["Devil's Sacrifice"] = 999
}

local OtherCards = {
    ["Bullet Breaker I"] = 999,
    ["Bullet Breaker II"] = 999,
    ["Bullet Breaker III"] = 999,
    ["Hell Merchant I"] = 999,
    ["Hell Merchant II"] = 999,
    ["Hell Merchant III"] = 999,
    ["Hellish Warp I"] = 999,
    ["Hellish Warp II"] = 999,
    ["Fiery Surge I"] = 999,
    ["Fiery Surge II"] = 999,
    ["Grevious Wounds I"] = 999,
    ["Grevious Wounds II"] = 999,
    ["Scorching Hell I"] = 999,
    ["Scorching Hell II"] = 999,
    ["Fortune Flow"] = 999,
    ["Soul Link"] = 999
}

getgenv().CardPriority = {}
for name, priority in pairs(CandyCards) do getgenv().CardPriority[name] = priority end
for name, priority in pairs(DevilSacrifice) do getgenv().CardPriority[name] = priority end
for name, priority in pairs(OtherCards) do getgenv().CardPriority[name] = priority end


Tabs.AutoEvent:AddParagraph({
    Title = "Halloween 2025 Event Auto Join",
    Content = "Automatically joins and starts the Halloween event."
})

local AutoEventToggle = Tabs.AutoEvent:AddToggle("AutoEventToggle", {
    Title = "Enable Auto Event Join",
    Description = "Automatically join and start the event",
    Default = getgenv().Config.toggles.AutoEventToggle or false
})

AutoEventToggle:OnChanged(function()
    getgenv().AutoEventEnabled = Options.AutoEventToggle.Value
    getgenv().Config.toggles.AutoEventToggle = Options.AutoEventToggle.Value
    saveConfig(getgenv().Config)
    if getgenv().AutoEventEnabled then
        Fluent:Notify({
            Title = "Auto Event",
            Content = "Auto event join enabled!",
            Duration = 3
        })
    else
        Fluent:Notify({
            Title = "Auto Event",
            Content = "Auto event join disabled!",
            Duration = 3
        })
    end
end)


Tabs.AutoAbility:AddParagraph({
    Title = "Auto Ability System",
    Content = "Automatically uses tower abilities based on your equipped units."
})

local AutoAbilityToggle = Tabs.AutoAbility:AddToggle("AutoAbilityToggle", {
    Title = "Enable Auto Abilities",
    Description = "Toggle automatic ability usage",
    Default = getgenv().Config.toggles.AutoAbilityToggle or false
})

AutoAbilityToggle:OnChanged(function()
    getgenv().AutoAbilitiesEnabled = Options.AutoAbilityToggle.Value
    getgenv().Config.toggles.AutoAbilityToggle = Options.AutoAbilityToggle.Value
    saveConfig(getgenv().Config)
    if getgenv().AutoAbilitiesEnabled then
        Fluent:Notify({
            Title = "Auto Ability",
            Content = "Auto abilities enabled!",
            Duration = 3
        })
    else
        Fluent:Notify({
            Title = "Auto Ability",
            Content = "Auto abilities disabled!",
            Duration = 3
        })
    end
end)

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

local function getTowerInfo(unitName)
    local success, towerData = pcall(function()
        local towerInfoPath = RS:WaitForChild("Modules"):WaitForChild("TowerInfo")
        local towerModule = towerInfoPath:FindFirstChild(unitName)
        if towerModule and towerModule:IsA("ModuleScript") then
            return require(towerModule)
        end
        return nil
    end)
    return success and towerData or nil
end

local function getAllAbilities(unitName)
    local towerInfo = getTowerInfo(unitName)
    if not towerInfo then return {} end
    
    local abilities = {}
    
    for level = 0, 50 do
        if towerInfo[level] then
            if towerInfo[level].Ability then
                local abilityData = towerInfo[level].Ability
                local abilityName = abilityData.Name
                
                if not abilities[abilityName] then
                    abilities[abilityName] = {
                        name = abilityName,
                        cooldown = abilityData.Cd,
                        requiredLevel = level,
                        isGlobal = abilityData.IsCdGlobal or false,
                        isAttribute = abilityData.AttributeRequired or false
                    }
                end
            end
            
            if towerInfo[level].Abilities then
                for _, abilityData in pairs(towerInfo[level].Abilities) do
                    local abilityName = abilityData.Name
                    
                    if not abilities[abilityName] then
                        abilities[abilityName] = {
                            name = abilityName,
                            cooldown = abilityData.Cd,
                            requiredLevel = level,
                            isGlobal = abilityData.IsCdGlobal or false,
                            isAttribute = abilityData.AttributeRequired or false
                        }
                    end
                end
            end
        end
    end
    
    return abilities
end

local function buildAutoAbilityUI()
    local clientData = getClientData()
    if not clientData or not clientData.Slots then
        Tabs.AutoAbility:AddParagraph({
            Title = "No Units Found",
            Content = "Could not load your equipped units from ClientData."
        })
        return
    end
    
    local sortedSlots = {"Slot1", "Slot2", "Slot3", "Slot4", "Slot5", "Slot6"}
    
    for _, slotName in ipairs(sortedSlots) do
        local slotData = clientData.Slots[slotName]
        if slotData then
            local unitName = slotData.Value
            if unitName then
                local abilities = getAllAbilities(unitName)
            
            if next(abilities) then
                Tabs.AutoAbility:AddParagraph({
                    Title = unitName .. " - " .. slotName,
                    Content = "Level " .. (slotData.Level or 0)
                })
                
                if not getgenv().UnitAbilities[unitName] then
                    getgenv().UnitAbilities[unitName] = {}
                end
                
                local sortedAbilities = {}
                for abilityName, abilityData in pairs(abilities) do
                    table.insert(sortedAbilities, {name = abilityName, data = abilityData})
                end
                table.sort(sortedAbilities, function(a, b)
                    return a.data.requiredLevel < b.data.requiredLevel
                end)
                
                for _, abilityInfo in ipairs(sortedAbilities) do
                    local abilityName = abilityInfo.name
                    local abilityData = abilityInfo.data
                    
                    if not getgenv().UnitAbilities[unitName][abilityName] then
                        getgenv().UnitAbilities[unitName][abilityName] = {
                            enabled = true,
                            onlyOnBoss = false,
                            specificWave = nil,
                            requireBossInRange = false,
                            delayAfterBossSpawn = false,
                            useOnWave = false
                        }
                    end
                    
                    local abilityConfig = getgenv().UnitAbilities[unitName][abilityName]
                    local toggleKey = unitName .. "_" .. abilityName .. "_Toggle"
                    local modifiersKey = unitName .. "_" .. abilityName .. "_Modifiers"
                    local waveKey = unitName .. "_" .. abilityName .. "_Wave"
                    
                    local savedAbility = getgenv().Config.abilities[unitName] and getgenv().Config.abilities[unitName][abilityName]
                    local defaultToggle = savedAbility and savedAbility.enabled or false
                    local defaultWave = savedAbility and savedAbility.specificWave or ""
                    local defaultModifiers = {}
                    if savedAbility then
                        if savedAbility.onlyOnBoss then table.insert(defaultModifiers, "Only On Boss") end
                        if savedAbility.requireBossInRange then table.insert(defaultModifiers, "Boss In Range") end
                        if savedAbility.delayAfterBossSpawn then table.insert(defaultModifiers, "Delay After Boss Spawn") end
                        if savedAbility.useOnWave then table.insert(defaultModifiers, "On Wave") end
                    end
                    
                    if savedAbility and savedAbility.specificWave then
                        abilityConfig.specificWave = savedAbility.specificWave
                    end
                    
                    local abilityToggle = Tabs.AutoAbility:AddToggle(toggleKey, {
                        Title = abilityName,
                        Description = "Lvl " .. abilityData.requiredLevel .. " | CD: " .. abilityData.cooldown .. "s" .. (abilityData.isAttribute and " | Requires Attribute" or ""),
                        Default = defaultToggle
                    })
                    
                    abilityToggle:OnChanged(function()
                        abilityConfig.enabled = Options[toggleKey].Value
                        if not getgenv().Config.abilities[unitName] then
                            getgenv().Config.abilities[unitName] = {}
                        end
                        if not getgenv().Config.abilities[unitName][abilityName] then
                            getgenv().Config.abilities[unitName][abilityName] = {}
                        end
                        getgenv().Config.abilities[unitName][abilityName].enabled = Options[toggleKey].Value
                        saveConfig(getgenv().Config)
                    end)
                    
                    local waveInput = Tabs.AutoAbility:AddInput(waveKey, {
                        Title = "    Wave Number",
                        Default = tostring(defaultWave),
                        Placeholder = "Enter wave (only used if 'On Wave' selected)",
                        Numeric = true,
                        Finished = true,
                        Callback = function(waveValue)
                            local num = tonumber(waveValue)
                            abilityConfig.specificWave = num
                            if not getgenv().Config.abilities[unitName] then
                                getgenv().Config.abilities[unitName] = {}
                            end
                            if not getgenv().Config.abilities[unitName][abilityName] then
                                getgenv().Config.abilities[unitName][abilityName] = {}
                            end
                            getgenv().Config.abilities[unitName][abilityName].specificWave = num
                            saveConfig(getgenv().Config)
                        end
                    })
                    
                    local modifiersDropdown = Tabs.AutoAbility:AddDropdown(modifiersKey, {
                        Title = "  Conditions",
                        Description = "Optional modifiers",
                        Values = {"Only On Boss", "Boss In Range", "Delay After Boss Spawn", "On Wave"},
                        Multi = true,
                        Default = defaultModifiers
                    })
                    
                    modifiersDropdown:OnChanged(function(Value)
                        abilityConfig.onlyOnBoss = Value["Only On Boss"] or false
                        abilityConfig.requireBossInRange = Value["Boss In Range"] or false
                        abilityConfig.delayAfterBossSpawn = Value["Delay After Boss Spawn"] or false
                        abilityConfig.useOnWave = Value["On Wave"] or false
                        
                        if not getgenv().Config.abilities[unitName] then
                            getgenv().Config.abilities[unitName] = {}
                        end
                        if not getgenv().Config.abilities[unitName][abilityName] then
                            getgenv().Config.abilities[unitName][abilityName] = {}
                        end
                        getgenv().Config.abilities[unitName][abilityName].onlyOnBoss = abilityConfig.onlyOnBoss
                        getgenv().Config.abilities[unitName][abilityName].requireBossInRange = abilityConfig.requireBossInRange
                        getgenv().Config.abilities[unitName][abilityName].delayAfterBossSpawn = abilityConfig.delayAfterBossSpawn
                        getgenv().Config.abilities[unitName][abilityName].useOnWave = abilityConfig.useOnWave
                        saveConfig(getgenv().Config)
                    end)
                end
            end
        end
        end
    end
end

task.spawn(function()
    task.wait(1)
    buildAutoAbilityUI()
end)


Tabs.CardSelection:AddParagraph({
    Title = "Card Priority System",
    Content = "Set priority values for each card (lower number = higher priority).\nCards with priority 999 will be avoided."
})

local CardSelectionToggle = Tabs.CardSelection:AddToggle("CardSelectionToggle", {
    Title = "Enable Card Selection",
    Description = "Automatically select cards based on priority",
    Default = getgenv().Config.toggles.CardSelectionToggle or false
})

CardSelectionToggle:OnChanged(function()
    getgenv().CardSelectionEnabled = Options.CardSelectionToggle.Value
    getgenv().Config.toggles.CardSelectionToggle = Options.CardSelectionToggle.Value
    saveConfig(getgenv().Config)
    if getgenv().CardSelectionEnabled then
        Fluent:Notify({
            Title = "Card Selection",
            Content = "Card selection enabled!",
            Duration = 3
        })
    else
        Fluent:Notify({
            Title = "Card Selection",
            Content = "Card selection disabled!",
            Duration = 3
        })
    end
end)

Tabs.CardSelection:AddParagraph({
    Title = "━━━━━ Candy Cards ━━━━━",
    Content = "These cards give Candy Basket bonuses"
})

local candyCardNames = {}
for cardName, _ in pairs(CandyCards) do
    table.insert(candyCardNames, cardName)
end
table.sort(candyCardNames, function(a, b)
    return CandyCards[a] < CandyCards[b]
end)

for _, cardName in ipairs(candyCardNames) do
    local inputKey = "Card_" .. cardName
    local defaultValue = getgenv().Config.inputs[inputKey] or tostring(CandyCards[cardName])
    
    Tabs.CardSelection:AddInput(inputKey, {
        Title = cardName,
        Default = defaultValue,
        Placeholder = "Priority (1-999)",
        Numeric = true,
        Finished = true,
        Callback = function(Value)
            local num = tonumber(Value)
            if num then
                getgenv().CardPriority[cardName] = num
                getgenv().Config.inputs[inputKey] = Value
                saveConfig(getgenv().Config)
            end
        end
    })
end

Tabs.CardSelection:AddParagraph({
    Title = "━━━━━ Devil's Sacrifice ━━━━━",
    Content = "Disables all abilities permanently!"
})

for cardName, priority in pairs(DevilSacrifice) do
    local inputKey = "Card_" .. cardName
    local defaultValue = getgenv().Config.inputs[inputKey] or tostring(priority)
    
    Tabs.CardSelection:AddInput(inputKey, {
        Title = cardName,
        Default = defaultValue,
        Placeholder = "Priority (1-999)",
        Numeric = true,
        Finished = true,
        Callback = function(Value)
            local num = tonumber(Value)
            if num then
                getgenv().CardPriority[cardName] = num
                getgenv().Config.inputs[inputKey] = Value
                saveConfig(getgenv().Config)
            end
        end
    })
end

Tabs.CardSelection:AddParagraph({
    Title = "━━━━━ Other Cards ━━━━━",
    Content = "Non-candy bonus cards"
})

local otherCardNames = {}
for cardName, _ in pairs(OtherCards) do
    table.insert(otherCardNames, cardName)
end
table.sort(otherCardNames)

for _, cardName in ipairs(otherCardNames) do
    local inputKey = "Card_" .. cardName
    local defaultValue = getgenv().Config.inputs[inputKey] or tostring(OtherCards[cardName])
    
    Tabs.CardSelection:AddInput(inputKey, {
        Title = cardName,
        Default = defaultValue,
        Placeholder = "Priority (1-999)",
        Numeric = true,
        Finished = true,
        Callback = function(Value)
            local num = tonumber(Value)
            if num then
                getgenv().CardPriority[cardName] = num
                getgenv().Config.inputs[inputKey] = Value
                saveConfig(getgenv().Config)
            end
        end
    })
end

Tabs.Webhook:AddParagraph({
    Title = "Discord Webhook Integration",
    Content = "Send game completion stats to Discord when you finish a match."
})

local WebhookInput = Tabs.Webhook:AddInput("WebhookURL", {
    Title = "Webhook URL",
    Default = getgenv().Config.inputs.WebhookURL or "",
    Placeholder = "https://discord.com/api/webhooks/...",
    Numeric = false,
    Finished = true,
    Callback = function(Value)
        getgenv().WebhookURL = Value
        getgenv().Config.inputs.WebhookURL = Value
        saveConfig(getgenv().Config)
    end
})

local WebhookToggle = Tabs.Webhook:AddToggle("WebhookToggle", {
    Title = "Enable Webhook",
    Description = "Send match results to Discord",
    Default = getgenv().Config.toggles.WebhookToggle or false
})

WebhookToggle:OnChanged(function()
    getgenv().WebhookEnabled = Options.WebhookToggle.Value
    getgenv().Config.toggles.WebhookToggle = Options.WebhookToggle.Value
    saveConfig(getgenv().Config)
    if getgenv().WebhookEnabled then
        if getgenv().WebhookURL == "" and getgenv().Config.inputs.WebhookURL then
            getgenv().WebhookURL = getgenv().Config.inputs.WebhookURL
        end
        
        if getgenv().WebhookURL == "" or not string.match(getgenv().WebhookURL, "^https://discord%.com/api/webhooks/") then
            Fluent:Notify({
                Title = "Webhook Error",
                Content = "Please enter a valid webhook URL first!",
                Duration = 5
            })
            Options.WebhookToggle:SetValue(false)
            getgenv().Config.toggles.WebhookToggle = false
            saveConfig(getgenv().Config)
        else
            Fluent:Notify({
                Title = "Webhook",
                Content = "Webhook enabled!",
                Duration = 3
            })
        end
    else
        Fluent:Notify({
            Title = "Webhook",
            Content = "Webhook disabled!",
            Duration = 3
        })
    end
end)


Tabs.SeamlessFix:AddParagraph({
    Title = "Seamless Retry Bug Fix",
    Content = "Automatically disables seamless retry after X rounds to prevent lag and restart the match."
})

local SeamlessRoundsInput = Tabs.SeamlessFix:AddInput("SeamlessRounds", {
    Title = "Maximum Rounds",
    Default = getgenv().Config.inputs.SeamlessRounds or "4",
    Placeholder = "Number of rounds (default: 4)",
    Numeric = true,
    Finished = true,
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num > 0 then
            getgenv().MaxSeamlessRounds = num
            getgenv().Config.inputs.SeamlessRounds = Value
            saveConfig(getgenv().Config)
        else
            getgenv().MaxSeamlessRounds = 4
        end
    end
})

getgenv().MaxSeamlessRounds = tonumber(getgenv().Config.inputs.SeamlessRounds) or 4

local SeamlessToggle = Tabs.SeamlessFix:AddToggle("SeamlessToggle", {
    Title = "Enable Seamless Bug Fix",
    Description = "Limit seamless retry to configured rounds",
    Default = getgenv().Config.toggles.SeamlessToggle or false
})

SeamlessToggle:OnChanged(function()
    getgenv().SeamlessLimiterEnabled = Options.SeamlessToggle.Value
    getgenv().Config.toggles.SeamlessToggle = Options.SeamlessToggle.Value
    saveConfig(getgenv().Config)
    if getgenv().SeamlessLimiterEnabled then
        Fluent:Notify({
            Title = "Seamless Fix",
            Content = "Seamless bug fix enabled!",
            Duration = 3
        })
    else
        Fluent:Notify({
            Title = "Seamless Fix",
            Content = "Seamless bug fix disabled!",
            Duration = 3
        })
    end
end)


Tabs.Event:AddParagraph({
    Title = "Halloween 2025 Event Automation",
    Content = "Automatically manages bingo stamps, buys capsules, and opens them."
})

Tabs.Event:AddParagraph({
    Title = "━━━━━ Auto Bingo ━━━━━",
    Content = "Automatically use stamps, claim rewards, and complete boards."
})

local BingoToggle = Tabs.Event:AddToggle("BingoToggle", {
    Title = "Enable Auto Bingo",
    Description = "Automatically manage bingo stamps and rewards",
    Default = getgenv().Config.toggles.BingoToggle or false
})

BingoToggle:OnChanged(function()
    getgenv().BingoEnabled = Options.BingoToggle.Value
    getgenv().Config.toggles.BingoToggle = Options.BingoToggle.Value
    saveConfig(getgenv().Config)
    if getgenv().BingoEnabled then
        Fluent:Notify({
            Title = "Auto Bingo",
            Content = "Auto bingo enabled!",
            Duration = 3
        })
    else
        Fluent:Notify({
            Title = "Auto Bingo",
            Content = "Auto bingo disabled!",
            Duration = 3
        })
    end
end)

Tabs.Event:AddParagraph({
    Title = "━━━━━ Auto Capsules ━━━━━",
    Content = "Automatically buy and open Halloween capsules based on Candy Basket."
})

local CapsuleToggle = Tabs.Event:AddToggle("CapsuleToggle", {
    Title = "Enable Auto Capsules",
    Description = "Auto-buy and auto-open Halloween capsules",
    Default = getgenv().Config.toggles.CapsuleToggle or false
})

CapsuleToggle:OnChanged(function()
    getgenv().CapsuleEnabled = Options.CapsuleToggle.Value
    getgenv().Config.toggles.CapsuleToggle = Options.CapsuleToggle.Value
    saveConfig(getgenv().Config)
    if getgenv().CapsuleEnabled then
        Fluent:Notify({
            Title = "Auto Capsules",
            Content = "Auto capsules enabled!",
            Duration = 3
        })
    else
        Fluent:Notify({
            Title = "Auto Capsules",
            Content = "Auto capsules disabled!",
            Duration = 3
        })
    end
end)

Tabs.Event:AddParagraph({
    Title = "How It Works",
    Content = "Bingo: Uses stamps (25x), claims rewards (25x), completes board\nCapsules: Buys 100/10/1 based on candy, opens all capsules"
})

Tabs.Misc:AddParagraph({
    Title = "Miscellaneous Features",
    Content = "Additional utility features for the game."
})

local RemoveEnemiesToggle = Tabs.Misc:AddToggle("RemoveEnemiesToggle", {
    Title = "Remove Enemies/SpawnedUnits",
    Description = "Deletes all non-boss enemies and spawned units",
    Default = getgenv().Config.toggles.RemoveEnemiesToggle or false
})

RemoveEnemiesToggle:OnChanged(function()
    getgenv().RemoveEnemiesEnabled = Options.RemoveEnemiesToggle.Value
    getgenv().Config.toggles.RemoveEnemiesToggle = Options.RemoveEnemiesToggle.Value
    saveConfig(getgenv().Config)
    if getgenv().RemoveEnemiesEnabled then
        Fluent:Notify({
            Title = "Remove Enemies/SpawnedUnits",
            Content = "Remove enemies and spawned units enabled!",
            Duration = 3
        })
    else
        Fluent:Notify({
            Title = "Remove Enemies/SpawnedUnits",
            Content = "Remove enemies and spawned units disabled!",
            Duration = 3
        })
    end
end)


SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("ALSHalloweenEvent")
SaveManager:SetFolder("ALSHalloweenEvent/configs")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
    Title = "ALS Halloween Event",
    Content = "Script loaded successfully!",
    Duration = 5
})

SaveManager:LoadAutoloadConfig()

task.spawn(function()
    while true do
        task.wait(0.1)
        
        if getgenv().RemoveEnemiesEnabled then
            local enemies = workspace:FindFirstChild("Enemies")
            if enemies then
                for _, enemy in pairs(enemies:GetChildren()) do
                    if enemy:IsA("Model") and enemy.Name ~= "Boss" then
                        pcall(function()
                            enemy:Destroy()
                        end)
                    end
                end
            end
            local spawnedunits = workspace:FindFirstChild("SpawnedUnits")
            if spawnedunits then
                for _, spawnedunit in pairs(spawnedunits:GetChildren()) do
                    if spawnedunit:IsA("Model") then
                        pcall(function()
                            spawnedunit:Destroy()
                        end)
                    end
                end
            end
        end
        
        if Fluent.Unloaded then break end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        
        if getgenv().AutoEventEnabled then
            local eventsFolder = RS:FindFirstChild("Events")
            if eventsFolder then
                local halloweenFolder = eventsFolder:FindFirstChild("Hallowen2025")
                if halloweenFolder then
                    local enterEvent = halloweenFolder:FindFirstChild("Enter")
                    local startEvent = halloweenFolder:FindFirstChild("Start")
                    
                    if enterEvent and startEvent then
                        pcall(function()
                            enterEvent:FireServer()
                            task.wait(0.2)
                            startEvent:FireServer()
                        end)
                        print("[Auto Event] Joined and started Halloween event")
                    end
                end
            end
        end
        
        if Fluent.Unloaded then break end
    end
end)

task.spawn(function()
    local GAME_SPEED = 3
    local Towers = workspace.Towers
    local bossSpawnTime = nil
    local bossInRangeTracker = {}
    local abilityCooldowns = {}
    local towerInfoCache = {}
    local generalBossSpawnTime = nil
    local lastWave = 0
    
    local function resetRoundTrackers()
        bossSpawnTime = nil
        bossInRangeTracker = {}
        generalBossSpawnTime = nil
    end
    
    local function getTowerInfoCached(towerName)
        if towerInfoCache[towerName] then return towerInfoCache[towerName] end
        local towerData = getTowerInfo(towerName)
        if towerData then
            towerInfoCache[towerName] = towerData
        end
        return towerData
    end
    
    local function getAbilityData(towerName, abilityName)
        local towerInfo = getTowerInfoCached(towerName)
        if not towerInfo then return nil end
        for level = 0, 50 do
            if towerInfo[level] then
                if towerInfo[level].Ability then
                    local abilityData = towerInfo[level].Ability
                    if abilityData.Name == abilityName then
                        return {
                            cooldown = abilityData.Cd,
                            requiredLevel = level,
                            isGlobal = abilityData.IsCdGlobal
                        }
                    end
                end
                if towerInfo[level].Abilities then
                    for _, abilityData in pairs(towerInfo[level].Abilities) do
                        if abilityData.Name == abilityName then
                            return {
                                cooldown = abilityData.Cd,
                                requiredLevel = level,
                                isGlobal = abilityData.IsCdGlobal
                            }
                        end
                    end
                end
            end
        end
        return nil
    end
    
    local function getCurrentWave()
        local ok, result = pcall(function()
            local gui = LocalPlayer.PlayerGui:FindFirstChild("Top")
            if not gui then return 0 end
            local frame = gui:FindFirstChild("Frame")
            if not frame then return 0 end
            frame = frame:FindFirstChild("Frame")
            if not frame then return 0 end
            frame = frame:FindFirstChild("Frame")
            if not frame then return 0 end
            frame = frame:FindFirstChild("Frame")
            if not frame then return 0 end
            local button = frame:FindFirstChild("TextButton")
            if not button then return 0 end
            local children = button:GetChildren()
            if #children < 3 then return 0 end
            local text = children[3].Text
            return tonumber(text) or 0
        end)
        return ok and result or 0
    end
    
    local function getTowerInfoName(tower)
        if not tower then return nil end
        local candidates = {
            tower:GetAttribute("TowerType"),
            tower:GetAttribute("Type"),
            tower:GetAttribute("TowerName"),
            tower:GetAttribute("BaseTower"),
            tower:FindFirstChild("TowerType") and tower.TowerType:IsA("ValueBase") and tower.TowerType.Value,
            tower:FindFirstChild("Type") and tower.Type:IsA("ValueBase") and tower.Type.Value,
            tower:FindFirstChild("TowerName") and tower.TowerName:IsA("ValueBase") and tower.TowerName.Value,
            tower.Name
        }
        for _, candidate in ipairs(candidates) do
            if candidate and type(candidate) == "string" and candidate ~= "" then
                return candidate
            end
        end
        return tower.Name
    end
    
    local function getTower(name)
        return Towers:FindFirstChild(name)
    end
    
    local function getUpgradeLevel(tower)
        if not tower then return 0 end
        local upgradeVal = tower:FindFirstChild("Upgrade")
        if upgradeVal and upgradeVal:IsA("ValueBase") then
            return upgradeVal.Value or 0
        end
        return 0
    end
    
    local function useAbility(tower, abilityName)
        if tower then
            pcall(function()
                local Event = RS.Remotes.Ability
                Event:InvokeServer(tower, abilityName)
            end)
        end
    end
    
    local function isOnCooldown(towerName, abilityName)
        local abilityData = getAbilityData(towerName, abilityName)
        if not abilityData or not abilityData.cooldown then return false end
        local key = towerName .. "_" .. abilityName
        local lastUsed = abilityCooldowns[key]
        if not lastUsed then return false end
        local adjustedCooldown = abilityData.cooldown / GAME_SPEED
        local elapsed = tick() - lastUsed
        return elapsed < adjustedCooldown
    end
    
    local function setAbilityUsed(towerName, abilityName)
        local key = towerName .. "_" .. abilityName
        abilityCooldowns[key] = tick()
    end
    
    local function hasAbilityBeenUnlocked(towerName, abilityName, towerLevel)
        local abilityData = getAbilityData(towerName, abilityName)
        if not abilityData then return false end
        return towerLevel >= abilityData.requiredLevel
    end
    
    local function bossExists()
        local ok, result = pcall(function()
            local enemies = workspace:FindFirstChild("Enemies")
            if not enemies then return false end
            return enemies:FindFirstChild("Boss") ~= nil
        end)
        return ok and result
    end
    
    local function bossReadyForAbilities()
        if bossExists() then
            if not generalBossSpawnTime then
                generalBossSpawnTime = tick()
            end
            local elapsed = tick() - generalBossSpawnTime
            return elapsed >= 1
        else
            generalBossSpawnTime = nil
            return false
        end
    end
    
    local function checkBossSpawnTime()
        if bossExists() then
            if not bossSpawnTime then
                bossSpawnTime = tick()
            end
            local elapsed = tick() - bossSpawnTime
            return elapsed >= 16
        else
            bossSpawnTime = nil
            return false
        end
    end
    
    local function getBossPosition()
        local ok, result = pcall(function()
            local enemies = workspace:FindFirstChild("Enemies")
            if not enemies then return nil end
            local boss = enemies:FindFirstChild("Boss")
            if not boss then return nil end
            local hrp = boss:FindFirstChild("HumanoidRootPart")
            if hrp then return hrp.Position end
            return nil
        end)
        return ok and result or nil
    end
    
    local function getTowerPosition(tower)
        if not tower then return nil end
        local ok, result = pcall(function()
            local hrp = tower:FindFirstChild("HumanoidRootPart")
            if hrp then return hrp.Position end
            return nil
        end)
        return ok and result or nil
    end
    
    local function getTowerRange(tower)
        if not tower then return 0 end
        local ok, result = pcall(function()
            local stats = tower:FindFirstChild("Stats")
            if not stats then return 0 end
            local range = stats:FindFirstChild("Range")
            if not range then return 0 end
            return range.Value or 0
        end)
        return ok and result or 0
    end
    
    local function isBossInRange(tower)
        local bossPos = getBossPosition()
        local towerPos = getTowerPosition(tower)
        if not bossPos or not towerPos then return false end
        local range = getTowerRange(tower)
        if range <= 0 then return false end
        local distance = (bossPos - towerPos).Magnitude
        return distance <= range
    end
    
    local function checkBossInRangeForDuration(tower, requiredDuration)
        if not tower then return false end
        local towerName = tower.Name
        local currentTime = tick()
        if isBossInRange(tower) then
            if requiredDuration == 0 then return true end
            if not bossInRangeTracker[towerName] then
                bossInRangeTracker[towerName] = currentTime
                return false
            else
                local timeInRange = currentTime - bossInRangeTracker[towerName]
                if timeInRange >= requiredDuration then return true end
            end
        else
            bossInRangeTracker[towerName] = nil
        end
        return false
    end
    
    while true do
        wait(0.5)
        
        if getgenv().AutoAbilitiesEnabled then
            local currentWave = getCurrentWave()
            local hasBoss = bossExists()
            
            if currentWave < lastWave then
                resetRoundTrackers()
                print("[Auto Ability] Round reset detected (Wave " .. currentWave .. " < " .. lastWave .. ")")
            end
            lastWave = currentWave
            
            for unitName, abilitiesConfig in pairs(getgenv().UnitAbilities) do
                local tower = getTower(unitName)
                
                if tower then
                    local towerInfoName = getTowerInfoName(tower)
                    local towerLevel = getUpgradeLevel(tower)
                    
                    for abilityName, abilityConfig in pairs(abilitiesConfig) do
                        if abilityConfig.enabled then
                            local shouldUse = true
                            local skipReason = nil
                            
                            if not hasAbilityBeenUnlocked(towerInfoName, abilityName, towerLevel) then
                                shouldUse = false
                                skipReason = "Not unlocked"
                            end
                            
                            if shouldUse and isOnCooldown(towerInfoName, abilityName) then
                                shouldUse = false
                                skipReason = "On cooldown"
                            end
                            
                            if shouldUse then
                                if abilityConfig.onlyOnBoss then
                                    if not hasBoss then
                                        shouldUse = false
                                        skipReason = "Boss required"
                                    elseif not bossReadyForAbilities() then
                                        shouldUse = false
                                        skipReason = "Boss not ready"
                                    end
                                end
                                
                                if shouldUse and abilityConfig.useOnWave and abilityConfig.specificWave then
                                    if currentWave ~= abilityConfig.specificWave then
                                        shouldUse = false
                                        skipReason = "Wrong wave (waiting for wave " .. abilityConfig.specificWave .. ")"
                                    end
                                end
                                
                                if shouldUse and abilityConfig.requireBossInRange then
                                    if not hasBoss then
                                        shouldUse = false
                                        skipReason = "No boss for range check"
                                    elseif not checkBossInRangeForDuration(tower, 0) then
                                        shouldUse = false
                                        skipReason = "Boss not in range"
                                    end
                                end
                                
                                if shouldUse and abilityConfig.delayAfterBossSpawn then
                                    if not hasBoss then
                                        shouldUse = false
                                        skipReason = "No boss for delay check"
                                    elseif not checkBossSpawnTime() then
                                        shouldUse = false
                                        skipReason = "Boss spawn delay not met"
                                    end
                                end
                            end
                            
                            if shouldUse then
                                useAbility(tower, abilityName)
                                setAbilityUsed(towerInfoName, abilityName)
                                print("[Auto Ability] ✓ Used " .. abilityName .. " on " .. unitName)
                            end
                        end
                    end
                end
            end
        end
        
        if Fluent.Unloaded then break end
    end
end)

task.spawn(function()
    local function getAvailableCards()
        local playerGui = LocalPlayer.PlayerGui
        local prompt = playerGui:FindFirstChild("Prompt")
        if not prompt then return nil end
        local frame = prompt:FindFirstChild("Frame")
        if not frame or not frame:FindFirstChild("Frame") then return nil end
        local cards = {}
        local cardButtons = {}
        for _, descendant in pairs(frame:GetDescendants()) do
            if descendant:IsA("TextLabel") and descendant.Parent and descendant.Parent:IsA("Frame") then
                local text = descendant.Text
                if getgenv().CardPriority[text] then
                    local button = descendant.Parent.Parent
                    if button:IsA("GuiButton") or button:IsA("TextButton") or button:IsA("ImageButton") then
                        table.insert(cardButtons, {text = text, button = button})
                    end
                end
            end
        end
        table.sort(cardButtons, function(a, b)
            return a.button.AbsolutePosition.X < b.button.AbsolutePosition.X
        end)
        for i, cardData in ipairs(cardButtons) do
            cards[i] = {name = cardData.text, button = cardData.button}
        end
        return #cards > 0 and cards or nil
    end
    
    local function findBestCard(availableCards)
        local bestIndex = 1
        local bestPriority = math.huge
        for cardIndex = 1, #availableCards do
            local cardData = availableCards[cardIndex]
            local cardName = cardData.name
            local priority = getgenv().CardPriority[cardName] or 999
            if priority < bestPriority then
                bestPriority = priority
                bestIndex = cardIndex
            end
        end
        return bestIndex, availableCards[bestIndex], bestPriority
    end
    
    local function pressConfirmButton()
        local ok, confirmButton = pcall(function()
            local prompt = LocalPlayer.PlayerGui:FindFirstChild("Prompt")
            if not prompt then return nil end
            local frame = prompt:FindFirstChild("Frame")
            if not frame then return nil end
            local innerFrame = frame:FindFirstChild("Frame")
            if not innerFrame then return nil end
            local children = innerFrame:GetChildren()
            if #children < 5 then return nil end
            local button = children[5]:FindFirstChild("TextButton")
            if not button then return nil end
            local label = button:FindFirstChild("TextLabel")
            if label and label.Text == "Confirm" then
                return button
            end
            return nil
        end)
        if ok and confirmButton then
            local events = {"Activated", "MouseButton1Click", "MouseButton1Down", "MouseButton1Up"}
            for _, eventName in ipairs(events) do
                pcall(function()
                    for _, conn in ipairs(getconnections(confirmButton[eventName])) do
                        conn:Fire()
                    end
                end)
            end
            return true
        end
        return false
    end
    
    local function selectCard()
        if not getgenv().CardSelectionEnabled then return false end
        local availableCards = getAvailableCards()
        if not availableCards then return false end
        local bestCardIndex, bestCardData, bestPriority = findBestCard(availableCards)
        local buttonToClick = bestCardData.button
        local events = {"Activated", "MouseButton1Click", "MouseButton1Down", "MouseButton1Up"}
        for _, eventName in ipairs(events) do
            pcall(function()
                for _, conn in ipairs(getconnections(buttonToClick[eventName])) do
                    conn:Fire()
                end
            end)
        end
        wait(0.2)
        pressConfirmButton()
        return true
    end
    
    while true do
        wait(1)
        if getgenv().CardSelectionEnabled then
            selectCard()
        end
        if Fluent.Unloaded then break end
    end
end)

task.spawn(function()
    local hasRun = false
    local isProcessing = false
    
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
    
    local function getRewards()
        local rewards = {}
        local ok, result = pcall(function()
            local endgameUI = LocalPlayer.PlayerGui:FindFirstChild("EndGameUI")
            if not endgameUI then return {} end
            local rewardsHolder = endgameUI:FindFirstChild("BG")
            if rewardsHolder then
                rewardsHolder = rewardsHolder:FindFirstChild("Container")
                if rewardsHolder then
                    rewardsHolder = rewardsHolder:FindFirstChild("Rewards")
                    if rewardsHolder then
                        rewardsHolder = rewardsHolder:FindFirstChild("Holder")
                        if rewardsHolder then
                            for _, item in pairs(rewardsHolder:GetChildren()) do
                                if item:IsA("GuiObject") and not item:IsA("UIListLayout") then
                                    local amountLabel = item:FindFirstChild("Amount")
                                    local nameLabel = item:FindFirstChild("ItemName")
                                    if amountLabel and nameLabel then
                                        local amountText = amountLabel.Text
                                        local itemName = nameLabel.Text
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
            return rewards
        end)
        return ok and result or {}
    end
    
    local function getMatchResult()
        local ok, time, wave, result = pcall(function()
            local endgameUI = LocalPlayer.PlayerGui:FindFirstChild("EndGameUI")
            if not endgameUI then return "00:00:00", "0", "Unknown" end
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
        if not getgenv().WebhookEnabled then return end
        if hasRun or isProcessing then return end
        
        isProcessing = true
        hasRun = true
        
        task.wait(0.1)
        
        local clientData = getClientData()
        if not clientData then 
            isProcessing = false
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
        
        local bingoStamps = 0
        if clientData.ItemData and clientData.ItemData.HallowenBingoStamp then
            bingoStamps = clientData.ItemData.HallowenBingoStamp.Amount or 0
        end
        playerStatsText = playerStatsText .. "\n<:bingostamp:1426362482141954068> " .. formatNumber(bingoStamps)
        
        local rewardsText = ""
        if #rewards > 0 then
            for _, reward in ipairs(rewards) do
                local totalAmount = 0
                if clientData.Items and clientData.Items[reward.name] then
                    totalAmount = clientData.Items[reward.name].Amount or 0
                elseif clientData[reward.name] then
                    totalAmount = clientData[reward.name]
                elseif reward.name == "HallowenBingoStamp" or reward.name:find("Bingo Stamp") then
                    if clientData.ItemData and clientData.ItemData.HallowenBingoStamp then
                        totalAmount = clientData.ItemData.HallowenBingoStamp.Amount or 0
                    end
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
        
        SendMessageEMBED(getgenv().WebhookURL, embed)
        
        isProcessing = false
    end
    
    LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
        if child.Name == "EndGameUI" and getgenv().WebhookEnabled then
            sendGameCompletionWebhook()
        end
    end)
    
    LocalPlayer.PlayerGui.ChildRemoved:Connect(function(child)
        if child.Name == "EndGameUI" then
            task.wait(1)
            hasRun = false
            isProcessing = false
        end
    end)
end)

task.spawn(function()
    local endgameCount = 0
    local seamlessRetry = nil
    
    local function checkSeamlessRetry()
        local ok, result = pcall(function()
            local settingsGui = LocalPlayer.PlayerGui:WaitForChild("Settings", 10)
            if settingsGui then
                local seamless = settingsGui:FindFirstChild("SeamlessRetry")
                if seamless and seamless:IsA("ValueBase") then
                    return seamless
                end
            end
            return nil
        end)
        return ok and result or nil
    end
    
    task.spawn(function()
        task.wait(2)
        seamlessRetry = checkSeamlessRetry()
        if seamlessRetry and seamlessRetry.Value == false then
            pcall(function()
                RS.Remotes.SetSettings:InvokeServer("SeamlessRetry", true)
                print("[Seamless Fix] Enabled seamless retry on startup")
            end)
        end
    end)
    
    LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
        if not getgenv().SeamlessLimiterEnabled then return end
        
        if child.Name == "EndGameUI" then
            endgameCount = endgameCount + 1
            
            local maxRounds = getgenv().MaxSeamlessRounds or 4
            
            if endgameCount >= maxRounds then
                if not seamlessRetry then
                    seamlessRetry = checkSeamlessRetry()
                end
                
                if seamlessRetry then
                    local currentValue = seamlessRetry.Value
                    
                    if currentValue == true then
                        task.wait(2)
                        
                        pcall(function()
                            RS.Remotes.SetSettings:InvokeServer("SeamlessRetry")
                        end)
                        
                        task.wait(0.5)
                        
                        pcall(function()
                            RS.Remotes.RestartMatch:InvokeServer()
                        end)
                        
                        endgameCount = 0
                    end
                end
            end
        end
    end)
    
    LocalPlayer.PlayerGui.ChildRemoved:Connect(function(child)
        if child.Name == "EndGameUI" then
            local maxRounds = getgenv().MaxSeamlessRounds or 4
            if endgameCount < maxRounds then
                endgameCount = 0
            end
        end
    end)
end)

if game.PlaceId == 12900046592 then
    task.spawn(function()
        task.wait(2)
        
        local BingoEvents = RS:WaitForChild("Events"):WaitForChild("Bingo")
        local UseStampEvent = BingoEvents:FindFirstChild("UseStamp")
        local ClaimRewardEvent = BingoEvents:FindFirstChild("ClaimReward")
        local CompleteBoardEvent = BingoEvents:FindFirstChild("CompleteBoard")
        
        print("[Auto Bingo] Bingo automation loaded!")
        
        while true do
            task.wait(1)
            
            if getgenv().BingoEnabled then
                if UseStampEvent then
                    print("[Auto Bingo] Using 25 stamps...")
                    for i = 1, 25 do
                        pcall(function()
                            UseStampEvent:FireServer()
                        end)
                        task.wait(0.1)
                    end
                    task.wait(0.2)
                end
                
                if ClaimRewardEvent then
                    print("[Auto Bingo] Claiming 25 rewards...")
                    for i = 1, 25 do
                        pcall(function()
                            ClaimRewardEvent:InvokeServer(i)
                        end)
                        task.wait(0.1)
                    end
                    task.wait(0.2)
                end
                

                if CompleteBoardEvent then
                    print("[Auto Bingo] Completing board...")
                    pcall(function()
                        CompleteBoardEvent:InvokeServer()
                    end)
                    task.wait(0.1)
                end

                print("[Auto Bingo] Cycle complete, waiting 0 seconds...")
                task.wait(0)
            end
            
            if Fluent.Unloaded then break end
        end
    end)
    
    task.spawn(function()
        task.wait(2)
        
        local PurchaseEvent = RS:WaitForChild("Events"):WaitForChild("Hallowen2025"):WaitForChild("Purchase")
        local OpenCapsuleEvent = RS:WaitForChild("Remotes"):WaitForChild("OpenCapsule")
        
        print("[Auto Capsules] Capsule automation loaded!")
        
        while true do
            task.wait(2)
            
            if getgenv().CapsuleEnabled then
                local clientData = getClientData()
                if clientData then
                    local candyBasket = clientData.CandyBasket or 0
                    local capsuleAmount = 0
                    
                    if clientData.ItemData and clientData.ItemData.HalloweenCapsule2025 then
                        capsuleAmount = clientData.ItemData.HalloweenCapsule2025.Amount or 0
                    end
                    
                    if candyBasket >= 100000 then
                        print("[Auto Capsules] Buying 100 capsules (" .. candyBasket .. " candy)")
                        pcall(function()
                            PurchaseEvent:InvokeServer(1, 100)
                        end)
                        task.wait(1)
                    elseif candyBasket >= 10000 then
                        print("[Auto Capsules] Buying 10 capsules (" .. candyBasket .. " candy)")
                        pcall(function()
                            PurchaseEvent:InvokeServer(1, 10)
                        end)
                        task.wait(1)
                    elseif candyBasket >= 1000 then
                        print("[Auto Capsules] Buying 1 capsule (" .. candyBasket .. " candy)")
                        pcall(function()
                            PurchaseEvent:InvokeServer(1, 1)
                        end)
                        task.wait(1)
                    end
                    
                    task.wait(0.5)
                    clientData = getClientData()
                    if clientData and clientData.ItemData and clientData.ItemData.HalloweenCapsule2025 then
                        capsuleAmount = clientData.ItemData.HalloweenCapsule2025.Amount or 0
                    end
                    
                    if capsuleAmount > 0 then
                        print("[Auto Capsules] Opening " .. capsuleAmount .. " capsules")
                        pcall(function()
                            OpenCapsuleEvent:FireServer("HalloweenCapsule2025", capsuleAmount)
                        end)
                        task.wait(1)
                    end
                end
            end
            
            if Fluent.Unloaded then break end
        end
    end)
end
