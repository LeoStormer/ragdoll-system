--# selene: allow(unused_variable)
local Types = require(script.Parent.Types)
--[=[
    @class Blueprint
    @__index Blueprint
]=]
--[=[
	@within Blueprint
	@interface SocketSettings
	.MaxFrictionTorque number
	.UpperAngle number
	.TwistLowerAngle number
	.TwistUpperAngle number
]=]
--[=[
	@within Blueprint
	@type SocketSettingsDictionary {[string] = SocketSetting}
	Each string must refer to a Motor6D within the character this blueprint describes.
]=]
--[=[
	@within Blueprint
	@type CFrameOverrides {[string] = {C0: CFrame, C1: CFrame}
	Each string must refer to a Motor6D within the character this blueprint describes.
]=]
--[=[
	@within Blueprint
	@prop numJoints number?
	Number of joints your character model has
	:::tip

	Putting an accurate number can improve the performance of ragdoll construction slightly, although it isn't necessary.
	
	:::
]=]
--[=[
    @within Blueprint
    @prop socketSettings SocketSettingsDictionary
    Used to describe the range of motion of each joint within the ragdoll.
]=]
--[=[
    @within Blueprint
    @prop cframeOverrides CFrameOverrides?
    Used to change how joints connect their parts on the ragdoll.
    For example, in the R6 blueprint the shoulders are overridden to attach the Arms to the Torso the same way the Upper Arms are attached to the Upper Torso in R15 Characters.
]=]
--[=[
	@within Blueprint
	@prop lowDetailModeJoints { [string]: boolean }?
	Describes which Joints will be activated in low detail mode.
]=]
local Blueprint = {}
Blueprint.__index = Blueprint
Blueprint.numJoints = 15
Blueprint.socketSettings = {}
Blueprint.cframeOverrides = {}

--[=[
    @within Blueprint
    @function satisfiesRequirements
    @param model Model
    @return boolean
    Returns whether the model can be properly constructed by this blueprint.
]=]
function Blueprint.satisfiesRequirements(model: Model)
	error(`satisfiesRequirements() must be defined`)
end

--[=[
    @param ragdoll Ragdoll & RagdollInternals
    Apply final touches to the ragdoll. For example, in the R15 blueprint some extra NoCollisionConstraints are added to make the ragdoll physics flow smoother.
]=]
function Blueprint.finalTouches(ragdoll: Types.Ragdoll & Types.RagdollInternals) end

export type Blueprint = Types.Blueprint

return Blueprint
