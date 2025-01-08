-- Credit to Rookstun and the Ragdoll Solution: https://devforum.roblox.com/t/ragdoll-solution-r15customizable-ragdolls-for-use-with-layered-clothing/1738685
-- local RunService = game:GetService("RunService")

local Types = require(script.Parent.Parent.Types)
local TableUtils = require(script.Parent.Parent.TableUtils)
local Signal = require(script.Parent.Parent.Parent.Signal)
local Trove = require(script.Parent.Parent.Parent.Trove)

--[=[
	@class Ragdoll
	@__index Ragdoll
]=]
--[=[
	@within Ragdoll
	@private
	@interface RagdollInternals
	._constraintsFolder Folder -- Root Folder
	._noCollisionConstraintFolder Folder -- Parent Folder to the Ragdoll's NoCollisionConstraints
	._socketFolder Folder -- Parent folder to the Ragdoll's BallSocketConstraints
	._noCollisionConstraints { NoCollisionConstraints }.
	._sockets  { BallSocketConstraint }
	._limbs { BasePart } -- List of the Ragdoll's direct children BaseParts exluding the root part. 
	._accessoryHandles { BasePart }
	._motor6Ds { Motor6D } 
]=]
--[=[
	@within Ragdoll
	@readonly
	@prop Character Model
	The model this ragdoll corresponds to.
]=]
--[=[
	@within Ragdoll
	@readonly
	@prop Humanoid Humanoid
]=]
--[=[
	@within Ragdoll
	@readonly
	@prop HumanoidRootPart BasePart
]=]
--[=[
	@within Ragdoll
	@readonly
	@prop RagdollBegan Signal
	
	An signal fired when ragdoll physics has begun.

	```lua
		ragdoll.RagdollBegan:Connect(function()
			--Do something when ragdoll physics has begun
		end)
	```
]=]
--[=[
	@within Ragdoll
	@readonly
	@prop RagdollEnded Signal
	A signal fired when ragdoll physics has ended.

	```lua
		ragdoll.RagdollEnded:Connect(function()
			--Do something when ragdoll physics has ended
		end)
	```
]=]
--[=[
	@within Ragdoll
	@readonly
	@prop Destroying Signal
	A signal fired when ragdoll:destroy() is called.
]=]
local Ragdoll = {}
Ragdoll.__index = Ragdoll

local LIMB_PHYSICAL_PROPERTIES = PhysicalProperties.new(5, 0.7, 0.5, 100, 100)
local ROOT_PART_PHYSICAL_PROPERTIES = PhysicalProperties.new(0.01, 0, 0, 0, 0)

local BALLSOCKETCONSTRAINT_TEMPLATE: BallSocketConstraint = Instance.new("BallSocketConstraint")
BALLSOCKETCONSTRAINT_TEMPLATE.Enabled = false
Ragdoll.BALLSOCKETCONSTRAINT_TEMPLATE = BALLSOCKETCONSTRAINT_TEMPLATE

local NOCOLLISIONCONSTRAINT_TEMPLATE: NoCollisionConstraint = Instance.new("NoCollisionConstraint")
NOCOLLISIONCONSTRAINT_TEMPLATE.Enabled = false
Ragdoll.NOCOLLISIONCONSTRAINT_TEMPLATE = NOCOLLISIONCONSTRAINT_TEMPLATE

local LINEARVELOCITY_TEMPLATE: LinearVelocity = Instance.new("LinearVelocity")
LINEARVELOCITY_TEMPLATE.VectorVelocity = Vector3.new(0, 50, -8000) --At least any must be >0 to wake physics
LINEARVELOCITY_TEMPLATE.MaxForce = 8000
LINEARVELOCITY_TEMPLATE.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
LINEARVELOCITY_TEMPLATE.Enabled = false
Ragdoll.LINEARVELOCITY_TEMPLATE = LINEARVELOCITY_TEMPLATE

