--[[
notes:
interiors in hamlet are a size of 15x10 units(usually 1:1.5 ratio, but ROOM_LARGE said fuck you and gave 1:1.444 ratio

ROOM_TINY_WIDTH   = 15,
		ROOM_TINY_DEPTH   = 10,

		ROOM_SMALL_WIDTH  = 18,
		ROOM_SMALL_DEPTH  = 12,

		ROOM_MEDIUM_WIDTH = 24,
		ROOM_MEDIUM_DEPTH = 16,

		ROOM_LARGE_WIDTH  = 26,
		ROOM_LARGE_DEPTH  = 18,

(H): this is a fragile shell of interiors, but it's enough of a layout that you guys are smart enough to complete it(there's probably some things I might still have to do, but otherwise, ik youre clever enough, Half)

TODO:
Minimap Logic
Room Generation + the whole housing renovation stuff
Followers need to teleport
Interior textures only support 512x512 textures(Hamlet will use some of the original tile types like wooden flooring which is 1024x1024)

me(H) things:
some AnimStates will need to be rotated billboards, like in Hamlet. A default shader can probably do this task.
Whatever other shader stuff needs to be done for the interiors
]]

--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------

--------------------------------------------------------------------------
--[[ InteriorManager class definition ]]
--------------------------------------------------------------------------
return Class(function(self, inst)

assert(TheWorld.ismastersim, "InteriorManager should not exist on client")

--------------------------------------------------------------------------
--[[ Private constants ]]
--------------------------------------------------------------------------

--TODO, scale with world size. for now, 2048x2048 world makers will be eating L's
local interior_spawn_origin = Vector3(2000,0,0)
local interior_storage_origin = Vector3(0, 0, 2000) --welcome to the dumping facility

--At most *possible* max, there can be 64 active interiors at a time as there can be 64 max players in a shard. We are unlikely to push to even a quarter of this limit in normal play however.
local _space_between_interiors = TUNING.MAX_INTERIOR_SIZE

--------------------------------------------------------------------------
--[[ Public Member Variables ]]
--------------------------------------------------------------------------

self.inst = inst

--------------------------------------------------------------------------
--[[ Private Member Variables ]]
--------------------------------------------------------------------------

local _world = TheWorld
local _map = _world.Map

local taken_positions = {} --[pos] = true
local pathfindingBarriers = {} --[pos] = {positions}

local interiors = {} --[id] = data
local active_interiors = {} --[id] = interiors[id]
local cached_player_interiors = {} --[userid] = interior_id
local interior_room_positions = {} --[interior_group] = {[x][y] = interior_id}, same interior can be set to multiple positions, def or id?
local next_interior_ID = 0

--------------------------------------------------------------------------
--[[ Private Member functions ]]
--------------------------------------------------------------------------

local function ConfigureInteriorVisualAndPhysics(active_interior)
	local visual = SpawnPrefab("interior_visual")
	
	visual.Transform:SetPositionIgnoringInterior(active_interior.world_position:Get())

	visual.floortexture:set(active_interior.floortexture)
	visual.walltexture:set(active_interior.walltexture)

    visual.walltexturedimensions:set(active_interior.walltexturedimensions)
	
	visual.roomheight:set(active_interior.height)
	visual.roomlength:set(active_interior.length)
	visual.roomwidth:set(active_interior.width)

	visual.roomreverb:set(active_interior.reverb)
	visual.roomcolourcube:set(active_interior.cc)
	visual.roomgroup:set(active_interior.interior_group or "")
	visual.roomid:set(active_interior.interior_id)

	visual.roomposx:set(active_interior.pos.x)
	visual.roomposy:set(active_interior.pos.y)
	
	visual.emit:push()
	--
	local physics = SpawnPrefab("interior_physics")
	physics.Transform:SetPositionIgnoringInterior(active_interior.world_position:Get())
	physics:SetRectangle(active_interior.length, active_interior.width)
	--
	active_interior.visual = visual
	active_interior.physics = physics
end

local function ClearInteriorVisualAndPhysics(active_interior)
	active_interior.visual:Remove()
	active_interior.visual = nil

	active_interior.physics:Remove()
	active_interior.physics = nil
end

local function SetUpPathFindingBarriers(interior, length, width)
	local x, y, z = interior.world_position:Get()
	pathfindingBarriers[interior.world_position] = {}

	for r = -length/2, length/2 do
		table.insert(pathfindingBarriers[interior.world_position], Vector3(x+(width/2)+0.5, y, z+r))
		table.insert(pathfindingBarriers[interior.world_position], Vector3(x-(width/2)-0.5, y, z+r))
	end
	for r = -width/2, width/2 do
		table.insert(pathfindingBarriers[interior.world_position], Vector3(x+r,y,z-(length / 2)-0.5))
		table.insert(pathfindingBarriers[interior.world_position], Vector3(x+r,y,z+(length / 2)+0.5))
	end

	for i,pt in pairs(pathfindingBarriers[interior.world_position]) do
		self.inst.Pathfinder:AddWall(pt.x, pt.y, pt.z)
	end
end

local function ClearPathfindingBarriers(interior)
	for i,pt in pairs(pathfindingBarriers[interior.world_position]) do
		self.inst.Pathfinder:RemoveWall(pt.x, pt.y, pt.z)
	end
	pathfindingBarriers[interior.world_position] = nil
end

local function SpawnProp(prefab, interior)
	local ent = SpawnPrefab(prefab.name)

	ent.Transform:SetPositionIgnoringInterior((interior.world_position + (prefab.pos_offset or Vector3(0,0,0))):Get())
	ent.Transform:SetRotation(prefab.rotation or 0)
	
	for _, tag in pairs(prefab.addtags or {}) do
		ent:AddTag(tag)
	end
	
	return ent
end

local function SpawnPendingProps(interior)
	--Spawn our pending props once, these will now be in object_list
	print("Spawning our pending props for "..interior.interior_id)
	
	for i, prefab in pairs(interior.pending_props) do
		local prop = SpawnProp(prefab, interior)
		interior.object_list[prop] = true
	end
	
	--Hornet: Done spawning, goodbye props
	interior.pending_props = nil
end

local function ChuckObjectIntoLimbo(obj, interior)
	if not obj.persists then
		--This object isn't meant to persist anyways, chuck it out
		obj:Remove()
		interior.object_list[obj] = nil
		return
	end
	
	obj:AddTag("INTERIOR_LIMBO")

    if obj.SoundEmitter then
        obj.SoundEmitter:OverrideVolumeMultiplier(0)
    end
    
    if obj.Physics and not obj.Physics:IsActive() then
        obj.dissablephysics = true			
    end
	
	if obj.RemovedFromInteriorScene then
		--Hornet: Making sure that we are NOT touching interior data from a prefab
		obj:RemovedFromInteriorScene(deepcopy(interior))
	end

	for k, v in pairs(obj.components) do
        if v and type(v) == "table" and v.RemovedFromInteriorScene then
            v:RemovedFromInteriorScene(deepcopy(interior))
        end
    end
	
	local pos_offset = obj:GetPosition()-interior.world_position
	print("Our offset isss ", pos_offset)
	local pos = interior_storage_origin+pos_offset
	print(pos)
	
	obj:RemoveFromScene()
	obj.Transform:SetPositionIgnoringInterior(pos:Get())
end

local function RescueObjectFromLimbo(obj, interior)
	if not obj.persists then
		--This already should've been handled in ChuckObjectIntoLimbo... but just in case?
		obj:Remove()
		interior.object_list[obj] = nil
		return
	end
	
	obj:RemoveTag("INTERIOR_LIMBO")

    if obj.SoundEmitter then
        obj.SoundEmitter:OverrideVolumeMultiplier(1)
    end

	if obj.dissablephysics then
		obj.dissablephysics = nil
		obj.Physics:SetActive(false)
	end
	
	if obj.ReturnedToInteriorScene then
		obj:ReturnedToInteriorScene(deepcopy(interior))
	end

	for k, v in pairs(obj.components) do
        if v and type(v) == "table" and v.ReturnedToInteriorScene then
            v:ReturnedToInteriorScene(deepcopy(interior))
        end
    end
	
	local pos_offset = obj:GetPosition()-interior_storage_origin
	print("Rescuin!", pos_offset)
	local pos = interior.world_position + pos_offset
	print(pos)

	obj:ReturnToScene()
	obj.Transform:SetPositionIgnoringInterior(pos:Get())
end

local function GetNextInteriorSpawnPos()
	local pos = Vector3(interior_spawn_origin:Get())
	--Hornet: This feels stupid for some reason
	for i = 0, (GetTableSize(taken_positions)+2) * _space_between_interiors, _space_between_interiors do
		if taken_positions[pos.z] == nil then
			taken_positions[pos.z] = true
			return pos
		end
		print(pos)
		print(pos.z)
		
		pos.z = pos.z + _space_between_interiors
	end
end

--------------------------------------------------------------------------
--[[ Public Member functions ]]
--------------------------------------------------------------------------

function self:EnterInterior(doer, interior_id, dest, skipunloadattempt)
	local interior = interiors[interior_id]
	
	if not skipunloadattempt then
		local cached_interior = cached_player_interiors[doer.userid]
		
		self.inst:DoTaskInTime(0, function()
			if cached_interior and self:ShouldUnloadInterior(cached_interior) then
				print("unloading")
				self:UnloadInterior(cached_interior)
			end
		end)
	end
	
	cached_player_interiors[doer.userid] = interior_id
	
	if self:ShouldLoadInterior(interior_id) then
		self:LoadInterior(interior_id)
	end
	
	doer:SetInteriorID(interior_id)

    if dest ~= doer then
        local pt = Vector3(interior.world_position:Get())
        if dest ~= nil and dest.prefab then
            pt = dest:GetPosition()
        elseif dest ~= nil then
            pt = dest
        end
        doer.Transform:SetPositionIgnoringInterior(pt:Get())
    end

    if doer.components.interiorplayer ~= nil then
        doer.components.interiorplayer:EnterInterior(interior.visual)
    end
    -- TODO: Support for non players
end

function self:ExitInterior(doer, interior_id, dest)
	local interior = interiors[interior_id]
	
	cached_player_interiors[doer.userid] = nil
	
	doer:SetInteriorID(nil)

    if dest ~= doer then
        local pt = Vector3(TheWorld.components.playerspawner:GetAnySpawnPoint()) --florid postern if no location found...
        if dest ~= nil and dest.prefab then
            pt = dest:GetPosition()
        elseif dest ~= nil then
            pt = dest
        end
        doer.Transform:SetPositionIgnoringInterior(pt:Get())
    end

	if self:ShouldUnloadInterior(interior_id) then
		self:UnloadInterior(interior_id)
	end

    print("exit interior")
    if doer.components.interiorplayer ~= nil then
        print("exit interior player")
        doer.components.interiorplayer:ExitInterior()
    end
end

function self:LoadInterior(interior_id)
	print("LoadInterior", GetTime())
	if active_interiors[interior_id] ~= nil then print("[Interior_Manager] Tried running Load Interior, "..interior_id.." is already loaded!") return end
	--
	local interior = interiors[interior_id]
	interior.world_position = GetNextInteriorSpawnPos()
	print("Loading interior "..interior.interior_id..". Part of group: ("..(interior.interior_group or "UNKNOWN GROUP")..")")

	active_interiors[interior_id] = interior
	
	if interior.pending_props then
		SpawnPendingProps(interior)
	else
		for obj, _ in pairs(interior.object_list) do
			RescueObjectFromLimbo(obj, interior)
		end
	end

	self:GetInteriorEntities(interior_id)
	SetUpPathFindingBarriers(active_interiors[interior_id], interior.length, interior.width)
	ConfigureInteriorVisualAndPhysics(active_interiors[interior_id])
end

function self:UnloadInterior(interior_id)
	if active_interiors[interior_id] == nil then print("[Interior_Manager] Tried running Unload Interior, "..interior_id.." is already NOT loaded!") return end
	--
	local interior = interiors[interior_id]
	print("Unload interior "..interior.interior_id..". Part of group: ("..(interior.interior_group or "UNKNOWN GROUP")..")")

	self:GetInteriorEntities(interior_id)
	
	for obj, _ in pairs(interior.object_list) do
		ChuckObjectIntoLimbo(obj, interior)
	end
	
	ClearPathfindingBarriers(active_interiors[interior_id])
	ClearInteriorVisualAndPhysics(active_interiors[interior_id])
	
	taken_positions[interior.world_position.z] = nil
	interior.world_position = nil

	active_interiors[interior_id] = nil
end

--[[
--Hornet: Named parameters instead of positional parameters because holy moly there is too many parameters for me to want to remember each position
interior_data = {
	length = 15, the length
	width = 10, the width
	interior_group = group_id, the group this interior belongs to, for minimapping logic(and etc)
	interior_id = id, the unique id that this specific interior holds, and only this interior
	pending_props = { { name = prefabname, pos_offset = Vector3(0,0,0), rotation = 0, addtags = {"sus"}} }, a table enlisting the prefabs that need to spawn on first load of the interior
	
	floortexture = "levels/textures/noise_woodfloor.tex",
	walltexture = "levels/textures/interiors/shop_wall_woodwall.tex",
	minimaptexture = "levels/textures/map_interior/mini_ruins_slab.tex",
	
	cc = "images/colour_cubes/pigshop_interior_cc.tex",
	reverb = "inside",
}
local id = TheWorld.components.interiormanager:GetNewID() 
TheWorld.components.interiormanager:CreateRoom({interior_id = id, floortexture = INTERIOR_FLOOR, walltexture = INTERIOR_WALL}) print(id) 
TheWorld.components.interiormanager:EnterInterior(ThePlayer, id)

object_list = {
	[ent] = true,
}
]]

function self:RetrofitInteriorData(interior_data)
	if interior_data.length == nil then interior_data.length = 15 end
	if interior_data.width == nil then interior_data.width = 10 end
	if interior_data.height == nil then interior_data.height = 5 end
	if interior_data.pending_props == nil then interior_data.pending_props = {} end
	if interior_data.floortexture == nil then interior_data.floortexture = "levels/textures/interiors/sourceerror.tex" end
	if interior_data.walltexture == nil then interior_data.walltexture = "levels/textures/interiors/sourceerror.tex" end
    if interior_data.walltexturedimensions == nil then interior_data.walltexturedimensions = 512 end
	if interior_data.minimaptexture == nil then interior_data.minimaptexture = "levels/textures/interiors/sourceerror.tex" end
	if interior_data.cc == nil then interior_data.cc = "images/colour_cubes/pigshop_interior_cc.tex" end
	if interior_data.reverb == nil then interior_data.reverb = "inside" end
	if interior_data.pos == nil then interior_data.pos = {x = 0, y = 0} end
	if interior_room_positions[interior_data.interior_group] == nil then interior_room_positions[interior_data.interior_group] = {} end
	if interior_room_positions[interior_data.interior_group][interior_data.pos.x] == nil then interior_room_positions[interior_data.interior_group][interior_data.pos.x] = {} end
	if interior_room_positions[interior_data.interior_group][interior_data.pos.x][interior_data.pos.y] == nil then interior_room_positions[interior_data.interior_group][interior_data.pos.x][interior_data.pos.y] = {} end
end

function self:CreateRoom(interior_data)
    self:RetrofitInteriorData(interior_data)

	local interior_def = {
		length = interior_data.length,
		width = interior_data.width,
		height = interior_data.height,
		interior_group = interior_data.interior_group,
		interior_id = interior_data.interior_id,
		pending_props = interior_data.pending_props,
		object_list = {},
		
		floortexture = interior_data.floortexture,
		walltexture = interior_data.walltexture,
        walltexturedimensions = interior_data.walltexturedimensions,
		minimaptexture = interior_data.minimaptexture,
		
		cc = interior_data.cc,
		reverb = interior_data.reverb,
		pos = interior_data.pos,
	}
	
	interiors[interior_def.interior_id] = interior_def
	print(interior_def.interior_group, interior_data.pos.x, interior_data.pos.y)
	interior_room_positions[interior_def.interior_group][interior_data.pos.x][interior_data.pos.y] = interior_def.interior_id -- def or id?
end
--TODO(H): unfinished function, needs to be lot more clean up here
function self:RemoveRoom(interior_id)
	interiors[interior_id] = nil
end

function self:ShouldLoadInterior(interior_id)
	return active_interiors[interior_id] == nil
end

function self:ShouldUnloadInterior(interior_id)
	return active_interiors[interior_id] ~= nil and
		(#self:GetPlayersInInterior(interior_id) <= 0)
end

function self:GetNewID()
	next_interior_ID = next_interior_ID + 1
	return next_interior_ID
end

function self:GetPlayersInInterior(interior_id)
	local interior = active_interiors[interior_id]
	local x, y, z = interior.world_position:Get()
	
	return FindPlayersInRange(x,y,z, math.max(interior.length, interior.width))
end

function self:IsPointInInteriorSpawn(x, y, z)
    return x + _space_between_interiors >= interior_spawn_origin.x
end

function self:IsPointInInteriorStorage(x, y, z)
    return z + _space_between_interiors >= interior_storage_origin.z
end

function self:IsPointInInterior(x, y, z)
    if not self:IsPointInInteriorSpawn(x, z) then return end
	local pos = {x = x, y = z}
	for id, interior in pairs(active_interiors) do
		local int_pos = interior.world_position
		local width = interior.width
		local length = interior.length
		local AABB = {
			minX = int_pos.x - (width/2),
			maxX = int_pos.x + (width/2),
			minY = int_pos.z - (length/2),
			maxY = int_pos.z + (length/2),
		}
		if PointInsideAABB(pos, AABB) then
			return true, id
		end
	end
    -- In interior space but not in an interior
    return false, -1
end

--(H): lots of more work needs to be done on interior entity collection implementation
--in hamlet they go back to a bunch of prefabs to add interior funcs and tags to make em work when sleeping/waking in interiors
--this seems tedious for u guys to do for each little prefab, i would like to see if it's possible to cover everything in this function instead
--ill include some stuff like "FX" tag but that might be unreliable, idk
--i noticed a lot of stuff when returning to interior needed to turn off/on light, can we handle that in our load and unload automatically? probably
local INTERIOR_IMMUNE_TAGS = {"INTERIOR_LIMBO", "interior_spawn_storage"}--, "FX"}
--(NOTE, H): uhh nope?? including "FX" breaks stuff and prevents you from interacting with objects? lololol??
function self:GetInteriorEntities(interior_id)
	local interior = interiors[interior_id]
	--unloaded, return object_list
	if active_interiors[interior_id] == nil then return interior.object_list end
	--todo(h): there needs to be clean up for old object list

	local pt = interior.world_position
	local ents = TheSim:FindEntities(pt.x, pt.y, pt.z, math.max(interior.length, interior.width), nil, INTERIOR_IMMUNE_TAGS)

	for i = #ents, 1, -1 do
		local ent = ents[i]
		ent:SetInteriorID(interior_id)

		if ent:HasTag("interior_spawn_origin") or ent:HasTag("player") or ent:IsInLimbo() or ent:HasTag("INTERIOR_LIMBO_IMMUNE") --[[or ent.entity:GetParent()]] then
			table.remove(ents, i)
		end
	end

	for k, ent in pairs(ents) do
		interior.object_list[ent] = true
	end

	return ents
end

function self:GetDebugString()
	--[[
	TODO(H): include debug names for interiors?
	]]
	local str = "\n[[\n\n"

	for id, data in pairs(active_interiors) do
		str = str.."\tInterior ID    : "..id.."\n"
		str = str.."\tInterior Group : "..data.interior_group.."\n"

		str = str.."\tRoom Length    : "..data.length.."\n"
		str = str.."\tRoom Width     : "..data.width.."\n"
		str = str.."\tRoom Height    : "..data.height.."\n"

		str = str.."\tFlooring       : "..data.floortexture.."\n"
		str = str.."\tWalling        : "..data.walltexture.."\n"
		str = str.."\tMiniMapping    : "..data.minimaptexture.."\n"

		str = str.."\tReverb         : "..data.reverb.."\n"
		str = str.."\tCC         	 : "..data.cc.."\n"

		str = str.."\tPlayers:\n"

		for k, v in pairs(AllPlayers) do
			if v:IsValid() and v:GetInteriorID() == id then
				str = str.."\t\t"..v:GetDisplayName().."\n"
			end
		end

		str = str.."-----------------------\n\n"
	end

	str = str.."\n]]"

	return str
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnPlayerJoined(src, player)
	--Load into interior, and blahblah such stuff.
	if player == nil or (player.userid and player.userid == "") then
        return
    end

    local name = UserToName(player.userid)
    if name ~= nil then
        print("[Interior_Manager] "..name.. " joined the server. Were they in an interior last time? Let's chuck em in if so!")
		local cached_interior = cached_player_interiors[player.userid]

		if cached_interior == nil then return end
		if interiors[cached_interior] == nil then
			--(H): This interior doesn't exist anymore, so for now, we're chucking them back to the Florid Postern.
			print("[Interior_Manager "..name.."'s cached interior didn't exist. We chucked them to the Florid Postern.")
			player.Transform:SetPositionIgnoringInterior(TheWorld.components.playerspawner:GetAnySpawnPoint())
			return
		end
		
		print("Throwing em into the interior")
		--TODO(H): I think player_classified isn't set in time fast enough
		self:EnterInterior(player, cached_interior, nil, true)
    end
end

local function OnPlayerLeft(src, player)
	if player == nil or (player.userid and player.userid == "") then
        return
    end

    local name = UserToName(player.userid)
    if name ~= nil then
		local cached_interior = cached_player_interiors[player.userid]
       	print("[InteriorManager] "..name.. " left the server. Let's unload their interior if need be: ", cached_interior)

		if cached_interior == nil then return end
		if self:ShouldUnloadInterior(cached_interior) then
			self:UnloadInterior(cached_interior)
		end
    end
end

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

function self:OnSave()
    local data = {}
	local ents = {}

    data.interiors = deepcopy(interiors)
	data.object_list = {} --[id] = { objGUID, objGUID2 }

	for id, interior in pairs(data.interiors) do
		data.object_list[id] = {}

		for obj, _ in pairs(interior.object_list) do
			print("Saving", obj, "in interior")
			table.insert(data.object_list, obj.GUID)
			table.insert(ents, obj.GUID)
		end
		
		data.interiors[id].object_list = {}
		data.interiors[id].visual = nil --these don't persist, no need to save
		data.interiors[id].physics = nil
	end
	
	data.next_interior_ID = next_interior_ID
	data.cached_player_interiors = cached_player_interiors
	data.interior_room_positions = interior_room_positions

	return ZipAndEncodeSaveData(data), ents --TODO, zip and encode ents?
end

function self:OnLoad(data)
    data = DecodeAndUnzipSaveData(data)
    if data == nil then
        return
    end

	interiors = data.interiors or {}
	
	for id, interior in pairs(interiors) do
        self:RetrofitInteriorData(interiors[id])
		interiors[id].object_list = {}
	end

	next_interior_ID = data.next_interior_ID or 0
	cached_player_interiors = data.cached_player_interiors or {}
	interior_room_positions = data.interior_room_positions or {}
end

function self:LoadPostPass(ents, data)
	data = DecodeAndUnzipSaveData(data)
    if data == nil then
        return
    end

	--Hornet: me praying to the LUA goddess(i need the continue statement)
	print("LoadPostPass", GetTime())
	print(data.object_list)
	for id, obj_list in pairs(data.object_list or {}) do
		print(id, obj_list)
		print(interiors[id])
		if interiors[id] then
			print("Hey there we passed?")
			printwrap("Our object list", obj_list)
			for _, objID in pairs(obj_list) do
				print("object id: ", objID)
				if objID ~= nil and ents[objID] then
					local object = ents[objID].entity
					print(object)
					table.insert(interiors[id].object_list, object)	
				end
			end
		end
	end
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

inst:ListenForEvent("ms_playerjoined", OnPlayerJoined)
inst:ListenForEvent("ms_playerleft", OnPlayerLeft)

end)