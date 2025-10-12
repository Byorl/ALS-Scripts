repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

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

local WindUI
do
    local ok, result = pcall(function()
        return require("./src/init")
    end)
    if ok then
        WindUI = result
    else
        WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
    end
end

local oldLogWarn = logwarn or warn
local function filteredWarn(...)
    local msg = tostring(...)
    if not msg:find("ImageLabel") and not msg:find("not a valid member") then
        oldLogWarn(...)
    end
end
if logwarn then logwarn = filteredWarn end
warn = filteredWarn

local function createObsidianCompat()
    local compat = {
        Options = {},
        Toggles = {},
        ForceCheckbox = false,
        ShowToggleFrameInKeybinds = true,
        KeybindFrame = { Visible = false },
        _windows = {},
        _currentWindow = nil,
        _theme = {},
    }

    local function makeSignal()
        local listeners = {}
        return {
            Connect = function(_, fn)
                table.insert(listeners, fn)
                return { Disconnect = function() end }
            end,
            Fire = function(_, ...)
                for i = 1, #listeners do
                    local fn = listeners[i]
                    local ok = pcall(fn, ...)
                    if not ok then end
                end
            end
        }
    end

    local function makeToggleProxy(key, defaultValue)
        local signal = makeSignal()
        local proxy = {
            Key = key,
            Value = defaultValue == true,
            OnChanged = function(self, cb)
                signal:Connect(function()
                    cb(self.Value)
                end)
            end,
            _fire = function(self)
                signal:Fire(self.Value)
            end,
        }
        return proxy
    end

    local function makeOptionProxy(key, element)
        local signal = makeSignal()
        local proxy = {
            Key = key,
            _element = element,
            _values = nil,
            Value = nil,
            OnChanged = function(self, cb)
                signal:Connect(function(val)
                    cb(val)
                end)
            end,
            SetValue = function(self, val)
                self.Value = val
                local e = rawget(self, "_element")
                if e then
                    if type(e.Select) == "function" then
                        pcall(function() e:Select(val) end)
                    elseif type(e.Set) == "function" then
                        pcall(function() e:Set(val) end)
                    elseif type(e.SetValue) == "function" then
                        pcall(function() e:SetValue(val) end)
                    end
                end
                signal:Fire(val)
            end,
            SetValues = function(self, list)
                self._values = list
                local e = rawget(self, "_element")
                if e and type(e.Refresh) == "function" then
                    pcall(function() e:Refresh(list) end)
                end
            end,
            _fire = function(self, val)
                self.Value = val
                signal:Fire(val)
            end,
        }
        return proxy
    end

    local windowWrapperMT
    local tabWrapperMT
    local groupWrapperMT
    local labelWrapperMT

    labelWrapperMT = {
        __index = function(self, k)
            if k == "AddKeyPicker" then
                return function(_, key, opts)
                    opts = opts or {}
                    local el = self._tab:Keybind({
                        Flag = key,
                        Title = opts.Text or "Menu keybind",
                        Desc = opts.Desc,
                        Value = (opts.Default or "LeftControl"),
                        Callback = function(v)
                            local opt = compat.Options[key]
                            if opt then opt:_fire(v) end
                            if compat._currentWindow and type(compat._currentWindow.SetToggleKey) == "function" then
                                pcall(function() compat._currentWindow:SetToggleKey(Enum.KeyCode[v]) end)
                            end
                        end,
                    })
                    local proxy = makeOptionProxy(key, el)
                    compat.Options[key] = proxy
                    return el
                end
            end
        end
    }

    groupWrapperMT = {
        __index = function(self, k)
            if k == "AddLabel" then
                return function(_, text)
                    self._tab:Section({ Title = tostring(text) })
                    return setmetatable({ _tab = self._tab }, labelWrapperMT)
                end
            elseif k == "AddDivider" then
                return function()
                    self._tab:Space({ Columns = 1 })
                end
            elseif k == "AddButton" then
                return function(_, text, cb)
                    self._tab:Button({ Title = tostring(text), Callback = function()
                        if type(cb) == "function" then cb() end
                    end })
                end
            elseif k == "AddToggle" then
                return function(_, key, cfg)
                    cfg = cfg or {}
                    local initial = cfg.Default == true
                    local proxy = compat.Toggles[key] or makeToggleProxy(key, initial)
                    compat.Toggles[key] = proxy
                    local el = self._tab:Toggle({
                        Flag = key,
                        Title = cfg.Text or key,
                        Desc = cfg.Desc,
                        Default = initial,
                        Locked = cfg.Locked == true,
                        Callback = function(state)
                            proxy.Value = state
                            if type(cfg.Callback) == "function" then
                                pcall(function() cfg.Callback(state) end)
                            end
                            proxy:_fire()
                        end
                    })
                    return el
                end
            elseif k == "AddDropdown" then
                return function(_, key, cfg)
                    cfg = cfg or {}
                    local el = self._tab:Dropdown({
                        Flag = key,
                        Title = cfg.Text or key,
                        Values = cfg.Values or {},
                        Value = cfg.Default,
                        Multi = cfg.Multi == true,
                        Searchable = cfg.Searchable == true,
                        Callback = function(value)
                            local opt = compat.Options[key]
                            if type(cfg.Callback) == "function" then
                                pcall(function() cfg.Callback(value) end)
                            end
                            if opt then opt:_fire(value) end
                        end
                    })
                    local proxy = makeOptionProxy(key, el)
                    if cfg.Default ~= nil then proxy.Value = cfg.Default end
                    compat.Options[key] = proxy
                    return el
                end
            elseif k == "AddInput" then
                return function(_, key, cfg)
                    cfg = cfg or {}
                    local el = self._tab:Input({
                        Flag = key,
                        Title = cfg.Text or key,
                        Desc = cfg.Placeholder,
                        Value = cfg.Default or "",
                        Type = (cfg.Type == "Textarea" and "Textarea" or "Input"),
                        Placeholder = cfg.Placeholder,
                        Callback = function(val)
                            if type(cfg.Callback) == "function" then
                                pcall(function() cfg.Callback(val) end)
                            end
                            local opt = compat.Options[key]
                            if opt then opt:_fire(val) end
                        end
                    })
                    local proxy = makeOptionProxy(key, el)
                    proxy.Value = cfg.Default or ""
                    compat.Options[key] = proxy
                    return el
                end
            end
        end
    }

    tabWrapperMT = {
        __index = function(self, k)
            if k == "AddLeftGroupbox" or k == "AddRightGroupbox" then
                return function(_, title)
                    if title and title ~= "" then
                        self._tab:Section({ Title = tostring(title) })
                    end
                    return setmetatable({ _tab = self._tab }, groupWrapperMT)
                end
            elseif k == "AddLabel" then
                return function(_, text)
                    self._tab:Section({ Title = tostring(text) })
                end
            end
        end
    }

    windowWrapperMT = {
        __index = function(self, k)
            if k == "AddTab" then
                return function(_, title, icon)
                    return self._wnd:Tab({ Title = tostring(title), Icon = tostring(icon or "") })
                end
            elseif k == "Section" then
                return function(_, opts)
                    return self._wnd:Section(opts)
                end
            else
                return self._wnd[k]
            end
        end
    }

    function compat:CreateWindow(opts)
        opts = opts or {}
        local wnd = WindUI:CreateWindow({
            Title = tostring(opts.Title or "ALS"),
            Author = tostring(opts.Footer or ""),
            Folder = "ALS-WindUI",
            NewElements = true,
            HideSearchBar = false,
            OpenButton = {
                Title = tostring(opts.Title or "ALS"),
                CornerRadius = UDim.new(1, 0),
                StrokeThickness = 1,
                Enabled = true,
                Draggable = true,
                OnlyMobile = false,
                Color = ColorSequence.new(Color3.fromRGB(48, 255, 106), Color3.fromRGB(231, 255, 47)),
            },
        })
        local wrapper = setmetatable({ _wnd = wnd }, windowWrapperMT)
        self._currentWindow = wnd
        return wrapper
    end

    function compat:Notify(info)
        local title = (info and (info.Title or info.title)) or "ALS"
        local content = (info and (info.Description or info.Desc or info.Content)) or ""
        local duration = (info and (info.Duration or info.Time)) or nil
        WindUI:Notify({ Title = title, Content = content, Duration = duration })
    end

    function compat:Unload()
        self.Unloaded = true
        if self._currentWindow and type(self._currentWindow.Destroy) == "function" then
            pcall(function() self._currentWindow:Destroy() end)
        end
    end

    function compat:Toggle()
        if self._currentWindow then
            local ok = pcall(function()
                if type(self._currentWindow.Toggle) == "function" then
                    self._currentWindow:Toggle()
                elseif type(self._currentWindow.SetVisible) == "function" then
                    self._currentWindow:SetVisible(not self._visible)
                    self._visible = not self._visible
                end
            end)
            if not ok then
                -- no-op if underlying doesn't support toggle
            end
        end
    end

    return compat
end

local Library = createObsidianCompat()
local ThemeManager = {
    SetLibrary = function() end,
    SetFolder = function() end,
    ApplyToTab = function() end,
}

getgenv().ALS_Library = Library
getgenv().ALS_ThemeManager = ThemeManager

local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")
local VIM = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local MOBILE_DELAY_MULTIPLIER = isMobile and 1.5 or 1.0

local function cleanupBeforeTeleport()    
    pcall(function()
        if Library and Library.Unload then
            Library:Unload()
        end
    end)
    task.wait(0.1)
    
    pcall(function()
        getgenv().ALS_Library = nil
        getgenv().ALS_ThemeManager = nil
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
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                obj.Enabled = false
                obj:Destroy()
            elseif obj:IsA("Sound") then
                obj:Stop()
                obj.Volume = 0
                obj:Destroy()
            elseif obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
                obj:Destroy()
            end
        end
    end)
    
    pcall(function()
        for _, gui in pairs(LocalPlayer.PlayerGui:GetChildren()) do
            if gui.Name ~= "Chat" and gui.Name ~= "CoreGui" and gui.Name ~= "PlayerList" then
                gui:Destroy()
            end
        end
    end)
    
    pcall(function()
        local coreGui = game:GetService("CoreGui")
        for _, gui in pairs(coreGui:GetChildren()) do
            if gui.Name:find("Wind") or gui.Name:find("ALS") or gui.Name:find("UI") then
                gui:Destroy()
            end
        end
    end)
    
    pcall(function()
        local lighting = game:GetService("Lighting")
        for _, effect in pairs(lighting:GetChildren()) do
            if not effect:IsA("Sky") and not effect:IsA("Atmosphere") then
                effect:Destroy()
            end
        end
    end)
    
    pcall(function()
        for i = 1, 5 do
            collectgarbage("collect")
            task.wait(0.15)
        end
    end)
    
    task.wait(0.8)

end

getgenv().CleanupBeforeTeleport = cleanupBeforeTeleport

local LOBBY_PLACEIDS = {12886143095, 18583778121}
local function checkIsInLobby()
    for _, placeId in ipairs(LOBBY_PLACEIDS) do
        if game.PlaceId == placeId then return true end
    end
    return false
end
local isInLobby = checkIsInLobby()

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

