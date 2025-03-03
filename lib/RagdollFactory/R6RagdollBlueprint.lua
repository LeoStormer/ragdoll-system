local Blueprint = require(script.Parent.Parent.Blueprint)

local SHOULDER_SOCKET_SETTINGS =
	{ MaxFrictionTorque = 150, UpperAngle = 50, TwistLowerAngle = -70, TwistUpperAngle = 160 }
local HIP_SOCKET_SETTINGS = { MaxFrictionTorque = 150, UpperAngle = 40, TwistLowerAngle = -60, TwistUpperAngle = 80 }
local RIGHT_SHOULDER_ATTACHMENT_CFRAME0 = CFrame.new(1, 0.763, 0)
local RIGHT_SHOULDER_ATTACHMENT_CFRAME1 = CFrame.new(-0.5, 0.763, 0)
local LEFT_SHOULDER_ATTACHMENT_CFRAME0 = CFrame.new(-1, 0.763, 0)
local LEFT_SHOULDER_ATTACHMENT_CFRAME1 = CFrame.new(0.5, 0.763, -0)
local RIGHT_HIP_ATTACHMENT_CFRAME0 = CFrame.new(0.5, -1, -0)
local LEFT_HIP_ATTACHMENT_CFRAME0 = CFrame.new(-0.5, -1, -0)
local HIP_ATTACHMENT_CFRAME1 = CFrame.new(0, 1, 0)

local R6RagdollBlueprint = setmetatable({
	numLimbs = 6, -- number of constraints created on an R6 Rig, this number was tested for
	socketSettings = {
		Neck = { MaxFrictionTorque = 150, UpperAngle = 45, TwistLowerAngle = -30, TwistUpperAngle = 30 },
		RootJoint = { MaxFrictionTorque = 50, UpperAngle = 20, TwistLowerAngle = 0, TwistUpperAngle = 30 },
		["Right Shoulder"] = SHOULDER_SOCKET_SETTINGS,
		["Left Shoulder"] = SHOULDER_SOCKET_SETTINGS,
		["Right Hip"] = HIP_SOCKET_SETTINGS,
		["Left Hip"] = HIP_SOCKET_SETTINGS,
	},
	cframeOverrides = {
		["Right Shoulder"] = { C0 = RIGHT_SHOULDER_ATTACHMENT_CFRAME0, C1 = RIGHT_SHOULDER_ATTACHMENT_CFRAME1 },
		["Left Shoulder"] = { C0 = LEFT_SHOULDER_ATTACHMENT_CFRAME0, C1 = LEFT_SHOULDER_ATTACHMENT_CFRAME1 },
		["Right Hip"] = { C0 = RIGHT_HIP_ATTACHMENT_CFRAME0, C1 = HIP_ATTACHMENT_CFRAME1 },
		["Left Hip"] = { C0 = LEFT_HIP_ATTACHMENT_CFRAME0, C1 = HIP_ATTACHMENT_CFRAME1 },
	},
}, Blueprint)

function R6RagdollBlueprint.satisfiesRequirements(model: Model): boolean
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	return if humanoid and humanoid.RigType == Enum.HumanoidRigType.R6 then true else false
end

return R6RagdollBlueprint :: Blueprint.Blueprint
