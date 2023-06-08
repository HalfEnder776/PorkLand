--TODO:(H)
--[[
	omg just turn this into a 'interior_manager' or something similar and manage visual/physics/misc data for clients
]]

--local TEXTURE = "levels/tiles/falloff.tex"
--local TEXTURE = "levels/tiles/blocky.tex"
local TEXTURE = "levels/textures/Ground_noise_deciduous.tex"
local TEXTURE_FLOOR = "levels/textures/interiors/floor_cityhall.tex"
local TEXTURE_WALL = "levels/textures/interiors/shop_wall_woodwall.tex"
local SHADER = "shaders/interior.ksh"

local MAX_LIFETIME = 99999 --27 hours. Should be good enough aye?
local MAX_PARTICLES1 = 1
local MAX_PARTICLES2 = 2

local assets =
{
    Asset("SHADER", SHADER),
    Asset("IMAGE", TEXTURE),
    Asset("IMAGE", TEXTURE_FLOOR),
    Asset("IMAGE", TEXTURE_WALL),
}

local function emit(inst, emitter, pos, uv)
	uv = uv or {}

    inst.VFXEffect:AddParticle(
        emitter or 0,
        MAX_LIFETIME,   -- lifetime
        (pos.x or 0), (pos.y or 0), (pos.z or 0),     -- position
        0, 0, 0			-- velocity
        --(uv.x or 0), (uv.y or 0)        -- uv offset
    )
end

local function settexture(inst, emitter, texture)
	print("yay")
	inst.VFXEffect:SetRenderResources(emitter or 0, resolvefilepath(texture), resolvefilepath(SHADER))
end

local function OnTextureDirty(inst)
	print("floortexture", inst.floortexture:value())
	print("walltexture", inst.walltexture:value())
	settexture(inst, 0, inst.floortexture:value())
	settexture(inst, 1, inst.walltexture:value())
	settexture(inst, 2, inst.walltexture:value())
	settexture(inst, 3, inst.walltexture:value())
end

local function OnEmitDirty(inst)
	inst:DoTaskInTime(0, function()
		local heightscale = UnitToPixel(inst.roomheight:value()) / 512
		local scale = UnitToPixel(inst.roomwidth:value()) / 512
		local height = PixelToUnit(inst.walltexturedimensions:value() * heightscale) / 2
		local realheight = height * 0.948 --magic number
		local halflength = inst.roomlength:value()/2
		local halfwidth = inst.roomwidth:value()/2
		local extrawidth = height/math.tan(math.rad(64.65)) --this should be 60 degrees(or pi/3) but its... just not I guess? this looks more accurate in-game so um, yea, let's go with it
		
		--i am really shit with math, as you can tell.
		
		inst.VFXEffect:SetScaleEnvelope(0, "interiorwidth"..inst.roomwidth:value())
		inst.VFXEffect:SetUVFrameSize(0, -inst.roomlength:value()/inst.roomwidth:value(), 1)

		inst.VFXEffect:SetScaleEnvelope(1, "interiorheightleftwall"..inst.roomheight:value())
		inst.VFXEffect:SetUVFrameSize(1, -inst.roomwidth:value()/inst.roomheight:value(), 1)
		
		inst.VFXEffect:SetScaleEnvelope(2, "interiorheight"..inst.roomheight:value())
		inst.VFXEffect:SetUVFrameSize(2, -inst.roomwidth:value()/inst.roomheight:value(), 1)
		
		inst.VFXEffect:SetScaleEnvelope(3, "interiorheight"..inst.roomheight:value())
		inst.VFXEffect:SetUVFrameSize(3, -inst.roomlength:value()/inst.roomheight:value(), 1)

		print("halflength", halflength)
		print("halfwidth", halfwidth)
		print("extrawidth", extrawidth)
		print("scale: ", scale)
		
		emit(inst, 0, {x = 0, y = 0, z = 0}) --floor
		emit(inst, 1, {x = -extrawidth, y = realheight, z = -halflength}) --side wall
		emit(inst, 2, {x = -extrawidth, y = realheight, z = halflength}) --side wall
		emit(inst, 3, {x = -halfwidth-extrawidth, y = realheight, z = 0}) --back wall
	end)
end

local function GetInteriorEntities(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, math.max(inst.roomlength:value(), inst.roomwidth:value()), nil, {"INTERIOR_LIMBO","interior_spawn_storage"})

	for i = #ents, 1, -1 do
		if not ents[i] then
			print("entry: ", i, " was null for some reason?!?")
		end
	
		if ents[i]:HasTag("interior_spawn_origin") or ents[i]:HasTag("player") or ents[i]:IsInLimbo() or ents[i]:HasTag("INTERIOR_LIMBO_IMMUNE") then
			table.remove(ents, i)
		end
	end

	return ents
