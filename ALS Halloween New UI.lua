repeat task.wait() until game:IsLoaded()

local MacLib = loadstring(game:HttpGet("https://github.com/biggaboy212/Maclib/releases/latest/download/maclib.txt"))()

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local LOBBY_PLACEID = 12886143095
local isInLobby = game.PlaceId == LOBBY_PLACEID

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
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(configPath))
        end)
        if ok and type(data) == "table" then
            data.toggles = data.toggles or {}
            data.inputs = data.inputs or {}
            data.dropdowns = data.dropdowns or {}
            data.abilities = data.abilities or {}
            return data
        end
    end
    return { toggles = {}, inputs = {}, dropdowns = {}, abilities = {} }
end

local function saveConfig(config)
    if not isfolder(CONFIG_FOLDER) then
        makefolder(CONFIG_FOLDER)
    end
    local ok = pcall(function()
        writefile(getConfigPath(), HttpService:JSONEncode(config))
    end)
    return ok
end

getgenv().Config = loadConfig()

getgenv().AutoEventEnabled = false
getgenv().AutoAbilitiesEnabled = false
getgenv().CardSelectionEnabled = false
getgenv().BossRushEnabled = false
getgenv().WebhookEnabled = false
getgenv().SeamlessLimiterEnabled = false
getgenv().BingoEnabled = false
getgenv().CapsuleEnabled = false
getgenv().RemoveEnemiesEnabled = false
getgenv().AntiAFKEnabled = false
getgenv().BlackScreenEnabled = false
getgenv().FPSBoostEnabled = false
getgenv().WebhookURL = getgenv().Config.inputs.WebhookURL or ""
getgenv().UnitAbilities = {}

local Window = MacLib:Window({
    Title = "ALS Halloween Event",
    Subtitle = "Anime Last Stand Script",
    Size = UDim2.fromOffset(868, 650),
    DragStyle = 1,
    DisabledWindowControls = {},
    ShowUserInfo = true,
    Keybind = Enum.KeyCode.LeftControl,
    AcrylicBlur = true,
})

local function notify(title, desc, time)
    Window:Notify({ Title = title or "ALS", Description = desc or "", Lifetime = time or 3 })
end

local ToggleGui = Instance.new("ScreenGui")
ToggleGui.Name = "ALS_MacLib_Toggle"
ToggleGui.ResetOnSpawn = false
ToggleGui.IgnoreGuiInset = true
ToggleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ToggleGui.Parent = game:GetService("CoreGui")

