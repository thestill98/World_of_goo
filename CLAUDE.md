# World of Bloop — Reguli de proiect

Citit la **fiecare sesiune nouă**. Overrides orice comportament implicit.

---

## Limbă

- Tot codul, comentariile, identificatorii și cheile JSON sunt în **engleză**.
- Userul vorbește în română. Claude răspunde în română.
- Textele vizibile în UI se scriu ca `tr("...")`, traducerile în `assets/lang/`.

---

## Arhitectură — ce merge unde

| Fișier | Responsabilitate |
|---|---|
| `scripts/World.gd` | Fizică, logică de joc, spring forces — **fără pygame/display** |
| `scripts/Game.gd` | Input, desenare, flow UI, tranziții de scenă |
| `scripts/GooNode.gd` | Starea și desenul unui singur goo ball |
| `scripts/GooTypes.gd` | Datele statice pentru fiecare tip de bilă |
| `scripts/StrandNode.gd` | Date pentru un fir (nu face fizică singur) |
| `scripts/LevelData.gd` | Parsarea JSON-ului de nivel |
| `scripts/GameState.gd` | Autoload — stare globală între scene (nivel curent etc.) |
| `scripts/UI.gd` | Factory butoane (`UI.make_button`) — roluri: `"primary"`, `"secondary"`, `"card"` |
| `scripts/Draw.gd` | Funcții statice grafice reutilizabile: `sky`, `hills`, `heading` |
| `scripts/MainMenu.gd` | Ecranul principal |
| `scripts/LevelSelect.gd` | Ecranul de selectare nivel |
| `levels/*.json` | Datele nivelurilor (nu cod) |
| `assets/textures/` | Texturi PNG generate sau importate |
| `docs/` | Documentație de referință (tipuri, design etc.) |
| `TODO.md` | Lista de dorințe și buguri neimplementate |

**Reguli de arhitectură:**
- `World.gd` nu importă nimic din Godot display. Testele pot folosi World headless.
- Bile în stare `"node"` sunt KINEMATIC și integrate manual în `_apply_spring_forces()`.
- Bile în stare `"drag"` sunt STATIC freeze (evită effective velocity la drop).
- `PhysicsServer2D.body_set_state` e obligatoriu la tranziție din freeze → dinamic.

---

## Adăugare tip nou de bilă

1. Adaugă intrarea în `GooTypes.gd` cu toți parametrii.
2. Dacă tipul are comportament special (lift, burns, attract), adaugă logica în `World.gd`.
3. Adaugă culoarea firului în `STRAND_COLORS` din `Game.gd → _draw_strands()`.
4. Creează un nivel de test cu `python tools/new_level.py`.
5. Documentează în `docs/goo_types.md`.

---

## Workflow — cuvinte cheie

| Ce spune userul | Ce fac eu |
|---|---|
| `note it` / `noteaza` | Adaug **doar** în `TODO.md`, nu implementez nimic |
| `implementeaza` / `fa` / `baga` | Implementez imediat |
| Ambiguu (lipsesc cuvintele cheie) | **Întreb** înainte să implementez |
| `implementeaza tot din todo` | Iau itemii din TODO.md și implementez în batch |

---

## Testare și debugging

- **Eu (Claude) nu pot rula jocul.** Userul e interfața de testare.
- Userul testează → copiază console log → îmi dă log-ul → eu fac trace-back.
- **Nu șterge print-urile de debug** (`PICK`, `DROP`, `FREE`, `BREAK`, `ATTACH`, trace) fără acord explicit — sunt canalul principal de comunicare.
- Când apare un bug, cer console log dacă nu e furnizat deja.
- Când adaug funcționalitate nouă, adaug și print-uri relevante.

---

## Fizică — invarianți critici

- **Spring forces** sunt calculate manual în `World.gd → _apply_spring_forces(delta)`.
  `DampedSpringJoint2D` a fost abandonat (nu funcționează cu frozen anchors).
- **Floor clamping**: după fiecare update de poziție pentru bile `"node"`, clampez la `_ground_y() - radius`.
- **Throw velocity**: tracked via EMA a mouse delta × 60Hz în `drag_to()`, aplicat via `PhysicsServer2D` la drop.
- **Y coordinate**: level JSON folosește Y-up (pymunk), Godot e Y-down. Conversia: `godot_y = level_height - json_y` (în `LevelData`).
- **Collision layers**: TERRAIN=1, STRUCTURE=2, FREE=4.

---

## Reutilizare și centralizare (DRY vizual)

**Regula de bază:** un element definit o dată, folosit oriunde. Nu duplica stiluri, culori sau forme.

- **UI buttons** → factory `UI.gd` (`make_button(text, pos, size, role)`) cu `StyleBoxFlat` per rol (`"primary"`, `"secondary"`, `"danger"`). Niciun buton creat manual în altă parte.
- **Elemente decorative** (soare, nori, dealuri, pipe, etc.) → funcții statice în `Draw.gd` (`draw_sun(canvas, pos, radius, palette)`, `draw_hills(canvas, points, col)` etc.). Aceeași funcție se cheamă din MainMenu, Game, LevelSelect.
- **Palete de culori** → constante în `Theme.gd` (autoload): `BG_SKY`, `COL_HILL_FAR`, `COL_HILL_NEAR` etc. Nicio culoare literală duplicată în mai mult de un fișier.
- **Când adaugi ceva vizual nou** → întâi verifică dacă există deja în `Draw.gd` / `Theme.gd` / `UI.gd`; dacă nu, adaugă acolo și cheamă de oriunde ai nevoie.
- **Scenes vs funcții**: elemente complexe cu logică proprie → scenă `.tscn`; elemente pur grafice → funcție statică în `Draw.gd`.

---

## Niveluri

- Adaugă cu `python tools/new_level.py <id> "<Name>"`.
- Validează cu `python tools/validate_levels.py`.
- Un nivel livrat trebuie să fie rezolvabil de bot (`tests/test_bot_solves_levels.py`).
- `TODO.md` ține evidența a ce mai rămâne de implementat.
