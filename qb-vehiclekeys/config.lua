Config = {}

-- Key System Settings
Config.PersistentKeys = true -- Whether keys received should be saved after server restart, or not

-- Vehicle lock settings
Config.LockToggleAnimation = {
    AnimDict = 'anim@mp_player_intmenu@key_fob@',
    Anim = 'fob_click',
    Prop = 'prop_cuff_keys_01',
    PropBone = 57005,
    WaitTime = 500,
}
Config.LockAnimSound = "keys"
Config.LockToggleSound = "lock"
Config.LockToggleDist = 8.0

-- NPC Vehicle Lock States
Config.LockNPCDrivingCars = true -- Lock state for NPC cars being driven by NPCs [true = locked, false = unlocked]
Config.LockNPCParkedCars = true -- Lock state for NPC parked cars [true = locked, false = unlocked]
Config.UseKeyfob = false -- you can set this true if you dont need ui
-- Lockpick Settings
Config.RemoveLockpickNormal = 0.5 -- Chance to remove lockpick on fail
Config.RemoveLockpickAdvanced = 0.2 -- Chance to remove advanced lockpick on fail
-- Carjack Settings
Config.CarJackEnable = true -- True allows for the ability to car jack peds.
Config.CarjackingTime = 7500 -- How long it takes to carjack
Config.DelayBetweenCarjackings = 10000 -- Time before you can carjack again
Config.CarjackChance = {
    ['2685387236'] = 0.0, -- melee
    ['416676503'] = 0.5, -- handguns
    ['-957766203'] = 0.75, -- SMG
    ['860033945'] = 0.90, -- shotgun
    ['970310034'] = 0.90, -- assault
    ['1159398588'] = 0.99, -- LMG
    ['3082541095'] = 0.99, -- sniper
    ['2725924767'] = 0.99, -- heavy
    ['1548507267'] = 0.0, -- throwable
    ['4257178988'] = 0.0, -- misc
}

-- Hotwire Settings
Config.HotwireChance = 0.5 -- Chance for successful hotwire or not
Config.TimeBetweenHotwires = 5000 -- Time in ms between hotwire attempts
Config.minHotwireTime = 20000 -- Minimum hotwire time in ms
Config.maxHotwireTime = 40000 --  Maximum hotwire time in ms

-- Police Alert Settings
Config.AlertCooldown = 10000 -- 10 seconds
Config.PoliceAlertChance = 0.75 -- Chance of alerting police during the day
Config.PoliceNightAlertChance = 0.50 -- Chance of alerting police at night (times:01-06)

-- Job Settings
Config.SharedKeys = { -- Share keys amongst employees. Employees can lock/unlock any job-listed vehicle
    ['police'] = { -- Job name
        requireOnduty = false,
        vehicles = {
	    'police', -- Vehicle model
	    'police2', -- Vehicle model
	}
    },

    ['mechanic'] = {
        requireOnduty = false,
        vehicles = {
            'towtruck',
	}
    }
}

-- These vehicles cannot be jacked
Config.ImmuneVehicles = {
    'stockade'
}

-- These vehicles will never lock
Config.NoLockVehicles = {}

-- These weapons cannot be used for carjacking
Config.NoCarjackWeapons = {
    "WEAPON_UNARMED",
    "WEAPON_Knife",
    "WEAPON_Nightstick",
    "WEAPON_HAMMER",
    "WEAPON_Bat",
    "WEAPON_Crowbar",
    "WEAPON_Golfclub",
    "WEAPON_Bottle",
    "WEAPON_Dagger",
    "WEAPON_Hatchet",
    "WEAPON_KnuckleDuster",
    "WEAPON_Machete",
    "WEAPON_Flashlight",
    "WEAPON_SwitchBlade",
    "WEAPON_Poolcue",
    "WEAPON_Wrench",
    "WEAPON_Battleaxe",
    "WEAPON_Grenade",
    "WEAPON_StickyBomb",
    "WEAPON_ProximityMine",
    "WEAPON_BZGas",
    "WEAPON_Molotov",
    "WEAPON_FireExtinguisher",
    "WEAPON_PetrolCan",
    "WEAPON_Flare",
    "WEAPON_Ball",
    "WEAPON_Snowball",
    "WEAPON_SmokeGrenade",
}

Config.Locksmith = {
    Cost = 500, -- Anahtar başına ücret
    NPCModel = 's_m_y_construct_01', -- Çilingir NPC modeli
    Locations = {
        { -- Konum 1: Los Santos Downtown
            coords = vector3(-829.07, -1226.24, 6.93),
            heading = 53.79,
            blip = { enabled = true, sprite = 186, color = 2, name = 'Çilingir' }
        },
        { -- Konum 2: Sandy Shores
            coords = vector3(307.0, -272.12, 53.95),
            heading = 340.73,
            blip = { enabled = true, sprite = 186, color = 2, name = 'Çilingir' }
        },
        { -- Konum 3: Paleto Bay
            coords = vector3(384.02, -1025.48, 29.49),
            heading = 224.96,
            blip = { enabled = true, sprite = 186, color = 2, name = 'Çilingir' }
        }
    }
}