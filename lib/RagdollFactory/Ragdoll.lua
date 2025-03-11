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
	._noCollisionConstraints { NoCollisionConstraint }.
	._sockets  { BallSocketConstraint }
	._limbs { BasePart } -- List of the Ragdoll's direct children BaseParts exluding the root part. 
	._accessoryHandles { BasePart }
	._joints { Motor6D | AnimationConstraint } 
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
BALLSOCKETCONSTRAINT_TEMPLATE.LimitsEnabled = true
BALLSOCKETCONSTRAINT_TEMPLATE.TwistLimitsEnabled = true
Ragdoll.BALLSOCKETCONSTRAINT_TEMPLATE = BALLSOCKETCONSTRAINT_TEMPLATE

local NOCOLLISIONCONSTRAINT_TEMPLATE: NoCollisionConstraint = Instance.new("NoCollisionConstraint")
NOCOLLISIONCONSTRAINT_TEMPLATE.Enabled = false
Ragdoll.NOCOLLISIONCONSTRAINT_TEMPLATE = NOCOLLISIONCONSTRAINT_TEMPLATE

local ACCEPTABLE_RAGDOLL_STATES = {
	[Enum.HumanoidStateType.Dead] = true,
	[Enum.HumanoidStateType.Physics] = true,
}

function recordOriginalSettings(
	humanoid: Humanoid,
	humanoidRootPart: BasePart,
	limbs: { BasePart },
	accessoryHandles: { BasePart },
	joints: { Joint },
	ballSocketConstraints: { BallSocketConstraint },
	noCollisionConstraints: { NoCollisionConstraint }
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

	for _, joint in joints do
		originalSettings[joint] = { Enabled = joint.Enabled }
	end

	for _, ballSocketConstraint in ballSocketConstraints do
		originalSettings[ballSocketConstraint] = {
			Enabled = ballSocketConstraint.Enabled,
			Attachment0 = ballSocketConstraint.Attachment0,
			Attachment1 = ballSocketConstraint.Attachment1,
		}
	end

	for _, noCollisionConstraint in noCollisionConstraints do
		originalSettings[noCollisionConstraint] = { Enabled = noCollisionConstraint.Enabled }
	end

	return originalSettings
end

function constructRagdoll(
	character: Model,
	humanoid: Humanoid,
	humanoidRootPart: BasePart,
	limbs: { BasePart },
	accessoryHandles: { BasePart },
	joints: { Joint },
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

	local originalSettings = recordOriginalSettings(
		humanoid,
		humanoidRootPart,
		limbs,
		accessoryHandles,
		joints,
		sockets,
		noCollisionConstraints
	)

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
		_joints = joints,
		_lowDetailModeSockets = if blueprint.lowDetailModeJoints
			then TableUtils.filter(sockets, function(socket)
				local jointName = string.gsub(socket.Name, "BallSocket", "")
				return blueprint.lowDetailModeJoints[jointName]
			end)
			else sockets,
		_lowDetailJoints = if blueprint.lowDetailModeJoints
			then TableUtils.filter(joints, function(joint)
				return blueprint.lowDetailModeJoints[joint.Name]
			end)
			else joints,
	}, Ragdoll)

	trove:Connect(humanoid.StateChanged, function(old, new)
		if old == Enum.HumanoidStateType.Dead then
			ragdoll:unfreeze()
			ragdoll:deactivateRagdollPhysics()
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
	local descendants = character:GetDescendants()

	local limbs = TableUtils.filter(children, function(limb)
		return limb:IsA("BasePart") and limb.Name ~= "HumanoidRootPart"
	end)

	local accessoryHandles = TableUtils.map(
		TableUtils.filter(children, function(accessory)
			return accessory:IsA("Accessory")
		end),
		function(accessory)
			return accessory:FindFirstChild("Handle")
		end
	)

	local joints = TableUtils.filter(descendants, function(motor)
		return motor:IsA("Motor6D") or motor:IsA("AnimationConstraint")
	end) :: { Joint }

	local ballSocketConstraints = TableUtils.filter(descendants, function(socket)
		return socket:IsA("BallSocketConstraint")
	end)

	local noCollisionConstraints = TableUtils.filter(descendants, function(constraint)
		return constraint:IsA("NoCollisionConstraint")
	end)

	return humanoid, humanoidRootPart, limbs, accessoryHandles, joints, ballSocketConstraints, noCollisionConstraints
end

do
	local function createNoCollisionConstraint(joint: Joint, limb0: BasePart, limb1: BasePart)
		local noCollisionConstraint = Ragdoll.NOCOLLISIONCONSTRAINT_TEMPLATE:Clone()
		noCollisionConstraint.Name = `{joint.Name}NoCollision`
		noCollisionConstraint.Part0 = limb0
		noCollisionConstraint.Part1 = limb1
		return noCollisionConstraint
	end

	local function createBallSocketConstraint(
		joint: Joint,
		attachment0: Attachment,
		attachment1: Attachment,
		socketSetting: Types.SocketSetting
	)
		local socket = Ragdoll.BALLSOCKETCONSTRAINT_TEMPLATE:Clone()
		socket.Name = `{joint.Name}BallSocket`
		socket.Attachment0 = attachment0
		socket.Attachment1 = attachment1

		if socketSetting ~= nil then
			for key, value in socketSetting do
				if socket[key] then
					socket[key] = value
				end
			end
		end

		return socket
	end

	local function getMotor6DAttachment0(motor: Motor6D)
		local _, attachment: Attachment? = TableUtils.find((motor.Part0 :: BasePart):GetChildren(), function(inst)
			return inst:IsA("Attachment") and inst.CFrame == motor.C0
		end)
		return attachment
	end

	local function getMotor6DAttachment1(motor: Motor6D)
		local _, attachment: Attachment? = TableUtils.find((motor.Part1 :: BasePart):GetChildren(), function(inst)
			return inst:IsA("Attachment") and inst.CFrame == motor.C1
		end)
		return attachment
	end

	local function setupLimbs(
		trove,
		joints: { Joint },
		socketsFolder: Folder,
		noCollisionsFolder: Folder,
		blueprint: Types.Blueprint,
		sockets: { BallSocketConstraint },
		noCollisionConstraints: { NoCollisionConstraint }
	)
		for _, joint in joints do
			local _, noCollisionConstraint = TableUtils.find(noCollisionConstraints, function(constraint)
				return string.match(constraint.Name, joint.Name) ~= nil
			end)
			local limb0 = if joint:IsA("Motor6D") then joint.Part0 else (joint.Attachment0 :: Attachment).Parent
			local limb1 = if joint:IsA("Motor6D") then joint.Part1 else (joint.Attachment1 :: Attachment).Parent
			if noCollisionConstraint == nil then
				noCollisionConstraint = createNoCollisionConstraint(joint, limb0, limb1)
				table.insert(noCollisionConstraints, noCollisionConstraint)
				noCollisionConstraint.Parent = noCollisionsFolder
			end

			local _, ballSocketConstraint = TableUtils.find(sockets, function(constraint)
				return string.match(constraint.Name, joint.Name) ~= nil
			end)
			local override = blueprint.cframeOverrides[joint.Name]
			if ballSocketConstraint == nil then
				local attachment0 = if joint:IsA("AnimationConstraint")
					then joint.Attachment0
					else getMotor6DAttachment0(joint)
				if override or attachment0 == nil then
					-- override == nil and attachment == nil if and only if joint was a motor6D and no attachment was found whose CFrame matches joint.C0
					attachment0 = Instance.new("Attachment")
					attachment0.CFrame = if override then override.C0 else joint.C0
					attachment0.Parent = limb0
					trove:Add(attachment0)
				end

				local attachment1 = if joint:IsA("AnimationConstraint")
					then joint.Attachment1
					else getMotor6DAttachment1(joint)
				if override or attachment1 == nil then
					-- same story as above
					attachment1 = Instance.new("Attachment")
					attachment1.CFrame = if override then override.C1 else joint.C1
					attachment1.Parent = limb1
					trove:Add(attachment1)
				end

				ballSocketConstraint =
					createBallSocketConstraint(joint, attachment0, attachment1, blueprint.socketSettings[joint.Name])
				table.insert(sockets, ballSocketConstraint)
				ballSocketConstraint.Parent = socketsFolder
			end
		end

		return sockets, noCollisionConstraints
	end

	--@ignore
	function Ragdoll.new(character: Model, blueprint): Ragdoll
		local humanoid, humanoidRootPart, limbs, accessoryHandles, joints, sockets, noCollisionConstraints =
			getCharacterComponents(character)
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
		sockets, noCollisionConstraints =
			setupLimbs(trove, joints, socketsFolder, noCollisionsfolder, blueprint, sockets, noCollisionConstraints)

		local self = constructRagdoll(
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
			sockets,
			noCollisionConstraints
		)

		blueprint.finalTouches(self)

		return self
	end
end

--@ignore
function Ragdoll.replicate(character: Model, blueprint): Ragdoll
	local constraintsFolder = character:WaitForChild("RagdollConstraints")
	local socketsFolder = constraintsFolder:WaitForChild("BallSocketConstraints")
	local noCollisionConstraintsFolder = constraintsFolder:WaitForChild("NoCollisionConstraints")

	local humanoid, humanoidRootPart, limbs, accessoryHandles, joints, ballSocketConstraints, noCollisionConstraints =
		getCharacterComponents(character)
	local trove = Trove.new()

	local self = constructRagdoll(
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
	)

	return self
end

--@ignore
function Ragdoll._activateRagdollPhysics(
	ragdoll,
	accessoryHandles,
	joints: { Joint },
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
function Ragdoll:_insertNoCollisionConstraint(limb0, limb1)
	local noCollisionConstraint = Ragdoll.NOCOLLISIONCONSTRAINT_TEMPLATE:Clone()
	noCollisionConstraint.Part0 = limb0
	noCollisionConstraint.Part1 = limb1
	table.insert(self._noCollisionConstraints, noCollisionConstraint)
	noCollisionConstraint.Name = `{limb0.Name}{limb1.Name}NoCollision`
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

type Joint = AnimationConstraint | Motor6D

export type Ragdoll = Types.Ragdoll

return Ragdoll
