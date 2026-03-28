# =============================================================================
# MINERALIS - Guia de Implementação dos Cards no Godot 4
# =============================================================================
# Este guia cobre:
#   1. Como importar os SVGs
#   2. Estrutura de cena recomendada
#   3. Script do card com estado bloqueado/desbloqueado
#   4. Animações (shader de cinza + efeitos de desbloqueio)
#   5. Como gerenciar o progresso do jogador
# =============================================================================


# =============================================================================
# PARTE 1 - IMPORTANDO OS SVGs NO GODOT
# =============================================================================

# O Godot 4 suporta SVG nativamente. Para importar:
#
# 1. Coloque os arquivos .svg em: res://assets/cards/
# 2. No FileSystem dock, clique no .svg
# 3. No Import dock, configure:
#    - Mode: Texture2D
#    - SVG Scale: 2.0 (para pixel art nítido em telas maiores)
#    - Filter: Nearest (ESSENCIAL para pixel art - evita blur)
# 4. Clique em "Re-Import"
#
# OU converta para PNG (recomendado para pixel art):
#   - Abra o SVG em qualquer editor (Inkscape, browser)
#   - Exporte como PNG em 160x160px
#   - No Import dock: Filter = Nearest, Mipmaps = OFF


# =============================================================================
# PARTE 2 - ESTRUTURA DA CENA DO CARD (card_phase.tscn)
# =============================================================================

# Hierarquia recomendada:
#
# Control (CardPhase) <── script: card_phase.gd
# ├── TextureButton (CardButton)          ← clicável
# │   ├── TextureRect (CardImage)         ← imagem da fase (SVG/PNG)
# │   └── TextureRect (LockOverlay)       ← ícone de cadeado (opcional)
# ├── ColorRect (GrayOverlay)             ← overlay cinza para bloqueado
# ├── AnimationPlayer (AnimPlayer)        ← animações
# └── AudioStreamPlayer (UnlockSound)    ← som de desbloqueio


# =============================================================================
# PARTE 3 - SHADER DE CINZA (gray_card.gdshader)
# =============================================================================
# Salve como: res://shaders/gray_card.gdshader

"""
shader_type canvas_item;

uniform float gray_amount : hint_range(0.0, 1.0) = 1.0;
uniform float brightness : hint_range(0.5, 1.5) = 1.0;

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    
    // Converte para escala de cinza
    float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    
    // Mistura entre colorido e cinza
    vec3 result = mix(color.rgb, vec3(gray), gray_amount);
    
    // Ajusta brilho (cards bloqueados ficam mais escuros)
    result *= brightness;
    
    COLOR = vec4(result, color.a);
}
"""


# =============================================================================
# PARTE 4 - SCRIPT DO CARD (card_phase.gd)
# =============================================================================

extends Control

# --- Configuração no Inspector ---
@export var phase_id: String = "1_1"        # Ex: "1_1", "1_2", "1_3"
@export var phase_texture: Texture2D        # Arraste o SVG/PNG aqui
@export var lock_texture: Texture2D         # Ícone de cadeado (opcional)
@export var unlock_sound: AudioStream       # Som ao desbloquear

# --- Estado ---
var is_unlocked: bool = false
var is_animating: bool = false

# --- Referências de nós ---
@onready var card_button: TextureButton = $CardButton
@onready var card_image: TextureRect = $CardButton/CardImage
@onready var lock_overlay: TextureRect = $CardButton/LockOverlay
@onready var gray_overlay: ColorRect = $GrayOverlay
@onready var anim_player: AnimationPlayer = $AnimPlayer
@onready var unlock_audio: AudioStreamPlayer = $UnlockSound

# Shader material (será aplicado em card_image)
var shader_material_instance: ShaderMaterial

# --- Sinal emitido ao clicar ---
signal card_pressed(phase_id: String)


func _ready() -> void:
    # Aplica a textura
    card_image.texture = phase_texture
    
    # Configura o shader de cinza
    var shader = load("res://shaders/gray_card.gdshader")
    shader_material_instance = ShaderMaterial.new()
    shader_material_instance.shader = shader
    card_image.material = shader_material_instance
    
    # Configura o som
    if unlock_sound:
        unlock_audio.stream = unlock_sound
    
    # Conecta o botão
    card_button.pressed.connect(_on_card_pressed)
    
    # Aplica estado inicial (sem animação)
    _apply_locked_state(animate: false)


func unlock(animate: bool = true) -> void:
    """Desbloqueia o card. Chame isto quando o jogador completar a fase anterior."""
    if is_unlocked:
        return
    
    is_unlocked = true
    
    if animate:
        _play_unlock_animation()
    else:
        _apply_unlocked_state(animate: false)


