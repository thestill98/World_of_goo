# Changelog — World of Bloop

Versiunea cea mai nouă prima. MINOR = feature nou, PATCH = fix.

---

## [0.3.0] — 2026-10-14

### Added
- WinOverlay: ecran de victorie cu colectate, timp, OCD ★, butoane Next/Retry/Menu
- OCD tracking: `GameState.mark_ocd()` — nivelurile cu `ocd.target` afișează goal în overlay
- Celebrare: 35 particule colorate explodează din pipe la victorie
- Camera pan la marginile ecranului când tragi o bilă (edge scroll 380 px/s)
- Animație pipe pulsată (inel sin-bazat, mai strălucitor când structura e conectată)
- Hint text level 1: "Drag a goo ball onto the structure" — 8s sau ascuns la primul ATTACH
- `GooNode`: clipire aleatorie + direcție privire (ochi urmăresc velocity)
- 3 niveluri noi: 06 Twin Peaks, 07 Sky High, 08 Gear Gauntlet

### Fixed
- `_draw_eyes()` acceptă acum parametrul `look: Vector2` (era eroare de runtime cu 4 argumente)

---

## [0.2.0] — 2026-10-14

### Added
- Sistem de decoruri (iarbă auto-scatter, boschete, flori, stânci, ciuperci) cu animație de vânt
- Mecanisme hazard: gear, saw, spinner — distrug orice bilă la contact, firele se rup
  - 3 tipuri vizuale procedurale (desenate în GDScript)
  - Tipuri mobile (traiectorie A→B în JSON) și staționare
  - Particule slime la distrugere
- Petalele de drag (WOG-style) la bila ținută în mână
- Redesign ochi bile negre (mai mici, mai sus, mai apropiați)
- Z-index layering: terrain(0) → decor(1) → bile(2) → hazard(3)
- Sistem DRY vizual: `UI.gd`, `Draw.gd`, funcții statice reutilizabile
- `version.gd` și `CHANGELOG.md`
- Debug overlay (tasta D) cu ultimele 4 evenimente
- Save system: nivele completate salvate în `user://save.json`
- Git init + push la GitHub

### Fixed
- `PackedVector2Array` nu poate fi `const` în GDScript 4 → schimbat în `var`
- Hover ring galben apărea în timp ce bila era ținută în mână

---

## [0.1.0] — sesiunea anterioară

### Added
- Fizică de baze: goo balls, strands cu spring forces, pipe, undo
- 5 tipuri de bile: ivy, slime, balloon, sticky, fire
- 5 niveluri JSON
- MainMenu + LevelSelect cu butoane organice stilizate
- Skybox, dealuri procedurale, fundal animat
- Localizare RO/EN cu `tr()`