end

local function fn()
    local inst = CreateEntity()

    inst:AddTag("FX")
    inst:AddTag("interior_visual")

    inst.entity:AddTransform()
	inst.entity:AddNetwork()

    inst.persists = false
	
	inst.floortexture = net_string(inst.GUID, "interior.floortexture", "interiortexturedirty")
	inst.walltexture = net_string(inst.GUID, "interior.walltexture", "interiortexturedirty")

    inst.walltexturedimensions = net_ushortint(inst.GUID, "interior.walltexturedimensions")
	--
	inst.roomheight = net_smallbyte(inst.GUID, "interior.roomheight", "roomdirty")
	inst.roomlength = net_smallbyte(inst.GUID, "interior.roomlength", "roomdirty")
	inst.roomwidth = net_smallbyte(inst.GUID, "interior.roomwidth", "roomdirty")
	--
	--extra interior data unrelated to visuals
	inst.roomreverb = net_string(inst.GUID, "interior.roomreverb")
	inst.roomcolourcube = net_string(inst.GUID, "interior.roomcolourcube")
	inst.roomgroup = net_string(inst.GUID, "interior.roomgroup")
	inst.roomid = net_string(inst.GUID, "interior.roomid")
	--pos for map
	inst.roomposx = net_shortint(inst.GUID, "interior.roomposx")
	inst.roomposy = net_shortint(inst.GUID, "interior.roomposy")
	--
	inst.emit = net_event(inst.GUID, "interior.emit")

	inst.GetInteriorEntities = GetInteriorEntities
	
	inst.entity:SetPristine()

    -----------------------------------------------------

    --Dedicated does not need to spawn local vfx
    if TheNet:IsDedicated() then return inst end

    local effect = inst.entity:AddVFXEffect()
    effect:InitEmitters(4)
	--floor
	effect:SetRenderResources(0, resolvefilepath(TEXTURE_FLOOR), resolvefilepath(SHADER))
	effect:SetMaxNumParticles(0, MAX_PARTICLES1)
	effect:SetMaxLifetime(0, MAX_LIFETIME)
	effect:SetSpawnVectors(0,
		0, 0, -1,
		1, 0, 0
	)
    effect:SetUVFrameSize(0, -1.5, 1)
	effect:SetKillOnEntityDeath(0, true)
	--effect:SetWorldSpaceEmitter(0, true)
	effect:SetLayer(0, LAYER_GROUND)
	--walls
	effect:SetRenderResources(1, resolvefilepath(TEXTURE_WALL), resolvefilepath(SHADER))
	effect:SetMaxNumParticles(1, MAX_PARTICLES2)
	effect:SetMaxLifetime(1, MAX_LIFETIME)
	effect:SetSpawnVectors(1,
		1, 0, 0,
		-.5, 1, 0
	)
    effect:SetUVFrameSize(1, 2, 1)
	effect:SetKillOnEntityDeath(1, true)
	effect:SetLayer(1, LAYER_WORLD_BACKGROUND)
	
	effect:SetRenderResources(2, resolvefilepath(TEXTURE_WALL), resolvefilepath(SHADER))
	effect:SetMaxNumParticles(2, MAX_PARTICLES2)
	effect:SetMaxLifetime(2, MAX_LIFETIME)
	effect:SetSpawnVectors(2,
		1, 0, 0,
		-.5, 1, 0
	)
    effect:SetUVFrameSize(2, 2, 1)
	effect:SetKillOnEntityDeath(2, true)
	effect:SetLayer(2, LAYER_WORLD_BACKGROUND)
	--back wall
	effect:SetRenderResources(3, resolvefilepath(TEXTURE_WALL), resolvefilepath(SHADER))
	effect:SetMaxNumParticles(3, MAX_PARTICLES1)
	effect:SetMaxLifetime(3, MAX_LIFETIME)
	effect:SetSpawnVectors(3,
		0, 0, 1,
		-.5, 1, 0
	)
    effect:SetUVFrameSize(3, 3, 1)
	effect:SetKillOnEntityDeath(3, true)
	effect:SetLayer(3, LAYER_WORLD_BACKGROUND)

	inst.Emit = emit
	inst.SetTexture = settexture
    -----------------------------------------------------
	inst:ListenForEvent("interior.emit", OnEmitDirty)
	inst:ListenForEvent("interiortexturedirty", OnTextureDirty)
	--
    return inst
end

return Prefab("interior_visual", fn, assets)