# Night Drop — Unity

Original IP. Mobile-first open-world crime game (Unity 6 LTS / 2022.3, URP, C#).
Not affiliated with Rockstar or any existing franchise.

The Godot prototype at the repo root stays as-is. This folder is the Unity project.

## Open it

1. Unity Hub is installing **6000.0.82f1** (Unity 6 LTS, Apple Silicon).
2. **Open → Add project from disk** → this `NightDropUnity` folder.
3. First import auto-runs **Night Drop → Run Phase 0 Setup**.
4. Play `Assets/_Project/Scenes/Bootstrap.unity`.

## Controls

- Move: left stick / WASD
- Look: right half of screen / right mouse
- Run: Run / Shift
- Jump / handbrake: Jump / Space
- Enter or exit a car: **Use** / E

Hit a pedestrian (on foot sprint or with a car) to raise **heat** (pips at the top). Patrol units spawn and chase. Hide long enough and heat drops.

## Built so far

- Phase 0 — project layout, touch Input System, additive scene streaming
- Phase 1 — walk / run / jump / swim + Cinemachine
- Phase 2 — WheelCollider cars, enter/exit, traffic
- Phase 3 — pedestrians, heat, chasing patrol units

## Next (Phase 4)

Melee, guns, health. Ask for that as its own session.
