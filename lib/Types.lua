local Signal = require(script.Parent.Parent.Signal)

export type SystemSettings = {
	LowDetailModeThreshold: number?,
	CollapseTimeoutInterval: number?,
	CollapseTimeoutDistanceThreshold: number?,
	FreezeIfDead: boolean?,
}

export type RagdollInternals = {
	_constraintsFolder: Folder,
	_noCollisionConstraintFolder: Folder,
	_socketFolder: Folder,
	_sockets: { BallSocketConstraint },
	_noCollisionConstraints: { NoCollisionConstraint },
	_limbs: { BasePart },
	_accessoryHandles: { BasePart },
	_joints: { Motor6D | AnimationConstraint },
	_insertNoCollisionConstraint: (self: RagdollInternals, limb0: BasePart, limb2: BasePart) -> (),
}

export type Ragdoll = {
	Character: Model,
	Humanoid: Humanoid,
	HumanoidRootPart: BasePart,
	RagdollBegan: Signal.Signal<()>,
	RagdollEnded: Signal.Signal<()>,
	Collapsed: Signal.Signal<()>,
	Destroying: Signal.Signal<()>,
	isRagdolled: (self: Ragdoll) -> boolean,
	isCollapsed: (self: Ragdoll) -> boolean,
	isFrozen: (self: Ragdoll) -> boolean,
	activateRagdollPhysics: (self: Ragdoll) -> (),
	activateRagdollPhysicsLowDetail: (self: Ragdoll) -> (),
	deactivateRagdollPhysics: (self: Ragdoll) -> (),
	collapse: (self: Ragdoll) -> (),
	collapseLowDetail: (self: Ragdoll) -> (),
	freeze: (self: Ragdoll) -> (),
	unfreeze: (self: Ragdoll) -> (),
	destroy: (self: Ragdoll) -> (),
	Destroy: (self: Ragdoll) -> (),
}

export type SocketSetting = {
	MaxFrictionTorque: number,
	UpperAngle: number,
	TwistLowerAngle: number,
	TwistUpperAngle: number,
}

export type Blueprint = {
	numJoints: number,
	socketSettings: { [string]: SocketSetting },
	cframeOverrides: { [string]: { C0: CFrame, C1: CFrame } },
	lowDetailModeJoints: { [string]: boolean }?,
	satisfiesRequirements: (Model) -> boolean,
	finalTouches: (RagdollInternals & Ragdoll) -> (),
}

local Types = {}

return Types
