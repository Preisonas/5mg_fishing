local Core
CreateThread(function()
    if Config.Core == "ESX" then
        Core = exports['es_extended']:getSharedObject()

        Core.RegisterUsableItem('fishingrod', function(source)
            TriggerClientEvent('fishing:useOldKey', source)
        end)
    elseif Config.Core == "QBOX" or Config.Core == "QB" then
        Core = exports['qb-core']:GetCoreObject()

        Core.RegisterUsableItem('fishingrod', function(source)
            TriggerClientEvent('fishing:useOldKey', source)
        end)
    end
end)

RegisterCommand("testfish", function(source, args, rawCommand)
    TriggerClientEvent('fishing:useOldKey', source)
end, false)

local function GetPlayer(source)
    if Config.Core == "ESX" then
        return Core.GetPlayerFromId(source)
    elseif Config.Core == "QB" then
        return Core.Functions.GetPlayer(source)
    elseif Config.Core == "QBOX" then
        return exports.qbx_core:GetPlayer(source)
    end
end

local function GetInventoryItem(player, item)
    if Config.Inventory == "esx_inventory" then
        return player.getInventoryItem(item)
    elseif Config.Inventory == "qb-inventory" then
        return player.Functions.GetItemByName(item)
    elseif Config.Inventory == "ox_inventory" then
        return exports.ox_inventory:GetItem(source, item, nil, false)
    end
end

local function AddInventoryItem(player, item, amount)
    if Config.Inventory == "esx_inventory" then
        player.addInventoryItem(item, amount)
    elseif Config.Inventory == "qb-inventory" then
        player.Functions.AddItem(item, amount)
    elseif Config.Inventory == "ox_inventory" then
        exports.ox_inventory:AddItem(source, item, amount)
    end
end

local function RemoveInventoryItem(player, item, amount)
    if Config.Inventory == "esx_inventory" then
        player.removeInventoryItem(item, amount)
    elseif Config.Inventory == "qb-inventory" then
        player.Functions.RemoveItem(item, amount)
    elseif Config.Inventory == "ox_inventory" then
        exports.ox_inventory:RemoveItem(source, item, amount)
    end
end

local function AddMoney(player, amount)
    if Config.Core == "ESX" then
        player.addMoney(amount)
    else
        player.Functions.AddMoney("cash", amount)
    end
end


lib.callback.register('fishing:hasOldKey', function(source)
    local player = GetPlayer(source)
    local item = GetInventoryItem(player, 'fishingrod')  -- Make sure to specify the item name
    for k,v in pairs(item) do
        print(k,v)
    end
    if item.count >= 1 then
        return true
    else
        return false
    end
end)


lib.callback.register('fishing:getMarketInventory', function(source)
    local player = GetPlayer(source)
    local items = {}
    
    for itemName, itemData in pairs(Config.MarketPrices) do
        local item = GetInventoryItem(player, itemName)
        if item and item.count > 0 then
            table.insert(items, {
                name = itemName,
                label = itemData.label,
                count = item.count,
                price = itemData.price,
                type = 'fish'
            })
        end
    end
    return items
end)

RegisterNetEvent('fishing:giveReward', function()
    local player = GetPlayer(source)
    local totalChance = 0
    for _, reward in pairs(Config.FishingRewards) do
        totalChance = totalChance + reward.chance
    end
    
    local randomNum = math.random(totalChance)
    local currentChance = 0
    
    for _, reward in pairs(Config.FishingRewards) do
        currentChance = currentChance + reward.chance
        if randomNum <= currentChance then
            local count = math.random(reward.min, reward.max)
            AddInventoryItem(player, reward.item, count)
            TriggerClientEvent('ox_lib:notify', source, {type = 'success', description = string.format(Config.Locale.rewardReceived, count, reward.label)})
            break
        end
    end
end)

RegisterNetEvent('fishing:sellItem', function(item, amount)
    local player = GetPlayer(source)
    if not Config.MarketPrices[item] then
        TriggerClientEvent('ox_lib:notify', source, {type = 'error', description = Config.Locale.invalidItem})
        return
    end
    
    local playerItem = GetInventoryItem(player, item)
    if not playerItem or playerItem.count < amount then
        TriggerClientEvent('ox_lib:notify', source, {type = 'error', description = Config.Locale.notEnoughItems})
        return
    end
    
    local price = Config.MarketPrices[item].price * amount
    RemoveInventoryItem(player, item, amount)
    AddMoney(player, price)
    
    TriggerClientEvent('ox_lib:notify', source, {type = 'success', description = string.format(Config.Locale.itemSold, amount, Config.MarketPrices[item].label, price)})
end)
