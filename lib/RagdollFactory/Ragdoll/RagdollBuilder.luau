--!strict
local RagdollBuilder = {}

local BALLSOCKETCONSTRAINT_TEMPLATE = Instance.new("BallSocketConstraint")
BALLSOCKETCONSTRAINT_TEMPLATE.Enabled = false
BALLSOCKETCONSTRAINT_TEMPLATE.LimitsEnabled = true
BALLSOCKETCONSTRAINT_TEMPLATE.TwistLimitsEnabled = true
local NOCOLLISIONCONSTRAINT_TEMPLATE = Instance.new("NoCollisionConstraint")
NOCOLLISIONCONSTRAINT_TEMPLATE.Enabled = false

local TableUtils = require(script.Parent.Parent.Parent.TableUtils)
local Types = require(script.Parent.Parent.Parent.Types)
local Signal = require(script.Parent.Parent.Parent.Parent.Signal)

local function getAttachment0(joint: Types.Joint): Attachment?
	if joint:IsA("AnimationConstraint") then
		assert(joint.Attachment0 ~= nil, `Attachment0 not found for AnimationConstraint {joint}`)
		return joint.Attachment0
	end

	assert(joint.Part0 ~= nil, `Given motor6D {joint} does not have a part0`)
	-- local attachment = joint.Part0:QueryDescendants(`Attachment[CFrame = {joint.C0}]`)[1] -- this just errors with: Expected ']' to complete a property filter
	local _, attachment: Attachment? = TableUtils.find(joint.Part0:QueryDescendants("Attachment"), function(inst)
		return inst.CFrame == joint.C0
	end)

	return (attachment :: any) :: Attachment?
end

local function getAttachment1(joint: Types.Joint): Attachment?
	if joint:IsA("AnimationConstraint") then
		assert(joint.Attachment1 ~= nil, `Attachment1 not found for AnimationConstraint {joint}`)
		return joint.Attachment1
	end

	assert(joint.Part1 ~= nil, `Given motor6D {joint} does not have a part0`)
	local _, attachment: Attachment? = TableUtils.find(joint.Part1:QueryDescendants("Attachment"), function(inst)
		return inst.CFrame == joint.C1
	end)

	return (attachment :: any) :: Attachment?
end

function RagdollBuilder.createNoCollisionConstraint(name: string, limb0: BasePart, limb1: BasePart)
	local noCollisionConstraint = NOCOLLISIONCONSTRAINT_TEMPLATE:Clone()
	noCollisionConstraint.Name = name
	noCollisionConstraint.Part0 = limb0
	noCollisionConstraint.Part1 = limb1
	return noCollisionConstraint
end

function RagdollBuilder.createBallSocketConstraint(
	name: string,
	attachment0: Attachment,
	attachment1: Attachment,
	socketSetting: Types.SocketSetting?
)
	local socket = BALLSOCKETCONSTRAINT_TEMPLATE:Clone()
	socket.Name = name
	socket.Attachment0 = attachment0
	socket.Attachment1 = attachment1

	if socketSetting ~= nil then
		socket.MaxFrictionTorque = socketSetting.MaxFrictionTorque
		socket.TwistLowerAngle = socketSetting.TwistLowerAngle
		socket.TwistUpperAngle = socketSetting.TwistUpperAngle
		socket.UpperAngle = socketSetting.UpperAngle
	end

	return socket
end

function RagdollBuilder.recordOriginalSettings(
	humanoid: Humanoid,
	humanoidRootPart: BasePart,
	limbs: { BasePart },
	accessoryHandles: { BasePart },
	joints: { Types.Joint },
	ballSocketConstraints: { BallSocketConstraint },
	noCollisionConstraints: { NoCollisionConstraint }
)
	local originalSettings = {} :: any
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
		}
	end

	for _, noCollisionConstraint in noCollisionConstraints do
		originalSettings[noCollisionConstraint] = { Enabled = noCollisionConstraint.Enabled }
	end

	return originalSettings