getgenv().AutoEventEnabled = getgenv().Config.toggles.AutoEventToggle or false
getgenv().AutoAbilitiesEnabled = getgenv().Config.toggles.AutoAbilityToggle or false
getgenv().AutoReadyEnabled = getgenv().Config.toggles.AutoReadyToggle or false
getgenv().CardSelectionEnabled = getgenv().Config.toggles.CardSelectionToggle or false
getgenv().SlowerCardSelectionEnabled = getgenv().Config.toggles.SlowerCardSelectionToggle or false
getgenv().BossRushEnabled = getgenv().Config.toggles.BossRushToggle or false
getgenv().WebhookEnabled = getgenv().Config.toggles.WebhookToggle or false
getgenv().SeamlessLimiterEnabled = getgenv().Config.toggles.SeamlessToggle or false
getgenv().BingoEnabled = getgenv().Config.toggles.BingoToggle or false
getgenv().CapsuleEnabled = getgenv().Config.toggles.CapsuleToggle or false
getgenv().RemoveEnemiesEnabled = getgenv().Config.toggles.RemoveEnemiesToggle or false
getgenv().AntiAFKEnabled = getgenv().Config.toggles.AntiAFKToggle or false
getgenv().BlackScreenEnabled = getgenv().Config.toggles.BlackScreenToggle or false
getgenv().FPSBoostEnabled = (not isInLobby) and (getgenv().Config.toggles.FPSBoostToggle or false) or false

getgenv().AutoLeaveEnabled = getgenv().Config.toggles.AutoLeaveToggle or false
getgenv().AutoFastRetryEnabled = getgenv().Config.toggles.AutoFastRetryToggle or false
getgenv().AutoNextEnabled = getgenv().Config.toggles.AutoNextToggle or false
getgenv().AutoSmartEnabled = getgenv().Config.toggles.AutoSmartToggle or false

getgenv().FinalExpAutoJoinEasyEnabled = getgenv().Config.toggles.FinalExpAutoJoinEasyToggle or false
getgenv().FinalExpAutoJoinHardEnabled = getgenv().Config.toggles.FinalExpAutoJoinHardToggle or false
getgenv().FinalExpAutoSkipShopEnabled = getgenv().Config.toggles.FinalExpAutoSkipShopToggle or false



getgenv().WebhookURL = getgenv().Config.inputs.WebhookURL or ""
getgenv().MaxSeamlessRounds = tonumber(getgenv().Config.inputs.SeamlessRounds) or 4
getgenv().UnitAbilities = getgenv().UnitAbilities or {}

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
getgenv().CardPriority = getgenv().CardPriority or {}
for n,v in pairs(CandyCards) do if getgenv().Config.inputs["Card_"..n] then getgenv().CardPriority[n] = tonumber(getgenv().Config.inputs["Card_"..n]) else getgenv().CardPriority[n] = v end end
for n,v in pairs(DevilSacrifice) do if getgenv().Config.inputs["Card_"..n] then getgenv().CardPriority[n] = tonumber(getgenv().Config.inputs["Card_"..n]) else getgenv().CardPriority[n] = v end end
for n,v in pairs(OtherCards) do if getgenv().Config.inputs["Card_"..n] then getgenv().CardPriority[n] = tonumber(getgenv().Config.inputs["Card_"..n]) else getgenv().CardPriority[n] = v end end

local BossRushGeneral = {
    ["Metal Skin"] = 0,["Raging Power"] = 0,["Demon Takeover"] = 0,["Fortune"] = 0,
    ["Chaos Eater"] = 0,["Godspeed"] = 0,["Insanity"] = 0,["Feeding Madness"] = 0,["Emotional Damage"] = 0
}
local BabyloniaCastle = {}
getgenv().BossRushCardPriority = getgenv().BossRushCardPriority or {}
for n,v in pairs(BossRushGeneral) do
    local key = "BossRush_"..n
    if getgenv().Config.inputs[key] then getgenv().BossRushCardPriority[n] = tonumber(getgenv().Config.inputs[key]) else getgenv().BossRushCardPriority[n] = v end
end
for n,v in pairs(BabyloniaCastle) do
    local key = "BabyloniaCastle_"..n
    if getgenv().Config.inputs[key] then getgenv().BossRushCardPriority[n] = tonumber(getgenv().Config.inputs[key]) else getgenv().BossRushCardPriority[n] = v end
end

getgenv().BreachAutoJoin = getgenv().BreachAutoJoin or {}
getgenv().BreachEnabled = getgenv().Config.toggles.BreachToggle or false

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

local function notify(title, content, duration)
    Library:Notify({
        Title = title or "ALS",
        Description = content or "",
        Time = duration or 3,
    })
end

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

local Window
local windowAttempts = 0
local windowCreated = false

while not windowCreated and windowAttempts < 3 do
    windowAttempts = windowAttempts + 1
    local windowSuccess, result = pcall(function()
        return Library:CreateWindow({
            Title = "ALS Halloween Event",
            Footer = "Anime Last Stand Script",
            Icon = 72399447876912,
            NotifySide = getgenv().Config.inputs.NotificationSide or "Right",
            ShowCustomCursor = getgenv().Config.toggles.ShowCustomCursor ~= false,
            Size = UDim2.fromOffset(700, 460),
        })
    end)
    if windowSuccess and result then
        Window = result
        windowCreated = true
    else
        warn("[UI] Failed to create window (Attempt " .. windowAttempts .. "/3):", result)
        task.wait(1)
        if windowAttempts >= 3 then
            Window = Library:CreateWindow({
                Title = "ALS Halloween Event",
                Footer = "Anime Last Stand Script",
                Size = UDim2.fromOffset(700, 460),
            })
            windowCreated = true
        end
    end
end

task.wait(0.5)

local UpdatesSection = Window:Section({
    Title = "Updates",
    Icon = "newspaper",
})

local MainSection = Window:Section({
    Title = "Main",
    Icon = "home",
})

local CombatSection = Window:Section({
    Title = "Combat",
    Icon = "swords",
})

local ModesSection = Window:Section({
    Title = "Game Modes",
    Icon = "gamepad-2",
})

local AutomationSection = Window:Section({
    Title = "Automation",
    Icon = "zap",
})

local SettingsSection = Window:Section({
    Title = "Settings",
    Icon = "settings",
})

local Tabs = {
    Changes = UpdatesSection:Tab({ Title = "Recent Changes", Icon = "file-text" }),
    
    AutoJoin = MainSection:Tab({ Title = "Auto Join", Icon = "log-in" }),
    GameAuto = MainSection:Tab({ Title = "Game Actions", Icon = "play" }),
    
    Abilities = CombatSection:Tab({ Title = "Auto Abilities", Icon = "zap" }),
    CardSelection = CombatSection:Tab({ Title = "Card Priority", Icon = "layers" }),
    
    BossRush = ModesSection:Tab({ Title = "Boss Rush", Icon = "shield" }),
    Breach = ModesSection:Tab({ Title = "Breach", Icon = "alert-triangle" }),
    FinalExp = ModesSection:Tab({ Title = "Final Expedition", Icon = "map" }),
    
    Webhook = AutomationSection:Tab({ Title = "Webhook", Icon = "send" }),
    SeamlessFix = AutomationSection:Tab({ Title = "Seamless Fix", Icon = "refresh-cw" }),
    Event = AutomationSection:Tab({ Title = "Event Farm", Icon = "gift" }),
    
    Performance = SettingsSection:Tab({ Title = "Performance", Icon = "gauge" }),
    Safety = SettingsSection:Tab({ Title = "Safety & UI", Icon = "shield-check" }),
    Config = SettingsSection:Tab({ Title = "Config", Icon = "save" }),
}

Tabs.Changes:Paragraph({
    Title = "🎉 Welcome to ALS Halloween Event Script",
    Desc = "Switched to WindUI for better performance and modern design. Check out the changes below!",
})

Tabs.Changes:Space()

Tabs.Changes:Section({ Title = "📅 October 10, 2025 - Major Update" })

Tabs.Changes:Paragraph({
    Title = "✨ New UI Library - WindUI",
    Desc = "Completely rebuilt the script using WindUI for a modern, clean interface with better organization and performance.",
})

Tabs.Changes:Paragraph({
    Title = "🔧 Critical Fixes",
    Desc = "• Fixed teleport/serverhop crashes caused by memory buildup\n• Ultra aggressive cleanup before every teleport (100% crash prevention)\n• Fixed config not loading into UI (toggles and dropdowns now show saved values)\n• Fixed dropdowns appearing blank on script load\n• Added AutoJoinConfig persistence to save your map selections",
})

Tabs.Changes:Paragraph({
    Title = "🎨 UI Improvements",
    Desc = "• Reorganized tabs into logical sections with icons\n• Cleaner ability display with better formatting\n• Added emoji icons to sections for easier navigation\n• Improved dropdown and toggle initialization\n• Better mobile optimization",
})

Tabs.Changes:Paragraph({
    Title = "⚡ Performance Enhancements",
    Desc = "• Periodic garbage collection every 30 seconds\n• Enhanced FPS Boost (removes particles, sounds, shadows)\n• More aggressive graphics reduction\n• Memory optimization throughout the script\n• Faster UI loading times",
})

Tabs.Changes:Paragraph({
    Title = "🆕 New Features",
    Desc = "• Server Hop (Safe) button with automatic cleanup\n• Better player state validation after teleport\n• Improved console logging for debugging\n• Config auto-save on every change\n• This changelog tab!",
})

Tabs.Changes:Space()

Tabs.Changes:Section({ Title = "🔮 Coming Soon" })

Tabs.Changes:Paragraph({
    Title = "Planned Features",
    Desc = "• Auto-update system\n• More customization options\n• Additional game mode support\n• Performance analytics\n• Cloud config sync",
})

Tabs.Changes:Space()

Tabs.Changes:Section({ Title = "💡 Tips" })

Tabs.Changes:Paragraph({
    Title = "Getting Started",
    Desc = "1. Configure your Auto Join settings in the Main section\n2. Set up Auto Abilities for your units in Combat section\n3. Enable FPS Boost in Settings for better performance\n4. Use Server Hop (Safe) button to avoid crashes when switching servers",
})

Tabs.Changes:Divider()

local function applyOldConfigValue(flag, elementType)
    if elementType == "toggle" and getgenv().Config.toggles[flag] ~= nil then
        return getgenv().Config.toggles[flag]
    elseif elementType == "input" and getgenv().Config.inputs[flag] ~= nil then
        return getgenv().Config.inputs[flag]
    elseif elementType == "dropdown" and getgenv().Config.dropdowns[flag] ~= nil then
        return getgenv().Config.dropdowns[flag]
    end
    return nil
end

