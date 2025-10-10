repeat task.wait() until game:IsLoaded()

-- Priority list (lower number = higher priority)
local cardPriority = {
    -- Candy Cards
    ["Weakened Resolve I"] = 13, -- Candy Basket bonus: +15 Candy Baskets gained per wave, Boss Damage Reduction: Damage dealt to bosses is reduced by 5%
    ["Weakened Resolve II"] = 11, -- Candy Basket bonus: +25 Candy Baskets gained per wave, Boss Damage Reduction+: Damage dealt to bosses is reduced by 10%
    ["Weakened Resolve III"] = 4, -- Candy Basket bonus: +50 Candy Baskets gained per wave, Boss Damage Reduction++: Damage dealt to bosses is reduced by 15%
    ["Fog of War I"] = 12, -- Candy Basket Bonus: +15 Candy Baskets gained per wave, Range Reduction: The range of all units is reduced by 5%
    ["Fog of War II"] = 10, -- Candy Basket Bonus: +25 Candy Baskets gained per wave, Range Reduction+: The range of all units is reduced by 15%
    ["Fog of War III"] = 5, -- Candy Basket Bonus: +50 Candy Baskets gained per wave, Range Reduction+: The range of all units is reduced by 30%
    ["Lingering Fear I"] = 6, -- Candy Basket Bonus: +1 Candy Baskets gained per kill Attack Speed Reduction+: Attack speed of all units is reduced by 10%
    ["Lingering Fear II"] = 2, -- Candy Basket Bonus: +2 Candy Baskets gained per kill Attack Speed Reduction+: Attack speed of all units is reduced by 20%
    ["Power Reversal I"] = 14, -- Candy Basket Bonus: +15 Candy Baskets gained per Wave, Buff Effectiveness Reduction: All buffs are 50% less effective
    ["Power Reversal II"] = 9, -- Candy Basket Bonus: +25 Candy Baskets gained per Wave, Buff Effectiveness Reduction: All buffs are 100% less effective
    ["Greedy Vampire's"] = 8, -- Candy Basket Bonus: +25 Candy Baskets gained per wave, Cash Theft: Enemies steal 50% of your total cash when you lose a stock
    ["Hellish Gravity"] = 3, -- Candy Basket Bonus: +2 Candy Baskets gained per kill, AOE Damage Penalty: Full AOE units deal 25% less damage
    ["Deadly Striker"] = 7, -- Candy Basket Bonus: +1 Candy Basket gained per kill, Double Stock Damage: Enemies deal Double Stock Damage
    ["Critical Denial"] = 1, -- Candy Basket Bonus: +100 Candy Baskets gained per wave, No Crits: Critical hits are disabled
    ["Trick or Treat Coin Flip"] = 15, -- Treat: (+5000 Candy Baskets, +15% Damage), Trick:  Tricket (-10% Damage, Spawn Dracula's Army)
    -- Candy Cards but if you pick this you just weird
    ["Devil's Sacrifice"] = 999, -- Candy Basket Bonus: +25 Candy Baskets gained per wave No Abilities: Abilities may never be used


    -- Non Candy Cards
    ["Bullet Breaker I"] = 999, -- Armor Piercing: Attacks ignore +10% Damage Reduction
    ["Bullet Breaker II"] = 999, -- Armor Piercing: Attacks ignore +20% Damage Reduction
    ["Bullet Breaker III"] = 999, -- Armor Piercing: Attacks ignore +30% Damage Reduction
    ["Hell Merchant I"] = 999, -- Farm Range Aura: All allies within your Farm Units range receive 3% Range
    ["Hell Merchant II"] = 999, -- Farm Range Aura+: All allies within your Farm Units range receive 6% Range
    ["Hell Merchant III"] = 999, -- Farm Range Aura++: All allies within your Farm Units range receive 9% Range
    ["Hellish Warp I"] = 999, -- Cooldown Reduction: Reduces ability cooldowns by 15%
    ["Hellish Warp II"] = 999, -- Cooldown Reduction+: Reduces ability cooldowns by 30%
    ["Fiery Surge I"] = 999, -- Elemental Dominance: Units gain 100% Damage against enemies weaker to their element
    ["Fiery Surge II"] = 999, -- Elemental Dominance+: Units gain 200% Damage against enemies weaker to their element
    ["Grevious Wounds I"] = 999, -- Crit Chance+: +5% Crit Chance, Crit Damage+: +10 Crit Damage
    ["Grevious Wounds II"] = 999, -- Crit Chance+: +10% Crit Chance, Crit Damage+: +20 Crit Damage
    ["Scorching Hell I"] = 999, -- Attack Speed Surge: +25% Attack Speed to all units for 10 seconds after placing a unit
    ["Scorching Hell II"] = 999, -- Attack Speed Surge+: +50% Attack Speed to all units for 10 seconds after placing a unit
    ["Fortune Flow"] = 999, -- Cash Flow: +200% Cash from enemies defeated (Does not work for farms)
    ["Soul Link"] = 999, -- Boss Slayer Boost: When a boss is defeated, nearby units gain +20% Damage for 80 seconds
}

local function getAvailableCards()
    local playerGui = game:GetService("Players").LocalPlayer.PlayerGui
    local prompt = playerGui:FindFirstChild("Prompt")
    
    if not prompt then
        return nil
    end
    
    local frame = prompt:FindFirstChild("Frame")
    if not frame or not frame:FindFirstChild("Frame") then
        return nil
    end
    
    local cards = {}
    local cardButtons = {}
    
    for _, descendant in pairs(frame:GetDescendants()) do
        if descendant:IsA("TextLabel") and descendant.Parent and descendant.Parent:IsA("Frame") then
            local text = descendant.Text
            if cardPriority[text] then
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
        local priority = cardPriority[cardName] or 999
        print("Card " .. cardIndex .. ": " .. cardName .. " (Priority: " .. priority .. ")")
        if priority < bestPriority then
            bestPriority = priority
            bestIndex = cardIndex
        end
    end
    
    return bestIndex, availableCards[bestIndex], bestPriority
end

local function pressConfirmButton()
    local playerGui = game:GetService("Players").LocalPlayer.PlayerGui
    
    local ok, confirmButton = pcall(function()
        local prompt = playerGui:FindFirstChild("Prompt")
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
        print("Pressing Confirm button...")
        
        local events = {"Activated", "MouseButton1Click", "MouseButton1Down", "MouseButton1Up"}
        for _, eventName in ipairs(events) do
            pcall(function()
                for _, conn in ipairs(getconnections(confirmButton[eventName])) do
                    conn:Fire()
                end
            end)
        end
        
        print("Confirm button pressed!")
        return true
    end
    
    return false
end

local function selectCard()
    local availableCards = getAvailableCards()
    
    if not availableCards then
        return false
    end
    
    print("=== Card Selection ===")
    print("Total cards found: " .. #availableCards)
    local bestCardIndex, bestCardData, bestPriority = findBestCard(availableCards)
    
    print(">>> Best choice: Card " .. bestCardIndex .. " - " .. (bestCardData.name or "Unknown") .. " (Priority: " .. bestPriority .. ")")
    
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
    
    print("Card selected and confirmed successfully!")
    return true
end

print("Card selection script running...")
while true do
    local success = selectCard()
    if success then
        print("Card selected successfully")
    end
    wait(1) 
end
