# supreme-couscous
Open Sourced, Typeslop ESP.

<p align="left">
  <img width="179" height="285" alt="full" src="https://github.com/user-attachments/assets/4a766bad-8a1c-4def-a075-75ff4cb6947a" />
  <img width="187" height="282" alt="dropshadow" src="https://github.com/user-attachments/assets/1006a0ac-4d36-4f4b-85e8-ee61ac4e1bb7" />
  <img width="1047" height="939" alt="image" src="https://github.com/user-attachments/assets/95c41b72-a715-438c-a82d-f9224c347b31" />

  <br>
  <span>full, dropshadow, skinned mesh preview ^^^^^^^^^^^^</span>
</p>


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
Works on npcs as well!!!
<center><img width="479" height="221" alt="image" src="https://github.com/user-attachments/assets/8a03df61-180b-4069-ade6-f227bd522f0d" /></center>

```lua
  for _, Humanoid in workspace:QueryDescendants("Humanoid") do
      local Character = Humanoid.Parent
  
      if Character:IsA("Model") and not Character:IsAncestorOf(Camera) and not Players:GetPlayerFromCharacter(Character) then
          ESP:Add({ Model = Character })
      end
  end
```