local ANGULARVELOCITY_TEMPLATE: AngularVelocity = Instance.new("AngularVelocity")
ANGULARVELOCITY_TEMPLATE.AngularVelocity = Vector3.new(0, 10, 0)
ANGULARVELOCITY_TEMPLATE.MaxTorque = 1000
ANGULARVELOCITY_TEMPLATE.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
ANGULARVELOCITY_TEMPLATE.ReactionTorqueEnabled = false
ANGULARVELOCITY_TEMPLATE.Enabled = false
Ragdoll.ANGULARVELOCITY_TEMPLATE = ANGULARVELOCITY_TEMPLATE

local ACCEPTABLE_RAGDOLL_STATES = {
	[Enum.HumanoidStateType.Dead] = true,
	[Enum.HumanoidStateType.Physics] = true,
}

function recordOriginalSettings(
	humanoid: Humanoid,
	humanoidRootPart: BasePart,
	limbs: { BasePart },
	accessoryHandles: { BasePart },
	motor6Ds: { Motor6D }
)
	local originalSettings = {}
	originalSettings[humanoid] = { WalkSpeed = humanoid.WalkSpeed, AutoRotate = humanoid.AutoRotate }
	originalSettings[humanoidRootPart] = {
		Anchored = humanoidRootPart.Anchored,
		CanCollide = humanoidRootPart.CanCollide,
		CustomPhysicalProperties = humanoidRootPart.CustomPhysicalProperties,
	}

	for _, limb in limbs do
		originalSettings[limb] = {
			Anchored = limb.Anchored,
			CanCollide = limb.CanCollide,
			CustomPhysicalProperties = limb.CustomPhysicalProperties,
		}
	end

	for _, handle in accessoryHandles do
		originalSettings[handle] =
			{ CanCollide = handle.CanCollide, CanTouch = handle.CanTouch, Massless = handle.Massless }
	end

	for _, motor6D in motor6Ds do
		originalSettings[motor6D] = { Enabled = motor6D.Enabled }
	end

	return originalSettings
end

function constructRagdoll(
	character: Model,
	humanoid: Humanoid,
	humanoidRootPart: BasePart,
	limbs: { BasePart },
	accessoryHandles: { BasePart },
	motor6Ds: { Motor6D },
	blueprint: Types.Blueprint,
	trove,
	constraintsFolder: Folder,
	socketsFolder: Folder,
	noCollisionsFolder: Folder,
	sockets: { BallSocketConstraint },
	noCollisionConstraints: { NoCollisionConstraint }
)
	humanoid.AutomaticScalingEnabled = false
	humanoid.BreakJointsOnDeath = false

	local originalSettings = recordOriginalSettings(humanoid, humanoidRootPart, limbs, accessoryHandles, motor6Ds)

	local ragdoll = setmetatable({
		Character = character,
		Humanoid = humanoid,
		Animator = humanoid:WaitForChild("Animator"),
		HumanoidRootPart = humanoidRootPart,
		RagdollBegan = trove:Construct(Signal),
		RagdollEnded = trove:Construct(Signal),
		Collapsed = trove:Construct(Signal),
		Destroying = trove:Construct(Signal),
		_collapsed = false,
		_frozen = false,
		_ragdolled = false,
		_trove = trove,
		_constraintsFolder = constraintsFolder,
		_socketFolder = socketsFolder,
		_noCollisionConstraintFolder = noCollisionsFolder,
		_sockets = sockets,
		_noCollisionConstraints = noCollisionConstraints,
		_originalSettings = originalSettings,
		_limbs = limbs,
		_accessoryHandles = accessoryHandles,
		_motor6Ds = motor6Ds,
		_lowDetailModeSockets = if blueprint.lowDetailModeLimbs
			then TableUtils.filter(sockets, function(socket: BallSocketConstraint)
				return blueprint.lowDetailModeLimbs[socket.Name]
			end)
			else sockets,
		_lowDetailMotor6Ds = if blueprint.lowDetailModeLimbs
			then TableUtils.filter(motor6Ds, function(motor: Motor6D)
				return blueprint.lowDetailModeLimbs[(motor.Part1 :: BasePart).Name]
			end)
			else motor6Ds,
	}, Ragdoll)

	trove:Connect(humanoid.StateChanged, function(old, new)
		if old == Enum.HumanoidStateType.Dead then
			ragdoll:unfreeze()
		end

		if not ragdoll:isRagdolled() then
			return
		end

		if new == Enum.HumanoidStateType.FallingDown then
			humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		elseif not ACCEPTABLE_RAGDOLL_STATES[new] then
			humanoid:ChangeState(Enum.HumanoidStateType.FallingDown)
		end
	end)

	ragdoll.RagdollBegan:Connect(function()
		character:SetAttribute("Ragdolled", true)
	end)

	ragdoll.RagdollEnded:Connect(function()
		character:SetAttribute("Ragdolled", false)
	end)

	trove:Connect(character.Destroying, function()
		ragdoll:destroy()
	end)

	return ragdoll
