@tool
extends RefCounted

static func read_level(path: String, number: int) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"error": "Collection not found: " + path}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"error": "Cannot read collection: " + path}
	var levels: Array[PackedStringArray] = []
	var rows := PackedStringArray()
	for line in file.get_as_text().replace("\r", "").split("\n"):
		if line.begins_with(";"):
			continue
		if line.strip_edges().is_empty():
			if not rows.is_empty():
				levels.append(rows)
				rows = PackedStringArray()
		else:
			rows.append(line)
	if not rows.is_empty():
		levels.append(rows)
	if number < 1 or number > levels.size():
		return {"error": "Choose a level from 1 to %d." % levels.size()}
	var result := validate(levels[number - 1])
	result["level_count"] = levels.size()
	return result

static func validate(rows: PackedStringArray) -> Dictionary:
	var width := 0
	var crates := 0
	var targets := 0
	var players: Array[Vector2i] = []
	var occupied: Array[Vector2i] = []
	for y in rows.size():
		width = maxi(width, rows[y].length())
		for x in rows[y].length():
			var tile := rows[y][x]
			if not tile in " #.$*@+-_":
				return {"error": "Unknown symbol '%s' at row %d, column %d." % [tile, y + 1, x + 1]}
			if tile in "$*":
				crates += 1
			if tile in ".*+":
				targets += 1
			if tile in "@+":
				players.append(Vector2i(x, y))
			if tile in ".$*@+":
				occupied.append(Vector2i(x, y))
	if players.size() != 1:
		return {"error": "Expected exactly one player; found %d." % players.size()}
	if crates == 0 or crates != targets:
		return {"error": "Expected equal nonzero crate and target counts; found %d crates, %d targets." % [crates, targets]}
	# Ignore crates for enclosure/connectivity, but never treat outside padding as floor.
	var visited := {players[0]: true}
	var queue: Array[Vector2i] = [players[0]]
	var cursor := 0
	while cursor < queue.size():
		var cell := queue[cursor]
		cursor += 1
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + direction
			if next.y < 0 or next.y >= rows.size() or next.x < 0 or next.x >= rows[next.y].length():
				return {"error": "The playable area must be enclosed by walls."}
			if rows[next.y][next.x] != "#" and not visited.has(next):
				visited[next] = true
				queue.append(next)
	for cell in occupied:
		if not visited.has(cell):
			return {"error": "A crate or target is disconnected from the player's area."}
	return {"rows": rows, "width": width, "height": rows.size(), "crates": crates, "targets": targets, "player": players[0]}
