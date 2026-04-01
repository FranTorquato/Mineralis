extends Node
# ──────────────────────────────────────────────────────────────
# progress_manager.gd
# Salve em: res://Menu Principal/Scripts/progress_manager.gd
#
# Adicione como Autoload:
#   Project > Project Settings > Globals > Autoload
#   Nome:   ProgressManager
#   Caminho: res://Menu Principal/Scripts/progress_manager.gd
# ──────────────────────────────────────────────────────────────

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

# ── Lifecycle ─────────────────────────────────────────────────

func _ready() -> void:
	_load()


# ── API pública ───────────────────────────────────────────────

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


# ── Save / Load ───────────────────────────────────────────────

func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({
			"version":  SAVE_VERSION,
			"unlocked": _unlocked,
		}))
		f.close()


func _load() -> void:
	# Garante fases iniciais
	for pid in STARTING_PHASES:
		_unlocked[pid] = true

	if not FileAccess.file_exists(SAVE_PATH):
		return

	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return

	var txt  := f.get_as_text()
	f.close()

	var json := JSON.new()
	if json.parse(txt) != OK:
		push_warning("ProgressManager: save corrompido, ignorando.")
		return

	var data = json.get_data()
	# Suporte ao formato antigo ("unlocked_phases") e novo ("unlocked")
	var key := "unlocked" if data.has("unlocked") else "unlocked_phases"
	if data.has(key):
		_unlocked.merge(data[key], true)
