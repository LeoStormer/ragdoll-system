local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)

local DEFAULT_PUNCH_INTERVAL = 3

local PunchMachine = Component.new({
	Tag = "PunchMachine",
})

function PunchMachine:Construct()
	self.startTime = DateTime.now().UnixTimestampMillis
	self.Instance:SetAttribute("StartTime", self.startTime)
	self.punchInterval = self.Instance:GetAttribute("PunchInterval")
	if self.punchInterval == nil then
		self.punchInterval = DEFAULT_PUNCH_INTERVAL
		self.Instance:SetAttribute("PunchInterval", DEFAULT_PUNCH_INTERVAL)
	end
end

return PunchMachine
