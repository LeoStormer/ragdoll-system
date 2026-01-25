-- Credit to Rookstun and the Ragdoll Solution: https://devforum.roblox.com/t/ragdoll-solution-r15customizable-ragdolls-for-use-with-layered-clothing/1738685
-- local RunService = game:GetService("RunService")

local Types = require(script.Parent.Parent.Types)
local Trove = require(script.Parent.Parent.Parent.Trove)
local RagdollBuilder = require(script.RagdollBuilder)

--[=[
	@class Ragdoll
	@__index Ragdoll
	This class wraps around a Model and enables ragdoll physics by finding or
	creating physics constraints for it based on a [Blueprint]. The [Model] must
	contain a [Humanoid], a HumanoidRootPart, and have [Motor6D] or
	[AnimationConstraint] descendants as joints.
]=]
--[=[
	@within Ragdoll
	@private
	@prop _constraintsFolder Folder
	The root container for the ragdoll's internally created constraints.
]=]
--[=[
	@within Ragdoll
	@private
	@prop _noCollisionConstraintsFolder Folder
	The folder containing all internally created NoCollisionConstraints.
]=]
--[=[
	@within Ragdoll
	@private
	@prop _socketFolder Folder
	The folder containing all internally created BallSocketConstraints.
]=]
--[=[
	@within Ragdoll
	@private
	@prop _noCollisionConstraints { NoCollisionConstraint }
]=]
--[=[
	@within Ragdoll
	@private
	@prop _sockets { BallSocketConstraint }
]=]
--[=[
	@within Ragdoll
	@private
	@prop _limbs { BasePart }
	Array of the Ragdoll's direct children BaseParts exluding the root part.
]=]
--[=[
	@within Ragdoll
	@private
	@prop _accessoryHandles { BasePart }
]=]
--[=[
	@within Ragdoll
	@private
	@prop _joints { AnimationConstraint | Motor6D }
]=]
--[=[
	@within Ragdoll
	@readonly
	@prop Character Model
	The model this ragdoll wraps.
]=]
--[=[
	@within Ragdoll
	@readonly
	@prop Humanoid Humanoid
	The Humanoid descendant of this Ragdoll's Character.
]=]
--[=[
	@within Ragdoll
	@readonly
	@prop HumanoidRootPart BasePart
	The root part of this Ragdoll's Character.
]=]
--[=[
	@within Ragdoll
	@readonly
	@prop RagdollBegan Signal
	
	A signal fired when ragdoll physics has begun.

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
	@prop Collapsed Signal
	A signal fired when ragdoll:collapse() is called.
]=]
--[=[
	@within Ragdoll
	@readonly
	@prop Destroying Signal
	A signal fired when ragdoll:destroy() is called.
]=]

local LIMB_PHYSICAL_PROPERTIES = PhysicalProperties.new(5, 0.7, 0.5, 100, 100)
local ROOT_PART_PHYSICAL_PROPERTIES = PhysicalProperties.new(0.01, 0, 0, 0, 0)

local Ragdoll = {}
Ragdoll.__index = Ragdoll

local ACCEPTABLE_RAGDOLL_STATES = {
	[Enum.HumanoidStateType.Dead] = true,
	[Enum.HumanoidStateType.Physics] = true,
}

local function connectEvents(trove, ragdoll)
	trove:Connect(ragdoll.Humanoid.StateChanged, function(old, new)
		if old == Enum.HumanoidStateType.Dead then
			ragdoll:unfreeze()
			ragdoll:deactivateRagdollPhysics()
		end

		if not ragdoll:isRagdolled() then
			return
		end

		if new == Enum.HumanoidStateType.FallingDown then
			ragdoll.Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		elseif not ACCEPTABLE_RAGDOLL_STATES[new] then
			ragdoll.Humanoid:ChangeState(Enum.HumanoidStateType.FallingDown)
		end
	end)

	ragdoll.RagdollBegan:Connect(function()
		ragdoll.Character:SetAttribute("Ragdolled", true)
	end)

	ragdoll.RagdollEnded:Connect(function()
		ragdoll.Character:SetAttribute("Ragdolled", false)
	end)

	trove:Connect(ragdoll.Character.Destroying, function()
		ragdoll:destroy()
	end)
end

