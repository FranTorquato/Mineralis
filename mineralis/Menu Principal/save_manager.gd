extends Node

const SAVE_PATH = "user://mineralis_save.json"

var _data : Dictionary = {
	"unlocked_phases"  : ["1_1"],
	"completed_phases" : [],
	"save_version"     : 1
}

func _ready():
	load_game()

func save_game() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[Save] Erro ao abrir arquivo para escrita")
		return
	file.store_string(JSON.stringify(_data, "\t"))
	file.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return  # primeiro acesso, usa padrão
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null: return
	var json = JSON.parse_string(file.get_as_text())
	file.close()
	if json == null or not json is Dictionary:
		push_error("[Save] JSON inválido, resetando")
		return
	for key in _data:
		if json.has(key):
			_data[key] = json[key]

func get_unlocked() -> Array:
	return _data["unlocked_phases"]

func get_completed() -> Array:
	return _data["completed_phases"]

func unlock_phase(id: String) -> void:
	if id not in _data["unlocked_phases"]:
		_data["unlocked_phases"].append(id)
		save_game()

func complete_phase(id: String) -> void:
	if id not in _data["completed_phases"]:
		_data["completed_phases"].append(id)
		save_game()

func reset_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	_data = {"unlocked_phases": ["1_1"], "completed_phases": [], "save_version": 1}
