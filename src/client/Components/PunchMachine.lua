local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CapsuleCollider = require(ReplicatedStorage.Modules.CapsuleCollider)
local Component = require(ReplicatedStorage.Packages.Component)
-- local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

local CollapsePlayerRagdollBindable: BindableEvent =
	ReplicatedStorage.Modules.RagdollSystem.Remotes.CollapsePlayerRagdollBindable
-- local RAYCAST_PARAMS = RaycastParams.new()
-- RAYCAST_PARAMS.FilterDescendantsInstances = {Players.LocalPlayer.Character}
-- RAYCAST_PARAMS.FilterType = Enum.RaycastFilterType.Include
local OVERLAP_PARAMS = OverlapParams.new()
OVERLAP_PARAMS.FilterDescendantsInstances = { Players.LocalPlayer.Character }
OVERLAP_PARAMS.FilterType = Enum.RaycastFilterType.Include

Players.LocalPlayer.CharacterAdded:Connect(function(character)
	-- RAYCAST_PARAMS.FilterDescendantsInstances = {character}
	OVERLAP_PARAMS.FilterDescendantsInstances = { character }
end)

local PunchMachine = Component.new({
	Tag = "PunchMachine",
	Ancestors = { workspace, ReplicatedStorage },
})

function PunchMachine:Construct()
	self._trove = Trove.new()
	self.enabled = false
	self.clientOnlyClone = self._trove:Add(self.Instance:Clone()) :: Model
	for _, tag in CollectionService:GetTags(self.clientOnlyClone) do
		CollectionService:RemoveTag(self.clientOnlyClone, tag)
	end

	self.punchPart = self.clientOnlyClone.PunchPart
	self._prismaticConstraint = self.clientOnlyClone:FindFirstChildOfClass("PrismaticConstraint")
	local enabledLength = self.Instance:GetAttribute("EnabledLength")
	self._prismaticConstraint.UpperLimit = if enabledLength then enabledLength else self._prismaticConstraint.UpperLimit

	local diameter = self.punchPart.Size.X
	local height = diameter + 0.5
	self.capsuleCollider = self._trove:Construct(CapsuleCollider, diameter * 0.5, height, OVERLAP_PARAMS)
	self.capsuleCollider:setBottomBallCFrame(self.punchPart.CFrame)

	local ball = self.capsuleCollider:getBottomBall()
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = self.punchPart
	weld.Part1 = ball
	weld.Parent = self.punchPart
	self.capsuleCollider:setParent(self.clientOnlyClone)

	self._trove:Connect(self.clientOnlyClone:GetAttributeChangedSignal("Enabled"), function()
		local length = if self.clientOnlyClone:GetAttribute("Enabled")
			then self.Instance:GetAttribute("EnabledLength")
			else self.Instance:GetAttribute("DisabledLength")
		
		self._prismaticConstraint.TargetPosition = length
	end)

	self.clientOnlyClone.Parent = self.Instance.Parent
	self.Instance.Parent = ReplicatedStorage
	self.lastPosition = self.punchPart.Position
end

function PunchMachine:Start()
	self.startTime = self.Instance:GetAttribute("StartTime")
	self.punchInterval = self.Instance:GetAttribute("PunchInterval")
end

function PunchMachine:HeartbeatUpdate(dt: number)
	local elapsedSeconds = (DateTime.now().UnixTimestampMillis - self.startTime) / 1000
	self.clientOnlyClone:SetAttribute("Enabled", math.floor(elapsedSeconds / self.punchInterval) % 2 == 0)

	local lastPosition = self.lastPosition
	local currentPosition = self.punchPart.Position
	local displacement = currentPosition - lastPosition
	self.lastPosition = currentPosition

	local velocity = displacement / dt
	if velocity.Magnitude < 3 then
		return
	end

	-- self.capsuleCollider:setBottomBallCFrame(self.punchPart.CFrame)
	local characterParts = self.capsuleCollider:getPartsInCapsule()
	if #characterParts > 0 then
		CollapsePlayerRagdollBindable:Fire()
	end
end

function PunchMachine:Stop()
	self._trove:Destroy()
end

return PunchMachine
