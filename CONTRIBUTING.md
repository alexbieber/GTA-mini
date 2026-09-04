# Contributing to Night Drop

You do not need to be a professional game programmer. You do need a playable change and respect for the original IP.

Read this once, then pick a [good first mission](README.md#good-first-missions).

## Ground rules

1. **Original IP.** Genre-inspired only. Never copy Rockstar (or any studio) names, logos, likenesses, maps, vehicles, audio, or mission structure.
2. **One system per PR.** Wanted logic, a new car, and a skybox do not share a branch.
3. **Do not mix engines.** Godot code stays at the repo root. Unity code stays in `NightDropUnity/`. No ports "just to keep them in sync" unless a maintainer asks.
4. **Pool anything spawned in a loop.** Traffic, peds, bullets, pickups.
5. **No paid Asset Store / Godot Asset Library packs** unless a maintainer agrees in the issue.
6. **CC0 art only** for new third-party assets. Add a line to `assets/CREDITS.txt`.

## Which tree do I touch?

| You want to… | Work in |
|---|---|
| See it running tonight, desktop | Godot root (`scripts/`, `scenes/`, `assets/`) |
| Ship on a phone | `NightDropUnity/` |
| Docs, README, issues | Either, in a docs-only PR |

## Godot setup

- Godot **4.7**, renderer **Forward Plus**.
- Import the repo root. Main scene: `res://scenes/main.tscn`.
- Language: GDScript. Match local style: typed vars, `class_name`, early returns, no drive-by refactors.

Useful files:

| File | Job |
|---|---|
| `scripts/game.gd` | Phases, input, mission, services |
| `scripts/city.gd` | Grid, shops, base, water |
| `scripts/wanted_system.gd` | Heat, stars, decay |
| `scripts/vehicle.gd` | Player + AI cars |
| `scripts/player.gd` | On-foot body |
| `scripts/pedestrian.gd` | Sidewalk AI |
| `scripts/arsenal.gd` | Gun stats |
| `scripts/touch_controls.gd` | Mobile HUD |

Physics layers (don't reshuffle without a migration note): 1 world, 2 player, 3 vehicles, 4 cops, 5 peds.

## Unity setup

- Unity **6 LTS** (`6000.0.82f1`) or 2022.3 LTS, URP, C#, Input System.
- Open `NightDropUnity/`. First import: **Night Drop → Run Phase 0 Setup**.
- Play `Assets/_Project/Scenes/Bootstrap.unity`.
- Scripts live under `NightDropUnity/Assets/_Project/`.
- Mobile-first: on-screen touch is the real input. Keyboard is editor fallback.
- Current unfinished phase: combat (Phase 4) → missions → UI → polish.

## How to send a change

1. Fork and branch from `main`: `feat/ped-scatter`, `fix/coupe-spawn`, `audio/engine-loop`.
2. Open or comment on an issue first if the work is more than a couple of hours.
3. Keep the diff small. Include a screenshot or 10-second clip when the change is visible.
4. Update `assets/CREDITS.txt` if you added art.
5. Open a PR against `main`. Use the template. Link the issue.

## PR bar

A maintainer should be able to:

- Import / open the project
- Play the steal → heat → deliver loop
- Tell what your PR changed in one sentence

We will bounce PRs that:

- Drop copyrighted names or ripped assets into the tree
- Rewrite formatting across files you didn't need to touch
- Add a system with no way to turn it off or test it
- Cross the Godot / Unity boundary

## Community

Be kind. See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md). If you are stuck, open an issue with `question` and what you already tried.

Welcome to the harbor.