local ToggleButton = Instance.new("ImageButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0, 72, 0, 72)
ToggleButton.Position = UDim2.new(0, 24, 0, 24)
ToggleButton.AnchorPoint = Vector2.new(0, 0)
ToggleButton.BackgroundTransparency = 1
ToggleButton.Image = "rbxassetid://72399447876912"
ToggleButton.Active = true
ToggleButton.Draggable = true
ToggleButton.Parent = ToggleGui

local uiVisible = true
local TOGGLE_KEY = Window.Settings.Keybind or Enum.KeyCode.LeftControl
local VIM = game:GetService("VirtualInputManager")

local function toggleUI()
    local ok = pcall(function()
        if Window.Toggle then Window:Toggle() end
    end)
    if not ok or not Window.Toggle then
        VIM:SendKeyEvent(true, TOGGLE_KEY, false, game)
        task.wait(0.05)
        VIM:SendKeyEvent(false, TOGGLE_KEY, false, game)
    end
    uiVisible = not uiVisible
end

ToggleButton.MouseButton1Click:Connect(toggleUI)

local tabGroups = { Main = Window:TabGroup() }

local Tabs = {
    AutoEvent = tabGroups.Main:Tab({ Name = "Auto Event", Image = "rbxassetid://18821914323" }),
    AutoAbility = tabGroups.Main:Tab({ Name = "Auto Ability", Image = "rbxassetid://18821914323" }),
    CardSelection = tabGroups.Main:Tab({ Name = "Card Selection", Image = "rbxassetid://18821914323" }),
    BossRush = tabGroups.Main:Tab({ Name = "Boss Rush", Image = "rbxassetid://18821914323" }),
    Webhook = tabGroups.Main:Tab({ Name = "Webhook", Image = "rbxassetid://18821914323" }),
    SeamlessFix = tabGroups.Main:Tab({ Name = "Seamless Fix", Image = "rbxassetid://18821914323" }),
    Misc = tabGroups.Main:Tab({ Name = "Misc", Image = "rbxassetid://18821914323" }),
    Settings = tabGroups.Main:Tab({ Name = "Settings", Image = "rbxassetid://10734950309" }),
}
if not isInLobby then
    Tabs.Event = tabGroups.Main:Tab({ Name = "Event", Image = "rbxassetid://18821914323" })
end

local Sections = {}
for name, tab in pairs(Tabs) do
    Sections[name] = {
        Left = tab:Section({ Side = "Left" })
    }
end

local CandyCards = {
    ["Weakened Resolve I"] = 13, ["Weakened Resolve II"] = 11, ["Weakened Resolve III"] = 4,
    ["Fog of War I"] = 12, ["Fog of War II"] = 10, ["Fog of War III"] = 5,
    ["Lingering Fear I"] = 6, ["Lingering Fear II"] = 2,
    ["Power Reversal I"] = 14, ["Power Reversal II"] = 9,
    ["Greedy Vampire's"] = 8, ["Hellish Gravity"] = 3, ["Deadly Striker"] = 7,
    ["Critical Denial"] = 1, ["Trick or Treat Coin Flip"] = 15
}
local DevilSacrifice = { ["Devil's Sacrifice"] = 999 }
local OtherCards = {
    ["Bullet Breaker I"] = 999, ["Bullet Breaker II"] = 999, ["Bullet Breaker III"] = 999,
    ["Hell Merchant I"] = 999, ["Hell Merchant II"] = 999, ["Hell Merchant III"] = 999,
    ["Hellish Warp I"] = 999, ["Hellish Warp II"] = 999,
    ["Fiery Surge I"] = 999, ["Fiery Surge II"] = 999,
    ["Grevious Wounds I"] = 999, ["Grevious Wounds II"] = 999,
    ["Scorching Hell I"] = 999, ["Scorching Hell II"] = 999,
    ["Fortune Flow"] = 999, ["Soul Link"] = 999
}
getgenv().CardPriority = {}
for n,v in pairs(CandyCards) do getgenv().CardPriority[n]=v end
for n,v in pairs(DevilSacrifice) do getgenv().CardPriority[n]=v end
for n,v in pairs(OtherCards) do getgenv().CardPriority[n]=v end

local BossRushGeneral = {
    ["Metal Skin"] = 0,["Raging Power"] = 0,["Demon Takeover"] = 0,["Fortune"] = 0,
    ["Chaos Eater"] = 0,["Godspeed"] = 0,["Insanity"] = 0,["Feeding Madness"] = 0,["Emotional Damage"] = 0
}
local BabyloniaCastle = {}
getgenv().BossRushCardPriority = {}
for n,v in pairs(BossRushGeneral) do getgenv().BossRushCardPriority[n]=v end
for n,v in pairs(BabyloniaCastle) do getgenv().BossRushCardPriority[n]=v end

local function getClientData()
    local ok, data = pcall(function()
        local modulePath = RS:WaitForChild("Modules"):WaitForChild("ClientData")
        if modulePath and modulePath:IsA("ModuleScript") then
            return require(modulePath)
        end
        return nil
    end)
    return ok and data or nil
end

local function getTowerInfo(unitName)
    local ok, data = pcall(function()
        local towerInfoPath = RS:WaitForChild("Modules"):WaitForChild("TowerInfo")
        local towerModule = towerInfoPath:FindFirstChild(unitName)
        if towerModule and towerModule:IsA("ModuleScript") then
            return require(towerModule)
        end
        return nil
    end)
    return ok and data or nil
end

local function getAllAbilities(unitName)
    local towerNameToCheck = unitName
    if unitName == "TuskSummon_Act4" then towerNameToCheck = "JohnnyGodly" end
    local towerInfo = getTowerInfo(towerNameToCheck)
    if not towerInfo then return {} end
    local abilities = {}
    for level = 0,50 do
        if towerInfo[level] then
            if towerInfo[level].Ability then
                local a = towerInfo[level].Ability
                local nm = a.Name
                if not abilities[nm] then
                    local hasRealAttribute = false
                    if a.AttributeRequired and type(a.AttributeRequired) == "table" then
                        if a.AttributeRequired.Name ~= "JUST_TO_DISPLAY_IN_LOBBY" then
                            hasRealAttribute = true
                        end
                    elseif a.AttributeRequired and type(a.AttributeRequired) ~= "table" then
                        hasRealAttribute = true
                    end
                    abilities[nm] = { name = nm, cooldown = a.Cd, requiredLevel = level, isGlobal = a.IsCdGlobal or false, isAttribute = hasRealAttribute }
                end
            end
            if towerInfo[level].Abilities then
                for _, a in pairs(towerInfo[level].Abilities) do
                    local nm = a.Name
                    if not abilities[nm] then
                        local hasRealAttribute = false
                        if a.AttributeRequired and type(a.AttributeRequired) == "table" then
                            if a.AttributeRequired.Name ~= "JUST_TO_DISPLAY_IN_LOBBY" then
                                hasRealAttribute = true
                            end
                        elseif a.AttributeRequired and type(a.AttributeRequired) ~= "table" then
                            hasRealAttribute = true
                        end
                        abilities[nm] = { name = nm, cooldown = a.Cd, requiredLevel = level, isGlobal = a.IsCdGlobal or false, isAttribute = hasRealAttribute }
                    end
                end
            end
        end
    end
    return abilities
end

Sections.AutoEvent.Left:Paragraph({ Header = "Halloween 2025 Event Auto Join", Body = "Automatically joins and starts the Halloween event." })
Sections.AutoEvent.Left:Toggle({
    Name = "Enable Auto Event Join",
    Default = getgenv().Config.toggles.AutoEventToggle or false,
    Callback = function(val)
        getgenv().AutoEventEnabled = val
        getgenv().Config.toggles.AutoEventToggle = val
        saveConfig(getgenv().Config)
        notify("Auto Event", val and "Auto event join enabled!" or "Auto event join disabled!", 3)
    end,
}, "AutoEventToggle")
getgenv().AutoEventEnabled = getgenv().Config.toggles.AutoEventToggle or false

Sections.AutoEvent.Left:Toggle({
    Name = "Auto Fast Retry",
    Default = getgenv().Config.toggles.AutoFastRetryToggle or false,
    Callback = function(val)
        getgenv().AutoFastRetryEnabled = val
        getgenv().Config.toggles.AutoFastRetryToggle = val
        saveConfig(getgenv().Config)
        notify("Auto Fast Retry", val and "Enabled!" or "Disabled!", 3)
    end,
}, "AutoFastRetryToggle")
getgenv().AutoFastRetryEnabled = getgenv().Config.toggles.AutoFastRetryToggle or false

Sections.AutoAbility.Left:Paragraph({ Header = "Auto Ability System", Body = "Automatically uses tower abilities based on your equipped units." })
Sections.AutoAbility.Left:Toggle({
    Name = "Enable Auto Abilities",
    Default = getgenv().Config.toggles.AutoAbilityToggle or false,
    Callback = function(val)
        getgenv().AutoAbilitiesEnabled = val
        getgenv().Config.toggles.AutoAbilityToggle = val
        saveConfig(getgenv().Config)
        notify("Auto Ability", val and "Auto abilities enabled!" or "Auto abilities disabled!", 3)
    end,
}, "AutoAbilityToggle")
getgenv().AutoAbilitiesEnabled = getgenv().Config.toggles.AutoAbilityToggle or false

local function buildAutoAbilityUI()
    local clientData = getClientData()
    if not clientData or not clientData.Slots then return end
    local sortedSlots = {"Slot1","Slot2","Slot3","Slot4","Slot5","Slot6"}

    local unitCount = 0
    for _, slotName in ipairs(sortedSlots) do
        local slotData = clientData.Slots[slotName]
        if slotData and slotData.Value then
            local unitName = slotData.Value
            local abilities = getAllAbilities(unitName)
            if next(abilities) then
                if unitCount > 0 then
                    Sections.AutoAbility.Left:Divider()
                end
                unitCount = unitCount + 1
                
                Sections.AutoAbility.Left:Header({ Text = "━━━ " .. unitName .. " ━━━" })
                Sections.AutoAbility.Left:SubLabel({ Text = slotName .. " • Level " .. tostring(slotData.Level or 0) })

                if not getgenv().UnitAbilities[unitName] then getgenv().UnitAbilities[unitName] = {} end

                local sortedAbilities = {}
                for abilityName, data in pairs(abilities) do
                    table.insert(sortedAbilities, { name = abilityName, data = data })
                end
                table.sort(sortedAbilities, function(a,b) return a.data.requiredLevel < b.data.requiredLevel end)

                for _, ab in ipairs(sortedAbilities) do
                    local abilityName = ab.name
                    local abilityData = ab.data
                    if not getgenv().UnitAbilities[unitName][abilityName] then
                        getgenv().UnitAbilities[unitName][abilityName] = { enabled = true, onlyOnBoss=false, specificWave=nil, requireBossInRange=false, delayAfterBossSpawn=false, useOnWave=false }
                    end
                    local cfg = getgenv().UnitAbilities[unitName][abilityName]
                    local saved = getgenv().Config.abilities[unitName] and getgenv().Config.abilities[unitName][abilityName]

                    local defaultToggle = saved and saved.enabled or false
                    if saved then
                        cfg.enabled = saved.enabled or false
                        cfg.onlyOnBoss = saved.onlyOnBoss or false
                        cfg.specificWave = saved.specificWave
                        cfg.requireBossInRange = saved.requireBossInRange or false
                        cfg.delayAfterBossSpawn = saved.delayAfterBossSpawn or false
                        cfg.useOnWave = saved.useOnWave or false
                    end

                    local abilityInfo = "Lvl " .. abilityData.requiredLevel .. " | CD: " .. tostring(abilityData.cooldown) .. "s"
                    if abilityData.isAttribute then abilityInfo = abilityInfo .. " | 🔒 Attribute" end

                    Sections.AutoAbility.Left:Toggle({
                        Name = abilityName,
                        Default = defaultToggle,
                        Callback = function(v)
                            cfg.enabled = v
                            getgenv().Config.abilities[unitName] = getgenv().Config.abilities[unitName] or {}
                            getgenv().Config.abilities[unitName][abilityName] = getgenv().Config.abilities[unitName][abilityName] or {}
                            getgenv().Config.abilities[unitName][abilityName].enabled = v
                            saveConfig(getgenv().Config)
                        end
                    }, unitName .. "_" .. abilityName .. "_Toggle")
                    
                    Sections.AutoAbility.Left:SubLabel({ Text = abilityInfo })

                    local defaultModifiers = {}
                    if saved then
                        if saved.onlyOnBoss then defaultModifiers["Only On Boss"] = true end
                        if saved.requireBossInRange then defaultModifiers["Boss In Range"] = true end
                        if saved.delayAfterBossSpawn then defaultModifiers["Delay After Boss Spawn"] = true end
                        if saved.useOnWave then defaultModifiers["On Wave"] = true end
                    end

                    Sections.AutoAbility.Left:Dropdown({
                        Name = "Conditions",
                        Search = false,
                        Multi = true,
                        Required = false,
                        Options = {"Only On Boss","Boss In Range","Delay After Boss Spawn","On Wave"},
                        Default = (function()
                            local list = {}
                            for k,v in pairs(defaultModifiers) do if v then table.insert(list, k) end end
                            return list
                        end)(),
                        Callback = function(Value)
                            local selected = {}
                            if type(Value) == "table" then
                                for k,v in pairs(Value) do
                                    if type(k) == "string" and v == true then selected[k] = true end
                                end
                                if #Value > 0 then
                                    for _,opt in ipairs(Value) do selected[opt] = true end
                                end
                            end
                            cfg.onlyOnBoss = selected["Only On Boss"] or false
                            cfg.requireBossInRange = selected["Boss In Range"] or false
                            cfg.delayAfterBossSpawn = selected["Delay After Boss Spawn"] or false
                            cfg.useOnWave = selected["On Wave"] or false

                            getgenv().Config.abilities[unitName] = getgenv().Config.abilities[unitName] or {}
                            getgenv().Config.abilities[unitName][abilityName] = getgenv().Config.abilities[unitName][abilityName] or {}
                            local store = getgenv().Config.abilities[unitName][abilityName]
                            store.onlyOnBoss = cfg.onlyOnBoss
                            store.requireBossInRange = cfg.requireBossInRange
                            store.delayAfterBossSpawn = cfg.delayAfterBossSpawn
                            store.useOnWave = cfg.useOnWave
                            saveConfig(getgenv().Config)
                        end
                    }, unitName .. "_" .. abilityName .. "_Modifiers")
                    
                    Sections.AutoAbility.Left:Input({
                        Name = "Wave Number (if 'On Wave' selected)",
                        Default = saved and saved.specificWave and tostring(saved.specificWave) or "",
                        Placeholder = "Enter wave number",
                        Callback = function(text)
                            local num = tonumber(text)
                            cfg.specificWave = num
                            getgenv().Config.abilities[unitName] = getgenv().Config.abilities[unitName] or {}
                            getgenv().Config.abilities[unitName][abilityName] = getgenv().Config.abilities[unitName][abilityName] or {}
                            getgenv().Config.abilities[unitName][abilityName].specificWave = num
                            saveConfig(getgenv().Config)
                        end,
                        onChanged = function(_) end,
                    }, unitName .. "_" .. abilityName .. "_Wave")
                end
            end
        end
    end
end

task.spawn(function()
    task.wait(1)
    local maxRetries, retryDelay = 10, 3
    local ok = false
    for i=1,maxRetries do
        local cd = getClientData()
        if cd and cd.Slots then
            buildAutoAbilityUI()
            ok = true
            break
        else
            notify("Auto Ability", "ClientData loading failed, retrying... ("..i.."/"..maxRetries..")", 3)
            task.wait(retryDelay)
        end
    end
    if not ok then
        Sections.AutoAbility.Left:Paragraph({ Header = "❌ Failed to Load Units", Body = "Could not load your equipped units from ClientData. Rejoin or reload the script." })
    end
end)

Sections.CardSelection.Left:Paragraph({ Header = "Card Priority System", Body = "Set priority values for each card (lower number = higher priority). Cards with priority 999 will be avoided." })
Sections.CardSelection.Left:Toggle({
    Name = "Enable Card Selection",
    Default = getgenv().Config.toggles.CardSelectionToggle or false,
    Callback = function(v)
        getgenv().CardSelectionEnabled = v
        getgenv().Config.toggles.CardSelectionToggle = v
        saveConfig(getgenv().Config)
        notify("Card Selection", v and "Card selection enabled!" or "Card selection disabled!", 3)
    end
}, "CardSelectionToggle")
getgenv().CardSelectionEnabled = getgenv().Config.toggles.CardSelectionToggle or false

Sections.CardSelection.Left:Header({ Text = "━━━━━ Candy Cards ━━━━━" })
local candyNames = {}
for k in pairs(CandyCards) do table.insert(candyNames, k) end
 table.sort(candyNames, function(a,b) return CandyCards[a] < CandyCards[b] end)
for _, cardName in ipairs(candyNames) do
    local key = "Card_"..cardName
    local defaultValue = getgenv().Config.inputs[key] or tostring(CandyCards[cardName])
    Sections.CardSelection.Left:Input({
        Name = cardName,
        Default = defaultValue,
        Placeholder = "Priority (1-999)",
        Callback = function(Value)
            local num = tonumber(Value)
            if num then
                getgenv().CardPriority[cardName] = num
                getgenv().Config.inputs[key] = tostring(num)
                saveConfig(getgenv().Config)
            end
        end,
        onChanged = function(_) end,
    }, key)
    getgenv().CardPriority[cardName] = tonumber(defaultValue)
end

Sections.CardSelection.Left:Header({ Text = "━━━━━ Devil's Sacrifice ━━━━━" })
for cardName,priority in pairs(DevilSacrifice) do
    local key = "Card_"..cardName
    local defaultValue = getgenv().Config.inputs[key] or tostring(priority)
    Sections.CardSelection.Left:Input({
        Name = cardName,
        Default = defaultValue,
        Placeholder = "Priority (1-999)",
        Callback = function(Value)
            local num = tonumber(Value)
            if num then
                getgenv().CardPriority[cardName] = num
                getgenv().Config.inputs[key] = tostring(num)
                saveConfig(getgenv().Config)
            end
        end,
        onChanged = function(_) end,
    }, key)
    getgenv().CardPriority[cardName] = tonumber(defaultValue)
end

Sections.CardSelection.Left:Header({ Text = "━━━━━ Other Cards ━━━━━" })
local otherNames = {}
for k in pairs(OtherCards) do table.insert(otherNames, k) end
 table.sort(otherNames)
for _, cardName in ipairs(otherNames) do
    local key = "Card_"..cardName
    local defaultValue = getgenv().Config.inputs[key] or tostring(OtherCards[cardName])
    Sections.CardSelection.Left:Input({
        Name = cardName,
        Default = defaultValue,
        Placeholder = "Priority (1-999)",
        Callback = function(Value)
            local num = tonumber(Value)
            if num then
                getgenv().CardPriority[cardName] = num
                getgenv().Config.inputs[key] = tostring(num)
                saveConfig(getgenv().Config)
            end
        end,
        onChanged = function(_) end,
    }, key)
    getgenv().CardPriority[cardName] = tonumber(defaultValue)
end

Sections.BossRush.Left:Paragraph({ Header = "Boss Rush Card System", Body = "Set priority for Boss Rush cards (lower = better). Cards with 999 will be avoided." })
Sections.BossRush.Left:Toggle({
    Name = "Enable Boss Rush Cards",
    Default = getgenv().Config.toggles.BossRushToggle or false,
    Callback = function(v)
        getgenv().BossRushEnabled = v
        getgenv().Config.toggles.BossRushToggle = v
        saveConfig(getgenv().Config)
        notify("Boss Rush", v and "Boss Rush card selection enabled!" or "Boss Rush card selection disabled!", 3)
    end
}, "BossRushToggle")
getgenv().BossRushEnabled = getgenv().Config.toggles.BossRushToggle or false

Sections.BossRush.Left:Header({ Text = "━━━━━ Boss Rush ━━━━━" })
local brNames = {}
for k in pairs(BossRushGeneral) do table.insert(brNames, k) end
 table.sort(brNames)
for _, cardName in ipairs(brNames) do
    local inputKey = "BossRush_"..cardName
    local defaultValue = getgenv().Config.inputs[inputKey] or tostring(BossRushGeneral[cardName])
    local cardType = "Buff"
    pcall(function()
        local bossRushModule = RS:FindFirstChild("Modules"):FindFirstChild("CardHandler"):FindFirstChild("BossRushCards")
        if bossRushModule then
            local cards = require(bossRushModule)
            for _, card in pairs(cards) do if card.CardName == cardName then cardType = card.CardType or "Buff" break end end
        end
    end)
    Sections.BossRush.Left:Input({
        Name = cardName .. " ("..cardType..")",
        Default = defaultValue,
        Placeholder = "Priority (1-999)",
        Callback = function(Value)
            local num = tonumber(Value)
            if num then
                getgenv().BossRushCardPriority[cardName] = num
                getgenv().Config.inputs[inputKey] = tostring(num)
                saveConfig(getgenv().Config)
            end
        end,
        onChanged = function(_) end,
    }, inputKey)
    getgenv().BossRushCardPriority[cardName] = tonumber(defaultValue)
end

Sections.BossRush.Left:Header({ Text = "━━━━━ Babylonia Castle ━━━━━" })
pcall(function()
    local babyloniaModule = RS:FindFirstChild("Modules"):FindFirstChild("CardHandler"):FindFirstChild("BossRushCards"):FindFirstChild("Babylonia Castle")
    if babyloniaModule then
        local cards = require(babyloniaModule)
        for _, card in pairs(cards) do
            local cardName = card.CardName
            local cardType = card.CardType or "Buff"
            local inputKey = "BabyloniaCastle_" .. cardName
            if not getgenv().BossRushCardPriority[cardName] then getgenv().BossRushCardPriority[cardName] = 999 end
            local defaultValue = getgenv().Config.inputs[inputKey] or "999"
            Sections.BossRush.Left:Input({
                Name = cardName .. " ("..cardType..")",
                Default = defaultValue,
                Placeholder = "Priority (1-999)",
                Callback = function(Value)
                    local num = tonumber(Value)
                    if num then
                        getgenv().BossRushCardPriority[cardName] = num
                        getgenv().Config.inputs[inputKey] = tostring(num)
                        saveConfig(getgenv().Config)
                    end
                end,
                onChanged = function(_) end,
            }, inputKey)
            getgenv().BossRushCardPriority[cardName] = tonumber(defaultValue)
        end
    end
end)

Sections.Webhook.Left:Paragraph({ Header = "Discord Webhook Integration", Body = "Send game completion stats to Discord when you finish a match." })
Sections.Webhook.Left:Input({
    Name = "Webhook URL",
    Default = getgenv().Config.inputs.WebhookURL or "",
    Placeholder = "https://discord.com/api/webhooks/...",
    Callback = function(Value)
        getgenv().WebhookURL = Value or ""
        getgenv().Config.inputs.WebhookURL = getgenv().WebhookURL
        saveConfig(getgenv().Config)
    end,
    onChanged = function(_) end,
}, "WebhookURL")

Sections.Webhook.Left:Toggle({
    Name = "Enable Webhook",
    Default = getgenv().Config.toggles.WebhookToggle or false,
    Callback = function(v)
        getgenv().WebhookEnabled = v
        getgenv().Config.toggles.WebhookToggle = v
        saveConfig(getgenv().Config)
        if v then
            if (getgenv().WebhookURL == "" or not string.match(getgenv().WebhookURL, "^https://discord%.com/api/webhooks/")) then
                notify("Webhook Error", "Please enter a valid webhook URL first!", 5)
                getgenv().WebhookEnabled = false
                getgenv().Config.toggles.WebhookToggle = false
                saveConfig(getgenv().Config)
            else
                notify("Webhook", "Webhook enabled!", 3)
            end
        else
            notify("Webhook", "Webhook disabled!", 3)
        end
    end
}, "WebhookToggle")

Sections.SeamlessFix.Left:Paragraph({ Header = "Seamless Retry Bug Fix", Body = "Automatically disables seamless retry after X rounds to prevent lag and restart the match." })
getgenv().MaxSeamlessRounds = tonumber(getgenv().Config.inputs.SeamlessRounds) or 4
Sections.SeamlessFix.Left:Input({
    Name = "Maximum Rounds",
    Default = getgenv().Config.inputs.SeamlessRounds or "4",
    Placeholder = "Number of rounds (default: 4)",
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num > 0 then
            getgenv().MaxSeamlessRounds = num
            getgenv().Config.inputs.SeamlessRounds = tostring(num)
            saveConfig(getgenv().Config)
        else
            getgenv().MaxSeamlessRounds = 4
        end
    end,
    onChanged = function(_) end,
}, "SeamlessRounds")

Sections.SeamlessFix.Left:Toggle({
    Name = "Enable Seamless Bug Fix",
    Default = getgenv().Config.toggles.SeamlessToggle or false,
    Callback = function(v)
        getgenv().SeamlessLimiterEnabled = v
        getgenv().Config.toggles.SeamlessToggle = v
        saveConfig(getgenv().Config)
        if v then
            notify("Seamless Fix", "Seamless bug fix enabled!", 3)
            print("[Seamless Fix] Seamless bug fix enabled!")
        else
            notify("Seamless Fix", "Seamless bug fix disabled!", 3)
            print("[Seamless Fix] Seamless bug fix disabled!")
        end
    end
}, "SeamlessToggle")
getgenv().SeamlessLimiterEnabled = getgenv().Config.toggles.SeamlessToggle or false

if not isInLobby then
    Sections.Event.Left:Paragraph({ Header = "Halloween 2025 Event Automation", Body = "Automatically manages bingo stamps, buys capsules, and opens them." })
    Sections.Event.Left:Header({ Text = "━━━━━ Auto Bingo ━━━━━" })
    Sections.Event.Left:Toggle({
        Name = "Enable Auto Bingo",
        Default = getgenv().Config.toggles.BingoToggle or false,
        Callback = function(v)
            getgenv().BingoEnabled = v
            getgenv().Config.toggles.BingoToggle = v
            saveConfig(getgenv().Config)
            notify("Auto Bingo", v and "Auto bingo enabled!" or "Auto bingo disabled!", 3)
        end
    }, "BingoToggle")
    getgenv().BingoEnabled = getgenv().Config.toggles.BingoToggle or false

    Sections.Event.Left:Header({ Text = "━━━━━ Auto Capsules ━━━━━" })
    Sections.Event.Left:Toggle({
        Name = "Enable Auto Capsules",
        Default = getgenv().Config.toggles.CapsuleToggle or false,
        Callback = function(v)
            getgenv().CapsuleEnabled = v
            getgenv().Config.toggles.CapsuleToggle = v
            saveConfig(getgenv().Config)
            notify("Auto Capsules", v and "Auto capsules enabled!" or "Auto capsules disabled!", 3)
        end
    }, "CapsuleToggle")
    getgenv().CapsuleEnabled = getgenv().Config.toggles.CapsuleToggle or false

    Sections.Event.Left:Paragraph({ Header = "How It Works", Body = "Bingo: Uses stamps (25x), claims rewards (25x), completes board\nCapsules: Buys 100/10/1 based on candy, opens all capsules" })
end

Sections.Misc.Left:Paragraph({ Header = "Miscellaneous Features", Body = "Additional utility features for the game." })

Sections.Misc.Left:Toggle({
    Name = "Remove Enemies/SpawnedUnits",
    Default = getgenv().Config.toggles.RemoveEnemiesToggle or false,
    Callback = function(v)
        getgenv().RemoveEnemiesEnabled = v
        getgenv().Config.toggles.RemoveEnemiesToggle = v
        saveConfig(getgenv().Config)
        notify("Remove Enemies/SpawnedUnits", v and "Remove enabled!" or "Remove disabled!", 3)
    end
}, "RemoveEnemiesToggle")
getgenv().RemoveEnemiesEnabled = getgenv().Config.toggles.RemoveEnemiesToggle or false

if not isInLobby then
    Sections.Misc.Left:Toggle({
        Name = "FPS Boost",
        Default = getgenv().Config.toggles.FPSBoostToggle or false,
        Callback = function(v)
            getgenv().FPSBoostEnabled = v
            getgenv().Config.toggles.FPSBoostToggle = v
            saveConfig(getgenv().Config)
            notify("FPS Boost", v and "Optimization enabled!" or "Optimization disabled!", 3)
        end
    }, "FPSBoostToggle")
    getgenv().FPSBoostEnabled = getgenv().Config.toggles.FPSBoostToggle or false
else
    getgenv().FPSBoostEnabled = false
end

Sections.Misc.Left:Toggle({
    Name = "Anti-AFK",
    Default = getgenv().Config.toggles.AntiAFKToggle or false,
    Callback = function(v)
        getgenv().AntiAFKEnabled = v
        getgenv().Config.toggles.AntiAFKToggle = v
        saveConfig(getgenv().Config)
        notify("Anti-AFK", v and "Anti-AFK enabled!" or "Anti-AFK disabled!", 3)
    end
}, "AntiAFKToggle")
getgenv().AntiAFKEnabled = getgenv().Config.toggles.AntiAFKToggle or false

Sections.Misc.Left:Toggle({
    Name = "Black Screen",
    Default = getgenv().Config.toggles.BlackScreenToggle or false,
    Callback = function(v)
        getgenv().BlackScreenEnabled = v
        getgenv().Config.toggles.BlackScreenToggle = v
        saveConfig(getgenv().Config)
        notify("Black Screen", v and "Black screen enabled!" or "Black screen disabled!", 3)
    end
}, "BlackScreenToggle")
getgenv().BlackScreenEnabled = getgenv().Config.toggles.BlackScreenToggle or false

MacLib:SetFolder("ALSHalloweenEvent")
Tabs.Settings:InsertConfigSection("Left")

Tabs.AutoEvent:Select()
notify("ALS Halloween Event", "MacLib UI loaded successfully!", 5)

for inputKey, value in pairs(getgenv().Config.inputs) do
    if inputKey:match("^Card_") then
        local cardName = inputKey:gsub("^Card_", "")
        local num = tonumber(value)
        if num and getgenv().CardPriority[cardName] then getgenv().CardPriority[cardName] = num end
    elseif inputKey:match("^BossRush_") then
        local cardName = inputKey:gsub("^BossRush_", "")
        local num = tonumber(value)
        if num and getgenv().BossRushCardPriority[cardName] then getgenv().BossRushCardPriority[cardName] = num end
    elseif inputKey:match("^BabyloniaCastle_") then
        local cardName = inputKey:gsub("^BabyloniaCastle_", "")
        local num = tonumber(value)
        if num then getgenv().BossRushCardPriority[cardName] = num end
    end
end

local isUnloaded = false
Window.onUnloaded(function()
    isUnloaded = true
end)

task.spawn(function()
    repeat task.wait() until game.CoreGui:FindFirstChild("RobloxPromptGui")
    local TeleportService = game:GetService("TeleportService")
    local promptOverlay = game.CoreGui.RobloxPromptGui.promptOverlay
    promptOverlay.ChildAdded:Connect(function(child)
        if child.Name == "ErrorPrompt" then
            print("[Auto Rejoin] Disconnect detected! Attempting to rejoin...")
            task.spawn(function()
                while true do
                    local ok = pcall(function()
                        TeleportService:Teleport(12886143095, Players.LocalPlayer)
                    end)
                    if ok then print("[Auto Rejoin] Rejoining...") break else print("[Auto Rejoin] Retry in 2s...") task.wait(2) end
                end
            end)
        end
    end)
    print("[Auto Rejoin] Auto rejoin system loaded!")
end)

task.spawn(function()
    local vu = game:GetService("VirtualUser")
    Players.LocalPlayer.Idled:Connect(function()
        if getgenv().AntiAFKEnabled then
            vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end
    end)
    print("[Anti-AFK] Anti-AFK system loaded!")
end)

task.spawn(function()
    local blackScreenGui, blackFrame
    local function createBlack()
        if blackScreenGui then return end
        blackScreenGui = Instance.new("ScreenGui")
        blackScreenGui.Name = "BlackScreenOverlay"
        blackScreenGui.DisplayOrder = -999999
        blackScreenGui.IgnoreGuiInset = true
        blackScreenGui.ResetOnSpawn = false
        blackFrame = Instance.new("Frame")
        blackFrame.Size = UDim2.new(1,0,1,0)
        blackFrame.BackgroundColor3 = Color3.new(0,0,0)
        blackFrame.BorderSizePixel = 0
        blackFrame.ZIndex = -999999
        blackFrame.Parent = blackScreenGui
        pcall(function() blackScreenGui.Parent = LocalPlayer.PlayerGui end)
        pcall(function()
            if workspace.CurrentCamera then workspace.CurrentCamera.MaxAxisFieldOfView = 0.001 end
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)
    end
    local function removeBlack()
        if blackScreenGui then blackScreenGui:Destroy() blackScreenGui=nil blackFrame=nil end
        pcall(function() if workspace.CurrentCamera then workspace.CurrentCamera.MaxAxisFieldOfView = 70 end end)
    end
    while true do
        task.wait(0.5)
        if getgenv().BlackScreenEnabled then if not blackScreenGui then createBlack() end else if blackScreenGui then removeBlack() end end
        if isUnloaded then removeBlack() break end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.1)
        if getgenv().RemoveEnemiesEnabled then
            local enemies = workspace:FindFirstChild("Enemies")
            if enemies then
                for _, enemy in pairs(enemies:GetChildren()) do
                    if enemy:IsA("Model") and enemy.Name ~= "Boss" then pcall(function() enemy:Destroy() end) end
                end
            end
            local spawnedunits = workspace:FindFirstChild("SpawnedUnits")
            if spawnedunits then
                for _, su in pairs(spawnedunits:GetChildren()) do
                    if su:IsA("Model") then pcall(function() su:Destroy() end) end
                end
            end
        end
        if isUnloaded then break end
    end
end)

