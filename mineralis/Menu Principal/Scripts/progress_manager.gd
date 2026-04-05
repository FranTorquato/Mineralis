extends Node

const SAVE_PATH    = "user://mineralis_save.json"
const SAVE_VERSION = "1.1"

# Única fase que começa desbloqueada
const STARTING_PHASES : Array[String] = ["1_1"]

# Progressão linear
const PROGRESSION : Dictionary = {
	"1_1": "1_2",
	"1_2": "1_3",
	"1_3": "2_1",
	"2_1": "2_2",
	"2_2": "2_3",
	"2_3": "3_1",
	"3_1": "3_2",
	"3_2": "3_3",
	"3_3": "4_1",
	"4_1": "4_2",
	"4_2": "4_3",
	"4_3": "5_1",
	"5_1": "5_2",
	"5_2": "5_3",
	"5_3": "6_1",
	"6_1": "6_2",
	"6_2": "6_3",
}

var _unlocked : Dictionary = {}

signal phase_unlocked(phase_id: String)


func _ready() -> void:
	reset()
	_load()
	
	# Se mesmo assim não abrir, descomente a linha abaixo por UM SEGUNDO, rode o jogo e apague ela:
	# reset()


## Retorna true se a fase está desbloqueada
func is_unlocked(phase_id: String) -> bool:
	return _unlocked.get(phase_id, false)


## Desbloqueia uma fase específica
func unlock_phase(phase_id: String) -> void:
	if _unlocked.get(phase_id, false):
		return
	_unlocked[phase_id] = true
	_save()
	emit_signal("phase_unlocked", phase_id)


## Chame ao final de uma fase — desbloqueia a próxima
func complete_phase(phase_id: String) -> void:
	unlock_phase(phase_id)
	var next : String = PROGRESSION.get(phase_id, "")
	if next != "":
		unlock_phase(next)


## Apaga o save (Novo Jogo / debug)
func reset() -> void:
	_unlocked.clear()
	for pid in STARTING_PHASES:
		_unlocked[pid] = true
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)



func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({
			"version":  SAVE_VERSION,
			"unlocked": _unlocked,
		}))
		f.close()


func _load() -> void:
	# 1. Primeiro, tentamos carregar o que existe no arquivo
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if f:
			var json := JSON.new()
			if json.parse(f.get_as_text()) == OK:
				var data = json.get_data()
				var key := "unlocked" if data.has("unlocked") else "unlocked_phases"
				if data.has(key):
					_unlocked = data[key]
			f.close()

	# 2. Forçamos o desbloqueio das fases iniciais 
	# DEPOIS de carregar o save. Isso garante que a 1_1 sempre esteja aberta.
	for pid in STARTING_PHASES:
		_unlocked[pid] = true
	
	# Salva de volta para corrigir o arquivo se necessário
	_save()
