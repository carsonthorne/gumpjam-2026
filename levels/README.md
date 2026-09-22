# Building levels

The Sokoban Layout plugin is enabled in Project Settings → Plugins. If the project
was already open when the plugin was added, reopen the project or enable the plugin
there once.

1. Open `scenes/main.tscn` and select `LevelLayout`.
2. Choose a local `.txt` / `.sok` Collection and a 1-based Level Number.
3. Review dimensions and crate/target counts, then click **Build Level**.
4. Save the scene. The generated walls, crates, targets, and cage are normal scene
   instances. Ctrl/Cmd-Z restores the previous layout and player position.

`wikipedia.txt` contains the requested first map. `tutorials.txt` contains two small
project-authored practice maps, useful for trying the level selector.

## Included puzzle corpus

Choose one of these files in **LevelLayout → Collection**, then set **Level Number**:

| Collection | File | Puzzles |
| --- | --- | ---: |
| Microban I | `microban.txt` | 154 |
| Microban II | `microban_ii.txt` | 134 |
| Microban III | `microban_iii.txt` | 100 |
| Microban IV | `microban_iv.txt` | 100 |
| Sasquatch I | `sasquatch.txt` | 46 |
| Sasquatch II | `sasquatch_ii.txt` | 49 |
| Sasquatch III | `sasquatch_iii.txt` | 49 |
| Sasquatch IV | `sasquatch_iv.txt` | 49 |
| LOMA (2010 mirror edition) | `loma.txt` | 60 |

Start with Microban I for small introductory puzzles; Sasquatch provides more
variety and larger boards. These add **741 puzzle entries**, with some overlap
between collections. See [sources, credits, and omitted puzzles](SOURCES.md).


Build replaces only `LevelLayout/Generated` and repositions the Player Path node.
Edits under Generated are replaced by the next build; put hand-authored additions
beside Generated. The existing ground, lights, backdrop, player, and goal logic are
retained. Generation never runs at game startup.

## Collection format

Separate boards with blank lines. Lines beginning with `;` are comments; use them
for titles, authors, sources, and any distribution terms. Keep leading spaces.

| Symbol | Meaning |
| --- | --- |
| `#` | Wall |
| space, `-`, `_` | Floor / outside padding |
| `$` | Crate |
| `.` | Target |
| `@` | Player |
| `*` | Crate on target |
| `+` | Player on target |

Rows may have different lengths. The player area must be enclosed, with exactly
one player and matching nonzero crate/target counts. Crates and targets must belong
to that area. Validation checks structure, not puzzle solvability. This reader
supports plain text boards, not RLE or saved move sequences. Click **Refresh
Collection** after editing the collection externally.

This lab uses one-unit cells, unscaled/unrotated LevelLayout at ground height,
boards up to 40×40, and an origin within one unit of world X/Z zero. This keeps the
automatically sized cage inside the backdrop and ground. Crate skins are applied
by the existing runtime scripts; the editor retains their original preview mesh.

The Wikipedia example was transcribed from map 1 at
https://www.mathsisfun.com/games/a/sokoban/js/maps.js, whose comment identifies the
Wikipedia Sokoban page as its source. No broader collection license is asserted.

## Checks

From the project directory, using the installed Godot executable:

```sh
godot --headless --path . tests/layout_runtime.tscn
godot --headless --editor --path . --script tests/layout_editor.gd
```

The editor test operates on its own unsaved scene and writes its round-trip copy
under `user://`; it does not overwrite Main. It covers build, undo/redo, repeated
builds, instance persistence, and preserving the layout on invalid input. The
runtime test checks parsing, saved layout contents, initial target occupancy,
blocked/open pushes, one-cell movement, and win detection.
