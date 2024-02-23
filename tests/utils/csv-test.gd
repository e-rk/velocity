extends GutTest
class_name CsvTest

func get_csv() -> FileAccess:
	return null

func body(data: Dictionary):
	pass

func get_csv_line_dict(file, header):
	var line = file.get_csv_line()
	var result = Dictionary()
	if len(line) == 1:
		return null
	for i in line.size():
		result[header[i]] = line[i]
	return result

func test_csv():
	var csv = self.get_csv()
	var header = csv.get_csv_line()
	while not csv.eof_reached():
		var line = self.get_csv_line_dict(csv, header)
		if line == null:
			break
		self.body(line)

func rpm(data: Dictionary) -> float:
	return float(data["rpm"])

func torque(data: Dictionary) -> float:
	return float(data["torque"])

func gear(data: Dictionary) -> int:
	return int(data["gear"])

func local_linear_velocity(data: Dictionary) -> Vector3:
	var vx = float(data.get("local_linear_velocity_x", "0.0"))
	var vy = float(data.get("local_linear_velocity_y", "0.0"))
	var vz = float(data.get("local_linear_velocity_z", "0.0"))
	return Vector3(vx, vy, vz)

func global_angular_velocity(data: Dictionary) -> Vector3:
	var wx = float(data.get("global_angular_velocity_x", "0.0"))
	var wy = float(data.get("global_angular_velocity_y", "0.0"))
	var wz = float(data.get("global_angular_velocity_z", "0.0"))
	return Vector3(wx, wy, wz)

func inertia_inv(data: Dictionary) -> Vector3:
	var ix = float(data.get("inertia_inv_x", "0.0"))
	var iy = float(data.get("inertia_inv_y", "0.0"))
	var iz = float(data.get("inertia_inv_z", "0.0"))
	return Vector3(ix, iy, iz)

func mass(data: Dictionary) -> float:
	return float(data["mass"])

func is_airborne(data: Dictionary) -> bool:
	var airborne_counter = int(data["airborne_counter"])
	return airborne_counter != 0

func handbrake(data: Dictionary) -> bool:
	return data["handbrake"] != "0"

func steering(data: Dictionary) -> int:
	return int(data["turn_angle"])
