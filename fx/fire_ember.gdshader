shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// Une braise, par instance d'un `MultiMesh` : un point chaud tourné vers la caméra, étiré le long de sa
// course (l'axe Y du quad, que le script couche sur sa vitesse). Son âge, de 0 à 1, dans le rouge de
// `INSTANCE_CUSTOM` : elle passe du cœur de la rampe au rouge profond et s'éteint.

uniform vec3 heart = vec3(1.0, 0.72, 0.22);
uniform vec3 tint = vec3(1.0, 0.36, 0.04);
uniform vec3 deep = vec3(0.72, 0.1, 0.02);
instance uniform float opacity = 1.0;
varying float age;

void vertex() {
	age = INSTANCE_CUSTOM.r;
	// L'axe Y garde sa direction (la course) ; X se tourne vers la caméra autour de lui.
	vec3 along = MODEL_MATRIX[1].xyz;
	vec3 eye = normalize(INV_VIEW_MATRIX[2].xyz);
	vec3 side = normalize(cross(along, eye)) * length(MODEL_MATRIX[0].xyz);
	mat4 world = mat4(vec4(side, 0.0), vec4(along, 0.0), vec4(eye, 0.0), MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = VIEW_MATRIX * world;
}

void fragment() {
	if (age >= 1.0) {
		discard;
	}
	vec2 d = UV * 2.0 - 1.0;
	float dot_ = exp(-dot(d, d) * 5.0);
	vec3 c = age < 0.4 ? mix(heart, tint, age / 0.4) : mix(tint, deep, (age - 0.4) / 0.6);
	ALBEDO = c * dot_ * (1.0 - smoothstep(0.6, 1.0, age)) * 1.4 * opacity;
}
