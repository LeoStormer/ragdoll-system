# Extending the System

So you want to create a different type of ragdoll than R15 or R6? No problem create a [Blueprint](/api/Blueprint) and add it to the RagdollFactory.


```lua title="MyBlueprint.lua"
    local MyBlueprint = {}
    MyBlueprint.numLimbs = 15
    MyBlueprint.socketSettings = {} --The keys are names of Parts in your model e.g. RightHand, UpperTorso, or Head.
    MyBlueprint.cframeOverrides = {} --The keys are names of Parts in your model.

    function MyBlueprint.satisfiesRequirements(model: Model): boolean
        --How can we tell that model satisfies my blueprint?
    end

    function MyBlueprint.finalTouches(ragdoll: Ragdoll)
        --Do something with ragdoll, or don't, ragdoll won't mind.
    end

    return MyBlueprint
```

```lua title="Main"
local MyBlueprint = require(path.to.MyBlueprint)
local RagdollFactory = require(path.to.RagdollSystem).RagdollFactory
RagdollFactory.addBlueprint(MyBlueprint)
```
