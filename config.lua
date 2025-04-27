Config = {}

Config.Debug = false

Config.Target = 'qb' -- Options: 'qb' for qb-target or 'ox' for ox_target

Config.RepairLocation = vector3(823.19, -2997.61, 6.02)

Config.RepairTimes = {
    pistol = 60,
    smg = 120,
    rifle = 180,
}

Config.RepairCosts = {
    pistol = 1500,
    smg = 2500,
    rifle = 3500
}

Config.RequiredItems = {
    pistol = {
        {
            item = "pistol_mag",
            amount = 1
        },
        {
            item = "pistol_suppressor",
            amount = 1
        }
    },
    smg = {
        {
            item = "cryptostick",
            amount = 2
        },
        {
            item = "smg_mag",
            amount = 1
        },
        {
            item = "smg_suppressor",
            amount = 1
        }
    },
    rifle = {
        {
            item = "cryptostick",
            amount = 3
        },
        {
            item = "rifle_mag",
            amount = 1
        },
        {
            item = "rifle_suppressor",
            amount = 1
        }
    }
}

Config.WeaponClasses = {
    pistol = {
        'WEAPON_PISTOL',
        'WEAPON_PISTOL50',
        'WEAPON_SNSPISTOL',
    },
    smg = {
        'WEAPON_SMG',
        'WEAPON_MICROSMG',
    },
    rifle = {
        'WEAPON_CARBINERIFLE',
        'WEAPON_ASSAULTRIFLE',
    }
} 