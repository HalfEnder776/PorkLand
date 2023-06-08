local InteriorPlayer = Class(function(self, inst)
    self.inst = inst

    self.classified = inst.player_classified
end)

-- Save/load currently handled by the InteriorManager
-- function InteriorPlayer:OnSave()

-- end

-- function InteriorPlayer:OnLoad(data)

-- end

function InteriorPlayer:EnterInterior(interior_visual, skipfade)
    print("player entering interior", interior_visual)
    if not skipfade then
        self.inst:SnapCamera()
        self.inst:ScreenFade(true, 1)
    end

	if self.inst.player_classified ~= nil then
		self.inst.player_classified.interior_visual:set(interior_visual)
	end

    self.inst:PushEvent("enterinterior")
end

function InteriorPlayer:ExitInterior(skipfade)
    if not skipfade then
        self.inst:SnapCamera()
        self.inst:ScreenFade(true, 1)
    end

    print("exit interior", self.classified)
	if self.classified ~= nil then
		self.classified.interior_visual:set(nil)
	end

    self.inst:PushEvent("exitinterior")
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

