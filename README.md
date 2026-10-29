# supreme-couscous
Open Sourced, Typeslop ESP.

```lua
local ESP = {
    Enabled = true, -- (master(psst'kashou') toggle)

    BoundingBox = { -- Draws a box around a player.
        Enabled     = true,

        ColorTop    = Color3.fromRGB(100, 100, 100), -- yes this is gradient slop, shut up.
        ColorBottom = Color3.fromRGB(255, 255, 255),

        Style       = "Full", -- You can pick "Full" or "Dropshadow".

        Filled = { -- Draws a frame inside the bounding box, filling the insides (ay bor wtf is this explanation)
            Enabled      = true,

            ColorTop     = Color3.fromRGB(100, 100, 100),
            ColorBottom  = Color3.fromRGB(255, 255, 255),

            Transparency = 0.5
        }
    },

    Name = { -- Draws a text above the bounding box, it represents the player's name.
        Enabled = true,
        Color   = Color3.fromRGB(255, 255, 255)
    },

    HealthBar = { -- 
        Enabled = true,

        ColorTop     = Color3.fromRGB(131, 245, 78),
        ColorMiddle  = Color3.fromRGB(255, 255, 0),
        ColorBottom  = Color3.fromRGB(252, 71, 77),

        Style        = "Full", -- You can pick "Full" or "Dropshadow".
        Thickness    = 2
    },
}
```
Preview:
<center> <img width="179" height="285" alt="image" src="https://github.com/user-attachments/assets/4a766bad-8a1c-4def-a075-75ff4cb6947a" /> </center>
