@tool
class_name EngineSoundManager
extends Node


@export var car : Car : set = set_car
@export var engine_audio_player: AudioStreamPlayer : set = set_engine_audio_player
@export var max_pitch : float = 2.25
@export var min_pitch : float = 0.60

@export_group("RPM", "rpm")
@export var max_rpm : float = 9000
@export var idle_rpm : float = 1000
@export var rpm_climb_rate : float = 6000
@export var rpm_sink_rate : float = 4000

@export_group("Gears", "gear")
@export var num_gears : int = 3 : set = set_num_gears
@export var gear_min_speeds : Array[float] = [
		0,
		0.23,
		0.55
] : set = set_min_speeds
@export var gear_max_speeds : Array[float] = [
		0.37,
		0.73,
		1.05
] : set = set_max_speeds


var rpm = idle_rpm
var _gear_speeds : Array[GearSpec] = [ GearSpec.new(idle_rpm, max_rpm) ]

# TODO: Add spooling down before idle if car slows down too fast


class GearSpec:
	var min_speed : float
	var max_speed : float
	
	func _init(min : float, max : float) -> void:
		min_speed = min
		max_speed = max



func _ready() -> void:
	_check_set_process_enabled()


func _process(delta: float) -> void:
	if not engine_audio_player.playing:
		engine_audio_player.play()
	
	#if Input.is_action_just_pressed("accelerate"):
		#rpm = lerpf(idle_rpm, max_rpm, absf(car.acceleratior_input))
	if car._crashing:
		var required_rpm : float = lerpf(idle_rpm, max_rpm, absf(car.acceleratior_input))
		
		if car._just_crashed:
			rpm = max(max(rpm / 2, lerpf(idle_rpm, max_rpm, car._speed / car.max_forward_speed)), idle_rpm)
		if required_rpm > rpm:
			rpm = min(rpm + rpm_climb_rate * delta, required_rpm)
		else:
			rpm = max(rpm - rpm_sink_rate * delta, required_rpm)
		
	else:
		var required_rpm : float
		var ignore_climb_rate : bool = true
		
		var gear : int = 0
		var spec : GearSpec
		var rpm_fraction : float
		
		if not car._moving_forwards:
			rpm_fraction = car._speed / car.max_reverse_speed
		else:
			#if car.acceleratior_input > 0.7:
			for i in range(num_gears):
				if _gear_speeds[i].max_speed > car._speed or i == (num_gears - 1):
					spec = _gear_speeds[i]
					gear = i + 1
					#print(1)
					break
			#else:
				#for i in range(num_gears - 1, -1, -1):
					#if _gear_speeds[i].min_speed <= car._speed:
						##print(2)
						#gear = i + 1
						#spec = _gear_speeds[i]
						#break
			rpm_fraction = min(1, inverse_lerp(spec.min_speed, spec.max_speed, car._speed))
		
		
		#if Engine.get_frames_drawn() % 15 == 0: print(str(gear) + " @ " + str(car._speed) + " => " + str(rpm_fraction))
		
		if car._traction < car.max_traction and not is_zero_approx(car.acceleratior_input):
			rpm_fraction = lerpf(rpm_fraction, abs(car.acceleratior_input), inverse_lerp(car.min_traction, car.max_traction, 1 - car._traction))
			ignore_climb_rate = false
		
		required_rpm = lerpf(idle_rpm, max_rpm, rpm_fraction)
		
		if required_rpm > rpm:
			rpm = required_rpm if ignore_climb_rate else min(rpm + rpm_climb_rate * delta, max_rpm)
		else:
			rpm = max(max(rpm - rpm_climb_rate * delta, required_rpm), required_rpm)
	
	
	engine_audio_player.pitch_scale = lerpf(min_pitch, max_pitch, inverse_lerp(idle_rpm, max_rpm, rpm))


func set_car(node : Car) -> void:
	car = node
	if is_node_ready(): _update_gear_speeds()
	_check_set_process_enabled()


func set_engine_audio_player(stream : AudioStreamPlayer) -> void:
	engine_audio_player = stream
	_check_set_process_enabled()


func _check_set_process_enabled() -> void:
	if engine_audio_player and car and not Engine.is_editor_hint():
		set_process(true)
	else:
		set_process(false)
	


func set_num_gears(count : int) -> void:
	if count == num_gears: return
	num_gears = count
	update_configuration_warnings()


func set_min_speeds(speeds : Array[float]) -> void:
	gear_min_speeds = speeds
	update_configuration_warnings()


func set_max_speeds(speeds : Array[float]) -> void:
	gear_max_speeds = speeds
	update_configuration_warnings()


func _update_gear_speeds() -> void:
	#var ratio_sum : int = 0
	#for ratio in relative_gear_ratios:
		#ratio_sum += ratio
	#
	#var max_speed = car.max_forward_speed
	#
	#var gear_cutoffs : Array[float] = []
	#gear_cutoffs.resize(num_gears)
	#var prev_cutoff : float = 0
	#var cummulative_ratio : int = 0
	#for index in range(num_gears):
		#cummulative_ratio += relative_gear_ratios[index]
		#var cutoff : float = max_speed * (float(cummulative_ratio) / ratio_sum)
		#gear_cutoffs[index] = cutoff
		#prev_cutoff = cutoff
	#
	#_gear_speeds.clear()
	#
	#var prev_min : float = 0
	#var prev_max : float = 0
	#for gear in range(num_gears):
		#var max = gear_cutoffs[gear]
		#var min = prev_max - (prev_max - prev_min) * gear_overlap
		#_gear_speeds.append(GearSpec.new(min, max))
		#prev_max = max
		#prev_min = min
	
	if gear_max_speeds.size() != num_gears or gear_min_speeds.size() != num_gears or not car:
		return
	
	var max_speed = car.max_forward_speed
	
	_gear_speeds.clear()
	_gear_speeds.resize(num_gears)
	for idx in range(num_gears):
		_gear_speeds[idx] = GearSpec.new(gear_min_speeds[idx] * max_speed, gear_max_speeds[idx] * max_speed)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings : PackedStringArray = []
	
	if not car:
		warnings.append("A car must be specified.")
	
	if gear_max_speeds.size() != num_gears:
		warnings.append("Max rpm array must have exactly one entry for every gear.")
	
	if gear_min_speeds.size() != num_gears:
		warnings.append("Min rpm array must have exactly one entry for every gear.")
	
	return warnings
