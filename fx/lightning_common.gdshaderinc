// La rampe de la foudre et du givre (jalon 54) : celle de `FlameFx.RAMPS`, passée par le nœud, et un cœur
// blanc au-dessus. C'est le cœur fin qui dit l'éclair : sans lui, une fumée violette.

uniform vec3 heart = vec3(0.6, 0.48, 1.0);
uniform vec3 tint = vec3(0.34, 0.18, 0.92);
uniform vec3 deep = vec3(0.13, 0.05, 0.5);
uniform vec3 core = vec3(0.95, 0.93, 1.0);

vec3 ramp_of(float l) {
	if (l < 0.3) {
		return deep * (l / 0.3);
	}
	if (l < 0.6) {
		return mix(deep, tint, (l - 0.3) / 0.3);
	}
	if (l < 0.85) {
		return mix(tint, heart, (l - 0.6) / 0.25);
	}
	return mix(heart, core, (l - 0.85) / 0.15);
}
