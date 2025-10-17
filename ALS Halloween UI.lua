repeat task.wait() until game:IsLoaded()

if getgenv().ALSScriptLoaded then
    warn("[ALS] Script already running! Please restart Roblox to reload.")
    return
end
getgenv().ALSScriptLoaded = true

local MacLib = loadstring(game:HttpGet("https://github.com/biggaboy212/Maclib/releases/latest/download/maclib.txt"))()

if not MacLib then
    error("[ALS] Failed to load MacLib library")
    return
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local VIM = game:GetService("VirtualInputManager")

local isMobile = UserInputService.TouchEnabled
local MOBILE_DELAY_MULTIPLIER = isMobile and 1.5 or 1.0

local CONFIG_FOLDER = "ALSHalloweenEvent"
local CONFIG_FILE = "config.json"
local USER_ID = tostring(LocalPlayer.UserId)

local function getConfigPath()
    return CONFIG_FOLDER .. "/" .. USER_ID .. "/" .. CONFIG_FILE
end

local function getUserFolder()
    return CONFIG_FOLDER .. "/" .. USER_ID
end

local function loadConfig()
    if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
    local userFolder = getUserFolder()
    if not isfolder(userFolder) then makefolder(userFolder) end
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
            data.autoJoin = data.autoJoin or {}
            return data
        end
    end
    return { toggles = {}, inputs = {}, dropdowns = {}, abilities = {}, autoJoin = {} }
end

local function saveConfig(config)
    local userFolder = getUserFolder()
    if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
    if not isfolder(userFolder) then makefolder(userFolder) end
    local ok, err = pcall(function()
        local json = HttpService:JSONEncode(config)
        writefile(getConfigPath(), json)
    end)
    if not ok then warn("[Config] Save failed: " .. tostring(err)) end
    return ok
end

getgenv().Config = loadConfig()
getgenv().Config.toggles = getgenv().Config.toggles or {}
getgenv().Config.inputs = getgenv().Config.inputs or {}
getgenv().Config.dropdowns = getgenv().Config.dropdowns or {}
getgenv().Config.abilities = getgenv().Config.abilities or {}
getgenv().Config.autoJoin = getgenv().Config.autoJoin or {}

getgenv().SaveConfig = saveConfig
getgenv().LoadConfig = loadConfig

local defaultWidth = 720
local defaultHeight = 480
local customWidth = tonumber(getgenv().Config.inputs.UIWidth) or defaultWidth
local customHeight = tonumber(getgenv().Config.inputs.UIHeight) or defaultHeight

if customWidth < 400 or customWidth > 1920 then customWidth = defaultWidth end
if customHeight < 300 or customHeight > 1080 then customHeight = defaultHeight end

print("[UI Size] Creating window with size:", customWidth, "x", customHeight)

local Window = MacLib:Window({
    Title = "Byorl Last Stand",
    Subtitle = "Anime Last Stand Automation",
    Size = UDim2.fromOffset(customWidth, customHeight),
    DragStyle = 1,
    DisabledWindowControls = {},
    ShowUserInfo = true,
    Keybind = Enum.KeyCode.LeftControl,
    AcrylicBlur = true,
})

if not Window then
    error("[ALS] Failed to create Window")
    return
end

Window.onUnloaded(function()
    getgenv().ALSScriptLoaded = false
    getgenv().MacroPlayEnabled = false
    getgenv().MacroRecordingV2 = false
    getgenv().AutoAbilitiesEnabled = false
end)

task.wait(2)

local function isTeleportUIVisible()
    local tpUI = LocalPlayer.PlayerGui:FindFirstChild("TeleportUI")
    if not tpUI then return false end
    
    local ok, visible = pcall(function()
        return tpUI.Enabled
    end)
    return ok and visible
end

local function isPlayerInValidState()
    local character = LocalPlayer.Character
    if not character then return false end
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    return true
end

local maxWaitTime = 0
local maxWait = 20
repeat
    task.wait(0.2)
    maxWaitTime = maxWaitTime + 0.2
until (not isTeleportUIVisible() and isPlayerInValidState()) or maxWaitTime > maxWait

if maxWaitTime > maxWait and not isPlayerInValidState() then
    task.wait(3)
end

task.wait(1)

if not getgenv().Config.hasJoinedDiscord then
    Window:Dialog({
        Title = "Join Our Discord!",
        Description = "Have you joined the Byorl Last Stand Discord server? Get updates, support, and connect with the community!",
        Buttons = {
            {
                Name = "Yes, I'm in!",
                Callback = function()
                    getgenv().Config.hasJoinedDiscord = true
                    saveConfig(getgenv().Config)
                    Window:Notify({
                        Title = "Byorl Last Stand",
                        Description = "Awesome! Thanks for being part of the community!",
                        Lifetime = 3
                    })
                end,
            },
            {
                Name = "Not yet",
                Callback = function()
                    getgenv().Config.hasJoinedDiscord = true
                    saveConfig(getgenv().Config)
                    
                    if setclipboard then
                        setclipboard("https://discord.gg/V3WcdHpd3J")
                    end
                    
                    Window:Notify({
                        Title = "Byorl Last Stand",
                        Description = "Discord link copied! Opening in browser...",
                        Lifetime = 5
                    })
                    
                    task.wait(0.5)
                    
                    local success = pcall(function()
                        if request then
                            request({
                                Url = "https://discord.gg/V3WcdHpd3J",
                                Method = "GET"
                            })
                        end
                    end)
                    
                    if not success then
                        Window:Notify({
                            Title = "Byorl Last Stand",
                            Description = "Link copied to clipboard: discord.gg/V3WcdHpd3J",
                            Lifetime = 5
                        })
                    end
                end,
            }
        }
    })
end

getgenv()._AbilityUIBuilt = false
getgenv()._AbilityUIBuilding = false

local function shouldFilterMessage(msg)
    local msgLower = msg:lower()
    
    if msgLower:find("playermodule") 
        or msgLower:find("cameramodule") 
        or msgLower:find("zoomcontroller")
        or msgLower:find("popper")
        or msgLower:find("poppercam")
        or msgLower:find("imagelabel")
        or msgLower:find("not a valid member")
        or msgLower:find("is not a valid member")
        or msgLower:find("attempt to perform arithmetic")
        or msgLower:find("playerscripts")
        or msgLower:find("byorials")
        or msgLower:find("stack begin")
        or msgLower:find("stack end")
        or msgLower:find("runservice")
        or msgLower:find("firerenderstepearlyfunctions")
        or msgLower:find("firerenderstep")
        or msgLower:find("metamethod")
        or msgLower:find("__namecall")
        or msgLower:find("unexpected error while invoking callback")
        or msgLower:find("frogionsol") then
        return true
    end
    
    return false
end

local oldLogWarn = logwarn or warn
local oldLogError = logerror or error

local function createFilteredLogger(originalLogger)
    return function(...)
        local args = {...}
        local msg = ""
        for i, v in ipairs(args) do
            msg = msg .. tostring(v)
        end
        if not shouldFilterMessage(msg) then
            originalLogger(...)
        end
    end
end

if logwarn then logwarn = createFilteredLogger(oldLogWarn) end
warn = createFilteredLogger(oldLogWarn)
if logerror then logerror = createFilteredLogger(oldLogError) end

local oldErrorHandler = geterrorhandler and geterrorhandler()
if seterrorhandler then
    seterrorhandler(function(msg)
        if not shouldFilterMessage(tostring(msg)) then
            if oldErrorHandler then
                oldErrorHandler(msg)
            else
                oldLogError(msg)
            end
        end
    end)
end

local function cleanupBeforeTeleport()    
    pcall(function()
        if Window and Window.Unload then
            Window:Unload()
        end
    end)
    
    pcall(function()
        getgenv().AutoAbilitiesEnabled = nil
        getgenv().CardSelectionEnabled = nil
        getgenv().SlowerCardSelectionEnabled = nil
    end)
    
    pcall(function()
        if getconnections then
            for _, service in pairs({RunService.Heartbeat, RunService.RenderStepped, RunService.Stepped}) do
                for _, connection in pairs(getconnections(service)) do
                    if connection.Disable then connection:Disable() end
                    if connection.Disconnect then connection:Disconnect() end
                end
            end
        end
    end)
    
    pcall(function()
        collectgarbage("collect")
    end)
    
    task.wait(0.2)
end

getgenv().CleanupBeforeTeleport = cleanupBeforeTeleport


MacLib:SetFolder("ALSHalloweenEvent")



local TabGroup1 = Window:TabGroup()

local TabGroup2 = Window:TabGroup()

local TabGroup3 = Window:TabGroup()

local Tabs = {
    Main = TabGroup1:Tab({ 
        Name = "Main", 
        Image = "rbxassetid://10734950309" 
    }),
    Macro = TabGroup1:Tab({ 
        Name = "Macro", 
        Image = "rbxassetid://10734923549" 
    }),
    Abilities = TabGroup1:Tab({ 
        Name = "Abilities", 
        Image = "rbxassetid://10747373176" 
    }),
    Portals = TabGroup1:Tab({ 
        Name = "Portals", 
        Image = "rbxassetid://10723407389" 
    }),
    
    Event = TabGroup2:Tab({ 
        Name = "Event", 
        Image = "rbxassetid://10734952273" 
    }),
    BossRush = TabGroup2:Tab({ 
        Name = "Boss Rush", 
        Image = "rbxassetid://10734923549" 
    }),
    Breach = TabGroup2:Tab({ 
        Name = "Breach", 
        Image = "rbxassetid://10747374131" 
    }),
    FinalExpedition = TabGroup2:Tab({ 
        Name = "Final Expedition", 
        Image = "rbxassetid://10723407389" 
    }),
    
    Webhook = TabGroup3:Tab({ 
        Name = "Webhook", 
        Image = "rbxassetid://10734952273" 
    }),
    SeamlessFix = TabGroup3:Tab({ 
        Name = "Seamless Fix", 
        Image = "rbxassetid://10734923549" 
    }),
    Misc = TabGroup3:Tab({ 
        Name = "Misc", 
        Image = "rbxassetid://10734949856" 
    }),
    Settings = TabGroup3:Tab({ 
        Name = "Settings", 
        Image = "rbxassetid://10734949856" 
    })
}

local ToggleGui = Instance.new("ScreenGui")
ToggleGui.Name = "ALS_Fluent_Toggle"
ToggleGui.ResetOnSpawn = false
ToggleGui.IgnoreGuiInset = true
ToggleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ToggleGui.Parent = game:GetService("CoreGui")

