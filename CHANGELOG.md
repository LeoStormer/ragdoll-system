# Changelog

## 0.3.2
### Fixed

- Fixed bug where humanoid would leave Physics state if ragdoll was activated from being smacked while in the air.

## 0.3.1
### Fixed

- Fixed bug where walking animation would break when movement input was pressed before deactivating ragdoll physics.
- Fixed bug where fall animation would play while ragdolled if ragdoll physics was activated during humanoid Jumping state.

## 0.3.0
### Changed

- Ragdolls are now automatically created on the client as well as the server.
- After a threshold of ragdolls are activated at once, any more ragdolls activated are activated in low detail mode.
- Renamed Blueprint.numConstraints to Blueprint.numLimbs.

### Added

- Added Ragdoll.Destroying a signal that fires when ragdoll:Destroy() is called.
- Added Low Detail Mode:
  - Ragdoll.activateRagdollPhysicsLowDetail()
  - Ragdoll.collapseLowDetail()

## 0.2.0
### Changed

- Automatically create ragdolls on models tagged "Ragdoll" instead of "NPCRagdoll".
- Renamed BaseRagdoll Class to Ragdoll.
- Renamed R15Ragdoll to R15RagdollBlueprint.
- Renamed R6Ragdoll to R6RagdollBlueprint.

### Added

- Added RagdollSystem.RagdollFactory a reference to the ragdoll factory.
- Added methods to RagdollSystem:
  - addRagdoll(Model)
  - removeRagdoll(Model)
  - getRagdoll(Model)
  - activateRagdoll(Model)
  - deactivateRagdoll(Model)
  - collapseRagdoll(Model)
  - addPlayerRagdoll(Player)
  - removePlayerRagdoll(Player)
  - getPlayerRagdoll(Player)
  - getLocalRagdoll()
  - setLocalRagdoll(Ragdoll)
  - activateLocalRagdoll()
  - deactivateLocalRagdoll()
  - collapseLocalRagdoll()
- Added Ragdoll.Collapsed a signal that fires when a ragdoll collapses.
- Added methods to Ragdoll:
  - isRagdolled()
  - isCollapsed()
  - isFrozen()
- Added Blueprints which allow custom characters to be described and have ragdolls constructed for them.
- Added RagdollFactory.addBlueprint(blueprint).
- Added RagdollFactory.RagdollConstructed a signal that fires when a ragdoll is constructed.

### Fixed
- Fix bug where models would lose their heads in experiences with immediate mode signal behavior.

## 0.1.0

- Initial Release