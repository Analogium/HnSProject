shader_type spatial;

// Le décor d'une zone (`Scenery`) : la texture de son scan, tirée vers la couleur du biome
// (`tint`, de `amount`), et estompée quand il passe devant le joueur (`fade.gdshaderinc`).
#include "res://world/fade.gdshaderinc"

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform vec3 tint : source_color = vec3(1.0);
uniform float amount = 0.0;

varying float height;

void vertex() {
	height = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}

void fragment() {
	vec4 color = texture(albedo_tex, UV);
	float light = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	ALBEDO = mix(color.rgb, tint * light * 2.0, amount);
	ALPHA = color.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	NORMAL_MAP = texture(normal_tex, UV).rgb;
	ROUGHNESS = 0.9;
	if (faded(SCREEN_UV, VIEWPORT_SIZE, -VERTEX.z, FRAGCOORD.xy, height)) {
		discard;
	}
}
