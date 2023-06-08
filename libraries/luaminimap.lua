GLOBAL.setfenv(1, GLOBAL)

local session = TheNet:GetSessionIdentifier()

--

local MINIMAP_TO_DATA = {} --[inst.MiniMapEntity] = {inst = inst, icon = icon, priority = priority}
local MAPEXPLORER_TO_DATA = {} --[inst.MapExplorer] = {inst = inst, intmapdata = {}}

--

local _AddMiniMapEntity = Entity.AddMiniMapEntity
function Entity:AddMiniMapEntity(...)
	local guid = self:GetGUID()
	local inst = Ents[guid]
	local hasMiniMapEntity = inst.MiniMapEntity
	local minimapentity = _AddMiniMapEntity(self, ...)

	if inst and not hasMiniMapEntity then
		MINIMAP_TO_DATA[minimapentity] = {inst = inst, priority = 0}
	end

	return minimapentity
end

local _AddMapExplorer = Entity.AddMapExplorer
function Entity:AddMapExplorer(...)
	local guid = self:GetGUID()
	local inst = Ents[guid]
	local hasMapExplorer = inst.MapExplorer
	local mapexplorer = _AddMapExplorer(self, ...)

	if inst and not hasMapExplorer then
		MAPEXPLORER_TO_DATA[mapexplorer] = {inst = inst, intmapdata = {}}
	end

	return hasMapExplorer
end

--TODO (H): These must be networked if called on the server, add a flag to allow networking after SetPristine is called on master.
local _SetIcon = MiniMapEntity.SetIcon
function MiniMapEntity:SetIcon(icon, ...)
    MINIMAP_TO_DATA[self].icon = icon
    _SetIcon(self, icon, ...)
end

local _SetPriority = MiniMapEntity.SetPriority
function MiniMapEntity:SetPriority(priority, ...)
    MINIMAP_TO_DATA[self].priority = priority
    _SetPriority(self, priority, ...)
end

function MiniMapEntity:GetIcon()
	return MINIMAP_TO_DATA[self].icon or "NO_ICON"
end

function MiniMapEntity:GetPriority()
	return MINIMAP_TO_DATA[self].priority or 0
end

function MiniMapEntity:OnDestroyLuaMinimap()
	MINIMAP_TO_DATA[self] = nil
	--TODO(H): might need to add something here in the future
end
--todo(H): there has to be support for recording interiors we CANT see, passed from server to client, for stuff lik ocuvigils
--also we only update when we first open the map/leaving/entering interiors, we should also update while on the screen like game does with vanilla map
--might need to rework how interiormapwidget is constructed to make for an optimized moving of objects when updating
function MapExplorer:RecordInteriorMapData()
	--[[
	(H): When called record map data of current interior and store for map widget to use
	--should be called on client ONLY
	]]
	local inst = MAPEXPLORER_TO_DATA[self].inst
	local interior = inst.interior_visual:value()
	if not interior then print("Tried to record interior map data but we aren't even in one!") return end
	if not MAPEXPLORER_TO_DATA[self].intmapdata[interior.roomgroup:value()] then MAPEXPLORER_TO_DATA[self].intmapdata[interior.roomgroup:value()] = {} end

	--clear past tables oops, clean this code up
	for k, v in pairs(MAPEXPLORER_TO_DATA[self].intmapdata[interior.roomgroup:value()]) do
		if v.pos.x == interior.roomposx:value() and v.pos.y == interior.roomposy:value() then
			table.remove(MAPEXPLORER_TO_DATA[self].intmapdata[interior.roomgroup:value()], k)
		end
	end

	local length, width = interior.roomlength:value(), interior.roomwidth:value()
	local botleftpos = interior:GetPosition() + Vector3(width/2, 0, -length/2)
	local objects = {}
	
	for k, v in pairs(interior:GetInteriorEntities()) do
		if v and v.MiniMapEntity and v:IsValid() then
			--determine x and y
			local x, y, z = v.Transform:GetWorldPosition()
			local percy, percx = math.abs(botleftpos.x- x) / width, math.abs(botleftpos.z - z) / length
			--TODO JUST FOR TESTING
			local direction
			if v:HasTag("door_north") then
				direction = "north"
			elseif v:HasTag("door_south") then
				direction = "south"
			elseif v:HasTag("door_west") then
				direction = "west"
			elseif v:HasTag("door_east") then
				direction = "east"
			end
			table.insert(objects, {
				name = v.MiniMapEntity:GetIcon(),
				priority = v.MiniMapEntity:GetPriority(),
				x = percx,
				y = percy,
				doordirection = direction, --TODO, JUST FOR TESTING
			})
		end
	end

	table.insert(MAPEXPLORER_TO_DATA[self].intmapdata[interior.roomgroup:value()], {
		name = "mini_ruins_slab", --TODO
		id = interior.roomid:value(),
		length = length,
		width = width,
		--occupied = false,
		pos = {x = interior.roomposx:value(), y = interior.roomposy:value()},
		objects = objects,
	})
	--[[
		objects = {
			{
				--x and y are percents of the rooms width and length
				name = "researchlab2.png",
				x = .2,
				y = .5,
			},
		}
	]]
end

function MapExplorer:GetInteriorMapData()
	return MAPEXPLORER_TO_DATA[self].intmapdata
end

--[[
function MapExplorer:SaveInteriorMapToPersistentString()
	local str = json.encode({mapdata = MAPEXPLORER_TO_DATA[self].intmapdata})
    TheSim:SetPersistentString("interiormapdata", str, false)
end

function MapExplorer:LoadInteriorMapFromPersistentString()
	TheSim:GetPersistentString("interiormapdata", function(load_success, data) 
        if load_success and data ~= nil then
            local status, invdata = pcall( function() return json.decode(data) end )
            if status and invdata then
                MAPEXPLORER_TO_DATA[self].intmapdata = invdata.mapdata or {}
            else
                print("Failed to load Interior Map Data!", status, invdata)
            end
        end
    end)
end
]]

--Misc

local miniMapIconAtlasLookup = {} --e.g. ["pond.png"] = "images/minimap_atlas.xml"
local minimap_atlases = {} --e.g. [1] = "images/atlas.xml"
local _AddAtlas = MiniMap.AddAtlas

function MiniMap:AddAtlas(atlas, ...)
	if not table.contains(minimap_atlases, atlas) then table.insert(minimap_atlases, atlas) end
	return _AddAtlas(self, atlas, ...)
end

function GetMiniMapIconAtlas(imagename)
	local atlas = miniMapIconAtlasLookup[imagename]
	if atlas then
		return atlas
	end

	for i, v in pairs(minimap_atlases) do
    	atlas = TheSim:AtlasContains(v, imagename) and v
		if atlas ~= nil then
			miniMapIconAtlasLookup[imagename] = atlas
			break
		end
	end

	return atlas
end