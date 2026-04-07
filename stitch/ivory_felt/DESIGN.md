# Design System Strategy: The Grand Salon

## 1. Overview & Creative North Star
**The Creative North Star: "The Modern Croupier"**
This design system moves away from the flashing lights of "cheap" digital gambling and toward the hushed, high-stakes atmosphere of an exclusive private salon. The aesthetic is defined by **Tactile Minimalism**—where the interface feels like premium physical equipment.

We break the "standard app" template by utilizing a "center-weighted" layout that mimics a physical tabletop. Instead of rigid sidebar-and-header grids, we use intentional asymmetry, generous negative space, and a scale of typography that feels more like an editorial magazine than a mobile game.

---

## 2. Colors: Tonal Depth
Our palette is rooted in the "Table Green" tradition but elevated through a dark-mode-first implementation.

### The "No-Line" Rule
**Standard borders are strictly prohibited.** To section off the UI, use background shifts. A `surface-container-low` card sitting on a `surface` background provides all the definition a user needs. If you feel the urge to draw a line, increase the spacing instead.

### Surface Hierarchy & Nesting
Treat the UI as physical layers of felt and ivory.
- **Base Layer:** `surface` (#131313) for the deep background.
- **The Table:** `primary-container` (#1a472a) for the main play area.
- **The Equipment:** `surface-container-highest` (#353535) for player cards and dice trays.

### Signature Textures: The "Glass & Gradient" Rule
To add "soul," use a subtle radial gradient on the main game board, transitioning from `primary` (#a1d2ab) at the center to `primary-container` (#1a472a) at the edges. For floating overlays (Modals/Toasts), use **Glassmorphism**: 
- `surface-container` at 80% opacity with a 16px backdrop-blur.

---

## 3. Typography: The Editorial Voice
We pair the intellectual weight of a serif with the clinical precision of a modern sans-serif.

| Level | Token | Font Family | Size | Character |
| :--- | :--- | :--- | :--- | :--- |
| **Display** | `display-lg` | Newsreader | 3.5rem | High-contrast, elegant, "The Win" |
| **Headline** | `headline-md` | Newsreader | 1.75rem | Section headers, "Player 1 Turn" |
| **Title** | `title-lg` | Manrope | 1.375rem | Bold, utilitarian labels |
| **Body** | `body-lg` | Manrope | 1rem | Gameplay instructions |
| **Label** | `label-md` | Manrope | 0.75rem | Metadata and dice stats |

*Usage Note: Use Newsreader for anything "Expressive" (Scores, Winner names) and Manrope for anything "Functional" (Settings, Odds, Button text).*

---

## 4. Elevation & Depth
We eschew traditional drop shadows for **Tonal Layering**.

- **The Layering Principle:** Place a `surface-container-lowest` card on a `surface-container-low` section. The slight shift in value creates a natural "recessed" or "raised" effect without visual clutter.
- **Ambient Shadows:** For floating elements (Dice in flight), use an extra-diffused shadow: `box-shadow: 0 20px 40px rgba(0,0,0,0.3)`. The shadow color should never be pure black; it should be a darkened tint of the background green.
- **The Ghost Border:** For accessibility on interactive inputs, use a 1px border of `outline-variant` (#414942) at **20% opacity**. It should be felt, not seen.

---

## 5. Components

### Dice Elements & Icons
- **Style:** Not flat, not skeuomorphic. Use `surface-container-highest` for the die body and `on-secondary-container` (#6d5000) for the pips.
- **Radius:** Use `md` (0.375rem) to mimic the feel of premium casino dice.

### Buttons
- **Primary:** `primary` background with `on-primary` text. No border. Radius: `xl` (0.75rem) for a friendly, pill-like feel.
- **Secondary:** `surface-container-highest` background. Use a subtle gradient to `surface-variant`.
- **States:** On `hover`, increase the `surface-bright` value. On `active`, shift to `primary-fixed-dim`.

### Player Cards & Score Panels
- **Constraint:** **No Dividers.**
- **Implementation:** Group information using the 8px spacing grid. Use `title-sm` for the player name and `display-sm` (Newsreader) for the score. Use `surface-container-low` as the base card.

### Connection Banners & Toasts
- **Disconnected:** `error-container` background with a glassmorphism blur. 
- **Success:** `primary-container` with an `amber` (#ffbf00) accent glow.

### Status Chips
- Use `full` radius (9999px). For "Waiting" states, use `surface-variant`. For "Active" states, use `secondary-container` with `on-secondary-container` text.

---

## 6. Global States

1.  **Normal:** The standard high-contrast, clean tabletop.
2.  **Loading:** Use a skeleton state where the "bones" of the UI are `surface-container-high` with a subtle pulse.
3.  **Empty:** Use `display-md` typography in `outline` color (low contrast) to fill the space artistically—avoid "No Games Found" text in favor of "The table is currently clear."
4.  **Error/Disconnected:** Use the `tertiary` (#ffb3ac) tokens. These red/amber tones should feel like a warning light on a dashboard, high contrast against the green.

---

## 7. Do's and Don'ts

- **DO** use white space as your primary organizational tool.
- **DO** overlap elements (e.g., a Die slightly overlapping the edge of a Player Card) to create a sense of three-dimensional space.
- **DON'T** use 100% opaque black. Use `surface-container-lowest` (#0e0e0e).
- **DON'T** use purple. It breaks the "Grand Salon" palette.
- **DON'T** use sharp 90-degree corners. Everything should have at least the `sm` (2px) radius to feel handled and polished.