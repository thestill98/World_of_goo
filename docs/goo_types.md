# Goo Types — Reference

All types defined in `scripts/GooTypes.gd`.

| Type    | Color (hex)  | Detachable | Links (min/max) | Radius | Mass | Stiffness | Damping | Break ratio | Attach range | Special                  | Status               |
|---------|--------------|------------|-----------------|--------|------|-----------|---------|-------------|--------------|--------------------------|----------------------|
| common  | #242429 (black)  | No      | 2 / 2           | 12     | 1.0  | 100       | 0.8     | 1.9×        | 115          | —                        | Implemented          |
| ivy     | #449644 (green)  | Yes     | 1 / 2           | 10     | 0.7  | 120       | 0.7     | 1.45×       | 115          | Lighter, breaks easier   | Implemented          |
| balloon | #eb6e8c (pink)   | No      | 1 / 1           | 13     | 0.5  | 80        | 0.7     | 2.2×        | 80           | lift=1.7 (floats up)     | Type defined, unused |
| sticky  | #dcbe3d (yellow) | No      | 1 / 2           | 12     | 1.0  | 100       | 0.8     | 1.9×        | 95           | sticks_to_terrain=true   | Type defined, unused |
| fire    | #eb5929 (orange) | No      | 1 / 0           | 11     | 0.6  | 100       | 0.8     | 1.9×        | 90           | burns=true, spikes-safe  | Type defined, unused |

## Notes

- **Detachable** = `movable: true` in type definition — bila poate fi scoasă din structură
- **Break ratio** = lungimea curentă / rest_len la care firul se rupe
- `max_links: 0` la fire = nu poate forma fire noi, dar are min_links=1 (trebuie să fie conectată la ceva)
- Balloon și sticky și fire sunt definite complet dar nu apar în niciun nivel încă
- Culorile exacte se văd în `GooTypes.gd` ca `Color(r, g, b)` Godot format