end

function getCharacterComponents(character: Model)
	local humanoid = character:WaitForChild("Humanoid")
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	local children = character:GetChildren()

	local limbs = TableUtils.filter(children, function(limb)
		return limb:IsA("BasePart") and limb.Name ~= "HumanoidRootPart"
	end)

	local accessoryHandles = TableUtils.map(
		TableUtils.filter(children, function(accessory)
			return accessory:IsA("Accessory")
		end),
		function(accessory: Accessory)
			return accessory:FindFirstChild("Handle")
		end
	)

	local motor6Ds = TableUtils.filter(character:GetDescendants(), function(motor)
		return motor:IsA("Motor6D")
	end)

	return humanoid, humanoidRootPart, limbs, accessoryHandles, motor6Ds
end

do
	local function createConstraints(
		sourceLimb: BasePart,
		affectedLimb: BasePart,
		cframe0: CFrame,
		cframe1: CFrame,
		blueprint: Types.Blueprint
	)
		local noCollisionConstraint = Ragdoll.NOCOLLISIONCONSTRAINT_TEMPLATE:Clone()
		noCollisionConstraint.Part0 = sourceLimb
		noCollisionConstraint.Part1 = affectedLimb

		local attachment0 = Instance.new("Attachment")
		attachment0.CFrame = cframe0
		attachment0.Parent = sourceLimb

		local attachment1 = Instance.new("Attachment")
		attachment1.CFrame = cframe1
		attachment1.Parent = affectedLimb

		local socket = Ragdoll.BALLSOCKETCONSTRAINT_TEMPLATE:Clone()
		socket.Attachment0 = attachment0
		socket.Attachment1 = attachment1
		socket.LimitsEnabled = true
		socket.TwistLimitsEnabled = true

		local socketSettings = blueprint.socketSettings[affectedLimb.Name]
		if socketSettings ~= nil then
			for key, value in socketSettings do
				if socket[key] then
					socket[key] = value
				end
			end
		end

		return socket, noCollisionConstraint, attachment0, attachment1
	end

	local function setupLimbs(
		trove,
		motor6Ds: { Motor6D },
		socketsFolder: Folder,
		noCollisionsFolder: Folder,
		blueprint
	)
		local sockets = table.create(blueprint.numLimbs)
		local noCollisionConstraints = table.create(blueprint.numLimbs)

		for _, motor6D: Motor6D in motor6Ds do
			local sourceLimb = motor6D.Part0
			local affectedLimb = motor6D.Part1
			local override = blueprint.cframeOverrides[affectedLimb.Name]
			local cframe0 = if override then override.C0 else motor6D.C0
			local cframe1 = if override then override.C1 else motor6D.C1
			local socket, noCollisionConstraint, attachment0, attachment1 =
				createConstraints(sourceLimb, affectedLimb, cframe0, cframe1, blueprint)

			table.insert(sockets, socket)
			socket.Name = motor6D.Name
			socket.Parent = socketsFolder
			table.insert(noCollisionConstraints, noCollisionConstraint)
			noCollisionConstraint.Name = motor6D.Name
			noCollisionConstraint.Parent = noCollisionsFolder
			trove:Add(attachment0)
			trove:Add(attachment1)
		end

		return sockets, noCollisionConstraints
	end

	--@ignore
	function Ragdoll.new(character: Model, blueprint): Ragdoll
		local humanoid, humanoidRootPart, limbs, accessoryHandles, motor6Ds = getCharacterComponents(character)
		local trove = Trove.new()
		local constraintsFolder = trove:Add(Instance.new("Folder"))
		constraintsFolder.Name = "RagdollConstraints"
		local socketsFolder = Instance.new("Folder")
		socketsFolder.Name = "BallSocketConstraints"
		socketsFolder.Parent = constraintsFolder
		local noCollisionsfolder = Instance.new("Folder")
		noCollisionsfolder.Name = "NoCollisionConstraints"
		noCollisionsfolder.Parent = constraintsFolder
		constraintsFolder.Parent = character

		character:SetAttribute("Ragdolled", false)

		local sockets, noCollisionConstraints =
			setupLimbs(trove, motor6Ds, socketsFolder, noCollisionsfolder, blueprint)

		local self = constructRagdoll(
			character,
			humanoid,
			humanoidRootPart,
			limbs,
			accessoryHandles,
			motor6Ds,
			blueprint,
			trove,
			constraintsFolder,
			socketsFolder,
			noCollisionsfolder,
			sockets,
			noCollisionConstraints
		)

		blueprint.finalTouches(self)

		return self
	end
