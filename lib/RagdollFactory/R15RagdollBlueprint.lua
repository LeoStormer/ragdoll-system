local Blueprint = require(script.Parent.Parent.Blueprint)
local Ragdoll = require(script.Parent.Ragdoll)

local SHOULDER_SOCKET_SETTINGS =
	{ MaxFrictionTorque = 150, UpperAngle = 50, TwistLowerAngle = -70, TwistUpperAngle = 160 }
local ELBOW_SOCKET_SETTINGS = { MaxFrictionTorque = 150, UpperAngle = 0, TwistLowerAngle = -5, TwistUpperAngle = 95 }
local HIP_SOCKET_SETTINGS = { MaxFrictionTorque = 150, UpperAngle = 40, TwistLowerAngle = -45, TwistUpperAngle = 45 }
local KNEE_SOCKET_SETTINGS = { MaxFrictionTorque = 150, UpperAngle = 0, TwistLowerAngle = -80, TwistUpperAngle = 5 }
local WRIST_SOCKET_SETTINGS = { MaxFrictionTorque = 50, UpperAngle = 10, TwistLowerAngle = -45, TwistUpperAngle = 5 }
local ANKLE_SOCKET_SETTINGS = { MaxFrictionTorque = 50, UpperAngle = 10, TwistLowerAngle = -45, TwistUpperAngle = 5 }

function insertNoCollisionConstraint(ragdoll, limb0, limb1)
	local noCollisionConstraint = Ragdoll.NOCOLLISIONCONSTRAINT_TEMPLATE:Clone()
	noCollisionConstraint.Part0 = limb0
	noCollisionConstraint.Part1 = limb1
	table.insert(ragdoll._noCollisionConstraints, noCollisionConstraint)
	noCollisionConstraint.Parent = ragdoll._noCollisionConstraintFolder
end

function setupCollisionConstraints(ragdoll)
	insertNoCollisionConstraint(ragdoll, ragdoll.Character.RightFoot, ragdoll.Character.RightUpperLeg)
	insertNoCollisionConstraint(ragdoll, ragdoll.Character.RightUpperLeg, ragdoll.Character.UpperTorso)
	insertNoCollisionConstraint(ragdoll, ragdoll.Character.RightLowerLeg, ragdoll.Character.UpperTorso)
	insertNoCollisionConstraint(ragdoll, ragdoll.Character.LeftFoot, ragdoll.Character.LeftUpperLeg)
	insertNoCollisionConstraint(ragdoll, ragdoll.Character.LeftUpperLeg, ragdoll.Character.UpperTorso)
	insertNoCollisionConstraint(ragdoll, ragdoll.Character.LeftLowerLeg, ragdoll.Character.UpperTorso)
	insertNoCollisionConstraint(ragdoll, ragdoll.Character.LeftHand, ragdoll.Character.LeftUpperArm)
	insertNoCollisionConstraint(ragdoll, ragdoll.Character.RightHand, ragdoll.Character.RightUpperArm)
end

local R15RagdollBlueprint = setmetatable({
	numLimbs = 15, -- number of constraints created on an R15 Rig, this number was tested for.
	socketSettings = {
		Neck = { MaxFrictionTorque = 150, UpperAngle = 45, TwistLowerAngle = -30, TwistUpperAngle = 30 },
		Waist = { MaxFrictionTorque = 50, UpperAngle = 20, TwistLowerAngle = -10, TwistUpperAngle = 30 },
		Root = { MaxFrictionTorque = 50, UpperAngle = 20, TwistLowerAngle = 0, TwistUpperAngle = 30 },

		RightShoulder = SHOULDER_SOCKET_SETTINGS,
		LeftShoulder = SHOULDER_SOCKET_SETTINGS,

		RightElbow = ELBOW_SOCKET_SETTINGS,
		LeftElbow = ELBOW_SOCKET_SETTINGS,

		RightHip = HIP_SOCKET_SETTINGS,
		LeftHip = HIP_SOCKET_SETTINGS,

		RightKnee = KNEE_SOCKET_SETTINGS,
		LeftKnee = KNEE_SOCKET_SETTINGS,

		RightWrist = WRIST_SOCKET_SETTINGS,
		LeftWrist = WRIST_SOCKET_SETTINGS,

		RightAnkle = ANKLE_SOCKET_SETTINGS,
		LeftAnkle = ANKLE_SOCKET_SETTINGS,
	},
	lowDetailModeJoints = {
		Neck = true,
		Root = true,
		RightShoulder = true,
		LeftShoulder = true,
		RightHip = true,
		LeftHip = true,
	},
}, Blueprint)

function R15RagdollBlueprint.satisfiesRequirements(model: Model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	return if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then true else false
end

function R15RagdollBlueprint.finalTouches(ragdoll)
	setupCollisionConstraints(ragdoll)
end

return R15RagdollBlueprint :: Blueprint.Blueprint
