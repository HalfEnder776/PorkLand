GLOBAL.setfenv(1, GLOBAL)

local unpack = unpack
local assert = assert
local Ents = Ents

function SilenceEvent(event, data, ...)
    return event .. "_silenced", data
end

function EntityScript:AddPushEventPostFn(event, fn, source)
    source = source or self

    if not source.pushevent_postfn then
        source.pushevent_postfn = {}
    end

    source.pushevent_postfn[event] = fn
end

local _PushEvent = EntityScript.PushEvent
if not IA_ENABLED then function EntityScript:PushEvent(event, data, ...)
    local eventfn = self.pushevent_postfn ~= nil and self.pushevent_postfn[event] or nil

    if eventfn ~= nil then
        local newevent, newdata = eventfn(event, data, ...)

        if newevent ~= nil then
            event = newevent
        end
        if newdata ~= nil then
            data = newdata
        end
    end

    _PushEvent(self, event, data, ...)
end end

function EntityScript:GetEventCallbacks(event, source, source_file)
    source = source or self

    assert(self.event_listening[event] and self.event_listening[event][source])

    for _, fn in ipairs(self.event_listening[event][source]) do
        if source_file then
            local info = debug.getinfo(fn, "S")
            if info and info.source == source_file then
                return fn
            end
        else
            return fn
        end
    end
end

-- for houses

if TheNet:GetIsMasterSimulation() then

    local _transform_to_inst = {}
    local _physics_to_inst = {}

    local _skip_interior_transition = {}

    local _AddTransform = Entity.AddTransform
    function Entity:AddTransform(...)
        local rets = {_AddTransform(self, ...)}
        local inst = Ents[self:GetGUID()]
        if inst ~= nil and rets[1] ~= nil then
            _transform_to_inst[rets[1]] = inst
        end
        return unpack(rets)
    end

    local _AddPhysics = Entity.AddPhysics
    function Entity:AddPhysics(...)
        local rets = {_AddPhysics(self, ...)}
        local inst = Ents[self:GetGUID()]
        if inst ~= nil and rets[1] ~= nil then
            _physics_to_inst[rets[1]] = inst
        end
        return unpack(rets)
    end

    local _SetPosition = Transform.SetPosition
    function Transform:SetPosition(x, y, z, ...)
        local inst = _transform_to_inst[self]
        local rets = {_SetPosition(self, x, y, z, ...)}
        if inst ~= nil then
            inst:OnTeleported(x, y, z)
        end
        return unpack(rets)
    end

    local _Teleport = Physics.Teleport
    function Physics:Teleport(x, y, z, ...)
        local inst = _physics_to_inst[self]
        local rets = {_Teleport(self, x, y, z, ...)}
        if inst ~= nil then
            inst:OnTeleported(x, y, z)
        end
        return unpack(rets)
    end

    local _TeleportRespectingInterpolation = Physics.TeleportRespectingInterpolation
    function Physics:TeleportRespectingInterpolation(x, y, z, ...)
        local inst = _physics_to_inst[self]
        local rets = {_TeleportRespectingInterpolation(self, x, y, z, ...)}
        if inst ~= nil then
            inst:OnTeleported(x, y, z)
        end
        return unpack(rets)
    end

    function Transform:OnDestroyLuaTransform()
        _transform_to_inst[self] = nil
    end

    function Physics:OnDestroyLuaPhysics()
        _physics_to_inst[self] = nil
    end

    function EntityScript:GetInteriorID()
        return self.interior_id
    end

    function EntityScript:SetInteriorID(id)
        assert(id == nil or id > 0, "Tried setting invalid interior id", id, " for", self)
        
        if not self.interior_label then
            local label = self.entity:AddLabel()
            self.interior_label = label
            label:SetColour(unpack(PLAYERCOLOURS.CORAL))
            label:SetWorldOffset(0, 1, 0)
            label:SetFont(CHATFONT_OUTLINE)
            label:SetFontSize(16)
            label:Enable(true)
        end
        self.interior_label:SetText(tostring(id or 0)) 

        self.interior_id = id
    end

    function Transform:SetPositionIgnoringInterior(x, y, z, ...)
        local inst = _transform_to_inst[self]

        local _skip = _skip_interior_transition[inst]
        _skip_interior_transition[inst] = true

        local rets = {self:SetPosition(x, y, z, ...)}

        _skip_interior_transition[inst] = _skip

        return unpack(rets)
    end

    function EntityScript:OnTeleported(tx, ty, tz)
        if _skip_interior_transition[self] then return end
        local _world = TheWorld
        if not _world then return end
        local _interiormanager = _world.components.interiormanager
        if not _interiormanager then return end

        -- is the entity in an interior
        -- is the destination in an interior
        local source_interior_id = self:GetInteriorID()
        local _, dest_interior_id = _interiormanager:IsPointInInterior(tx, ty, tz)
        if self:HasTag("player") then
            print("Player teleporting", source_interior_id, dest_interior_id)
        end
        if source_interior_id == dest_interior_id then return end
        if self.components.interiorplayer then
            -- if source_interior_id then
            --     -- remove us from the source room
            --     print("player exit interior", source_interior_id)
            --     _interiormanager:ExitInterior(self, source_interior_id, self)
            -- end
            -- if dest_interior_id then
            --     -- add us to the dest room
            --     print("player enter interior", dest_interior_id)
            --     _interiormanager:EnterInterior(self, dest_interior_id, self)
            -- end
        else    
            -- todo should we deal with non players?
            -- if source_interior_id then
            --     -- remove us from the source room
            --     _interiormanager:RemoveProp(self, source_interior_id)
            --     _interiormanager:ReturnItemToScene(self)
            -- end
            -- if dest_interior_id then
            --     -- add us to the dest room
            --     _interiormanager:InjectProp(self,is_interior, dest_interior_id)
            -- end
        end
    end
else
    function Transform:OnDestroyLuaTransform()
    end

    function Physics:OnDestroyLuaPhysics()
    end

    function EntityScript:GetInteriorID()
    end

    function EntityScript:SetInteriorID(id)
    end

    function Transform:SetPositionIgnoringInterior(...)
        return self:SetPosition(...)
    end

    function EntityScript:OnTeleported(tx, ty, tz)
    end
end

local _Remove = EntityScript.Remove
function EntityScript:Remove(...)
	if self.MiniMapEntity ~= nil then
		self.MiniMapEntity:OnDestroyLuaMinimap()
	end
	if self.LightWatcher ~= nil then
		self.LightWatcher:OnDestroyLuaLighting()
	end
    if self.Transform ~= nil then
        self.Transform:OnDestroyLuaTransform()
    end
    if self.Physics ~= nil then
        self.Physics:OnDestroyLuaPhysics()
    end
	return _Remove(self, ...)
end

--
