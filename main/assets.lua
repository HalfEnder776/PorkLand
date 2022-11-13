local resolvefilepath = GLOBAL.resolvefilepath
local TheNet = GLOBAL.TheNet

PrefabFiles = {
    "grass_tall",
    "machete",
    "peagawk_spawner",
	"peagawk",
	"peagawkfeather",
	"shears",
    "weevole_carapace",
    "weevole"
}

local AddInventoryItemAtlas = gemrun("tools/misc").Local.AddInventoryItemAtlas
AddInventoryItemAtlas(resolvefilepath("images/pl_inventoryimages.xml"))

Assets = {
	Asset("IMAGE", "images/pl_inventoryimages.tex"),
    Asset("ATLAS", "images/pl_inventoryimages.xml"),
	Asset("ATLAS_BUILD", "images/pl_inventoryimages.xml", 256),  --For minisign

	Asset("ANIM", "anim/player_actions_shear.zip"),
}

AddMinimapAtlas("images/minimap/pl_minimap.xml")

if not TheNet:IsDedicated() then
	-- table.insert(Assets, Asset("SOUND", "sound/"))
end
