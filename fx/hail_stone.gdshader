shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, shadows_disabled;

// Un grêlon du Nuage d'orage en grêle (`StormCloudFx`) : une bille de glace qui prend la lumière, un
// reflet net, une lueur froide qui la garde lisible à l'ombre du nuage.

uniform vec3 color = vec3(0.82, 0.9, 1.0);
uniform vec3 glow = vec3(0.25, 0.35, 0.45);
instance uniform float opacity = 1.0;

void fragment() {
	ALBEDO = color;
	ROUGHNESS = 0.25;
	EMISSION = glow;
	ALPHA = opacity;
}
