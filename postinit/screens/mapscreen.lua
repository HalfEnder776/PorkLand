IAENV = env
GLOBAL.setfenv(1, GLOBAL)

local MapScreen = require("screens/mapscreen")
local InteriorMapWidget = require("widgets/interiormapwidget")

local _AddChild = MapScreen.AddChild
function MapScreen:AddChild(child, ...)
	if child and child.name == "MapWidget" and (self.owner ~= nil and self.owner.replica.interiorplayer ~= nil and self.owner.replica.interiorplayer:InInterior() ~= nil) then
		self.owner.player_classified.MapExplorer:RecordInteriorMapData()
		child:Kill()
		child = InteriorMapWidget(self.owner)
	end
	return _AddChild(self, child, ...)
end