local function adaptTab(tab)
    return setmetatable({ _tab = tab }, {
        __index = function(self, k)
            if k == "AddToggle" then
                return function(_, flag, cfg)
                    cfg = cfg or {}
                    local configValue = applyOldConfigValue(flag, "toggle")
                    if configValue ~= nil then
                        cfg.Default = configValue
                    end
                    
                    if cfg.Default == nil then
                        cfg.Default = false
                    end
                    
                    local toggle = tab:Toggle({
                        Flag = flag,
                        Title = cfg.Text or flag,
                        Desc = cfg.Desc,
                        Default = cfg.Default,
                        Locked = cfg.Locked == true,
                        Callback = function(state)
                            if Library.Toggles[flag] then
                                Library.Toggles[flag].Value = state
                            end
                            getgenv().Config.toggles[flag] = state
                            saveConfig(getgenv().Config)
                            if cfg.Callback then
                                cfg.Callback(state)
                            end
                        end,
                    })
                    
                    local proxy = {
                        Value = cfg.Default,
                        SetValue = function(self, val)
                            self.Value = val
                            if toggle and toggle.Set then
                                toggle:Set(val)
                            end
                        end,
                        _element = toggle
                    }
                    Library.Toggles[flag] = proxy
                    
                    task.spawn(function()
                        task.wait(0.15)
                        if toggle and toggle.Set and cfg.Default ~= nil then
                            toggle:Set(cfg.Default)
                        end
                    end)
                    
                    return toggle
                end
            elseif k == "AddDropdown" then
                return function(_, flag, cfg)
                    cfg = cfg or {}
                    local configValue = applyOldConfigValue(flag, "dropdown")
                    if configValue ~= nil then
                        cfg.Default = configValue
                        cfg.Value = configValue
                    end
                    
                    local initialValue = cfg.Value or cfg.Default
                    
                    if cfg.Multi == true and initialValue then
                        if type(initialValue) == "table" then
                            local dictValue = {}
                            for _, v in pairs(initialValue) do
                                dictValue[v] = true
                            end
                            initialValue = dictValue
                        end
                    end
                    
                    local dropdown = tab:Dropdown({
                        Flag = flag,
                        Title = cfg.Text or cfg.Title or flag,
                        Values = cfg.Values or {},
                        Value = initialValue, 
                        Multi = cfg.Multi == true,
                        AllowNone = cfg.AllowNone == true,
                        Searchable = cfg.Searchable == true,
                        Callback = function(value)
                            if Library.Options[flag] then
                                Library.Options[flag].Value = value
                            end
                            getgenv().Config.dropdowns[flag] = value
                            saveConfig(getgenv().Config)
                            if cfg.Callback then
                                cfg.Callback(value)
                            end
                        end,
                    })
                    
                    local proxy = {
                        Value = initialValue,
                        SetValue = function(self, val)
                            self.Value = val
                            if dropdown and dropdown.Select then
                                dropdown:Select(val)
                            end
                        end,
                        SetValues = function(self, list)
                            if dropdown and dropdown.Refresh then
                                dropdown:Refresh(list)
                            end
                        end,
                        _element = dropdown
                    }
                    Library.Options[flag] = proxy
                    
                    task.spawn(function()
                        task.wait(0.3)
                        if dropdown and dropdown.Select and initialValue then
                            dropdown:Select(initialValue)
                            local displayValue = initialValue
                            if type(initialValue) == "table" then
                                displayValue = game:GetService("HttpService"):JSONEncode(initialValue)
                            end
                            print("[UI] Force-set dropdown " .. flag .. " to " .. tostring(displayValue))
                        end
                    end)
                    
                    return dropdown
                end
            elseif k == "AddInput" then
                return function(_, flag, cfg)
                    cfg = cfg or {}
                    local configValue = applyOldConfigValue(flag, "input")
                    if configValue ~= nil then
                        cfg.Default = configValue
                    end
                    return tab:Input({
                        Flag = flag,
                        Title = cfg.Text or cfg.Title or flag,
                        Desc = cfg.Desc or cfg.Placeholder,
                        Value = cfg.Default,
                        Type = (cfg.Type == "Textarea" and "Textarea" or "Input"),
                        Placeholder = cfg.Placeholder,
                        Callback = function(value)
                            getgenv().Config.inputs[flag] = value
                            saveConfig(getgenv().Config)
                            if cfg.Callback then
                                cfg.Callback(value)
                            end
                        end,
                    })
                end
            elseif k == "AddButton" then
                return function(_, text, cb)
                    return tab:Button({ Title = tostring(text), Callback = cb })
                end
            elseif k == "AddLabel" then
                return function(_, text)
                    return tab:Section({ Title = tostring(text) })
                end
            elseif k == "AddDivider" then
                return function()
                    return tab:Divider({})
                end
            elseif k == "Paragraph" or k == "Space" or k == "Divider" or k == "Button" or k == "Toggle" or k == "Dropdown" or k == "Input" or k == "Section" then
                return tab[k]
            else
                return tab[k]
            end
        end
    })
end

local GB = {}
GB.Main_Left = adaptTab(Tabs.AutoJoin)
GB.Main_Right = adaptTab(Tabs.GameAuto)
GB.Ability_Left = adaptTab(Tabs.Abilities)
GB.Ability_Right = adaptTab(Tabs.Abilities)
GB.Card_Left = adaptTab(Tabs.CardSelection)
GB.Card_Right = adaptTab(Tabs.CardSelection)
GB.Boss_Left = adaptTab(Tabs.BossRush)
GB.Boss_Right = adaptTab(Tabs.BossRush)
GB.Breach_Left = adaptTab(Tabs.Breach)
GB.FinalExp_Left = adaptTab(Tabs.FinalExp)
GB.FinalExp_Right = adaptTab(Tabs.FinalExp)
GB.Webhook_Left = adaptTab(Tabs.Webhook)
GB.Seam_Left = adaptTab(Tabs.SeamlessFix)
GB.Event_Left = adaptTab(Tabs.Event)
GB.Misc_Left = adaptTab(Tabs.Performance)
GB.Misc_Right = adaptTab(Tabs.Safety)
GB.Settings_Left = adaptTab(Tabs.Config)
GB.Settings_Right = adaptTab(Tabs.Config)

local Options = Library.Options
local Toggles = Library.Toggles

local function addToggle(group, key, text, default, onChanged)
    local configValue = applyOldConfigValue(key, "toggle")
    if configValue ~= nil then
        default = configValue
    end
    
    if default == nil then
        default = false
    end
    
    local toggle = group:AddToggle(key, {
        Text = text,
        Default = default,
        Callback = function(val)
            if onChanged then onChanged(val) end
        end,
    })
    
    if Toggles[key] and onChanged then
        -- The callback is already set in AddToggle, no need to duplicate
    end
    
    return toggle
end

if isInLobby then
    GB.Main_Left:Paragraph({
        Title = "🎮 Auto Join System",
        Desc = "Automatically join maps and start games. Configure your preferred mode, map, act, and difficulty below."
    })
    GB.Main_Left:Space()
    
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

    GB.Main_Left:AddDropdown("AutoJoinMode", {
        Values = {"Story","Infinite","Raids","ElementalCaverns","LegendaryStages","Dungeon","Survival","Challenge"},
        Default = getgenv().AutoJoinConfig.mode or "Story",
        Text = "Mode",
        Callback = function(value)
            getgenv().AutoJoinConfig.mode = value
            getgenv().Config.autoJoin.mode = value
            saveConfig(getgenv().Config)
            local newMaps = getMapsByMode(value)
            if Options.AutoJoinMap then Options.AutoJoinMap:SetValues(newMaps) end
            if #newMaps > 0 then
                if Options.AutoJoinMap then Options.AutoJoinMap:SetValue(newMaps[1]) end
                getgenv().AutoJoinConfig.map = newMaps[1]
                getgenv().Config.autoJoin.map = newMaps[1]
                saveConfig(getgenv().Config)
            end
        end,
        Searchable = true,
    })
    GB.Main_Left:AddDropdown("AutoJoinMap", {
        Values = getMapsByMode(getgenv().AutoJoinConfig.mode),
        Default = getgenv().AutoJoinConfig.map ~= "" and getgenv().AutoJoinConfig.map or nil,
        Text = "Map",
        Callback = function(value)
            getgenv().AutoJoinConfig.map = value
            getgenv().Config.autoJoin.map = value
            saveConfig(getgenv().Config)
        end,
        Searchable = true,
    })
    GB.Main_Left:AddDropdown("AutoJoinAct", {
        Values = {"1","2","3","4","5","6"},
        Default = tostring(getgenv().AutoJoinConfig.act or 1),
        Text = "Act",
        Callback = function(value)
            getgenv().AutoJoinConfig.act = tonumber(value) or 1
            getgenv().Config.autoJoin.act = tonumber(value) or 1
            saveConfig(getgenv().Config)
        end,
    })
    GB.Main_Left:AddDropdown("AutoJoinDifficulty", {
        Values = {"Normal","Nightmare","Purgatory","Insanity"},
        Default = getgenv().AutoJoinConfig.difficulty or "Normal",
        Text = "Difficulty",
        Callback = function(value)
            getgenv().AutoJoinConfig.difficulty = value
            getgenv().Config.autoJoin.difficulty = value
            saveConfig(getgenv().Config)
        end,
    })

    addToggle(GB.Main_Left, "AutoJoinToggle", "Auto Join Map", getgenv().AutoJoinConfig.enabled or false, function(val)
        getgenv().AutoJoinConfig.enabled = val
        getgenv().Config.autoJoin.enabled = val
        saveConfig(getgenv().Config)
        notify("Auto Join", val and "Enabled" or "Disabled", 3)
    end)
    addToggle(GB.Main_Left, "AutoJoinStartToggle", "Auto Start", getgenv().AutoJoinConfig.autoStart or false, function(val)
        getgenv().AutoJoinConfig.autoStart = val
        getgenv().Config.autoJoin.autoStart = val
        saveConfig(getgenv().Config)
        notify("Auto Start", val and "Enabled" or "Disabled", 3)
    end)
    addToggle(GB.Main_Left, "FriendsOnlyToggle", "Friends Only", getgenv().AutoJoinConfig.friendsOnly or false, function(val)
        getgenv().AutoJoinConfig.friendsOnly = val
        getgenv().Config.autoJoin.friendsOnly = val
        saveConfig(getgenv().Config)
        pcall(function()
            RS.Remotes.Teleporter.InteractEvent:FireServer("FriendsOnly")
        end)
        notify("Friends Only", val and "Enabled" or "Disabled", 3)
    end)
else
    GB.Main_Left:Paragraph({
        Title = "⚠️ Lobby Only",
        Desc = "The Auto Join system is only available in the lobby. Please rejoin the lobby to use this feature."
    })
end

GB.Main_Left:Space({ Columns = 1 })

GB.Main_Right:Paragraph({
    Title = "🎯 Game Actions",
    Desc = "Automate common game actions like leaving, replaying, and progressing to the next stage."
})
GB.Main_Right:Space()
GB.Main_Right:Section({ Title = "⚙️ Action Toggles" })
addToggle(GB.Main_Right, "AutoLeaveToggle", "Auto Leave", getgenv().Config.toggles.AutoLeaveToggle or false, function(val)
    getgenv().AutoLeaveEnabled = val
    getgenv().Config.toggles.AutoLeaveToggle = val
    saveConfig(getgenv().Config)
    notify("Auto Leave", val and "Enabled" or "Disabled", 3)
end)
addToggle(GB.Main_Right, "AutoFastRetryToggle", "Auto Replay", getgenv().Config.toggles.AutoFastRetryToggle or false, function(val)
    getgenv().AutoFastRetryEnabled = val
    getgenv().Config.toggles.AutoFastRetryToggle = val
    saveConfig(getgenv().Config)
    notify("Auto Replay", val and "Enabled" or "Disabled", 3)
end)
addToggle(GB.Main_Right, "AutoNextToggle", "Auto Next", getgenv().Config.toggles.AutoNextToggle or false, function(val)
    getgenv().AutoNextEnabled = val
    getgenv().Config.toggles.AutoNextToggle = val
    saveConfig(getgenv().Config)
    notify("Auto Next", val and "Enabled" or "Disabled", 3)
end)
addToggle(GB.Main_Right, "AutoSmartToggle", "Auto Leave/Replay/Next", getgenv().Config.toggles.AutoSmartToggle or false, function(val)
    getgenv().AutoSmartEnabled = val
    getgenv().Config.toggles.AutoSmartToggle = val
    saveConfig(getgenv().Config)
    notify("Auto Leave/Replay/Next", val and "Enabled" or "Disabled", 3)
end)
addToggle(GB.Main_Right, "AutoReadyToggle", "Auto Ready", getgenv().Config.toggles.AutoReadyToggle or false, function(val)
    getgenv().AutoReadyEnabled = val
    getgenv().Config.toggles.AutoReadyToggle = val
    saveConfig(getgenv().Config)
    notify("Auto Ready", val and "Enabled" or "Disabled", 3)
end)

