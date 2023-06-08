local TheNet = GLOBAL.TheNet

PrefabFiles = {
    "aporkalypse_clock",
    "asparagus",
    "chitin",
    "deep_jungle_fern_noise",
    "flower_rainforest",
    "glowfly",
    "grass_tall",
    "pl_wave_shore",
    "jungle_border_vine",
    "machete",
    "peagawk",
    "peagawk_spawner",
    "peagawkfeather",
    "poisonbubble",
    "porkland_network",
    "rabid_beetle",
    "porkland",
    "shears",
    "tree_pillar",
    -- "tuber",
    -- "tubertrees",
    "weevole_carapace",
    "weevole",

    -- house prefabs
    "interior_physics",
	"interior_visual",

    -- debug
    "debug_door",
}

Assets = {
    -- minimap
    Asset("IMAGE", "images/minimap/pl_minimap.tex"),
    Asset("ATLAS", "images/minimap/pl_minimap.xml"),

    -- inventoryimages
    Asset("IMAGE", "images/pl_inventoryimages.tex"),
    Asset("ATLAS", "images/pl_inventoryimages.xml"),
    Asset("ATLAS_BUILD", "images/pl_inventoryimages.xml", 256),  -- for minisign

    -- hud
    Asset("ATLAS", "images/overlays/fx3.xml"),  -- poison
    Asset("IMAGE", "images/overlays/fx3.tex"),
    Asset("ATLAS", "images/overlays/fx5.xml"),  -- fog
    Asset("IMAGE", "images/overlays/fx5.tex"),
    Asset("ANIM", "anim/moon_aporkalypse_phases.zip"),  -- blood moon

    -- player_actions
    Asset("ANIM", "anim/player_idles_poison.zip"),
    Asset("ANIM", "anim/player_mount_idles_poison.zip"),
    Asset("ANIM", "anim/player_actions_hack.zip"),
    Asset("ANIM", "anim/player_actions_shear.zip"),

    -- house Assets
    --Asset("SHADER", "shaders/billboard.ksh"),
	Asset("SHADER", "shaders/interior.ksh"),
	Asset("SHADER", "shaders/map_interior.ksh"),
	Asset("IMAGE", "levels/textures/interiors/sourceerror.tex"),
	Asset("IMAGE", "levels/textures/interiors/antcave_floor.tex"),
	Asset("IMAGE", "levels/textures/interiors/antcave_wall_rock.tex"),
	Asset("IMAGE", "levels/textures/interiors/floor_marble_royal.tex"),
	Asset("IMAGE", "levels/textures/interiors/wall_royal_high.tex"),
	Asset("IMAGE", "images/colour_cubes/pigshop_interior_cc.tex"),

	Asset("ATLAS", "levels/textures/map_interior/mini_ruins_slab.xml"),
	Asset("IMAGE", "levels/textures/map_interior/mini_ruins_slab.tex"),
	Asset("ATLAS", "levels/textures/map_interior/frame.xml"),
	Asset("IMAGE", "levels/textures/map_interior/frame.tex"),

	Asset("ATLAS", "levels/textures/map_interior/exit.xml"),
	Asset("IMAGE", "levels/textures/map_interior/exit.tex"),

	Asset("ATLAS", "levels/textures/map_interior/passage.xml"),
	Asset("IMAGE", "levels/textures/map_interior/passage.tex"),
	Asset("ATLAS", "levels/textures/map_interior/passage_blocked.xml"),
	Asset("IMAGE", "levels/textures/map_interior/passage_blocked.tex"),
	Asset("ATLAS", "levels/textures/map_interior/passage_unknown.xml"),
	Asset("IMAGE", "levels/textures/map_interior/passage_unknown.tex"),
}

Pl_Util.RegisterInventoryItemAtlas("images/pl_inventoryimages.xml")
AddMinimapAtlas("images/minimap/pl_minimap.xml")

if not TheNet:IsDedicated() then
    -- table.insert(Assets, Asset("SOUND", "sound/"))
end
