extends Node

var unlocked_phases = {
	"1_1": true,   # Andes liberada
	"1_2": false,  # Amazônia bloqueada
	"1_3": false   # Machu Picchu bloqueada
}

func is_phase_unlocked(id: String) -> bool:
	if unlocked_phases.has(id):
		return unlocked_phases[id]
	return false

func unlock_phase(id: String):
	if unlocked_phases.has(id):
		unlocked_phases[id] = true
