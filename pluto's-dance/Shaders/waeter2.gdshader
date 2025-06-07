shader_type spatial;
render_mode blend_mix, cull_disabled;

uniform sampler2D water_texture;
uniform float scroll_speed = 0.1;

void fragment() {
    vec2 uv = UV + vec2(TIME * scroll_speed, 0.0); // Смещение UV по времени
    vec4 color = texture(water_texture, uv);
    ALBEDO = color.rgb;
    ALPHA = color.a; // Поддержка прозрачности
}
void vertex() {
	VERTEX += vec3(sin(TIME + VERTEX.x) * 0.01, 0.0, cos(TIME + VERTEX.z) * 0.01);
	VERTEX.y += sin(TIME + VERTEX.x * 2.0) * 0.1;
}