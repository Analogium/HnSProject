shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// Le marteau du Marteau béni (`HolyHammerFx`) et les maillons des Chaînes (`JudgmentChainsFx`) : du fer béni,
// la tête claire et le manche plus sombre comme en 2D. Éclairé, pour que ses faces se lisent ; tout en
// lumière, il sortait en tache blanche. Il luit de l'or du sacré, plus fort au bord, et la bande de lumière
// de Qwen-Image (`fx/holy_wave.png`) court dessus.

#include "res://fx/lightning_common.gdshaderinc"

uniform sampler2D photo : filter_linear_mipmap, repeat_enable;
// Là où commence la tête, sur l'axe du manche (y du maillage) ; sous 0, tout est tête (un maillon).
uniform float head = 3.0;
instance uniform float opacity = 1.0;
instance uniform float clock = 0.0;
varying float along;
varying vec3 spot;

void vertex() {
	along = VERTEX.y;
	spot = VERTEX;
}

void fragment() {
	float rim = 1.0 - abs(dot(NORMAL, VIEW));
	vec3 p = texture(photo, vec2(spot.x * 0.08 + spot.y * 0.05 - clock * 1.5, spot.z * 0.1 + 0.5)).rgb;
	float l = max(p.r, max(p.g, p.b));
	bool top = along > head;
	ALBEDO = top ? heart * 0.8 : deep * 1.4;
	METALLIC = 0.85;
	ROUGHNESS = top ? 0.3 : 0.5;
	EMISSION = heart * (top ? 0.1 + 0.3 * l : 0.05) + tint * pow(rim, 2.0) * 0.7;
	ALPHA = opacity;
}