GB.Ability_Left:Paragraph({
    Title = "⚡ Auto Ability System",
    Desc = "Automatically trigger unit abilities during gameplay. Configure conditions and timing for each ability on the right."
})
GB.Ability_Left:Space()

GB.Ability_Left:Section({ Title = "🎛️ Master Control" })
addToggle(GB.Ability_Left, "AutoAbilityToggle", "✨ Enable Auto Abilities", getgenv().AutoAbilitiesEnabled, function(val)
    getgenv().AutoAbilitiesEnabled = val
    getgenv().Config.toggles.AutoAbilityToggle = val
    saveConfig(getgenv().Config)
    notify("Auto Ability", val and "Enabled" or "Disabled", 3)
end)

local function buildAutoAbilityUI()
    local clientData = getClientData()
    if not clientData or not clientData.Slots then
        notify("Auto Ability", "ClientData not available yet, retrying...", 3)
        return
    end
    local sortedSlots = {"Slot1","Slot2","Slot3","Slot4","Slot5","Slot6"}
    for _, slotName in ipairs(sortedSlots) do
        local slotData = clientData.Slots[slotName]
        if slotData and slotData.Value then
            local unitName = slotData.Value
            local abilities = getAllAbilities(unitName)
            if next(abilities) then
                GB.Ability_Right:AddDivider()
                GB.Ability_Right:AddLabel("📦 " .. unitName .. " (" .. slotName .. " • Lvl " .. tostring(slotData.Level or 0) .. ")")
                
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
                    
                    local abilityIcon = abilityData.isAttribute and "🔒" or "⚡"
                    local abilityInfo = abilityIcon .. " " .. abilityName .. " (CD: " .. tostring(abilityData.cooldown) .. "s)"
                    
                    addToggle(GB.Ability_Right, unitName .. "_" .. abilityName .. "_Toggle", abilityInfo, defaultToggle, function(v)
                        cfg.enabled = v
                        getgenv().Config.abilities[unitName] = getgenv().Config.abilities[unitName] or {}
                        getgenv().Config.abilities[unitName][abilityName] = getgenv().Config.abilities[unitName][abilityName] or {}
                        getgenv().Config.abilities[unitName][abilityName].enabled = v
                        saveConfig(getgenv().Config)
                    end)

                    local defaultList = {}
                    if cfg.onlyOnBoss then defaultList["Only On Boss"] = true end
                    if cfg.requireBossInRange then defaultList["Boss In Range"] = true end
                    if cfg.delayAfterBossSpawn then defaultList["Delay After Boss Spawn"] = true end
                    if cfg.useOnWave then defaultList["On Wave"] = true end
                    
                    local dropdownDefault = next(defaultList) and defaultList or nil

                    local modifierKey = unitName .. "_" .. abilityName .. "_Modifiers"
                    local dropdown = GB.Ability_Right:AddDropdown(modifierKey, {
                        Values = {"Only On Boss","Boss In Range","Delay After Boss Spawn","On Wave"},
                        Multi = true,
                        AllowNone = true,
                        Default = dropdownDefault,
                        Text = "  > Conditions",
                        Callback = function(Value)
                            local selected = {}
                            if type(Value) == "table" then
                                for k,v in pairs(Value) do if v == true then selected[k] = true end end
                            end
                            cfg.onlyOnBoss = selected["Only On Boss"] or false
                            cfg.requireBossInRange = selected["Boss In Range"] or false
                            cfg.delayAfterBossSpawn = selected["Delay After Boss Spawn"] or false
                            cfg.useOnWave = selected["On Wave"] or false
                            getgenv().Config.abilities[unitName] = getgenv().Config.abilities[unitName] or {}
                            local store = getgenv().Config.abilities[unitName]
                            store[abilityName] = store[abilityName] or {}
                            store[abilityName].onlyOnBoss = cfg.onlyOnBoss
                            store[abilityName].requireBossInRange = cfg.requireBossInRange
                            store[abilityName].delayAfterBossSpawn = cfg.delayAfterBossSpawn
                            store[abilityName].useOnWave = cfg.useOnWave
                            saveConfig(getgenv().Config)
                        end,
                    })
                    
                    if dropdownDefault and next(dropdownDefault) then
                        task.spawn(function()
                            task.wait(0.4)
                            if Options[modifierKey] and Options[modifierKey].SetValue then
                                Options[modifierKey]:SetValue(dropdownDefault)
                            end
                        end)
                    end
                    
                    GB.Ability_Right:AddInput(unitName .. "_" .. abilityName .. "_Wave", {
                        Text = "  > Wave Number",
                        Default = (saved and saved.specificWave and tostring(saved.specificWave)) or "",
                        Numeric = true,
                        Finished = true,
                        Placeholder = "Required if 'On Wave' selected",
                        Callback = function(text)
                            local num = tonumber(text)
                            cfg.specificWave = num
                            getgenv().Config.abilities[unitName] = getgenv().Config.abilities[unitName] or {}
                            getgenv().Config.abilities[unitName][abilityName] = getgenv().Config.abilities[unitName][abilityName] or {}
                            getgenv().Config.abilities[unitName][abilityName].specificWave = num
                            saveConfig(getgenv().Config)
                        end,
                    })
                end
            end
        end
    end
end

task.spawn(function()
    task.wait(2 * MOBILE_DELAY_MULTIPLIER)
    local maxRetries, retryDelay = 10, 3 * MOBILE_DELAY_MULTIPLIER
    for i=1,maxRetries do
        local ok = pcall(function()
            local cd = getClientData()
            if cd and cd.Slots then
                buildAutoAbilityUI()
            else
                if i <= 3 then
                    notify("Auto Ability","Loading units... ("..i.."/"..maxRetries..")",2)
                end
            end
        end)
        if ok then break end
        task.wait(retryDelay)
    end
end)

GB.Card_Left:Paragraph({
    Title = "🎴 Card Priority System",
    Desc = "Automatically select cards based on priority. Lower number = higher priority (1 is best, 999 to skip)."
})
GB.Card_Left:Space()

GB.Card_Left:Section({ Title = "⚙️ Selection Mode" })
addToggle(GB.Card_Left, "CardSelectionToggle", "⚡ Fast Mode", getgenv().CardSelectionEnabled, function(v)
    getgenv().CardSelectionEnabled = v
    getgenv().Config.toggles.CardSelectionToggle = v
    if v and getgenv().SlowerCardSelectionEnabled then
        getgenv().SlowerCardSelectionEnabled = false
        getgenv().Config.toggles.SlowerCardSelectionToggle = false
        if Toggles.SlowerCardSelectionToggle then
            Toggles.SlowerCardSelectionToggle:SetValue(false)
        end
    end
    saveConfig(getgenv().Config)
    notify("Card Selection", v and "Fast Mode Enabled" or "Disabled", 3)
end)
addToggle(GB.Card_Left, "SlowerCardSelectionToggle", "🐢 Slower Mode (More Reliable)", getgenv().SlowerCardSelectionEnabled, function(v)
    getgenv().SlowerCardSelectionEnabled = v
    getgenv().Config.toggles.SlowerCardSelectionToggle = v
    if v and getgenv().CardSelectionEnabled then
        getgenv().CardSelectionEnabled = false
        getgenv().Config.toggles.CardSelectionToggle = false
        if Toggles.CardSelectionToggle then
            Toggles.CardSelectionToggle:SetValue(false)
        end
    end
    saveConfig(getgenv().Config)
    notify("Card Selection", v and "Slower Mode Enabled" or "Disabled", 3)
end)

GB.Card_Left:Space()
GB.Card_Left:Paragraph({
    Title = "💡 How It Works",
    Desc = "The script will automatically select cards in order of priority (1-999). Cards with priority 999 will be skipped. Adjust priorities below to customize selection.",
})

GB.Card_Right:Section({ Title = "🍬 Candy Cards", Box = true })
do
    local candyNames = {}
    for k in pairs(CandyCards) do table.insert(candyNames, k) end
    table.sort(candyNames, function(a,b) return (CandyCards[a] or 999) < (CandyCards[b] or 999) end)
    for _, cardName in ipairs(candyNames) do
        local key = "Card_"..cardName
        local defaultValue = getgenv().Config.inputs[key] or tostring(CandyCards[cardName])
        GB.Card_Right:AddInput(key, {
            Text = cardName,
            Default = defaultValue,
            Numeric = true,
            Finished = true,
            Placeholder = "Priority (1-999)",
            Callback = function(Value)
                local num = tonumber(Value)
                if num then
                    getgenv().CardPriority[cardName] = num
                    getgenv().Config.inputs[key] = tostring(num)
                    saveConfig(getgenv().Config)
                end
            end,
        })
        getgenv().CardPriority[cardName] = tonumber(defaultValue) or CandyCards[cardName]
    end
end

GB.Card_Right:Space()
GB.Card_Right:Section({ Title = "😈 Devil's Sacrifice", Box = true })
for cardName,priority in pairs(DevilSacrifice) do
    local key = "Card_"..cardName
    local defaultValue = getgenv().Config.inputs[key] or tostring(priority)
    GB.Card_Right:AddInput(key, {
        Text = cardName,
        Default = defaultValue,
        Numeric = true,
        Finished = true,
        Placeholder = "Priority (1-999)",
        Callback = function(Value)
            local num = tonumber(Value)
            if num then
                getgenv().CardPriority[cardName] = num
                getgenv().Config.inputs[key] = tostring(num)
                saveConfig(getgenv().Config)
            end
        end,
    })
    getgenv().CardPriority[cardName] = tonumber(defaultValue) or priority
end

GB.Card_Right:Space()
GB.Card_Right:Section({ Title = "📋 Other Cards", Box = true })
do
    local otherNames = {}
    for k in pairs(OtherCards) do table.insert(otherNames, k) end
    table.sort(otherNames)
    for _, cardName in ipairs(otherNames) do
        local key = "Card_"..cardName
        local defaultValue = getgenv().Config.inputs[key] or tostring(OtherCards[cardName])
        GB.Card_Right:AddInput(key, {
            Text = cardName,
            Default = defaultValue,
            Numeric = true,
            Finished = true,
            Placeholder = "Priority (1-999)",
            Callback = function(Value)
                local num = tonumber(Value)
                if num then
                    getgenv().CardPriority[cardName] = num
                    getgenv().Config.inputs[key] = tostring(num)
                    saveConfig(getgenv().Config)
                end
            end,
        })
        getgenv().CardPriority[cardName] = tonumber(defaultValue) or OtherCards[cardName]
    end
end

GB.Boss_Left:Paragraph({
    Title = "Boss Rush Mode",
    Desc = "Automatically select cards during Boss Rush mode with custom priorities"
})
GB.Boss_Left:Space({ Columns = 1 })

