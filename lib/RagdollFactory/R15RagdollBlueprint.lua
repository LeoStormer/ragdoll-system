local Blueprint = require(script.Parent.Parent.Blueprint)

local SHOULDER_SOCKET_SETTINGS =
	{ MaxFrictionTorque = 150, UpperAngle = 50, TwistLowerAngle = -70, TwistUpperAngle = 160 }
local ELBOW_SOCKET_SETTINGS = { MaxFrictionTorque = 150, UpperAngle = 0, TwistLowerAngle = -5, TwistUpperAngle = 95 }
local HIP_SOCKET_SETTINGS = { MaxFrictionTorque = 150, UpperAngle = 40, TwistLowerAngle = -45, TwistUpperAngle = 45 }
local KNEE_SOCKET_SETTINGS = { MaxFrictionTorque = 150, UpperAngle = 0, TwistLowerAngle = -80, TwistUpperAngle = 5 }
local WRIST_SOCKET_SETTINGS = { MaxFrictionTorque = 50, UpperAngle = 10, TwistLowerAngle = -45, TwistUpperAngle = 5 }
local ANKLE_SOCKET_SETTINGS = { MaxFrictionTorque = 50, UpperAngle = 10, TwistLowerAngle = -45, TwistUpperAngle = 5 }

local R15RagdollBlueprint = setmetatable({
	numJoints = 15, -- number of constraints created on an R15 Rig, this number was tested for.
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
	local isAvatarUpgrade = ragdoll.Character.Head.Neck:IsA("AnimationConstraint")
	if isAvatarUpgrade then
		return
	end

	ragdoll:_insertNoCollisionConstraint(ragdoll.Character.RightFoot, ragdoll.Character.RightUpperLeg)
	ragdoll:_insertNoCollisionConstraint(ragdoll.Character.RightUpperLeg, ragdoll.Character.UpperTorso)
	ragdoll:_insertNoCollisionConstraint(ragdoll.Character.RightLowerLeg, ragdoll.Character.UpperTorso)
	ragdoll:_insertNoCollisionConstraint(ragdoll.Character.LeftFoot, ragdoll.Character.LeftUpperLeg)
	ragdoll:_insertNoCollisionConstraint(ragdoll.Character.LeftUpperLeg, ragdoll.Character.UpperTorso)
	ragdoll:_insertNoCollisionConstraint(ragdoll.Character.LeftLowerLeg, ragdoll.Character.UpperTorso)
	ragdoll:_insertNoCollisionConstraint(ragdoll.Character.LeftHand, ragdoll.Character.LeftUpperArm)
	ragdoll:_insertNoCollisionConstraint(ragdoll.Character.RightHand, ragdoll.Character.RightUpperArm)
end

return R15RagdollBlueprint :: Blueprint.Blueprint
