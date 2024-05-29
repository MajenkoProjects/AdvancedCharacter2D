@tool
extends CharacterBody2D
class_name AdvancedCharacter2D


signal fell(force : int)
signal landed
signal noticed(object : Node)
signal attack(object : Node, distance : int, direction: Vector2)

class Direction:
	const IDLE = Vector2i.ZERO
	const UP = Vector2i(0, -1)
	const DOWN = Vector2i(0, 1)
	const LEFT = Vector2i(-1, 0)
	const RIGHT = Vector2i(1, 0)

@export_category("Movement Settings")
@export_enum("Platform", "World") var MovementType : int = 0
@export_range(1, 1000) var WalkSpeed : int = 30
@export_range(1, 1000) var RunSpeed : int = 50
@export_range(1, 1000) var CrawlSpeed : int = 10
@export_range(1, 1000) var JumpPower : int = 250
@export_range(1, 1000) var FallSoundThreshold : int = 500

@export_category("Movement Actions")
@export var MoveLeft : String = "left"
@export var MoveRight : String = "right"
@export var MoveUp : String = "up"
@export var MoveDown : String = "down"
@export var Jump : String = "jump"
@export var Attack : String = "attack"

@export_category("Movement Modifiers")
@export var Run : String = "shift"
@export var Crawl : String = "control"

@export_category("Raycast")
@export_range(1, 1000) var ObservationLength : int = 50
@export_range(1, 1000) var AttackLength : int = 25

@export_category("Animation")

@export var LandingSound : AudioStream

@export var AnimatedSprite : AnimatedSprite2D :
	set(x):
		AnimatedSprite = x
		update_configuration_warnings()
@export var StartingDirection : Vector2i = Direction.IDLE

@export_category("Actions")
@export var Actions : Array[AdvancedCharacter2DMovement] = [] : 
	set(x):
		Actions = x
		for a in Actions:
			if a != null:
				if not a.is_connected("changed", _on_resource_changed):
					a.changed.connect(_on_resource_changed)
				if not a.is_connected("hitbox_updated", _on_hitbox_updated):
					a.hitbox_updated.connect(_on_hitbox_updated)
		update_configuration_warnings()

@export_category("Debug")
@export var EditorAction : int = 0 :
	set(x):
		x = clamp(x, 0, Actions.size()-1)
		EditorAction = x
		if Engine.is_editor_hint():
			_update_sprite_preview()
			
var _audio_movement : AudioStreamPlayer
var _audio_action : AudioStreamPlayer
var _audio_vocal : AudioStreamPlayer

var _collision_shape : CollisionShape2D

class BitField:
	var value : int = 0
	func bit_set(b : int, v : bool = true) -> void:
		if v:
			value |= (1 << b)
		else:
			value &= ~(1 << b)
	func is_set(b) -> bool:
		return (value & (1 << b)) == (1 << b)


enum PlayerActions { WALK, RUN, CRAWL, JUMP, FALL, ATTACK, LONGFALL }

var _state : BitField = BitField.new()

var _speed : int = 0
@onready var _direction : Vector2 = Vector2.ZERO
@onready var _facing : Vector2i = StartingDirection
var _jump_position : Vector2 = Vector2.ZERO
var _jump_speed : int = 0
var _observation_ray : ShapeCast2D
var _attack_ray : ShapeCast2D
var _last_col : Node = null

var _seen : Array[Node] = []

var _attack_timer : Timer