addToggle(GB.Boss_Left, "BossRushToggle", "Enable Boss Rush Card Selection", getgenv().BossRushEnabled, function(v)
    getgenv().BossRushEnabled = v
    getgenv().Config.toggles.BossRushToggle = v
    saveConfig(getgenv().Config)
    notify("Boss Rush", v and "Enabled" or "Disabled", 3)
end)

GB.Boss_Right:AddLabel("Lower number = higher priority • Set to 999 to avoid", true)
GB.Boss_Right:AddDivider()
GB.Boss_Right:AddLabel("🎯 General Cards")
do
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
        GB.Boss_Right:AddInput(inputKey, {
            Text = cardName .. " ("..cardType..")",
            Default = defaultValue,
            Numeric = true,
            Finished = true,
            Placeholder = "Priority (1-999)",
            Callback = function(Value)
                local num = tonumber(Value)
                if num then
                    getgenv().BossRushCardPriority[cardName] = num
                    getgenv().Config.inputs[inputKey] = tostring(num)
                    saveConfig(getgenv().Config)
                end
            end,
        })
        getgenv().BossRushCardPriority[cardName] = tonumber(defaultValue) or BossRushGeneral[cardName]
    end
end

if not isInLobby then
    GB.Boss_Right:AddDivider()
    GB.Boss_Right:AddLabel("🏰 Babylonia Castle")
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
                GB.Boss_Right:AddInput(inputKey, {
                    Text = cardName .. " ("..cardType..")",
                    Default = defaultValue,
                    Numeric = true,
                    Finished = true,
                    Placeholder = "Priority (1-999)",
                    Callback = function(Value)
                        local num = tonumber(Value)
                        if num then
                            getgenv().BossRushCardPriority[cardName] = num
                            getgenv().Config.inputs[inputKey] = tostring(num)
                            saveConfig(getgenv().Config)
                        end
                    end,
                })
                getgenv().BossRushCardPriority[cardName] = tonumber(defaultValue) or 999
            end
        end
    end)
else
    GB.Boss_Right:AddLabel("Babylonia Castle cards are only available outside the lobby.", true)
end

GB.Breach_Left:Paragraph({
    Title = "Breach Auto-Join",
    Desc = "Automatically join specific Breach modes when they become available"
})
GB.Breach_Left:Space({ Columns = 1 })

if isInLobby then
    addToggle(GB.Breach_Left, "BreachToggle", "Enable Breach Auto-Join", getgenv().BreachEnabled, function(v)
        getgenv().BreachEnabled = v
        getgenv().Config.toggles.BreachToggle = v
        saveConfig(getgenv().Config)
        notify("Breach Auto-Join", v and "Enabled" or "Disabled", 3)
    end)
    GB.Breach_Left:Space({ Columns = 1 })
    GB.Breach_Left:Divider({ Title = "📋 Available Breaches" })
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
                    addToggle(GB.Breach_Left, breachKey, breach.name .. statusText, savedState, function(v)
                        getgenv().BreachAutoJoin[breach.name] = v
                        getgenv().Config.toggles[breachKey] = v
                        saveConfig(getgenv().Config)
                    end)
                end
                breachesLoaded = true
            end
        end
    end)
    if not breachesLoaded then
        GB.Breach_Left:Paragraph({
            Title = "⚠️ Error",
            Desc = "Could not load breach data from MapParameters. The module may not be available."
        })
    end
else
    GB.Breach_Left:Paragraph({
        Title = "⚠️ Lobby Only",
        Desc = "The Auto Breach feature can only be used in the lobby. Please rejoin the lobby to use this feature."
    })
end

GB.FinalExp_Left:Paragraph({
    Title = "Final Expedition Auto Join",
    Desc = "Automatically join Final Expedition mode with your preferred difficulty"
})
GB.FinalExp_Left:Space({ Columns = 1 })

if isInLobby then
    addToggle(GB.FinalExp_Left, "FinalExpAutoJoinEasyToggle", "Auto Join Easy", getgenv().FinalExpAutoJoinEasyEnabled, function(v)
        getgenv().FinalExpAutoJoinEasyEnabled = v
        getgenv().Config.toggles.FinalExpAutoJoinEasyToggle = v
        saveConfig(getgenv().Config)
        notify("Final Expedition", v and "Auto Join Easy Enabled" or "Auto Join Easy Disabled", 3)
    end)

    addToggle(GB.FinalExp_Left, "FinalExpAutoJoinHardToggle", "Auto Join Hard", getgenv().FinalExpAutoJoinHardEnabled, function(v)
        getgenv().FinalExpAutoJoinHardEnabled = v
        getgenv().Config.toggles.FinalExpAutoJoinHardToggle = v
        saveConfig(getgenv().Config)
        notify("Final Expedition", v and "Auto Join Hard Enabled" or "Auto Join Hard Disabled", 3)
    end)

    GB.FinalExp_Left:Paragraph({
        Title = "⚠️ Important",
        Desc = "Only enable ONE auto join option at a time to avoid conflicts"
    })
else
    GB.FinalExp_Left:Paragraph({
        Title = "⚠️ Lobby Only",
        Desc = "Auto Join features are only available in the lobby. Please rejoin the lobby to use this feature."
    })
end

GB.FinalExp_Right:Paragraph({
    Title = "Automation Features",
    Desc = "Additional automation options for Final Expedition mode"
})
GB.FinalExp_Right:Space({ Columns = 1 })

addToggle(GB.FinalExp_Right, "FinalExpAutoSkipShopToggle", "Auto Skip Shop", getgenv().FinalExpAutoSkipShopEnabled, function(v)
    getgenv().FinalExpAutoSkipShopEnabled = v
    getgenv().Config.toggles.FinalExpAutoSkipShopToggle = v
    saveConfig(getgenv().Config)
    notify("Final Expedition", v and "Auto Skip Shop Enabled" or "Auto Skip Shop Disabled", 3)
end)

GB.FinalExp_Right:Paragraph({
    Title = "How it works",
    Desc = "Automatically selects dungeon options and skips the shop screen"
})
GB.FinalExp_Right:AddLabel("Use Auto Leave/Replay/Next in Main tab to automatically leave on last round", true)

GB.Webhook_Left:Paragraph({
    Title = "Discord Notifications",
    Desc = "Get real-time notifications about game events sent directly to your Discord server"
})
GB.Webhook_Left:Space({ Columns = 1 })

addToggle(GB.Webhook_Left, "WebhookToggle", "Enable Webhook Notifications", getgenv().WebhookEnabled, function(v)
    getgenv().WebhookEnabled = v
    getgenv().Config.toggles.WebhookToggle = v
    saveConfig(getgenv().Config)
    if v then
        if (getgenv().WebhookURL == "" or not string.match(getgenv().WebhookURL, "^https://discord%.com/api/webhooks/")) then
            notify("Webhook", "Please enter a valid webhook URL first", 5)
            getgenv().WebhookEnabled = false
            getgenv().Config.toggles.WebhookToggle = false
            saveConfig(getgenv().Config)
        else
            notify("Webhook", "Enabled", 3)
        end
    else
        notify("Webhook", "Disabled", 3)
    end
end)
GB.Webhook_Left:AddInput("WebhookURL", {
    Text = "Webhook URL",
    Default = getgenv().WebhookURL or "",
    Numeric = false,
    Finished = true,
    Placeholder = "https://discord.com/api/webhooks/...",
    Callback = function(Value)
        getgenv().WebhookURL = Value or ""
        getgenv().Config.inputs.WebhookURL = getgenv().WebhookURL
        saveConfig(getgenv().Config)
    end,
})

GB.Seam_Left:Paragraph({
    Title = "Seamless Retry Fix",
    Desc = "Automatically leave after a set number of rounds to prevent game issues"
})
GB.Seam_Left:Space({ Columns = 1 })

addToggle(GB.Seam_Left, "SeamlessToggle", "Enable Seamless Fix", getgenv().SeamlessLimiterEnabled, function(v)
    getgenv().SeamlessLimiterEnabled = v
    getgenv().Config.toggles.SeamlessToggle = v
    saveConfig(getgenv().Config)
    notify("Seamless Fix", v and "Enabled" or "Disabled", 3)
end)
GB.Seam_Left:AddInput("SeamlessRounds", {
    Text = "Max Rounds Before Restart",
    Default = getgenv().Config.inputs.SeamlessRounds or "4",
    Numeric = true,
    Finished = true,
    Placeholder = "Default: 4",
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
})

addToggle(GB.Event_Left, "AutoEventToggle", "Auto Event Join", getgenv().AutoEventEnabled, function(val)
    getgenv().AutoEventEnabled = val
    getgenv().Config.toggles.AutoEventToggle = val
    saveConfig(getgenv().Config)
    notify("Auto Event", val and "Enabled" or "Disabled", 3)
end)
GB.Event_Left:Paragraph({
    Title = "Halloween 2025 Event",
    Desc = "Automated features for the Halloween event including Bingo and Capsules"
})
GB.Event_Left:Space({ Columns = 1 })

if isInLobby then
    GB.Event_Left:Divider({ Title = "🎲 Auto Bingo" })
    addToggle(GB.Event_Left, "BingoToggle", "Enable Auto Bingo", getgenv().BingoEnabled, function(v)
        getgenv().BingoEnabled = v
        getgenv().Config.toggles.BingoToggle = v
        saveConfig(getgenv().Config)
        notify("Auto Bingo", v and "Enabled" or "Disabled", 3)
    end)
    GB.Event_Left:Paragraph({
        Title = "How it works",
        Desc = "Uses stamps (25x), claims rewards, and completes the board automatically"
    })
    
    GB.Event_Left:Space({ Columns = 1 })
    GB.Event_Left:Divider({ Title = "🎁 Auto Capsules" })
    addToggle(GB.Event_Left, "CapsuleToggle", "Enable Auto Capsules", getgenv().CapsuleEnabled, function(v)
        getgenv().CapsuleEnabled = v
        getgenv().Config.toggles.CapsuleToggle = v
        saveConfig(getgenv().Config)
        notify("Auto Capsules", v and "Enabled" or "Disabled", 3)
    end)
    GB.Event_Left:Paragraph({
        Title = "How it works",
        Desc = "Buys capsules (100/10/1 based on candy) and opens all automatically"
    })
else
    GB.Event_Left:Paragraph({
        Title = "⚠️ Lobby Only",
        Desc = "Bingo and Capsule features are only available in the lobby. Please rejoin the lobby to use these features."
    })
end

GB.Misc_Left:Paragraph({
    Title = "Performance Optimization",
    Desc = "Boost FPS and reduce lag by removing visual elements"
})
GB.Misc_Left:Space({ Columns = 1 })

if not isInLobby then
    addToggle(GB.Misc_Left, "FPSBoostToggle", "FPS Boost", getgenv().FPSBoostEnabled, function(v)
        getgenv().FPSBoostEnabled = v
        getgenv().Config.toggles.FPSBoostToggle = v
        saveConfig(getgenv().Config)
        notify("FPS Boost", v and "Enabled" or "Disabled", 3)
    end)
else
    getgenv().FPSBoostEnabled = false
