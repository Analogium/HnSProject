shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

// L'ombre du Météore au point d'impact (« boule et ombre » choisie sur planche) : un disque
// sombre qui grandit pendant la chute. Le plan fait 2 de côté, mis à l'échelle de l'ombre.

instance uniform float opacity = 1.0;
instance uniform float progress = 0.0;
varying vec2 local;

void vertex() {
	local = VERTEX.xz;
}

void fragment() {
	float d = length(local) / max(progress, 0.05);
	if (d > 1.0) {
		discard;
	}
	ALBEDO = vec3(0.03, 0.02, 0.02);
	ALPHA = (1.0 - d * d) * 0.55 * progress * opacity;
}