func _ready() -> void:
	_attack_timer = Timer.new()
	_attack_timer.one_shot = true
	_attack_timer.timeout.connect(_attack_finished)
	_attack_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	add_child(_attack_timer)
	_audio_movement = AudioStreamPlayer.new()
	_audio_movement.max_polyphony = 1
	add_child(_audio_movement)
	_audio_action = AudioStreamPlayer.new()
	_audio_action.max_polyphony = 1
	add_child(_audio_action)
	_audio_vocal = AudioStreamPlayer.new()
	_audio_vocal.max_polyphony = 1
	add_child(_audio_vocal)
	_collision_shape = CollisionShape2D.new()
	add_child(_collision_shape)

	if not Engine.is_editor_hint():
		_observation_ray = ShapeCast2D.new()
		add_child(_observation_ray)
		_observation_ray.collide_with_areas = true
		_observation_ray.collide_with_bodies = true
		_observation_ray.collision_mask = 0xFFFFFFFF

		_attack_ray = ShapeCast2D.new()
		add_child(_attack_ray)
		_attack_ray.collide_with_areas = true
		_attack_ray.collide_with_bodies = true
		#_attack_ray.enabled = false
		_attack_ray.collision_mask = 0xFFFFFFFF


	for a in Actions:
		if a != null:
			if Engine.is_editor_hint():
				if not a.is_connected("changed", _on_resource_changed):
					a.changed.connect(_on_resource_changed)
				if not a.is_connected("hitbox_updated", _on_hitbox_updated):
					a.hitbox_updated.connect(_on_hitbox_updated)
			else:
				a.AnimationDuration = _animation_duration(a.AnimationName)
	
	AnimatedSprite.animation_finished.connect(_animation_finished)
	
#	_switch_anim(StartingAction, true)
	
