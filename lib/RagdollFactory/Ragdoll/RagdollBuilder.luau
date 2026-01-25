local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TableUtils = require(ReplicatedStorage.Packages.RagdollSystem.TableUtils)
local Types = require(ReplicatedStorage.Packages.RagdollSystem.Types)
local Signal = require(ReplicatedStorage.Packages.Signal)

local RagdollBuilder = {}

local BALLSOCKETCONSTRAINT_TEMPLATE: BallSocketConstraint = Instance.new("BallSocketConstraint")
BALLSOCKETCONSTRAINT_TEMPLATE.Enabled = false
BALLSOCKETCONSTRAINT_TEMPLATE.LimitsEnabled = true
BALLSOCKETCONSTRAINT_TEMPLATE.TwistLimitsEnabled = true
local NOCOLLISIONCONSTRAINT_TEMPLATE: NoCollisionConstraint = Instance.new("NoCollisionConstraint")
NOCOLLISIONCONSTRAINT_TEMPLATE.Enabled = false

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
	socketSetting: Types.SocketSetting
)
	local socket = BALLSOCKETCONSTRAINT_TEMPLATE:Clone()
	socket.Name = name
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

function RagdollBuilder.recordOriginalSettings(
	humanoid: Humanoid,
	humanoidRootPart: BasePart,
	limbs: { BasePart },
	accessoryHandles: { BasePart },
	joints: { Types.Joint },
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
	end) :: { Types.Joint }

	local ballSocketConstraints = TableUtils.filter(descendants, function(socket)
		return socket:IsA("BallSocketConstraint")
	end)

	local noCollisionConstraints = TableUtils.filter(descendants, function(constraint)
		return constraint:IsA("NoCollisionConstraint")
	end)

	return humanoid, humanoidRootPart, limbs, accessoryHandles, joints, ballSocketConstraints, noCollisionConstraints
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
		local limb0 = if joint:IsA("Motor6D") then joint.Part0 else (joint.Attachment0 :: Attachment).Parent
		local limb1 = if joint:IsA("Motor6D") then joint.Part1 else (joint.Attachment1 :: Attachment).Parent

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
			local attachment0 = if joint:IsA("AnimationConstraint")
				then joint.Attachment0
				else getMotor6DAttachment0(joint)
			if override or attachment0 == nil then
				-- attachment0 == nil if and only if joint was a motor6D and no attachment was found whose CFrame matches joint.C0
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

			ballSocketConstraint = RagdollBuilder.createBallSocketConstraint(
				`{joint.Name}BallSocket`,
				attachment0,
				attachment1,
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
