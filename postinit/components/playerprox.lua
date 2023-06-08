GLOBAL.setfenv(1, GLOBAL)
local PlayerProx = require("components/playerprox")

function PlayerProx:RemovedFromInteriorScene()
    if self.onfar ~= nil then
        self.onfar(self.inst)
    end
end