func lock() -> void:
    """Bloqueia o card (uso raro, ex: reset de progresso)."""
    is_unlocked = false
    _apply_locked_state(animate: false)


# --- Estados visuais ---

func _apply_locked_state(animate: bool = false) -> void:
    card_button.disabled = true
    lock_overlay.visible = true
    
    if animate:
        # Transição suave para cinza
        var tween = create_tween()
        tween.tween_method(
            func(v): shader_material_instance.set_shader_parameter("gray_amount", v),
            0.0, 1.0, 0.4
        )
        tween.parallel().tween_method(
            func(v): shader_material_instance.set_shader_parameter("brightness", v),
            1.0, 0.6, 0.4
        )
    else:
        shader_material_instance.set_shader_parameter("gray_amount", 1.0)
        shader_material_instance.set_shader_parameter("brightness", 0.6)
        modulate.a = 1.0


func _apply_unlocked_state(animate: bool = false) -> void:
    card_button.disabled = false
    lock_overlay.visible = false
    
    if animate:
        var tween = create_tween()
        tween.tween_method(
            func(v): shader_material_instance.set_shader_parameter("gray_amount", v),
            1.0, 0.0, 0.6
        )
        tween.parallel().tween_method(
            func(v): shader_material_instance.set_shader_parameter("brightness", v),
            0.6, 1.0, 0.6
        )
    else:
        shader_material_instance.set_shader_parameter("gray_amount", 0.0)
        shader_material_instance.set_shader_parameter("brightness", 1.0)


# --- Animação de desbloqueio ---

func _play_unlock_animation() -> void:
    is_animating = true
    
    # Som de desbloqueio
    if unlock_audio.stream:
        unlock_audio.play()
    
    var tween = create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_BACK)
    
    # 1. Flash branco
    gray_overlay.color = Color(1, 1, 1, 0.8)
    gray_overlay.visible = true
    tween.tween_property(gray_overlay, "color:a", 0.0, 0.3)
    
    # 2. Escala (pulse)
    tween.parallel().tween_property(self, "scale", Vector2(1.15, 1.15), 0.15)
    tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.25)
    
    # 3. Destrava cor (começa a ficar colorido)
    tween.tween_callback(func():
        _apply_unlocked_state(animate: true)
    )
    
    # 4. Shimmer (brilho percorrendo o card)
    tween.tween_callback(_play_shimmer_effect)
    
    # 5. Finaliza
    tween.tween_callback(func():
        is_animating = false
        gray_overlay.visible = false
    )


func _play_shimmer_effect() -> void:
    """Efeito de brilho passando pelo card após desbloqueio."""
    # Cria um ColorRect diagonal branco semi-transparente
    var shimmer = ColorRect.new()
    shimmer.color = Color(1, 1, 1, 0.4)
    shimmer.size = Vector2(40, 80)
    shimmer.position = Vector2(-40, 0)
    add_child(shimmer)
    
    var tween = create_tween()
    tween.tween_property(shimmer, "position:x", 120.0, 0.4)
    tween.tween_callback(shimmer.queue_free)


# --- Hover effect (card desbloqueado) ---

func _on_card_button_mouse_entered() -> void:
    if not is_unlocked or is_animating:
        return
    var tween = create_tween()
    tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.1)


func _on_card_button_mouse_exited() -> void:
    if not is_unlocked or is_animating:
        return
    var tween = create_tween()
    tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)


func _on_card_pressed() -> void:
    if is_unlocked and not is_animating:
        # Feedback visual de clique
        var tween = create_tween()
        tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.05)
        tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
        
        emit_signal("card_pressed", phase_id)


# =============================================================================
# PARTE 5 - GERENCIADOR DE PROGRESSO (progress_manager.gd - Autoload)
# =============================================================================
# Adicione este script como Autoload em Project > Project Settings > Autoload
# Nome: ProgressManager

