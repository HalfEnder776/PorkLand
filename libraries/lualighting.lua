GLOBAL.setfenv(1, GLOBAL)

local light_at_dist = light_at_dist

--(H): Only necessary for server, we override it to be dark on client side, but server needs support for exclusive areas of darkness.

if not TheNet:GetIsMasterSimulation()  then
	function LightWatcher:OnDestroyLuaLighting() end
	return 
end

--

local LIGHTWATCHERS_TO_DATA = {} --[inst.LightWatcher] = {inst = inst, darkthresh = 0, lightthresh = 0, minlightthresh = 0, inlight = true, timedark = 0, timelight = 0}
local LIGHTWATCHERS_TO_UPDATE = {} --[inst.LightWatcher] = true

--

local _Update = Update
function Update(dt, ...)
	--print("Test, Update is called")
	for k, v in pairs(LIGHTWATCHERS_TO_UPDATE) do
		--(h): pause if unloaded??
		local watcherdata = LIGHTWATCHERS_TO_DATA[k]
		if watcherdata.inst:GetInteriorID() then
			--print(TheWorld.ismastersim, "This is the mastersim", k:IsInLight())
			if not watcherdata.inlight and k:IsInLight() then
				watcherdata.inlight = true
				watcherdata.timelight = GetTime()
				watcherdata.timedark = nil
				watcherdata.inst:PushEvent("enterlight")
			elseif watcherdata.inlight and not k:IsInLight() then
				watcherdata.inlight = false
				watcherdata.timedark = GetTime()
				watcherdata.timelight = nil
				watcherdata.inst:PushEvent("enterdark")
			end
		end
	end
	--
	_Update(dt, ...)
end

local _ListenForEvent = EntityScript.ListenForEvent
function EntityScript:ListenForEvent(event, fn, source, ...)
	if event == "enterdark" or event == "enterlight" then
		assert(self.LightWatcher, "Tried to listen for enterdark/enterlight event but this entity has no LightWatcher!")
		LIGHTWATCHERS_TO_UPDATE[self.LightWatcher] = true
	end
	_ListenForEvent(self, event, fn, source, ...)
end

local _RemoveEventCallback = EntityScript.RemoveEventCallback
function EntityScript:RemoveEventCallback(event, fn, source, ...)
	if event == "enterdark" or event == "enterlight" then --todo: don't remove if we still have existing events with these 
		LIGHTWATCHERS_TO_UPDATE[self.LightWatcher] = nil
		
		local watcherdata = LIGHTWATCHERS_TO_DATA[self.LightWatcher]
		watcherdata.inlight = nil
		watcherdata.timelight = nil
		watcherdata.timedark = nil
	end
	_RemoveEventCallback(self, event, fn, source, ...)
end

local _AddLightWatcher = Entity.AddLightWatcher
function Entity:AddLightWatcher(...)
	local guid = self:GetGUID()
	local inst = Ents[guid]
	local hasLightWatcher = inst.LightWatcher
	local lightwatcher = _AddLightWatcher(self, ...)

	if inst and not hasLightWatcher then
		LIGHTWATCHERS_TO_DATA[lightwatcher] = {inst = inst}
	end

	return lightwatcher
end

local _SetDarkThresh = LightWatcher.SetDarkThresh
function LightWatcher:SetDarkThresh(threshold, ...)
    LIGHTWATCHERS_TO_DATA[self].darkthresh = threshold
    _SetDarkThresh(self, threshold, ...)
end

local _SetLightThresh = LightWatcher.SetLightThresh
function LightWatcher:SetLightThresh(threshold, ...)
    LIGHTWATCHERS_TO_DATA[self].lightthresh = threshold
    _SetLightThresh(self, threshold, ...)
end


local _SetMinLightThresh = LightWatcher.SetMinLightThresh
function LightWatcher:SetMinLightThresh(threshold, ...)
    LIGHTWATCHERS_TO_DATA[self].minlightthresh = threshold
    _SetMinLightThresh(self, threshold, ...)
end

local _GetLightValue = LightWatcher.GetLightValue
function LightWatcher:GetLightValue(...) --(H) Override lighting in interiors, interiors are dark by default in ambient lighting
	local inst = LIGHTWATCHERS_TO_DATA[self].inst
	local interior_id = inst ~= nil and inst:GetInteriorID()
	if interior_id then
		return TheSim:GetLightAtPoint(inst.Transform:GetWorldPosition())
	end

	return _GetLightValue(self, ...)
end

local _GetTimeInDark = LightWatcher.GetTimeInDark
function LightWatcher:GetTimeInDark(...)
	local watcherdata = LIGHTWATCHERS_TO_DATA[self]
	if watcherdata.timedark then
		return GetTime() - watcherdata.timedark
	elseif watcherdata.timelight then
		return 0
	end

	return _GetTimeInDark(self, ...)
end

local _GetTimeInLight = LightWatcher.GetTimeInLight
function LightWatcher:GetTimeInLight(...)
	local watcherdata = LIGHTWATCHERS_TO_DATA[self]
	if watcherdata.timelight then
		return GetTime() - watcherdata.timelight
	elseif watcherdata.timedark then
		return 0
	end

	return _GetTimeInLight(self, ...)
end

local _IsInLight = LightWatcher.IsInLight
function LightWatcher:IsInLight(...)
	local inst = LIGHTWATCHERS_TO_DATA[self].inst
	local interior_id = inst ~= nil and inst:GetInteriorID()
	if interior_id then
		--TODO, over or over AND equal to????? CHECK!
		return self:GetLightValue() > LIGHTWATCHERS_TO_DATA[self].darkthresh
	end
	return _IsInLight(self, ...)
end

function LightWatcher:OnDestroyLuaLighting()
	LIGHTWATCHERS_TO_DATA[self] = nil
	LIGHTWATCHERS_TO_UPDATE[self] = nil
	--TODO(H): might need to add something here in the future
end

local _GetLightAtPoint = Sim.GetLightAtPoint
function Sim:GetLightAtPoint(x, y, z, ...)
    local inside, interior_id = TheWorld.components.interiormanager:IsPointInInterior(x,y,z)
    --print(inside, interior_id)
    if inside then
        local lights = TheWorld.components.interiormanager:GetInteriorEntities(interior_id)
        local sum = 0
        for k, v in pairs(lights) do
            if v.Light then
                sum = sum + light_at_dist(v.Light, math.sqrt(v:GetDistanceSqToPoint(x, y, z)))
            end
        end
        --calculations aren't fully accurate, idk why
        --print("GetLightAtPoint interior(server) override( LUA: "..sum.." , C++: ".._GetLightAtPoint(self, x, y, z, ...)..")")
        return sum
    end

	return _GetLightAtPoint(self, x, y, z, ...)
end