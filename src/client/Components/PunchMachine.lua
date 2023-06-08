local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CollapseRagdollBindable: BindableEvent = ReplicatedStorage.Modules.RagdollSystem.Remotes.CollapseRagdollBindable
local Component = require(ReplicatedStorage.Packages.Component)
-- local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

local RAYCAST_PARAMS = RaycastParams.new()
RAYCAST_PARAMS.FilterDescendantsInstances = {Players.LocalPlayer.Character}
RAYCAST_PARAMS.FilterType = Enum.RaycastFilterType.Include

Players.LocalPlayer.CharacterAdded:Connect(function(character)
	RAYCAST_PARAMS.FilterDescendantsInstances = {character}
end)

local PunchMachine = Component.new({
	Tag = "PunchMachine",
	Ancestors = { workspace, ReplicatedStorage },
})

function PunchMachine:Construct()
	self._trove = Trove.new()
	self.enabled = false
	self.clientOnlyClone = self.Instance:Clone()
	
	for _, tag in CollectionService:GetTags(self.clientOnlyClone) do
		CollectionService:RemoveTag(self.clientOnlyClone, tag)
	end

    for _, descendant: Instance in self.clientOnlyClone:GetDescendants() do
        if descendant:IsA("PrismaticConstraint") then
            self._prismaticConstraint = descendant
            break
        end
    end

	self._prismaticConstraint.UpperLimit = math.max(self.Instance:GetAttribute("EnabledLength"), self._prismaticConstraint.UpperLimit)
	
	self._trove:Connect(self.Instance:GetAttributeChangedSignal("Enabled"), function()
		local length = if self.Instance:GetAttribute("Enabled")
			then self.Instance:GetAttribute("EnabledLength")
			else self.Instance:GetAttribute("DisabledLength")
		self._prismaticConstraint.TargetPosition = length
	end)

	self.clientOnlyClone.Parent = self.Instance.Parent
	self.Instance.Parent = ReplicatedStorage
	self.lastPosition = self.clientOnlyClone.PunchPart.Position
	self.radius = self.clientOnlyClone.PunchPart.Size.X * 0.5
end

function PunchMachine:Start()
	self.startTime = self.Instance:GetAttribute("StartTime")
	self.punchInterval = self.Instance:GetAttribute("PunchInterval")
end

function PunchMachine:HeartbeatUpdate(dt: number)
	local elapsedSeconds = (DateTime.now().UnixTimestampMillis - self.startTime) / 1000
	self.Instance:SetAttribute("Enabled", math.floor(elapsedSeconds / self.punchInterval) % 2 == 0)
	
	local lastPosition = self.lastPosition
	local currentPosition = self.clientOnlyClone.PunchPart.Position
	local displacement = currentPosition - lastPosition
	self.lastPosition = currentPosition
	
	local velocity = displacement / dt
	if velocity.Magnitude < 3 then
		return
	end

	local result = workspace:Spherecast(lastPosition, self.radius, displacement, RAYCAST_PARAMS)
	if result then
		CollapseRagdollBindable:Fire()
	end
end

function PunchMachine:Stop()
	self._trove:Destroy()
end

return PunchMachine