func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() == false:

		if MovementType == 0: # Platform
			var mode = 0


		_direction = Vector2(Input.get_axis(MoveLeft, MoveRight), 0)
		var is_run = Input.is_action_pressed(Run)
		var is_crawl = Input.is_action_pressed(Crawl)

		if _direction == Vector2.ZERO:
			_speed = 0
			_state.bit_set(PlayerActions.WALK, false)
		else:
			_state.bit_set(PlayerActions.WALK)
			_state.bit_set(PlayerActions.RUN, is_run)
			_state.bit_set(PlayerActions.CRAWL, is_crawl)
			if is_run:
				_speed = RunSpeed
			elif is_crawl:
				_speed = CrawlSpeed
			else:
				_speed = WalkSpeed

		if is_on_floor():
			if Input.is_action_just_pressed(Jump):
				print("JUMP!!!")
				_audio_movement.stop()
				_state.bit_set(PlayerActions.JUMP)
				velocity.y -= JumpPower
				_jump_position = global_position
				_jump_speed = _speed
				if _facing.x < 0:
					var action = get_action_by_type(AdvancedCharacter2DMovement.MovementType.JUMP_LEFT)
					_audio_action.stream = action.AudioFile
					_audio_action.play()
				elif _facing.x > 0:
					var action = get_action_by_type(AdvancedCharacter2DMovement.MovementType.JUMP_RIGHT)
					_audio_action.stream = action.AudioFile
					_audio_action.play()



		velocity.x = _direction.x * _speed
		
		if not is_on_floor():
			var gravity_vector : Vector2 = ProjectSettings.get_setting("physics/2d/default_gravity_vector")
			var gravity_magnitude : int = ProjectSettings.get_setting("physics/2d/default_gravity")
			velocity += (gravity_vector * gravity_magnitude * delta)

		_face_motion()


		if not is_on_floor():
			if _state.is_set(PlayerActions.JUMP):
				if global_position.y > _jump_position.y:
					_state.bit_set(PlayerActions.JUMP, false)
					_state.bit_set(PlayerActions.FALL)
					_audio_movement.stop()
			else:
				_state.bit_set(PlayerActions.FALL)
				_audio_movement.stop()

		var _starting_velocity = velocity
		_observation_ray.target_position = _facing * ObservationLength

		_attack_ray.target_position = _facing * AttackLength

		move_and_slide()

		var restart_animation : bool = false
		if Input.is_action_just_pressed(Attack):
			print("ATTACK!!!")
			_state.bit_set(PlayerActions.ATTACK)
			#_attack_ray.enabled = true
				
			if _facing.x < 0:
				var action = get_action_by_type(AdvancedCharacter2DMovement.MovementType.ATTACK_LEFT)
				_audio_action.stream = action.AudioFile
				_audio_action.play()
				_attack_timer.start(action.AnimationDuration)
				restart_animation = true
			elif _facing.x > 0:
				var action = get_action_by_type(AdvancedCharacter2DMovement.MovementType.ATTACK_RIGHT)
				_audio_action.stream = action.AudioFile
				_audio_action.play()
				_attack_timer.start(action.AnimationDuration)
				restart_animation = true
				
			if _attack_ray.get_collision_count() > 0:
				print(_attack_ray.get_collision_count())
				var closest_distance = (1<<63)-1
				var closest_body = null
				for i in _attack_ray.get_collision_count():
					var body = _attack_ray.get_collider(i)
					var distance = global_position.distance_to(body.global_position)
					attack.emit(body, distance, _facing)

		if _state.is_set(PlayerActions.ATTACK):
			if _facing == Direction.LEFT:
				_switch_anim(AdvancedCharacter2DMovement.MovementType.ATTACK_LEFT, restart_animation)
			elif _facing == Direction.RIGHT:
				_switch_anim(AdvancedCharacter2DMovement.MovementType.ATTACK_RIGHT, restart_animation)
			else:
				_switch_anim(AdvancedCharacter2DMovement.MovementType.IDLE)
		elif _state.is_set(PlayerActions.FALL):
			if _facing == Direction.LEFT:
				_switch_anim(AdvancedCharacter2DMovement.MovementType.FALL_LEFT)
			elif _facing == Direction.RIGHT:
				_switch_anim(AdvancedCharacter2DMovement.MovementType.FALL_RIGHT)
			else:
				_switch_anim(AdvancedCharacter2DMovement.MovementType.IDLE)
		elif _state.is_set(PlayerActions.JUMP):
			if _facing == Direction.LEFT:
				_switch_anim(AdvancedCharacter2DMovement.MovementType.JUMP_LEFT)
			elif _facing == Direction.RIGHT:
				_switch_anim(AdvancedCharacter2DMovement.MovementType.JUMP_RIGHT)
			else:
				_switch_anim(AdvancedCharacter2DMovement.MovementType.IDLE)
		elif _state.is_set(PlayerActions.RUN):
			if _facing == Direction.LEFT:
				_switch_anim(AdvancedCharacter2DMovement.MovementType.RUN_LEFT)
			elif _facing == Direction.RIGHT:
				_switch_anim(AdvancedCharacter2DMovement.MovementType.RUN_RIGHT)
			else:
				_switch_anim(AdvancedCharacter2DMovement.MovementType.IDLE)
		elif _state.is_set(PlayerActions.CRAWL):
			if _facing == Direction.LEFT:
				_switch_anim(AdvancedCharacter2DMovement.MovementType.CRAWL_LEFT)
			elif _facing == Direction.RIGHT:
				_switch_anim(AdvancedCharacter2DMovement.MovementType.CRAWL_RIGHT)
			else:
				_switch_anim(AdvancedCharacter2DMovement.MovementType.IDLE)
		elif _state.is_set(PlayerActions.WALK):
			if _facing == Direction.LEFT:
				_switch_anim(AdvancedCharacter2DMovement.MovementType.WALK_LEFT)
			elif _facing == Direction.RIGHT:
				_switch_anim(AdvancedCharacter2DMovement.MovementType.WALK_RIGHT)
			else:
				_switch_anim(AdvancedCharacter2DMovement.MovementType.IDLE)
		else:
			if _facing == Direction.LEFT:
				_switch_anim(AdvancedCharacter2DMovement.MovementType.IDLE_LEFT)
			elif _facing == Direction.RIGHT:
				_switch_anim(AdvancedCharacter2DMovement.MovementType.IDLE_RIGHT)
			else:
				_switch_anim(AdvancedCharacter2DMovement.MovementType.IDLE)

		if _observation_ray.get_collision_count() > 0:
			var _new_seen : Array[Node] = []
			for i in _observation_ray.get_collision_count():
				var col = _observation_ray.get_collider(i)
				if col != self:
					if not _seen.has(col):
						_new_seen.push_back(col)

			if _new_seen.size() > 0:
				for col in _new_seen:
					noticed.emit(col)
				_seen.clear()
				_seen.assign(_new_seen)
		else:
			_seen.clear()



		if is_on_floor() and _state.is_set(PlayerActions.JUMP):
			_state.bit_set(PlayerActions.JUMP, false)

		if _state.is_set(PlayerActions.FALL):
			if is_on_floor():
				_state.bit_set(PlayerActions.FALL, false)
				_state.bit_set(PlayerActions.LONGFALL, false)
				if _starting_velocity.y > FallSoundThreshold: 
					print("Landed %d" % _starting_velocity.y)
					_audio_vocal.stream = LandingSound
					_audio_vocal.play()
			else:
				if _starting_velocity.y > FallSoundThreshold:
					if not _state.is_set(PlayerActions.LONGFALL):
						_state.bit_set(PlayerActions.LONGFALL)
						if _facing.x < 0:
							var action = get_action_by_type(AdvancedCharacter2DMovement.MovementType.FALL_LEFT)
							_audio_vocal.stream = action.AudioFile
							_audio_vocal.play()
						elif _facing.x > 0:
							var action = get_action_by_type(AdvancedCharacter2DMovement.MovementType.FALL_RIGHT)
							_audio_vocal.stream = action.AudioFile
							_audio_vocal.play()




