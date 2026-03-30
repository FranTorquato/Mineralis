extends Node

signal phase_unlocked(id)

const UNLOCK_MAP = {
	"1_1": "1_2",
	"1_2": "1_3",
}

func is_unlocked(id: String) -> bool:
	return id in SaveManager.get_unlocked()

func is_completed(id: String) -> bool:
	return id in SaveManager.get_completed()

func complete_phase(id: String) -> void:
	if not is_unlocked(id): return
	SaveManager.complete_phase(id)
	if id in UNLOCK_MAP:
		var next = UNLOCK_MAP[id]
		if not is_unlocked(next):
			SaveManager.unlock_phase(next)
			emit_signal("phase_unlocked", next)
