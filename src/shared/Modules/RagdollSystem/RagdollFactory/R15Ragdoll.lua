local BaseRagdoll = require(script.Parent.BaseRagdoll)
local UPPER_ARM_SOCKET_SETTINGS =
	{ MaxFrictionTorque = 150, UpperAngle = 90, TwistLowerAngle = -45, TwistUpperAngle = 45 }
local LOWER_ARM_SOCKET_SETTINGS =
	{ MaxFrictionTorque = 150, UpperAngle = 0, TwistLowerAngle = -5, TwistUpperAngle = 65 }
local UPPER_LEG_SOCKET_SETTINGS =
	{ MaxFrictionTorque = 150, UpperAngle = 40, TwistLowerAngle = -5, TwistUpperAngle = 20 }
local LOWER_LEG_SOCKET_SETTINGS =
	{ MaxFrictionTorque = 150, UpperAngle = 0, TwistLowerAngle = -45, TwistUpperAngle = 10 }
local HANDS_FEET_SOCKET_SETTINGS =
	{ MaxFrictionTorque = 50, UpperAngle = 10, TwistLowerAngle = -45, TwistUpperAngle = 25 }

local SOCKET_SETTINGS = {
	Head = { MaxFrictionTorque = 150, UpperAngle = 15, TwistLowerAngle = -15, TwistUpperAngle = 15 },
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
	local noCollisionConstraint1 =
		BaseRagdoll._addConstraint(ragdoll, BaseRagdoll.NOCOLLISIONCONSTRAINT_TEMPLATE:Clone())
	noCollisionConstraint1.Part0 = ragdoll.character.RightFoot
	noCollisionConstraint1.Part1 = ragdoll.character.RightUpperLeg

	local noCollisionConstraint2 =
		BaseRagdoll._addConstraint(ragdoll, BaseRagdoll.NOCOLLISIONCONSTRAINT_TEMPLATE:Clone())
	noCollisionConstraint2.Part0 = ragdoll.character.RightUpperLeg
	noCollisionConstraint2.Part1 = ragdoll.character.UpperTorso

	local noCollisionConstraint3 =
		BaseRagdoll._addConstraint(ragdoll, BaseRagdoll.NOCOLLISIONCONSTRAINT_TEMPLATE:Clone())
	noCollisionConstraint3.Part0 = ragdoll.character.RightLowerLeg
	noCollisionConstraint3.Part1 = ragdoll.character.UpperTorso

	local noCollisionConstraint4 =
		BaseRagdoll._addConstraint(ragdoll, BaseRagdoll.NOCOLLISIONCONSTRAINT_TEMPLATE:Clone())
	noCollisionConstraint4.Part0 = ragdoll.character.LeftFoot
	noCollisionConstraint4.Part1 = ragdoll.character.LeftUpperLeg

	local noCollisionConstraint5 =
		BaseRagdoll._addConstraint(ragdoll, BaseRagdoll.NOCOLLISIONCONSTRAINT_TEMPLATE:Clone())
	noCollisionConstraint5.Part0 = ragdoll.character.LeftUpperLeg
	noCollisionConstraint5.Part1 = ragdoll.character.UpperTorso

	local noCollisionConstraint6 =
		BaseRagdoll._addConstraint(ragdoll, BaseRagdoll.NOCOLLISIONCONSTRAINT_TEMPLATE:Clone())
	noCollisionConstraint6.Part0 = ragdoll.character.LeftLowerLeg
	noCollisionConstraint6.Part1 = ragdoll.character.UpperTorso

	local noCollisionConstraint7 =
		BaseRagdoll._addConstraint(ragdoll, BaseRagdoll.NOCOLLISIONCONSTRAINT_TEMPLATE:Clone())
	noCollisionConstraint7.Part0 = ragdoll.character.LeftHand
	noCollisionConstraint7.Part1 = ragdoll.character.LeftUpperArm

	local noCollisionConstraint8 =
		BaseRagdoll._addConstraint(ragdoll, BaseRagdoll.NOCOLLISIONCONSTRAINT_TEMPLATE:Clone())
	noCollisionConstraint8.Part0 = ragdoll.character.RightHand
	noCollisionConstraint8.Part1 = ragdoll.character.RightUpperArm
end

function setupLimbs(ragdoll)
	for _, limb in ragdoll.character:GetChildren() do
		for _, motor6D: Motor6D in limb:GetChildren() do
			if not motor6D:IsA("Motor6D") then
				continue
			end

			local sourcePart = motor6D.Part0
			local affectedLimb = motor6D.Part1
			local cframe0 = motor6D.C0
			local cframe1 = motor6D.C1
			BaseRagdoll._setupLimb(ragdoll, SOCKET_SETTINGS, sourcePart, affectedLimb, cframe0, cframe1)
		end
	end
end

local NUM_CONSTRAINTS = 38 -- number of constraints created on an R15 Rig, this number was tested for.

local R15Ragdoll = setmetatable({}, BaseRagdoll)
R15Ragdoll.__index = R15Ragdoll

function R15Ragdoll.new(character): BaseRagdoll.Ragdoll
	local self = setmetatable(BaseRagdoll.new(character, NUM_CONSTRAINTS), R15Ragdoll)
	setupCollisionConstraints(self)
	setupLimbs(self)

	self._trove:Connect(self.humanoid.Died, function()
		self:collapse()
	end)

	self._trove:Connect(character:GetAttributeChangedSignal("Ragdolled"), function()
		--the server has ragdolled us, we dont need to do anything other than manage the humanoid
		local ragdolled = character:GetAttribute("Ragdolled")
		if ragdolled == true then
			self:activateRagdollPhysics()
		else
			self:deactivateRagdollPhysics()
		end
		self.ragdolled = ragdolled
	end)

	return self
end

return R15Ragdoll
