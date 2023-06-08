GLOBAL.setfenv(1, GLOBAL)

------------------House Patches-------------
local ValidInteriorSpace = ValidInteriorSpace
local TILE_SCALE = TILE_SCALE

local _GetTile = Map.GetTile
function Map:GetTile(tilex, tiley, ...)
	local w, h = self:GetSize()
	local x, y, z = (tilex - w/2.0)*TILE_SCALE, 0, (tiley - h/2.0)*TILE_SCALE
	if ValidInteriorSpace(x,y,z) then
		return WORLD_TILES.INTERIOR
	end
	
    return _GetTile(self, tilex, tiley, ...)
end

local _GetTileAtPoint = Map.GetTileAtPoint
function Map:GetTileAtPoint(x, y, z, ...)
	if ValidInteriorSpace(x,y,z) then
		return WORLD_TILES.INTERIOR
	end
	
    return _GetTileAtPoint(self, x, y, z, ...)
end

local _IsVisualGroundAtPoint = Map.IsVisualGroundAtPoint
function Map:IsVisualGroundAtPoint(x, y, z, ...)
	if ValidInteriorSpace(x,y,z) then
		return true
	end
	
    return _IsVisualGroundAtPoint(self, x, y, z, ...)
end
--(H): GetTileCenterPoint breaks outside of the map in vanilla engine so, heres a fix
local _GetTileCenterPoint = Map.GetTileCenterPoint
function Map:GetTileCenterPoint(x, y, z, ...)
	if z ~= nil then
		if x > 1900 then return math.floor(x/TILE_SCALE)*TILE_SCALE + 2, 0, math.floor(z/TILE_SCALE)*TILE_SCALE + 2 end
		
    	return _GetTileCenterPoint(self, x, y, z, ...)
	else
		if x > 1900 then return math.floor(x/TILE_SCALE)*TILE_SCALE + 2, 0, math.floor(y/TILE_SCALE)*TILE_SCALE + 2 end
		
    	return _GetTileCenterPoint(self, x, y, ...)
	end
end
--------------------------------------------