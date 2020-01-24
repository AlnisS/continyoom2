extends Spatial

# all signals (comment added for visual consistency)
signal ground_hit # once on landing on ground
signal timescale_updated(new_timescale) # once per physics update
signal targ_drift_updated(new_targ_drift) # once per physics update
signal curr_steer_updated(new_curr_steer) # once per physics update

# debug drawing resource
onready var draw: ImmediateGeometry = get_node("../draw")
var m: SpatialMaterial = SpatialMaterial.new()

# time travel data
var timescale: float = 1
var history: Array = Array()
var latest_state: Dictionary

# car physics and camera physics states
onready var initial_phys_transform: Transform = get_global_transform()
var phys_transform: Transform
onready var initial_camera_transform: Transform = get_global_transform()
var camera_transform: Transform

# drifting variables
var drift_hint: int = 0 # proposed drift to begin when ground is hit
var targ_drift: int = 0 # drift control (left, none, right)
var curr_drift: float = 0 # internal interpolation variable

# steering variables
var targ_steer: float = 0 # steering control (-1 to 1)
var curr_steer: float = 0 # internal interpolation variable

# velocities
var pos_vel: Vector3 = Vector3(0, 0, 0)
var rot_vel: float = 0
var vrt_vel: float = 0 # TODO: combine with pos_vel
var override_motion: Vector3 = Vector3(0, 0, 0)

# all constants (comment added for visual consistency)
const STEER_SPEED = 14
const DRIFT_SPEED = 8
const HEIGHT_ABOVE_GROUND = 0
const SEARCH_LOW = .5
const SEARCH_HIGH = .5
const GRAVITY = -40
const REVERSE_SPEED = 1
const SLOW_TIMESCALE = .5
const NORMAL_TIMESCALE = 1
const MAX_TIMESCALE = 2
const BOOP_DISTANCE = .375
const SPEED_FACTOR = 9999
const MIN_DRIFT_SPEED = 5
const WALL_COLLISION_HEIGHT = .125
const WALL_BOUNCE_FACTOR = 1
const OVERRIDE_SPEED = 30


var cc = 100
var MAX_SPEED = 7
var STEER_FACTOR = 1
var DRIFT_FACTOR = 2
var DRIFT_INFLUENCE = .75
var DRIFT_STEER_INFLUENCE = 1
var SPEED_DEC = 13
var ACTUAL_ACCEL = 20

func _prepare_cc(var cc):
	var lcc = (cc - 50) / 150.0
	MAX_SPEED = lerp(7, 12, lcc)
	STEER_FACTOR = lerp(1.5, 1, lcc)
	DRIFT_FACTOR = lerp(2, 2, lcc)
	DRIFT_INFLUENCE = lerp(.75, .75, lcc)
	DRIFT_STEER_INFLUENCE = lerp(1, 1, lcc)
	SPEED_DEC = lerp(13, 8, lcc)
	ACTUAL_ACCEL = lerp(20, 10, lcc)

func _ready():
	self.connect("ground_hit", self, "_on_Car_ground_hit")
	_reset()


func _physics_process(delta):
	print(override_motion)
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
	transform.origin = phys_transform.origin
	transform = transform.interpolate_with(phys_transform, .1 )
	$Camera.transform = camera_transform
	phys_transform = phys_transform.orthonormalized()
	transform = transform.orthonormalized()
	$Camera.transform = $Camera.transform.orthonormalized()
	emit_signal("timescale_updated", timescale)
	emit_signal("targ_drift_updated", targ_drift)
	emit_signal("curr_steer_updated", curr_steer)


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
	_collide_waluigi_cannon(delta)
	if override_motion == Vector3(0, 0, 0):
		if Input.is_action_just_pressed("bhop") and vrt_vel == 0:
			vrt_vel = 5
		if !Input.is_action_pressed("bhop"):
			targ_drift = 0
		_update_steer(delta)
		_update_drift(delta)
		_move(delta, _update_speed(delta))
		_collide_walls(delta)
	else:
		var om: Vector3 = override_motion.normalized() * delta * OVERRIDE_SPEED
		phys_transform.origin += om
		override_motion -= om
		vrt_vel = 0
		if override_motion.length() < .5:
			override_motion = Vector3(0, 0, 0)
	_move_camera(delta)


