extends Resource
class_name HandlingModel

func extract(params: Dictionary) -> Dictionary:
	return {
		"linear_velocity": params["linear_velocity"],
		"angular_velocity": params["angular_velocity"],
		"gear": params["gear"],
		"rpm": params["rpm"],
		"current_steering": params["current_steering"],
		"has_grip": params["has_grip"],
	}

func extend(f: Callable) -> Callable:
	return func(params: Dictionary) -> Dictionary:
		var value = f.call(params)
		var result = params
		if value.has("linear_velocity"):
			result["linear_velocity"] = value["linear_velocity"]
		if value.has("angular_velocity"):
			result["angular_velocity"] = value["angular_velocity"]
		if value.has("gear"):
			result["gear"] = value["gear"]
		if value.has("rpm"):
			result["rpm"] = value["rpm"]
		if value.has("current_steering"):
			result["current_steering"] = value["current_steering"]
		if value.has("has_grip"):
			result["has_grip"] = value["has_grip"]
		return result

func integrate(f: Callable) -> Callable:
	return func(params: Dictionary) -> Dictionary:
		var value = f.call(params)
		var linear_velocity = params["linear_velocity"]
		var angular_velocity = params["angular_velocity"]
		var timestep = params["timestep"]
		if value.has("linear_acceleration"):
			linear_velocity += value["linear_acceleration"] * timestep
		if value.has("angular_acceleration"):
			angular_velocity += value["angular_acceleration"] * timestep
		value["linear_velocity"] = linear_velocity
		value["angular_velocity"] = angular_velocity
		return value

func enable_if(predicate: Callable, f: Callable) -> Callable:
	return func(params: Dictionary) -> Dictionary:
		if predicate.call(params):
			return f.call(params)
		return extract(params)

func neg(predicate: Callable) -> Callable:
	return func(params: Dictionary) -> bool:
		return not predicate.call(params)

func compose(f: Callable, g: Callable) -> Callable:
	return func(params: Dictionary) -> Dictionary:
		var result = extend(g).call(params)
		return extract(extend(f).call(result))

func make_model_pipeline(func_array: Array) -> Callable:
	var last_idx = func_array.size() - 1
	var i = last_idx - 1
	var f = func_array[last_idx]
	while i >= 0:
		var g = func_array[i]
		f = compose(f, g)
		i -= 1
	return f

func process(params: Dictionary) -> Dictionary:
	return extract(params)

