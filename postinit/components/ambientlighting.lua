local AddComponentPostInit = AddComponentPostInit
GLOBAL.setfenv(1, GLOBAL)

AddComponentPostInit("ambientlighting", function(self, inst)

    local _activatedplayer = nil --cached for activation/deactivation only, NOT for logic use
    local _isinterior = false -- This is whether or not the active player is in an interior

    local OnPhaseChanged = self.inst:GetEventCallbacks("phasechanged", nil, "scripts/components/ambientlighting.lua")
    local PushCurrentColour = Pl_Util.GetUpvalue(OnPhaseChanged, "PushCurrentColour")
    local ComputeTargetColour = Pl_Util.GetUpvalue(OnPhaseChanged, "ComputeTargetColour")

    local _realcolour = Pl_Util.GetUpvalue(OnPhaseChanged, "_realcolour")
    local _overridecolour = Pl_Util.GetUpvalue(OnPhaseChanged, "_overridecolour")

    function self:GetRealColour()
        return _realcolour.currentcolour.x, _realcolour.currentcolour.y, _realcolour.currentcolour.z
    end
    
    local function IA_ComputeTargetColour(targetsettings, timeoverride, ...)
        if not _isinterior then 
            return ComputeTargetColour(targetsettings, timeoverride, ...)
        end

        local col = targetsettings.currentcolourset.PHASE_COLOURS.default.night
            or targetsettings.currentcolourset.CAVE_COLOUR or nil
        if col == nil then
            return ComputeTargetColour(targetsettings, timeoverride, ...)
        end

        -- spoof night or cave colours when in an interior
        local _currentcolourset = targetsettings.currentcolourset
        targetsettings.currentcolourset = {
            CAVE_COLOUR = col,
            PHASE_COLOURS = {
                default = {
                    day = col,
                    dusk = col,
                    night = col, 
                }
            }
        }

        ComputeTargetColour(targetsettings, timeoverride, ...)

        targetsettings.currentcolourset = _currentcolourset
    end
    Pl_Util.SetUpvalue(OnPhaseChanged, IA_ComputeTargetColour, "ComputeTargetColour")

    local function OnUpdateInterior(player, enabled)
        _isinterior = enabled
        IA_ComputeTargetColour(_realcolour, 0)
        IA_ComputeTargetColour(_overridecolour, 0)
        PushCurrentColour()
    end

    local function OnEnterInterior(player)
        OnUpdateInterior(player, true)
    end

    local function OnExitInterior(player)
        OnUpdateInterior(player, false)
    end

    local function IA_OnPlayerDeactivated(inst, player)
        inst:RemoveEventCallback("enterinterior", OnEnterInterior, player)
        inst:RemoveEventCallback("exitinterior", OnExitInterior, player)
        if player == _activatedplayer then
            _activatedplayer = nil
        end
    end
    
    local function IA_OnPlayerActivated(inst, player)
        if _activatedplayer == player then
            return
        elseif _activatedplayer ~= nil and _activatedplayer.entity:IsValid() then
            IA_OnPlayerDeactivated(_activatedplayer)
        end
        _activatedplayer = player
        inst:ListenForEvent("enterinterior", OnEnterInterior, player)
        inst:ListenForEvent("exitinterior", OnExitInterior, player)
    end


    inst:ListenForEvent("playeractivated", IA_OnPlayerActivated)
    inst:ListenForEvent("playerdeactivated", IA_OnPlayerDeactivated)
end)
