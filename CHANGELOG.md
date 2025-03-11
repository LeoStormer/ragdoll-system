# Changelog

## 0.6.0
### Added

- Added support for Rigs that use the new AnimationConstraint in the avatar upgrade beta.

## 0.5.1
### Fixed

- Fixed error causing the system to fail when constructing Ragdolls.

## 0.5.0
### Changed

- Blueprints now describe ragdolls by their Motor6Ds rather than the limbs affected by them.
- Blueprint._lowDetailModeLimbs -> Blueprint._lowDetailModeJoints.
- Blueprint.numLimbs -> Blueprint.numJoints.

## 0.4.0
### Added

- Ragdoll.replicate(Model, Blueprint?), creates a ragdoll from a model that already has its constraints constructed.
- RagdollSystem.RagdollConstructed a signal that fires when a ragdoll is constructed by the RagdollFactory.
- RagdollSystem.replicateRagdoll(Model, Blueprint?)
- RagdollSystem.Blueprint a reference to the blueprint base class.
- RagdollSystem.setSystemSettings(SystemSettings)
- RagdollSystem.getSystemSettings()

### Removed

- ReplicatedRagdoll class
- RagdollSystem:addPlayerRagdoll(Player, Model)
- RagdollSystem:removePlayerRagdoll(Player)

### Changed

- Player ragdolls are now created, stored, and removed the same way npc ragdolls are.
- Ragdolls are now unfrozen and their physics deactivated when their humanoid exits the Dead state.

### Fixed

- Fixed a bug where if player spammed DeactivateRagdoll Remote after dying, the server could revive their character.
- Fixed a bug that caused a delay in freeing a collapsed ragdoll from the motion sensor loop.

## 0.3.5
### Fixed

- Fixed a bug where Ragdoll class was not treating Blueprint.lowDetailModeLimbs as an optional value.

## 0.3.4
### Fixed

- Updated ragdoll root part physical properties to use a valid density value to silence warning.

## 0.3.3
### Fixed

- Fixed a bug introduced in version 0.3.2 that caused a ragdoll's humanoid to constantly flip between Physics State and FallingDown state while ragdolled.

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
- RagdollFactory.wrap(Model, Blueprint?)

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