shader_type canvas_item;

// Le bord de l'écran assombri vers une terre brûlée, comme la planche du biome.
// Sur un calque au-dessus du monde : le glow ne le voit pas, l'interface le couvre.

uniform vec4 tint : source_color = vec4(0.1, 0.047, 0.02, 1.0);
uniform float strength = 0.8;

void fragment() {
	float r = length((UV - 0.5) * 2.0);
	COLOR = vec4(tint.rgb, pow(clamp((r - 0.55) / 0.75, 0.0, 1.0), 1.5) * strength);
}