end
addToggle(GB.Misc_Left, "RemoveEnemiesToggle", "Remove Enemies & Units", getgenv().RemoveEnemiesEnabled, function(v)
    getgenv().RemoveEnemiesEnabled = v
    getgenv().Config.toggles.RemoveEnemiesToggle = v
    saveConfig(getgenv().Config)
    notify("Remove Enemies", v and "Enabled" or "Disabled", 3)
end)
addToggle(GB.Misc_Left, "BlackScreenToggle", "Black Screen Mode", getgenv().BlackScreenEnabled, function(v)
    getgenv().BlackScreenEnabled = v
    getgenv().Config.toggles.BlackScreenToggle = v
    saveConfig(getgenv().Config)
    notify("Black Screen", v and "Enabled" or "Disabled", 3)
end)

GB.Misc_Right:Paragraph({
    Title = "Safety & Anti-AFK",
    Desc = "Keep your account safe and prevent disconnections"
})
GB.Misc_Right:Space({ Columns = 1 })

addToggle(GB.Misc_Right, "AntiAFKToggle", "Anti-AFK", getgenv().AntiAFKEnabled, function(v)
    getgenv().AntiAFKEnabled = v
    getgenv().Config.toggles.AntiAFKToggle = v
    saveConfig(getgenv().Config)
    notify("Anti-AFK", v and "Enabled" or "Disabled", 3)
end)

GB.Settings_Left:Paragraph({
    Title = "Config Management",
    Desc = "Your settings are automatically saved to: " .. CONFIG_FOLDER .. "/" .. CONFIG_FILE
})
GB.Settings_Left:Space({ Columns = 1 })

GB.Settings_Left:Button({
    Title = "💾 Force Save Config",
    Callback = function()
        local success = saveConfig(getgenv().Config)
        if success then notify("Config", "Settings saved successfully!", 3) else notify("Config", "Failed to save settings!", 5) end
    end
})

GB.Settings_Left:Button({
    Title = "📁 Open Config Folder",
    Callback = function()
        notify("Config Location", CONFIG_FOLDER .. "/" .. CONFIG_FILE, 5)
    end
})

GB.Settings_Left:Space({ Columns = 1 })
GB.Settings_Left:Divider({ Title = "UI Preferences" })

GB.Settings_Left:Toggle({
    Flag = "KeybindMenuOpen",
    Title = "Show Keybind Menu",
    Default = Library.KeybindFrame.Visible,
    Callback = function(value)
        Library.KeybindFrame.Visible = value
    end,
})

GB.Settings_Left:Toggle({
    Flag = "ShowCustomCursor",
    Title = "Custom Cursor",
    Default = getgenv().Config.toggles.ShowCustomCursor ~= false,
    Callback = function(Value)
        Library.ShowCustomCursor = Value
        getgenv().Config.toggles.ShowCustomCursor = Value
        saveConfig(getgenv().Config)
    end,
})

GB.Settings_Left:Dropdown({
    Flag = "NotificationSide",
    Title = "Notification Side",
    Values = { "Left", "Right" },
    Default = getgenv().Config.inputs.NotificationSide or "Right",
    Callback = function(Value)
        Library:SetNotifySide(Value)
        getgenv().Config.inputs.NotificationSide = Value
        saveConfig(getgenv().Config)
    end,
})

GB.Settings_Right:AddDropdown("DPIDropdown", {
    Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
    Default = getgenv().Config.inputs.DPIScale or "100%",
    Text = "DPI Scale",
    Callback = function(Value)
        Value = Value:gsub("%%", "")
        local DPI = tonumber(Value)
        Library:SetDPIScale(DPI)
        getgenv().Config.inputs.DPIScale = Value .. "%"
        saveConfig(getgenv().Config)
    end,
})

pcall(function()
    if getgenv().Config.inputs.DPIScale then
        local savedDPI = getgenv().Config.inputs.DPIScale:gsub("%%", "")
        local DPI = tonumber(savedDPI)
        if DPI then
            Library:SetDPIScale(DPI)
        end
    end
end)

GB.Settings_Right:AddDivider()

local savedKeybind = applyOldConfigValue("MenuKeybind", "input") or "LeftControl"

GB.Settings_Right:AddInput("MenuKeybind", {
    Text = "Menu Keybind",
    Default = savedKeybind,
    Placeholder = "Enter key name (e.g. LeftControl, H, G)",
    Callback = function(value)
        if value and value ~= "" then
            local keyCode = Enum.KeyCode[value]
            if keyCode then
                pcall(function()
                    if Library._currentWindow and type(Library._currentWindow.SetToggleKey) == "function" then
                        Library._currentWindow:SetToggleKey(keyCode)
                    end
                end)
            end
        end
    end,
})

GB.Settings_Right:AddButton("Server Hop (Safe)", function()
    notify("Server Hop", "Cleaning up and hopping to new server...", 3)
    task.spawn(function()
        task.wait(1)
        cleanupBeforeTeleport()
        local ok, err = pcall(function()
            TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
        end)
        if not ok then
            warn("[Server Hop] Failed:", err)
        end
    end)
end)

GB.Settings_Right:AddButton("Unload", function()
    pcall(function()
        if Library and Library.Unload then
            Library:Unload()
        end
    end)
end)

task.wait(0.5)

local notifyAttempts = 0
while notifyAttempts < 3 do
    notifyAttempts = notifyAttempts + 1
    local ok = pcall(function()
        notify("🎃 ALS Halloween Event", "UI loaded with improved organization! Check out the new tab sections for better navigation.", 5)
    end)
    if ok then break end
    task.wait(1)
end



if getgenv().Config.toggles.AutoHideUIToggle then
    task.spawn(function()
        task.wait(2)
        if Library and Library.Unloaded ~= true then
            local hideAttempts = 0
            local hideSuccess = false
            while hideAttempts < 3 and not hideSuccess do
                hideAttempts = hideAttempts + 1
                local ok = pcall(function()
                    if Library and Library.Toggle and type(Library.Toggle) == "function" then
                        Library:Toggle()
                        hideSuccess = true
                    end
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
            warn("[Auto Hide] Library not ready or already unloaded, skipping auto-hide")
        end
    end)
end

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

task.spawn(function()
    repeat task.wait() until game.CoreGui:FindFirstChild("RobloxPromptGui")
    local promptOverlay = game.CoreGui.RobloxPromptGui.promptOverlay
    promptOverlay.ChildAdded:Connect(function(child)
        if child.Name == "ErrorPrompt" then
            task.spawn(function()
                cleanupBeforeTeleport()
                while true do
                    local ok = pcall(function()
                        TeleportService:Teleport(12886143095, Players.LocalPlayer)
                    end)
                    if not ok then
                        task.wait(1)
                    end
                end
            end)
        end
    end)
end)

task.spawn(function()
    while true do
        task.wait(30)
        pcall(function()
            collectgarbage("collect")
        end)
    end
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
    end
end)

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
                        if enemy:IsA("Model") and enemy.Name ~= "Boss" then enemy:Destroy() end
                    end
                end
                local spawnedunits = workspace:FindFirstChild("SpawnedUnits")
                if spawnedunits then
                    for _, su in pairs(spawnedunits:GetChildren()) do if su:IsA("Model") then su:Destroy() end end
                end
            end)
        end
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
                            obj.CastShadow = false
                            if obj:FindFirstChildOfClass("Texture") then
                                for _, t in ipairs(obj:GetChildren()) do if t:IsA("Texture") then t:Destroy() end end
                            end
                            if obj:IsA("MeshPart") then obj.TextureID = "" end
                        end
                        if obj:IsA("Decal") then obj:Destroy() end
                    end
                    if obj:IsA("SurfaceAppearance") then obj:Destroy() end
                    if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                        obj.Enabled = false
                    end
                    if obj:IsA("Sound") then
                        obj.Volume = 0
                        obj:Stop()
                    end
                end
                
                local mapPath = game.Workspace:FindFirstChild("Map") and game.Workspace.Map:FindFirstChild("Map")
                if mapPath then for _, ch in ipairs(mapPath:GetChildren()) do if not ch:IsA("Model") then ch:Destroy() end end end
                
                collectgarbage("collect")
            end)
        end
    end
end)

task.spawn(function()
    local eventsFolder = RS:FindFirstChild("Events")
    local halloweenFolder = eventsFolder and eventsFolder:FindFirstChild("Hallowen2025")
    local enterEvent = halloweenFolder and halloweenFolder:FindFirstChild("Enter")
    local startEvent = halloweenFolder and halloweenFolder:FindFirstChild("Start")
    while true do
        task.wait(0.5)
        if getgenv().AutoEventEnabled and enterEvent and startEvent then
            pcall(function() enterEvent:FireServer(); startEvent:FireServer() end)
        end
    end
end)

if isInLobby then
    task.spawn(function()
        local finalExpRemote = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("FinalExpeditionStart")
        if not finalExpRemote then
            warn("[Final Expedition] FinalExpeditionStart not found")
            return
        end
        while true do
            task.wait(2)
            if getgenv().FinalExpAutoJoinEasyEnabled then
                local success = pcall(function()
                    finalExpRemote:FireServer("Easy")
                end)
                if not success then
                    warn("[Final Expedition] Failed to join Easy mode")
                end
            elseif getgenv().FinalExpAutoJoinHardEnabled then
                local success = pcall(function()
                    finalExpRemote:FireServer("Hard")
                end)
                if not success then
                    warn("[Final Expedition] Failed to join Hard mode")
                end
            end
        end
    end)
end

if not isInLobby then
    task.spawn(function()
        local abilitySelection = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("AbilitySelection")
        if not abilitySelection then
            warn("[Final Expedition] AbilitySelection remote not found")
            return
        end
        task.spawn(function()
            while true do
                task.wait(5)
                if getgenv().FinalExpAutoSkipShopEnabled then
                    pcall(function()
                        abilitySelection:FireServer("FinalExpeditionSelection", "Double_Dungeon")
                    end)
                end
            end
        end)
        task.spawn(function()
            while true do
                task.wait(5)
                if getgenv().FinalExpAutoSkipShopEnabled then
                    pcall(function()
                        abilitySelection:FireServer("FinalExpeditionSelection", "Dungeon")
                    end)
                end
            end
        end)
    end)
end

