local IAENV = env
GLOBAL.setfenv(1, GLOBAL)

function PointInsideAABB(point, box)
	return point.x >= box.minX and
		point.x <= box.maxX and
		point.y >= box.minY and
		point.y <= box.maxY
end
--(H): the x <= 1900 check is a filter before moving onto more expensive calculations
function ValidInteriorSpace(x,y,z)
	if TheWorld.ismastersim then
		return TheWorld.components.interiormanager ~= nil and TheWorld.components.interiormanager:IsPointInInterior(x,y,z)
	else
        if x <= 1900 then return false end
        local _player = ThePlayer
		if _player == nil then return false end
		if _player.replica.interiorplayer == nil then return false end
	
		local interior = _player.replica.interiorplayer:GetInteriorVisual()
		if interior == nil then return end

		local int_pos = interior:GetPosition()
		local width = interior.roomwidth:value()
		local length = interior.roomlength:value()
		local AABB = {
			minX = int_pos.x - (width/2),
			maxX = int_pos.x + (width/2),
			minY = int_pos.z - (length/2),
			maxY = int_pos.z + (length/2),
		}
		if PointInsideAABB({x=x,y=z}, AABB) then
			return true
		end
	end
	
	return false
end


--(H): 150 Pixels is equal to one unit! Ain't that neateroo!
function PixelToUnit(pixels)
	return pixels/150
end

function UnitToPixel(units)
	return units*150
end

function CreateInteriorRoom(group, x, y)
	local id = TheWorld.components.interiormanager:GetNewID()
	local props = {
		--note, offset is 'backwards'. in the interior x looks like z and z looks like x. Yes, I know that is awful, i'm really sorry about it.
		{ name = "researchlab2", pos_offset = Vector3(-2, 0, 5), rotation = 0}
	}
	
	TheWorld.components.interiormanager:CreateRoom({
		interior_id = id,
		interior_group = group or id,
		floortexture = INTERIOR_FLOOR,
		walltexture = INTERIOR_WALL,
		pending_props = props,
		pos = {x = x or 0, y = y or 0},
	})
	
	return id
end
--[[
	TheCamera.interior_currentpos_original = Vector3(2000-2, 0, 0) 
	TheCamera.interior_currentpos = Vector3(2000-2, 0, 0) 
	TheCamera.interior_distance = 35
]]
function CreateAntRoom(group, x, y)
	local id = TheWorld.components.interiormanager:GetNewID()
	local props = {

	}
	
	TheWorld.components.interiormanager:CreateRoom({
		length = 26, 
		width = 18,
		height = 7,
		interior_id = id,
		interior_group = group or id,
		floortexture = INTERIOR_FLOOR_ANT,
		walltexture = INTERIOR_WALL_ANT,
		pending_props = props,
		pos = {x = x or 0, y = y or 0},
	})
	
	return id
end

function CreatePalaceRoom(group, x, y)
	local id = TheWorld.components.interiormanager:GetNewID()
	local props = {

	}
	
	TheWorld.components.interiormanager:CreateRoom({
		length = 26, 
		width = 18,
		height = 13,
		interior_id = id,
		interior_group = group or id,
		floortexture = INTERIOR_FLOOR_PALACE,
		walltexture = INTERIOR_WALL_PALACE,
        walltexturedimensions = 1024,
		pending_props = props,
		pos = {x = x or 0, y = y or 0},
	})
	
	return id
end

--https://forums.kleientertainment.com/forums/topic/138533-solved-how-do-light-intensityradiusfalloff-work/
--thanks!
function light_at_dist(l, dist) --light value at distance from source
    local A = math.log(l:GetIntensity())
    local B = -(l:GetFalloff() / A)
    local C = (dist / l:GetRadius()) ^ B
    local D = math.exp(A * C)
    local r, g, b = l:GetColour()
    local E = 0.2126 * r + 0.7152 * g + 0.0722 * b

    return D * E
end

function dist_for_light(l, threshold) --dist from source with threshold value
    threshold = threshold or 0.075

    local A = math.log(l:GetIntensity())
    local B = -(l:GetFalloff() / A)
    local r, g, b = l:GetColour()
    local E = 0.2126 * r + 0.7152 * g + 0.0722 * b

    return math.exp(math.log(math.log(threshold / E) / A) / B) * l:GetRadius()
end

require("cameras/interiorcamera")
 
OutdoorCamera = nil
TheInteriorCamera = InteriorCamera()

local function GetInteriorCameraData(width)
	local cameraoffset = -2.5 		--10x15
	local zoom = 23

	if width == 12 then    --12x18
		cameraoffset = -2
		zoom = 25
	elseif width == 16 then --16x24
		cameraoffset = -1.5
		zoom = 30
	elseif width == 18 then --18x26
		cameraoffset = -2 -- -1
		zoom = 35
	end

	return cameraoffset, zoom
end

if not TheNet:IsDedicated() then
    function SwitchToInteriorCamera(interior)
        if OutdoorCamera == nil then
            OutdoorCamera = TheCamera
        end

        local x, y, z = interior.Transform:GetWorldPosition()
        local cameraoffset, zoom = GetInteriorCameraData(interior.roomwidth:value())
        local pos = Vector3(x+cameraoffset,y,z)

        TheCamera = TheInteriorCamera
        TheCamera:SetTarget(TheFocalPoint)
        TheCamera:Snap()
        TheCamera.interior_currentpos_original = pos
        TheCamera.interior_currentpos = pos
        TheCamera.interior_distance = zoom
        TheCamera.interior_heading = 0
    end

    function SwitchToOutdoorCamera()
        if OutdoorCamera == nil then
            OutdoorCamera = TheCamera
        end
        
        TheCamera = OutdoorCamera
        TheCamera:SetTarget(TheFocalPoint)
        TheCamera:SetDefault()
        TheCamera:Snap()
    end

    function SwitchToInteriorEnviroment(interior)
        local _world = TheWorld
        local _player = ThePlayer

        if _world.components.ambientsound ~= nil then
            _world.components.ambientsound:SetReverbOverride(interior.roomreverb:value())
        end

        if _world.components.oceancolor ~= nil then
            _world.components.oceancolor:SetVoid()
        end

        if _player.components.playervision ~= nil then
            _player.components.playervision:SetInteriorCCTable(interior.roomcolourcube:value())
        end
    end

    function SwitchToOutdoorEnviroment()
        local _world = TheWorld
        local _player = ThePlayer 

        if _world.components.ambientsound ~= nil then
            _world.components.ambientsound:ClearReverbOveride()
        end

        if _world.components.oceancolor ~= nil then
            _world.components.oceancolor:ClearVoid()
        end

        if _player.components.playervision ~= nil then
            _player.components.playervision:SetInteriorCCTable(nil)
        end
    end
else
    function SwitchToInteriorCamera(interior)
    end

    function SwitchToOutdoorCamera()
    end

    function SwitchToInteriorEnviroment(interior)
    end

    function SwitchToOutdoorEnviroment()
    end
end
