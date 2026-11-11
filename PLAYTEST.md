# Playtesting LANTERNFALL

## Run
- With Godot 4.7.2: `godot --path game` (from the repo root), or open `game/project.godot` in the editor and press F5.
- Playtest tools are on whenever you run from the editor or a debug build, or with `-- --dev`. They are never in a
  release export.

## Keys
- **F1**: the dev menu. Travel to any zone, the next unlit waylamp or the boss arena; set your level (points spent
  and rare gear of that level come with it); god mode; one-hit kills; spawn a pack (and pick the enemy kind); restart
  the boss fight; time x0.5 / x1 / x2 / x4; draw hitboxes and light radii.
- **F8**: write a note. The game pauses and a one-line box opens. Type what you noticed and press Enter (Esc
  cancels). A note is saved to `playtest/notes/<time>.md` with a screenshot beside it, plus the zone, your position,
  level and build, life and Light, and the last 30 seconds of combat.
- Every time you leave a zone, `playtest/sessions/<time>_<zone>.json` records the time you spent there, each death
  (cause and place), each boss's time to kill, and how often you used each skill.

## Send your notes
```
git add playtest
git commit -m "Playtest notes"
git push
```