task.spawn(function()
    while true do
        task.wait(10)
        if not isInLobby and getgenv().FPSBoostEnabled then
            pcall(function()
                local lighting = game:GetService("Lighting")
                for _, child in ipairs(lighting:GetChildren()) do child:Destroy() end
                lighting.Ambient = Color3.new(1,1,1)
                lighting.Brightness = 1
                lighting.GlobalShadows = false
                lighting.FogEnd = 100000
                lighting.FogStart = 100000
                lighting.ClockTime = 12
                lighting.GeographicLatitude = 0
                for _, obj in ipairs(game.Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") then
                        if obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("WedgePart") or obj:IsA("CornerWedgePart") then
                            obj.Material = Enum.Material.SmoothPlastic
                            if obj:FindFirstChildOfClass("Texture") then
                                for _, t in ipairs(obj:GetChildren()) do if t:IsA("Texture") then t:Destroy() end end
                            end
                            if obj:IsA("MeshPart") then obj.TextureID = "" end
                        end
                        if obj:IsA("Decal") then obj:Destroy() end
                    end
                    if obj:IsA("SurfaceAppearance") then obj:Destroy() end
                end
                local mapPath = game.Workspace:FindFirstChild("Map") and game.Workspace.Map:FindFirstChild("Map")
                if mapPath then for _, ch in ipairs(mapPath:GetChildren()) do if not ch:IsA("Model") then ch:Destroy() end end end
            end)
        end
        if isUnloaded then break end
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
                        pcall(function() enterEvent:FireServer() task.wait(0.2) startEvent:FireServer() end)
                        print("[Auto Event] Joined and started Halloween event")
                    end
                end
            end
        end
        if isUnloaded then break end
    end
end)

task.spawn(function()
    local p = Players.LocalPlayer
    local v = VIM
    local g = game:GetService("GuiService")
    local rs = RS
    local seen = false
    local function press(k)
        v:SendKeyEvent(true, k, false, game)
        task.wait(0.1)
        v:SendKeyEvent(false, k, false, game)
    end
    while true do
        task.wait(1)
        if getgenv().AutoFastRetryEnabled then
            pcall(function()
                local s = p:WaitForChild("PlayerGui"):WaitForChild("Settings")
                local a = s:WaitForChild("AutoReady")
                if a.Value == true then rs.Remotes.SetSettings:InvokeServer("AutoReady") end
                local e = p.PlayerGui:FindFirstChild("EndGameUI")
                if e and e:FindFirstChild("BG") then
                    seen = true
                    local r = e.BG.Buttons:FindFirstChild("Retry")
                    if r then
                        g.SelectedObject = r
                        repeat press(Enum.KeyCode.Return) task.wait(0.5) until not p.PlayerGui:FindFirstChild("EndGameUI")
                        g.SelectedObject = nil
                    end
                elseif g.SelectedObject ~= nil then g.SelectedObject = nil end
                if seen and not a.Value then rs.Remotes.SetSettings:InvokeServer("AutoReady") end
            end)
        end
        if isUnloaded then break end
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
        abilityCooldowns = {}
    end
    local function getTowerInfoCached(towerName)
        if towerInfoCache[towerName] then return towerInfoCache[towerName] end
        local t = getTowerInfo(towerName)
        if t then towerInfoCache[towerName] = t end
        return t
    end
    local function getAbilityData(towerName, abilityName)
        local info = getTowerInfoCached(towerName)
        if not info then return nil end
        for level=0,50 do
            if info[level] then
                if info[level].Ability then
                    local a = info[level].Ability
                    if a.Name == abilityName then return { cooldown=a.Cd, requiredLevel=level, isGlobal=a.IsCdGlobal } end
                end
                if info[level].Abilities then
                    for _,a in pairs(info[level].Abilities) do
                        if a.Name == abilityName then return { cooldown=a.Cd, requiredLevel=level, isGlobal=a.IsCdGlobal } end
                    end
                end
            end
        end
        return nil
    end
    local function getCurrentWave()
        local ok, result = pcall(function()
            local gui = LocalPlayer.PlayerGui:FindFirstChild("Top") if not gui then return 0 end
            local frame = gui:FindFirstChild("Frame") if not frame then return 0 end
            frame = frame:FindFirstChild("Frame") if not frame then return 0 end
            frame = frame:FindFirstChild("Frame") if not frame then return 0 end
            frame = frame:FindFirstChild("Frame") if not frame then return 0 end
            local button = frame:FindFirstChild("TextButton") if not button then return 0 end
            local children = button:GetChildren() if #children < 3 then return 0 end
            local text = children[3].Text
            return tonumber(text) or 0
        end)
        return ok and result or 0
    end
    local function getTowerInfoName(tower)
        if not tower then return nil end
        local candidates = { tower:GetAttribute("TowerType"), tower:GetAttribute("Type"), tower:GetAttribute("TowerName"), tower:GetAttribute("BaseTower"),
            tower:FindFirstChild("TowerType") and tower.TowerType:IsA("ValueBase") and tower.TowerType.Value,
            tower:FindFirstChild("Type") and tower.Type:IsA("ValueBase") and tower.Type.Value,
            tower:FindFirstChild("TowerName") and tower.TowerName:IsA("ValueBase") and tower.TowerName.Value,
            tower.Name }
        for _, c in ipairs(candidates) do if c and type(c)=="string" and c ~= "" then return c end end
        return tower.Name
    end
    local function getTower(name) return Towers:FindFirstChild(name) end
    local function getUpgradeLevel(tower)
        if not tower then return 0 end
        local u = tower:FindFirstChild("Upgrade")
        if u and u:IsA("ValueBase") then return u.Value or 0 end
        return 0
    end
    local function useAbility(tower, abilityName)
        if tower then pcall(function() RS.Remotes.Ability:InvokeServer(tower, abilityName) end) end
    end
    local function isOnCooldown(towerName, abilityName)
        local d = getAbilityData(towerName, abilityName) if not d or not d.cooldown then return false end
        local key = towerName .. "_" .. abilityName
        local last = abilityCooldowns[key]
        if not last then return false end
        local elapsed = tick() - last
        return elapsed < (d.cooldown / GAME_SPEED)
    end
    local function setAbilityUsed(towerName, abilityName) abilityCooldowns[towerName.."_"..abilityName] = tick() end
    local function hasAbilityBeenUnlocked(towerName, abilityName, towerLevel)
        local d = getAbilityData(towerName, abilityName)
        return d and towerLevel >= d.requiredLevel
    end
    local function bossExists()
        local ok, res = pcall(function()
            local enemies = workspace:FindFirstChild("Enemies") if not enemies then return false end
            return enemies:FindFirstChild("Boss") ~= nil
        end)
        return ok and res
    end
    local function bossReadyForAbilities()
        if bossExists() then
            if not generalBossSpawnTime then generalBossSpawnTime = tick() end
            return (tick() - generalBossSpawnTime) >= 1
        else
            generalBossSpawnTime = nil
            return false
        end
    end
    local function checkBossSpawnTime()
        if bossExists() then
            if not bossSpawnTime then bossSpawnTime = tick() end
            return (tick() - bossSpawnTime) >= 16
        else
            bossSpawnTime = nil
            return false
        end
    end
    local function getBossPosition()
        local ok,res = pcall(function()
            local enemies = workspace:FindFirstChild("Enemies") if not enemies then return nil end
            local boss = enemies:FindFirstChild("Boss") if not boss then return nil end
            local hrp = boss:FindFirstChild("HumanoidRootPart") if hrp then return hrp.Position end
            return nil
        end)
        return ok and res or nil
    end
    local function getTowerPosition(tower)
        if not tower then return nil end
        local ok,res = pcall(function() local hrp = tower:FindFirstChild("HumanoidRootPart") if hrp then return hrp.Position end return nil end)
        return ok and res or nil
    end
    local function getTowerRange(tower)
        if not tower then return 0 end
        local ok,res = pcall(function() local stats = tower:FindFirstChild("Stats") if not stats then return 0 end local range = stats:FindFirstChild("Range") if not range then return 0 end return range.Value or 0 end)
        return ok and res or 0
    end
    local function isBossInRange(tower)
        local b = getBossPosition() local t = getTowerPosition(tower)
        if not b or not t then return false end
        local r = getTowerRange(tower) if r <= 0 then return false end
        return (b - t).Magnitude <= r
    end
    local function checkBossInRangeForDuration(tower, requiredDuration)
        if not tower then return false end
        local name = tower.Name
        local currentTime = tick()
        if isBossInRange(tower) then
            if requiredDuration == 0 then return true end
            if not bossInRangeTracker[name] then bossInRangeTracker[name] = currentTime return false else return (currentTime - bossInRangeTracker[name]) >= requiredDuration end
        else
            bossInRangeTracker[name] = nil
        end
        return false
    end

    while true do
        task.wait(0.5)
        if getgenv().AutoAbilitiesEnabled then
            local currentWave = getCurrentWave()
            local hasBoss = bossExists()
            if currentWave < lastWave then resetRoundTrackers() end
            if getgenv().SeamlessLimiterEnabled and lastWave >= 50 and currentWave < 50 then resetRoundTrackers() end
            lastWave = currentWave
            for unitName, abilitiesConfig in pairs(getgenv().UnitAbilities) do
                local tower = Towers:FindFirstChild(unitName)
                if tower then
                    local infoName = getTowerInfoName(tower)
                    local towerLevel = getUpgradeLevel(tower)
                    for abilityName, cfg in pairs(abilitiesConfig) do
                        if cfg.enabled then
                            local shouldUse = true
                            if not hasAbilityBeenUnlocked(infoName, abilityName, towerLevel) then shouldUse=false end
                            if shouldUse and isOnCooldown(infoName, abilityName) then shouldUse=false end
                            if shouldUse and cfg.onlyOnBoss then if not hasBoss or not bossReadyForAbilities() then shouldUse=false end end
                            if shouldUse and cfg.useOnWave and cfg.specificWave then if currentWave ~= cfg.specificWave then shouldUse=false end end
                            if shouldUse and cfg.requireBossInRange then if not hasBoss or not checkBossInRangeForDuration(tower,0) then shouldUse=false end end
                            if shouldUse and cfg.delayAfterBossSpawn then if not hasBoss or not checkBossSpawnTime() then shouldUse=false end end
                            if shouldUse then useAbility(tower, abilityName) setAbilityUsed(infoName, abilityName) end
                        end
                    end
                end
            end
        end
        if isUnloaded then break end
    end
end)

task.spawn(function()
    local function getAvailableCards()
        local playerGui = LocalPlayer.PlayerGui
        local prompt = playerGui:FindFirstChild("Prompt") if not prompt then return nil end
        local frame = prompt:FindFirstChild("Frame") if not frame or not frame:FindFirstChild("Frame") then return nil end
        local cards, cardButtons = {}, {}
        for _, d in pairs(frame:GetDescendants()) do
            if d:IsA("TextLabel") and d.Parent and d.Parent:IsA("Frame") then
                local text = d.Text
                if getgenv().CardPriority[text] then
                    local button = d.Parent.Parent
                    if button:IsA("GuiButton") or button:IsA("TextButton") or button:IsA("ImageButton") then table.insert(cardButtons, {text=text, button=button}) end
                end
            end
        end
        table.sort(cardButtons, function(a,b) return a.button.AbsolutePosition.X < b.button.AbsolutePosition.X end)
        for i, c in ipairs(cardButtons) do cards[i] = { name=c.text, button=c.button } end
        return #cards > 0 and cards or nil
    end
    local function findBestCard(list)
        local bestIndex, bestPriority = 1, math.huge
        for i=1,#list do local nm = list[i].name local p = getgenv().CardPriority[nm] or 999 if p < bestPriority then bestPriority=p bestIndex=i end end
        return bestIndex, list[bestIndex], bestPriority
    end
    local function pressConfirm()
        local ok, confirmButton = pcall(function()
            local prompt = LocalPlayer.PlayerGui:FindFirstChild("Prompt") if not prompt then return nil end
            local frame = prompt:FindFirstChild("Frame") if not frame then return nil end
            local inner = frame:FindFirstChild("Frame") if not inner then return nil end
            local children = inner:GetChildren() if #children < 5 then return nil end
            local button = children[5]:FindFirstChild("TextButton") if not button then return nil end
            local label = button:FindFirstChild("TextLabel") if label and label.Text == "Confirm" then return button end
            return nil
        end)
        if ok and confirmButton then
            local events = {"Activated","MouseButton1Click","MouseButton1Down","MouseButton1Up"}
            for _, ev in ipairs(events) do pcall(function() for _, conn in ipairs(getconnections(confirmButton[ev])) do conn:Fire() end end) end
            return true
        end
        return false
    end
    local function selectCard()
        if not getgenv().CardSelectionEnabled then return false end
        local list = getAvailableCards() if not list then return false end
        local _, best = findBestCard(list)
        local button = best.button
        local events = {"Activated","MouseButton1Click","MouseButton1Down","MouseButton1Up"}
        for _, ev in ipairs(events) do pcall(function() for _, conn in ipairs(getconnections(button[ev])) do conn:Fire() end end) end
        task.wait(0.2)
        pressConfirm()
        return true
    end
    while true do task.wait(1) if getgenv().CardSelectionEnabled then selectCard() end if isUnloaded then break end end
end)

task.spawn(function()
    local function getBossRushCards()
        local playerGui = LocalPlayer.PlayerGui
        local prompt = playerGui:FindFirstChild("Prompt") if not prompt then return nil end
        local frame = prompt:FindFirstChild("Frame") if not frame or not frame:FindFirstChild("Frame") then return nil end
        local cards, cardButtons = {}, {}
        for _, d in pairs(frame:GetDescendants()) do
            if d:IsA("TextLabel") and d.Parent and d.Parent:IsA("Frame") then
                local text = d.Text
                if getgenv().BossRushCardPriority[text] then
                    local button = d.Parent.Parent
                    if button:IsA("GuiButton") or button:IsA("TextButton") or button:IsA("ImageButton") then table.insert(cardButtons, {text=text, button=button}) end
                end
            end
        end
        table.sort(cardButtons, function(a,b) return a.button.AbsolutePosition.X < b.button.AbsolutePosition.X end)
        for i, c in ipairs(cardButtons) do cards[i] = { name=c.text, button=c.button } end
        return #cards > 0 and cards or nil
    end
    local function best(list)
        local idx, bestPriority = 1, math.huge
        for i=1,#list do local nm=list[i].name local p=getgenv().BossRushCardPriority[nm] or 999 if p<bestPriority then bestPriority=p idx=i end end
        return idx, list[idx], bestPriority
    end
    local function confirm()
        local ok, confirmButton = pcall(function()
            local prompt = LocalPlayer.PlayerGui:FindFirstChild("Prompt") if not prompt then return nil end
            local frame = prompt:FindFirstChild("Frame") if not frame then return nil end
            local inner = frame:FindFirstChild("Frame") if not inner then return nil end
            local children = inner:GetChildren() if #children < 5 then return nil end
            local button = children[5]:FindFirstChild("TextButton") if not button then return nil end
            local label = button:FindFirstChild("TextLabel") if label and label.Text == "Confirm" then return button end
            return nil
        end)
        if ok and confirmButton then
            local events={"Activated","MouseButton1Click","MouseButton1Down","MouseButton1Up"}
            for _,ev in ipairs(events) do pcall(function() for _,conn in ipairs(getconnections(confirmButton[ev])) do conn:Fire() end end) end
            return true
        end
        return false
    end
    local function select()
        if not getgenv().BossRushEnabled then return false end
        local list = getBossRushCards() if not list then return false end
        local _, bc, pri = best(list)
        if pri >= 999 then return false end
        local events={"Activated","MouseButton1Click","MouseButton1Down","MouseButton1Up"}
        for _,ev in ipairs(events) do pcall(function() for _,conn in ipairs(getconnections(bc.button[ev])) do conn:Fire() end end) end
        task.wait(0.2)
        confirm()
        return true
    end
    while true do task.wait(1) if getgenv().BossRushEnabled then select() end if isUnloaded then break end end
end)

task.spawn(function()
    local hasRun = 0
    local isProcessing = false
    local function formatNumber(num)
        if not num or num == 0 then return "0" end
        local s = tostring(num) local k
        while true do s,k = string.gsub(s, "^(-?%d+)(%d%d%d)", '%1,%2') if k==0 then break end end
        return s
    end
    local function SendMessageEMBED(url, embed)
        local headers = { ["Content-Type"] = "application/json" }
        local data = { embeds = { { title=embed.title, description=embed.description, color=embed.color, fields=embed.fields, footer=embed.footer, timestamp=os.date("!%Y-%m-%dT%H:%M:%S.000Z") } } }
        local body = HttpService:JSONEncode(data)
        request({ Url=url, Method="POST", Headers=headers, Body=body })
    end
    local function getRewards()
        local rewards = {}
        local ok, res = pcall(function()
            local ui = LocalPlayer.PlayerGui:FindFirstChild("EndGameUI") if not ui then return {} end
            local rewardsHolder = ui:FindFirstChild("BG")
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
                                        local clean = string.gsub(string.gsub(amountText, "x", ""), "+", "")
                                        clean = string.gsub(clean, ",", "")
                                        local n = tonumber(clean)
                                        if n and itemName ~= "" then table.insert(rewards, { name=itemName, amount=n }) end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            return rewards
        end)
        return ok and res or {}
    end
    local function getMatchResult()
        local ok, time, wave, result = pcall(function()
            local ui = LocalPlayer.PlayerGui:FindFirstChild("EndGameUI") if not ui then return "00:00:00","0","Unknown" end
            local c = ui:FindFirstChild("BG") if c then c=c:FindFirstChild("Container") if c then
                local stats = c:FindFirstChild("Stats")
                if stats then
                    local resultText = stats:FindFirstChild("Result")
                    local timeText = stats:FindFirstChild("ElapsedTime")
                    local waveText = stats:FindFirstChild("EndWave")
                    local r = resultText and resultText.Text or "Unknown"
                    local t = timeText and timeText.Text or "00:00:00"
                    local w = waveText and waveText.Text or "0"
                    if t:find("Total Time:") then local m,s = t:match("Total Time:%s*(%d+):(%d+)") if m and s then t = string.format("%02d:%02d:%02d", 0, tonumber(m) or 0, tonumber(s) or 0) end end
                    if w:find("Wave Reached:") then local wm = w:match("Wave Reached:%s*(%d+)") if wm then w = wm end end
                    if r:lower():find("win") or r:lower():find("victory") then r = "VICTORY" elseif r:lower():find("defeat") or r:lower():find("lose") or r:lower():find("loss") then r = "DEFEAT" end
                    return t, w, r
                end
            end end
            return "00:00:00", "0", "Unknown"
        end)
        if ok then return time, wave, result else return "00:00:00","0","Unknown" end
    end
    local function getMapInfo()
        local ok, name, difficulty = pcall(function()
            local map = workspace:FindFirstChild("Map") if not map then return "Unknown Map","Unknown" end
            local mapName = map:FindFirstChild("MapName")
            local mapDifficulty = map:FindFirstChild("MapDifficulty")
            return mapName and mapName.Value or "Unknown Map", mapDifficulty and mapDifficulty.Value or "Unknown"
        end)
        if ok then return name, difficulty else return "Unknown Map","Unknown" end
    end
    local function sendWebhook()
        if not getgenv().WebhookEnabled then return end
        if getgenv()._webhookLock and (tick() - getgenv()._webhookLock) < 10 then return end
        if isProcessing then return end
        if hasRun > 0 and (tick() - hasRun) < 5 then return end
        getgenv()._webhookLock = tick() isProcessing = true hasRun = tick()
        task.wait(0.5)
        local clientData = getClientData() if not clientData then isProcessing=false return end
        local rewards = getRewards()
        local matchTime, matchWave, matchResult = getMatchResult()
        local mapName, mapDifficulty = getMapInfo()
        local description = "**Username:** ||"..LocalPlayer.Name.."||\n**Level:** "..(clientData.Level or 0).." ["..formatNumber(clientData.EXP or 0).."/"..formatNumber(clientData.MaxEXP or 0).."]"
        local stats = "<:jewel:1217525743408648253> "..formatNumber(clientData.Jewels or 0)
        stats = stats .. "\n<:gold:1265957290251522089> " .. formatNumber(clientData.Gold or 0)
        stats = stats .. "\n<:emerald:1389165843966984192> " .. formatNumber(clientData.Emeralds or 0)
        stats = stats .. "\n<:rerollshard:1426315987019501598> " .. formatNumber(clientData.Rerolls or 0)
        stats = stats .. "\n<:candybasket:1426304615284084827> " .. formatNumber(clientData.CandyBasket or 0)
        local bingoStamps = 0
        if clientData.ItemData and clientData.ItemData.HallowenBingoStamp then bingoStamps = clientData.ItemData.HallowenBingoStamp.Amount or 0 end
        stats = stats .. "\n<:bingostamp:1426362482141954068> " .. formatNumber(bingoStamps)
        local rewardsText = ""
        if #rewards > 0 then
            for _, r in ipairs(rewards) do
                local total = 0
                if r.name == "CandyBasket" or r.name == "Candy Basket" then total = (clientData.CandyBasket or 0) + r.amount
                elseif r.name == "HallowenBingoStamp" or r.name:find("Bingo Stamp") then
                    if clientData.ItemData and clientData.ItemData.HallowenBingoStamp then total = (clientData.ItemData.HallowenBingoStamp.Amount or 0) + r.amount else total = r.amount end
                elseif clientData.Items and clientData.Items[r.name] then total = (clientData.Items[r.name].Amount or 0) + r.amount
                elseif clientData[r.name] then total = (clientData[r.name] or 0) + r.amount
                else total = r.amount end
                rewardsText = rewardsText .. "+"..formatNumber(r.amount).." "..r.name.." [ Total: "..formatNumber(total).." ]\n"
            end
        else rewardsText = "No rewards found" end
        local unitsText = ""
        if clientData.Slots then
            local slots = {"Slot1","Slot2","Slot3","Slot4","Slot5","Slot6"}
            for _,slotName in ipairs(slots) do
                local slot = clientData.Slots[slotName]
                if slot and slot.Value then
                    local level = slot.Level or 0
                    local kills = formatNumber(slot.Kills or 0)
                    local unitName = slot.Value
                    unitsText = unitsText .. "[ "..level.." ] "..unitName.." = "..kills.." ⚔️\n"
                end
            end
        end
        local embed = { title="Anime Last Stand", description=description or "N/A", color=0x00ff00, fields={
            { name="Player Stats", value=(stats ~= "" and stats or "N/A"), inline=true },
            { name="Rewards", value=(rewardsText ~= "" and rewardsText or "No rewards found"), inline=true },
            { name="Units", value=(unitsText ~= "" and unitsText or "No units"), inline=false },
            { name="Match Result", value=(matchTime or "00:00:00") .. " - Wave " .. tostring(matchWave or "0") .. "\n" .. (mapName or "Unknown Map") .. ((mapDifficulty and mapDifficulty ~= "Unknown") and (" ["..mapDifficulty.."]") or "") .. " - " .. (matchResult or "Unknown"), inline=false }
        }, footer={ text="Halloween Hook" } }
        SendMessageEMBED(getgenv().WebhookURL, embed)
        isProcessing=false
    end
    LocalPlayer.PlayerGui.ChildAdded:Connect(function(child) if child.Name=="EndGameUI" and getgenv().WebhookEnabled then sendWebhook() end end)
    LocalPlayer.PlayerGui.ChildRemoved:Connect(function(child) if child.Name=="EndGameUI" then task.wait(2) isProcessing=false end end)
end)

task.spawn(function()
    local endgameCount = 0
    local hasRun = false
    repeat task.wait(0.5) until not LocalPlayer.PlayerGui:FindFirstChild("TeleportUI")
    print("[Seamless Fix] Waiting for Settings GUI...")
    repeat task.wait(0.5) until LocalPlayer.PlayerGui:FindFirstChild("Settings")
    print("[Seamless Fix] Settings GUI found!")

    local function getSeamlessValue()
        local settings = LocalPlayer.PlayerGui:FindFirstChild("Settings")
        if settings then
            local seamless = settings:FindFirstChild("SeamlessRetry")
            if seamless then 
                print("[Seamless Fix] SeamlessRetry.Value =", seamless.Value)
                return seamless.Value 
            else
                print("[Seamless Fix] SeamlessRetry not found in Settings")
            end
        else
            print("[Seamless Fix] Settings not found")
        end
        return false
    end
    
    local function setSeamlessRetry()
        pcall(function()
            RS.Remotes.SetSettings:InvokeServer("SeamlessRetry")
        end)
    end
    
    local function restartMatch()
        pcall(function()
            RS.Remotes.RestartMatch:FireServer()
        end)
    end

    print("[Seamless Fix] Checking initial seamless state...")
    local currentSeamless = getSeamlessValue()
    if endgameCount < (getgenv().MaxSeamlessRounds or 4) then
        if not currentSeamless and getgenv().SeamlessLimiterEnabled then
            setSeamlessRetry()
            task.wait(0.5)
            print("[Seamless Fix] Enabled Seamless Retry")
        else
            print("[Seamless Fix] Seamless Retry already enabled")
        end
    end

    LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
        if child.Name == "EndGameUI" and not hasRun then
            if not getgenv().SeamlessLimiterEnabled then return end
            hasRun = true
            endgameCount = endgameCount + 1
            local maxRounds = getgenv().MaxSeamlessRounds or 4
            print("[Seamless Fix] Endgame detected. Current seamless rounds: " .. endgameCount .. "/" .. maxRounds)
            
            if endgameCount >= maxRounds and getSeamlessValue() then
                task.wait(0.5)
                print("[Seamless Fix] Max rounds reached, disabling seamless retry to restart match...")
                setSeamlessRetry()
                print("[Seamless Fix] Disabled Seamless Retry")
                task.wait(0.5)
                if not getSeamlessValue() then
                    restartMatch()
                    print("[Seamless Fix] Restarted match")
                end
            end
        end
    end)
    
    LocalPlayer.PlayerGui.ChildRemoved:Connect(function(child)
        if child.Name == "EndGameUI" then
            hasRun = false
            print("[Seamless Fix] EndgameUI removed, ready for next round")
        end
    end)
end)