func _face_motion() -> void:
	if velocity.x > 0:
		_facing = Direction.RIGHT
	elif velocity.x < 0:
		_facing = Direction.LEFT




func _switch_anim(type : AdvancedCharacter2DMovement.MovementType, force : bool = false) -> void:
	
	var action = get_action_by_type(type)
	if action == null:
		action = get_action_by_type(type & 0xF000)
	if action == null:
		action = get_action_by_type(type & 0x000F)
	if action == null:
		action = get_action_by_type(0)
	
	AnimatedSprite.flip_h = action.FlipH
	AnimatedSprite.flip_v = action.FlipV
	_collision_shape.shape = action.Hitbox
	_collision_shape.position = action.HitboxOffset
	_observation_ray.position = action.HitboxOffset
	_observation_ray.shape = _collision_shape.shape
	_attack_ray.position = action.HitboxOffset
	_attack_ray.shape = _collision_shape.shape
	if (AnimatedSprite.animation != action.AnimationName) or force:
		AnimatedSprite.play(action.AnimationName)

	match action.Type & AdvancedCharacter2DMovement.MOVE_TYPE_MASK:

		AdvancedCharacter2DMovement.MOVE_WALK, AdvancedCharacter2DMovement.MOVE_RUN, AdvancedCharacter2DMovement.MOVE_CRAWL, AdvancedCharacter2DMovement.MOVE_IDLE:
			if (action.AudioFile != _audio_movement.stream) or force or not _audio_movement.playing:
				if action.AudioFile == null:
					_audio_movement.stop()
					_audio_movement.stream = null
				else:
					_audio_movement.stop()
					_audio_movement.stream = action.AudioFile
					_audio_movement.play()

		
func _get_configuration_warnings() -> PackedStringArray:
	var out : PackedStringArray = []
	if Actions.size() == 0:
		out.push_back("There are no actions assigned to this node")
	for i in Actions.size():
		if Actions[i] == null:
			out.push_back("Action %d has no resource loaded" % i)
			continue
		if Actions[i].Hitbox == null:
			out.push_back("Action %d has an empty hitbox" % i)
	if AnimatedSprite == null:
		out.push_back("No AnimatedSprite2D is assigned to this node")
	return out

func _on_resource_changed() -> void:
	_update_sprite_preview()
	update_configuration_warnings()

func get_action_by_type(action_type : AdvancedCharacter2DMovement.MovementType) -> AdvancedCharacter2DMovement:
	for action in Actions:
		if action.Type == action_type:
			return action
	return null

func _on_hitbox_updated(resource : Resource) -> void:
	if resource == Actions[EditorAction]:
		_collision_shape.shape = resource.Hitbox
		_collision_shape.position = resource.HitboxOffset

func _animation_finished() -> void:
	print("Animation finished %s" % AnimatedSprite.animation)
	#if _state.is_set(PlayerActions.ATTACK):
		#_state.bit_set(PlayerActions.ATTACK, false)

func _update_sprite_preview() -> void:
	var action = Actions[EditorAction]
	if AnimatedSprite != null:
		AnimatedSprite.flip_h = action.FlipH
		AnimatedSprite.flip_v = action.FlipV
		AnimatedSprite.play(action.AnimationName)
		_collision_shape.shape = action.Hitbox
		_collision_shape.position = action.HitboxOffset


func _animation_duration(name : String) -> float:
	var framecount = AnimatedSprite.sprite_frames.get_frame_count(name)
	var speed = AnimatedSprite.sprite_frames.get_animation_speed(name)
	return float(framecount) / float(speed)

func _attack_finished() -> void:
	print("Attack finished")
	_state.bit_set(PlayerActions.ATTACK, false)
	#_attack_ray.enabled = false
