# Rat Albert

Rat Albert is a browser-playable 3D Sokoban game made with Godot 4.7.2 for
[gump jam 3: Computer Lab](https://itch.io/jam/gump-jam-3). Guide a lab rat,
push the lettered blocks onto their targets, and try to finish with fewer moves
and less time. The game has two tutorials and 878 entries from puzzle collections;
some collections overlap, so these are not 880 unique puzzles.

Play the current build on [itch.io](https://carsonthorne.itch.io/rat-albert).

## Play locally

1. Open this folder as a project in Godot 4.7.2.
2. Run the project (`F5` in the Godot editor). The splash screen is the main
   scene; use the level selector to choose a puzzle.

In a browser, click or press a key at the opening screen to enable audio. This
gesture is required by browser autoplay rules.

| Control | Action |
| --- | --- |
| WASD | Move |
| Shift | Run |
| E or Space | Interact / push |
| Left / Right Arrow | Rotate the camera |
| Esc | Pause |

## Browser export

The `Web` preset in `export_presets.cfg` produces an HTML5 build at
`dist/web/index.html`. It currently points to a no-threads Web release template
at `.godot/export_templates/web_nothreads_release.zip`. The `.godot` directory
is generated locally and is not committed, so supply a compatible Godot 4.7.2
template at that path or update the preset's `custom_template/release` setting
before exporting from a fresh clone.

With the template in place, run:

```sh
godot --headless --path . --export-release Web dist/web/index.html
```

Zip the *contents* of `dist/web` so `index.html` is at the ZIP root, then upload
that ZIP as an HTML project on itch.io and mark it playable in the browser.
`dist/` is ignored by Git. The Web export includes an audio-unlock prompt and
browser audio-context handling for Safari and other autoplay-restricted browsers.

## Puzzles and leaderboards

The level collections and their counts are listed in [levels/README.md](levels/README.md).
See [levels/SOURCES.md](levels/SOURCES.md) for collection credits, original
links, conversion notes, and omitted puzzles. In brief:

- Microban I–IV and Sasquatch I–IV: David W. Skinner.
- LOMA: curated by Aymeric du Peloux, with individual puzzle authors preserved
  in the level data.
- Math Is Fun Sokoban: 60 adapted maps from its online game. The repository
  does not claim a broader redistribution licence for this collection.

The game scenes currently point at a hosted Cloudflare leaderboard API. To run
your own leaderboard, see
[cloudflare/leaderboard-worker/README.md](cloudflare/leaderboard-worker/README.md)
and update the `api_base_url` in `scenes/main.tscn` and `scenes/start_menu.tscn`.

## Tests

From the project directory:

```sh
godot --headless --path . tests/layout_runtime.tscn
godot --headless --editor --path . --script tests/layout_editor.gd
```

## Asset and licence notes

The active UI font is Lower Pixel by IbraCreative. Its supplied
[usage notice](assets/fonts/LowresPixel-README.txt) permits personal use only
and prohibits commercial use. Do not assume that this repository grants a
commercial font licence. The older Arcade Classic font is not part of the
committed project because its notice prohibits redistribution.

This repository has no blanket open-source or asset-redistribution licence.
Puzzle-source permissions and caveats are documented separately in
[levels/SOURCES.md](levels/SOURCES.md); check the rights for code, puzzles,
fonts, images, models, and audio before reusing or republishing them.