local isProcessing = false
task.spawn(function()
    local function press(key)
        VIM:SendKeyEvent(true, key, false, game)
        task.wait(0.1)
        VIM:SendKeyEvent(false, key, false, game)
    end
    local GuiService = game:GetService("GuiService")
    local hasProcessedCurrentUI = false
    local endGameUIDetectedTime = 0
    local lastEndGameUIInstance = nil

    LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
        if child.Name == "EndGameUI" then
            hasProcessedCurrentUI = false
            endGameUIDetectedTime = tick()
            lastEndGameUIInstance = child
        end
    end)

    LocalPlayer.PlayerGui.ChildRemoved:Connect(function(child)
        if child.Name == "EndGameUI" then
            hasProcessedCurrentUI = false
            lastEndGameUIInstance = nil
        end
    end)
    while true do
        task.wait(0.5 * MOBILE_DELAY_MULTIPLIER)
        local success, errorMsg = pcall(function()
            local endGameUI = LocalPlayer.PlayerGui:FindFirstChild("EndGameUI")
            if endGameUI and endGameUI:FindFirstChild("BG") and endGameUI.BG:FindFirstChild("Buttons") then
                if lastEndGameUIInstance and endGameUI ~= lastEndGameUIInstance then
                    hasProcessedCurrentUI = false
                    lastEndGameUIInstance = endGameUI
                    endGameUIDetectedTime = tick()
                end
                if hasProcessedCurrentUI then
                    return
                end
                local buttons = endGameUI.BG.Buttons
                local nextButton = buttons:FindFirstChild("Next")
                local retryButton = buttons:FindFirstChild("Retry")
                local leaveButton = buttons:FindFirstChild("Leave")
                local buttonToPress, actionName = nil, ""
                task.wait(0.5)
                if getgenv().AutoSmartEnabled then
                    if nextButton and nextButton.Visible then
                        buttonToPress = nextButton
                        actionName = "Next"
                    elseif retryButton and retryButton.Visible then
                        buttonToPress = retryButton
                        actionName = "Replay"
                    elseif leaveButton then
                        buttonToPress = leaveButton
                        actionName = "Leave"
                    end
                elseif getgenv().AutoNextEnabled and nextButton and nextButton.Visible then
                    buttonToPress = nextButton
                    actionName = "Next"
                elseif getgenv().AutoFastRetryEnabled and retryButton and retryButton.Visible then
                    buttonToPress = retryButton
                    actionName = "Replay"
                elseif getgenv().AutoLeaveEnabled and leaveButton then
                    buttonToPress = leaveButton
                    actionName = "Leave"
                end
                if buttonToPress then
                    task.wait(0.3)
                    if getgenv().WebhookEnabled then
                        local timeSinceDetection = tick() - endGameUIDetectedTime
                        if timeSinceDetection < 3 then
                            return
                        end
                        if isProcessing then
                            return
                        end
                    end
                    hasProcessedCurrentUI = true
                    GuiService.SelectedObject = buttonToPress
                    repeat
                        press(Enum.KeyCode.Return)
                        task.wait(0.5)
                    until not LocalPlayer.PlayerGui:FindFirstChild("EndGameUI")
                    GuiService.SelectedObject = nil
                end
                if GuiService.SelectedObject ~= nil then
                    GuiService.SelectedObject = nil
                end
            end
        end)
        if not success then
            warn("[Auto Leave/Replay] Error in loop: " .. tostring(errorMsg))
        end
    end
end)

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
                                            print("[Auto Ready] Player ready fired")
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

task.spawn(function()
    local function getGameSpeed()
        local ok, speed = pcall(function()
            return RS:WaitForChild("TimeScale", 5).Value
        end)
        return ok and speed or 3
    end
    local GAME_SPEED = getGameSpeed()
    local Towers = workspace:WaitForChild("Towers", 10)
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
        towerInfoCache = {}
        print("[Auto Abilities] Round trackers reset")
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
    local function isOnCooldown(towerName, abilityName)
        local d = getAbilityData(towerName, abilityName) if not d or not d.cooldown then return false end
        local key = towerName .. "_" .. abilityName
        local last = abilityCooldowns[key]
        if not last then return false end
        return (tick() - last) < (d.cooldown / GAME_SPEED)
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
            if not generalBossSpawnTime then generalBossSpawnTime = tick() print("[Auto Abilities] Boss spawned, waiting 2 seconds...") end
            return (tick() - generalBossSpawnTime) >= 2
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
        task.wait(1)
        if getgenv().AutoAbilitiesEnabled then
            pcall(function()
                local currentWave = getCurrentWave()
                local hasBoss = bossExists()
                if currentWave < lastWave then resetRoundTrackers() end
                if getgenv().SeamlessLimiterEnabled and lastWave >= 50 and currentWave < 50 then resetRoundTrackers() end
                lastWave = currentWave
                if not Towers then return end
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
            end)
        end
    end
end)

task.spawn(function()
    local function getAvailableCards()
        local ok, result = pcall(function()
            local playerGui = LocalPlayer.PlayerGui
            local prompt = playerGui:FindFirstChild("Prompt") if not prompt then return nil end
            local frame = prompt:FindFirstChild("Frame") if not frame or not frame:FindFirstChild("Frame") then return nil end
            local cards, cardButtons = {}, {}
            local descendants = frame:GetDescendants()
            for i = 1, #descendants do
                local d = descendants[i]
                if d:IsA("TextLabel") and d.Parent and d.Parent:IsA("Frame") then
                    local text = d.Text
                    if getgenv().CardPriority[text] then
                        local button = d.Parent.Parent
                        if button:IsA("GuiButton") or button:IsA("TextButton") or button:IsA("ImageButton") then
                            table.insert(cardButtons, {text=text, button=button})
                        end
                    end
                end
            end
            table.sort(cardButtons, function(a,b) return a.button.AbsolutePosition.X < b.button.AbsolutePosition.X end)
            for i, c in ipairs(cardButtons) do cards[i] = { name=c.text, button=c.button } end
            return #cards > 0 and cards or nil
        end)
        return ok and result or nil
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
        local ok = pcall(function()
            local list = getAvailableCards() if not list then return false end
            local _, best = findBestCard(list)
            if not best or not best.button then return false end
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
            local list = getAvailableCards() if not list then return false end
            local _, best = findBestCard(list)
            if not best or not best.button then return false end
            local button = best.button
            local GuiService = game:GetService("GuiService")
            local function press(key)
                VIM:SendKeyEvent(true, key, false, game)
                task.wait(0.15)
                VIM:SendKeyEvent(false, key, false, game)
            end
            GuiService.SelectedObject = button
            task.wait(0.4)
            press(Enum.KeyCode.Return)
            task.wait(0.5)
            local ok2, confirmButton = pcall(function()
                local prompt = LocalPlayer.PlayerGui:FindFirstChild("Prompt") if not prompt then return nil end
                local frame = prompt:FindFirstChild("Frame") if not frame then return nil end
                local inner = frame:FindFirstChild("Frame") if not inner then return nil end
                local children = inner:GetChildren() if #children < 5 then return nil end
                local button = children[5]:FindFirstChild("TextButton") if not button then return nil end
                local label = button:FindFirstChild("TextLabel") if label and label.Text == "Confirm" then return button end
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
    while true do
        task.wait(1.5)
        if getgenv().CardSelectionEnabled then
            selectCard()
        elseif getgenv().SlowerCardSelectionEnabled then
            selectCardSlower()
        end
    end
end)

task.spawn(function()
    local function getBossRushCards()
        local ok, result = pcall(function()
            local playerGui = LocalPlayer.PlayerGui
            local prompt = playerGui:FindFirstChild("Prompt") if not prompt then return nil end
            local frame = prompt:FindFirstChild("Frame") if not frame or not frame:FindFirstChild("Frame") then return nil end
            local cards, cardButtons = {}, {}
            local descendants = frame:GetDescendants()
            for i = 1, #descendants do
                local d = descendants[i]
                if d:IsA("TextLabel") and d.Parent and d.Parent:IsA("Frame") then
                    local text = d.Text
                    if getgenv().BossRushCardPriority[text] then
                        local button = d.Parent.Parent
                        if button:IsA("GuiButton") or button:IsA("TextButton") or button:IsA("ImageButton") then
                            table.insert(cardButtons, {text=text, button=button})
                        end
                    end
                end
            end
            table.sort(cardButtons, function(a,b) return a.button.AbsolutePosition.X < b.button.AbsolutePosition.X end)
            for i, c in ipairs(cardButtons) do cards[i] = { name=c.text, button=c.button } end
            return #cards > 0 and cards or nil
        end)
        return ok and result or nil
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
        local ok = pcall(function()
            local list = getBossRushCards() if not list then return false end
            local _, bc, pri = best(list)
            if pri >= 999 then return false end
            if not bc or not bc.button then return false end
            local events={"Activated","MouseButton1Click","MouseButton1Down","MouseButton1Up"}
            for _,ev in ipairs(events) do pcall(function() for _,conn in ipairs(getconnections(bc.button[ev])) do conn:Fire() end end) end
            task.wait(0.2)
            confirm()
        end)
        return ok
    end
    while true do
        task.wait(1.5)
        if getgenv().BossRushEnabled then select() end
    end
end)

task.spawn(function()
    local hasRun = 0
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
            local ui = LocalPlayer.PlayerGui:FindFirstChild("EndGameUI")
            if not ui then return {} end
            local holder = ui:FindFirstChild("BG") and ui.BG:FindFirstChild("Container") and ui.BG.Container:FindFirstChild("Rewards") and ui.BG.Container.Rewards:FindFirstChild("Holder")
            if not holder then return {} end
            local waitTime = 0
            local lastCount = 0
            local stableCount = 0
            repeat
                task.wait(0.3) waitTime = waitTime + 0.3
                local children = holder:GetChildren()
                local currentCount = 0
                for i = 1, #children do if children[i]:IsA("TextButton") then currentCount = currentCount + 1 end end
                if currentCount == lastCount and currentCount > 0 then stableCount = stableCount + 1 else stableCount = 0 end
                lastCount = currentCount
            until (stableCount >= 5 and currentCount > 0) or waitTime > 4
            for _, item in pairs(holder:GetChildren()) do
                if item:IsA("TextButton") then
                    local rewardName, rewardAmount
                    local unitName = item:FindFirstChild("UnitName")
                    if unitName and unitName.Text and unitName.Text ~= "" then rewardName = unitName.Text end
                    local itemName = item:FindFirstChild("ItemName")
                    if itemName and itemName.Text and itemName.Text ~= "" then rewardName = itemName.Text end
                    if rewardName then
                        local amountLabel = item:FindFirstChild("Amount")
                        if amountLabel and amountLabel.Text then
                            local amountText = amountLabel.Text
                            local clean = string.gsub(string.gsub(string.gsub(amountText, "x", ""), "+", ""), ",", "")
                            rewardAmount = tonumber(clean)
                        else
                            rewardAmount = 1
                        end
                        if rewardAmount then table.insert(rewards, { name = rewardName, amount = rewardAmount }) end
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
            if not ui then return "00:00:00","0","Unknown" end
            local stats = ui:FindFirstChild("BG") and ui.BG:FindFirstChild("Container") and ui.BG.Container:FindFirstChild("Stats")
            if not stats then return "00:00:00", "0", "Unknown" end
            local r = (stats:FindFirstChild("Result") and stats.Result.Text) or "Unknown"
            local t = (stats:FindFirstChild("ElapsedTime") and stats.ElapsedTime.Text) or "00:00:00"
            local w = (stats:FindFirstChild("EndWave") and stats.EndWave.Text) or "0"
            if t:find("Total Time:") then local m,s = t:match("Total Time:%s*(%d+):(%d+)") if m and s then t = string.format("%02d:%02d:%02d", 0, tonumber(m) or 0, tonumber(s) or 0) end end
            if w:find("Wave Reached:") then local wm = w:match("Wave Reached:%s*(%d+)") if wm then w = wm end end
            if r:lower():find("win") or r:lower():find("victory") then r = "VICTORY" elseif r:lower():find("defeat") or r:lower():find("lose") or r:lower():find("loss") then r = "DEFEAT" end
            return t, w, r
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
    local lastWebhookHash = ""
    local lastWebhookTime = 0
    local WEBHOOK_COOLDOWN = 15
    local function sendWebhook()
        pcall(function()
            if not getgenv().WebhookEnabled then return end
            if isProcessing then return end
            local currentTime = tick()
            if currentTime - lastWebhookTime < WEBHOOK_COOLDOWN then return end
            if getgenv()._webhookLock and (currentTime - getgenv()._webhookLock) < 10 then return end
            getgenv()._webhookLock = currentTime
            lastWebhookTime = currentTime
            isProcessing = true
            hasRun = currentTime
            local rewards = getRewards()
            local matchTime, matchWave, matchResult = getMatchResult()
            local mapName, mapDifficulty = getMapInfo()
            local clientData = getClientData()
            if not clientData then isProcessing = false return end
            local function formatStats()
                local stats = "<:gold:1265957290251522089> "..formatNumber(clientData.Gold or 0)
                stats = stats .. "\n<:jewel:1217525743408648253> " .. formatNumber(clientData.Jewels or 0)
                stats = stats .. "\n<:emerald:1389165843966984192> " .. formatNumber(clientData.Emeralds or 0)
                stats = stats .. "\n<:rerollshard:1426315987019501598> " .. formatNumber(clientData.Rerolls or 0)
                stats = stats .. "\n<:candybasket:1426304615284084827> " .. formatNumber(clientData.CandyBasket or 0)
                local bingoStamps = 0
                if clientData.ItemData and clientData.ItemData.HallowenBingoStamp then bingoStamps = clientData.ItemData.HallowenBingoStamp.Amount or 0 end
                stats = stats .. "\n<:bingostamp:1426362482141954068> " .. formatNumber(bingoStamps)
                return stats
            end
            local rewardsText = ""
            if #rewards > 0 then
                for _, r in ipairs(rewards) do
                    local total = 0
                    local itemName = r.name
                    if clientData[itemName] and type(clientData[itemName]) == "number" then total = clientData[itemName]
                    elseif clientData.ItemData and clientData.ItemData[itemName] and clientData.ItemData[itemName].Amount then total = clientData.ItemData[itemName].Amount
                    elseif clientData.Items and clientData.Items[itemName] and clientData.Items[itemName].Amount then total = clientData.Items[itemName].Amount
                    elseif itemName == "Candy Basket" and clientData.CandyBasket then total = clientData.CandyBasket
                    elseif itemName:find("Bingo Stamp") and clientData.ItemData and clientData.ItemData.HallowenBingoStamp then total = clientData.ItemData.HallowenBingoStamp.Amount or 0
                    else total = r.amount end
                    rewardsText = rewardsText .. "+"..formatNumber(r.amount).." "..itemName.." [ Total: "..formatNumber(total).." ]\n"
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
            local description = "**Username:** ||"..LocalPlayer.Name.."||\n**Level:** "..(clientData.Level or 0).." ["..formatNumber(clientData.EXP or 0).."/"..formatNumber(clientData.MaxEXP or 0).."]"
            local embed = { title="Anime Last Stand", description=description or "N/A", color=0x00ff00, fields={
                { name="Player Stats", value=(formatStats() ~= "" and formatStats() or "N/A"), inline=true },
                { name="Rewards", value=(rewardsText ~= "" and rewardsText or "No rewards found"), inline=true },
                { name="Units", value=(unitsText ~= "" and unitsText or "No units"), inline=false },
                { name="Match Result", value=(matchTime or "00:00:00") .. " - Wave " .. tostring(matchWave or "0") .. "\n" .. (mapName or "Unknown Map") .. ((mapDifficulty and mapDifficulty ~= "Unknown") and (" ["..mapDifficulty.."]") or "") .. " - " .. (matchResult or "Unknown"), inline=false }
            }, footer={ text="Halloween Hook" } }
            local webhookHash = LocalPlayer.Name .. "_" .. matchTime .. "_" .. matchWave .. "_" .. rewardsText
            if webhookHash == lastWebhookHash then
                isProcessing = false
                return
            end
            lastWebhookHash = webhookHash
            local sendSuccess = false
            local sendAttempts = 0
            while not sendSuccess and sendAttempts < 2 do
                sendAttempts = sendAttempts + 1
                local ok = pcall(function()
                    SendMessageEMBED(getgenv().WebhookURL, embed)
                end)
                if ok then
                    sendSuccess = true
                    print("[Webhook] Successfully sent!")
                else
                    warn("[Webhook] Send failed (Attempt " .. sendAttempts .. "/2)")
                    task.wait(2)
                end
            end
            task.wait(1)
            isProcessing = false
        end)
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
            isProcessing = false
            if getgenv()._lastRewardHash then
                getgenv()._lastRewardHash = nil
            end
        end
    end)
end)

task.spawn(function()
    if not getgenv().SeamlessLimiterEnabled then return end
    pcall(function()
        local endgameCount = 0
        local hasRun = false
        local lastEndgameTime = 0
        local DEBOUNCE_TIME = 5
        local maxWait = 0
        repeat task.wait(0.5) maxWait = maxWait + 0.5 until not LocalPlayer.PlayerGui:FindFirstChild("TeleportUI") or maxWait > 30
        maxWait = 0
        repeat task.wait(0.5) maxWait = maxWait + 0.5 until LocalPlayer.PlayerGui:FindFirstChild("Settings") or maxWait > 30
        local function getSeamlessValue()
            local ok, result = pcall(function()
                local settings = LocalPlayer.PlayerGui:FindFirstChild("Settings")
                if settings then
                    local seamless = settings:FindFirstChild("SeamlessRetry")
                else
                end
                return false
            end)
            return ok and result or false
        end
        local function setSeamlessRetry()
            pcall(function()
                local remotes = RS:FindFirstChild("Remotes")
                local setSettings = remotes and remotes:FindFirstChild("SetSettings")
                if setSettings then setSettings:InvokeServer("SeamlessRetry") end
            end)
        end
        local currentSeamless = getSeamlessValue()
        if endgameCount < (getgenv().MaxSeamlessRounds or 4) then
        end
        LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
            pcall(function()
                if child.Name == "EndGameUI" and not hasRun then
                    local currentTime = tick()
                    hasRun = true
                    lastEndgameTime = currentTime
                    endgameCount = endgameCount + 1
                    local maxRounds = getgenv().MaxSeamlessRounds or 4
                    if endgameCount >= maxRounds then
                    end
                end
            end)
        end)
        LocalPlayer.PlayerGui.ChildRemoved:Connect(function(child) if child.Name == "EndGameUI" then task.wait(2) hasRun = false end end)
    end)
end)

