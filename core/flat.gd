class_name Flat

## Le plan du jeu en 3D (jalon 54) : le `(x, y)` d'avant est `(x, 0, y)`, et un angle garde
## son sens — le bas de l'écran est +Z. Ce que `Vector3` n'a pas, et rien d'autre.

## Le monde se mesure en pixels de l'ancien repère ; les modèles (`art/models/`), en mètres.
## Le même chiffre que `tools/blender/export_glb.py`.
const PX_PER_M := 16.0


static func from_angle(angle: float) -> Vector3:
	return Vector3(cos(angle), 0.0, sin(angle))


static func angle(v: Vector3) -> float:
	return atan2(v.z, v.x)


static func rotated(v: Vector3, angle: float) -> Vector3:
	var c := cos(angle)
	var s := sin(angle)
	return Vector3(v.x * c - v.z * s, v.y, v.x * s + v.z * c)


## Comme `Vector2.orthogonal()` : un quart de tour dans le sens inverse des angles.
static func orthogonal(v: Vector3) -> Vector3:
	return Vector3(v.z, 0.0, -v.x)


## Comme `Vector2.cross()` : un nombre, positif quand `b` tourne dans le sens des angles.
static func cross(a: Vector3, b: Vector3) -> float:
	return a.x * b.z - a.z * b.x


## L'angle signé de `from` à `to`, comme `Vector2.angle_to()`.
static func angle_to(from: Vector3, to: Vector3) -> float:
	return atan2(from.x * to.z - from.z * to.x, from.x * to.x + from.z * to.z)


## Le point dans le plan, pour ce qui raisonne en 2D : grilles, polygones (`Geometry2D`).
static func xz(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


## Le point du sol sous la souris : le rayon de la caméra contre le plan y = 0. La seule
## visée du jeu.
static func under_mouse(viewport: Viewport) -> Vector3:
	var camera := viewport.get_camera_3d()
	if camera == null:
		return Vector3.ZERO
	var at := viewport.get_mouse_position()
	var hit: Variant = Plane(Vector3.UP).intersects_ray(camera.project_ray_origin(at), camera.project_ray_normal(at))
	return hit if hit != null else Vector3.ZERO


## Où se voit ce point du monde, en coordonnées du canevas : l'inverse de `under_mouse()`.
## `lift` le monte d'autant de pixels de sprite le long du haut de la caméra — les sprites
## se tiennent face à elle. Sans caméra (les tests), le plan à plat, comme en 2D.
static func on_screen(viewport: Viewport, point: Vector3, lift := 0.0) -> Vector2:
	var camera := viewport.get_camera_3d() if viewport != null else null
	if camera == null:
		return Vector2(point.x, point.z - lift)
	return camera.unproject_position(point + camera.global_basis.y * lift)
