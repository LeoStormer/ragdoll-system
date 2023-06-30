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

local SOCKET_SETTINGS = {
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
}

function setupCollisionConstraints(ragdoll)
	local noCollisionConstraint1 = Ragdoll._addConstraint(ragdoll, Ragdoll.NOCOLLISIONCONSTRAINT_TEMPLATE:Clone())
	noCollisionConstraint1.Part0 = ragdoll.Character.RightFoot
	noCollisionConstraint1.Part1 = ragdoll.Character.RightUpperLeg

	local noCollisionConstraint2 = Ragdoll._addConstraint(ragdoll, Ragdoll.NOCOLLISIONCONSTRAINT_TEMPLATE:Clone())
	noCollisionConstraint2.Part0 = ragdoll.Character.RightUpperLeg
	noCollisionConstraint2.Part1 = ragdoll.Character.UpperTorso

	local noCollisionConstraint3 = Ragdoll._addConstraint(ragdoll, Ragdoll.NOCOLLISIONCONSTRAINT_TEMPLATE:Clone())
	noCollisionConstraint3.Part0 = ragdoll.Character.RightLowerLeg
	noCollisionConstraint3.Part1 = ragdoll.Character.UpperTorso

	local noCollisionConstraint4 = Ragdoll._addConstraint(ragdoll, Ragdoll.NOCOLLISIONCONSTRAINT_TEMPLATE:Clone())
	noCollisionConstraint4.Part0 = ragdoll.Character.LeftFoot
	noCollisionConstraint4.Part1 = ragdoll.Character.LeftUpperLeg

	local noCollisionConstraint5 = Ragdoll._addConstraint(ragdoll, Ragdoll.NOCOLLISIONCONSTRAINT_TEMPLATE:Clone())
	noCollisionConstraint5.Part0 = ragdoll.Character.LeftUpperLeg
	noCollisionConstraint5.Part1 = ragdoll.Character.UpperTorso

	local noCollisionConstraint6 = Ragdoll._addConstraint(ragdoll, Ragdoll.NOCOLLISIONCONSTRAINT_TEMPLATE:Clone())
	noCollisionConstraint6.Part0 = ragdoll.Character.LeftLowerLeg
	noCollisionConstraint6.Part1 = ragdoll.Character.UpperTorso

	local noCollisionConstraint7 = Ragdoll._addConstraint(ragdoll, Ragdoll.NOCOLLISIONCONSTRAINT_TEMPLATE:Clone())
	noCollisionConstraint7.Part0 = ragdoll.Character.LeftHand
	noCollisionConstraint7.Part1 = ragdoll.Character.LeftUpperArm

	local noCollisionConstraint8 = Ragdoll._addConstraint(ragdoll, Ragdoll.NOCOLLISIONCONSTRAINT_TEMPLATE:Clone())
	noCollisionConstraint8.Part0 = ragdoll.Character.RightHand
	noCollisionConstraint8.Part1 = ragdoll.Character.RightUpperArm
end

function setupLimbs(ragdoll)
	for _, motor6D: Motor6D in ragdoll._motor6Ds do
		local sourcePart = motor6D.Part0
		local affectedLimb = motor6D.Part1
		local cframe0 = motor6D.C0
		local cframe1 = motor6D.C1
		Ragdoll._setupLimb(ragdoll, SOCKET_SETTINGS, sourcePart, affectedLimb, cframe0, cframe1)
	end
end

local NUM_CONSTRAINTS = 38 -- number of constraints created on an R15 Rig, this number was tested for.

local R15RagdollBlueprint = {}

function R15RagdollBlueprint.satisfiesRequirements(model: Model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	return if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then true else false
end

function R15RagdollBlueprint.construct(character): Ragdoll
	local self = Ragdoll.new(character, NUM_CONSTRAINTS)
	setupCollisionConstraints(self)
	setupLimbs(self)

	self._trove:Connect(self.Humanoid.Died, function()
		self:collapse()
	end)

	self._trove:Connect(character:GetAttributeChangedSignal("Ragdolled"), function()
		if character:GetAttribute("Ragdolled") then
			self:activateRagdollPhysics()
		else
			self:deactivateRagdollPhysics()
		end
	end)

	return self
end

export type Ragdoll = Ragdoll.Ragdoll

return R15RagdollBlueprint
