extends Spatial

signal ground_hit
signal timescale_updated(new_timescale)

onready var draw: ImmediateGeometry = get_node("../draw")
var m = SpatialMaterial.new()

var history: Array = Array()
var latest_state: Dictionary
onready var initial_phys_transform: Transform = get_global_transform()
onready var initial_camera_transform: Transform = get_global_transform()
var phys_transform: Transform
var camera_transform: Transform

var targ_steer = 0
var targ_drift = 0
var curr_steer = 0
var curr_drift = 0

var pos_vel: Vector3 = Vector3(0, 0, 0)
var rot_vel: float = 0
var vrt_vel: float = 0

var timescale = 1

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
const SPEED_FACTOR = 10
const MIN_DRIFT_SPEED = 5
const SPEED_DEC = 6
const MAX_SPEED = 10
const WALL_COLLISION_HEIGHT = .125

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
	transform.origin = phys_transform.origin
	transform = transform.interpolate_with(phys_transform, .5)
	$Camera.transform = camera_transform
	emit_signal("timescale_updated", timescale)


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
		vrt_vel = 5
	if !Input.is_action_pressed("bhop"):
		targ_drift = 0
	_update_steer(delta)
	_update_drift(delta)
	_move(delta, _update_speed(delta))
	_collide_walls(delta)
	_move_camera(delta)


func _update_steer(delta: float) -> void:
	var mult = 1
	if vrt_vel != 0:
		mult = .5
	if Input.is_action_pressed("steer_left"):
		curr_steer = clamp(curr_steer - delta * STEER_SPEED * mult, -1, 1)
	elif Input.is_action_pressed("steer_right"):
		curr_steer = clamp(curr_steer + delta * STEER_SPEED * mult, -1, 1)
	elif curr_steer < 0:
		curr_steer = clamp(curr_steer + delta * STEER_SPEED * mult, -1, 0)
	elif curr_steer > 0:
		curr_steer = clamp(curr_steer - delta * STEER_SPEED * mult, 0, 1)


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
	var tmp_origin = phys_transform.origin + phys_transform.basis.y * WALL_COLLISION_HEIGHT
	var hit = null
	var hit_normal = null
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
		hit_normal = l_hit.normal
		hit = l_hit
#		phys_transform.origin = hit.position + phys_transform.basis.x * BOOP_DISTANCE
#		print("l_hit")
#		phys_transform = phys_transform.translated(+phys_transform.basis.x * (BOOP_DISTANCE - l_hit.position.distance_to(phys_transform.origin)))
	if r_hit:
		hit_normal = r_hit.normal
		hit = r_hit
#		phys_transform.origin = hit.position - phys_transform.basis.x * BOOP_DISTANCE
#		print("r_hit")
#		phys_transform = phys_transform.translated(-phys_transform.basis.x * (BOOP_DISTANCE - r_hit.position.distance_to(phys_transform.origin)))
	if f_hit:
		hit_normal = f_hit.normal
		hit = f_hit
#		phys_transform.origin = hit.position + phys_transform.basis.z * BOOP_DISTANCE
#		print("f_hit")
#		phys_transform = phys_transform.translated(+phys_transform.basis.z * (BOOP_DISTANCE - f_hit.position.distance_to(phys_transform.origin)))
	if b_hit:
		hit_normal = b_hit.normal
		hit = b_hit
#		phys_transform.origin = hit.position - phys_transform.basis.z * BOOP_DISTANCE
#		print("b_hit")
#		phys_transform = phys_transform.translated(-phys_transform.basis.z * (BOOP_DISTANCE - b_hit.position.distance_to(phys_transform.origin)))
	
	if hit_normal != null:
#		phys_transform.origin += hit_normal * BOOP_DISTANCE
		var direction = phys_transform.xform_inv(phys_transform.origin + hit_normal)
		var angle_between = atan2(pos_vel.z, pos_vel.x) - atan2(direction.z, direction.x)
		direction = direction.rotated(Vector3(0, 1, 0), PI + angle_between)
		phys_transform.origin += phys_transform.basis.x * direction.x * pos_vel.length() * 1 * delta
		phys_transform.origin += phys_transform.basis.z * direction.z * pos_vel.length() * 1 * delta
		direction = direction.normalized() * pos_vel.length()
		pos_vel.x = direction.x * 1.0
		pos_vel.z = direction.z * 1.0
		
		
#		phys_transform.origin = hit.position + hit.normal * BOOP_DISTANCE
		
		
#		print(angle_between)
#		pos_vel.x -= direction.x * 100
#		pos_vel.z -= direction.z * 100
#		print(direction)
#		phys_transform.origin += phys_transform.basis.x * direction.x
#		phys_transform.origin += phys_transform.basis.z * direction.z
	


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
	pos_vel.x = _derp(pos_vel.x, vel.x, delta * 10)
	pos_vel.z = _derp(pos_vel.z, vel.z, delta * 10)
#	pos_vel = vel
#	pos_vel = lerp(pos_vel, vel, .3)
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
	phys_transform = initial_phys_transform
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
	state.camera_transform = camera_transform
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
	return state


func _on_Car_ground_hit():
	vrt_vel = 0
	if Input.is_action_pressed("bhop"):
		_just_drift()


func _move_camera(delta: float) -> void:
	var prev_camera_transform = $Camera.transform
	camera_transform = phys_transform.translated(Vector3(0, .5, 1))#camera_transform.interpolate_with(phys_transform.translated(Vector3(0, .5, 1)), .2)
	$Camera.set_as_toplevel(true)
	$Camera.transform = camera_transform
	$Camera.look_at(phys_transform.origin, phys_transform.basis.y)
	$Camera.rotate_object_local(Vector3(1, 0, 0), .4)
#	camera_transform = prev_camera_transform.interpolate_with($Camera.transform, 15 * delta)
	camera_transform.basis = prev_camera_transform.basis.slerp($Camera.transform.basis, 5 * delta)
	camera_transform.origin = prev_camera_transform.origin.linear_interpolate($Camera.transform.origin, 10 * delta)


func _derp(from: float, to: float, step: float):
	if from < to:
		return clamp(from + step, from, to)
	if from > to:
		return clamp(from - step, to, from)
	return to
