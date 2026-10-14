# World of Bloop — TODO

Items de implementat. Adaugă cu "note it", implementează când zici tu.

---

## Mecanisme hazard ✓ FACUT (2026-10-14)

Gear, saw, spinner — distrug bile la contact, firele se rup.
Particule slime la kill. Plasare în JSON (pos/path/speed/radius).
Nivel 01: 3 hazarduri de test (gear, saw, spinner mobil).

---

## Decoruri (iarbă, boschete, etc.) ✓ FACUT

Auto-scatter iarbă pe suprafețe. Manual în JSON pentru boschete/flori/stânci/ciuperci.
Animație wind sway. PNG generate cu Pillow.

---

## Save system ✓ FACUT (2026-10-14)

`user://save.json` cu lista de level_id completate.
`GameState.mark_complete(id)` + `is_complete(id)`.
LevelSelect: carduri completate au ✓ verde.
Salvare automată la win.

---

## Debug overlay ✓ FACUT (2026-10-14)

Tasta D: panel colț dreapta-jos cu ultimele 4 evenimente (PICK, ATTACH, DROP, BREAK, SMASH).
Fiecare eveniment dispare după 1.5s.

---

## Git ✓ FACUT (sesiunea anterioară)

Push la https://github.com/thestill98/World_of_goo.git

---

## CHANGELOG + version ✓ FACUT (2026-10-14)

`version.gd` (VERSION = "0.2.0") + `CHANGELOG.md`.

---

## Playtesting bot ✓ FACUT (2026-10-14) — NETESTAT

`tools/bot_solver.gd` — rulat cu:
```
godot --headless --script tools/bot_solver.gd -- levels/01_humble_tower.json
```
Strategie greedy: bila liberă cea mai apropiată de structură.
⚠️ Netestat — poate necesita ajustări dacă `SceneTree` nu inițializează
corect `World2D` în modul headless (physics raycast poate eșua).

---

## WinOverlay + Game polish ✓ FACUT (2026-10-14)

- WinOverlay integrat: colectate, timp, OCD star, butoane Next/Retry/Menu
- GameState.mark_ocd() la win când collected >= ocd_target
- Celebrare: 35 particule colorate din pipe la win
- Camera pan la marginea ecranului când tragi o bilă (EDGE_MARGIN=80, speed=380px/s)
- Animație pipe pulsată (sin-based ring, mai intens când pipe e conectat)
- Hint text pe nivelul 1 ("Drag a goo ball..."): 8s sau ascuns la primul ATTACH
- Animație clipeală + direcție privire pentru GooNode (_draw_eyes cu look: Vector2)

---

## Niveluri noi ✓ FACUT (2026-10-14)

Adăugate nivelurile 06, 07, 08:
- 06 Twin Peaks: 2 dealuri, pod între ele cu ivy, pipe pe deal drept
- 07 Sky High: turn foarte înalt, balloon goo ajută la ridicare
- 08 Gear Gauntlet: gear/saw/spinner blochează drumul, calea prin gap-ul dintre ele

---

## Pipe logic (prioritate medie)

**Pipe activ condiționat de structură:**
- Pipe-ul se activează vizual și funcțional doar când cel puțin o bilă din structură
  (state "node" sau "anchor") se află în raza de proximitate a pipe-ului.
- Dacă structura se retrage (nicio bilă în rază), pipe-ul se dezactivează.
- Stabilitate: structura trebuie să rămână în proximitate (nu e suficient să treci prin zonă).
- Bile aruncate liber în pipe → colectate direct (ca "collected"), fără a fi nevoie să fie în structură.
- Vizual: pipe-ul să aibă o stare activă/inactivă clară (culoare, glow, animație).
**Status:** parțial implementat — pipe_connected() există, vizual de bază există.
Lipsește: glow mai vizibil pentru activare, animație pulsată.

---

## Level editor / tilemap decorativ (prioritate viitoare)

Inspirat dintr-un video YT cu Godot TileMap editor — nivelurile au nevoie de:
- **Teren vizual** cu tileset (nu doar polyline simplu ca acum) — dale, margini, texturi
- **Decorații structurale**: boscheti, copaci, tufișuri, flori, ciuperci, etc.
- **Elemente de ambient**: fundal stratificat (parallax), nori, iarbă, animații idle
- **Workflow**: deocamdată nivelurile le fac eu în JSON; pe termen mediu userul
  vrea să poată construi vizual niveluri în Godot (TileMapLayer + nivel editor propriu)
- Primul pas când venim la asta: înlocuiește polyline-ul de teren cu tile-uri reale
  → arată mult mai bine chiar și cu assets placeholder

---

## Sunete (prioritate medie)

Nicio implementare deocamdată. Prioritate după hazards + pipe.
Tipuri de sunet necesare: pick, attach, drop, break, smash, collect, win, lose.

---
