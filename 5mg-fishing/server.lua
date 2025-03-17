local ESX = exports['es_extended']:getSharedObject()


ESX.RegisterUsableItem('fishingrod', function(source)
    TriggerClientEvent('fishing:useOldKey', source)
end)


ESX.RegisterServerCallback('fishing:hasOldKey', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local oldKey = xPlayer.getInventoryItem('fishingrod')
    
    cb(oldKey.count > 0)
end)


ESX.RegisterServerCallback('fishing:getMarketInventory', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local items = {}
    

    for itemName, itemData in pairs(Config.MarketPrices) do
        local item = xPlayer.getInventoryItem(itemName)
        
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
    
    cb(items)
end)


RegisterNetEvent('fishing:giveReward')
AddEventHandler('fishing:giveReward', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    

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
            
           
            xPlayer.addInventoryItem(reward.item, count)
            
           
            TriggerClientEvent('esx:showNotification', source, string.format(Config.Locale.rewardReceived, count, reward.label))
            
            break
        end
    end
end)


RegisterNetEvent('fishing:sellItem')
AddEventHandler('fishing:sellItem', function(item, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    

    if not Config.MarketPrices[item] then
        TriggerClientEvent('esx:showNotification', source, Config.Locale.invalidItem)
        return
    end
    

    local playerItem = xPlayer.getInventoryItem(item)
    
    if not playerItem or playerItem.count < amount then
        TriggerClientEvent('esx:showNotification', source, Config.Locale.notEnoughItems)
        return
    end
    

    local price = Config.MarketPrices[item].price * amount
    

    xPlayer.removeInventoryItem(item, amount)
    xPlayer.addMoney(price)
    

    TriggerClientEvent('esx:showNotification', source, string.format(Config.Locale.itemSold, amount, Config.MarketPrices[item].label, price))
end)