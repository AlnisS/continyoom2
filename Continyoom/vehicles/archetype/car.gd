extends Spatial

signal ground_hit

var history: Array = Array()
var latest_state: Dictionary
onready var initial_transform: Transform = get_global_transform()
var phys_transform: Transform

var targ_steer = 0
var targ_drift = 0
var curr_steer = 0
var curr_drift = 0

var pos_vel: Vector3 = Vector3(0, 0, 0)
var rot_vel: float = 0
var vrt_vel: float = 0

var timescale = 1

const STEER_SPEED = 8
const DRIFT_SPEED = 3
const HEIGHT_ABOVE_GROUND = 0
const SEARCH_LOW = .125
const SEARCH_HIGH = .25
const GRAVITY = -40
const REVERSE_SPEED = 1
const SLOW_TIMESCALE = .5
const NORMAL_TIMESCALE = 1
const MAX_TIMESCALE = 2
const BOOP_DISTANCE = .375
const SPEED_FACTOR = 10
const MIN_DRIFT_SPEED = 5
const SPEED_DEC = 6
const MAX_SPEED = 10

func _ready():
	self.connect("ground_hit", self, "_on_Car_ground_hit")
	_reset()


func _physics_process(delta):
	if Input.is_action_just_pressed("reset"):
		_reset()
	_keyboard_timescale()
	delta *= timescale
	if delta < 0:
		_step_backward(-delta)
	else:
		_step_forward(delta)
	_collide_ground(delta)
	set_as_toplevel(true)
	transform = phys_transform


func _step_backward(delta: float) -> void:
	while history.size() > 0 and delta >= history.back().remaining_delta:
		latest_state = history.pop_back()
		delta -= latest_state.remaining_delta
	if history.size() == 0:
		return
	history.back().remaining_delta -= delta
	_set_state_from_dictionary(_interpolate_states(history.back(), latest_state, history.back().remaining_delta))


func _step_forward(delta: float) -> void:
	history.push_back(_get_state_as_dictionary(delta))
	if Input.is_action_just_pressed("bhop") and vrt_vel == 0:
		vrt_vel = 10
	if !Input.is_action_pressed("bhop"):
		targ_drift = 0
	_update_steer(delta)
	_update_drift(delta)
	_move(delta, _update_speed(delta))
	_collide_walls(delta)


func _update_steer(delta: float) -> void:
	if Input.is_action_pressed("steer_left"):
		curr_steer = clamp(curr_steer - delta * STEER_SPEED, -1, 1)
	elif Input.is_action_pressed("steer_right"):
		curr_steer = clamp(curr_steer + delta * STEER_SPEED, -1, 1)
	elif curr_steer < 0:
		curr_steer = clamp(curr_steer + delta * STEER_SPEED, -1, 0)
	elif curr_steer > 0:
		curr_steer = clamp(curr_steer - delta * STEER_SPEED, 0, 1)


func _update_drift(delta: float) -> void:
	pass


func _update_speed(delta: float) -> float:
	var result = pos_vel.length()
	if !Input.is_action_pressed("brake"):
		result += SPEED_FACTOR * delta
	result -= SPEED_DEC * delta
	result = clamp(result, 0, MAX_SPEED)
	if result < MIN_DRIFT_SPEED * timescale:
		targ_drift = 0
	return result


func _collide_walls(delta: float) -> void:
	var space_state = get_world().get_direct_space_state()
	var r_hit = space_state.intersect_ray(phys_transform.origin, phys_transform.origin + phys_transform.basis.x * BOOP_DISTANCE, [], 0x00000004)
	var l_hit = space_state.intersect_ray(phys_transform.origin, phys_transform.origin - phys_transform.basis.x * BOOP_DISTANCE, [], 0x00000004)
	var f_hit = space_state.intersect_ray(phys_transform.origin, phys_transform.origin - phys_transform.basis.z * BOOP_DISTANCE, [], 0x00000004)
	var b_hit = space_state.intersect_ray(phys_transform.origin, phys_transform.origin + phys_transform.basis.z * BOOP_DISTANCE, [], 0x00000004)
	if l_hit:
		phys_transform = phys_transform.translated(+phys_transform.basis.x * (BOOP_DISTANCE - l_hit.position.distance_to(phys_transform.origin)))
	if r_hit:
		phys_transform = phys_transform.translated(-phys_transform.basis.x * (BOOP_DISTANCE - r_hit.position.distance_to(phys_transform.origin)))
	if f_hit:
		phys_transform = phys_transform.translated(+phys_transform.basis.z * (BOOP_DISTANCE - f_hit.position.distance_to(phys_transform.origin)))
	if b_hit:
		phys_transform = phys_transform.translated(-phys_transform.basis.z * (BOOP_DISTANCE - b_hit.position.distance_to(phys_transform.origin)))