task.spawn(function()
    if not isInLobby then return end
    task.wait(1)
    local BingoEvents = RS:FindFirstChild("Events") and RS.Events:FindFirstChild("Bingo")
    if not BingoEvents then return end
    local UseStampEvent = BingoEvents:FindFirstChild("UseStamp")
    local ClaimRewardEvent = BingoEvents:FindFirstChild("ClaimReward")
    local CompleteBoardEvent = BingoEvents:FindFirstChild("CompleteBoard")
    print("[Auto Bingo] Bingo automation loaded!")
    while true do
        task.wait(0.1)
        if getgenv().BingoEnabled then
            pcall(function()
                if UseStampEvent then for i=1,25 do UseStampEvent:FireServer() end end
                if ClaimRewardEvent then for i=1,25 do ClaimRewardEvent:InvokeServer(i) end end
                if CompleteBoardEvent then CompleteBoardEvent:InvokeServer() end
            end)
        end
    end
end)

task.spawn(function()
    if not isInLobby then return end
    task.wait()
    local PurchaseEvent = RS:WaitForChild("Events"):WaitForChild("Hallowen2025"):WaitForChild("Purchase")
    local OpenCapsuleEvent = RS:WaitForChild("Remotes"):WaitForChild("OpenCapsule")
    print("[Auto Capsules] Capsule automation loaded!")
    while true do
        task.wait(0.1)
        if getgenv().CapsuleEnabled then
            local clientData = getClientData()
            if clientData then
                local candyBasket = clientData.CandyBasket or 0
                local capsuleAmount = 0
                if clientData.ItemData and clientData.ItemData.HalloweenCapsule2025 then capsuleAmount = clientData.ItemData.HalloweenCapsule2025.Amount or 0 end
                if candyBasket >= 100000 then pcall(function() PurchaseEvent:InvokeServer(1, 100) end)
                elseif candyBasket >= 10000 then pcall(function() PurchaseEvent:InvokeServer(1, 10) end)
                elseif candyBasket >= 1000 then pcall(function() PurchaseEvent:InvokeServer(1, 1) end) end
                clientData = getClientData()
                if clientData and clientData.ItemData and clientData.ItemData.HalloweenCapsule2025 then capsuleAmount = clientData.ItemData.HalloweenCapsule2025.Amount or 0 end
                if capsuleAmount > 0 then pcall(function() OpenCapsuleEvent:FireServer("HalloweenCapsule2025", capsuleAmount) end) end
            end
        end
    end
end)

if isInLobby then
    task.spawn(function()
        print("=== [Breach Auto-Join] STARTING ===")
        print("[Breach Auto-Join] Initial isInLobby:", isInLobby)
        print("[Breach Auto-Join] Current PlaceId:", game.PlaceId)
        print("[Breach Auto-Join] Valid Lobby PlaceIds:", table.concat(LOBBY_PLACEIDS, ", "))
        print("[Breach Auto-Join] BreachEnabled:", getgenv().BreachEnabled)
        print("[Breach Auto-Join] BreachAutoJoin table:", game:GetService("HttpService"):JSONEncode(getgenv().BreachAutoJoin))
        print("[Breach Auto-Join] Breach automation loaded! (Will check lobby status each loop)")
        local function getAvailableBreaches()
            local ok, breaches = pcall(function()
                local lobby = workspace:FindFirstChild("Lobby")
                if not lobby then print("[Breach Auto-Join] ERROR: No Lobby found in workspace") return {} end
                local breachesFolder = lobby:FindFirstChild("Breaches")
                if not breachesFolder then print("[Breach Auto-Join] ERROR: No Breaches folder found in Lobby") return {} end
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

if isInLobby then
    task.spawn(function()
        print("[Auto Join] Auto Join system loaded!")
        while true do
            task.wait(2)
            if getgenv().AutoJoinConfig and getgenv().AutoJoinConfig.enabled then
                pcall(function()
                    local mode = getgenv().AutoJoinConfig.mode
                    local map = getgenv().AutoJoinConfig.map
                    local act = getgenv().AutoJoinConfig.act
                    local difficulty = getgenv().AutoJoinConfig.difficulty
                    if not map or map == "" then return end
                    
                    print("[Auto Join] Preparing to join " .. map .. "...")
                    cleanupBeforeTeleport()
                    
                    local teleporterRemote = RS.Remotes.Teleporter.InteractEvent
                    if mode == "Story" then
                        teleporterRemote:FireServer("Select", map, act, difficulty, "Story")
                    elseif mode == "Infinite" then
                        teleporterRemote:FireServer("Select", map, act, difficulty, "Infinite")
                    elseif mode == "Raids" then
                        teleporterRemote:FireServer("Select", map, act)
                    elseif mode == "Dungeon" then
                        teleporterRemote:FireServer("Select", map)
                    elseif mode == "Survival" then
                        teleporterRemote:FireServer("Select", map)
                    elseif mode == "ElementalCaverns" then
                        teleporterRemote:FireServer("Select", map, difficulty)
                    elseif mode == "Challenge" then
                        teleporterRemote:FireServer("Select", "Challenge", act)
                    elseif mode == "LegendaryStages" then
                        teleporterRemote:FireServer("Select", map, act, difficulty, "LegendaryStages")
                    end
                    task.wait(1)
                end)
            end
            if getgenv().AutoJoinConfig and getgenv().AutoJoinConfig.autoStart then
                pcall(function()
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
                                            if playerReady then playerReady:FireServer() end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end
    end)
end