end

--@ignore
function Ragdoll.replicate(character: Model, blueprint): Ragdoll
	local humanoid, humanoidRootPart, limbs, accessoryHandles, motor6Ds = getCharacterComponents(character)
	local trove = Trove.new()

	local constraintsFolder = character:WaitForChild("RagdollConstraints")
	local socketsFolder = constraintsFolder:WaitForChild("BallSocketConstraints")
	local noCollisionConstraintsFolder = constraintsFolder:WaitForChild("NoCollisionConstraints")

	local self = constructRagdoll(
		character,
		humanoid,
		humanoidRootPart,
		limbs,
		accessoryHandles,
		motor6Ds,
		blueprint,
		trove,
		constraintsFolder,
		socketsFolder,
		noCollisionConstraintsFolder,
		socketsFolder:GetChildren(),
		noCollisionConstraintsFolder:GetChildren()
	)

	return self
end

--@ignore
function Ragdoll._activateRagdollPhysics(ragdoll, accessoryHandles, motor6Ds, limbs, noCollisionConstraints, sockets)
	if ragdoll._ragdolled then
		return
	end

	ragdoll._ragdolled = true
	ragdoll.Humanoid.WalkSpeed = 0
	ragdoll.Humanoid.AutoRotate = false
	ragdoll.Humanoid:ChangeState(Enum.HumanoidStateType.FallingDown)
	ragdoll.HumanoidRootPart.CanCollide = false
	ragdoll.HumanoidRootPart.CustomPhysicalProperties = ROOT_PART_PHYSICAL_PROPERTIES

	for _, handle in accessoryHandles do
		handle.CanCollide = false
		handle.CanTouch = false
		handle.Massless = true
	end

	for _, motor6D: Motor6D in motor6Ds do
		motor6D.Enabled = false
	end

	for _, limb in limbs do
		limb.CanCollide = true
		limb.CustomPhysicalProperties = LIMB_PHYSICAL_PROPERTIES
	end

	for _, constraint: Constraint in noCollisionConstraints do
		constraint.Enabled = true
	end

	for _, socket: Constraint in sockets do
		socket.Enabled = true
	end

	ragdoll.RagdollBegan:Fire()