local ToggleButton = Instance.new("ImageButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0, 75, 0, 75)
ToggleButton.Position = UDim2.new(0, 24, 0, 24)
ToggleButton.AnchorPoint = Vector2.new(0, 0)
ToggleButton.BackgroundTransparency = 1
ToggleButton.Image = "rbxassetid://72399447876912"
ToggleButton.Active = true
ToggleButton.Draggable = true
ToggleButton.Parent = ToggleGui

local function toggleUI()
    VIM:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
    task.wait(0.05)
    VIM:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
end
ToggleButton.MouseButton1Click:Connect(toggleUI)

local Sections = {
    MainLeft = Tabs.Main:Section({ Side = "Left" }),
    MainRight = Tabs.Main:Section({ Side = "Right" }),
    
    MacroLeft = Tabs.Macro:Section({ Side = "Left" }),
    MacroRight = Tabs.Macro:Section({ Side = "Right" }),
    
    PortalsLeft = Tabs.Portals:Section({ Side = "Left" }),
    PortalsRight = Tabs.Portals:Section({ Side = "Right" }),
    
    BossRushLeft = Tabs.BossRush:Section({ Side = "Left" }),
    BossRushRight = Tabs.BossRush:Section({ Side = "Right" }),
    
    BreachLeft = Tabs.Breach:Section({ Side = "Left" }),
    BreachRight = Tabs.Breach:Section({ Side = "Right" }),
    
    FinalExpeditionLeft = Tabs.FinalExpedition:Section({ Side = "Left" }),
    FinalExpeditionRight = Tabs.FinalExpedition:Section({ Side = "Right" }),
    
    EventLeft = Tabs.Event:Section({ Side = "Left" }),
    EventRight = Tabs.Event:Section({ Side = "Right" }),
    
    WebhookLeft = Tabs.Webhook:Section({ Side = "Left" }),
    
    SeamlessFixLeft = Tabs.SeamlessFix:Section({ Side = "Left" }),
    
    MiscLeft = Tabs.Misc:Section({ Side = "Left" }),
    MiscRight = Tabs.Misc:Section({ Side = "Right" }),
    
    SettingsLeft = Tabs.Settings:Section({ Side = "Left" }),
    SettingsRight = Tabs.Settings:Section({ Side = "Right" })
}

Tabs.Main:Select()


local function createToggle(section, name, flag, callback, default)
    name = tostring(name or "Toggle")
    default = default or false
    local savedValue = getgenv().Config.toggles[flag]
    if savedValue == nil then
        savedValue = default
    end
    
    return section:Toggle({
        Name = name,
        Default = savedValue,
        Callback = function(value)
            getgenv().Config.toggles[flag] = value
            saveConfig(getgenv().Config)
            if callback then 
                callback(value) 
            end
        end,
    }, flag)
end

local function createToggleNoSave(section, name, flag, callback, default)
    name = tostring(name or "Toggle")
    default = default or false
    
    return section:Toggle({
        Name = name,
        Default = default,
        Callback = function(value)
            if callback then 
                callback(value) 
            end
        end,
    }, flag)
end

local function createInput(section, name, flag, placeholder, charType, callback, default)
    name = tostring(name or "Input")
    placeholder = placeholder or ""
    charType = charType or "All"
    default = default or ""
    
    local savedValue = getgenv().Config.inputs[flag]
    if savedValue == nil then
        savedValue = default
    end
    
    local inputElement = section:Input({
        Name = name,
        Placeholder = placeholder,
        AcceptedCharacters = charType,
        Callback = function(value)
            getgenv().Config.inputs[flag] = value
            saveConfig(getgenv().Config)
            if callback then 
                callback(value) 
            end
        end,
    }, flag)
    
    if savedValue and savedValue ~= "" then
        pcall(function()
            inputElement:UpdateText(tostring(savedValue))
        end)
    end
    
    return inputElement
end

local function createDropdown(section, name, flag, options, multi, callback, default)
    name = tostring(name or "Dropdown")
    options = options or {}
    multi = multi or false
    default = default or (multi and {} or 1)
    
    local savedValue = getgenv().Config.dropdowns[flag]
    if savedValue == nil then
        savedValue = default
    end
    
    
    local defaultValue = savedValue
    if multi and type(savedValue) == "table" then
        local isDictionary = false
        for k, v in pairs(savedValue) do
            if type(v) == "boolean" then
                isDictionary = true
                break
            end
        end
        
        if isDictionary then
            defaultValue = {}
            for optionName, isSelected in pairs(savedValue) do
                if isSelected == true then
                    table.insert(defaultValue, optionName)
                end
            end
        end
    elseif not multi and type(savedValue) == "string" then
        defaultValue = 1
        for i, option in ipairs(options) do
            if option == savedValue then
                defaultValue = i
                break
            end
        end
    elseif not multi and type(savedValue) == "number" then
        defaultValue = savedValue
    end
    
    
    return section:Dropdown({
        Name = name,
        Options = options,
        Multi = multi,
        Required = false,
        Default = defaultValue,
        Callback = function(value)
            getgenv().Config.dropdowns[flag] = value
            saveConfig(getgenv().Config)
            if callback then 
                callback(value) 
            end
        end,
    }, flag)
end

local function createSlider(section, name, flag, minimum, maximum, default, callback, displayMethod)
    name = tostring(name or "Slider")
    minimum = minimum or 0
    maximum = maximum or 100
    default = default or minimum
    displayMethod = displayMethod or "Default"
    
    local savedValue = getgenv().Config.inputs[flag]
    if savedValue ~= nil then
        savedValue = tonumber(savedValue)
        if savedValue then
            default = savedValue
        end
    end
    
    return section:Slider({
        Name = name,
        Minimum = minimum,
        Maximum = maximum,
        Default = default,
        DisplayMethod = displayMethod,
        Callback = function(value)
            getgenv().Config.inputs[flag] = value
            saveConfig(getgenv().Config)
            if callback then 
                callback(value) 
            end
        end,
    }, flag)
end

local function createMutuallyExclusiveToggle(section, name, flag, otherToggle, otherFlag, callback, default)
    local toggle = createToggle(
        section,
        name,
        flag,
        function(value)
            if callback then callback(value) end
            
            if value and otherToggle then
                getgenv().Config.toggles[otherFlag] = false
                saveConfig(getgenv().Config)
                pcall(function()
                    otherToggle:UpdateState(false)
                end)
            end
        end,
        default
    )
    return toggle
end

local function createCardPriorityInputs(section, cardTable, targetPriorityTable, keyPrefix)
    if not cardTable or type(cardTable) ~= "table" then return end
    keyPrefix = keyPrefix or "Card_"
    
    local cardNames = {}
    for name in pairs(cardTable) do
        if name and name ~= "" then
            table.insert(cardNames, name)
        end
    end
    table.sort(cardNames, function(a, b)
        return (cardTable[a] or 999) < (cardTable[b] or 999)
    end)
    
    for _, cardName in ipairs(cardNames) do
        if cardName and cardName ~= "" then
            local configKey = keyPrefix .. tostring(cardName)
            local defaultValue = getgenv().Config.inputs[configKey] or tostring(cardTable[cardName] or 999)
            
            createInput(
                section,
                tostring(cardName),
                configKey,
                "Priority (1-999)",
                "Numeric",
                function(value)
                    local num = tonumber(value)
                    if num then
                        targetPriorityTable[cardName] = num
                    end
                end,
                tostring(defaultValue)
            )
            
            targetPriorityTable[cardName] = tonumber(defaultValue) or cardTable[cardName] or 999
        end
    end
end

getgenv().CreateToggle = createToggle
getgenv().CreateInput = createInput
getgenv().CreateDropdown = createDropdown
getgenv().CreateSlider = createSlider
getgenv().CreateMutuallyExclusiveToggle = createMutuallyExclusiveToggle


local MACRO_FOLDER = CONFIG_FOLDER .. "/macros"
local SETTINGS_FILE = MACRO_FOLDER .. "/settings.json"

if not isfolder(MACRO_FOLDER) then makefolder(MACRO_FOLDER) end

getgenv().Macros = {}
getgenv().MacroMaps = {}

local function loadMacroSettings()
    local settings = {
        playMacroEnabled = false,
        selectedMacro = nil,
        macroMaps = {},
        stepDelay = 0
    }
    pcall(function()
        if isfile(SETTINGS_FILE) then
            local data = HttpService:JSONDecode(readfile(SETTINGS_FILE))
            if type(data) == "table" then
                settings = data
            end
        end
    end)
    return settings
end

local function saveMacroSettings()
    pcall(function()
        local settings = {
            playMacroEnabled = getgenv().MacroPlayEnabled or false,
            selectedMacro = getgenv().CurrentMacro,
            macroMaps = getgenv().MacroMaps or {},
            stepDelay = getgenv().MacroStepDelay or 0
        }
        writefile(SETTINGS_FILE, HttpService:JSONEncode(settings))
    end)
end

local function loadMacros()
    getgenv().Macros = {}
    if not isfolder(MACRO_FOLDER) then return end
    local files = listfiles(MACRO_FOLDER)
    if not files then return end
    for _, file in pairs(files) do
        if file:sub(-5) == ".json" then
            local fileName = file:match("([^/\\]+)%.json$")
            
            if fileName ~= "settings" and fileName ~= "playback_state" then
                local ok, data = pcall(function() 
                    return HttpService:JSONDecode(readfile(file)) 
                end)
                if ok and type(data) == "table" then
                    local isSettings = (data.playMacroEnabled ~= nil or data.selectedMacro ~= nil or data.macroMaps ~= nil)
                    if not isSettings then
                        getgenv().Macros[fileName] = data
                    end
                end
            end
        end
    end
end

local function saveMacro(name, data)
    local success, err = pcall(function()
        writefile(MACRO_FOLDER .. "/" .. name .. ".json", HttpService:JSONEncode(data))
        getgenv().Macros[name] = data
    end)
    if not success then
        warn("[Macro] Failed to save:", err)
    end
    return success
end

local function getMacroNames()
    local names = {}
    for name in pairs(getgenv().Macros) do 
        table.insert(names, name) 
    end
    table.sort(names)
    return names
end

local savedMacroSettings = loadMacroSettings()
getgenv().MacroMaps = savedMacroSettings.macroMaps or {}
getgenv().MacroStepDelay = savedMacroSettings.stepDelay or 0
getgenv().CurrentMacro = savedMacroSettings.selectedMacro

getgenv().MacroPlayEnabled = getgenv().Config.toggles.MacroPlayToggle or false

loadMacros()

getgenv().LoadMacroSettings = loadMacroSettings
getgenv().SaveMacroSettings = saveMacroSettings
getgenv().LoadMacros = loadMacros
getgenv().SaveMacro = saveMacro
getgenv().GetMacroNames = getMacroNames

getgenv().MacroStatusText = "Idle"
getgenv().MacroActionText = ""
getgenv().MacroUnitText = ""
getgenv().MacroWaitingText = ""
getgenv().MacroCurrentStep = 0
getgenv().MacroTotalSteps = 0
getgenv().MacroLastStatusUpdate = 0

getgenv().UpdateMacroStatus = function()
    local now = tick()
    if now - getgenv().MacroLastStatusUpdate < 0.033 then 
        return 
    end
    getgenv().MacroLastStatusUpdate = now
    
    pcall(function()
        if getgenv().MacroStatusLabel and getgenv().MacroStatusLabel.UpdateName then
            local statusText = tostring(getgenv().MacroStatusText or "Idle")
            getgenv().MacroStatusLabel:UpdateName("Status: " .. statusText)
        end
        
        if getgenv().MacroStepLabel and getgenv().MacroStepLabel.UpdateName then
            local currentStep = tonumber(getgenv().MacroCurrentStep) or 0
            local totalSteps = tonumber(getgenv().MacroTotalSteps) or 0
            getgenv().MacroStepLabel:UpdateName("📝 Step: " .. currentStep .. "/" .. totalSteps)
        end
        
        if getgenv().MacroActionLabel and getgenv().MacroActionLabel.UpdateName then
            local actionText = (getgenv().MacroActionText and tostring(getgenv().MacroActionText) ~= "") and tostring(getgenv().MacroActionText) or "None"
            getgenv().MacroActionLabel:UpdateName("⚡ Action: " .. actionText)
        end
        
        if getgenv().MacroUnitLabel and getgenv().MacroUnitLabel.UpdateName then
            local unitText = (getgenv().MacroUnitText and tostring(getgenv().MacroUnitText) ~= "") and tostring(getgenv().MacroUnitText) or "None"
            getgenv().MacroUnitLabel:UpdateName("🗼 Unit: " .. unitText)
        end
        
        if getgenv().MacroWaitingLabel and getgenv().MacroWaitingLabel.UpdateName then
            local waitingText = (getgenv().MacroWaitingText and tostring(getgenv().MacroWaitingText) ~= "") and tostring(getgenv().MacroWaitingText) or "None"
            getgenv().MacroWaitingLabel:UpdateName("⏳ Waiting: " .. waitingText)
        end
    end)
end


getgenv().MacroCurrentCash = 0
getgenv().MacroLastCash = 0
getgenv().MacroCashHistory = {}
local MAX_CASH_HISTORY = 30

task.spawn(function()
    while true do
        RunService.Heartbeat:Wait()
        pcall(function()
            getgenv().MacroCurrentCash = LocalPlayer.Cash.Value
        end)
    end
end)

local cashTrackingActive = false
local function trackCash()
    if cashTrackingActive then return end
    cashTrackingActive = true
    
    task.spawn(function()
        while true do
            RunService.Heartbeat:Wait()
            
            local currentCash = 0
            pcall(function()
                currentCash = tonumber(LocalPlayer.Cash.Value) or 0
            end)
            
            local lastCash = tonumber(getgenv().MacroLastCash) or 0
            if lastCash > 0 and currentCash < lastCash then
                local decrease = lastCash - currentCash
                table.insert(getgenv().MacroCashHistory, 1, {
                    time = tick(),
                    decrease = decrease,
                    before = lastCash,
                    after = currentCash
                })
                
                if #getgenv().MacroCashHistory > MAX_CASH_HISTORY then
                    table.remove(getgenv().MacroCashHistory, #getgenv().MacroCashHistory)
                end
            end
            
            getgenv().MacroLastCash = currentCash
        end
    end)
end

getgenv().GetRecentCashDecrease = function(withinSeconds)
    withinSeconds = withinSeconds or 1
    local now = tick()
    for _, entry in ipairs(getgenv().MacroCashHistory) do
        if (now - entry.time) <= withinSeconds then
            return entry.decrease
        end
    end
    return 0
end

getgenv().GetPlaceCost = function(towerName)
    if not getgenv().MacroTowerInfoCache then
        return 0
    end
    
    if not getgenv().MacroTowerInfoCache[towerName] then 
        return 0 
    end
    
    if getgenv().MacroTowerInfoCache[towerName][0] then
        return getgenv().MacroTowerInfoCache[towerName][0].Cost or 0
    end
    
    return 0
end

getgenv().GetUpgradeCost = function(towerName, currentLevel)
    if not getgenv().MacroTowerInfoCache then
        return 0
    end
    
    if not getgenv().MacroTowerInfoCache[towerName] then 
        return 0 
    end
    
    local nextLevel = (currentLevel or 0) + 1
    if getgenv().MacroTowerInfoCache[towerName][nextLevel] then
        return getgenv().MacroTowerInfoCache[towerName][nextLevel].Cost or 0
    end
    
    return 0
end

trackCash()


local function isKilled()
    return getgenv().MacroSystemKillSwitch == true
end

getgenv().IsKilled = isKilled

getgenv().MacroTowerInfoCache = {}
getgenv().MacroRemoteCache = {}

local function cacheTowerInfo()
    if next(getgenv().MacroTowerInfoCache) then return end
    
    pcall(function()
        local towerInfoPath = RS:WaitForChild("Modules"):WaitForChild("TowerInfo")
        for _, mod in pairs(towerInfoPath:GetChildren()) do
            if mod:IsA("ModuleScript") then
                local ok, data = pcall(function() 
                    return require(mod) 
                end)
                if ok then 
                    getgenv().MacroTowerInfoCache[mod.Name] = data 
                end
            end
        end
    end)
end


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
    if not unitName or unitName == "" then return {} end
    local towerNameToCheck = unitName
    if unitName == "TuskSummon_Act4" then towerNameToCheck = "JohnnyGodly" end
    local towerInfo = getTowerInfo(towerNameToCheck)
    if not towerInfo then return {} end
    local abilities = {}
    
    for level = 0, 50 do
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
                    abilities[nm] = {
                        name = nm,
                        cooldown = a.Cd,
                        requiredLevel = level,
                        isGlobal = a.IsCdGlobal or false,
                        isAttribute = hasRealAttribute
                    }
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
                        abilities[nm] = {
                            name = nm,
                            cooldown = a.Cd,
                            requiredLevel = level,
                            isGlobal = a.IsCdGlobal or false,
                            isAttribute = hasRealAttribute
                        }
                    end
                end
            end
        end
    end
    
    return abilities
end

getgenv().AutoAbilitiesEnabled = getgenv().Config.toggles.AutoAbilityToggle or false
getgenv().UnitAbilities = getgenv().UnitAbilities or {}

getgenv().AutoReadyEnabled = getgenv().Config.toggles.AutoReady or false
getgenv().AutoNextEnabled = getgenv().Config.toggles.AutoNext or false
getgenv().AutoLeaveEnabled = getgenv().Config.toggles.AutoLeave or false
getgenv().AutoFastRetryEnabled = getgenv().Config.toggles.AutoRetry or false
getgenv().AutoSmartEnabled = getgenv().Config.toggles.AutoSmart or false

getgenv().AutoEventEnabled = getgenv().Config.toggles.AutoEventToggle or false
getgenv().BingoEnabled = getgenv().Config.toggles.BingoToggle or false
getgenv().CapsuleEnabled = getgenv().Config.toggles.CapsuleToggle or false

getgenv().RemoveEnemiesEnabled = getgenv().Config.toggles.RemoveEnemiesToggle or false
getgenv().AntiAFKEnabled = getgenv().Config.toggles.AntiAFKToggle or false
getgenv().BlackScreenEnabled = getgenv().Config.toggles.BlackScreenToggle or false
getgenv().FPSBoostEnabled = getgenv().Config.toggles.FPSBoostToggle or false

getgenv().SeamlessFixEnabled = getgenv().Config.toggles.SeamlessFixToggle or false
getgenv().SeamlessRounds = tonumber(getgenv().Config.inputs.SeamlessRounds) or 4
getgenv().AutoExecuteTeleportEnabled = getgenv().Config.toggles.AutoExecuteTeleport or false
getgenv().AutoExecuteEnabled = getgenv().Config.toggles.AutoExecuteToggle or false

local queueteleport = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)

if getgenv().AutoExecuteEnabled and queueteleport then
    local TeleportCheck = false
    LocalPlayer.OnTeleport:Connect(function(State)
        if getgenv().AutoExecuteEnabled and (not TeleportCheck) and queueteleport then
            TeleportCheck = true
            queueteleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/Byorl/ALS-Scripts/refs/heads/main/Maclib.lua"))()')
            print("[ALS] Auto Execute queued for next game")
        end
    end)
    print("[ALS] Auto Execute on Teleport enabled")
elseif getgenv().AutoExecuteEnabled and not queueteleport then
    warn("[ALS] Auto Execute enabled but queue_on_teleport function not found in your executor")
end

if getgenv().SeamlessFixEnabled then
    task.spawn(function()
        task.wait(2)
        pcall(function()
            local remotes = RS:FindFirstChild("Remotes")
            local setSettings = remotes and remotes:FindFirstChild("SetSettings")
            if setSettings then 
                setSettings:InvokeServer("SeamlessRetry")
            end
        end)
    end)
end

getgenv().WebhookEnabled = getgenv().Config.toggles.WebhookToggle or false
getgenv().WebhookProcessing = false

getgenv().GetClientData = getClientData
getgenv().GetTowerInfo = getTowerInfo
getgenv().GetAllAbilities = getAllAbilities

local function cacheRemotes()
    if next(getgenv().MacroRemoteCache) then return true end
    
    pcall(function()
        for _, v in pairs(RS:GetDescendants()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                getgenv().MacroRemoteCache[v.Name:lower()] = v
            end
        end
    end)
    
    local count = 0
    for _ in pairs(getgenv().MacroRemoteCache) do 
        count = count + 1 
    end
    
    return count > 0
end

local function ensureCachesReady()
    cacheTowerInfo()
    
    local attempts = 0
    while not cacheRemotes() and attempts < 10 do
        task.wait(0.5)
        attempts = attempts + 1
    end
    
    if attempts >= 10 then
        warn("[Macro] Warning: Remote cache may be incomplete")
    end
end

getgenv().CacheTowerInfo = cacheTowerInfo
getgenv().CacheRemotes = cacheRemotes
getgenv().EnsureCachesReady = ensureCachesReady

task.spawn(function()
    task.wait(2)
    ensureCachesReady()
end)


getgenv().MacroGameState = {
    currentWave = 0,
    isInGame = false,
    hasStartButton = false,
    hasEndGameUI = false,
    gameEnded = false,
    lastWaveChange = 0,
    matchStartTime = 0,
    lastGameEndedState = false
}

local function updateGameState()
    pcall(function()
        local wave = RS:FindFirstChild("Wave")
        if wave and wave.Value then
            local newWave = wave.Value
            if newWave ~= getgenv().MacroGameState.currentWave then
                getgenv().MacroGameState.lastWaveChange = tick()
                getgenv().MacroGameState.currentWave = newWave
            end
        end
        
        local hasStart = false
        pcall(function()
            local bottom = LocalPlayer.PlayerGui:FindFirstChild("Bottom")
            if bottom and bottom:FindFirstChild("Frame") then
                for _, child in ipairs(bottom.Frame:GetChildren()) do
                    if child:IsA("Frame") then
                        for _, subChild in ipairs(child:GetChildren()) do
                            if subChild:IsA("TextButton") and subChild.Visible then
                                for _, element in ipairs(subChild:GetChildren()) do
                                    if element:IsA("TextLabel") and element.Text == "Start" then
                                        hasStart = true
                                        return
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
        getgenv().MacroGameState.hasStartButton = hasStart
        
        local endGameUI = LocalPlayer.PlayerGui:FindFirstChild("EndGameUI")
        getgenv().MacroGameState.hasEndGameUI = endGameUI and endGameUI.Enabled or false
        
        local gameEndedValue = RS:FindFirstChild("GameEnded")
        local currentGameEnded = gameEndedValue and gameEndedValue.Value or false
        
        if currentGameEnded and not getgenv().MacroGameState.lastGameEndedState then
            getgenv().MacroGameState.gameEnded = true
            
            getgenv().BulmaWishUsedThisRound = false
            getgenv().WukongTrackedClones = {}
            getgenv()._WukongLastSynthesisTime = 0
        end
        
        getgenv().MacroGameState.lastGameEndedState = currentGameEnded
        getgenv().MacroGameState.isInGame = not getgenv().MacroGameState.hasStartButton and not getgenv().MacroGameState.hasEndGameUI and not currentGameEnded
    end)
end

task.spawn(function()
    while true do
        RunService.Heartbeat:Wait()
        updateGameState()
    end
end)

getgenv().MacroRecordingV2 = false
getgenv().MacroDataV2 = {}
getgenv().MacroRecordingStartTime = 0

local towerTracker = {
    placeCounts = {},
    upgradeLevels = {},
    lastPlaceTime = {},
    lastUpgradeTime = {},
    pendingActions = {},
    upgradeConnections = {}
}

local function setupTowerUpgradeListener(tower)
    
    if not tower:FindFirstChild("Upgrade") then 
        print("[Macro Debug] ✗ Tower has no Upgrade child:", tower.Name)
        return 
    end
    
    if towerTracker.upgradeConnections[tower] then 
        print("[Macro Debug] ✗ Listener already exists for:", tower.Name)
        return 
    end
    
    local currentLevel = tower.Upgrade.Value
    towerTracker.upgradeLevels[tower] = currentLevel
    print("[Macro Debug] ✓ Setting up upgrade listener for:", tower.Name, "Initial level:", currentLevel)
    
    local connection = tower.Upgrade:GetPropertyChangedSignal("Value"):Connect(function()
        if not getgenv().MacroRecordingV2 then return end
        
        local success, err = pcall(function()
            if not tower or not tower.Parent or not tower:FindFirstChild("Upgrade") then 
                print("[Macro Debug] Tower or Upgrade missing")
                return 
            end
            
            local towerName = tower.Name
            local currentLevel = tower.Upgrade.Value
            local now = tick()
            
            print("[Macro Debug] Upgrade detected:", towerName, "Level:", currentLevel)
            
            if towerName == "NarutoBaryonClone" or towerName == "WukongClone" then
                print("[Macro Debug] Skipping clone upgrade")
                return
            end
            
            local oldLevel = towerTracker.upgradeLevels[tower] or 0
            if currentLevel <= oldLevel then
                print("[Macro Debug] Level not increased (Old:", oldLevel, "New:", currentLevel, "), skipping")
                return
            end
            
            local levelsGained = currentLevel - oldLevel
            print("[Macro Debug] Levels gained:", levelsGained, "Old:", oldLevel, "New:", currentLevel)
            
            towerTracker.upgradeLevels[tower] = currentLevel
            towerTracker.lastUpgradeTime[tower] = now
            
            for i = 1, levelsGained do
                local upgradeLevel = oldLevel + i - 1
                local cost = 0
                
                if getgenv().GetUpgradeCost then
                    cost = getgenv().GetUpgradeCost(towerName, upgradeLevel)
                end
                
                if cost == 0 and getgenv().GetRecentCashDecrease then
                    cost = getgenv().GetRecentCashDecrease(0.3)
                end
                
                print("[Macro Record] Upgraded:", towerName, "Level:", upgradeLevel, "→", upgradeLevel + 1, "Cost:", cost)
                
                table.insert(getgenv().MacroDataV2, {
                    RemoteName = "Upgrade",
                    Args = {},
                    Time = now - getgenv().MacroRecordingStartTime,
                    IsInvoke = true,
                    Cost = cost,
                    TowerName = towerName,
                    ActionType = "Upgrade",
                    Wave = getgenv().MacroGameState.currentWave
                })
            end
            
            getgenv().MacroStatusText = "Recording"
            getgenv().MacroCurrentStep = #getgenv().MacroDataV2
            getgenv().MacroTotalSteps = #getgenv().MacroDataV2
            getgenv().MacroActionText = "Upgrade"
            getgenv().MacroUnitText = towerName
            
            task.spawn(function()
                if getgenv().UpdateMacroStatus then
                    getgenv().UpdateMacroStatus()
                end
            end)
            
            print("[Macro Debug] ✓ Recorded", levelsGained, "upgrade(s) for", towerName, "- Total steps:", #getgenv().MacroDataV2)
        end)
        
        if not success then
            warn("[Macro Debug] Error in upgrade listener:", err)
        end
    end)
    
    towerTracker.upgradeConnections[tower] = connection
    
    tower.AncestryChanged:Connect(function()
        if not tower:IsDescendantOf(game) then
            if towerTracker.upgradeConnections[tower] then
                towerTracker.upgradeConnections[tower]:Disconnect()
                towerTracker.upgradeConnections[tower] = nil
            end
        end
    end)
end

task.spawn(function()    
    workspace.Towers.ChildAdded:Connect(function(tower)
        print("[Macro Debug] Tower added to workspace:", tower.Name)
        
        task.spawn(function()
            local maxAttempts = 10
            for attempt = 1, maxAttempts do
                task.wait(0.1)
                
                if tower:FindFirstChild("Owner") then
                    if tower.Owner.Value == LocalPlayer then
                        print("[Macro Debug] ✓ New tower added:", tower.Name, "(attempt", attempt .. ")")
                        setupTowerUpgradeListener(tower)
                        return
                    else
                        print("[Macro Debug] Tower not owned by player:", tower.Name)
                        return
                    end
                end
                
                if attempt == maxAttempts then
                    print("[Macro Debug] ✗ Timeout waiting for Owner on:", tower.Name)
                end
            end
        end)
    end)
    
    task.wait(0.5)
    for _, tower in pairs(workspace.Towers:GetChildren()) do
        if tower:FindFirstChild("Owner") and tower.Owner.Value == LocalPlayer then
            print("[Macro Debug] Found existing tower:", tower.Name)
            setupTowerUpgradeListener(tower)
        else
            print("[Macro Debug] Skipping tower (not owned):", tower.Name)
        end
    end
    print("[Macro Debug] Finished setting up listeners for existing towers")
end)

local originalNamecall
local namecallHook

local function processRemoteCall(remoteName, method, args)
    local now = tick()
    local remoteNameLower = remoteName:lower()
    
    if remoteNameLower:find("place") or remoteNameLower:find("tower") then
        if args[1] and type(args[1]) == "string" then
            local towerName = args[1]
            
            if towerTracker.lastPlaceTime[towerName] and (now - towerTracker.lastPlaceTime[towerName]) < 0.5 then
                return
            end
            
            towerTracker.lastPlaceTime[towerName] = now
            task.wait(0.7)
            
            local countBefore = towerTracker.placeCounts[towerName] or 0
            local countAfter = 0
            
            for _, tower in pairs(workspace.Towers:GetChildren()) do
                if tower.Name == towerName and tower:FindFirstChild("Owner") and tower.Owner.Value == LocalPlayer then
                    countAfter = countAfter + 1
                end
            end
            
            if countAfter > countBefore then
                local cost = getgenv().GetRecentCashDecrease and getgenv().GetRecentCashDecrease(0.3) or 0
                if cost == 0 and getgenv().GetPlaceCost then
                    cost = getgenv().GetPlaceCost(towerName)
                end
                
                local savedArgs = {args[1]}
                if args[2] and typeof(args[2]) == "CFrame" then
                    savedArgs[2] = {args[2]:GetComponents()}
                end
                
                table.insert(getgenv().MacroDataV2, {
                    RemoteName = remoteName,
                    Args = savedArgs,
                    Time = now - getgenv().MacroRecordingStartTime,
                    IsInvoke = (method == "InvokeServer"),
                    Cost = cost,
                    TowerName = towerName,
                    ActionType = "Place",
                    Wave = getgenv().MacroGameState.currentWave
                })
                
                towerTracker.placeCounts[towerName] = countAfter
                
                getgenv().MacroStatusText = "Recording"
                getgenv().MacroCurrentStep = #getgenv().MacroDataV2
                getgenv().MacroTotalSteps = #getgenv().MacroDataV2
                getgenv().MacroActionText = "Place"
                getgenv().MacroUnitText = towerName
                
                if getgenv().UpdateMacroStatus then
                    getgenv().UpdateMacroStatus()
                end
                
            end
        end
    end
    
    if remoteNameLower:find("upgrade") then
        if args[1] and typeof(args[1]) == "Instance" then
            local tower = args[1]
            local towerName = tower.Name
            
            if towerName ~= "NarutoBaryonClone" and towerName ~= "WukongClone" then
                local upgradeKey = tower .. "_" .. now
                if not towerTracker.pendingActions[upgradeKey] then
                    towerTracker.pendingActions[upgradeKey] = true
                    
                    task.spawn(function()
                        if towerTracker.pendingActions[upgradeKey] then
                            local currentLevel = 0
                            pcall(function()
                                if tower and tower:FindFirstChild("Upgrade") then
                                    currentLevel = tower.Upgrade.Value
                                end
                            end)
                            
                            local cost = 0
                            if getgenv().GetUpgradeCost then
                                cost = getgenv().GetUpgradeCost(towerName, currentLevel)
                            end
                            
                            if cost == 0 and getgenv().GetRecentCashDecrease then
                                cost = getgenv().GetRecentCashDecrease(0.3)
                            end
                            
                            table.insert(getgenv().MacroDataV2, {
                                RemoteName = "Upgrade",
                                Args = {nil},
                                Time = now - getgenv().MacroRecordingStartTime,
                                IsInvoke = (method == "InvokeServer"),
                                Cost = cost,
                                TowerName = towerName,
                                ActionType = "Upgrade",
                                Wave = getgenv().MacroGameState.currentWave
                            })
                            
                            getgenv().MacroStatusText = "Recording"
                            getgenv().MacroCurrentStep = #getgenv().MacroDataV2
                            getgenv().MacroTotalSteps = #getgenv().MacroDataV2
                            getgenv().MacroActionText = "Upgrade"
                            getgenv().MacroUnitText = towerName
                            
                            if getgenv().UpdateMacroStatus then
                                getgenv().UpdateMacroStatus()
                            end
                            
                            print("[Macro Debug] Upgrade recorded via remote hook (backup):", towerName)
                        end
                        
                        towerTracker.pendingActions[upgradeKey] = nil
                    end)
                end
            end
        end
    end
    
    if remoteNameLower:find("sell") then
        if args[1] and typeof(args[1]) == "Instance" then
            local tower = args[1]
            local towerName = tower.Name
            
            table.insert(getgenv().MacroDataV2, {
                RemoteName = remoteName,
                Args = {nil},
                Time = now - getgenv().MacroRecordingStartTime,
                IsInvoke = (method == "InvokeServer"),
                Cost = 0,
                TowerName = towerName,
                ActionType = "Sell",
                Wave = getgenv().MacroGameState.currentWave
            })
            
            if towerTracker.placeCounts[towerName] then
                towerTracker.placeCounts[towerName] = math.max(0, towerTracker.placeCounts[towerName] - 1)
            end
            
            getgenv().MacroStatusText = "Recording"
            getgenv().MacroCurrentStep = #getgenv().MacroDataV2
            getgenv().MacroTotalSteps = #getgenv().MacroDataV2
            getgenv().MacroActionText = "Sell"
            getgenv().MacroUnitText = towerName
            getgenv().UpdateMacroStatus()
        end
    end
end

local function setupRecordingHook()
    if namecallHook then return end
    
    task.spawn(function()
        local lastTowerCount = {}
        
        while true do
            task.wait(0.1)
            
            if not getgenv().MacroRecordingV2 then
                task.wait(0.5)
                continue
            end
            
            pcall(function()
                local currentCounts = {}
                
                for _, tower in pairs(workspace.Towers:GetChildren()) do
                    if tower:FindFirstChild("Owner") and tower.Owner.Value == LocalPlayer then
                        local towerName = tower.Name
                        currentCounts[towerName] = (currentCounts[towerName] or 0) + 1
                    end
                end
                
                for towerName, count in pairs(currentCounts) do
                    local lastCount = lastTowerCount[towerName] or 0
                    
                    if count > lastCount then
                        local now = tick()
                        
                        local newestTower = nil
                        for _, tower in pairs(workspace.Towers:GetChildren()) do
                            if tower.Name == towerName and tower:FindFirstChild("Owner") and tower.Owner.Value == LocalPlayer then
                                if not newestTower or (tower:FindFirstChild("Upgrade") and tower.Upgrade.Value == 0) then
                                    newestTower = tower
                                end
                            end
                        end
                        
                        if newestTower then
                            local cost = getgenv().GetRecentCashDecrease and getgenv().GetRecentCashDecrease(0.3) or 0
                            
                            if cost == 0 and getgenv().GetPlaceCost then
                                cost = getgenv().GetPlaceCost(towerName)
                            end
                            
                            print("[Macro Record] Placed:", towerName, "Cost:", cost)
                            
                            local cframe = newestTower:GetPivot()
                            local savedArgs = {towerName, {cframe:GetComponents()}}
                            
                            table.insert(getgenv().MacroDataV2, {
                                RemoteName = "PlaceTower",
                                Args = savedArgs,
                                Time = now - getgenv().MacroRecordingStartTime,
                                IsInvoke = false,
                                Cost = cost,
                                TowerName = towerName,
                                ActionType = "Place",
                                Wave = getgenv().MacroGameState.currentWave
                            })
                            
                            getgenv().MacroStatusText = "Recording"
                            getgenv().MacroCurrentStep = #getgenv().MacroDataV2
                            getgenv().MacroTotalSteps = #getgenv().MacroDataV2
                            getgenv().MacroActionText = "Place"
                            getgenv().MacroUnitText = towerName
                            
                            if getgenv().UpdateMacroStatus then
                                getgenv().UpdateMacroStatus()
                            end
                            
                            print("[Macro Debug] Recorded placement:", towerName)
                        end
                    end
                end
                
                lastTowerCount = currentCounts
            end)
        end
    end)
    
    namecallHook = true
end


local function monitorEndGameUI()
    task.spawn(function()
        while true do
            task.wait(0.5)
            
            if getgenv().MacroRecordingV2 and getgenv().MacroGameState.hasEndGameUI then
                getgenv().MacroRecordingV2 = false
                
                pcall(function()
                    if macroRecordToggle then
                        macroRecordToggle:UpdateState(false)
                    end
                end)
                
                if #getgenv().MacroDataV2 > 0 and getgenv().CurrentMacro then
                    local success = getgenv().SaveMacro(getgenv().CurrentMacro, getgenv().MacroDataV2)
                    
                    if success then
                        getgenv().MacroPlayEnabled = true
                        getgenv().Config.toggles.MacroPlayToggle = true
                        getgenv().SaveConfig(getgenv().Config)
                        
                        pcall(function()
                            if getgenv().MacroPlayToggle then
                                getgenv().MacroPlayToggle:UpdateState(true)
                            end
                        end)
                        
                        if Window and Window.Notify then
                            Window:Notify({
                                Title = "Macro Recording",
                                Description = "Saved " .. #getgenv().MacroDataV2 .. " steps. Playback enabled.",
                                Lifetime = 5
                            })
                        end
                    end
                end
                
                getgenv().MacroStatusText = "Idle"
                getgenv().MacroCurrentStep = 0
                getgenv().MacroTotalSteps = 0
                getgenv().MacroActionText = ""
                getgenv().MacroUnitText = ""
                getgenv().UpdateMacroStatus()
                
                towerTracker = {
                    placeCounts = {},
                    upgradeLevels = {},
                    lastPlaceTime = {},
                    lastUpgradeTime = {},
                    pendingActions = {}
                }
            end
        end
    end)
end

getgenv().MacroPlaybackActive = false

local function executeAction(action)
    if not action.RemoteName then 
        return false, "No remote name"
    end
    
    local remote = getgenv().MacroRemoteCache[action.RemoteName:lower()]
    if not remote then 
        return false, "Remote not found: " .. action.RemoteName
    end
    
    if action.ActionType == "Upgrade" then
        local towers = {}
        for _, t in pairs(workspace.Towers:GetChildren()) do
            if t.Name == action.TowerName and t:FindFirstChild("Owner") and t.Owner.Value == LocalPlayer then
                local currentLevel = t:FindFirstChild("Upgrade") and t.Upgrade.Value or 0
                local maxLevel = t:FindFirstChild("MaxUpgrade") and t.MaxUpgrade.Value or 999
                if currentLevel < maxLevel then
                    table.insert(towers, {tower = t, level = currentLevel})
                end
            end
        end
        
        if #towers == 0 then
            local allTowers = {}
            for _, t in pairs(workspace.Towers:GetChildren()) do
                if t.Name == action.TowerName and t:FindFirstChild("Owner") and t.Owner.Value == LocalPlayer then
                    table.insert(allTowers, t)
                end
            end
            
            if #allTowers == 0 then
                return false, "No " .. action.TowerName .. " found"
            else
                return true, "All " .. action.TowerName .. " already max level"
            end
        end
        
        table.sort(towers, function(a, b)
            return a.level < b.level
        end)
        
        local towerData = towers[1]
        local tower = towerData.tower
        
        local cash = tonumber(getgenv().MacroCurrentCash) or 0
        local cost = tonumber(action.Cost) or 0
        
        if cost > 0 and cash < cost then
            return false, "Not enough cash: need $" .. cost .. ", have $" .. cash
        end
        
        if remote:IsA("RemoteFunction") then
            remote:InvokeServer(tower)
        else
            remote:FireServer(tower)
        end
        
        task.wait(0.5)
        
        local newLevel = tower:FindFirstChild("Upgrade") and tower.Upgrade.Value or towerData.level
        if newLevel > towerData.level then
            return true, "Upgraded to level " .. newLevel
        else
            return false, "Upgrade may have failed"
        end
        
    elseif action.ActionType == "Sell" then
        local tower = nil
        for _, t in pairs(workspace.Towers:GetChildren()) do
            if t.Name == action.TowerName and t:FindFirstChild("Owner") and t.Owner.Value == LocalPlayer then
                tower = t
                break
            end
        end
        
        if tower and remote then
            if remote:IsA("RemoteFunction") then
                remote:InvokeServer(tower)
            else
                remote:FireServer(tower)
            end
            task.wait(0.3)
            return true, "Sold"
        else
            return false, "Tower not found for sell"
        end
        
    elseif action.ActionType == "Place" then
        local args = {action.Args[1]}
        if action.Args[2] and type(action.Args[2]) == "table" then
            args[2] = CFrame.new(unpack(action.Args[2]))
        end
        
        if remote:IsA("RemoteFunction") then
            remote:InvokeServer(unpack(args))
        else
            remote:FireServer(unpack(args))
        end
        task.wait(0.3)
        return true, "Placed"
    end
    
    return false, "Unknown action type"
end

local function detectMacroProgress(macroData)
    local towerStates = {}
    
    for _, tower in pairs(workspace.Towers:GetChildren()) do
        if tower:FindFirstChild("Owner") and tower.Owner.Value == LocalPlayer then
            local towerName = tower.Name
            local level = tower:FindFirstChild("Upgrade") and tower.Upgrade.Value or 0
            
            if not towerStates[towerName] then
                towerStates[towerName] = {count = 0, maxLevel = 0}
            end
            
            towerStates[towerName].count = towerStates[towerName].count + 1
            towerStates[towerName].maxLevel = math.max(towerStates[towerName].maxLevel, level)
        end
    end
    
    local lastCompletedStep = 0
    local expectedTowers = {}
    
    for i, action in ipairs(macroData) do
        if action.ActionType == "Place" then
            local towerName = action.TowerName
            expectedTowers[towerName] = (expectedTowers[towerName] or 0) + 1
            
            if towerStates[towerName] and towerStates[towerName].count >= expectedTowers[towerName] then
                lastCompletedStep = i
            else
                break
            end
            
        elseif action.ActionType == "Upgrade" then
            local towerName = action.TowerName
            
            local expectedLevel = 0
            for j = 1, i do
                if macroData[j].ActionType == "Upgrade" and macroData[j].TowerName == towerName then
                    expectedLevel = expectedLevel + 1
                end
            end
            
            if towerStates[towerName] and towerStates[towerName].maxLevel >= expectedLevel then
                lastCompletedStep = i
            else
                break
            end
        end
    end
    
    
    if lastCompletedStep >= #macroData then
        return -1
    end
    
    return lastCompletedStep + 1
end

local function playMacroV2()
    if getgenv().MacroPlaybackActive then return end
    if not getgenv().CurrentMacro or not getgenv().Macros[getgenv().CurrentMacro] then
        return
    end
    
    getgenv().MacroPlaybackActive = true
    
    task.spawn(function()
        local macroData = getgenv().Macros[getgenv().CurrentMacro]
        if not macroData or #macroData == 0 then
            getgenv().MacroPlaybackActive = false
            return
        end
        
        local step = 1
        
        local elapsedTime = 0
        pcall(function()
            local elapsed = RS:FindFirstChild("ElapsedTime")
            if elapsed and elapsed.Value then
                elapsedTime = elapsed.Value
            end
        end)
        
        if not getgenv().MacroGameState.hasStartButton and getgenv().MacroGameState.currentWave > 0 and elapsedTime > 5 then
            step = detectMacroProgress(macroData)
            
            if step == -1 then
                getgenv().MacroStatusText = "Finished Macro"
                getgenv().MacroWaitingText = "All steps complete"
                getgenv().MacroCurrentStep = #macroData
                getgenv().MacroTotalSteps = #macroData
                getgenv().UpdateMacroStatus()
                getgenv().MacroPlaybackActive = false
                return
            end
            
            if step > 1 then
                print("[Macro Resume] Resuming from step", step)
            end
        else
            print("[Macro] Starting fresh from step 1 (waiting for game to start)")
        end
        
        print("[Macro] Waiting for round to start...")
        
        local waitStartTime = tick()
        
        while getgenv().MacroPlayEnabled do
            local elapsedTime = 0
            local currentWave = 0
            
            pcall(function()
                local elapsed = RS:FindFirstChild("ElapsedTime")
                if elapsed and elapsed.Value then
                    elapsedTime = elapsed.Value
                end
                
                local wave = RS:FindFirstChild("Wave")
                if wave and wave.Value then
                    currentWave = wave.Value
                end
            end)
            
            if elapsedTime > 0 and currentWave > 0 then
                print("[Macro] Round started! ElapsedTime:", elapsedTime, "Wave:", currentWave)
                break
            end
            
            if elapsedTime == 0 then
                getgenv().MacroStatusText = "Waiting for Start"
                getgenv().MacroWaitingText = "Round not started..."
            else
                getgenv().MacroStatusText = "Waiting for Round"
                getgenv().MacroWaitingText = "Wave " .. currentWave .. "..."
            end
            getgenv().UpdateMacroStatus()
            
            local elapsed = tick() - waitStartTime
            if elapsed > 300 then
                print("[Macro] Timeout waiting for round start (5 minutes)")
                getgenv().MacroPlaybackActive = false
                return
            end
            
            task.wait(0.1)
        end
        
        if not getgenv().MacroPlayEnabled then
            getgenv().MacroPlaybackActive = false
            return
        end
        
        print("[Macro] Starting playback NOW")
        task.wait(0.5)
        
        if not getgenv().MacroPlayEnabled then
            getgenv().MacroPlaybackActive = false
            return
        end
        
        getgenv().MacroStatusText = "Playing"
        getgenv().MacroWaitingText = ""
        getgenv().UpdateMacroStatus()
        
        local lastCashCheck = 0
        local lastWaveCheck = getgenv().MacroGameState.currentWave
        
        while getgenv().MacroPlayEnabled and step <= #macroData do
            if getgenv().IsKilled and getgenv().IsKilled() then
                break
            end
            
            local currentWave = getgenv().MacroGameState.currentWave
            if lastWaveCheck > 5 and currentWave == 1 then
                getgenv().MacroStatusText = "Wave Reset - Restarting Macro"
                getgenv().MacroWaitingText = "Detected wave reset..."
                getgenv().UpdateMacroStatus()
                step = 1
                lastWaveCheck = currentWave
                task.wait(2)
                continue
            end
            lastWaveCheck = currentWave
            
            if getgenv().MacroGameState.gameEnded then
                getgenv().MacroStatusText = "Game Ended - Waiting"
                getgenv().MacroWaitingText = "Waiting for next round..."
                getgenv().UpdateMacroStatus()
                
                while getgenv().MacroGameState.gameEnded and getgenv().MacroPlayEnabled do
                    task.wait(0.5)
                end
                
                getgenv().MacroGameState.gameEnded = false
                step = 1
                task.wait(2)
                continue
            end
            
            if getgenv().MacroGameState.hasStartButton or getgenv().MacroGameState.currentWave == 0 then
                getgenv().MacroStatusText = "Restart Detected"
                getgenv().MacroWaitingText = "Waiting for game start..."
                getgenv().UpdateMacroStatus()
                
                while (getgenv().MacroGameState.hasStartButton or getgenv().MacroGameState.currentWave == 0) and getgenv().MacroPlayEnabled do
                    task.wait(0.1)
                end
                
                if not getgenv().MacroPlayEnabled then
                    break
                end
                
                print("[Macro] Game restarted, waiting 2 seconds...")
                task.wait(2)
                
                step = 1
                continue
            end
            
            local action = macroData[step]
            if not action then
                step = step + 1
                continue
            end
            
            getgenv().MacroCurrentStep = step
            getgenv().MacroTotalSteps = #macroData
            getgenv().MacroActionText = action.ActionType or "Action"
            getgenv().MacroUnitText = action.TowerName or "?"
            getgenv().UpdateMacroStatus()
            
            local cash = tonumber(getgenv().MacroCurrentCash) or 0
            local cost = tonumber(action.Cost) or 0
            
            local shouldSkipStep = false
            
            if cost > 0 and cash < cost then
                getgenv().MacroStatusText = "Waiting Cash"
                getgenv().MacroWaitingText = "$" .. cost .. " (have $" .. cash .. ")"
                getgenv().UpdateMacroStatus()
                
                local cashWaitStart = tick()
                local maxCashWait = 300
                local lastCash = cash
                local noIncomeTime = 0
                
                while getgenv().MacroPlayEnabled do
                    task.wait(0.1)
                    cash = tonumber(getgenv().MacroCurrentCash) or 0
                    
                    if cash >= cost then 
                        break 
                    end
                    
                    if cash > lastCash then
                        noIncomeTime = 0
                    else
                        noIncomeTime = noIncomeTime + 0.1
                    end
                    lastCash = cash
                    
                    local waitTime = tick() - cashWaitStart
                    
                    if waitTime > maxCashWait then
                        shouldSkipStep = true
                        break
                    end
                    
                    if noIncomeTime > 60 and waitTime > 30 then
                        shouldSkipStep = true
                        break
                    end
                    
                    getgenv().MacroWaitingText = "$" .. cost .. " (have $" .. cash .. ") - " .. math.floor(waitTime) .. "s"
                    getgenv().UpdateMacroStatus()
                end
                
                if not getgenv().MacroPlayEnabled then break end
            end
            
            if shouldSkipStep then
                getgenv().MacroStatusText = "Skipping - Not Enough Cash"
                getgenv().MacroWaitingText = "Needed $" .. cost .. ", have $" .. cash
                getgenv().UpdateMacroStatus()
                task.wait(2)
                step = step + 1
                continue
            end
            
            getgenv().MacroStatusText = "Playing"
            getgenv().MacroWaitingText = ""
            getgenv().UpdateMacroStatus()
            
            print("[Macro] Executing step", step, "-", action.ActionType, action.TowerName or "?", "Cost:", action.Cost or 0)
            
            local actionSuccess = false
            local actionMessage = ""
            
            local success, result, msg = pcall(function()
                return executeAction(action)
            end)
            
            if success and result then
                actionSuccess = true
                actionMessage = msg or "Success"
                print("[Macro] Step", step, "SUCCESS")
            else
                actionMessage = msg or "Action failed"
                print("[Macro] Step", step, "FAILED:", actionMessage)
            end
            
            if not actionSuccess then
                getgenv().MacroStatusText = "Step Failed - Continuing"
                getgenv().MacroWaitingText = actionMessage
                getgenv().UpdateMacroStatus()
                task.wait(0.5)
            end
            
            step = step + 1
            
            task.wait(0.3)
            
            local stepDelay = getgenv().MacroStepDelay or 0
            if stepDelay > 0 then
                task.wait(stepDelay)
            else
                task.wait(0.15)
            end
        end
        
        if step > #macroData then
            print("[Macro] Finished all steps, waiting for next round...")
            getgenv().MacroStatusText = "Waiting for Next Round"
            getgenv().MacroWaitingText = "Macro complete"
            getgenv().MacroCurrentStep = #macroData
            getgenv().MacroTotalSteps = #macroData
            getgenv().MacroActionText = "Complete"
            getgenv().MacroUnitText = ""
            getgenv().UpdateMacroStatus()
            
            local lastWaveBeforeWait = getgenv().MacroGameState.currentWave
            
            while getgenv().MacroPlayEnabled do
                task.wait(0.5)
                
                local currentWave = getgenv().MacroGameState.currentWave
                local elapsedTime = 0
                pcall(function()
                    local elapsed = RS:FindFirstChild("ElapsedTime")
                    if elapsed and elapsed.Value then
                        elapsedTime = elapsed.Value
                    end
                end)
                
                if lastWaveBeforeWait > 5 and currentWave > 0 and currentWave < lastWaveBeforeWait then
                    print("[Macro] Wave decrease detected (", lastWaveBeforeWait, "->", currentWave, ") - Restarting macro")
                    getgenv().MacroPlaybackActive = false
                    return
                end
                
                if elapsedTime == 0 and currentWave == 1 then
                    print("[Macro] ElapsedTime reset detected - New round starting")
                    getgenv().MacroPlaybackActive = false
                    return
                end
                
                if getgenv().MacroGameState.hasStartButton or currentWave == 0 then
                    print("[Macro] New round detected (start button or wave 0)")
                    getgenv().MacroPlaybackActive = false
                    return
                end
                
                if getgenv().MacroGameState.gameEnded then
                    print("[Macro] Game ended, will restart macro...")
                    getgenv().MacroPlaybackActive = false
                    return
                end
                
                lastWaveBeforeWait = currentWave
            end
        else
            getgenv().MacroStatusText = "Idle"
            getgenv().MacroCurrentStep = 0
            getgenv().MacroActionText = ""
            getgenv().MacroUnitText = ""
            getgenv().MacroWaitingText = ""
            getgenv().UpdateMacroStatus()
        end
        
        getgenv().MacroPlaybackActive = false
    end)
end

setupRecordingHook()
monitorEndGameUI()

task.spawn(function()
    while true do
        task.wait(0.5)
        
        if getgenv().MacroPlayEnabled and not getgenv().MacroPlaybackActive then
            playMacroV2()
        end
    end
end)



local MapData = nil
pcall(function()
    local mapDataModule = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("MapData")
    if mapDataModule and mapDataModule:IsA("ModuleScript") then
        MapData = require(mapDataModule)
    end
end)

local function getMapsByMode(mode)
    if not MapData then return {} end
    if mode == "ElementalCaverns" then return {"Light","Nature","Fire","Dark","Water"} end
    local maps = {}
    for mapName, mapInfo in pairs(MapData) do
        if mapInfo.Type and type(mapInfo.Type) == "table" then
            for _, mapType in ipairs(mapInfo.Type) do
                if mapType == mode then table.insert(maps, mapName) break end
            end
        end
    end
    table.sort(maps)
    return maps
end

local savedAutoJoin = getgenv().Config.autoJoin or {}
getgenv().AutoJoinConfig = {
    enabled = savedAutoJoin.enabled or false,
    autoStart = savedAutoJoin.autoStart or false,
    friendsOnly = savedAutoJoin.friendsOnly or false,
    mode = savedAutoJoin.mode or "Story",
    map = savedAutoJoin.map or "",
    act = savedAutoJoin.act or 1,
    difficulty = savedAutoJoin.difficulty or "Normal"
}




local success, err = pcall(function()
    Sections.MainLeft:Header({ Text = "🎮 Game Selection" })
    Sections.MainLeft:SubLabel({ Text = "Choose your game mode and map" })
end)
if not success then
    warn("[UI ERROR] Main tab header failed:", err)
    error("[FATAL] Cannot continue - Main tab header failed: " .. tostring(err))
end

local autoJoinModeList = {"Story", "Infinite", "Challenge", "LegendaryStages", "Raids", "Dungeon", "Survival", "ElementalCaverns", "Event", "MidnightHunt", "BossRush", "Siege", "Breach"}

local autoJoinMapDropdown = nil

local modeDefault = 1
if getgenv().AutoJoinConfig.mode then
    for i, modeName in ipairs(autoJoinModeList) do
        if modeName == getgenv().AutoJoinConfig.mode then
            modeDefault = i
            break
        end
    end
end


local autoJoinModeDropdown
local modeSuccess, modeErr = pcall(function()
    autoJoinModeDropdown = createDropdown(
        Sections.MainLeft,
        "Mode",
        "AutoJoinMode",
        autoJoinModeList,
        false,
        function(value)
            getgenv().AutoJoinConfig.mode = value
            getgenv().Config.autoJoin.mode = value
            saveConfig(getgenv().Config)
            
            local maps = getMapsByMode(value)
            if #maps == 0 then
                maps = {"No Maps Available"}
            end
            if autoJoinMapDropdown then
                pcall(function()
                    autoJoinMapDropdown:ClearOptions()
                    autoJoinMapDropdown:InsertOptions(maps)
                    if #maps > 0 then
                        autoJoinMapDropdown:UpdateSelection(1)
                        getgenv().AutoJoinConfig.map = maps[1]
                        getgenv().Config.autoJoin.map = maps[1]
                        saveConfig(getgenv().Config)
                    end
                end)
            end
        end,
        modeDefault
    )
end)
if not modeSuccess then
    warn("[UI ERROR] Mode dropdown failed:", modeErr)
    error("[FATAL] Cannot continue - Mode dropdown failed: " .. tostring(modeErr))
end

local initialMaps = getMapsByMode(getgenv().AutoJoinConfig.mode)
if #initialMaps == 0 then
    initialMaps = {"No Maps Available"}
end

local mapDefault = 1
if getgenv().AutoJoinConfig.map and getgenv().AutoJoinConfig.map ~= "" then
    for i, mapName in ipairs(initialMaps) do
        if mapName == getgenv().AutoJoinConfig.map then
            mapDefault = i
            break
        end
    end
end


local mapSuccess, mapErr = pcall(function()
    autoJoinMapDropdown = createDropdown(
        Sections.MainLeft,
        "Map",
        "AutoJoinMap",
        initialMaps,
        false,
        function(value)
            getgenv().AutoJoinConfig.map = value
            getgenv().Config.autoJoin.map = value
            saveConfig(getgenv().Config)
        end,
        mapDefault
    )
end)
if not mapSuccess then
    warn("[UI ERROR] Map dropdown failed:", mapErr)
    error("[FATAL] Cannot continue - Map dropdown failed: " .. tostring(mapErr))
end

local actDefault = getgenv().AutoJoinConfig.act or 1

local actSuccess, actErr = pcall(function()
    createDropdown(
        Sections.MainLeft,
        "Act",
        "AutoJoinAct",
        {"1", "2", "3", "4", "5", "6"},
        false,
        function(value)
            getgenv().AutoJoinConfig.act = tonumber(value) or 1
            getgenv().Config.autoJoin.act = tonumber(value) or 1
            saveConfig(getgenv().Config)
        end,
        actDefault
    )
end)
if not actSuccess then
    warn("[UI ERROR] Act dropdown failed:", actErr)
    error("[FATAL] Cannot continue - Act dropdown failed: " .. tostring(actErr))
end

local difficultyList = {"Normal", "Nightmare", "Purgatory", "Insanity"}
local difficultyDefault = 1
if getgenv().AutoJoinConfig.difficulty then
    for i, diff in ipairs(difficultyList) do
        if diff == getgenv().AutoJoinConfig.difficulty then
            difficultyDefault = i
            break
        end
    end
end


local diffSuccess, diffErr = pcall(function()
    createDropdown(
        Sections.MainLeft,
        "Difficulty",
        "AutoJoinDifficulty",
        difficultyList,
        false,
        function(value)
            getgenv().AutoJoinConfig.difficulty = value
            getgenv().Config.autoJoin.difficulty = value
            saveConfig(getgenv().Config)
        end,
        difficultyDefault
    )
end)
if not diffSuccess then
    warn("[UI ERROR] Difficulty dropdown failed:", diffErr)
    error("[FATAL] Cannot continue - Difficulty dropdown failed: " .. tostring(diffErr))
end

local divSuccess, divErr = pcall(function()
    Sections.MainLeft:Divider()
    Sections.MainLeft:Header({ Text = "⚙️ Join Settings" })
    Sections.MainLeft:SubLabel({ Text = "Configure auto-join behavior" })
end)
if not divSuccess then
    warn("[UI ERROR] Join Settings section failed:", divErr)
    error("[FATAL] Cannot continue - Join Settings section failed: " .. tostring(divErr))
end

local enableToggleSuccess, enableToggleErr = pcall(function()
    createToggle(
        Sections.MainLeft,
        "Enable Auto Join",
        "AutoJoinEnabled",
        function(value)
            getgenv().AutoJoinConfig.enabled = value
            getgenv().Config.autoJoin.enabled = value
            saveConfig(getgenv().Config)
            Window:Notify({
                Title = "Auto Join",
                Description = value and "Enabled" or "Disabled",
                Lifetime = 3
            })
        end,
        getgenv().AutoJoinConfig.enabled
    )
end)
if not enableToggleSuccess then
    warn("[UI ERROR] Enable Auto Join toggle failed:", enableToggleErr)
end

local joinDelaySuccess, joinDelayErr = pcall(function()
    createInput(
        Sections.MainLeft,
        "Join Delay (seconds)",
        "AutoJoinDelay",
        "Delay before joining map (0 = instant)",
        "Number",
        function(value)
            local delay = tonumber(value) or 0
            getgenv().AutoJoinDelay = delay
            Window:Notify({
                Title = "Auto Join Delay",
                Description = "Set to " .. delay .. " seconds",
                Lifetime = 2
            })
        end,
        tostring(getgenv().Config.inputs.AutoJoinDelay or 0)
    )
end)
if not joinDelaySuccess then
    warn("[UI ERROR] Auto Join Delay input failed:", joinDelayErr)
end

local friendsSuccess, friendsErr = pcall(function()
    createToggle(
        Sections.MainLeft,
        "Friends Only",
        "AutoJoinFriendsOnly",
        function(value)
            getgenv().AutoJoinConfig.friendsOnly = value
            getgenv().Config.autoJoin.friendsOnly = value
            saveConfig(getgenv().Config)
            
            pcall(function()
                RS.Remotes.Teleporter.InteractEvent:FireServer("FriendsOnly")
            end)
            
            Window:Notify({
                Title = "Friends Only",
                Description = value and "Enabled" or "Disabled",
                Lifetime = 3
            })
        end,
        getgenv().AutoJoinConfig.friendsOnly
    )
end)
if not friendsSuccess then
    warn("[UI ERROR] Friends Only toggle failed:", friendsErr)
    error("[FATAL] Cannot continue - Friends Only toggle failed: " .. tostring(friendsErr))
end

local autoStartSuccess, autoStartErr = pcall(function()
    createToggle(
        Sections.MainLeft,
        "Auto Start",
        "AutoJoinAutoStart",
        function(value)
            getgenv().AutoJoinConfig.autoStart = value
            getgenv().Config.autoJoin.autoStart = value
            saveConfig(getgenv().Config)
            Window:Notify({
                Title = "Auto Start",
                Description = value and "Enabled" or "Disabled",
                Lifetime = 3
            })
        end,
        getgenv().AutoJoinConfig.autoStart
    )
end)
if not autoStartSuccess then
    warn("[UI ERROR] Auto Start toggle failed:", autoStartErr)
    error("[FATAL] Cannot continue - Auto Start toggle failed: " .. tostring(autoStartErr))
end


local gameActionsSuccess, gameActionsErr = pcall(function()
    Sections.MainRight:Header({ Text = "📊 Quick Actions" })
    Sections.MainRight:SubLabel({ Text = "Fast toggles for common actions" })
end)
if not gameActionsSuccess then
    warn("[UI ERROR] Quick Actions header failed:", gameActionsErr)
    error("[FATAL] Cannot continue - Quick Actions header failed: " .. tostring(gameActionsErr))
end

local autoNextSuccess, autoNextErr = pcall(function()
    createToggle(
        Sections.MainRight,
        "Auto Next",
        "AutoNext",
        function(value)
            getgenv().AutoNextEnabled = value
            getgenv().Config.toggles.AutoNext = value
            saveConfig(getgenv().Config)
            Window:Notify({
                Title = "Auto Next",
                Description = value and "Enabled" or "Disabled",
                Lifetime = 3
            })
        end,
        getgenv().AutoNextEnabled
    )
end)
if not autoNextSuccess then
    warn("[UI ERROR] Auto Next toggle failed:", autoNextErr)
    error("[FATAL] Cannot continue - Auto Next toggle failed: " .. tostring(autoNextErr))
end

local autoRetrySuccess, autoRetryErr = pcall(function()
    createToggle(
        Sections.MainRight,
        "Auto Retry",
        "AutoRetry",
        function(value)
            getgenv().AutoFastRetryEnabled = value
            getgenv().Config.toggles.AutoRetry = value
            saveConfig(getgenv().Config)
            Window:Notify({
                Title = "Auto Retry",
                Description = value and "Enabled" or "Disabled",
                Lifetime = 3
            })
        end,
        getgenv().AutoFastRetryEnabled
    )
end)
if not autoRetrySuccess then
    warn("[UI ERROR] Auto Retry toggle failed:", autoRetryErr)
    error("[FATAL] Cannot continue - Auto Retry toggle failed: " .. tostring(autoRetryErr))
end

local autoLeaveSuccess, autoLeaveErr = pcall(function()
    createToggle(
        Sections.MainRight,
        "Auto Leave",
        "AutoLeave",
        function(value)
            getgenv().AutoLeaveEnabled = value
            getgenv().Config.toggles.AutoLeave = value
            saveConfig(getgenv().Config)
            Window:Notify({
                Title = "Auto Leave",
                Description = value and "Enabled" or "Disabled",
                Lifetime = 3
            })
        end,
        getgenv().AutoLeaveEnabled
    )
end)
if not autoLeaveSuccess then
    warn("[UI ERROR] Auto Leave toggle failed:", autoLeaveErr)
    error("[FATAL] Cannot continue - Auto Leave toggle failed: " .. tostring(autoLeaveErr))
end

local autoSmartSuccess, autoSmartErr = pcall(function()
    createToggle(
        Sections.MainRight,
        "Auto Next/Replay/Leave",
        "AutoSmart",
        function(value)
            getgenv().AutoSmartEnabled = value
            getgenv().Config.toggles.AutoSmart = value
            saveConfig(getgenv().Config)
            Window:Notify({
                Title = "Auto Next/Replay/Leave",
                Description = value and "Enabled" or "Disabled",
                Lifetime = 3
            })
        end,
        getgenv().AutoSmartEnabled
    )
end)
if not autoSmartSuccess then
    warn("[UI ERROR] Auto Next/Replay/Leave toggle failed:", autoSmartErr)
    error("[FATAL] Cannot continue - Auto Next/Replay/Leave toggle failed: " .. tostring(autoSmartErr))
end

local autoReadySuccess, autoReadyErr = pcall(function()
    createToggle(
        Sections.MainRight,
        "Auto Ready",
        "AutoReady",
        function(value)
            getgenv().AutoReadyEnabled = value
            Window:Notify({
                Title = "Auto Ready",
                Description = value and "Enabled" or "Disabled",
                Lifetime = 3
            })
        end,
        getgenv().AutoReadyEnabled
    )
end)
if not autoReadySuccess then
    warn("[UI ERROR] Auto Ready toggle failed:", autoReadyErr)
    error("[FATAL] Cannot continue - Auto Ready toggle failed: " .. tostring(autoReadyErr))
end




getgenv().CandyCards = {
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

getgenv().DevilSacrifice = { ["Devil's Sacrifice"] = 999 }

getgenv().OtherCards = {
    ["Bullet Breaker I"] = 999, ["Bullet Breaker II"] = 999, ["Bullet Breaker III"] = 999,
    ["Hell Merchant I"] = 999, ["Hell Merchant II"] = 999, ["Hell Merchant III"] = 999,
    ["Hellish Warp I"] = 999, ["Hellish Warp II"] = 999,
    ["Fiery Surge I"] = 999, ["Fiery Surge II"] = 999,
    ["Grevious Wounds I"] = 999, ["Grevious Wounds II"] = 999,
    ["Scorching Hell I"] = 999, ["Scorching Hell II"] = 999,
    ["Fortune Flow"] = 999, ["Soul Link"] = 999,
    ["Seeting Bloodlust"] = 999
}

getgenv().BossRushGeneral = {
    ["Metal Skin"] = 0, ["Raging Power"] = 0, ["Demon Takeover"] = 0, ["Fortune"] = 0,
    ["Chaos Eater"] = 0, ["Godspeed"] = 0, ["Insanity"] = 0, ["Feeding Madness"] = 0, ["Emotional Damage"] = 0
}

getgenv().BabyloniaCastle = {}

local function initializeCardPriorities(sourceTable, targetTable, keyPrefix)
    if not sourceTable then return end
    keyPrefix = keyPrefix or "Card_"
    
    for cardName, defaultPriority in pairs(sourceTable) do
        local configKey = keyPrefix .. cardName
        local savedValue = getgenv().Config.inputs[configKey]
        targetTable[cardName] = savedValue and tonumber(savedValue) or defaultPriority
    end
end

getgenv().CardPriority = getgenv().CardPriority or {}
initializeCardPriorities(getgenv().CandyCards, getgenv().CardPriority)
initializeCardPriorities(getgenv().DevilSacrifice, getgenv().CardPriority)
initializeCardPriorities(getgenv().OtherCards, getgenv().CardPriority)

getgenv().BossRushCardPriority = getgenv().BossRushCardPriority or {}
initializeCardPriorities(getgenv().BossRushGeneral, getgenv().BossRushCardPriority, "BossRush_")
initializeCardPriorities(getgenv().BabyloniaCastle, getgenv().BossRushCardPriority, "BabyloniaCastle_")

getgenv().CardSelectionEnabled = getgenv().Config.toggles.CardSelectionToggle or false
getgenv().SlowerCardSelectionEnabled = getgenv().Config.toggles.SlowerCardSelectionToggle or false

local savedPortalConfig = getgenv().Config.portals or {}
getgenv().PortalConfig = {
    selectedMap = savedPortalConfig.selectedMap or "",
    tier = savedPortalConfig.tier or 1,
    useBestPortal = savedPortalConfig.useBestPortal or false,
    pickPortal = savedPortalConfig.pickPortal or false,
    priorities = savedPortalConfig.priorities or {
        ["Tower Limit"] = 0,
        ["Immunity"] = 0,
        ["Speedy"] = 0,
        ["No Hit"] = 0,
        ["Flight"] = 0,
        ["Short Range"] = 0
    }
}
getgenv().Config.portals = getgenv().PortalConfig

Sections.PortalsRight:Header({ Text = "🌀 Portal Selection" })
Sections.PortalsRight:SubLabel({ Text = "Configure automatic portal selection" })

local function getPortalMaps()
    local maps = {}
    pcall(function()
        local mapData = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("MapData")
        if mapData and mapData:IsA("ModuleScript") then
            local data = require(mapData)
            for mapName, mapInfo in pairs(data) do
                if mapInfo.Type and type(mapInfo.Type) == "table" then
                    for _, mapType in ipairs(mapInfo.Type) do
                        if mapType == "Portal" then
                            table.insert(maps, mapName)
                            break
                        end
                    end
                end
            end
        end
    end)
    table.sort(maps)
    return #maps > 0 and maps or {"No Portal Maps Found"}
end

local portalMaps = getPortalMaps()
local portalMapDefault = 1
if getgenv().PortalConfig.selectedMap and getgenv().PortalConfig.selectedMap ~= "" then
    for i, mapName in ipairs(portalMaps) do
        if mapName == getgenv().PortalConfig.selectedMap then
            portalMapDefault = i
            break
        end
    end
end

createDropdown(
    Sections.PortalsRight,
    "Select Map",
    "PortalMap",
    portalMaps,
    false,
    function(value)
        getgenv().PortalConfig.selectedMap = value
        getgenv().Config.portals.selectedMap = value
        saveConfig(getgenv().Config)
    end,
    portalMapDefault
)

Sections.PortalsRight:Divider()

Sections.PortalsRight:Header({ Text = "⚙️ Portal Options" })
Sections.PortalsRight:SubLabel({ Text = "Additional portal settings" })

local tierOptions = {}
for i = 1, 10 do
    table.insert(tierOptions, tostring(i))
end

createDropdown(
    Sections.PortalsRight,
    "Portal Tier",
    "PortalTier",
    tierOptions,
    false,
    function(value)
        getgenv().PortalConfig.tier = tonumber(value) or 1
        getgenv().Config.portals.tier = tonumber(value) or 1
        saveConfig(getgenv().Config)
    end,
    getgenv().PortalConfig.tier
)

createToggle(
    Sections.PortalsRight,
    "Use Best Portal (Highest Tier)",
    "UseBestPortal",
    function(value)
        getgenv().PortalConfig.useBestPortal = value
        getgenv().Config.portals.useBestPortal = value
        saveConfig(getgenv().Config)
        Window:Notify({
            Title = "Portal System",
            Description = value and "Will use highest tier portal available" or "Will use selected tier",
            Lifetime = 3
        })
    end,
    getgenv().PortalConfig.useBestPortal
)

createToggle(
    Sections.PortalsRight,
    "Pick Portal (Manual Selection)",
    "PickPortal",
    function(value)
        getgenv().PortalConfig.pickPortal = value
        getgenv().Config.portals.pickPortal = value
        saveConfig(getgenv().Config)
        Window:Notify({
            Title = "Portal System",
            Description = value and "Manual portal selection enabled" or "Automatic selection enabled",
            Lifetime = 3
        })
    end,
    getgenv().PortalConfig.pickPortal
)

Sections.PortalsLeft:Header({ Text = "🎯 Challenge Priority" })
Sections.PortalsLeft:SubLabel({ Text = "Assign priority (1-6) to each challenge. 1 = highest priority, 0 = ignore" })

createInput(
    Sections.PortalsLeft,
    "Tower Limit",
    "PortalPriority_TowerLimit",
    "1-6 or 0 to ignore",
    "Numeric",
    function(value)
        local num = tonumber(value) or 0
        getgenv().PortalConfig.priorities["Tower Limit"] = num
        getgenv().Config.portals.priorities["Tower Limit"] = num
        saveConfig(getgenv().Config)
    end,
    tostring(getgenv().PortalConfig.priorities["Tower Limit"])
)

createInput(
    Sections.PortalsLeft,
    "Immunity",
    "PortalPriority_Immunity",
    "1-6 or 0 to ignore",
    "Numeric",
    function(value)
        local num = tonumber(value) or 0
        getgenv().PortalConfig.priorities["Immunity"] = num
        getgenv().Config.portals.priorities["Immunity"] = num
        saveConfig(getgenv().Config)
    end,
    tostring(getgenv().PortalConfig.priorities["Immunity"])
)

createInput(
    Sections.PortalsLeft,
    "Speedy",
    "PortalPriority_Speedy",
    "1-6 or 0 to ignore",
    "Numeric",
    function(value)
        local num = tonumber(value) or 0
        getgenv().PortalConfig.priorities["Speedy"] = num
        getgenv().Config.portals.priorities["Speedy"] = num
        saveConfig(getgenv().Config)
    end,
    tostring(getgenv().PortalConfig.priorities["Speedy"])
)

createInput(
    Sections.PortalsLeft,
    "No Hit",
    "PortalPriority_NoHit",
    "1-6 or 0 to ignore",
    "Numeric",
    function(value)
        local num = tonumber(value) or 0
        getgenv().PortalConfig.priorities["No Hit"] = num
        getgenv().Config.portals.priorities["No Hit"] = num
        saveConfig(getgenv().Config)
    end,
    tostring(getgenv().PortalConfig.priorities["No Hit"])
)

createInput(
    Sections.PortalsLeft,
    "Flight",
    "PortalPriority_Flight",
    "1-6 or 0 to ignore",
    "Numeric",
    function(value)
        local num = tonumber(value) or 0
        getgenv().PortalConfig.priorities["Flight"] = num
        getgenv().Config.portals.priorities["Flight"] = num
        saveConfig(getgenv().Config)
    end,
    tostring(getgenv().PortalConfig.priorities["Flight"])
)

createInput(
    Sections.PortalsLeft,
    "Short Range",
    "PortalPriority_ShortRange",
    "1-6 or 0 to ignore",
    "Numeric",
    function(value)
        local num = tonumber(value) or 0
        getgenv().PortalConfig.priorities["Short Range"] = num
        getgenv().Config.portals.priorities["Short Range"] = num
        saveConfig(getgenv().Config)
    end,
    tostring(getgenv().PortalConfig.priorities["Short Range"])
)


Sections.EventLeft:Header({ Text = "🎃 Event Automation" })
Sections.EventLeft:SubLabel({ Text = "Automatically join and start events" })

createToggle(
    Sections.EventLeft,
    "Auto Event Join",
    "AutoEventToggle",
    function(value)
        getgenv().AutoEventEnabled = value
        Window:Notify({
            Title = "Auto Event",
            Description = value and "Enabled" or "Disabled",
            Lifetime = 3
        })
    end,
    getgenv().Config.toggles.AutoEventToggle or false
)

createInput(
    Sections.EventLeft,
    "Join Delay (seconds)",
    "EventJoinDelay",
    "Delay before joining event (0 = instant)",
    "Number",
    function(value)
        local delay = tonumber(value) or 0
        getgenv().EventJoinDelay = delay
        Window:Notify({
            Title = "Event Join Delay",
            Description = "Set to " .. delay .. " seconds",
            Lifetime = 2
        })
    end,
    tostring(getgenv().Config.inputs.EventJoinDelay or 0)
)

local LOBBY_PLACEIDS = {12886143095, 18583778121}
local function checkIsInLobby()
    for _, placeId in ipairs(LOBBY_PLACEIDS) do
        if game.PlaceId == placeId then return true end
    end
    return false
end
local isInLobby = checkIsInLobby()

if isInLobby then
    Sections.EventLeft:Divider()
    
    Sections.EventLeft:Header({ Text = "🎲 Auto Bingo" })
    Sections.EventLeft:SubLabel({ Text = "Complete bingo cards automatically" })
    
    createToggle(
        Sections.EventLeft,
        "Enable Auto Bingo",
        "BingoToggle",
        function(value)
            getgenv().BingoEnabled = value
            Window:Notify({
                Title = "Auto Bingo",
                Description = value and "Enabled" or "Disabled",
                Lifetime = 3
            })
        end,
        getgenv().Config.toggles.BingoToggle or false
    )
    
    Sections.EventLeft:Divider()
    
    Sections.EventLeft:Header({ Text = "🎁 Auto Capsules" })
    Sections.EventLeft:SubLabel({ Text = "Open event capsules automatically" })
    
    createToggle(
        Sections.EventLeft,
        "Enable Auto Capsules",
        "CapsuleToggle",
        function(value)
            getgenv().CapsuleEnabled = value
            Window:Notify({
                Title = "Auto Capsules",
                Description = value and "Enabled" or "Disabled",
                Lifetime = 3
            })
        end,
        getgenv().Config.toggles.CapsuleToggle or false
    )
    
    Sections.EventLeft:Divider()
end

local eventHeaderSuccess, eventHeaderErr = pcall(function()
    Sections.EventLeft:Header({ Text = "⚙️ Card Selection Mode" })
    Sections.EventLeft:SubLabel({ Text = "Choose between fast or reliable selection" })
end)
if not eventHeaderSuccess then
    warn("[UI ERROR] Event tab header failed:", eventHeaderErr)
    error("[FATAL] Cannot continue - Event tab header failed: " .. tostring(eventHeaderErr))
end

local fastModeToggle, slowerModeToggle, smartModeToggle

getgenv().SmartCardSelectionEnabled = getgenv().Config.toggles.SmartCardSelectionToggle or false

local fastSuccess, fastErr = pcall(function()
    fastModeToggle = createToggle(
        Sections.EventLeft,
        "⚡ Fast Mode",
        "CardSelectionToggle",
        function(value)
            getgenv().CardSelectionEnabled = value
            if value then
                if slowerModeToggle then
                    getgenv().SlowerCardSelectionEnabled = false
                    getgenv().Config.toggles.SlowerCardSelectionToggle = false
                    pcall(function() slowerModeToggle:UpdateState(false) end)
                end
                if smartModeToggle then
                    getgenv().SmartCardSelectionEnabled = false
                    getgenv().Config.toggles.SmartCardSelectionToggle = false
                    pcall(function() smartModeToggle:UpdateState(false) end)
                end
                getgenv().SaveConfig(getgenv().Config)
            end
            Window:Notify({
                Title = "Card Selection",
                Description = value and "Fast Mode Enabled" or "Disabled",
                Lifetime = 3
            })
        end,
        getgenv().CardSelectionEnabled
    )
end)
if not fastSuccess then
    warn("[UI ERROR] Fast Mode toggle failed:", fastErr)
end

local slowerSuccess, slowerErr = pcall(function()
    slowerModeToggle = createToggle(
        Sections.EventLeft,
        "🐢 Slower Mode (More Reliable)",
        "SlowerCardSelectionToggle",
        function(value)
            getgenv().SlowerCardSelectionEnabled = value
            if value then
                if fastModeToggle then
                    getgenv().CardSelectionEnabled = false
                    getgenv().Config.toggles.CardSelectionToggle = false
                    pcall(function() fastModeToggle:UpdateState(false) end)
                end
                if smartModeToggle then
                    getgenv().SmartCardSelectionEnabled = false
                    getgenv().Config.toggles.SmartCardSelectionToggle = false
                    pcall(function() smartModeToggle:UpdateState(false) end)
                end
                getgenv().SaveConfig(getgenv().Config)
            end
            Window:Notify({
                Title = "Card Selection",
                Description = value and "Slower Mode Enabled" or "Disabled",
                Lifetime = 3
            })
        end,
        getgenv().SlowerCardSelectionEnabled
    )
end)
if not slowerSuccess then
    warn("[UI ERROR] Slower Mode toggle failed:", slowerErr)
end

local smartSuccess, smartErr = pcall(function()
    smartModeToggle = createToggle(
        Sections.EventLeft,
        "🧠 Smart Mode (Wave-Based)",
        "SmartCardSelectionToggle",
        function(value)
            getgenv().SmartCardSelectionEnabled = value
            getgenv().Config.toggles.SmartCardSelectionToggle = value
            if value then
                if fastModeToggle then
                    getgenv().CardSelectionEnabled = false
                    getgenv().Config.toggles.CardSelectionToggle = false
                    pcall(function() fastModeToggle:UpdateState(false) end)
                end
                if slowerModeToggle then
                    getgenv().SlowerCardSelectionEnabled = false
                    getgenv().Config.toggles.SlowerCardSelectionToggle = false
                    pcall(function() slowerModeToggle:UpdateState(false) end)
                end
            end
            getgenv().SaveConfig(getgenv().Config)
            Window:Notify({
                Title = "Card Selection",
                Description = value and "Smart Mode Enabled - Maximizes candy based on wave" or "Disabled",
                Lifetime = 3
            })
        end,
        getgenv().SmartCardSelectionEnabled
    )
end)
if not smartSuccess then
    warn("[UI ERROR] Smart Mode toggle failed:", smartErr)
end

local paraSuccess, paraErr = pcall(function()
    Sections.EventLeft:SubLabel({ 
        Text = "Lower number = higher priority (1 is best, 999 to skip)"
    })
end)
if not paraSuccess then
    warn("[UI ERROR] Event instructions failed:", paraErr)
end


local candyHeaderSuccess, candyHeaderErr = pcall(function()
    Sections.EventRight:Header({ Text = "🃏 Card Priorities" })
    Sections.EventRight:SubLabel({ Text = "Lower number = higher priority (1 is best, 999 to skip)" })
    Sections.EventRight:Divider()
    Sections.EventRight:Header({ Text = "🍬 Candy Cards" })
end)
if not candyHeaderSuccess then
    warn("[UI ERROR] Candy Cards header failed:", candyHeaderErr)
    error("[FATAL] Cannot continue - Candy Cards header failed: " .. tostring(candyHeaderErr))
end

local candyInputsSuccess, candyInputsErr = pcall(function()
    createCardPriorityInputs(Sections.EventRight, getgenv().CandyCards, getgenv().CardPriority)
end)
if not candyInputsSuccess then
    warn("[UI ERROR] Candy Cards inputs failed:", candyInputsErr)
    error("[FATAL] Cannot continue - Candy Cards inputs failed: " .. tostring(candyInputsErr))
end

Sections.EventRight:Divider()

Sections.EventRight:Header({ Text = "😈 Devil's Sacrifice" })
createCardPriorityInputs(Sections.EventRight, getgenv().DevilSacrifice, getgenv().CardPriority)

Sections.EventRight:Divider()

Sections.EventRight:Header({ Text = "📋 Other Cards" })
createCardPriorityInputs(Sections.EventRight, getgenv().OtherCards, getgenv().CardPriority)



Sections.BossRushLeft:Header({ Text = "⚔️ Boss Rush Settings" })
Sections.BossRushLeft:SubLabel({ Text = "Automatic card selection for Boss Rush" })

createToggle(
    Sections.BossRushLeft,
    "Enable Boss Rush",
    "BossRushToggle",
    function(value)
        getgenv().BossRushEnabled = value
        Window:Notify({
            Title = "Boss Rush",
            Description = value and "Enabled" or "Disabled",
            Lifetime = 3
        })
    end,
    getgenv().BossRushEnabled or false
)

Sections.BossRushLeft:Divider()

Sections.BossRushLeft:Header({ Text = "💡 How It Works" })
Sections.BossRushLeft:SubLabel({ 
    Text = "The script automatically selects cards by priority (1-999). Cards set to 999 are skipped. Adjust priorities on the right." 
})

Sections.BossRushLeft:SubLabel({ 
    Text = "Lower number = higher priority • Set to 999 to avoid" 
})


Sections.BossRushRight:Header({ Text = "🃏 Card Priorities" })
Sections.BossRushRight:SubLabel({ Text = "Set priority for each card (1 = highest, 999 = skip)" })
Sections.BossRushRight:Divider()

Sections.BossRushRight:Header({ Text = "🎯 General Cards" })

createCardPriorityInputs(Sections.BossRushRight, getgenv().BossRushGeneral, getgenv().BossRushCardPriority, "BossRush_")

Sections.BossRushRight:Divider()

Sections.BossRushRight:Header({ Text = "🏰 Babylonia Castle Cards" })

pcall(function()
    local babyloniaModule = RS:FindFirstChild("Modules"):FindFirstChild("CardHandler"):FindFirstChild("BossRushCards"):FindFirstChild("Babylonia Castle")
    if babyloniaModule then
        local cards = require(babyloniaModule)
        for _, card in pairs(cards) do
            local cardName = card.CardName
            local cardType = card.CardType or "Buff"
            local inputKey = "BabyloniaCastle_" .. cardName
            
            if not getgenv().BossRushCardPriority then 
                getgenv().BossRushCardPriority = {} 
            end
            if not getgenv().BossRushCardPriority[cardName] then 
                getgenv().BossRushCardPriority[cardName] = 999 
            end
            
            local defaultValue = getgenv().Config.inputs[inputKey] or "999"
            
            createInput(
                Sections.BossRushRight,
                cardName .. " (" .. cardType .. ")",
                inputKey,
                "Priority (1-999)",
                "Numeric",
                function(value)
                    local num = tonumber(value)
                    if num then
                        getgenv().BossRushCardPriority[cardName] = num
                    end
                end,
                defaultValue
            )
            
            getgenv().BossRushCardPriority[cardName] = tonumber(defaultValue) or 999
        end
    end
end)



local UnitNames = nil
pcall(function()
    local unitNamesModule = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("UnitNames")
    if unitNamesModule and unitNamesModule:IsA("ModuleScript") then
        UnitNames = require(unitNamesModule)
    end
end)

local function getUnitDisplayName(unitName)
    if UnitNames and UnitNames[unitName] then
        return UnitNames[unitName]
    end
    return unitName
end


getgenv().BulmaEnabled = getgenv().Config.toggles.BulmaToggle or false
getgenv().BulmaWishType = getgenv().Config.dropdowns.BulmaWishType or "Power"
getgenv().BulmaWishUsedThisRound = false

getgenv().WukongEnabled = getgenv().Config.toggles.WukongToggle or false
getgenv().WukongTrackedClones = {}

getgenv().EventJoinDelay = tonumber(getgenv().Config.inputs.EventJoinDelay) or 0
getgenv().AutoJoinDelay = tonumber(getgenv().Config.inputs.AutoJoinDelay) or 0

getgenv().FinalExpAutoJoinEasyEnabled = getgenv().Config.toggles.FinalExpAutoJoinEasyToggle or false
getgenv().FinalExpAutoJoinHardEnabled = getgenv().Config.toggles.FinalExpAutoJoinHardToggle or false
getgenv().FinalExpAutoSkipShopEnabled = getgenv().Config.toggles.FinalExpAutoSkipShopToggle or false
getgenv().FinalExpAutoSelectModeEnabled = getgenv().Config.toggles.FinalExpAutoSelectModeToggle or false
getgenv().FinalExpSkipRewardsEnabled = getgenv().Config.toggles.FinalExpSkipRewardsToggle or false

getgenv().FinalExpRestPriority = tonumber(getgenv().Config.inputs.FinalExpRestPriority) or 3
getgenv().FinalExpDungeonPriority = tonumber(getgenv().Config.inputs.FinalExpDungeonPriority) or 1
getgenv().FinalExpDoubleDungeonPriority = tonumber(getgenv().Config.inputs.FinalExpDoubleDungeonPriority) or 2

local BLACKLISTED_UNITS = {
    "NarutoBaryonClone"
}

local function isBlacklisted(unitName)
    for _, blacklisted in ipairs(BLACKLISTED_UNITS) do
        if unitName == blacklisted or unitName:find(blacklisted) then
            return true
        end
    end
    return false
end

if not getgenv()._AbilityUIElements then
    getgenv()._AbilityUIElements = {Left = {}, Right = {}}
end

local function clearAbilityUI()
    for side, elements in pairs(getgenv()._AbilityUIElements) do
        for _, element in ipairs(elements) do
            pcall(function()
                if element and element.Remove then
                    element:Remove()
                elseif element and element.SetVisibility then
                    element:SetVisibility(false)
                end
            end)
        end
    end
    getgenv()._AbilityUIElements = {Left = {}, Right = {}}
end


local function buildAutoAbilityUI()
    if getgenv()._AbilityUIBuilding then return end
    if getgenv()._AbilityUIBuilt then return end
    getgenv()._AbilityUIBuilding = true
    
    clearAbilityUI()
    
    local clientData = getClientData()
    if not clientData or not clientData.Slots then
        Window:Notify({
            Title = "Auto Ability",
            Description = "ClientData not available yet, retrying...",
            Lifetime = 3
        })
        getgenv()._AbilityUIBuilt = false
        getgenv()._AbilityUIBuilding = false
        return
    end
    
    local anyBuilt = false
    local success, err = pcall(function()
        local unitsToShow = {}
        
        local sortedSlots = {"Slot1", "Slot2", "Slot3", "Slot4", "Slot5", "Slot6"}
        for slotIndex, slotName in ipairs(sortedSlots) do
            local slotData = clientData.Slots[slotName]
            if slotData and slotData.Value then
                table.insert(unitsToShow, {
                    name = slotData.Value,
                    slot = slotName,
                    level = slotData.Level or 0,
                    slotIndex = slotIndex,
                    isSpawned = false
                })
            end
        end
        
        for _, unitInfo in ipairs(unitsToShow) do
            local unitName = unitInfo.name
            
            if isBlacklisted(unitName) then
                continue
            end
            
            if unitName == "Bulma" then
                continue
            end
            
            local abilities = getAllAbilities(unitName)
            
            if next(abilities) then
                local tabSide = (unitInfo.slotIndex <= 3) and "Left" or "Right"
                local sideKey = tabSide
                
                local displayName = getUnitDisplayName(unitName)
                
                local unitSection = Tabs.Abilities:Section({ Side = tabSide })
                table.insert(getgenv()._AbilityUIElements[sideKey], unitSection)
                
                local headerText = "📦 " .. displayName
                local sublabelText = unitInfo.slot .. " • Level " .. tostring(unitInfo.level)
                
                unitSection:Header({ Text = headerText })
                unitSection:SubLabel({ Text = sublabelText })
                unitSection:Divider()
                
                anyBuilt = true
                
                local targetSection = unitSection
                
                if not getgenv().UnitAbilities then getgenv().UnitAbilities = {} end
                if not getgenv().UnitAbilities[unitName] then getgenv().UnitAbilities[unitName] = {} end
                if not getgenv().Config.abilities then getgenv().Config.abilities = {} end
                if not getgenv().Config.abilities[unitName] then getgenv().Config.abilities[unitName] = {} end
                    
                    local sortedAbilities = {}
                    for abilityName, data in pairs(abilities) do
                        table.insert(sortedAbilities, { name = abilityName, data = data })
                    end
                    table.sort(sortedAbilities, function(a, b)
                        local aLevel = (a.data and a.data.requiredLevel) or 0
                        local bLevel = (b.data and b.data.requiredLevel) or 0
                        return aLevel < bLevel
                    end)
                    
                    for _, ab in ipairs(sortedAbilities) do
                        local abilityName = ab.name
                        local abilityData = ab.data
                        
                        if unitName == "JinMoriGodly" and abilityName == "Clone Synthesis" then
                            continue
                        end
                        
                        local saved = getgenv().Config.abilities and 
                                     getgenv().Config.abilities[unitName] and 
                                     getgenv().Config.abilities[unitName][abilityName]
                        
                        local waveInputFlag = unitName .. "_" .. abilityName .. "_Wave"
                        local savedWave = getgenv().Config.inputs[waveInputFlag]
                        if savedWave and savedWave ~= "" then
                            savedWave = tonumber(savedWave)
                        else
                            savedWave = nil
                        end
                        
                        if not getgenv().UnitAbilities[unitName][abilityName] then
                            getgenv().UnitAbilities[unitName][abilityName] = {
                                enabled = (saved and saved.enabled) or false,
                                onlyOnBoss = (saved and saved.onlyOnBoss) or false,
                                specificWave = savedWave or (saved and saved.specificWave) or nil,
                                requireBossInRange = (saved and saved.requireBossInRange) or false,
                                useOnWave = (saved and saved.useOnWave) or false
                            }
                        end
                        
                        local cfg = getgenv().UnitAbilities[unitName][abilityName]
                        local defaultToggle = cfg.enabled
                        
                        local abilityIcon = abilityData.isAttribute and "🔒" or "⚡"
                        local abilityInfo = abilityIcon .. " " .. abilityName .. " (CD: " .. tostring(abilityData.cooldown) .. "s)"
                        
                        createToggle(
                            targetSection,
                            abilityInfo,
                            unitName .. "_" .. abilityName .. "_Toggle",
                            function(v)
                                cfg.enabled = v
                                getgenv().Config.abilities[unitName] = getgenv().Config.abilities[unitName] or {}
                                getgenv().Config.abilities[unitName][abilityName] = getgenv().Config.abilities[unitName][abilityName] or {}
                                getgenv().Config.abilities[unitName][abilityName].enabled = v
                                getgenv().SaveConfig(getgenv().Config)
                                
                                Window:Notify({
                                    Title = "Auto Ability",
                                    Description = abilityName .. " " .. (v and "Enabled" or "Disabled"),
                                    Lifetime = 2
                                })
                            end,
                            defaultToggle
                        )
                        
                        local modifierKey = unitName .. "_" .. abilityName .. "_Modifiers"
                        
                        local savedDropdown = getgenv().Config.dropdowns[modifierKey]
                        local defaultValue
                        
                        if savedDropdown and type(savedDropdown) == "table" then
                            defaultValue = {}
                            for optionName, isSelected in pairs(savedDropdown) do
                                if isSelected == true then
                                    table.insert(defaultValue, optionName)
                                end
                            end
                        else
                            defaultValue = {}
                            if cfg.onlyOnBoss then table.insert(defaultValue, "Only On Boss") end
                            if cfg.requireBossInRange then table.insert(defaultValue, "Boss In Range") end
                            if cfg.useOnWave then table.insert(defaultValue, "On Wave") end
                        end
                        
                        createDropdown(
                            targetSection,
                            "  > Conditions",
                            modifierKey,
                            {"Only On Boss", "Boss In Range", "On Wave"},
                            true,
                            function(Value)
                                local selectedSet = {}
                                if type(Value) == "table" then
                                    for k, v in pairs(Value) do
                                        if v == true then
                                            selectedSet[k] = true
                                        end
                                    end
                                end
                                
                                cfg.onlyOnBoss = selectedSet["Only On Boss"] == true
                                cfg.requireBossInRange = selectedSet["Boss In Range"] == true
                                cfg.useOnWave = selectedSet["On Wave"] == true
                                
                                getgenv().Config.abilities[unitName] = getgenv().Config.abilities[unitName] or {}
                                local store = getgenv().Config.abilities[unitName]
                                store[abilityName] = store[abilityName] or {}
                                store[abilityName].onlyOnBoss = cfg.onlyOnBoss
                                store[abilityName].requireBossInRange = cfg.requireBossInRange
                                store[abilityName].useOnWave = cfg.useOnWave
                                
                                getgenv().SaveConfig(getgenv().Config)
                            end,
                            defaultValue
                        )
                        
                        local waveFlag = unitName .. "_" .. abilityName .. "_Wave"
                        local waveDefault = ""
                        if cfg.specificWave then
                            waveDefault = tostring(cfg.specificWave)
                        elseif getgenv().Config.inputs[waveFlag] and getgenv().Config.inputs[waveFlag] ~= "" then
                            waveDefault = tostring(getgenv().Config.inputs[waveFlag])
                        end
                        
                        createInput(
                            targetSection,
                            "  > Wave Number",
                            waveFlag,
                            "Required if 'On Wave' selected",
                            "Numeric",
                            function(text)
                                local num = tonumber(text)
                                cfg.specificWave = num
                                getgenv().Config.abilities[unitName] = getgenv().Config.abilities[unitName] or {}
                                getgenv().Config.abilities[unitName][abilityName] = getgenv().Config.abilities[unitName][abilityName] or {}
                                getgenv().Config.abilities[unitName][abilityName].specificWave = num
                                getgenv().SaveConfig(getgenv().Config)
                            end,
                            waveDefault
                        )
                    end
                end
            end
    end)
    
    if not success then
        warn("[Auto Ability UI] build failed: " .. tostring(err))
    end
    
    pcall(function()
        local clientData = getClientData()
        if clientData and clientData.Slots then
            local hasBulma = false
            for _, slotName in ipairs({"Slot1", "Slot2", "Slot3", "Slot4", "Slot5", "Slot6"}) do
                local slotData = clientData.Slots[slotName]
                if slotData and slotData.Value == "Bulma" then
                    hasBulma = true
                    break
                end
            end
            
            local hasBulma = false
            local hasWukong = false
            
            for _, slotName in ipairs({"Slot1", "Slot2", "Slot3", "Slot4", "Slot5", "Slot6"}) do
                local slotData = clientData.Slots[slotName]
                if slotData and slotData.Value then
                    if slotData.Value == "Bulma" then
                        hasBulma = true
                    elseif slotData.Value == "JinMoriGodly" then
                        hasWukong = true
                    end
                end
            end
            
            if hasBulma or hasWukong then
                local specialSection = Tabs.Abilities:Section({ Side = "Left" })
                table.insert(getgenv()._AbilityUIElements["Left"], specialSection)
                
                specialSection:Header({ Text = "🔮 Auto Units" })
                specialSection:Divider()
                
                if hasBulma then
                    createToggle(
                        specialSection,
                        "Bulma Auto-Wish",
                        "BulmaToggle",
                        function(value)
                            getgenv().BulmaEnabled = value
                            Window:Notify({
                                Title = "Bulma Auto-Wish",
                                Description = value and "Enabled" or "Disabled",
                                Lifetime = 2
                            })
                        end,
                        getgenv().BulmaEnabled
                    )
                    
                    
                    createDropdown(
                        specialSection,
                        "  > Wish Type",
                        "BulmaWishType",
                        {"Power", "Wealth", "Time"},
                        false,
                        function(value)
                            getgenv().BulmaWishType = value
                            Window:Notify({
                                Title = "Bulma Auto-Wish",
                                Description = "Wish type set to: " .. value,
                                Lifetime = 2
                            })
                        end,
                        getgenv().BulmaWishType or "Power"
                    )
                end
                
                if hasWukong then
                    if hasBulma then
                        specialSection:Divider()
                    end
                    
                    createToggle(
                        specialSection,
                        "Auto Wukong (Jin Mori)",
                        "WukongToggle",
                        function(value)
                            getgenv().WukongEnabled = value
                            Window:Notify({
                                Title = "Auto Wukong",
                                Description = value and "Enabled" or "Disabled",
                                Lifetime = 2
                            })
                        end,
                        getgenv().WukongEnabled
                    )
                end
            end
        end
    end)
    
    getgenv()._AbilityUIBuilt = anyBuilt
    getgenv()._AbilityUIBuilding = false
end

task.spawn(function()
    task.wait(2 * MOBILE_DELAY_MULTIPLIER)
    local maxRetries, retryDelay = 10, 3 * MOBILE_DELAY_MULTIPLIER
    
    for i = 1, maxRetries do
        pcall(function()
            local cd = getClientData()
            if cd and cd.Slots then
                buildAutoAbilityUI()
            else
                if i <= 3 then
                    Window:Notify({
                        Title = "Auto Ability",
                        Description = "Loading units... (" .. i .. "/" .. maxRetries .. ")",
                        Lifetime = 2
                    })
                end
            end
        end)
        
        if getgenv()._AbilityUIBuilt then break end
        task.wait(retryDelay)
    end
end)



Sections.MacroLeft:Header({ Text = "📁 Macro Management" })
Sections.MacroLeft:SubLabel({ Text = "Create, select, and manage your macros" })

local macroDropdown = createDropdown(
    Sections.MacroLeft,
    "Select Macro",
    "MacroSelect",
    getMacroNames(),
    false,
    function(value)
        getgenv().CurrentMacro = value
        if value and getgenv().Macros[value] then
            getgenv().MacroData = getgenv().Macros[value]
            getgenv().MacroTotalSteps = #getgenv().MacroData
            Window:Notify({
                Title = "Macro System",
                Description = "Selected: " .. value,
                Lifetime = 2
            })
        end
        saveMacroSettings()
        getgenv().UpdateMacroStatus()
    end,
    getgenv().CurrentMacro
)

local macroCreateInput = createInput(
    Sections.MacroLeft,
    "Create New Macro",
    "MacroCreateNew",
    "Enter macro name and press Enter",
    "All",
    function(value)
        if not value or value == "" then
            Window:Notify({
                Title = "Macro System",
                Description = "Please enter a macro name",
                Lifetime = 3
            })
            return
        end
        
        if getgenv().Macros[value] then
            Window:Notify({
                Title = "Macro System",
                Description = "Macro '" .. value .. "' already exists",
                Lifetime = 3
            })
            return
        end
        
        local success = saveMacro(value, {})
        if success then
            loadMacros()
            local macroNames = getMacroNames()
            if macroDropdown then
                pcall(function()
                    macroDropdown:ClearOptions()
                    macroDropdown:InsertOptions(macroNames)
                    macroDropdown:UpdateSelection(value)
                end)
            end
            getgenv().CurrentMacro = value
            getgenv().MacroData = {}
            getgenv().MacroTotalSteps = 0
            
            if macroCreateInput and macroCreateInput.UpdateText then
                pcall(function()
                    macroCreateInput:UpdateText("")
                end)
                task.wait(0.1)
                pcall(function()
                    macroCreateInput:UpdateText("")
                end)
            end
            
            Window:Notify({
                Title = "Macro System",
                Description = "Created: " .. value,
                Lifetime = 3
            })
        else
            Window:Notify({
                Title = "Macro System",
                Description = "Failed to create macro",
                Lifetime = 3
            })
        end
    end,
    ""
)

Sections.MacroLeft:Button({
    Name = "🔄 Refresh Macro List",
    Callback = function()
        loadMacros()
        local macroNames = getMacroNames()
        if macroDropdown then
            pcall(function()
                macroDropdown:ClearOptions()
                macroDropdown:InsertOptions(macroNames)
            end)
        end
        Window:Notify({
            Title = "Macro System",
            Description = "Loaded " .. #macroNames .. " macro(s)",
            Lifetime = 2
        })
    end,
})

Sections.MacroLeft:Divider()

Sections.MacroLeft:Header({ Text = "🎬 Recording & Playback" })
Sections.MacroLeft:SubLabel({ Text = "Record new macros or play existing ones" })

local macroRecordToggle = createToggleNoSave(
    Sections.MacroLeft,
    "Record Macro",
    "MacroRecordToggle",
    function(value)
        if value then
            if not getgenv().CurrentMacro or getgenv().CurrentMacro == "" then
                Window:Notify({
                    Title = "Macro System",
                    Description = "Please select or create a macro first",
                    Lifetime = 3
                })
                pcall(function()
                    macroRecordToggle:UpdateState(false)
                end)
                return
            end
            
            getgenv().MacroRecordingV2 = true
            getgenv().MacroDataV2 = {}
            getgenv().MacroRecordingStartTime = tick()
            getgenv().MacroStatusText = "Recording"
            getgenv().MacroCurrentStep = 0
            getgenv().MacroTotalSteps = 0
            
            print("[Macro Recording] Started recording for:", getgenv().CurrentMacro)
            print("[Macro Recording] MacroRecordingV2 =", getgenv().MacroRecordingV2)
            
            if getgenv().UpdateMacroStatus then
                getgenv().UpdateMacroStatus()
            end
            
            Window:Notify({
                Title = "Macro Recording",
                Description = "Recording started for: " .. getgenv().CurrentMacro,
                Lifetime = 3
            })
        else
            getgenv().MacroRecordingV2 = false
            
            if #getgenv().MacroDataV2 > 0 and getgenv().CurrentMacro then
                local success = saveMacro(getgenv().CurrentMacro, getgenv().MacroDataV2)
                if success then
                    Window:Notify({
                        Title = "Macro Recording",
                        Description = "Saved " .. #getgenv().MacroDataV2 .. " steps to " .. getgenv().CurrentMacro,
                        Lifetime = 5
                    })
                else
                    Window:Notify({
                        Title = "Macro Recording",
                        Description = "Failed to save macro",
                        Lifetime = 3
                    })
                end
            else
                Window:Notify({
                    Title = "Macro Recording",
                    Description = "Recording stopped (no actions recorded)",
                    Lifetime = 3
                })
            end
            
            getgenv().MacroStatusText = "Idle"
            getgenv().MacroCurrentStep = 0
            getgenv().MacroTotalSteps = 0
        end
        getgenv().UpdateMacroStatus()
    end,
    false
)

getgenv().MacroPlayToggle = createToggle(
    Sections.MacroLeft,
    "Play Macro",
    "MacroPlayToggle",
    function(value)
        
        if value then
            if not getgenv().CurrentMacro or getgenv().CurrentMacro == "" then
                Window:Notify({
                    Title = "Macro System",
                    Description = "Please select a macro first",
                    Lifetime = 3
                })
                getgenv().MacroPlayEnabled = false
                pcall(function()
                    getgenv().MacroPlayToggle:UpdateState(false)
                end)
                return
            end
            
            if not getgenv().Macros[getgenv().CurrentMacro] or #getgenv().Macros[getgenv().CurrentMacro] == 0 then
                Window:Notify({
                    Title = "Macro System",
                    Description = "Selected macro is empty",
                    Lifetime = 3
                })
                getgenv().MacroPlayEnabled = false
                pcall(function()
                    getgenv().MacroPlayToggle:UpdateState(false)
                end)
                return
            end
            
            getgenv().MacroPlayEnabled = true
            getgenv().MacroStatusText = "Playing"
            Window:Notify({
                Title = "Macro Playback",
                Description = "Started: " .. getgenv().CurrentMacro .. " (" .. #getgenv().Macros[getgenv().CurrentMacro] .. " steps)",
                Lifetime = 3
            })
        else
            getgenv().MacroPlayEnabled = false
            getgenv().MacroStatusText = "Idle"
            Window:Notify({
                Title = "Macro Playback",
                Description = "Stopped",
                Lifetime = 3
            })
        end
        saveMacroSettings()
        getgenv().UpdateMacroStatus()
    end,
    getgenv().MacroPlayEnabled or false
)

createInput(
    Sections.MacroLeft,
    "Step Delay (seconds)",
    "MacroStepDelay",
    "Additional delay between steps",
    "Numeric",
    function(value)
        local delay = tonumber(value) or 0
        getgenv().MacroStepDelay = delay
        saveMacroSettings()
    end,
    tostring(getgenv().MacroStepDelay or 0)
)

Sections.MacroLeft:Divider()

Sections.MacroLeft:Header({ Text = "📊 Macro Status" })
Sections.MacroLeft:SubLabel({ Text = "Real-time playback information" })

getgenv().MacroStatusLabel = Sections.MacroLeft:Label({ Text = "Status: Idle" })
getgenv().MacroStepLabel = Sections.MacroLeft:Label({ Text = "📝 Step: 0/0" })
getgenv().MacroActionLabel = Sections.MacroLeft:Label({ Text = "⚡ Action: None" })
getgenv().MacroUnitLabel = Sections.MacroLeft:Label({ Text = "🗼 Unit: None" })
getgenv().MacroWaitingLabel = Sections.MacroLeft:Label({ Text = "⏳ Waiting: None" })


Sections.MacroRight:Header({ Text = "🗺️ Macro Maps" })
Sections.MacroRight:SubLabel({
    Text = "Assign macros to specific maps. When you join a game, the assigned macro will auto-load."
})

local selectedGamemode = "Story"
local mapElementsByGamemode = {}

local function updateMacroMapDisplay()
    for gamemode, elements in pairs(mapElementsByGamemode) do
        for _, element in pairs(elements) do
            pcall(function()
                if element and element.SetVisibility then
                    element:SetVisibility(false)
                end
            end)
        end
    end
    
    if mapElementsByGamemode[selectedGamemode] then
        for _, element in pairs(mapElementsByGamemode[selectedGamemode]) do
            pcall(function()
                if element and element.SetVisibility then
                    element:SetVisibility(true)
                end
            end)
        end
        return
    end
    
    mapElementsByGamemode[selectedGamemode] = {}
    local elements = mapElementsByGamemode[selectedGamemode]
    
    local maps = getMapsByMode(selectedGamemode)
    
    if #maps == 0 then
        local label = Sections.MacroRight:SubLabel({
            Text = "No maps available for " .. selectedGamemode
        })
        table.insert(elements, label)
        return
    end
    
    local divider = Sections.MacroRight:Divider()
    local header = Sections.MacroRight:SubLabel({ Text = "📍 " .. selectedGamemode .. " Maps" })
    table.insert(elements, divider)
    table.insert(elements, header)
    
    for _, mapName in ipairs(maps) do
        local key = selectedGamemode .. "_" .. mapName
        local currentMacro = getgenv().MacroMaps[key] or "None"
        
        local macroNames = getMacroNames()
        table.insert(macroNames, 1, "None")
        
        local dropdown = createDropdown(
            Sections.MacroRight,
            mapName,
            "MacroMap_" .. key,
            macroNames,
            false,
            function(value)
                if value ~= "None" then
                    getgenv().MacroMaps[key] = value
                    Window:Notify({
                        Title = "Macro Maps",
                        Description = mapName .. " → " .. value,
                        Lifetime = 2
                    })
                else
                    getgenv().MacroMaps[key] = nil
                    Window:Notify({
                        Title = "Macro Maps",
                        Description = mapName .. " cleared",
                        Lifetime = 2
                    })
                end
                saveMacroSettings()
            end,
            currentMacro
        )
        
        table.insert(elements, dropdown)
    end
end

local savedGamemode = getgenv().Config.dropdowns.MacroMapsGamemode or "Story"
selectedGamemode = savedGamemode

local gamemodeDropdown = createDropdown(
    Sections.MacroRight,
    "Select Gamemode",
    "MacroMapsGamemode",
    {"Story", "Infinite", "Challenge", "LegendaryStages", "Raids", "Dungeon", "Survival", "ElementalCaverns", "Event", "MidnightHunt", "BossRush", "Siege", "Breach"},
    false,
    function(value)
        selectedGamemode = value
        task.spawn(function()
            updateMacroMapDisplay()
        end)
    end,
    savedGamemode
)

task.spawn(function()
    task.wait(0.2)
    updateMacroMapDisplay()
end)




local function getMapsByGamemode(mode)
    if not MapData then return {} end
    if mode == "ElementalCaverns" then return {"Light","Nature","Fire","Dark","Water"} end
    local maps = {}
    for mapName, mapInfo in pairs(MapData) do
        if mapInfo.Type and type(mapInfo.Type) == "table" then
            for _, mapType in ipairs(mapInfo.Type) do
                if mapType == mode then 
                    table.insert(maps, mapName) 
                    break 
                end
            end
        end
    end
    table.sort(maps)
    return maps
end


Sections.WebhookLeft:Header({ Text = "🔔 Discord Integration" })
Sections.WebhookLeft:SubLabel({ Text = "Send game notifications to Discord" })

getgenv().WebhookEnabled = getgenv().Config.toggles.WebhookToggle or false
getgenv().WebhookURL = getgenv().Config.inputs.WebhookURL or ""
getgenv().DiscordUserID = getgenv().Config.inputs.DiscordUserID or ""
getgenv().PingOnSecretDrop = getgenv().Config.toggles.PingOnSecretToggle or false

createToggle(
    Sections.WebhookLeft,
    "Enable Webhook Notifications",
    "WebhookToggle",
    function(value)
        getgenv().WebhookEnabled = value
        if value then
            if (getgenv().WebhookURL == "" or not string.match(getgenv().WebhookURL, "^https://discord%.com/api/webhooks/")) then
                Window:Notify({
                    Title = "Webhook",
                    Description = "Please enter a valid webhook URL first",
                    Lifetime = 5
                })
                getgenv().WebhookEnabled = false
                getgenv().Config.toggles.WebhookToggle = false
                getgenv().SaveConfig(getgenv().Config)
            else
                Window:Notify({
                    Title = "Webhook",
                    Description = "Enabled",
                    Lifetime = 3
                })
            end
        else
            Window:Notify({
                Title = "Webhook",
                Description = "Disabled",
                Lifetime = 3
            })
        end
    end,
    getgenv().WebhookEnabled
)

Sections.WebhookLeft:Divider()

Sections.WebhookLeft:Header({ Text = "⚙️ Configuration" })
Sections.WebhookLeft:SubLabel({ Text = "Enter your Discord webhook details" })

createInput(
    Sections.WebhookLeft,
    "Webhook URL",
    "WebhookURL",
    "https://discord.com/api/webhooks/...",
    "All",
    function(value)
        getgenv().WebhookURL = value or ""
    end,
    getgenv().WebhookURL
)

createInput(
    Sections.WebhookLeft,
    "Discord User ID",
    "DiscordUserID",
    "123456789012345678",
    "Numeric",
    function(value)
        getgenv().DiscordUserID = value or ""
    end,
    getgenv().DiscordUserID
)

Sections.WebhookLeft:Divider()

Sections.WebhookLeft:Header({ Text = "🔔 Notification Preferences" })
Sections.WebhookLeft:SubLabel({ Text = "Customize when you get pinged" })

createToggle(
    Sections.WebhookLeft,
    "Ping on Secret Drop",
    "PingOnSecretToggle",
    function(value)
        getgenv().PingOnSecretDrop = value
        Window:Notify({
            Title = "Ping on Secret",
            Description = value and "Enabled" or "Disabled",
            Lifetime = 3
        })
    end,
    getgenv().PingOnSecretDrop
)


Sections.MiscLeft:Header({ Text = "⚡ Performance" })
Sections.MiscLeft:SubLabel({ Text = "Boost FPS and reduce lag" })

local isInLobby = false
pcall(function()
    local lobbyCheck = workspace:FindFirstChild("Lobby") or game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name:find("Lobby")
    isInLobby = lobbyCheck ~= nil
end)

if not isInLobby then
    createToggle(
        Sections.MiscLeft,
        "FPS Boost",
        "FPSBoostToggle",
        function(value)
            getgenv().FPSBoostEnabled = value
            Window:Notify({
                Title = "FPS Boost",
                Description = value and "Enabled" or "Disabled",
                Lifetime = 3
            })
        end,
        getgenv().FPSBoostEnabled
    )
else
    getgenv().FPSBoostEnabled = false
end

createToggle(
    Sections.MiscLeft,
    "Remove Enemies & Units",
    "RemoveEnemiesToggle",
    function(value)
        getgenv().RemoveEnemiesEnabled = value
        Window:Notify({
            Title = "Remove Enemies",
            Description = value and "Enabled" or "Disabled",
            Lifetime = 3
        })
    end,
    getgenv().RemoveEnemiesEnabled
)

createToggle(
    Sections.MiscLeft,
    "Black Screen Mode",
    "BlackScreenToggle",
    function(value)
        getgenv().BlackScreenEnabled = value
        Window:Notify({
            Title = "Black Screen",
            Description = value and "Enabled" or "Disabled",
            Lifetime = 3
        })
        pcall(function()
            local Lighting = game:GetService("Lighting")
            if value then
                Lighting.Brightness = 0
                Lighting.ClockTime = 0
                Lighting.FogEnd = 0
                Lighting.GlobalShadows = false
                Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
            else
                Lighting.Brightness = 2
                Lighting.ClockTime = 14
                Lighting.FogEnd = 100000
                Lighting.GlobalShadows = true
                Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
            end
        end)
    end,
    getgenv().BlackScreenEnabled
)

Sections.MiscLeft:Divider()

Sections.MiscLeft:Header({ Text = "🛡️ Safety" })
Sections.MiscLeft:SubLabel({ Text = "Stay safe and avoid detection" })

createToggle(
    Sections.MiscLeft,
    "Anti-AFK",
    "AntiAFKToggle",
    function(value)
        getgenv().AntiAFKEnabled = value
        Window:Notify({
            Title = "Anti-AFK",
            Description = value and "Enabled" or "Disabled",
            Lifetime = 3
        })
    end,
    getgenv().AntiAFKEnabled
)

createToggle(
    Sections.MiscLeft,
    "Auto Hide UI on Load",
    "AutoHideUI",
    function(value)
        getgenv().AutoHideUIEnabled = value
        Window:Notify({
            Title = "Auto Hide UI",
            Description = value and "Enabled - UI will minimize on next load" or "Disabled",
            Lifetime = 3
        })
    end,
    false
)

createToggle(
    Sections.MiscLeft,
    "Auto Execute on Teleport",
    "AutoExecuteToggle",
    function(value)
        getgenv().AutoExecuteEnabled = value
        
        local queueteleport = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
        
        if value and queueteleport then
            print("[ALS] Auto Execute on Teleport enabled")
        elseif value and not queueteleport then
            warn("[ALS] Auto Execute enabled but queue_on_teleport not supported by your executor")
        end
        
        Window:Notify({
            Title = "Auto Execute",
            Description = value and "Enabled - Script will auto-load on teleport" or "Disabled",
            Lifetime = 3
        })
    end,
    getgenv().AutoExecuteEnabled
)


Sections.MiscRight:Header({ Text = "ℹ️ Information" })
Sections.MiscRight:SubLabel({ Text = "Important notes and warnings" })

Sections.MiscRight:Divider()

Sections.MiscRight:SubLabel({
    Text = "⚠️ Do NOT enable Auto Execute if you already have this script in your executor's auto-execute folder!"
})

Sections.MiscRight:SubLabel({
    Text = "💡 FPS Boost is only available in-game. Remove Enemies and Black Screen Mode provide performance boosts."
})


Sections.SettingsLeft:Header({ Text = "⚙️ UI Settings" })

local menuKeybind = Sections.SettingsLeft:Keybind({
    Name = "Menu Toggle",
    Default = Enum.KeyCode[getgenv().Config.inputs["MenuKeybind"] or "LeftControl"],
    Callback = function(key)
        Window:SetKeybind(key)
        getgenv().Config.inputs["MenuKeybind"] = key.Name
        getgenv().SaveConfig(getgenv().Config)
        Window:Notify({
            Title = "Keybind Updated",
            Description = "Menu toggle set to " .. key.Name,
            Lifetime = 3
        })
    end,
}, "MenuKeybind")

if getgenv().Config.inputs["MenuKeybind"] then
    pcall(function()
        Window:SetKeybind(Enum.KeyCode[getgenv().Config.inputs["MenuKeybind"]])
    end)
end

Sections.SettingsLeft:Divider()

Sections.SettingsLeft:Header({ Text = "🖥️ UI Size (Restart Required)" })
Sections.SettingsLeft:SubLabel({ Text = "Custom window size - changes apply on next script load" })

createInput(
    Sections.SettingsLeft,
    "Width",
    "UIWidth",
    "Default: 580 (mobile) or 868 (desktop)",
    "Numeric",
    function(value)
        local width = tonumber(value)
        if width and width >= 400 and width <= 1920 then
            getgenv().Config.inputs.UIWidth = width
            saveConfig(getgenv().Config)
            Window:Notify({
                Title = "UI Width",
                Description = "Set to " .. width .. " (restart to apply)",
                Lifetime = 3
            })
        end
    end,
    tostring(getgenv().Config.inputs.UIWidth or (isMobile and 580 or 868))
)

createInput(
    Sections.SettingsLeft,
    "Height",
    "UIHeight",
    "Default: 480 (mobile) or 650 (desktop)",
    "Numeric",
    function(value)
        local height = tonumber(value)
        if height and height >= 300 and height <= 1080 then
            getgenv().Config.inputs.UIHeight = height
            saveConfig(getgenv().Config)
            Window:Notify({
                Title = "UI Height",
                Description = "Set to " .. height .. " (restart to apply)",
                Lifetime = 3
            })
        end
    end,
    tostring(getgenv().Config.inputs.UIHeight or (isMobile and 480 or 650))
)

Sections.SettingsLeft:Divider()

Sections.SettingsLeft:Header({ Text = "💾 Configuration" })

Sections.SettingsLeft:Button({
    Name = "💾 Save Config",
    Callback = function()
        local success = saveConfig(getgenv().Config)
        if success then
            Window:Notify({
                Title = "Config",
                Description = "Settings saved successfully!",
                Lifetime = 3
            })
        else
            Window:Notify({
                Title = "Config",
                Description = "Failed to save settings!",
                Lifetime = 5
            })
        end
    end
})

Sections.SettingsLeft:Button({
    Name = "📁 Load Config",
    Callback = function()
        getgenv().Config = loadConfig()
        Window:Notify({
            Title = "Config",
            Description = "Config loaded! Restart script to apply.",
            Lifetime = 5
        })
    end
})

Sections.SettingsRight:Header({ Text = "🔧 Utility Actions" })

Sections.SettingsRight:Button({
    Name = "🌐 Server Hop (Safe)",
    Callback = function()
        Window:Notify({
            Title = "Server Hop",
            Description = "Cleaning up and hopping to new server...",
            Lifetime = 3
        })
        task.spawn(function()
            task.wait(1)
            pcall(function()
                if getgenv().MacroEnabled then
                    getgenv().MacroEnabled = false
                end
                if getgenv().AutoJoinEnabled then
                    getgenv().AutoJoinEnabled = false
                end
            end)
            local ok, err = pcall(function()
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
            end)
            if not ok then
                warn("[Server Hop] Failed:", err)
                Window:Notify({
                    Title = "Server Hop",
                    Description = "Failed to hop servers!",
                    Lifetime = 5
                })
            end
        end)
    end
})



getgenv().BreachAutoJoin = getgenv().BreachAutoJoin or {}
getgenv().BreachEnabled = getgenv().Config.toggles.BreachToggle or false

Sections.BreachLeft:Header({ Text = "🛡️ Breach Auto-Join" })
Sections.BreachLeft:SubLabel({ Text = "Automatically join specific Breach modes" })

createToggle(
    Sections.BreachLeft,
    "Enable Breach Auto-Join",
    "BreachToggle",
    function(value)
        getgenv().BreachEnabled = value
        Window:Notify({
            Title = "Breach Auto-Join",
            Description = value and "Enabled" or "Disabled",
            Lifetime = 3
        })
    end,
    getgenv().BreachEnabled
)

Sections.BreachLeft:Divider()

Sections.BreachLeft:Header({ Text = "📋 Available Breaches" })
Sections.BreachLeft:SubLabel({ Text = "Select which breaches to auto-join" })

local breachesLoaded = false
pcall(function()
    local mapParamsModule = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("Breach") and RS.Modules.Breach:FindFirstChild("MapParameters")
    if mapParamsModule and mapParamsModule:IsA("ModuleScript") then
        local mapParams = require(mapParamsModule)
        if mapParams and next(mapParams) then
            local breachList = {}
            for breachName, breachInfo in pairs(mapParams) do
                table.insert(breachList, { name = breachName, disabled = breachInfo.Disabled or false })
            end
            table.sort(breachList, function(a,b) return a.name < b.name end)
            
            for _, breach in ipairs(breachList) do
                local breachKey = "Breach_" .. breach.name
                local savedState = getgenv().Config.toggles[breachKey] or false
                
                if not getgenv().BreachAutoJoin[breach.name] then
                    getgenv().BreachAutoJoin[breach.name] = savedState
                end
                
                local statusText = breach.disabled and " [DISABLED]" or ""
                createToggle(
                    Sections.BreachLeft,
                    breach.name .. statusText,
                    breachKey,
                    function(value)
                        getgenv().BreachAutoJoin[breach.name] = value
                    end,
                    savedState
                )
            end
            breachesLoaded = true
        end
    end
end)

if not breachesLoaded then
    Sections.BreachLeft:SubLabel({
        Text = "⚠️ Could not load breach data. The module may not be available."
    })
end


Sections.BreachRight:Header({ Text = "👹 Sukuna's Fingers" })
Sections.BreachRight:SubLabel({ Text = "Automatically unleash Sukuna's fingers" })

getgenv().AutoUnleashSukunaEnabled = getgenv().Config.toggles.AutoUnleashSukunaToggle or false

createToggle(
    Sections.BreachRight,
    "Auto Unleash Sukuna's Fingers",
    "AutoUnleashSukunaToggle",
    function(value)
        getgenv().AutoUnleashSukunaEnabled = value
        Window:Notify({
            Title = "Sukuna's Fingers",
            Description = value and "Auto-unleash enabled" or "Auto-unleash disabled",
            Lifetime = 3
        })
    end,
    getgenv().AutoUnleashSukunaEnabled
)

Sections.BreachRight:Divider()

Sections.BreachRight:SubLabel({
    Text = "When enabled, the script will automatically teleport to and interact with the shrine to unleash Sukuna's fingers."
})


Sections.FinalExpeditionLeft:Header({ Text = "🏔️ Auto Join" })
Sections.FinalExpeditionLeft:SubLabel({ Text = "Automatically join Final Expedition with your preferred difficulty" })

createToggle(
    Sections.FinalExpeditionLeft,
    "Auto Join Easy",
    "FinalExpAutoJoinEasyToggle",
    function(value)
        getgenv().FinalExpAutoJoinEasyEnabled = value
        if value and getgenv().FinalExpAutoJoinHardEnabled then
            getgenv().FinalExpAutoJoinHardEnabled = false
            getgenv().Config.toggles.FinalExpAutoJoinHardToggle = false
            saveConfig(getgenv().Config)
            pcall(function()
                if getgenv().FinalExpAutoJoinHardToggle then
                    getgenv().FinalExpAutoJoinHardToggle:UpdateState(false)
                end
            end)
        end
        Window:Notify({
            Title = "Final Expedition",
            Description = value and "Auto Join Easy Enabled" or "Auto Join Easy Disabled",
            Lifetime = 3
        })
    end,
    getgenv().FinalExpAutoJoinEasyEnabled
)

local finalExpHardToggle = createToggle(
    Sections.FinalExpeditionLeft,
    "Auto Join Hard",
    "FinalExpAutoJoinHardToggle",
    function(value)
        getgenv().FinalExpAutoJoinHardEnabled = value
        if value and getgenv().FinalExpAutoJoinEasyEnabled then
            getgenv().FinalExpAutoJoinEasyEnabled = false
            getgenv().Config.toggles.FinalExpAutoJoinEasyToggle = false
            saveConfig(getgenv().Config)
            pcall(function()
                if getgenv().FinalExpAutoJoinEasyToggle then
                    getgenv().FinalExpAutoJoinEasyToggle:UpdateState(false)
                end
            end)
        end
        Window:Notify({
            Title = "Final Expedition",
            Description = value and "Auto Join Hard Enabled" or "Auto Join Hard Disabled",
            Lifetime = 3
        })
    end,
    getgenv().FinalExpAutoJoinHardEnabled
)

getgenv().FinalExpAutoJoinHardToggle = finalExpHardToggle

Sections.FinalExpeditionLeft:SubLabel({
    Text = "⚠️ Only enable ONE auto join option at a time"
})

Sections.FinalExpeditionRight:Header({ Text = "⚙️ Automation" })
Sections.FinalExpeditionRight:SubLabel({ Text = "Additional automation options" })

createToggle(
    Sections.FinalExpeditionRight,
    "Auto Skip Shop",
    "FinalExpAutoSkipShopToggle",
    function(value)
        getgenv().FinalExpAutoSkipShopEnabled = value
        Window:Notify({
            Title = "Final Expedition",
            Description = value and "Auto Skip Shop Enabled" or "Auto Skip Shop Disabled",
            Lifetime = 3
        })
    end,
    getgenv().FinalExpAutoSkipShopEnabled
)

Sections.FinalExpeditionRight:SubLabel({
    Text = "Automatically skips the shop selection when available"
})

Sections.FinalExpeditionRight:Divider()

createToggle(
    Sections.FinalExpeditionRight,
    "Skip Rewards",
    "FinalExpSkipRewardsToggle",
    function(value)
        getgenv().FinalExpSkipRewardsEnabled = value
        Window:Notify({
            Title = "Final Expedition",
            Description = value and "Skip Rewards Enabled" or "Skip Rewards Disabled",
            Lifetime = 3
        })
    end,
    getgenv().FinalExpSkipRewardsEnabled
)

Sections.FinalExpeditionRight:SubLabel({
    Text = "Automatically skips reward screens"
})

Sections.FinalExpeditionRight:Divider()

Sections.FinalExpeditionRight:Header({ Text = "🎯 Auto Select Mode" })
Sections.FinalExpeditionRight:SubLabel({ Text = "Automatically select Rest/Dungeon/Double Dungeon based on priority" })

createToggle(
    Sections.FinalExpeditionRight,
    "Enable Auto Select Mode",
    "FinalExpAutoSelectModeToggle",
    function(value)
        getgenv().FinalExpAutoSelectModeEnabled = value
        Window:Notify({
            Title = "Final Expedition",
            Description = value and "Auto Select Mode Enabled" or "Auto Select Mode Disabled",
            Lifetime = 3
        })
    end,
    getgenv().FinalExpAutoSelectModeEnabled
)

createInput(
    Sections.FinalExpeditionRight,
    "Rest Priority (1-3)",
    "FinalExpRestPriority",
    "3",
    "Numeric",
    function(value)
        local num = tonumber(value) or 3
        if num < 1 then num = 1 end
        if num > 3 then num = 3 end
        getgenv().FinalExpRestPriority = num
    end
)

createInput(
    Sections.FinalExpeditionRight,
    "Dungeon Priority (1-3)",
    "FinalExpDungeonPriority",
    "1",
    "Numeric",
    function(value)
        local num = tonumber(value) or 1
        if num < 1 then num = 1 end
        if num > 3 then num = 3 end
        getgenv().FinalExpDungeonPriority = num
    end
)

createInput(
    Sections.FinalExpeditionRight,
    "Double Dungeon Priority (1-3)",
    "FinalExpDoubleDungeonPriority",
    "2",
    "Numeric",
    function(value)
        local num = tonumber(value) or 2
        if num < 1 then num = 1 end
        if num > 3 then num = 3 end
        getgenv().FinalExpDoubleDungeonPriority = num
    end
)

Sections.FinalExpeditionRight:SubLabel({
    Text = "1 = Highest priority, 3 = Lowest priority"
})


Sections.SeamlessFixLeft:Header({ Text = "🔄 Seamless Fix" })
Sections.SeamlessFixLeft:SubLabel({ Text = "Keep script running across teleports" })

Sections.SeamlessFixLeft:Divider()

Sections.SeamlessFixLeft:Header({ Text = "💡 What is Seamless Fix?" })
Sections.SeamlessFixLeft:SubLabel({
    Text = "Seamless Fix ensures the script continues running smoothly when you teleport between game instances. No need to manually re-execute!"
})

Sections.SeamlessFixLeft:Divider()

Sections.SeamlessFixLeft:Header({ Text = "⚙️ Settings" })

createToggle(
    Sections.SeamlessFixLeft,
    "Enable Seamless Fix",
    "SeamlessFixToggle",
    function(value)
        getgenv().SeamlessFixEnabled = value
        
        task.spawn(function()
            pcall(function()
                local remotes = RS:FindFirstChild("Remotes")
                local setSettings = remotes and remotes:FindFirstChild("SetSettings")
                if setSettings then 
                    setSettings:InvokeServer("SeamlessRetry")
                end
            end)
        end)
        
        Window:Notify({
            Title = "Seamless Fix",
            Description = value and "Enabled - Script will persist through teleports" or "Disabled",
            Lifetime = 3
        })
    end,
    getgenv().SeamlessFixEnabled
)

createInput(
    Sections.SeamlessFixLeft,
    "Rounds Before Restart",
    "SeamlessRounds",
    "Enter number of rounds (e.g., 4)",
    "Numeric",
    function(value)
        getgenv().SeamlessRounds = tonumber(value) or 4
        Window:Notify({
            Title = "Seamless Fix",
            Description = "Will restart after " .. (tonumber(value) or 4) .. " rounds",
            Lifetime = 3
        })
    end,
    tostring(getgenv().Config.inputs.SeamlessRounds or "4")
)

Sections.SeamlessFixLeft:SubLabel({
    Text = "Script will automatically restart after this many rounds to prevent issues"
})


task.spawn(function()
    task.wait(2)
    
    pcall(function()
        
        local toggleCount = 0
        for flag, value in pairs(getgenv().Config.toggles) do
            local element = MacLib.Flags[flag]
            if element and element.UpdateState then
                pcall(function()
                    element:UpdateState(value)
                    toggleCount = toggleCount + 1
                end)
            end
        end
        
        local inputCount = 0
        for flag, value in pairs(getgenv().Config.inputs) do
            local element = MacLib.Flags[flag]
            if element and element.UpdateText then
                pcall(function()
                    if value ~= nil and value ~= "" then
                        element:UpdateText(tostring(value))
                        inputCount = inputCount + 1
                    end
                end)
            end
        end
        
        local dropdownCount = 0
        for flag, value in pairs(getgenv().Config.dropdowns) do
            local element = MacLib.Flags[flag]
            if element and element.UpdateSelection then
                pcall(function()
                    if value then
                        element:UpdateSelection(value)
                        dropdownCount = dropdownCount + 1
                    end
                end)
            end
        end
        
        
        if getgenv().CurrentMacro and MacLib.Flags["MacroSelect"] then
            pcall(function()
                MacLib.Flags["MacroSelect"]:UpdateSelection(getgenv().CurrentMacro)
            end)
        end
        
        if getgenv().AutoJoinConfig then
            if getgenv().AutoJoinConfig.mode and MacLib.Flags["AutoJoinMode"] then
                pcall(function()
                    MacLib.Flags["AutoJoinMode"]:UpdateSelection(getgenv().AutoJoinConfig.mode)
                end)
            end
            
            if getgenv().AutoJoinConfig.map and MacLib.Flags["AutoJoinMap"] then
                pcall(function()
                    MacLib.Flags["AutoJoinMap"]:UpdateSelection(getgenv().AutoJoinConfig.map)
                end)
            end
            
            if getgenv().AutoJoinConfig.difficulty and MacLib.Flags["AutoJoinDifficulty"] then
                pcall(function()
                    MacLib.Flags["AutoJoinDifficulty"]:UpdateSelection(getgenv().AutoJoinConfig.difficulty)
                end)
            end
        end
        
    end)
end)


local GuiService = game:GetService("GuiService")

local function press(key)
    pcall(function()
        game:GetService("VirtualInputManager"):SendKeyEvent(true, key, false, game)
        task.wait(0.05)
        game:GetService("VirtualInputManager"):SendKeyEvent(false, key, false, game)
    end)
end

task.spawn(function()
    local lastEndGameUIInstance = nil
    local hasProcessedCurrentUI = false
    local endGameUIDetectedTime = 0
    local endGameUIWasPresent = false
    
    while true do
        task.wait(0.2)
        
        local success, errorMsg = pcall(function()
            if not LocalPlayer or not LocalPlayer.PlayerGui then return end
            
            local endGameUI = LocalPlayer.PlayerGui:FindFirstChild("EndGameUI")
            
            if endGameUIWasPresent and not endGameUI then
                print("[Auto Retry] EndGameUI disappeared - Round restarted, units cleared")
                hasProcessedCurrentUI = false
                lastEndGameUIInstance = nil
                endGameUIWasPresent = false
                
                getgenv().MacroGameState = {
                    hasStartButton = false,
                    currentWave = 0,
                    gameEnded = false
                }
                getgenv().MacroCurrentStep = 0
                getgenv().MacroActionText = ""
                getgenv().MacroUnitText = ""
                getgenv().MacroWaitingText = ""
                getgenv().MacroStatusText = "Idle"
                if getgenv().UpdateMacroStatus then
                    getgenv().UpdateMacroStatus()
                end
                print("[Auto Retry] Reset macro progress for fresh start")
                return
            end
            
            if endGameUI then
                endGameUIWasPresent = true
            end
            
            if not endGameUI then 
                return 
            end
            
            local bg = endGameUI:FindFirstChild("BG")
            if not bg then return end
            
            local buttons = bg:FindFirstChild("Buttons")
            if not buttons then return end
            
            if lastEndGameUIInstance and endGameUI ~= lastEndGameUIInstance then
                hasProcessedCurrentUI = false
                lastEndGameUIInstance = endGameUI
                endGameUIDetectedTime = tick()
            end
            
            if not lastEndGameUIInstance then
                lastEndGameUIInstance = endGameUI
                endGameUIDetectedTime = tick()
            end
            
            if hasProcessedCurrentUI then
                return
            end
            
            local nextButton = buttons:FindFirstChild("Next")
            local retryButton = buttons:FindFirstChild("Retry")
            local leaveButton = buttons:FindFirstChild("Leave")
            
            local buttonToPress, actionName = nil, ""
            
            if getgenv().AutoNextEnabled and nextButton and nextButton.Visible then
                buttonToPress = nextButton
                actionName = "Next"
                print("[Auto Next] Next button detected and selected")
            elseif getgenv().AutoFastRetryEnabled and retryButton and retryButton.Visible then
                buttonToPress = retryButton
                actionName = "Retry"
                print("[Auto Retry] Retry button detected and selected")
            elseif getgenv().AutoLeaveEnabled and leaveButton and leaveButton.Visible then
                buttonToPress = leaveButton
                actionName = "Leave"
                print("[Auto Leave] Leave button detected and selected")
            elseif getgenv().AutoSmartEnabled then
                if nextButton and nextButton.Visible then
                    buttonToPress = nextButton
                    actionName = "Next"
                    print("[Auto Smart] Next button detected and selected")
                elseif retryButton and retryButton.Visible then
                    buttonToPress = retryButton
                    actionName = "Retry"
                    print("[Auto Smart] Retry button detected and selected")
                elseif leaveButton and leaveButton.Visible then
                    buttonToPress = leaveButton
                    actionName = "Leave"
                    print("[Auto Smart] Leave button detected and selected")
                end
            end
            
            if not buttonToPress and (getgenv().AutoFastRetryEnabled or getgenv().AutoSmartEnabled) then
                print("[Auto Retry Debug] No button selected - AutoFastRetryEnabled:", getgenv().AutoFastRetryEnabled)
            end
            
            if buttonToPress then
                
                if getgenv().WebhookEnabled then
                    task.wait(2)
                    local maxWait = 0
                    while getgenv().WebhookProcessing and maxWait < 10 do
                        task.wait(0.3)
                        maxWait = maxWait + 0.3
                    end
                    task.wait(0.5)
                end
                
                task.wait(0.3)
                hasProcessedCurrentUI = true
                
                local success = pcall(function()
                    local GuiService = game:GetService("GuiService")
                    
                    GuiService.SelectedObject = nil
                    task.wait(0.1)
                    
                    GuiService.SelectedObject = buttonToPress
                    task.wait(0.2)
                    
                    if GuiService.SelectedObject == buttonToPress then
                        
                        VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                        task.wait(0.05)
                        VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                        task.wait(0.2)
                        
                        GuiService.SelectedObject = nil

                    end
                end)
                
                if not success then
                    warn("[Auto Retry] UI navigation failed")
                end
                
                task.wait(0.3)
                
                if LocalPlayer.PlayerGui:FindFirstChild("EndGameUI") then
                    warn("[Auto Retry] EndGameUI still present - button may require server validation")
                else
                    print("[Auto Retry] Successfully clicked " .. actionName .. " button - EndGameUI closed")
                end
            end
        end)
        
        if not success then
            warn("[Auto Leave/Replay] Error in loop: " .. tostring(errorMsg))
        end
    end
end)

do
    task.spawn(function()
    while true do
        task.wait(1)
        if getgenv().AutoReadyEnabled then
            local success, err = pcall(function()
                local bottomGui = LocalPlayer.PlayerGui:FindFirstChild("Bottom")
                if bottomGui then
                    local frame = bottomGui:FindFirstChild("Frame")
                    if frame then
                        local children = frame:GetChildren()
                        if children[2] then
                            local subChildren = children[2]:GetChildren()
                            if subChildren[6] then
                                local textButton = subChildren[6]:FindFirstChild("TextButton")
                                if textButton then
                                    local textLabel = textButton:FindFirstChild("TextLabel")
                                    if textLabel and textLabel.Text == "Start" then
                                        local remotes = RS:FindFirstChild("Remotes")
                                        local playerReady = remotes and remotes:FindFirstChild("PlayerReady")
                                        if playerReady then
                                            playerReady:FireServer()
                                            task.wait(2)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
            if not success then
                warn("[Auto Ready] Error: " .. tostring(err))
            end
        end
    end
    end)
end



local abilityCooldowns = {}
local bossSpawnTime = nil
local generalBossSpawnTime = nil
local bossInRangeTracker = {}
local lastWave = 0
local Towers = workspace:WaitForChild("Towers", 10)

local function getCurrentWave()
    local ok, res = pcall(function()
        local waveValue = RS:FindFirstChild("Wave")
        if waveValue and waveValue:IsA("IntValue") then
            return waveValue.Value
        end
        return 0
    end)
    
    if ok and res > 0 then
        return res
    end
    
    local ok2, res2 = pcall(function()
        local gui = LocalPlayer.PlayerGui:FindFirstChild("HUD")
        if not gui then return 0 end
        local frame = gui:FindFirstChild("Frame")
        if not frame then return 0 end
        local wave = frame:FindFirstChild("Wave")
        if not wave then return 0 end
        local label = wave:FindFirstChild("TextLabel")
        if not label then return 0 end
        local text = label.Text
        local num = tonumber(text:match("%d+"))
        return num or 0
    end)
    return ok2 and res2 or 0
end

local function getCurrentTimeScale()
    local ok, res = pcall(function()
        local timeScale = RS:FindFirstChild("TimeScale")
        if timeScale and timeScale:IsA("NumberValue") then
            return timeScale.Value or 1
        end
        return 1
    end)
    return ok and res or 1
end

local function getUpgradeLevel(tower)
    if not tower then return 0 end
    local ok, res = pcall(function()
        local u = tower:FindFirstChild("Upgrade")
        if u and u:IsA("ValueBase") then return u.Value or 0 end
        return 0
    end)
    return ok and res or 0
end

local function fixAbilityName(abilityName)
    local fixed = abilityName
    fixed = fixed:gsub("!!+", "!")
    fixed = fixed:gsub("%?%?+", "?")
    return fixed
end

local function useAbility(tower, abilityName)
    if tower then
        local correctedName = fixAbilityName(abilityName)
        pcall(function() RS.Remotes.Ability:InvokeServer(tower, correctedName) end)
    end
end

local function getAbilityData(towerName, abilityName)
    local abilities = getAllAbilities(towerName)
    return abilities[abilityName]
end

local function isOnCooldown(towerName, abilityName)
    local d = getAbilityData(towerName, abilityName)
    if not d or not d.cooldown then return false end
    local key = towerName .. "_" .. abilityName
    local last = abilityCooldowns[key]
    if not last then return false end
    local scale = getCurrentTimeScale()
    local effectiveCd = d.cooldown / scale
    local timeSinceUse = tick() - last
    local cooldownRemaining = effectiveCd - timeSinceUse
    return cooldownRemaining > 0.5
end

local function setAbilityUsed(towerName, abilityName)
    abilityCooldowns[towerName.."_"..abilityName] = tick()
end

local function hasAbilityBeenUnlocked(towerName, abilityName, towerLevel)
    local d = getAbilityData(towerName, abilityName)
    return d and towerLevel >= d.requiredLevel
end

local function bossExists()
    local ok, res = pcall(function()
        local enemies = workspace:FindFirstChild("Enemies")
        if not enemies then 
            return false 
        end
        local boss = enemies:FindFirstChild("Boss")
        return boss ~= nil
    end)
    if not ok then
        warn("[Auto Ability] Error checking boss existence:", res)
    end
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

local function getBossCFrame()
    local ok, res = pcall(function()
        local enemies = workspace:FindFirstChild("Enemies")
        if not enemies then return nil end
        local boss = enemies:FindFirstChild("Boss")
        if not boss then return nil end
        local hrp = boss:FindFirstChild("HumanoidRootPart")
        if hrp then return hrp.CFrame end
        return nil
    end)
    return ok and res or nil
end

local function getTowerCFrame(tower)
    if not tower then return nil end
    local ok, res = pcall(function()
        local hrp = tower:FindFirstChild("HumanoidRootPart")
        if hrp then return hrp.CFrame end
        return nil
    end)
    return ok and res or nil
end

local function getTowerRange(tower)
    if not tower then return 0 end
    local ok, res = pcall(function()
        local stats = tower:FindFirstChild("Stats")
        if not stats then return 0 end
        local range = stats:FindFirstChild("Range")
        if not range then return 0 end
        return range.Value or 0
    end)
    return ok and res or 0
end

local function isBossInRange(tower)
    local bossCF = getBossCFrame()
    local towerCF = getTowerCFrame(tower)
    if not bossCF or not towerCF then return false end
    local range = getTowerRange(tower)
    if range <= 0 then return false end
    local distance = (bossCF.Position - towerCF.Position).Magnitude
    return distance <= range
end

local function checkBossInRangeForDuration(tower, requiredDuration)
    if not tower then return false end
    local name = tower.Name
    local currentTime = tick()
    if isBossInRange(tower) then
        if requiredDuration == 0 then return true end
        if not bossInRangeTracker[name] then
            bossInRangeTracker[name] = currentTime
            return false
        else
            return (currentTime - bossInRangeTracker[name]) >= requiredDuration
        end
    else
        bossInRangeTracker[name] = nil
    end
    return false
end

local function getTowerInfoName(tower)
    if not tower then return nil end
    return tower.Name
end

local function resetRoundTrackers()
    bossSpawnTime = nil
    generalBossSpawnTime = nil
    bossInRangeTracker = {}
    abilityCooldowns = {}
    print("[Auto Ability] Reset all cooldowns for new round")
end

local function checkGameEndedReset()
    local ok = pcall(function()
        local endGameUI = LocalPlayer.PlayerGui:FindFirstChild("EndGameUI")
        if endGameUI and endGameUI:FindFirstChild("Frame") then
            resetRoundTrackers()
        end
    end)
end



task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            checkGameEndedReset()
            local currentWave = getCurrentWave()
            local hasBoss = bossExists()
            
            if currentWave < lastWave then
                resetRoundTrackers()
                print("[Auto Ability] Round restart detected (wave", lastWave, "→", currentWave, "), reset trackers")
            end
            
            if getgenv().SeamlessFixEnabled and lastWave >= 50 and currentWave < 50 then
                resetRoundTrackers()
                print("[Auto Ability] Seamless round restart detected, reset trackers")
            end
            
            if currentWave == 1 and lastWave > 10 then
                resetRoundTrackers()
                print("[Auto Ability] Wave 1 after high wave, reset trackers")
            end
            
            lastWave = currentWave
            
            if not Towers then return end
            if not getgenv().UnitAbilities or type(getgenv().UnitAbilities) ~= "table" then return end
            
            for unitName, abilitiesConfig in pairs(getgenv().UnitAbilities) do
                local tower = Towers:FindFirstChild(unitName)
                if tower then
                    local infoName = getTowerInfoName(tower)
                    local towerLevel = getUpgradeLevel(tower)
                    
                    for abilityName, cfg in pairs(abilitiesConfig) do
                        local savedCfg = getgenv().Config.abilities[unitName] and getgenv().Config.abilities[unitName][abilityName]
                        if savedCfg then
                            cfg.enabled = savedCfg.enabled
                            cfg.onlyOnBoss = savedCfg.onlyOnBoss or false
                            cfg.useOnWave = savedCfg.useOnWave or false
                            cfg.specificWave = savedCfg.specificWave
                            cfg.requireBossInRange = savedCfg.requireBossInRange or false
                        end
                        
                        if cfg.enabled then
                            local shouldUse = true
                            local debugInfo = {}
                            
                            
                            if not hasAbilityBeenUnlocked(infoName, abilityName, towerLevel) then
                                shouldUse = false
                                table.insert(debugInfo, "not unlocked (level " .. towerLevel .. ")")
                            end
                            
                            if shouldUse and isOnCooldown(infoName, abilityName) then
                                shouldUse = false
                                table.insert(debugInfo, "on cooldown")
                            end
                            
                            if shouldUse and cfg.useOnWave and cfg.specificWave then
                                if currentWave ~= cfg.specificWave then
                                    shouldUse = false
                                    table.insert(debugInfo, "wrong wave (current: " .. currentWave .. ", need: " .. cfg.specificWave .. ")")
                                else
                                    table.insert(debugInfo, "wave OK (" .. currentWave .. ")")
                                    print("[Auto Ability] ✓", unitName, abilityName, "- wave condition met (wave", currentWave .. ")")
                                end
                            end
                            
                            if shouldUse and cfg.onlyOnBoss then
                                print("[Auto Ability] Checking onlyOnBoss for", unitName, abilityName, "| hasBoss:", hasBoss, "| bossReady:", bossReadyForAbilities())
                                if not hasBoss then
                                    shouldUse = false
                                    table.insert(debugInfo, "no boss")
                                elseif not bossReadyForAbilities() then
                                    shouldUse = false
                                    table.insert(debugInfo, "boss not ready")
                                else
                                    table.insert(debugInfo, "boss OK")
                                    print("[Auto Ability] ✓", unitName, abilityName, "- boss condition met")
                                end
                            end
                            
                            if shouldUse and cfg.requireBossInRange then
                                local inRange = checkBossInRangeForDuration(tower, 0)
                                if not hasBoss or not inRange then
                                    shouldUse = false
                                    table.insert(debugInfo, "boss not in range")
                                else
                                    table.insert(debugInfo, "boss in range")
                                    print("[Auto Ability] ✓", unitName, abilityName, "- boss in range condition met")
                                end
                            end
                            
                            if shouldUse then
                                if not isOnCooldown(infoName, abilityName) then
                                    useAbility(tower, abilityName)
                                    setAbilityUsed(infoName, abilityName)
                                    
                                    if unitName == "AsuraEvo" and abilityName == "Lines of Sanzu" then
                                    end
                                else
                                    print("[Auto Ability] ✗", unitName, abilityName, "- FINAL COOLDOWN CHECK FAILED")
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
end)



do
    task.spawn(function()
        while true do
            task.wait(1)
            if getgenv().BulmaEnabled then
            local success, err = pcall(function()
                local towers = workspace:FindFirstChild("Towers")
                if not towers then return end
                
                local bulma = towers:FindFirstChild("Bulma")
                if not bulma then return end
                
                local meters = bulma:FindFirstChild("Meters")
                if not meters then return end
                
                local wishBalls = meters:FindFirstChild("Wish Balls")
                if not wishBalls then return end
                
                local attributes = wishBalls:GetAttributes()
                local ballCount = 0
                
                if attributes.Value then
                    ballCount = attributes.Value
                end
                
                if ballCount == 7 and not getgenv().BulmaWishUsedThisRound then
                    getgenv().BulmaWishUsedThisRound = true
                    
                    pcall(function()
                        RS.Remotes.Ability:InvokeServer(bulma, "Summon Wish Dragon")
                    end)
                    task.wait(0.5)
                    
                    local wishType = getgenv().BulmaWishType or "Power"
                    pcall(function()
                        RS.Remotes.Ability:InvokeServer(bulma, "Wish: " .. wishType)
                    end)
                    
                    Window:Notify({
                        Title = "Bulma Auto-Wish",
                        Description = "Used Wish: " .. wishType .. " (1x per round)",
                        Lifetime = 3
                    })
                end
            end)
            
            if not success then
                warn("[Bulma] Error: " .. tostring(err))
            end
        end
    end
    end)
end



do
    task.spawn(function()
        
        local CLONE_UPGRADE_COSTS = {
        [1] = 1750,
        [2] = 3500,
        [3] = 7000,
        [4] = 12500,
        [5] = 25000,
        [6] = 27500,
        [7] = 30250,
        [8] = 55000
    }
    
    local function getPlayerCash()
        local clientData = getClientData()
        if clientData and clientData.Cash then
            return clientData.Cash
        end
        return 0
    end
    
    local function getJinMoriTower()
        local Towers = workspace:FindFirstChild("Towers")
        if not Towers then return nil end
        
        for _, tower in ipairs(Towers:GetChildren()) do
            if tower.Name == "JinMoriGodly" and tower:IsA("Model") then
                return tower
            end
        end
        return nil
    end
    
    local function getJinMoriClones()
        local Towers = workspace:FindFirstChild("Towers")
        if not Towers then return {} end
        
        local clones = {}
        for _, tower in ipairs(Towers:GetChildren()) do
            if tower.Name == "JinMoriGodlyClone" and tower:IsA("Model") then
                table.insert(clones, tower)
            end
        end
        return clones
    end
    
    local function useCloneSynthesis(jinMoriTower)
        if not jinMoriTower then return false end
        
        local success, err = pcall(function()
            local AbilityEvent = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("AbilityEvent")
            if AbilityEvent then
                AbilityEvent:InvokeServer(jinMoriTower, "Clone Synthesis")
                return true
            end
        end)
        
        return success
    end
    
    local function upgradeClone(cloneTower)
        if not cloneTower then return false end
        
        local upgradeValue = cloneTower:FindFirstChild("Upgrade")
        if not upgradeValue then return false end
        
        local currentUpgrade = upgradeValue.Value
        if currentUpgrade >= 8 then return false end 
        
        local nextUpgradeCost = CLONE_UPGRADE_COSTS[currentUpgrade + 1]
        if not nextUpgradeCost then return false end
        
        local cash = tonumber(getPlayerCash()) or 0
        if cash < (tonumber(nextUpgradeCost) or 0) then return false end
        
        local success, err = pcall(function()
            local UpgradeEvent = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("UpgradeEvent")
            if UpgradeEvent then
                UpgradeEvent:InvokeServer(cloneTower)
                return true
            end
        end)
        
        return success
    end
    
    local function useCloneDiffusion(cloneTower)
        if not cloneTower then return false end
        
        local success, err = pcall(function()
            local AbilityEvent = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("AbilityEvent")
            if AbilityEvent then
                AbilityEvent:InvokeServer(cloneTower, "Clone Diffusion")
                return true
            end
        end)
        
        return success
    end
    
    while true do
        task.wait(1)
        
        if not getgenv().WukongEnabled then continue end
        
        local jinMori = getJinMoriTower()
        if not jinMori then continue end
        
        local jinMoriUpgrade = jinMori:FindFirstChild("Upgrade")
        if not jinMoriUpgrade or jinMoriUpgrade.Value < 8 then continue end
        
        local reachingNirvana = jinMori:FindFirstChild("Meters") and jinMori.Meters:FindFirstChild("ReachingNirvana")
        if not reachingNirvana then continue end
        
        local currentNirvana = reachingNirvana:GetAttribute("Value") or 0
        local maxNirvana = reachingNirvana:GetAttribute("MaxValue") or 4
        
        if currentNirvana < maxNirvana then
            local lastSynthesisTime = getgenv()._WukongLastSynthesisTime or 0
            local currentTime = tick()
            
            if currentTime - lastSynthesisTime >= 10 then
                if useCloneSynthesis(jinMori) then
                    getgenv()._WukongLastSynthesisTime = currentTime
                    
                    Window:Notify({
                        Title = "Auto Wukong",
                        Description = "Clone Synthesis used (" .. (currentNirvana + 1) .. "/" .. maxNirvana .. ")",
                        Lifetime = 3
                    })
                    
                    task.wait(1)
                end
            end
        end
        
        local clones = getJinMoriClones()
        for _, clone in ipairs(clones) do
            local cloneUpgrade = clone:FindFirstChild("Upgrade")
            if cloneUpgrade and cloneUpgrade.Value < 8 then
                upgradeClone(clone)
                task.wait(0.5)
            end
        end
        
        for _, clone in ipairs(clones) do
            local cloneUpgrade = clone:FindFirstChild("Upgrade")
            if cloneUpgrade and cloneUpgrade.Value == 8 then
                local cloneId = clone:GetDebugId()
                if not getgenv().WukongTrackedClones[cloneId] then
                    if useCloneDiffusion(clone) then
                        getgenv().WukongTrackedClones[cloneId] = true
                        
                        Window:Notify({
                            Title = "Auto Wukong",
                            Description = "Clone Diffusion used! Nirvana state increased",
                            Lifetime = 3
                        })
                        
                        task.wait(1)
                    end
                end
            end
        end
    end
    end)
end


do
    task.spawn(function()
        LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
        if child.Name == "EndGameUI" then
            getgenv().BulmaWishUsedThisRound = false
            getgenv().WukongTrackedClones = {}
            getgenv()._WukongLastSynthesisTime = 0
        end
    end)
    end)
end

do
    task.spawn(function()
    local lastWave = 0
    while true do
        task.wait(1)
        pcall(function()
            local wave = RS:FindFirstChild("Wave")
            if wave and wave:IsA("NumberValue") then
                local currentWave = wave.Value
                
                if currentWave < lastWave and currentWave <= 5 then
                    getgenv().BulmaWishUsedThisRound = false
                    getgenv().WukongTrackedClones = {}
                    getgenv()._WukongLastSynthesisTime = 0
                end
                
                lastWave = currentWave
            end
        end)
    end
end)


local function isInLobby()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    
    local lobbyUI = playerGui:FindFirstChild("LobbyUI")
    return lobbyUI ~= nil
end

task.spawn(function()
    while true do
        task.wait(2)
        
        local currentlyInLobby = false
        pcall(function()
            local lobbyCheck = workspace:FindFirstChild("Lobby")
            currentlyInLobby = lobbyCheck ~= nil
        end)
        
        if currentlyInLobby and (getgenv().FinalExpAutoJoinEasyEnabled or getgenv().FinalExpAutoJoinHardEnabled) then
            pcall(function()
                local finalExpRemote = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("FinalExpeditionStart")
                if finalExpRemote then
                    if getgenv().FinalExpAutoJoinEasyEnabled then
                        finalExpRemote:FireServer("Easy")
                        print("[Final Expedition] Auto joining Easy mode")
                    elseif getgenv().FinalExpAutoJoinHardEnabled then
                        finalExpRemote:FireServer("Hard")
                        print("[Final Expedition] Auto joining Hard mode")
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        
        local currentlyInLobby = false
        pcall(function()
            local lobbyCheck = workspace:FindFirstChild("Lobby")
            currentlyInLobby = lobbyCheck ~= nil
        end)
        
        if not currentlyInLobby then
            pcall(function()
                local promptUI = LocalPlayer.PlayerGui:FindFirstChild("Prompt")
                if not promptUI then return end
                
                local frame = promptUI:FindFirstChild("Frame")
                if not frame then return end
                
                local innerFrame = frame:FindFirstChild("Frame")
                if not innerFrame then return end
                
                local optionsFrame = innerFrame:FindFirstChild("Frame")
                if not optionsFrame then return end
                
                local optionsContainer = optionsFrame:FindFirstChild("Frame")
                if not optionsContainer then return end
                
                local availableOptions = {}
                for _, child in pairs(optionsContainer:GetChildren()) do
                    if child:IsA("Frame") or child:IsA("GuiObject") then
                        local textLabel = child:FindFirstChild("Frame", true)
                        if textLabel then
                            textLabel = textLabel:FindFirstChild("TextLabel")
                            if textLabel and textLabel.Text then
                                local optionText = textLabel.Text
                                availableOptions[optionText] = child
                                print("[Final Expedition] Found option:", optionText)
                            end
                        end
                    end
                end
                
                if next(availableOptions) == nil then return end
                
                local abilitySelectionRemote = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("AbilitySelectionEvent")
                if not abilitySelectionRemote then return end
                
                if getgenv().FinalExpAutoSkipShopEnabled and availableOptions["Shop"] then
                    print("[Final Expedition] Skipping Shop")
                    abilitySelectionRemote:FireServer("FinalExpeditionSelection", "Shop")
                    task.wait(0.5)
                    local shopRemote = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("FinalExpedition") and RS.Remotes.FinalExpedition:FindFirstChild("ShopEvent")
                    if shopRemote then
                        shopRemote:FireServer("Close")
                        print("[Final Expedition] Closed Shop")
                    end
                    return
                end
                
                if getgenv().FinalExpAutoSelectModeEnabled then
                    local priorities = {
                        {name = "Rest", priority = getgenv().FinalExpRestPriority or 3, remote = "Rest"},
                        {name = "Dungeon", priority = getgenv().FinalExpDungeonPriority or 1, remote = "Dungeon"},
                        {name = "Double Dungeon", priority = getgenv().FinalExpDoubleDungeonPriority or 2, remote = "Double_Dungeon"}
                    }
                    
                    table.sort(priorities, function(a, b) return a.priority < b.priority end)
                    
                    for _, option in ipairs(priorities) do
                        if availableOptions[option.name] then
                            print("[Final Expedition] Auto selecting:", option.name, "(Priority:", option.priority .. ")")
                            abilitySelectionRemote:FireServer("FinalExpeditionSelection", option.remote)
                            return
                        end
                    end
                end
                
                if getgenv().FinalExpSkipRewardsEnabled then
                    for optionName, optionFrame in pairs(availableOptions) do
                        local textButton = optionFrame:FindFirstChildOfClass("TextButton", true)
                        if textButton then
                            print("[Final Expedition] Skipping rewards by clicking button")
                            for _, connection in pairs(getconnections(textButton.MouseButton1Click)) do
                                connection:Fire()
                            end
                            return
                        end
                    end
                end
            end)
        end
    end
end)


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

local function findBestPortal()
    local clientData = getClientData()
    if not clientData then return nil end
    
    local selectedMap = getgenv().PortalConfig.selectedMap
    local targetTier = getgenv().PortalConfig.tier
    local useBestPortal = getgenv().PortalConfig.useBestPortal
    local priorities = getgenv().PortalConfig.priorities
    
    local matchingPortals = {}
    
    for portalID, portalInfo in pairs(clientData) do
        if type(portalInfo) == "table" and portalInfo.PortalData then
            local portalData = portalInfo.PortalData
            local mapMatch = (selectedMap == "" or portalData.Map == selectedMap)
            
            if mapMatch then
                table.insert(matchingPortals, {
                    id = portalID,
                    tier = portalData.Tier or 0,
                    challenge = portalData.Challenges or "",
                    map = portalData.Map or ""
                })
            end
        end
    end
    
    if #matchingPortals == 0 then return nil end
    
    if useBestPortal then
        table.sort(matchingPortals, function(a, b)
            return a.tier > b.tier
        end)
        return matchingPortals[1].id
    end
    
    local tierFiltered = {}
    for _, portal in ipairs(matchingPortals) do
        if portal.tier == targetTier then
            table.insert(tierFiltered, portal)
        end
    end
    
    if #tierFiltered == 0 then
        return matchingPortals[1].id
    end
    
    local challengePriorityMap = {}
    for challengeName, priorityNum in pairs(priorities) do
        if priorityNum > 0 and priorityNum <= 6 then
            challengePriorityMap[challengeName] = priorityNum
        end
    end
    
    for priority = 1, 6 do
        for challengeName, priorityNum in pairs(challengePriorityMap) do
            if priorityNum == priority then
                for _, portal in ipairs(tierFiltered) do
                    if portal.challenge:lower():find(challengeName:lower()) then
                        return portal.id
                    end
                end
            end
        end
    end
    
    return tierFiltered[1].id
end

local function activatePortal(portalID)
    if not portalID then return false end
    
    local success = pcall(function()
        local portalRemote = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("Portals") and RS.Remotes.Portals:FindFirstChild("ActivateEvent")
        if portalRemote then
            portalRemote:InvokeServer(portalID)
            return true
        end
    end)
    
    return success
end

if isInLobby then
    task.spawn(function()
        while true do
            task.wait(2)
            
            if getgenv().PortalConfig.pickPortal then
                pcall(function()
                    local promptUI = LocalPlayer.PlayerGui:FindFirstChild("Prompt")
                    if promptUI and promptUI:FindFirstChild("Frame") then
                        local frame = promptUI.Frame:FindFirstChild("Frame")
                        if frame then
                            local children = frame:GetChildren()
                            for _, child in ipairs(children) do
                                if child:IsA("Frame") or child:IsA("GuiObject") then
                                    local textButton = child:FindFirstChildOfClass("TextButton", true)
                                    if textButton then
                                        for i, v in pairs(getconnections(textButton.MouseButton1Click)) do
                                            v:Fire()
                                        end
                                        task.wait(0.2)
                                        
                                        local confirmButton = promptUI:FindFirstChild("Confirm", true)
                                        if confirmButton and confirmButton:IsA("TextButton") then
                                            for i, v in pairs(getconnections(confirmButton.MouseButton1Click)) do
                                                v:Fire()
                                            end
                                        end
                                        break
                                    end
                                end
                            end
                        end
                    end
                end)
            else
                local portalID = findBestPortal()
                if portalID then
                    activatePortal(portalID)
                end
            end
        end
    end)
end

task.spawn(function()
    while true do
        task.wait(1)
        
        pcall(function()
            local gamemode = RS:FindFirstChild("Gamemode")
            if gamemode and gamemode.Value == "Portal" then
                if getgenv().AutoNextEnabled or getgenv().AutoSmartEnabled then
                    local endGameUI = LocalPlayer.PlayerGui:FindFirstChild("EndGameUI")
                    if endGameUI and endGameUI:FindFirstChild("BG") then
                        local buttons = endGameUI.BG:FindFirstChild("Buttons")
                        if buttons then
                            local nextButton = buttons:FindFirstChild("Next")
                            if nextButton and nextButton:FindFirstChild("Styling") then
                                local label = nextButton.Styling:FindFirstChild("Label")
                                if label and label.Text == "View Portals" then
                                    for i, v in pairs(getconnections(nextButton.MouseButton1Click)) do
                                        v:Fire()
                                    end
                                    
                                    task.wait(1)
                                    
                                    if getgenv().PortalConfig.pickPortal then
                                        pcall(function()
                                            local promptUI = LocalPlayer.PlayerGui:FindFirstChild("Prompt")
                                            if promptUI and promptUI:FindFirstChild("Frame") then
                                                local frame = promptUI.Frame:FindFirstChild("Frame")
                                                if frame then
                                                    local children = frame:GetChildren()
                                                    for _, child in ipairs(children) do
                                                        if child:IsA("Frame") or child:IsA("GuiObject") then
                                                            local textButton = child:FindFirstChildOfClass("TextButton", true)
                                                            if textButton then
                                                                for i, v in pairs(getconnections(textButton.MouseButton1Click)) do
                                                                    v:Fire()
                                                                end
                                                                task.wait(0.2)
                                                                
                                                                local confirmButton = promptUI:FindFirstChild("Confirm", true)
                                                                if confirmButton and confirmButton:IsA("TextButton") then
                                                                    for i, v in pairs(getconnections(confirmButton.MouseButton1Click)) do
                                                                        v:Fire()
                                                                    end
                                                                end
                                                                break
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end)
                                    else
                                        local portalID = findBestPortal()
                                        if portalID then
                                            activatePortal(portalID)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
    end)
end


local function formatNumber(num)
    if not num then return "0" end
    local s = tostring(num)
    s = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    if s:sub(1,1) == "," then s = s:sub(2) end
    return s
end

local function SendMessageEMBED(url, embed, content)
    if not url or url == "" then
        warn("[Webhook] Invalid URL provided")
        return false
    end
    
    local success, result = pcall(function()
        local headers = { ["Content-Type"] = "application/json" }
        local data = { 
            embeds = { { 
                title = embed.title, 
                description = embed.description, 
                color = embed.color, 
                fields = embed.fields, 
                footer = embed.footer, 
                timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z") 
            } } 
        }
        
        if content and content ~= "" then
            data.content = content
        end
        
        local body = HttpService:JSONEncode(data)
        
        local requestFunc = syn and syn.request or http_request or request
        if not requestFunc then
            warn("[Webhook] No request function available")
            return false
        end
        
        local response = requestFunc({
            Url = url,
            Method = "POST",
            Headers = headers,
            Body = body
        })
        
        if response and response.StatusCode then
            if response.StatusCode == 204 or response.StatusCode == 200 then
                return true
            else
                warn("[Webhook] Failed with status: " .. response.StatusCode)
                if response.Body then
                    warn("[Webhook] Response: " .. response.Body)
                end
                return false
            end
        end
        
        return true
    end)
    
    if not success then
        warn("[Webhook] Error sending: " .. tostring(result))
        return false
    end
    
    return result
end

local function getRewards()
    local rewards = {}
    local ok, res = pcall(function()
        local ui = LocalPlayer.PlayerGui:FindFirstChild("EndGameUI")
        if not ui then return {} end
        local holder = ui:FindFirstChild("BG") and ui.BG:FindFirstChild("Container") and ui.BG.Container:FindFirstChild("Rewards") and ui.BG.Container.Rewards:FindFirstChild("Holder")
        if not holder then return {} end
        
        local waitTime = 0
        local lastCount = 0
        local stableCount = 0
        repeat
            task.wait(0.3)
            waitTime = waitTime + 0.3
            local children = holder:GetChildren()
            local currentCount = 0
            for i = 1, #children do
                if children[i]:IsA("TextButton") then
                    currentCount = currentCount + 1
                end
            end
            if currentCount == lastCount and currentCount > 0 then
                stableCount = stableCount + 1
            else
                stableCount = 0
            end
            lastCount = currentCount
        until (stableCount >= 5 and currentCount > 0) or waitTime > 4
        
        for _, item in pairs(holder:GetChildren()) do
            if item:IsA("TextButton") then
                local rewardName, rewardAmount
                local unitName = item:FindFirstChild("UnitName")
                if unitName and unitName.Text and unitName.Text ~= "" then
                    rewardName = unitName.Text
                end
                local itemName = item:FindFirstChild("ItemName")
                if itemName and itemName.Text and itemName.Text ~= "" then
                    rewardName = itemName.Text
                end
                if rewardName then
                    local amountLabel = item:FindFirstChild("Amount")
                    if amountLabel and amountLabel.Text then
                        local amountText = amountLabel.Text
                        local clean = string.gsub(string.gsub(string.gsub(amountText, "x", ""), "+", ""), ",", "")
                        rewardAmount = tonumber(clean)
                    else
                        rewardAmount = 1
                    end
                    if rewardAmount then
                        table.insert(rewards, { name = rewardName, amount = rewardAmount })
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
        local ui = LocalPlayer.PlayerGui:FindFirstChild("EndGameUI")
        if not ui then return "00:00:00", "0", "Unknown" end
        local stats = ui:FindFirstChild("BG") and ui.BG:FindFirstChild("Container") and ui.BG.Container:FindFirstChild("Stats")
        if not stats then return "00:00:00", "0", "Unknown" end
        
        local r = (stats:FindFirstChild("Result") and stats.Result.Text) or "Unknown"
        local t = (stats:FindFirstChild("ElapsedTime") and stats.ElapsedTime.Text) or "00:00:00"
        local w = (stats:FindFirstChild("EndWave") and stats.EndWave.Text) or "0"
        
        if t:find("Total Time:") then
            local m, s = t:match("Total Time:%s*(%d+):(%d+)")
            if m and s then
                t = string.format("%02d:%02d:%02d", 0, tonumber(m) or 0, tonumber(s) or 0)
            end
        end
        
        if w:find("Wave Reached:") then
            local wm = w:match("Wave Reached:%s*(%d+)")
            if wm then w = wm end
        end
        
        if r:lower():find("win") or r:lower():find("victory") then
            r = "VICTORY"
        elseif r:lower():find("defeat") or r:lower():find("lose") or r:lower():find("loss") then
            r = "DEFEAT"
        end
        
        return t, w, r
    end)
    if ok then return time, wave, result else return "00:00:00", "0", "Unknown" end
end

local function getMapInfo()
    local ok, name, difficulty = pcall(function()
        local map = workspace:FindFirstChild("Map")
        if not map then return "Unknown Map", "Unknown" end
        local mapName = map:FindFirstChild("MapName")
        local mapDifficulty = map:FindFirstChild("MapDifficulty")
        return mapName and mapName.Value or "Unknown Map", mapDifficulty and mapDifficulty.Value or "Unknown"
    end)
    if ok then return name, difficulty else return "Unknown Map", "Unknown" end
end


do
    task.spawn(function()
        local lastWebhookHash = ""
        local lastWebhookTime = 0
        local WEBHOOK_COOLDOWN = 10
        local isProcessing = false
    
    local function sendWebhook()
        local success, err = pcall(function()
            if not getgenv().WebhookEnabled then 
                return 
            end
            
            if isProcessing then 
                return 
            end
            
            local currentTime = tick()
            if currentTime - lastWebhookTime < WEBHOOK_COOLDOWN then 
                return 
            end
            
            if getgenv()._webhookLock and (currentTime - getgenv()._webhookLock) < 8 then 
                return 
            end
            
            getgenv()._webhookLock = currentTime
            lastWebhookTime = currentTime
            isProcessing = true
            getgenv().WebhookProcessing = true
            
            
            local rewards = getRewards()
            local matchTime, matchWave, matchResult = getMatchResult()
            local mapName, mapDifficulty = getMapInfo()
            local clientData = getClientData()
            
            if not clientData then
                isProcessing = false
                getgenv().WebhookProcessing = false
                return
            end
            
            if not matchWave or matchWave == "0" or matchWave == "" then
                warn("[Webhook] Invalid wave data, skipping send")
                isProcessing = false
                getgenv().WebhookProcessing = false
                return
            end
            
            if not matchResult or matchResult == "Unknown" or matchResult == "" then
                warn("[Webhook] Invalid match result, skipping send")
                isProcessing = false
                getgenv().WebhookProcessing = false
                return
            end
            
            if not matchTime or matchTime == "00:00:00" or matchTime == "" then
                warn("[Webhook] Invalid match time, skipping send")
                isProcessing = false
                getgenv().WebhookProcessing = false
                return
            end
            
            
            local function formatStats()
                local stats = "<:jewel:1217525743408648253> " .. formatNumber(clientData.Gold or 0)
                stats = stats .. "\n<:gold:1265957290251522089> " .. formatNumber(clientData.Jewels or 0)
                stats = stats .. "\n<:emerald:1389165843966984192> " .. formatNumber(clientData.Emeralds or 0)
                stats = stats .. "\n<:rerollshard:1426315987019501598> " .. formatNumber(clientData.Rerolls or 0)
                stats = stats .. "\n<:candybasket:1426304615284084827> " .. formatNumber(clientData.CandyBasket or 0)
                
                local bingoStamps = 0
                if clientData.ItemData and clientData.ItemData.HallowenBingoStamp then
                    bingoStamps = clientData.ItemData.HallowenBingoStamp.Amount or 0
                end
                stats = stats .. "\n<:bingostamp:1426362482141954068> " .. formatNumber(bingoStamps)
                
                return stats
            end
            
            local rewardsText = ""
            if #rewards > 0 then
                for _, r in ipairs(rewards) do
                    local total = 0
                    local itemName = r.name
                    
                    if clientData[itemName] and type(clientData[itemName]) == "number" then
                        total = clientData[itemName]
                    elseif clientData.ItemData and clientData.ItemData[itemName] and clientData.ItemData[itemName].Amount then
                        total = clientData.ItemData[itemName].Amount
                    elseif clientData.Items and clientData.Items[itemName] and clientData.Items[itemName].Amount then
                        total = clientData.Items[itemName].Amount
                    elseif itemName == "Candy Basket" and clientData.CandyBasket then
                        total = clientData.CandyBasket
                    elseif itemName:find("Bingo Stamp") and clientData.ItemData and clientData.ItemData.HallowenBingoStamp then
                        total = clientData.ItemData.HallowenBingoStamp.Amount or 0
                    else
                        total = r.amount
                    end
                    
                    rewardsText = rewardsText .. "+" .. formatNumber(r.amount) .. " " .. itemName .. " [ Total: " .. formatNumber(total) .. " ]\n"
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
            
            local hasUnitDrop = false
            local unitDropName = ""
            for _, r in ipairs(rewards) do
                if r.name then
                    local isUnit = not (
                        r.name:find("Jewel") or 
                        r.name:find("Gold") or 
                        r.name:find("Emerald") or 
                        r.name:find("Candy") or 
                        r.name:find("Stamp") or
                        r.name:find("Shard") or
                        r.name:find("EXP") or
                        r.name:find("Reroll")
                    )
                    
                    if r.type == "Unit" or isUnit then
                        hasUnitDrop = true
                        unitDropName = r.name
                        break
                    end
                end
            end
            
            local description = "**Username:** ||" .. LocalPlayer.Name .. "||\n**Level:** " .. (clientData.Level or 0) .. " [" .. formatNumber(clientData.EXP or 0) .. "/" .. formatNumber(clientData.MaxEXP or 0) .. "]"
            
            local embedColor = 0x00ff00
            if matchResult and (matchResult:upper():find("DEFEAT") or matchResult:upper():find("LOSE") or matchResult:upper():find("LOSS")) then
                embedColor = 0xff0000
            end
            
            local embed = {
                title = "Anime Last Stand",
                description = description or "N/A",
                color = embedColor,
                fields = {
                    { name = "Player Stats", value = (formatStats() ~= "" and formatStats() or "N/A"), inline = true },
                    { name = "Rewards", value = (rewardsText ~= "" and rewardsText or "No rewards found"), inline = true },
                    { name = "Units", value = (unitsText ~= "" and unitsText or "No units"), inline = false },
                    { name = "Match Result", value = (matchTime or "00:00:00") .. " - Wave " .. tostring(matchWave or "0") .. "\n" .. (mapName or "Unknown Map") .. ((mapDifficulty and mapDifficulty ~= "Unknown") and (" [" .. mapDifficulty .. "]") or "") .. " - " .. (matchResult or "Unknown"), inline = false }
                },
                footer = { text = "Byorl Last Stand | https://discord.gg/V3WcdHpd3J" }
            }
            
            local webhookContent = ""
            if hasUnitDrop then
                
                if getgenv().PingOnSecretDrop and getgenv().DiscordUserID and getgenv().DiscordUserID ~= "" then
                    webhookContent = "<@" .. getgenv().DiscordUserID .. "> 🎉 **SECRET UNIT DROP: " .. unitDropName .. "**"
                else
                end
            end
            
            local webhookHash = LocalPlayer.Name .. "_" .. matchTime .. "_" .. matchWave .. "_" .. rewardsText
            if webhookHash == lastWebhookHash then
                isProcessing = false
                getgenv().WebhookProcessing = false
                return
            end
            lastWebhookHash = webhookHash
            
            local sendSuccess = false
            local sendAttempts = 0
            local maxAttempts = 3 
            
            while not sendSuccess and sendAttempts < maxAttempts do
                sendAttempts = sendAttempts + 1
                
                local ok, result = pcall(function()
                    if webhookContent ~= "" then
                        return SendMessageEMBED(getgenv().WebhookURL, embed, webhookContent)
                    else
                        return SendMessageEMBED(getgenv().WebhookURL, embed)
                    end
                end)
                
                if ok and result then
                    sendSuccess = true
                    
                    Window:Notify({
                        Title = "Webhook Sent",
                        Description = hasUnitDrop and "Unit drop detected!" or "Match results sent",
                        Lifetime = 3
                    })
                else
                    warn("[Webhook] ❌ Send failed (Attempt " .. sendAttempts .. "/" .. maxAttempts .. ")")
                    if not ok then
                        warn("[Webhook] Error: " .. tostring(result))
                    end
                    
                    if sendAttempts < maxAttempts then
                        task.wait(1)
                    end
                end
            end
            
            if not sendSuccess then
                warn("[Webhook] Failed to send after " .. maxAttempts .. " attempts")
                Window:Notify({
                    Title = "Webhook Failed",
                    Description = "Failed to send webhook. Check URL and try again.",
                    Lifetime = 5
                })
            end
            
            task.wait(0.5)
            isProcessing = false
            getgenv().WebhookProcessing = false
        end)
        
        if not success then
            warn("[Webhook] Error in sendWebhook: " .. tostring(err))
            isProcessing = false
            getgenv().WebhookProcessing = false
        end
    end
    
    LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
        if child.Name == "EndGameUI" and getgenv().WebhookEnabled then
            task.wait(2)
            sendWebhook()
        end
    end)
    
    LocalPlayer.PlayerGui.ChildRemoved:Connect(function(child)
        if child.Name == "EndGameUI" then
            task.wait(2)
            getgenv().WebhookProcessing = false
        end
    end)
end)



do
    task.spawn(function()
        local eventsFolder = RS:FindFirstChild("Events")
    local halloweenFolder = eventsFolder and eventsFolder:FindFirstChild("Hallowen2025")
    local enterEvent = halloweenFolder and halloweenFolder:FindFirstChild("Enter")
    local startEvent = halloweenFolder and halloweenFolder:FindFirstChild("Start")
    
    while true do
        task.wait(0.5)
        if getgenv().AutoEventEnabled and enterEvent and startEvent then
            pcall(function()
                local delay = getgenv().EventJoinDelay or 0
                if delay > 0 then
                    task.wait(delay)
                end
                
                enterEvent:FireServer()
                startEvent:FireServer()
            end)
        end
    end
    end)
end

if isInLobby then
    task.spawn(function()
        local BingoEvents = RS:FindFirstChild("Events") and RS.Events:FindFirstChild("Bingo")
        if not BingoEvents then return end
        
        local UseStampEvent = BingoEvents:FindFirstChild("UseStamp")
        local ClaimRewardEvent = BingoEvents:FindFirstChild("ClaimReward")
        local CompleteBoardEvent = BingoEvents:FindFirstChild("CompleteBoard")
        
        
        while true do
            task.wait(0.1)
            if getgenv().BingoEnabled then
                pcall(function()
                    if UseStampEvent then
                        for i=1,25 do 
                            UseStampEvent:FireServer()
                        end
                    end
                    if ClaimRewardEvent then
                        for i=1,25 do 
                            ClaimRewardEvent:InvokeServer(i)
                        end
                    end
                    if CompleteBoardEvent then 
                        CompleteBoardEvent:InvokeServer()
                    end
                end)
            end
        end
    end)
    
    task.spawn(function()
        task.wait(1)
        local PurchaseEvent = RS:WaitForChild("Events"):WaitForChild("Hallowen2025"):WaitForChild("Purchase")
        local OpenCapsuleEvent = RS:WaitForChild("Remotes"):WaitForChild("OpenCapsule")
        
        local function clickButton(button)
            if not button then return false end
            local events = {"Activated", "MouseButton1Click", "MouseButton1Down", "MouseButton1Up"}
            for _, ev in ipairs(events) do
                pcall(function()
                    for _, conn in ipairs(getconnections(button[ev])) do
                        conn:Fire()
                    end
                end)
            end
            return true
        end
        
        local function clickAllPromptButtons()
            local success = false
            pcall(function()
                local prompt = LocalPlayer.PlayerGui:FindFirstChild("Prompt")
                if not prompt then return end
                
                local frame = prompt:FindFirstChild("Frame")
                if not frame then return end
                
                local textButton = frame:FindFirstChild("TextButton")
                if textButton then
                    clickButton(textButton)
                    success = true
                end
                
                local folder = frame:FindFirstChild("Folder")
                if folder then
                    local folderButton = folder:FindFirstChild("TextButton")
                    if folderButton then
                        clickButton(folderButton)
                        success = true
                    end
                end
            end)
            return success
        end
        
        while true do
            task.wait(0.1)
            if getgenv().CapsuleEnabled then
                local clientData = getClientData()
                if clientData then
                    local candyBasket = clientData.CandyBasket or 0
                    
                    if candyBasket >= 100000 then
                        pcall(function() PurchaseEvent:InvokeServer(1, 100) end)
                    elseif candyBasket >= 10000 then
                        pcall(function() PurchaseEvent:InvokeServer(1, 10) end)
                    elseif candyBasket >= 1000 then
                        pcall(function() PurchaseEvent:InvokeServer(1, 1) end)
                    end
                    
                    if candyBasket < 1000 then
                        clientData = getClientData()
                        local capsuleAmount = 0
                        if clientData and clientData.ItemData and clientData.ItemData.HalloweenCapsule2025 then
                            capsuleAmount = clientData.ItemData.HalloweenCapsule2025.Amount or 0
                        end
                        
                        if capsuleAmount > 0 then
                            pcall(function()
                                OpenCapsuleEvent:FireServer("HalloweenCapsule2025", capsuleAmount)
                            end)
                            task.wait(0.5)
                            clickAllPromptButtons()
                        end
                    end
                end
            end
        end
    end)
    end
end



do
    if isInLobby then
        task.spawn(function()
        
        local function getAvailableBreaches()
            local ok, breaches = pcall(function()
                local lobby = workspace:FindFirstChild("Lobby")
                if not lobby then return {} end
                local breachesFolder = lobby:FindFirstChild("Breaches")
                if not breachesFolder then return {} end
                local available = {}
                local children = breachesFolder:GetChildren()
                for i = 1, #children do
                    local part = children[i]
                    local breachPart = part:FindFirstChild("Breach")
                    if breachPart then
                        local proximityPrompt = breachPart:FindFirstChild("ProximityPrompt")
                        if proximityPrompt and proximityPrompt:IsA("ProximityPrompt") then
                            if proximityPrompt.ObjectText and proximityPrompt.ObjectText ~= "" then
                                local breachName = proximityPrompt.ObjectText
                                available[#available + 1] = { name = breachName, instance = part }
                            end
                        end
                    end
                end
                return available
            end)
            if not ok then return {} end
            return breaches or {}
        end
        
        while true do
            task.wait(1)
            if getgenv().BreachEnabled then
                local availableBreaches = getAvailableBreaches()
                for _, breach in ipairs(availableBreaches) do
                    local shouldJoin = getgenv().BreachAutoJoin[breach.name]
                    if shouldJoin then
                        pcall(function()
                            local remote = RS.Remotes.Breach.EnterEvent
                            remote:FireServer(breach.instance)
                        end)
                        task.wait(0.5)
                    end
                end
            end
        end
        end)
    end
end



do
    task.spawn(function()
        
        local VIM = game:GetService("VirtualInputManager")
        local TweenService = game:GetService("TweenService")
    
    local function teleportToShrine()
        local ok, err = pcall(function()
            local shrine = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Shrine")
            if not shrine then return false end
            
            local model = shrine:FindFirstChild("Model")
            if not model then return false end
            
            local proximityPrompt = model:FindFirstChild("ProximityPrompt")
            if not proximityPrompt then return false end
            
            local character = LocalPlayer.Character
            if not character then return false end
            
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            if not humanoidRootPart then return false end
            
            local shrinePosition = model:GetPivot().Position
            humanoidRootPart.CFrame = CFrame.new(shrinePosition + Vector3.new(0, 3, 0))
            
            task.wait(0.3)
            
            VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.05)
            VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
            
            return true
        end)
        
        return ok
    end
    
    local lastAttempt = 0
    
    while true do
        task.wait(1)
        
        if getgenv().AutoUnleashSukunaEnabled then
            local now = tick()
            
            if (now - lastAttempt) >= 5 then
                lastAttempt = now
                
                pcall(function()
                    local shrine = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Shrine")
                    if shrine then
                        local model = shrine:FindFirstChild("Model")
                        if model then
                            local proximityPrompt = model:FindFirstChild("ProximityPrompt")
                            if proximityPrompt then
                                teleportToShrine()
                            end
                        end
                    end
                end)
            end
        end
    end
    end)
end



do
    task.spawn(function()
        local VIM = game:GetService("VirtualInputManager")
    
    local function getAvailableCards()
        local ok, result = pcall(function()
            local playerGui = LocalPlayer.PlayerGui
            local prompt = playerGui:FindFirstChild("Prompt")
            if not prompt then return nil end
            local frame = prompt:FindFirstChild("Frame")
            if not frame or not frame:FindFirstChild("Frame") then return nil end
            local cards, cardButtons = {}, {}
            local descendants = frame:GetDescendants()
            for i = 1, #descendants do
                local d = descendants[i]
                if d:IsA("TextLabel") and d.Parent and d.Parent:IsA("Frame") then
                    local text = d.Text
                    if getgenv().CardPriority and getgenv().CardPriority[text] then
                        local button = d.Parent.Parent
                        if button:IsA("GuiButton") or button:IsA("TextButton") or button:IsA("ImageButton") then
                            table.insert(cardButtons, {text=text, button=button})
                        end
                    end
                end
            end
            table.sort(cardButtons, function(a,b) return a.button.AbsolutePosition.X < b.button.AbsolutePosition.X end)
            for i, c in ipairs(cardButtons) do
                cards[i] = { name=c.text, button=c.button }
            end
            return #cards > 0 and cards or nil
        end)
        return ok and result or nil
    end
    
    local function findBestCard(list)
        local bestIndex, bestPriority = nil, math.huge
        for i=1,#list do
            local nm = list[i].name
            local p = (getgenv().CardPriority and getgenv().CardPriority[nm]) or 999
            if p < bestPriority and p < 999 then
                bestPriority = p
                bestIndex = i
            end
        end
        if bestIndex then
            return bestIndex, list[bestIndex], bestPriority
        end
        return nil, nil, nil
    end
    
    local function pressConfirm()
        local ok, confirmButton = pcall(function()
            local prompt = LocalPlayer.PlayerGui:FindFirstChild("Prompt")
            if not prompt then return nil end
            local frame = prompt:FindFirstChild("Frame")
            if not frame then return nil end
            local inner = frame:FindFirstChild("Frame")
            if not inner then return nil end
            local children = inner:GetChildren()
            if #children < 5 then return nil end
            local button = children[5]:FindFirstChild("TextButton")
            if not button then return nil end
            local label = button:FindFirstChild("TextLabel")
            if label and label.Text == "Confirm" then return button end
            return nil
        end)
        if ok and confirmButton then
            local events = {"Activated","MouseButton1Click","MouseButton1Down","MouseButton1Up"}
            for _, ev in ipairs(events) do
                pcall(function()
                    for _, conn in ipairs(getconnections(confirmButton[ev])) do
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
        local ok = pcall(function()
            local list = getAvailableCards()
            if not list then return false end
            local _, best, priority = findBestCard(list)
            if not best or not best.button or not priority then return false end
            if priority >= 999 then return false end
            local button = best.button
            local events = {"Activated","MouseButton1Click","MouseButton1Down","MouseButton1Up"}
            for _, ev in ipairs(events) do
                pcall(function()
                    for _, conn in ipairs(getconnections(button[ev])) do
                        conn:Fire()
                    end
                end)
                task.wait(0.05)
            end
            task.wait(0.3)
            pressConfirm()
            task.wait(0.2)
        end)
        return ok
    end
    
    local function selectCardSlower()
        if not getgenv().SlowerCardSelectionEnabled then return false end
        local ok = pcall(function()
            local list = getAvailableCards()
            if not list then return false end
            local _, best, priority = findBestCard(list)
            if not best or not best.button or not priority then return false end
            if priority >= 999 then return false end
            local GuiService = game:GetService("GuiService")
            local function press(key)
                VIM:SendKeyEvent(true, key, false, game)
                task.wait(0.15)
                VIM:SendKeyEvent(false, key, false, game)
            end
            GuiService.SelectedObject = best.button
            task.wait(0.4)
            press(Enum.KeyCode.Return)
            task.wait(0.5)
            local ok2, confirmButton = pcall(function()
                local prompt = LocalPlayer.PlayerGui:FindFirstChild("Prompt")
                if not prompt then return nil end
                local frame = prompt:FindFirstChild("Frame")
                if not frame or not frame:FindFirstChild("Frame") then return nil end
                local inner = frame.Frame
                local children = inner:GetChildren()
                if #children < 5 then return nil end
                local btn = children[5]:FindFirstChild("TextButton")
                if btn and btn:FindFirstChild("TextLabel") and btn.TextLabel.Text == "Confirm" then
                    return btn
                end
                return nil
            end)
            if ok2 and confirmButton then
                GuiService.SelectedObject = confirmButton
                task.wait(0.4)
                press(Enum.KeyCode.Return)
                task.wait(0.5)
            end
            GuiService.SelectedObject = nil
        end)
        return ok
    end
    
    local function calculateCardValue(cardName, currentWave)
        local wavesRemaining = math.max(0, 50 - currentWave)
        
        local currentKills = 0
        pcall(function()
            currentKills = game:GetService("Players").LocalPlayer.leaderstats.Kills.Value
        end)
        
        local avgKillsPerWave = 40
        if currentWave > 0 and currentKills > 0 then
            avgKillsPerWave = currentKills / currentWave
        end
        
        local estimatedKillsRemaining = (wavesRemaining + 1) * avgKillsPerWave
        
        print("[Smart Card] Wave:", currentWave, "| Kills:", currentKills, "| Avg/Wave:", math.floor(avgKillsPerWave), "| Est. Remaining:", math.floor(estimatedKillsRemaining))
        
        local perWaveValue = {
            ["Critical Denial"] = 100,
            ["Weakened Resolve III"] = 50,
            ["Fog of War III"] = 50,
            ["Weakened Resolve II"] = 25,
            ["Fog of War II"] = 25,
            ["Power Reversal II"] = 25,
            ["Greedy Vampire's"] = 25,
            ["Weakened Resolve I"] = 15,
            ["Fog of War I"] = 15,
            ["Power Reversal I"] = 15,
        }
        
        local perKillBonus = {
            ["Lingering Fear II"] = 2,
            ["Hellish Gravity"] = 2,
            ["Lingering Fear I"] = 1,
            ["Deadly Striker"] = 1,
        }
        
        local calculatedValue = 0
        
        if perWaveValue[cardName] then
            calculatedValue = perWaveValue[cardName] * wavesRemaining
            print("[Smart Card] " .. cardName .. " = " .. perWaveValue[cardName] .. " × " .. wavesRemaining .. " waves = " .. calculatedValue)
        elseif perKillBonus[cardName] then
            local baseValue = perKillBonus[cardName] * estimatedKillsRemaining
            local stackingMultiplier = 1.3
            calculatedValue = baseValue * stackingMultiplier
            print("[Smart Card] " .. cardName .. " = " .. perKillBonus[cardName] .. " × " .. math.floor(estimatedKillsRemaining) .. " kills × 1.3 = " .. math.floor(calculatedValue))
        elseif cardName == "Trick or Treat Coin Flip" then
            calculatedValue = 100
            print("[Smart Card] " .. cardName .. " = 100 (risky but viable)")
        elseif cardName == "Devil's Sacrifice" then
            calculatedValue = -9999
            print("[Smart Card] " .. cardName .. " = -9999 (AVOID - disables abilities)")
        else
            print("[Smart Card] " .. cardName .. " = 0 (unknown card)")
        end
        
        return calculatedValue
    end
    
    local function selectCardSmart()
        if not getgenv().SmartCardSelectionEnabled then return false end
        local ok, result = pcall(function()
            local currentWave = 0
            pcall(function()
                local wave = RS:FindFirstChild("Wave")
                if wave and wave.Value then
                    currentWave = wave.Value
                end
            end)
            
            
            local list = getAvailableCards()
            if not list or #list == 0 then 
                return false 
            end
            
            print("[Smart Card] Found", #list, "cards available")
            
            local bestCard = nil
            local bestValue = -99999
            
            for i=1,#list do
                local nm = list[i].name
                local value = calculateCardValue(nm, currentWave)
                print("[Smart Card] Evaluating:", nm, "| Value:", math.floor(value))
                if value > bestValue then
                    bestValue = value
                    bestCard = list[i]
                    print("[Smart Card] ✓ New best card:", nm, "with value", math.floor(value))
                end
            end
            
            if not bestCard then
                print("[Smart Card] No valid card found")
                return false
            end
            
            if not bestCard.button then
                print("[Smart Card] Best card has no button:", bestCard.name)
                return false
            end
            
            print("[Smart Card] ========== SELECTED:", bestCard.name, "with value", math.floor(bestValue), "==========")
            print("[Smart Card] Clicking card button...")
            
            local GuiService = game:GetService("GuiService")
            local function press(key)
                VIM:SendKeyEvent(true, key, false, game)
                task.wait(0.05)
                VIM:SendKeyEvent(false, key, false, game)
            end
            
            GuiService.SelectedObject = nil
            task.wait(0.1)
            GuiService.SelectedObject = bestCard.button
            task.wait(0.2)
            print("[Smart Card] Pressing Enter on card...")
            press(Enum.KeyCode.Return)
            task.wait(0.1)
            GuiService.SelectedObject = nil
            print("[Smart Card] Card selected successfully!")
            
            task.wait(0.3)
            pressConfirm()
            task.wait(0.2)
            
            print("[Smart Card] Selected:", bestCard.name, "Value:", bestValue, "Wave:", currentWave)
            return true
        end)
        
        if not ok then
            warn("[Smart Card] Error:", result)
        end
        
        return ok and result
    end
    
    while true do
        task.wait(1.5)
        if getgenv().CardSelectionEnabled then
            selectCard()
        elseif getgenv().SlowerCardSelectionEnabled then
            selectCardSlower()
        elseif getgenv().SmartCardSelectionEnabled then
            selectCardSmart()
        end
    end
    end)
end



if not isInLobby then
    task.spawn(function()
        local endgameCount = 0
        local maxRoundsReached = false
        local hasRun = false
        local lastEndgameTime = 0
        local DEBOUNCE_TIME = 3
        
        print("[Seamless Fix] Waiting for Settings GUI...")
        local maxWait = 0
        repeat 
            task.wait(0.5) 
            maxWait = maxWait + 0.5 
        until LocalPlayer.PlayerGui:FindFirstChild("Settings") or maxWait > 30
        
        if not LocalPlayer.PlayerGui:FindFirstChild("Settings") then
            warn("[Seamless Fix] Settings GUI not found after 30s, seamless fix may not work")
            return
        end
        
        print("[Seamless Fix] Settings GUI found!")
        
        local function getSeamlessValue()
            local ok, result = pcall(function()
                local settings = LocalPlayer.PlayerGui:FindFirstChild("Settings")
                if settings then
                    local seamless = settings:FindFirstChild("SeamlessRetry")
                    if seamless then 
                        return seamless.Value 
                    end
                end
                return false
            end)
            return ok and result or false
        end
        
        local function setSeamlessRetry()
            pcall(function()
                local remotes = RS:FindFirstChild("Remotes")
                local setSettings = remotes and remotes:FindFirstChild("SetSettings")
                if setSettings then 
                    setSettings:InvokeServer("SeamlessRetry")
                    print("[Seamless Fix] Toggled SeamlessRetry")
                end
            end)
        end
        
        local function enableSeamlessIfNeeded()
            if not getgenv().SeamlessFixEnabled then return end
            local maxRounds = getgenv().SeamlessRounds or 4
            
            if endgameCount < maxRounds then
                if not getSeamlessValue() then
                    setSeamlessRetry()
                    print("[Seamless Fix] Enabled Seamless Retry (" .. endgameCount .. "/" .. maxRounds .. ")")
                    task.wait(0.5)
                end
            elseif endgameCount >= maxRounds then
                if getSeamlessValue() then
                    setSeamlessRetry()
                    print("[Seamless Fix] Disabled Seamless Retry - Max rounds reached (" .. endgameCount .. "/" .. maxRounds .. ")")
                    task.wait(0.5)
                end
            end
        end
        
        print("[Seamless Fix] Checking initial seamless state...")
        enableSeamlessIfNeeded()
        
        local seamlessToggleConnection
        seamlessToggleConnection = task.spawn(function()
            while true do
                task.wait(1)
                if getgenv().SeamlessFixEnabled then
                    enableSeamlessIfNeeded()
                end
            end
        end)
        
        LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
            pcall(function()
                if child.Name == "EndGameUI" and not hasRun then
                    local currentTime = tick()
                    if currentTime - lastEndgameTime < DEBOUNCE_TIME then
                        print("[Seamless Fix] Debounced duplicate EndGameUI trigger")
                        return
                    end
                    hasRun = true
                    lastEndgameTime = currentTime
                    endgameCount = endgameCount + 1
                    local maxRounds = getgenv().SeamlessRounds or 4
                    print("[Seamless Fix] Endgame detected. Current seamless rounds: " .. endgameCount .. "/" .. maxRounds)
                    
                    if endgameCount >= maxRounds and getgenv().SeamlessFixEnabled then
                        maxRoundsReached = true
                        print("[Seamless Fix] Max rounds reached, disabling seamless retry to restart match...")
                        task.wait(0.5)
                        if getSeamlessValue() then
                            setSeamlessRetry()
                            print("[Seamless Fix] Disabled Seamless Retry")
                            task.wait(0.5)
                        else
                            print("[Seamless Fix] Seamless already disabled")
                        end
                        
                        task.spawn(function()
                            print("[Seamless Fix] Waiting for EndGameUI to close...")
                            local maxWait = 0
                            while LocalPlayer.PlayerGui:FindFirstChild("EndGameUI") and maxWait < 30 do
                                task.wait(0.5)
                                maxWait = maxWait + 0.5
                            end
                            
                            print("[Seamless Fix] EndGameUI closed, attempting restart...")
                            task.wait(2)
                            
                            local success, err = pcall(function()
                                local remotes = RS:FindFirstChild("Remotes")
                                local restartEvent = remotes and remotes:FindFirstChild("RestartMatch")
                                if restartEvent then
                                    restartEvent:FireServer()
                                    print("[Seamless Fix] Restart signal sent")
                                    task.wait(3)
                                    endgameCount = 0
                                    maxRoundsReached = false
                                    hasRun = false
                                else
                                    warn("[Seamless Fix] RestartMatch remote not found")
                                end
                            end)
                            
                            if not success then
                                warn("[Seamless Fix] Restart failed:", err)
                            end
                        end)
                    end
                end
            end)
        end)
        
        LocalPlayer.PlayerGui.ChildRemoved:Connect(function(child) 
            if child.Name == "EndGameUI" then 
                task.wait(2) 
                hasRun = false 
            end 
        end)
        
        LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
            if child.Name == "TeleportUI" and maxRoundsReached then
                print("[Seamless Fix] Teleport detected after max rounds, resetting counter...")
                endgameCount = 0
                maxRoundsReached = false
                task.wait(2)
                enableSeamlessIfNeeded()
            end
        end)
    end)
    
end


do
    task.spawn(function()
        local vu = game:GetService("VirtualUser")
        Players.LocalPlayer.Idled:Connect(function()
            if getgenv().AntiAFKEnabled then
                vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(1)
                vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end
        end)
    end)
end

do
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
        blackFrame.Size = UDim2.new(1, 0, 1, 0)
        blackFrame.BackgroundColor3 = Color3.new(0, 0, 0)
        blackFrame.BorderSizePixel = 0
        blackFrame.ZIndex = -999999
        blackFrame.Parent = blackScreenGui
        
        pcall(function()
            blackScreenGui.Parent = LocalPlayer.PlayerGui
        end)
        
        pcall(function()
            if workspace.CurrentCamera then
                workspace.CurrentCamera.MaxAxisFieldOfView = 0.001
            end
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)
        
    end
    
    local function removeBlack()
        if blackScreenGui then
            blackScreenGui:Destroy()
            blackScreenGui = nil
            blackFrame = nil
        end
        
        pcall(function()
            if workspace.CurrentCamera then
                workspace.CurrentCamera.MaxAxisFieldOfView = 70
            end
        end)
        
    end
    
    while true do
        task.wait(0.5)
        if getgenv().BlackScreenEnabled then
            if not blackScreenGui then
                createBlack()
            end
        else
            if blackScreenGui then
                removeBlack()
            end
        end
    end
    end)
end

do
    task.spawn(function()
        while true do
            task.wait(1)
            if getgenv().RemoveEnemiesEnabled then
            pcall(function()
                local enemies = workspace:FindFirstChild("Enemies")
                if enemies then
                    local children = enemies:GetChildren()
                    for i = 1, #children do
                        local enemy = children[i]
                        if enemy:IsA("Model") and enemy.Name ~= "Boss" then
                            enemy:Destroy()
                        end
                    end
                end
                
                local spawnedunits = workspace:FindFirstChild("SpawnedUnits")
                if spawnedunits then
                    for _, su in pairs(spawnedunits:GetChildren()) do
                        if su:IsA("Model") then
                            su:Destroy()
                        end
                    end
                end
            end)
        end
    end
    end)
end

if getgenv().Config.toggles.AutoHideUI then
    task.spawn(function()
        task.wait(2)
        
        if Window and Window.SetState then
            local hideAttempts = 0
            local hideSuccess = false
            
            while hideAttempts < 3 and not hideSuccess do
                hideAttempts = hideAttempts + 1
                local ok = pcall(function()
                    Window:SetState(false)
                    hideSuccess = true
                end)
                
                if ok and hideSuccess then
                    break
                else
                    warn("[Auto Hide] Attempt " .. hideAttempts .. " failed, retrying...")
                    task.wait(0.5)
                end
            end
            
            if not hideSuccess then
                warn("[Auto Hide] Failed to minimize UI after 3 attempts - UI will remain visible")
            end
        else
            warn("[Auto Hide] Window not ready, skipping auto-hide")
        end
    end)
end


if not isInLobby then
    task.spawn(function()
        while true do
            task.wait(10)
            if getgenv().FPSBoostEnabled then
                pcall(function()
                    local lighting = game:GetService("Lighting")
                    for _, child in ipairs(lighting:GetChildren()) do
                        child:Destroy()
                    end
                    lighting.Ambient = Color3.new(1, 1, 1)
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
                                obj.CastShadow = false
                                if obj:FindFirstChildOfClass("Texture") then
                                    for _, t in ipairs(obj:GetChildren()) do
                                        if t:IsA("Texture") then
                                            t:Destroy()
                                        end
                                    end
                                end
                                if obj:IsA("MeshPart") then
                                    obj.TextureID = ""
                                end
                            end
                            if obj:IsA("Decal") then
                                obj:Destroy()
                            end
                        end
                        if obj:IsA("SurfaceAppearance") then
                            obj:Destroy()
                        end
                        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                            obj.Enabled = false
                        end
                        if obj:IsA("Sound") then
                            obj.Volume = 0
                            obj:Stop()
                        end
                    end
                    
                    local mapPath = game.Workspace:FindFirstChild("Map") and game.Workspace.Map:FindFirstChild("Map")
                    if mapPath then
                        for _, ch in ipairs(mapPath:GetChildren()) do
                            if not ch:IsA("Model") then
                                ch:Destroy()
                            end
                        end
                    end
                    
                    collectgarbage("collect")
                end)
            end
        end
    end)
end