func _update_steer(delta: float) -> void:
	var mult = 1
	if vrt_vel != 0:
		mult = .5
	if Input.is_action_pressed("steer_left"):
		curr_steer = _derp(curr_steer, -1, delta * STEER_SPEED * mult)
	elif Input.is_action_pressed("steer_right"):
		curr_steer = _derp(curr_steer, 1, delta * STEER_SPEED * mult)
	else:
		curr_steer = _derp(curr_steer, 0, delta * STEER_SPEED * mult)


func _update_drift(delta: float) -> void:
	if Input.is_action_pressed("bhop") and !drift_hint and vrt_vel:
		if Input.is_action_pressed("steer_left"):
			drift_hint = -1
		if Input.is_action_pressed("steer_right"):
			drift_hint = 1
	if !Input.is_action_pressed("bhop"):
		drift_hint = 0


func _update_speed(delta: float) -> float:
	var result = pos_vel.length()
	if !Input.is_action_pressed("brake"):
		result += SPEED_FACTOR * delta
	result -= SPEED_DEC * delta
	result = clamp(result, 0, MAX_SPEED)
	if result < MIN_DRIFT_SPEED:
		targ_drift = 0
	return result


func _collide_walls(delta: float) -> void:
	var space_state = get_world().get_direct_space_state()
	var tmp_origin = phys_transform.origin + phys_transform.basis.y * WALL_COLLISION_HEIGHT
	var hit = null
	var r_hit = space_state.intersect_ray(tmp_origin, tmp_origin + phys_transform.basis.x * BOOP_DISTANCE, [], 0x00000004)
	var l_hit = space_state.intersect_ray(tmp_origin, tmp_origin - phys_transform.basis.x * BOOP_DISTANCE, [], 0x00000004)
	var f_hit = space_state.intersect_ray(tmp_origin, tmp_origin - phys_transform.basis.z * BOOP_DISTANCE, [], 0x00000004)
	var b_hit = space_state.intersect_ray(tmp_origin, tmp_origin + phys_transform.basis.z * BOOP_DISTANCE, [], 0x00000004)
	
#	draw.set_material_override(m)
#	draw.clear()
#	draw.begin(Mesh.PRIMITIVE_LINE_STRIP, null)
#	draw.add_vertex(tmp_origin)
#	draw.add_vertex(tmp_origin + phys_transform.basis.x * BOOP_DISTANCE)
#	draw.add_vertex(tmp_origin)
#	draw.add_vertex(tmp_origin - phys_transform.basis.x * BOOP_DISTANCE)
#	draw.add_vertex(tmp_origin)
#	draw.add_vertex(tmp_origin - phys_transform.basis.z * BOOP_DISTANCE)
#	draw.add_vertex(tmp_origin)
#	draw.add_vertex(tmp_origin + phys_transform.basis.z * BOOP_DISTANCE)
#	draw.end()

	
	if l_hit:
		hit = l_hit
	if r_hit:
		hit = r_hit
	if f_hit:
		hit = f_hit
	if b_hit:
		hit = b_hit
	
	if hit != null:
#		phys_transform.origin += hit_normal * BOOP_DISTANCE
		var direction = phys_transform.xform_inv(phys_transform.origin + hit.normal)
		var angle_between = atan2(pos_vel.z, pos_vel.x) - atan2(direction.z, direction.x)
		var eject_direction = direction.rotated(Vector3(0, 1, 0), PI + angle_between)
		phys_transform.origin += phys_transform.basis.x * eject_direction.x * pos_vel.length() * delta
		phys_transform.origin += phys_transform.basis.z * eject_direction.z * pos_vel.length() * delta
		var eject_velocity = eject_direction.normalized() * pos_vel.length() * WALL_BOUNCE_FACTOR
		pos_vel.x = eject_velocity.x * 1.0
		pos_vel.z = eject_velocity.z * 1.0


