Config = {}

-- Fishing Radius (from water)
Config.FishingRadius = 30.0 -- Player can fish within this radius of water

-- Fish Buyer NPC
Config.FishBuyer = {
    x = 3725.3372,
    y = 4525.7412,
    z = 21.4705,
    h = 177.9272
}

-- Fishing Duration (in ms)
Config.FishingDuration = 30000

-- Reset Delay after fishing (in ms)
Config.ResetDelay = 5000

-- Fish Despawn Time (in ms)
Config.FishDespawnTime = 60000

-- Rope Split Chance (percentage)
Config.RopeSplitChance = 25

-- Fish Escape Chance (percentage)
Config.FishEscapeChance = 40

-- Fish Models
Config.FishModels = {
    "a_c_fish",
    "a_c_killerwhale",
    "a_c_sharktiger",
    "a_c_stingray"
}

-- Fishing Rewards
Config.FishingRewards = {
    {item = "fish", label = "Common Fish", chance = 40, min = 1, max = 3},
    {item = "fish2", label = "Rare Fish", chance = 30, min = 1, max = 2},
    {item = "fish3", label = "Exotic Fish", chance = 20, min = 1, max = 2},
    {item = "fish4", label = "Legendary Fish", chance = 10, min = 1, max = 1}
}

-- Market Items Prices
Config.MarketPrices = {
    fish = {price = 50, label = "Common Fish"},
    fish2 = {price = 100, label = "Rare Fish"},
    fish3 = {price = 200, label = "Exotic Fish"},
    fish4 = {price = 500, label = "Legendary Fish"}
}

-- Animations
Config.Animations = {
    success = {
        dict = "anim@mp_player_intcelebrationmale@salute",
        anim = "salute"
    },
    fail = {
        dict = "anim@mp_player_intcelebrationmale@face_palm",
        anim = "face_palm"
    },
    ropeSplit = {
        dict = "anim@mp_player_intcelebrationmale@damn",
        anim = "damn"
    },
    fishEscaped = {
        dict = "anim@mp_player_intcelebrationmale@damn",
        anim = "damn"
    },
    pickup = {
        dict = "amb@medic@standing@kneel@base",
        anim = "base"
    }
}

-- Locale
Config.Locale = {
    alreadyFishing = "You are already fishing!",
    noOldKey = "You don't have an old key!",
    fishCaught = "You caught something!",
    fishingFailed = "You failed to catch anything!",
    ropeSplit = "Your fishing line snapped!",
    fishEscaped = "The fish escaped!",
    rewardReceived = "You received %d %s",
    itemSold = "You sold %d %s for $%d",
    invalidItem = "This is not a valid item to sell!",
    notEnoughItems = "You don't have enough items!",
    fishingTitle = "Premium Fishing",
    fishingDesc = "Keep the tension balanced to catch something!",
    notNearWater = "You need to be near water to fish!",
    fishPickedUp = "You picked up the fish!"
}