"""
extends Node

# Arquivo de save
const SAVE_PATH = "user://mineralis_save.json"

# Dicionário de progresso: phase_id -> bool (desbloqueado?)
var unlocked_phases: Dictionary = {}

# Configuração inicial: quais fases começam desbloqueadas
const STARTING_PHASES = ["1_1"]  # Só a primeira fase começa aberta

signal phase_unlocked(phase_id: String)


func _ready() -> void:
    load_progress()


func is_phase_unlocked(phase_id: String) -> bool:
    return unlocked_phases.get(phase_id, false)


func unlock_phase(phase_id: String) -> void:
    if not unlocked_phases.get(phase_id, false):
        unlocked_phases[phase_id] = true
        save_progress()
        emit_signal("phase_unlocked", phase_id)


func complete_phase(phase_id: String) -> void:
    # Quando uma fase é completada, desbloqueia a próxima
    unlock_phase(phase_id)
    
    var next_id = _get_next_phase(phase_id)
    if next_id != "":
        unlock_phase(next_id)


func _get_next_phase(phase_id: String) -> String:
    # Mapeamento de progressão
    var progression = {
        "1_1": "1_2",
        "1_2": "1_3",
        "1_3": "2_1",  # América do Norte
        "2_1": "2_2",
        "2_2": "2_3",
        "2_3": "3_1",  # Europa
        # ... continue para todos os continentes
    }
    return progression.get(phase_id, "")


func save_progress() -> void:
    var save_data = {
        "unlocked_phases": unlocked_phases,
        "version": "1.0"
    }
    var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    file.store_string(JSON.stringify(save_data))
    file.close()


func load_progress() -> void:
    # Inicializa com fases iniciais
    for phase_id in STARTING_PHASES:
        unlocked_phases[phase_id] = true
    
    # Tenta carregar save existente
    if not FileAccess.file_exists(SAVE_PATH):
        return
    
    var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
    var json_string = file.get_as_text()
    file.close()
    
    var json = JSON.new()
    if json.parse(json_string) == OK:
        var data = json.get_data()
        if data.has("unlocked_phases"):
            unlocked_phases.merge(data["unlocked_phases"], true)
"""


# =============================================================================
# PARTE 6 - CENA DO MAPA (world_map.gd)
# =============================================================================

"""
extends Control

# Referências aos cards (arraste no Inspector ou use find_child)
@onready var card_1_1 = $Cards/Card_1_1
@onready var card_1_2 = $Cards/Card_1_2
@onready var card_1_3 = $Cards/Card_1_3


func _ready() -> void:
    # Aplica estado inicial a cada card baseado no save
    _setup_cards()
    
    # Escuta desbloqueios futuros
    ProgressManager.phase_unlocked.connect(_on_phase_unlocked)


func _setup_cards() -> void:
    var cards = {
        "1_1": card_1_1,
        "1_2": card_1_2,
        "1_3": card_1_3,
    }
    
    for phase_id in cards:
        if ProgressManager.is_phase_unlocked(phase_id):
            cards[phase_id].unlock(animate: false)  # Sem animação no setup
        else:
            cards[phase_id].lock()
        
        # Conecta o sinal de clique
        cards[phase_id].card_pressed.connect(_on_card_pressed)


func _on_phase_unlocked(phase_id: String) -> void:
    # Anima o card recém-desbloqueado
    match phase_id:
        "1_1": card_1_1.unlock(animate: true)
        "1_2": card_1_2.unlock(animate: true)
        "1_3": card_1_3.unlock(animate: true)


func _on_card_pressed(phase_id: String) -> void:
    # Navega para a fase
    match phase_id:
        "1_1": get_tree().change_scene_to_file("res://scenes/phase_1_1.tscn")
        "1_2": get_tree().change_scene_to_file("res://scenes/phase_1_2.tscn")
        "1_3": get_tree().change_scene_to_file("res://scenes/phase_1_3.tscn")


# Chame isto quando o jogador completar uma fase:
# ProgressManager.complete_phase("1_1")
"""


# =============================================================================
# PARTE 7 - DICAS ADICIONAIS DE ANIMAÇÃO
# =============================================================================

# ANIMAÇÃO DE ENTRADA DO MAPA (cards aparecem um por um)
"""
func _play_map_enter_animation() -> void:
    var cards = [card_1_1, card_1_2, card_1_3]
    
    for i in cards.size():
        var card = cards[i]
        card.modulate.a = 0.0
        card.position.y += 20
        
        var tween = create_tween()
        tween.set_delay(i * 0.15)  # Stagger de 150ms entre cada card
        tween.tween_property(card, "modulate:a", 1.0, 0.3)
        tween.parallel().tween_property(card, "position:y", card.position.y - 20, 0.3)
"""

# EFEITO DE "RESPIRAÇÃO" para card desbloqueado mas não jogado
"""
func _add_breathe_effect(card: Control) -> void:
    var tween = create_tween()
    tween.set_loops()
    tween.tween_property(card, "scale", Vector2(1.03, 1.03), 1.2)
    tween.tween_property(card, "scale", Vector2(1.0, 1.0), 1.2)
"""

# PARTÍCULAS DE ESTRELAS no desbloqueio (adicione um GPUParticles2D ao card)
"""
# No arquivo .tscn, configure GPUParticles2D:
# - Amount: 20
# - Lifetime: 1.0
# - Explosiveness: 0.9 (burst)
# - Em ParticleProcessMaterial:
#   - Direction: (0, -1, 0)
#   - Initial Velocity: 80-120
#   - Color: gradiente dourado (#FFD700 -> transparente)
#   - Scale: 3-6px
# Ative com: $Particles.emitting = true
"""
