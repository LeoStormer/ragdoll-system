local Ragdoll = require(script.Parent.Ragdoll)

local ARM_SOCKET_SETTINGS = { MaxFrictionTorque = 150, UpperAngle = 50, TwistLowerAngle = -70, TwistUpperAngle = 160 }
local LEG_SOCKET_SETTINGS = { MaxFrictionTorque = 150, UpperAngle = 40, TwistLowerAngle = -60, TwistUpperAngle = 80 }

local SOCKET_SETTINGS = {
	Head = { MaxFrictionTorque = 150, UpperAngle = 45, TwistLowerAngle = -30, TwistUpperAngle = 30 },
	Torso = { MaxFrictionTorque = 50, UpperAngle = 20, TwistLowerAngle = 0, TwistUpperAngle = 30 },
	["Right Arm"] = ARM_SOCKET_SETTINGS,
	["Left Arm"] = ARM_SOCKET_SETTINGS,
	["Right Leg"] = LEG_SOCKET_SETTINGS,
	["Left Leg"] = LEG_SOCKET_SETTINGS,
}

local RIGHT_SHOULDER_ATTACHMENT_CFRAME0 = CFrame.new(1, 0.763, 0)
local RIGHT_SHOULDER_ATTACHMENT_CFRAME1 = CFrame.new(-0.5, 0.763, 0)
local LEFT_SHOULDER_ATTACHMENT_CFRAME0 = CFrame.new(-1, 0.763, 0)
local LEFT_SHOULDER_ATTACHMENT_CFRAME1 = CFrame.new(0.5, 0.763, -0)
local RIGHT_HIP_ATTACHMENT_CFRAME0 = CFrame.new(0.5, -1, -0)
local LEFT_HIP_ATTACHMENT_CFRAME0 = CFrame.new(-0.5, -1, -0)
local HIP_ATTACHMENT_CFRAME1 = CFrame.new(0, 1, 0)

function setupLimbs(ragdoll)
	local torso = ragdoll.Character.Torso
	local rootJoint: Motor6D = ragdoll.HumanoidRootPart.RootJoint
	Ragdoll._setupLimb(ragdoll, SOCKET_SETTINGS, ragdoll.HumanoidRootPart, torso, rootJoint.C0, rootJoint.C1)

	local head = ragdoll.Character.Head
	local neckJoint: Motor6D = torso.Neck
	Ragdoll._setupLimb(ragdoll, SOCKET_SETTINGS, torso, head, neckJoint.C0, neckJoint.C1)

	local rightArm = ragdoll.Character["Right Arm"]
	Ragdoll._setupLimb(
		ragdoll,
		SOCKET_SETTINGS,
		torso,
		rightArm,
		RIGHT_SHOULDER_ATTACHMENT_CFRAME0,
		RIGHT_SHOULDER_ATTACHMENT_CFRAME1
	)

	local leftArm = ragdoll.Character["Left Arm"]
	Ragdoll._setupLimb(
		ragdoll,
		SOCKET_SETTINGS,
		torso,
		leftArm,
		LEFT_SHOULDER_ATTACHMENT_CFRAME0,
		LEFT_SHOULDER_ATTACHMENT_CFRAME1
	)

	local rightLeg = ragdoll.Character["Right Leg"]
	Ragdoll._setupLimb(ragdoll, SOCKET_SETTINGS, torso, rightLeg, RIGHT_HIP_ATTACHMENT_CFRAME0, HIP_ATTACHMENT_CFRAME1)

	local leftLeg = ragdoll.Character["Left Leg"]
	Ragdoll._setupLimb(ragdoll, SOCKET_SETTINGS, torso, leftLeg, LEFT_HIP_ATTACHMENT_CFRAME0, HIP_ATTACHMENT_CFRAME1)
end

local NUM_CONSTRAINTS = 14 -- number of constraints created on an R6 Rig

local R6RagdollBlueprint = {}

function R6RagdollBlueprint.satisfiesRequirements(model: Model): boolean
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	return if humanoid and humanoid.RigType == Enum.HumanoidRigType.R6 then true else false
end

function R6RagdollBlueprint.construct(character): Ragdoll
	local self = setmetatable(Ragdoll.new(character, NUM_CONSTRAINTS), Ragdoll)
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

return R6RagdollBlueprint
