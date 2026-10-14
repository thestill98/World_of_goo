# World of Bloop — TODO

Items de implementat. Adaugă cu "note it", implementează când zici tu.

---

## Pipe logic (prioritate medie)

**Pipe activ condiționat de structură:**
- Pipe-ul se activează vizual și funcțional doar când cel puțin o bilă din structură
  (state "node" sau "anchor") se află în raza de proximitate a pipe-ului.
- Dacă structura se retrage (nicio bilă în rază), pipe-ul se dezactivează.
- Stabilitate: structura trebuie să rămână în proximitate (nu e suficient să treci prin zonă).
- Bile aruncate liber în pipe → colectate direct (ca "collected"), fără a fi nevoie să fie în structură.
- Vizual: pipe-ul să aibă o stare activă/inactivă clară (culoare, glow, animație).

---

## On-screen debug overlay

- Panel mic (colț dreapta-jos) cu ultimele 3-4 evenimente (PICK, ATTACH, DROP, BREAK).
- Fiecare linie dispare după ~1.5s.
- Toggle cu tasta D.
- După ce merge, scoate print-urile verbose din consolă.

---

## Git — version control local

- `git init` în `world-of-bloop/`, `.gitignore` pentru `.godot/`, `export/`, `*.uid`.
- Commit după fiecare sesiune de lucru (sau după fiecare feature stabil).
- Nu e nevoie de remote/GitHub deocamdată — doar istoricul local salvează munca.

---

## Save system

- Salvează nivelele completate (listă de `level_id`-uri) în `user://save.json`.
- LevelSelect arată nivele completate diferit (check, stea, culoare).
- GameState expune `mark_complete(level_id)` și `is_complete(level_id)`.
- Nu salvăm scor sau timp deocamdată — doar "completat / nu".

---

## Playtesting bot (Godot)

- Script headless `tools/bot_solver.gd` care rulează un nivel fără renderer.
- Botul aplică strategia greedy: ia bila liberă cea mai apropiată de pipe, o atașează.
- Raport: nivel rezolvat în N mișcări / blocat după X secunde.
- Rulat din linie de comandă: `godot --headless --script tools/bot_solver.gd`.
- Un nivel livrat trebuie trecut de bot — dacă nu, fix nivel sau fix bot.

---

## CHANGELOG + version number

- `world-of-bloop/version.gd` — constantă `VERSION = "0.1.0"` (sursă unică).
- `world-of-bloop/CHANGELOG.md` — format standard: versiune, dată, ce s-a schimbat.
- La fiecare feature: MINOR++; la fiecare fix: PATCH++.

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
