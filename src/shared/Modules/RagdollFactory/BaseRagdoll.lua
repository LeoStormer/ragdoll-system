local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

local BaseRagdoll = {}
BaseRagdoll.__index = BaseRagdoll

local LIMB_PHYSICAL_PROPERTIES = PhysicalProperties.new(5, 0.7, 0.5, 100, 100)
local RAGDOLL_TIMEOUT_INTERVAL = 2
local RAGDOLL_TIMEOUT_DISTANCE_THRESHOLD = 2

local BALLSOCKETCONSTRAINT_TEMPLATE: BallSocketConstraint = Instance.new("BallSocketConstraint")
BALLSOCKETCONSTRAINT_TEMPLATE.Enabled = false
BaseRagdoll.BALLSOCKETCONSTRAINT_TEMPLATE = BALLSOCKETCONSTRAINT_TEMPLATE

local NOCOLLISIONCONSTRAINT_TEMPLATE: NoCollisionConstraint = Instance.new("NoCollisionConstraint")
NOCOLLISIONCONSTRAINT_TEMPLATE.Enabled = false
BaseRagdoll.NOCOLLISIONCONSTRAINT_TEMPLATE = NOCOLLISIONCONSTRAINT_TEMPLATE

local LINEARVELOCITY_TEMPLATE: LinearVelocity = Instance.new("LinearVelocity")
LINEARVELOCITY_TEMPLATE.VectorVelocity = Vector3.new(0, 50, -8000) --At least any must be >0 to wake physics
LINEARVELOCITY_TEMPLATE.MaxForce = 8000
LINEARVELOCITY_TEMPLATE.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
LINEARVELOCITY_TEMPLATE.Enabled = false
BaseRagdoll.LINEARVELOCITY_TEMPLATE = LINEARVELOCITY_TEMPLATE

local ANGULARVELOCITY_TEMPLATE: AngularVelocity = Instance.new("AngularVelocity")
ANGULARVELOCITY_TEMPLATE.AngularVelocity = Vector3.new(0, 10, 0)
ANGULARVELOCITY_TEMPLATE.MaxTorque = 1000
ANGULARVELOCITY_TEMPLATE.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
ANGULARVELOCITY_TEMPLATE.ReactionTorqueEnabled = false
ANGULARVELOCITY_TEMPLATE.Enabled = false
BaseRagdoll.ANGULARVELOCITY_TEMPLATE = ANGULARVELOCITY_TEMPLATE

function BaseRagdoll.new(character, numConstraints: number?)
	character:SetAttribute("Ragdolled", false)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.AutomaticScalingEnabled = false
	humanoid.BreakJointsOnDeath = false

	local trove = Trove.new()
	local constraintsFolder = trove:Add(Instance.new("Folder"))
	constraintsFolder.Name = "RagdollConstraints"
	constraintsFolder.Parent = character

	local self = {
		character = character,
		humanoid = humanoid,
		humanoidRootPart = character:WaitForChild("HumanoidRootPart"),
		frozen = false,
		ragdolled = false,
		ragdollBegan = trove:Construct(Signal),
		ragdollEnded = trove:Construct(Signal),
		_trove = trove,
		_constraintsFolder = constraintsFolder,
		_activeTrove = trove:Extend(),
		_constraints = if numConstraints then table.create(numConstraints) else {},
		_originalSettings = {},
		_accessoryHandles = {},
		_motor6Ds = {},
		_limbs = {},
	}

	for _, limb in character:GetChildren() do
		if limb:IsA("Accessory") then
			local handle = limb.Handle
			BaseRagdoll._recordOriginalSettings(self, handle, {
				CanCollide = handle.CanCollide,
				CanTouch = handle.CanTouch,
				Massless = handle.Massless,
			})
			table.insert(self._accessoryHandles, handle)
		end

		for _, motor6D: Motor6D in limb:getChildren() do
			if not motor6D:IsA("Motor6D") then
				continue
			end

			local affectedLimb = motor6D.Part1
			BaseRagdoll._recordOriginalSettings(self, motor6D, { Enabled = motor6D.Enabled })
			BaseRagdoll._recordOriginalSettings(self, affectedLimb, {
				Anchored = affectedLimb.Anchored,
				CanCollide = affectedLimb.CanCollide,
				CustomPhysicalProperties = affectedLimb.CustomPhysicalProperties,
			})

			table.insert(self._motor6Ds, motor6D)
			table.insert(self._limbs, affectedLimb)
		end
	end

	BaseRagdoll._recordOriginalSettings(self, self.humanoidRootPart, { CanCollide = self.humanoidRootPart.CanCollide })
	BaseRagdoll._recordOriginalSettings(self, humanoid, { WalkSpeed = humanoid.WalkSpeed })

	return self
end

function BaseRagdoll._addConstraint(ragdoll, constraint)
	constraint.Parent = ragdoll._constraintsFolder
	table.insert(ragdoll._constraints, constraint)
	return constraint
end