--@ignore
function Ragdoll.new(character: Model, blueprint: Types.Blueprint): Ragdoll
	character:SetAttribute("Ragdolled", false)
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

	local humanoid, humanoidRootPart, limbs, accessoryHandles, joints, ballSocketConstraints, noCollisionConstraints =
		RagdollBuilder.getCharacterComponents(character)
	ballSocketConstraints, noCollisionConstraints = RagdollBuilder.buildLimbs(
		trove,
		joints,
		socketsFolder,
		noCollisionsfolder,
		blueprint,
		ballSocketConstraints,
		noCollisionConstraints
	)

	local self = setmetatable(
		RagdollBuilder.constructRagdoll(
			character,
			humanoid,
			humanoidRootPart,
			limbs,
			accessoryHandles,
			joints,
			blueprint,
			trove,
			constraintsFolder,
			socketsFolder,
			noCollisionsfolder,
			ballSocketConstraints,
			noCollisionConstraints
		),
		Ragdoll
	)
	connectEvents(trove, self)
	blueprint.finalTouches(self)

	return self
end

--@ignore
function Ragdoll.replicate(character: Model, blueprint): Ragdoll
	local trove = Trove.new()
	local constraintsFolder = character:WaitForChild("RagdollConstraints")
	local socketsFolder = constraintsFolder:WaitForChild("BallSocketConstraints")
	local noCollisionConstraintsFolder = constraintsFolder:WaitForChild("NoCollisionConstraints")

	local humanoid, humanoidRootPart, limbs, accessoryHandles, joints, ballSocketConstraints, noCollisionConstraints =
		RagdollBuilder.getCharacterComponents(character)

	local self = setmetatable(
		RagdollBuilder.constructRagdoll(
			character,
			humanoid,
			humanoidRootPart,
			limbs,
			accessoryHandles,
			joints,
			blueprint,
			trove,
			constraintsFolder,
			socketsFolder,
			noCollisionConstraintsFolder,
			ballSocketConstraints,
			noCollisionConstraints
		),
		Ragdoll
	)
	connectEvents(trove, self)

	return self
end

--@ignore
function Ragdoll._activateRagdollPhysics(
	ragdoll,
	accessoryHandles,
	joints: { Types.Joint },
	limbs,
	noCollisionConstraints,
	sockets
)
	if ragdoll._ragdolled then
		return
	end

	ragdoll._ragdolled = true
	ragdoll.Humanoid.WalkSpeed = 0
	ragdoll.Humanoid.AutoRotate = false
	if ragdoll.Humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
		ragdoll.Humanoid:ChangeState(Enum.HumanoidStateType.FallingDown)
	end
	ragdoll.HumanoidRootPart.CanCollide = false
	ragdoll.HumanoidRootPart.CustomPhysicalProperties = ROOT_PART_PHYSICAL_PROPERTIES

	for _, handle in accessoryHandles do
		handle.CanCollide = false
		handle.CanTouch = false
		handle.Massless = true
	end

	for _, joint in joints do
		joint.Enabled = false
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
	@private
	Inserts a NoCollisionConstraint into the ragdoll. Used to fine-tune the ragdoll's limb collisions. 
]=]
function Ragdoll:_insertNoCollisionConstraint(limb0: BasePart, limb1: BasePart)
	local noCollisionConstraint =
		RagdollBuilder.createNoCollisionConstraint(`{limb0.Name}{limb1.Name}NoCollision`, limb0, limb1)
	table.insert(self._noCollisionConstraints, noCollisionConstraint)
	noCollisionConstraint.Parent = self._noCollisionConstraintFolder
	self._originalSettings[noCollisionConstraint] = { Enabled = false }
end

--[=[
	Activates ragdoll physics.
]=]
function Ragdoll:activateRagdollPhysics()
	Ragdoll._activateRagdollPhysics(
		self,
		self._accessoryHandles,
		self._joints,
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
		self._lowDetailJoints,
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

	for _, joint: Motor6D in self._joints do
		joint.Enabled = self._originalSettings[joint].Enabled
	end

	for _, limb in self._limbs do
		limb.CanCollide = self._originalSettings[limb].CanCollide
		limb.CustomPhysicalProperties = self._originalSettings[limb].CustomPhysicalProperties
	end

	for _, constraint: Constraint in self._noCollisionConstraints do
		constraint.Enabled = self._originalSettings[constraint].Enabled
	end

	for _, socket: Constraint in self._sockets do
		socket.Enabled = self._originalSettings[socket].Enabled
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
