local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local TableUtils = require(script.Parent.Parent.TableUtils)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

local BaseRagdoll = {}
BaseRagdoll.__index = BaseRagdoll

local LIMB_PHYSICAL_PROPERTIES = PhysicalProperties.new(5, 0.7, 0.5, 100, 100)
local ROOT_PART_PHYSICAL_PROPERTIES = PhysicalProperties.new(0, 0, 0, 0, 0)
local RAGDOLL_TIMEOUT_INTERVAL = 1.5
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
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.AutomaticScalingEnabled = false
	humanoid.BreakJointsOnDeath = false

	local trove = Trove.new()
	local constraintsFolder = trove:Add(Instance.new("Folder"))
	constraintsFolder.Name = "RagdollConstraints"
	constraintsFolder.Parent = character
	character:SetAttribute("Ragdolled", false)
	local children = character:GetChildren()

	local self = {
		character = character,
		humanoid = humanoid,
		humanoidRootPart = character:WaitForChild("HumanoidRootPart"),
		collapsed = false,
		frozen = false,
		ragdolled = false,
		ragdollBegan = trove:Construct(Signal),
		ragdollEnded = trove:Construct(Signal),
		_trove = trove,
		_constraintsFolder = constraintsFolder,
		_constraints = if numConstraints then table.create(numConstraints) else {},
		_originalSettings = {},
		_limbs = TableUtils.filter(children, function(limb: BasePart)
			return limb:IsA("BasePart") and limb.Name ~= "HumanoidRootPart"
		end),
		_accessoryHandles = TableUtils.map(
			TableUtils.filter(children, function(accessory: Accessory)
				return accessory:IsA("Accessory")
			end),
			function(accessory: Accessory)
				return accessory:FindFirstChild("Handle")
			end
		),
		_motor6Ds = TableUtils.filter(character:GetDescendants(), function(motor: Motor6D)
			return motor:IsA("Motor6D")
		end),
	}

	BaseRagdoll._recordOriginalSettings(self)
	
	self.ragdollBegan:Connect(function()
		character:SetAttribute("Ragdolled", true)
	end)

	self.ragdollEnded:Connect(function()
		character:SetAttribute("Ragdolled", false)
	end)

	return self
end

function BaseRagdoll._recordOriginalSettings(ragdoll)
	local function recordSetting(object: Instance, record)
		if ragdoll._originalSettings[object] then
			for key, value in record do
				ragdoll._originalSettings[object][key] = value
			end
		else
			ragdoll._originalSettings[object] = record
		end
	end

	recordSetting(ragdoll.humanoid, { WalkSpeed = ragdoll.humanoid.WalkSpeed, AutoRotate = ragdoll.humanoid.AutoRotate, })
	recordSetting(ragdoll.humanoidRootPart, {
		Anchored = ragdoll.humanoidRootPart.Anchored,
		CanCollide = ragdoll.humanoidRootPart.CanCollide,
		CustomPhysicalProperties = ragdoll.humanoidRootPart.CustomPhysicalProperties,
	})

	for _, limb in ragdoll._limbs do
		recordSetting(limb, {
			Anchored = limb.Anchored,
			CanCollide = limb.CanCollide,
			CustomPhysicalProperties = limb.CustomPhysicalProperties,
		})
	end

	for _, handle in ragdoll._accessoryHandles do
		recordSetting(handle, {
			CanCollide = handle.CanCollide,
			CanTouch = handle.CanTouch,
			Massless = handle.Massless,
		})
	end

	for _, motor6D in ragdoll._motor6Ds do
		recordSetting(motor6D, { Enabled = motor6D.Enabled })
	end
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

function BaseRagdoll:activateRagdollPhysics()
	if self.ragdolled then
		return
	end

	self.ragdolled = true
	self.humanoid.WalkSpeed = 0
	self.humanoid.AutoRotate = false
	self.humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	self.humanoidRootPart.CanCollide = false
	self.humanoidRootPart.CustomPhysicalProperties = ROOT_PART_PHYSICAL_PROPERTIES

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
	self.humanoid.WalkSpeed = self._originalSettings[self.humanoid].WalkSpeed
	self.humanoid.AutoRotate = self._originalSettings[self.humanoid].AutoRotate
	self.humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	self.humanoidRootPart.CanCollide = self._originalSettings[self.humanoidRootPart].CanCollide
	self.humanoidRootPart.CustomPhysicalProperties =
		self._originalSettings[self.humanoidRootPart].CustomPhysicalProperties

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

function BaseRagdoll:collapse()
	if self.collapsed then
		return
	end
	
	self.collapsed = true
	self:activateRagdollPhysics()
	self:_refreshLayeredClothing()

	local timer = 0
	local lastPos = self.humanoidRootPart.Position

	local connection
	connection = self._trove:Connect(RunService.Heartbeat, function(dt)
		if not self.ragdolled then
			self.collapsed = false
			self._trove:Remove(connection)
			return
		end
		
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
		
		self.collapsed = false
		self._trove:Remove(connection)
		if self.humanoid:GetState() == Enum.HumanoidStateType.Dead then
			self:freeze()
		else
			self:deactivateRagdollPhysics()
		end
	end)
end

function BaseRagdoll:freeze()
	if self.frozen then
		return
	end
	self.frozen = true
	self.humanoidRootPart.Anchored = true

	for _, part in self._limbs do
		part.Anchored = true
	end
end

function BaseRagdoll:unfreeze()
	if not self.frozen then
		return
	end
	self.frozen = false
	self.humanoidRootPart.Anchored = self._originalSettings[self.humanoidRootPart].Anchored

	for _, part in self._limbs do
		part.Anchored = self._originalSettings[part].Anchored
	end
end

function BaseRagdoll:destroy()
	self._trove:Destroy()
end
BaseRagdoll.Destroy = BaseRagdoll.destroy

export type Ragdoll = {
	collapsed: boolean,
	frozen: boolean,
	ragdolled: boolean,
	activateRagdollPhysics: (self: Ragdoll) -> (),
	deactivateRagdollPhysics: (self: Ragdoll) -> (),
	collapse: (self: Ragdoll) -> (),
	freeze: (self: Ragdoll) -> (),
	unfreeze: (self: Ragdoll) -> (),
	destroy: (self: Ragdoll) -> (),
	Destroy: (self: Ragdoll) -> (),
}

return BaseRagdoll