end

--[=[
	Activates ragdoll physics.
]=]
function Ragdoll:activateRagdollPhysics()
	Ragdoll._activateRagdollPhysics(
		self,
		self._accessoryHandles,
		self._motor6Ds,
		self._limbs,
		self._noCollisionConstraints,
		self._sockets
	)
end

--[=[
	Activates ragdoll physics in low detail mode.
]=]
function Ragdoll:activateRagdollPhysicsLowDetail()
	Ragdoll._activateRagdollPhysics(
		self,
		self._accessoryHandles,
		self._lowDetailMotor6Ds,
		self._limbs,
		self._noCollisionConstraints,
		self._lowDetailModeSockets
	)
end

--[=[
	Deactivates ragdoll physics.
]=]
function Ragdoll:deactivateRagdollPhysics()
	if not self._ragdolled then
		return
	end

	self._ragdolled = false
	self._collapsed = false
	self.Humanoid.WalkSpeed = self._originalSettings[self.Humanoid].WalkSpeed
	self.Humanoid.AutoRotate = self._originalSettings[self.Humanoid].AutoRotate
	self.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	self.HumanoidRootPart.CanCollide = self._originalSettings[self.HumanoidRootPart].CanCollide
	self.HumanoidRootPart.CustomPhysicalProperties =
		self._originalSettings[self.HumanoidRootPart].CustomPhysicalProperties

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

	for _, constraint: Constraint in self._noCollisionConstraints do
		constraint.Enabled = false
	end

	for _, socket: Constraint in self._sockets do
		socket.Enabled = false
	end

	self.RagdollEnded:Fire()
end

--[=[
	Activates ragdoll physics, then deactivates it when the ragdoll has remained still.
]=]
function Ragdoll:collapse()
	if self._collapsed then
		return
	end

	self._collapsed = true
	self:activateRagdollPhysics()
	self.Collapsed:Fire()
end

--[=[
	Activates ragdoll physics in low detail mode, then deactivates it when the ragdoll has remained still.
]=]
function Ragdoll:collapseLowDetail()
	if self._collapsed then
		return
	end

	self._collapsed = true
	self:activateRagdollPhysicsLowDetail()
	self.Collapsed:Fire()
end

--[=[
	Anchors all of the ragdoll's BaseParts.
]=]
function Ragdoll:freeze()
	if self._frozen then
		return
	end
	self._frozen = true
	self.HumanoidRootPart.Anchored = true

	for _, part in self._limbs do
		part.Anchored = true
	end
end

--[=[
	Returns all of the ragdoll's BaseParts to their original settings.
]=]
function Ragdoll:unfreeze()
	if not self._frozen then
		return
	end
	self._frozen = false
	self.HumanoidRootPart.Anchored = self._originalSettings[self.HumanoidRootPart].Anchored

	for _, part in self._limbs do
		part.Anchored = self._originalSettings[part].Anchored
	end
end

--[=[
	Returns true if ragdoll physics is active on this ragdoll.
]=]
function Ragdoll:isRagdolled(): boolean
	return self._ragdolled
end

--[=[
	Returns true if the ragdoll has callapsed.
]=]
function Ragdoll:isCollapsed(): boolean
	return self._collapsed
end

--[=[
	Returns true if the ragdoll is frozen.
]=]
function Ragdoll:isFrozen(): boolean
	return self._frozen
end

--[=[
	Destroys the ragdoll.
]=]
function Ragdoll:destroy()
	self.Destroying:Fire()
	self._trove:Destroy()
end

--[=[
	@within Ragdoll
	@method Destroy
	Alias for destroy().
]=]
Ragdoll.Destroy = Ragdoll.destroy

export type Ragdoll = Types.Ragdoll

return Ragdoll
