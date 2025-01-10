local Blueprint = require(script.Parent.Blueprint)
local Signal = require(script.Parent.Parent.Signal)
local Ragdoll = require(script.Ragdoll)
local R15RagdollBlueprint = require(script.R15RagdollBlueprint)
local R6RagdollBlueprint = require(script.R6RagdollBlueprint)

--[=[
	@class RagdollFactory
	@__index RagdollFactory
]=]
local RagdollFactory = {}
RagdollFactory._blueprints = {}
RagdollFactory._blueprintAdded = Signal.new()

--[=[
	@within RagdollFactory
	@readonly
	@prop RagdollConstructed Signal
	Fires when a ragdoll is constructed by the factory.

	```lua
	RagdollFactory.RagdollConstructed:Connect(function(ragdoll: Ragdoll)
		-- Do ragdoll things...
	end)
	```
]=]
RagdollFactory.RagdollConstructed = Signal.new()

function getMatchingBlueprint(model: Model, blueprintOverride: Blueprint?): Blueprint?
	if blueprintOverride and blueprintOverride.satisfiesRequirements(model) then
		return blueprintOverride
	else
		for _, backupBlueprint: Blueprint in RagdollFactory._blueprints do
			if backupBlueprint.satisfiesRequirements(model) then
				return backupBlueprint
			end
		end
	end

	return nil
end

--[=[
	Constructs a ragdoll from a model that satisfies any of its blueprints. Returns nil if no blueprint is satisfied.
]=]
function RagdollFactory.new(model: Model, blueprintOverride: Blueprint?): Ragdoll?
	local blueprint = getMatchingBlueprint(model, blueprintOverride)
	if blueprint then
		local ragdoll = Ragdoll.new(model, blueprint)
		RagdollFactory.RagdollConstructed:Fire(ragdoll)
		return ragdoll
	end

	return nil
end

--[=[
	@client
	Creates a Ragdoll from a model that already has its Constraints constructed. Used to replicate a ragdoll across server -> client boundary.
]=]
function RagdollFactory.wrap(ragdollModel: Model, blueprintOverride: Blueprint?): Ragdoll?
	local blueprint = getMatchingBlueprint(ragdollModel, blueprintOverride)
	if blueprint then
		local ragdoll = Ragdoll.replicate(ragdollModel, blueprint)
		RagdollFactory.RagdollConstructed:Fire(ragdoll)
		return ragdoll
	end

	return nil
end

--[=[
	Adds a blueprint to the factory. Retroactively updates all existing ragdolls to this type of ragdoll if they satisfy its requirements.
]=]
function RagdollFactory.addBlueprint(blueprint: Blueprint)
	table.insert(RagdollFactory._blueprints, 1, blueprint)
	RagdollFactory._blueprintAdded:Fire(blueprint)
end

export type Ragdoll = Ragdoll.Ragdoll
export type Blueprint = Blueprint.Blueprint

RagdollFactory.addBlueprint(R6RagdollBlueprint)
RagdollFactory.addBlueprint(R15RagdollBlueprint)

return RagdollFactory
