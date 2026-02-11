extends Node2D

var root_node: Branch
var tile_size: int =  16
var world_size = Vector2i(60,30)

var tilemap: TileMap
var paths: Array = []

const DUNGEON_TILESET_SOURCE_ID := 2
const TILE_FLOOR_ATLAS := Vector2i(2, 2)
const TILE_WALL_NON_CORNER_ATLAS := Vector2i(0, 0)
const TILE_WALL_CORNER_FLOOR_RIGHT_DOWN_ATLAS := Vector2i(0, 1)
const TILE_WALL_CORNER_FLOOR_RIGHT_UP_ATLAS := Vector2i(1, 1)
const TILE_WALL_CORNER_FLOOR_LEFT_DOWN_ATLAS := Vector2i(1, 0)
const TILE_WALL_CORNER_FLOOR_LEFT_UP_ATLAS := Vector2i(2, 0)
const CARDINAL_OFFSETS := [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]

func _draw():
	var rng = RandomNumberGenerator.new()
	var floor_cells_set: Dictionary = {}
	for leaf in root_node.get_leaves():
		var padding = Vector4i(rng.randi_range(2,3),rng.randi_range(2,3),rng.randi_range(2,3),rng.randi_range(2,3))
		for x in range(leaf.size.x):
			for y in range(leaf.size.y):
				if not is_inside_padding(x,y, leaf, padding) :
					var cell = Vector2i(x + leaf.position.x,y + leaf.position.y)
					floor_cells_set[cell] = true
	for path in paths:
		if path['left'].y == path['right'].y:
			for i in range(path['right'].x - path['left'].x):
				var cell = Vector2i(path['left'].x+i,path['left'].y)
				floor_cells_set[cell] = true
		else:
			for i in range(path['right'].y - path['left'].y):
				var cell = Vector2i(path['left'].x,path['left'].y+i)
				floor_cells_set[cell] = true
	for cell in floor_cells_set.keys():
		tilemap.set_cell(0, cell, DUNGEON_TILESET_SOURCE_ID, TILE_FLOOR_ATLAS)
	var wall_cells: Dictionary = {}
	for cell in floor_cells_set.keys():
		for offset in CARDINAL_OFFSETS:
			var neighbor = cell + offset
			if not floor_cells_set.has(neighbor):
				wall_cells[neighbor] = true
	for wall_cell in wall_cells.keys():
		var wall_tile = get_wall_tile_atlas(floor_cells_set, wall_cell)
		tilemap.set_cell(0, wall_cell, DUNGEON_TILESET_SOURCE_ID, wall_tile)
func _ready():
	tilemap = get_node("TileMap")
	root_node  = Branch.new(Vector2i(0,0), world_size)
	root_node.split(2, paths)
	queue_redraw()
	pass 


func is_inside_padding(x, y, leaf, padding):
	return x <= padding.x or y <= padding.y or x >= leaf.size.x - padding.z or y >= leaf.size.y - padding.w

func get_wall_tile_atlas(floor_cells_set: Dictionary, wall_cell: Vector2i) -> Vector2i:
	var has_left = floor_cells_set.has(wall_cell + Vector2i(-1, 0))
	var has_right = floor_cells_set.has(wall_cell + Vector2i(1, 0))
	var has_up = floor_cells_set.has(wall_cell + Vector2i(0, -1))
	var has_down = floor_cells_set.has(wall_cell + Vector2i(0, 1))
	var adjacent_floor_count = int(has_left) + int(has_right) + int(has_up) + int(has_down)
	if adjacent_floor_count != 2:
		return TILE_WALL_NON_CORNER_ATLAS
	if (has_left and has_right) or (has_up and has_down):
		return TILE_WALL_NON_CORNER_ATLAS
	if has_right and has_down:
		return TILE_WALL_CORNER_FLOOR_RIGHT_DOWN_ATLAS
	if has_right and has_up:
		return TILE_WALL_CORNER_FLOOR_RIGHT_UP_ATLAS
	if has_left and has_down:
		return TILE_WALL_CORNER_FLOOR_LEFT_DOWN_ATLAS
	if has_left and has_up:
		return TILE_WALL_CORNER_FLOOR_LEFT_UP_ATLAS
	return TILE_WALL_NON_CORNER_ATLAS