func _move(delta: float, speed: float) -> void:
	if curr_drift < targ_drift:
		curr_drift = clamp(curr_drift + DRIFT_SPEED * delta, -1, targ_drift)
	if curr_drift > targ_drift:
		curr_drift = clamp(curr_drift - DRIFT_SPEED * delta, targ_drift, +1)
	var steer_rot = -curr_steer * delta * 1
	var drift_rot = -(curr_steer * 0.5 + targ_drift * 0.75) * delta * 2
	var steer_vel = Vector3(0, 0, -speed)
	var drift_vel = Vector3(-cos(curr_drift * .75 - PI * .5) * speed, 0, sin(curr_drift * .75 - PI * .5) * speed)
	var rot = lerp(steer_rot, drift_rot, abs(curr_drift))
	var vel = lerp(steer_vel, drift_vel, abs(curr_drift))
	pos_vel = vel
	phys_transform.basis = phys_transform.basis.rotated(phys_transform.basis.y, rot)
	phys_transform.origin += phys_transform.basis.x * vel.x * delta + phys_transform.basis.z * vel.z * delta
	phys_transform.origin += phys_transform.basis.y * vrt_vel * delta


func _collide_hit(hit: Dictionary) -> void:
	var plane = Plane(
			phys_transform.origin,
			phys_transform.origin + hit.normal,
			phys_transform.origin + phys_transform.basis.y)
	var rotation_angle = phys_transform.basis.y.angle_to(hit.normal)
	if rotation_angle != 0 and plane.normal != Vector3(0, 0, 0):
		phys_transform.basis = phys_transform.basis.rotated(plane.normal, rotation_angle)
	phys_transform.origin = hit.position + phys_transform.basis.y * HEIGHT_ABOVE_GROUND


func _collide_ground(delta: float) -> void:
	var space_state = get_world().get_direct_space_state()
	var upper_hit = space_state.intersect_ray(
			phys_transform.origin + phys_transform.basis.y * SEARCH_HIGH,
			phys_transform.origin - phys_transform.basis.y * 0.001,
			[], 0x00000002)
	var lower_hit = space_state.intersect_ray(
			phys_transform.origin + phys_transform.basis.y * 0.001,
			phys_transform.origin - phys_transform.basis.y * SEARCH_LOW,
			[], 0x00000002)
	if vrt_vel <= 0 and upper_hit:
		_collide_hit(upper_hit)
		if vrt_vel < 0:
			emit_signal("ground_hit")
	elif vrt_vel == 0 and lower_hit:
		_collide_hit(lower_hit)
	else:
		vrt_vel += GRAVITY * delta


func _just_drift() -> void:
	if Input.is_action_pressed("steer_left"):
		targ_drift = -1
	if Input.is_action_pressed("steer_right"):
		targ_drift = 1


func _keyboard_timescale() -> void:
	if Input.is_action_pressed("reverse"):
		timescale = -REVERSE_SPEED
	elif Input.is_action_pressed("extra_speed"):
		timescale = MAX_TIMESCALE
	elif Input.is_action_pressed("slow"):
		timescale = SLOW_TIMESCALE
	else:
		timescale = NORMAL_TIMESCALE


func _reset() -> void:
	phys_transform = initial_transform
	pos_vel = Vector3(0, 0, 0)
	rot_vel = 0
	vrt_vel = 0
	history = Array()


func _get_state_as_dictionary(delta: float) -> Dictionary:
	var state = Dictionary()
	state.phys_transform = phys_transform
	state.pos_vel = pos_vel
	state.rot_vel = rot_vel
	state.vrt_vel = vrt_vel
	state.delta = delta
	state.remaining_delta = delta
	state.targ_steer = targ_steer
	state.targ_drift = targ_drift
	state.curr_steer = curr_steer
	state.curr_drift = curr_drift
	return state


func _set_state_from_dictionary(state: Dictionary) -> void:
	phys_transform = state.phys_transform
	pos_vel = state.pos_vel
	rot_vel = state.rot_vel
	vrt_vel = state.vrt_vel
	targ_steer = state.targ_steer
	targ_drift = state.targ_drift
	curr_steer = state.curr_steer
	curr_drift = state.curr_drift


func _interpolate_states(later_state: Dictionary, earlier_state: Dictionary, delta: float):
	var state := Dictionary()
	var lerp_amount: float = 1 - delta / earlier_state.delta
	state.phys_transform = earlier_state.phys_transform.interpolate_with(later_state.phys_transform, lerp_amount)
	state.pos_vel = lerp(earlier_state.pos_vel, later_state.pos_vel, lerp_amount)
	state.rot_vel = lerp(earlier_state.rot_vel, later_state.rot_vel, lerp_amount)
	state.vrt_vel = lerp(earlier_state.vrt_vel, later_state.vrt_vel, lerp_amount)
	state.delta = null
	state.remaining_delta = null
	state.targ_steer = lerp(earlier_state.targ_steer, later_state.targ_steer, lerp_amount)
	state.targ_drift = lerp(earlier_state.targ_drift, later_state.targ_drift, lerp_amount)
	state.curr_steer = lerp(earlier_state.curr_steer, later_state.curr_steer, lerp_amount)
	state.curr_drift = lerp(earlier_state.curr_steer, later_state.curr_steer, lerp_amount)
	return state


func _on_Car_ground_hit():
	vrt_vel = 0
	if Input.is_action_pressed("bhop"):
		_just_drift()
