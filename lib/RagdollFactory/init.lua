local Signal = require(script.Parent.Parent.Signal)
local Ragdoll = require(script.Ragdoll)
local R15RagdollBlueprint = require(script.R15RagdollBlueprint)
local R6RagdollBlueprint = require(script.R6RagdollBlueprint)

--[=[
	@within RagdollFactory
	@interface Blueprint
	.satisfiesRequirements (Model) -> boolean
	.construct (Model) -> Ragdoll 
]=]
--[=[
	@class RagdollFactory
	@__index RagdollFactory
]=]
--[=[
	@within RagdollFactory
	@private
	@readonly
	@prop BlueprintAdded
]=]
local RagdollFactory = {}
RagdollFactory._blueprints = {}
RagdollFactory.BlueprintAdded = Signal.new()

--[=[
	Constructs a ragdoll from a model that satisfies any of its blueprints. Returns nil if no blueprint is satisfied.
]=]
function RagdollFactory.new(model: Model): Ragdoll?
	for _, blueprint: Blueprint in RagdollFactory._blueprints do
		if blueprint.satisfiesRequirements(model) then
			return blueprint.construct(model)
		end
	end

	return nil
end

--[=[
	Adds a blueprint to the factory. Retroactively updates all existing ragdolls to this type of ragdoll if they satisfy its requirements.
]=]
function RagdollFactory.addBlueprint(blueprint: Blueprint)
	table.insert(RagdollFactory._blueprints, 1, blueprint)
	RagdollFactory.BlueprintAdded:Fire(blueprint)
end

export type Ragdoll = Ragdoll.Ragdoll
export type Blueprint = {
	construct: (Model) -> Ragdoll,
	satisfiesRequirements: (Model) -> boolean,
}

RagdollFactory.addBlueprint(R6RagdollBlueprint)
RagdollFactory.addBlueprint(R15RagdollBlueprint)

return RagdollFactory
