@tool
extends Resource
class_name AdvancedCharacter2DMovement

signal hitbox_updated(res : Resource)

enum MovementType {
	IDLE 			= 0x0000,
	IDLE_LEFT		= 0x0001,
	IDLE_RIGHT		= 0x0002,
	IDLE_UP			= 0x0003,
	IDLE_DOWN		= 0x0004,
	WALK_LEFT 		= 0x1001,
	WALK_RIGHT 		= 0x1002,
	WALK_UP 		= 0x1003,
	WALK_DOWN 		= 0x1004,
	RUN_LEFT 		= 0x2001,
	RUN_RIGHT 		= 0x2002,
	RUN_UP 			= 0x2003,
	RUN_DOWN 		= 0x2004,
	CRAWL_LEFT		= 0x3001,
	CRAWL_RIGHT		= 0x3002,
	CRAWL_UP		= 0x3003,
	CRAWL_DOWN		= 0x3004,
	JUMP_IDLE		= 0x4000,
	JUMP_LEFT		= 0x4001,
	JUMP_RIGHT		= 0x4002,
	JUMP_UP			= 0x4003,
	JUMP_DOWN		= 0x4004,
	FALL_IDLE		= 0x5000,
	FALL_LEFT		= 0x5001,
	FALL_RIGHT		= 0x5002,
	FALL_UP			= 0x5003,
	FALL_DOWN		= 0x5004,
	ATTACK_IDLE		= 0x6000,
	ATTACK_LEFT		= 0x6001,
	ATTACK_RIGHT	= 0x6002,
	ATTACK_UP		= 0x6003,
	ATTACK_DOWN		= 0x6004,
}

const MOVE_IDLE = 0x0000
const MOVE_LEFT = 0x0001
const MOVE_RIGHT = 0x0002
const MOVE_UP = 0x0003
const MOVE_DOWN = 0x0004
const MOVE_WALK = 0x1000
const MOVE_RUN = 0x2000
const MOVE_CRAWL = 0x3000
const MOVE_JUMP = 0x4000
const MOVE_FALL = 0x5000
const MOVE_ATTACK = 0x6000
const MOVE_TYPE_MASK = 0xF000
const MOVE_DIR_MASK = 0x000F

@export var Type : MovementType = MovementType.IDLE
@export var HitboxOffset : Vector2 = Vector2.ZERO :
	set(x):
		HitboxOffset = x
		hitbox_updated.emit(self)
		emit_changed()
@export var Hitbox : Shape2D :
	set(x):
		Hitbox = x
		hitbox_updated.emit(self)
		emit_changed()
@export var AnimationName : String = "default" :
	set(x):
		AnimationName = x
		emit_changed()
@export var FlipH : bool = false :
	set(x):
		FlipH = x
		emit_changed()
@export var FlipV : bool = false :
	set(x):
		FlipV = x
		emit_changed()
@export var AudioFile : AudioStream 

var AnimationDuration : float = 0
