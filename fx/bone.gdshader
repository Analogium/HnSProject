shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// L'os des Lanceurs d'os (`PlagueFx.bone()`) : de l'ivoire éclairé, couché, qui tournoie sur lui-même autour
// de la verticale — il dispense de l'orienter, comme en 2D.

uniform vec3 ivory = vec3(0.88, 0.85, 0.7);
uniform float spin = 14.0;
instance uniform float opacity = 1.0;

void vertex() {
	float a = TIME * spin;
	mat3 turn = mat3(vec3(cos(a), 0.0, -sin(a)), vec3(0.0, 1.0, 0.0), vec3(sin(a), 0.0, cos(a)));
	VERTEX = turn * VERTEX;
	NORMAL = turn * NORMAL;
}

void fragment() {
	ALBEDO = ivory;
	ROUGHNESS = 0.55;
	ALPHA = opacity;
}
