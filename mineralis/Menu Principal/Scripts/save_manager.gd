extends Node

# Caminho do arquivo de save (user:// = pasta de dados do app)
const SAVE_PATH : String = "user://mineralis_save.json"

# Estrutura padrão — usada quando não há save em disco
var _data : Dictionary = {
	"unlocked_phases"  : ["1_1"],   # fase 1_1 sempre desbloqueada
	"completed_phases" : [],
	"save_version"     : 1
}

# ==============================================================
# INICIALIZAÇÃO — carrega automaticamente ao iniciar o jogo
# ==============================================================
func _ready() -> void:
	load_game()

# ==============================================================
# SALVAR
# ==============================================================
func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[SaveManager] Erro ao abrir arquivo para escrita: " + SAVE_PATH)
		return
	file.store_string(JSON.stringify(_data, "\t"))
	file.close()
	print("[SaveManager] Salvo: ", _data["unlocked_phases"])

# ==============================================================
# CARREGAR
# ==============================================================
func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("[SaveManager] Nenhum save encontrado — iniciando do zero")
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("[SaveManager] Erro ao ler arquivo de save")
		return

	var parsed = JSON.parse_string(file.get_as_text())
	file.close()

	if parsed == null or not parsed is Dictionary:
		push_error("[SaveManager] Save corrompido — resetando")
		reset_save()
		return

	# Mescla com padrão para garantir chaves de versões futuras
	for key in _data:
		if parsed.has(key):
			_data[key] = parsed[key]

	print("[SaveManager] Carregado: ", _data["unlocked_phases"])

# ==============================================================
# GETTERS
# ==============================================================
func get_unlocked() -> Array:
	return _data["unlocked_phases"]

func get_completed() -> Array:
	return _data["completed_phases"]

# ==============================================================
# SETTERS (salvam em disco automaticamente)
# ==============================================================
func unlock_phase(id: String) -> void:
	if id not in _data["unlocked_phases"]:
		_data["unlocked_phases"].append(id)
		save_game()

func complete_phase(id: String) -> void:
	if id not in _data["completed_phases"]:
		_data["completed_phases"].append(id)
		save_game()

# ==============================================================
# RESET (útil para testes)
# ==============================================================
func reset_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	_data = {
		"unlocked_phases"  : ["1_1"],
		"completed_phases" : [],
		"save_version"     : 1
	}
	print("[SaveManager] Save resetado")
