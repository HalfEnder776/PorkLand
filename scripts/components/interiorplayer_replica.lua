local InteriorPlayer = Class(function(self, inst)
    self.inst = inst

    self:AttachClassified(inst.player_classified)
end)

--------------------------------------------------------------------------

function InteriorPlayer:OnRemoveFromEntity()
    if self.classified ~= nil then
        self:DetachClassified()
    end
end

InteriorPlayer.OnRemoveEntity = InteriorPlayer.OnRemoveFromEntity

function InteriorPlayer:AttachClassified(classified)
    self.classified = classified
    self.inst:DoTaskInTime(0, function()
        self:OnInteriorChanged()
        self.oninterior_visual = function() self:OnInteriorChanged() end
        self.inst:ListenForEvent("interiorvisualdirty", self.oninterior_visual, classified)
    end)
    if not TheWorld.ismastersim then
        self.ondetachclassified = function() self:DetachClassified() end
        self.inst:ListenForEvent("onremove", self.ondetachclassified, classified)
    end
end

function InteriorPlayer:DetachClassified()
    self.inst:RemoveEventCallback("interiorvisualdirty", self.oninterior_visual, self.classified)
    if not TheWorld.ismastersim then
        self.inst:ListenForEvent("onremove", self.ondetachclassified, self.classified)
        self.ondetachclassified = nil
    end
    self.oninterior_visual = nil
    self.classified = nil
end

--------------------------------------------------------------------------

function InteriorPlayer:OnInteriorChanged()

    local interior = self.classified.interior_visual:value()
    print("interiorchanged", interior)
    if interior ~= nil then

        if self.inst == ThePlayer then
            SwitchToInteriorCamera(interior)
            SwitchToInteriorEnviroment(interior)
        end

        if not TheWorld.ismastersim then
            self.inst:PushEvent("enterinterior")
        end
    else

        if self.inst == ThePlayer then
            SwitchToOutdoorCamera()
            SwitchToOutdoorEnviroment()
        end

        if not TheWorld.ismastersim then
            self.inst:PushEvent("exitinterior")
        end
    end
end

function InteriorPlayer:InInterior()
    if self.classified ~= nil then
        return self.classified.interior_visual:value() ~= nil
    end
end

function InteriorPlayer:GetInteriorVisual()
    if self.classified ~= nil then
        return self.classified.interior_visual:value()
    end
end

return InteriorPlayer
