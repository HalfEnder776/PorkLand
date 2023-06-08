local IAENV = env
GLOBAL.setfenv(1, GLOBAL)

IAENV.AddComponentPostInit("ambientsound", function(cmp)
    local inst = cmp.inst

    -- local AMBIENT_SOUNDS--, WAVE_SOUNDS
    -- local function Setup()
    --     AMBIENT_SOUNDS = UpvalueHacker.GetUpvalue(cmp.OnUpdate, "AMBIENT_SOUNDS")

    --     assert(AMBIENT_SOUNDS)
    -- end

    -- if not pcall(Setup) then return IA_MODULE_ERROR("ambientsound") end

    local _reverb_override = nil
    local _old_reverb = nil

    local _SetReverbPreset = cmp.SetReverbPreset
    function cmp:SetReverbPreset(reverb, ...)
        if not _reverb_override then
            _SetReverbPreset(self, reverb, ...)
        end		
        _old_reverb = reverb
    end
    
    function cmp:SetReverbOveride(reverb)
        _reverb_override = reverb
        TheSim:SetReverbPreset(reverb)
    end
    
    function cmp:ClearReverbOveride()
        _reverb_override = nil	
        TheSim:SetReverbPreset(_old_reverb or "default")
    end
end)
