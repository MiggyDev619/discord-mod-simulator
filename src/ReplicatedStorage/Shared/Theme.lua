-- ReplicatedStorage/Shared/Theme
-- Central brand palette + semantic colors. All Color3 references in UI / HUD code
-- should pull from here so a future rebrand is a single-file edit.
-- Status-effect colors on enemy parts and particle bursts are intentionally NOT
-- here — those live with their handlers because they're gameplay feedback, not brand.

local Theme = {}

-- Brand
Theme.Yellow400 = Color3.fromRGB(250, 204, 21)   -- main brand, headings, accents
Theme.Yellow300 = Color3.fromRGB(253, 224, 71)   -- softer highlight, hover
Theme.Yellow500 = Color3.fromRGB(234, 179, 8)    -- darker yellow, pressed states

-- Base
Theme.Zinc950 = Color3.fromRGB(9, 9, 11)         -- dark UI backgrounds
Theme.Zinc50  = Color3.fromRGB(250, 250, 250)    -- light text on dark bg

-- Status (run-end overlays + status text)
Theme.RedWarn  = Color3.fromRGB(239, 68, 68)     -- SERVER DEAD
Theme.GreenWin = Color3.fromRGB(34, 197, 94)     -- VICTORY

-- Health bar (semantic — % thresholds in ClientMain)
Theme.HealthGreen  = Color3.fromRGB(60, 200, 80)
Theme.HealthYellow = Color3.fromRGB(240, 210, 50)
Theme.HealthRed    = Color3.fromRGB(220, 60, 60)

-- Currency (semantic — coins always read gold)
Theme.CurrencyGold  = Color3.fromRGB(255, 215, 0)
Theme.CurrencyFlash = Color3.fromRGB(255, 255, 180)

return Theme