func _move(delta: float, speed: float) -> void:
	if curr_drift < targ_drift:
		curr_drift = clamp(curr_drift + DRIFT_SPEED * delta, -1, targ_drift)
	if curr_drift > targ_drift:
		curr_drift = clamp(curr_drift - DRIFT_SPEED * delta, targ_drift, +1)
	var steer_rot = -curr_steer * delta * STEER_FACTOR
	var drift_rot = -(curr_steer * DRIFT_STEER_INFLUENCE + targ_drift * DRIFT_INFLUENCE) * delta * DRIFT_FACTOR
	var steer_vel = Vector3(0, 0, -speed)
	var drift_vel = Vector3(-cos(curr_drift * .75 - PI * .5) * speed, 0, sin(curr_drift * .75 - PI * .5) * speed)
	var rot = lerp(steer_rot, drift_rot, abs(curr_drift))
	var vel = lerp(steer_vel, drift_vel, abs(curr_drift))
	pos_vel.x = _derp(pos_vel.x, vel.x, delta * ACTUAL_ACCEL)
	pos_vel.z = _derp(pos_vel.z, vel.z, delta * ACTUAL_ACCEL)
	phys_transform.basis = phys_transform.basis.rotated(phys_transform.basis.y, rot)
	phys_transform.origin += phys_transform.basis.x * pos_vel.x * delta + phys_transform.basis.z * pos_vel.z * delta
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


func _collide_waluigi_cannon(delta: float) -> void:
	var space_state = get_world().get_direct_space_state()
	var hit = space_state.intersect_ray(
			phys_transform.origin + phys_transform.basis.y * SEARCH_HIGH,
			phys_transform.origin - phys_transform.basis.y * SEARCH_LOW,
			[], 0x00000020)
	if hit:
#		print(hit.collider)
		override_motion = Vector3(0, 32.2, -84.5)


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
	if drift_hint:
		targ_drift = drift_hint
		return
	if Input.is_action_pressed("steer_left"):
		targ_drift = -1
	if Input.is_action_pressed("steer_right"):
		targ_drift = 1


func _keyboard_timescale() -> void:
	if Input.is_action_pressed("reverse"):
		timescale = -REVERSE_SPEED
	elif Input.is_action_pressed("extra_speed"):
		timescale = MAX_TIMESCALE
	else:
		timescale = NORMAL_TIMESCALE
	if Input.is_action_pressed("slow"):
		timescale *= SLOW_TIMESCALE


func set_start(tfm: Transform) -> void:
	initial_phys_transform = tfm
	initial_camera_transform = tfm
	_reset()


func _reset() -> void:
	phys_transform = initial_phys_transform
	pos_vel = Vector3(0, 0, 0)
	rot_vel = 0
	vrt_vel = 0
	history = Array()
	_prepare_cc(cc)


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
	state.camera_transform = camera_transform
	state.override_motion = override_motion
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
	camera_transform = state.camera_transform
	override_motion = state.override_motion


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
	state.curr_drift = lerp(earlier_state.curr_drift, later_state.curr_drift, lerp_amount)
	state.camera_transform = earlier_state.camera_transform.interpolate_with(later_state.camera_transform, lerp_amount)
	state.override_motion = lerp(earlier_state.override_motion, later_state.override_motion, lerp_amount)
	return state


func _on_Car_ground_hit():
	vrt_vel = 0
	if Input.is_action_pressed("bhop") and targ_drift == 0:
		_just_drift()
		drift_hint = 0


func _move_camera(delta: float) -> void:
	var prev_camera_transform = $Camera.transform
	camera_transform = phys_transform.translated(Vector3(0, .75, 1))
	$Camera.set_as_toplevel(true)
	$Camera.transform = camera_transform
	$Camera.look_at(phys_transform.origin, phys_transform.basis.y)
	$Camera.rotate_object_local(Vector3(1, 0, 0), .4)
	camera_transform.basis = prev_camera_transform.basis.slerp($Camera.transform.basis, 5 * delta)
	camera_transform.origin = prev_camera_transform.origin.linear_interpolate($Camera.transform.origin, 10 * delta)


func _derp(from: float, to: float, step: float):
	if from < to:
		return clamp(from + step, from, to)
	if from > to:
		return clamp(from - step, to, from)
	return to
