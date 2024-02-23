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