end

function RagdollBuilder.getCharacterComponents(character: Model)
	local humanoid = character:WaitForChild("Humanoid")
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	local limbs = character:QueryDescendants("> BasePart:not(#HumanoidRootPart)")
	local accessoryHandles = character:QueryDescendants("> Accessory > BasePart#Handle")
	local joints = character:QueryDescendants("Motor6D, AnimationConstraint")
	local ballSocketConstraints = character:QueryDescendants("BallSocketConstraint")
	local noCollisionConstraints = character:QueryDescendants("NoCollisionConstraint")

	return humanoid, humanoidRootPart, limbs, accessoryHandles, joints, ballSocketConstraints, noCollisionConstraints
end

function RagdollBuilder.buildLimbs(
	trove,
	joints: { Types.Joint },
	socketsFolder: Folder,
	noCollisionsFolder: Folder,
	blueprint: Types.Blueprint,
	sockets: { BallSocketConstraint },
	noCollisionConstraints: { NoCollisionConstraint }
)
	for _, joint in joints do
		local limb0 = (
			if joint:IsA("Motor6D") then joint.Part0 else (joint.Attachment0 :: Attachment).Parent
		) :: BasePart
		local limb1 = (
			if joint:IsA("Motor6D") then joint.Part1 else (joint.Attachment1 :: Attachment).Parent
		) :: BasePart

		local _, noCollisionConstraint = TableUtils.find(noCollisionConstraints, function(constraint)
			return string.match(constraint.Name, joint.Name) ~= nil
		end)
		if noCollisionConstraint == nil then
			noCollisionConstraint = RagdollBuilder.createNoCollisionConstraint(`{joint.Name}NoCollision`, limb0, limb1)
			table.insert(noCollisionConstraints, noCollisionConstraint)
			noCollisionConstraint.Parent = noCollisionsFolder
		end

		local _, ballSocketConstraint = TableUtils.find(sockets, function(constraint)
			return string.match(constraint.Name, joint.Name) ~= nil
		end)

		if ballSocketConstraint == nil then
			local override = blueprint.cframeOverrides[joint.Name]
			local attachment0 = getAttachment0(joint)
			if override or attachment0 == nil then
				-- attachment0 == nil if and only if joint was a motor6D and no attachment was found whose CFrame matches joint.C0
				local overrideAttachment = Instance.new("Attachment")
				overrideAttachment.CFrame = if override then override.C0 else (joint :: Motor6D).C0
				overrideAttachment.Parent = limb0
				trove:Add(overrideAttachment)
				attachment0 = overrideAttachment
			end

			local attachment1 = getAttachment1(joint)
			if override or attachment1 == nil then
				-- same story as above
				local overrideAttachment = Instance.new("Attachment")
				overrideAttachment.CFrame = if override then override.C1 else (joint :: Motor6D).C1
				overrideAttachment.Parent = limb1
				trove:Add(overrideAttachment)
				attachment1 = overrideAttachment
			end

			ballSocketConstraint = RagdollBuilder.createBallSocketConstraint(
				`{joint.Name}BallSocket`,
				attachment0 :: Attachment,
				attachment1 :: Attachment,
				blueprint.socketSettings[joint.Name]
			)
			table.insert(sockets, ballSocketConstraint)
			ballSocketConstraint.Parent = socketsFolder
		end
	end

	return sockets, noCollisionConstraints
end

function RagdollBuilder.constructRagdoll(
	character: Model,
	humanoid: Humanoid,
	humanoidRootPart: BasePart,
	limbs: { BasePart },
	accessoryHandles: { BasePart },
	joints: { Types.Joint },
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

	local originalSettings = RagdollBuilder.recordOriginalSettings(
		humanoid,
		humanoidRootPart,
		limbs,
		accessoryHandles,
		joints,
		sockets,
		noCollisionConstraints
	)

	local ragdoll = {
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
	}

	return ragdoll
end

return RagdollBuilder