function BaseRagdoll._setupLimb(
	ragdoll,
	socketSettingsDictionary,
	sourceLimb: BasePart,
	affectedLimb: BasePart,
	cframe0: CFrame,
	cframe1: CFrame
)
	local noCollisionConstraint =
		BaseRagdoll._addConstraint(ragdoll, BaseRagdoll.NOCOLLISIONCONSTRAINT_TEMPLATE:Clone())
	noCollisionConstraint.Part0 = sourceLimb
	noCollisionConstraint.Part1 = affectedLimb

	local attachment1 = ragdoll._trove:Add(Instance.new("Attachment"))
	attachment1.CFrame = cframe0
	attachment1.Parent = sourceLimb

	local attachment2 = ragdoll._trove:Add(Instance.new("Attachment"))
	attachment2.CFrame = cframe1
	attachment2.Parent = affectedLimb

	local socket = BaseRagdoll._addConstraint(ragdoll, BaseRagdoll.BALLSOCKETCONSTRAINT_TEMPLATE:Clone())
	socket.Attachment0 = attachment1
	socket.Attachment1 = attachment2
	socket.LimitsEnabled = true
	socket.TwistLimitsEnabled = true

	local socketSettings = socketSettingsDictionary[affectedLimb.Name]
	if socketSettings ~= nil then
		for key, value in socketSettings do
			if socket[key] then
				socket[key] = value
			end
		end
	end
end

function BaseRagdoll:_refreshLayeredClothing()
	--Hack. Refreshes and resyncs layered clothing.
	for _, accessory in pairs(self.character:GetChildren()) do
		if accessory:IsA("Accessory") then
			for _, wrapLayer: WrapLayer in pairs(accessory.Handle:GetChildren()) do
				if wrapLayer:IsA("WrapLayer") then
					local refWT = Instance.new("WrapTarget")
					refWT.Parent = wrapLayer.Parent
					refWT:Destroy()
					refWT.Parent = nil
				end
			end
		end
	end
end

function BaseRagdoll:_timeoutRagdoll()
	local timer = 0
	local lastPos = self.humanoidRootPart.Position

	local connection
	connection = self._activeTrove:Connect(RunService.Heartbeat, function(dt)
		timer += dt
		if timer < RAGDOLL_TIMEOUT_INTERVAL then
			return
		end

		local newPos = self.humanoidRootPart.Position
		local distance = (newPos - lastPos).Magnitude
		lastPos = newPos
		timer -= RAGDOLL_TIMEOUT_INTERVAL
		if distance >= RAGDOLL_TIMEOUT_DISTANCE_THRESHOLD then
			return
		end
		self._activeTrove:Remove(connection)

		if self.humanoid:GetState() == Enum.HumanoidStateType.Dead then
			self:freeze()
		else
			self:deactivateRagdollPhysics()
		end
	end)
end

function BaseRagdoll._recordOriginalSettings(ragdoll, object: Instance, record)
	if ragdoll._originalSettings[object] then
		for key, value in record do
			ragdoll._originalSettings[object][key] = value
		end
	else
		ragdoll._originalSettings[object] = record
	end
end

function BaseRagdoll:activateRagdollPhysics()
	if self.ragdolled then
		return
	end

	self.ragdolled = true
	self.character:SetAttribute("Ragdolled", true)
	self.humanoidRootPart.CanCollide = false
	self.humanoid.WalkSpeed = 0

	for _, handle in self._accessoryHandles do
		handle.CanCollide = false
		handle.CanTouch = false
		handle.Massless = true
	end

	for _, motor6D: Motor6D in self._motor6Ds do
		motor6D.Enabled = false
	end

	for _, limb in self._limbs do
		limb.CanCollide = true
		limb.CustomPhysicalProperties = LIMB_PHYSICAL_PROPERTIES
	end

	for _, constraint: Constraint in self._constraints do
		constraint.Enabled = true
	end
	
	self.ragdollBegan:Fire()
end

function BaseRagdoll:deactivateRagdollPhysics()
	if not self.ragdolled then
		return
	end

	self.ragdolled = false
	self.character:SetAttribute("Ragdolled", false)
	self.humanoidRootPart.CanCollide = self._originalSettings[self.humanoidRootPart].CanCollide
	self.humanoid.WalkSpeed = self._originalSettings[self.humanoid].WalkSpeed

	for _, handle in self._accessoryHandles do
		handle.CanCollide = self._originalSettings[handle].CanCollide
		handle.CanTouch = self._originalSettings[handle].CanTouch
		handle.Massless = self._originalSettings[handle].Massless
	end

	for _, motor6D: Motor6D in self._motor6Ds do
		motor6D.Enabled = self._originalSettings[motor6D].Enabled
	end

	for _, limb in self._limbs do
		limb.CanCollide = self._originalSettings[limb].CanCollide
		limb.CustomPhysicalProperties = self._originalSettings[limb].CustomPhysicalProperties
	end

	for _, constraint: Constraint in self._constraints do
		constraint.Enabled = false
	end

	self.ragdollEnded:Fire()
end

function BaseRagdoll:enable()
	self:activateRagdollPhysics()
	self:_refreshLayeredClothing()
	self:_timeoutRagdoll()
end

function BaseRagdoll:freeze()
	if self.frozen then
		return
	end
	self.frozen = true

	for _, part in self._limbs do
		self:_recordOriginalSettings(part, { Anchored = part.Anchored })
		part.Anchored = true
	end
end

function BaseRagdoll:unfreeze()
	if not self.frozen then
		return
	end
	self.frozen = false

	for _, part in self.limbs do
		part.Anchored = self._originalSettings[part].Anchored
	end
end

function BaseRagdoll:destroy()
	self._trove:Destroy()
end
BaseRagdoll.Destroy = BaseRagdoll.destroy

export type Ragdoll = {
	enabled: boolean,
	freeze: (self: Ragdoll) -> (),
	enable: (self: Ragdoll) -> (),
	disable: (self: Ragdoll) -> (),
	destroy: (self: Ragdoll) -> (),
}

return BaseRagdoll
