local modimport = modimport
local GetModConfigData = GetModConfigData
local IAENV = env
GLOBAL.IAENV = env
GLOBAL.setfenv(1, GLOBAL)

IA_ENABLED = rawget(_G, "IA_CONFIG") ~= nil
IA_CONFIG = rawget(_G, "IA_CONFIG") or {
    droplootground = true
}

PL_CONFIG = {
    -- Some of these may be treated as client-side, as indicated by the bool
    locale = GetModConfigData("locale", true),
}

-- TODO: Should prob be somewhere else
IAENV.AddSimPostInit(function()
    local Initialize = require("interior_defs/dimension_defs").Initialize
    Initialize()
end)

modimport("main/tuning")
modimport("main/constants")

modimport("main/pl_util")
modimport("main/util")
modimport("main/houseutil")
modimport("main/commands")
modimport("main/standardcomponents")

modimport("main/assets")
modimport("main/fx")
modimport("main/shadeeffects")
modimport("main/strings")

modimport("main/pl_worldsettings_overrides")
modimport("main/RPC")
modimport("main/actions")
modimport("main/postinit")

modimport("libraries/luaminimap")
modimport("libraries/lualighting")

------------------------------ HAM Replicatable Components ------------------------------------------------------------

AddReplicableComponent("interiorplayer")

------------------------------ Replicatable Components ---------------------------------------
