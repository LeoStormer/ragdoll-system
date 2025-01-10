local Blueprint = require(script.Parent.Parent.Blueprint)
local Ragdoll = require(script.Parent.Ragdoll)

local UPPER_ARM_SOCKET_SETTINGS =
	{ MaxFrictionTorque = 150, UpperAngle = 50, TwistLowerAngle = -70, TwistUpperAngle = 160 }
local LOWER_ARM_SOCKET_SETTINGS =
	{ MaxFrictionTorque = 150, UpperAngle = 0, TwistLowerAngle = -5, TwistUpperAngle = 95 }
local UPPER_LEG_SOCKET_SETTINGS =
	{ MaxFrictionTorque = 150, UpperAngle = 40, TwistLowerAngle = -45, TwistUpperAngle = 45 }
local LOWER_LEG_SOCKET_SETTINGS =
	{ MaxFrictionTorque = 150, UpperAngle = 0, TwistLowerAngle = -80, TwistUpperAngle = 5 }
local HANDS_FEET_SOCKET_SETTINGS =
	{ MaxFrictionTorque = 50, UpperAngle = 10, TwistLowerAngle = -45, TwistUpperAngle = 5 }

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
		Head = { MaxFrictionTorque = 150, UpperAngle = 45, TwistLowerAngle = -30, TwistUpperAngle = 30 },
		UpperTorso = { MaxFrictionTorque = 50, UpperAngle = 20, TwistLowerAngle = -10, TwistUpperAngle = 30 },
		LowerTorso = { MaxFrictionTorque = 50, UpperAngle = 20, TwistLowerAngle = 0, TwistUpperAngle = 30 },

		RightUpperArm = UPPER_ARM_SOCKET_SETTINGS,
		LeftUpperArm = UPPER_ARM_SOCKET_SETTINGS,

		RightLowerArm = LOWER_ARM_SOCKET_SETTINGS,
		LeftLowerArm = LOWER_ARM_SOCKET_SETTINGS,

		RightUpperLeg = UPPER_LEG_SOCKET_SETTINGS,
		LeftUpperLeg = UPPER_LEG_SOCKET_SETTINGS,

		RightLowerLeg = LOWER_LEG_SOCKET_SETTINGS,
		LeftLowerLeg = LOWER_LEG_SOCKET_SETTINGS,

		RightHand = HANDS_FEET_SOCKET_SETTINGS,
		LeftHand = HANDS_FEET_SOCKET_SETTINGS,
		RightFoot = HANDS_FEET_SOCKET_SETTINGS,
		LeftFoot = HANDS_FEET_SOCKET_SETTINGS,
	},
	lowDetailModeLimbs = {
		Head = true,
		RightUpperArm = true,
		LeftUpperArm = true,
		RightUpperLeg = true,
		LeftUpperLeg = true,
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
