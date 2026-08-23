class_name Weapon extends Node3D

signal started_anim(anim_name: String)
signal ended_anim(anim_name: String)

@export_category("weapon stats")
@export var wp_name: String
#@export var wp_model: PackedScene

@export_category("anims")
@export var anim_attack: StringName


@export_category("misc")
@export var anim_player: AnimationPlayer


func attack():
	started_anim.emit("attack")
	anim_player.play(anim_attack)


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == anim_attack:
		ended_anim.emit("attack")
