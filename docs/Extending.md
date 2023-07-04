# Extending the System

So you want to create a different type of ragdoll than R15 or R6? No problem create a [Blueprint](/api/Blueprint) and add it to the RagdollFactory.


```lua title="MyBlueprint.lua"
    local MyBlueprint = {}
    MyBlueprint.numConstraints = 38 --Test it, create a ragdoll with your blueprint, print(#ragdoll._constraints) and replace 38 with the number you get.
    MyBlueprint.socketSettings = {} --The keys are names of BaseParts in your model.
    MyBlueprint.cframeOverrides = {} --The keys are names of BaseParts in your model.

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