task.spawn(function()
    if isInLobby then return end
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
                for i=1,25 do pcall(function() UseStampEvent:FireServer() end) task.wait(0.1) end
                task.wait(0.2)
            end
            if ClaimRewardEvent then
                for i=1,25 do pcall(function() ClaimRewardEvent:InvokeServer(i) end) task.wait(0.1) end
                task.wait(0.2)
            end
            if CompleteBoardEvent then pcall(function() CompleteBoardEvent:InvokeServer() end) task.wait(0.1) end
        end
        if isUnloaded then break end
    end
end)

task.spawn(function()
    if isInLobby then return end
    task.wait()
    local PurchaseEvent = RS:WaitForChild("Events"):WaitForChild("Hallowen2025"):WaitForChild("Purchase")
    local OpenCapsuleEvent = RS:WaitForChild("Remotes"):WaitForChild("OpenCapsule")
    print("[Auto Capsules] Capsule automation loaded!")
    while true do
        task.wait()
        if getgenv().CapsuleEnabled then
            local clientData = getClientData()
            if clientData then
                local candyBasket = clientData.CandyBasket or 0
                local capsuleAmount = 0
                if clientData.ItemData and clientData.ItemData.HalloweenCapsule2025 then
                    capsuleAmount = clientData.ItemData.HalloweenCapsule2025.Amount or 0
                end
                if candyBasket >= 100000 then pcall(function() PurchaseEvent:InvokeServer(1, 100) end) task.wait(1)
                elseif candyBasket >= 10000 then pcall(function() PurchaseEvent:InvokeServer(1, 10) end) task.wait(1)
                elseif candyBasket >= 1000 then pcall(function() PurchaseEvent:InvokeServer(1, 1) end) task.wait(1) end
                task.wait()
                clientData = getClientData()
                if clientData and clientData.ItemData and clientData.ItemData.HalloweenCapsule2025 then capsuleAmount = clientData.ItemData.HalloweenCapsule2025.Amount or 0 end
                if capsuleAmount > 0 then pcall(function() OpenCapsuleEvent:FireServer("HalloweenCapsule2025", capsuleAmount) end) task.wait(1) end
            end
        end
        if isUnloaded then break end
    end
end)

MacLib:LoadAutoLoadConfig()
