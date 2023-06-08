local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)

local PunchMachine = Component.new({
    Tag = "PunchMachine",
})

function PunchMachine:Construct()
    self.Instance:SetAttribute("StartTime", DateTime.now().UnixTimestampMillis)
    local interval = self.Instance:GetAttribute("PunchInterval")
    if interval == nil then
        self.Instance:SetAttribute("PunchInterval", 3)
    end
end

return PunchMachine