# Puzzle collection sources

Downloaded 2026-09-21 and updated 2026-09-26. These ten files add 878 puzzle
entries (880 including the tutorials). Collections can overlap: Microban III
includes some of Skinner's LOMA contributions. This is not a count of unique
puzzles.

## David W. Skinner: Microban I–IV and Sasquatch I–IV

Author: **David W. Skinner**. His archived author page grants redistribution with
proper credit:

> These sets may be freely distributed provided they remain properly credited.

[Author page and distribution terms](http://www.abelmartin.com/rj/sokobanJS/Skinner/David%20W.%20Skinner%20-%20Sokoban.htm)

The files below were downloaded from the text links on that archived page.
Credit is included in every collection header. Keep that credit with redistributed
puzzles. These are that archive's editions, not a claim to be the newest revisions.

| Local file | Included | Source count | Download |
| --- | ---: | ---: | --- |
| [microban.txt](microban.txt) | 154 | 155 | [Source](http://www.abelmartin.com/rj/sokobanJS/Skinner/David%20W.%20Skinner%20-%20Sokoban_files/Microban.txt) |
| [microban_ii.txt](microban_ii.txt) | 134 | 135 | [Source](http://www.abelmartin.com/rj/sokobanJS/Skinner/David%20W.%20Skinner%20-%20Sokoban_files/Microban%20II.txt) |
| [microban_iii.txt](microban_iii.txt) | 100 | 101 | [Source](http://www.abelmartin.com/rj/sokobanJS/Skinner/David%20W.%20Skinner%20-%20Sokoban_files/Microban%20III.txt) |
| [microban_iv.txt](microban_iv.txt) | 100 | 102 | [Source](http://www.abelmartin.com/rj/sokobanJS/Skinner/David%20W.%20Skinner%20-%20Sokoban_files/Microban%20IV.txt) |
| [sasquatch.txt](sasquatch.txt) | 46 | 50 | [Source](http://www.abelmartin.com/rj/sokobanJS/Skinner/David%20W.%20Skinner%20-%20Sokoban_files/Sasquatch.txt) |
| [sasquatch_ii.txt](sasquatch_ii.txt) | 49 | 50 | [Source](http://www.abelmartin.com/rj/sokobanJS/Skinner/David%20W.%20Skinner%20-%20Sokoban_files/Sasquatch%20II.txt) |
| [sasquatch_iii.txt](sasquatch_iii.txt) | 49 | 50 | [Source](http://www.abelmartin.com/rj/sokobanJS/Skinner/David%20W.%20Skinner%20-%20Sokoban_files/Sasquatch%20III.txt) |
| [sasquatch_iv.txt](sasquatch_iv.txt) | 49 | 50 | [Source](http://www.abelmartin.com/rj/sokobanJS/Skinner/David%20W.%20Skinner%20-%20Sokoban_files/Sasquatch%20IV.txt) |

## LOMA

Curated by **Aymeric du Peloux**, with individual authors credited beside each
puzzle. This is the 137-level edition published in 2021 on the curator's site.
The source titles, authors, comments, and board rows were retained when its XSB
metadata was converted to this project's semicolon-comment format.

- [Curator's page and redistribution permission](https://aymericdupeloux.wixsite.com/sokoban/post/_loma)
- [Local collection: 137 puzzles](loma.txt)

The curator explicitly permits free publication without requesting permission.

## Math Is Fun Sokoban

The 60-map JavaScript collection from Math Is Fun's Sokoban game was converted
from numeric tile arrays to the plugin's text format. The first source map is
commented as coming from the Wikipedia Sokoban page.

- [Playable game](https://www.mathsisfun.com/games/sokoban.html)
- [Source map data](https://www.mathsisfun.com/games/a/sokoban/js/maps.js)
- [Local collection: 60 puzzles](wikipedia.txt)

## Conversion and compatibility

Boards retain their original orientation, spacing, and tile contents. Line endings
were normalized and headers/comments added for the plugin's text format. Selection
uses **1-based position in the local file**; `Source level` comments retain upstream
numbering, including gaps left by omissions. No solutions were imported.

The following source puzzles were excluded so every offered level works with the
current importer and 40×40 lab limit. Disconnected areas may be deliberate in the
original puzzles; omission does not mean the original puzzle is invalid.

- **microban.txt:** 155 'The Dungeon' (disconnected crate/target area).
- **microban_ii.txt:** 135 'Fractal' (47x41).
- **microban_iii.txt:** 101 (47x42).
- **microban_iv.txt:** 101 (42x42); 102 (49x44).
- **sasquatch.txt:** 4 (disconnected crate/target area); 19 (disconnected crate/target area); 41 (disconnected crate/target area); 46 (disconnected crate/target area).
- **sasquatch_ii.txt:** 9 (disconnected crate/target area).
- **sasquatch_iii.txt:** 36 (disconnected crate/target area).
- **sasquatch_iv.txt:** 25 (disconnected crate/target area).

The Math Is Fun conversion was checked for import compatibility: valid symbols,
one player, matching crate/target counts, enclosure, connected crate/target area,
and size at most 40×40. This checks structure, not solvability or a full manual
playthrough of every puzzle.
