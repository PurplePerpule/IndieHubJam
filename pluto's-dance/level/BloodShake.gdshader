shader_type spatial;
render_mode unshaded;

uniform sampler2D texture_albedo; // Текстура альбедо
uniform float time; // Время, передаваемое из GDScript
uniform float breathe_speed = 0.002; // Минимальная скорость дыхания (очень медленно)
uniform float breathe_amount = 0.05; // Лёгкая амплитуда дыхания

void fragment() {
    // Базовые UV
    vec2 base_uv = UV;

    // Дыхание: пульсация масштаба UV (синусоидальное расширение/сжатие)
    float breathe_scale = 1.0 + sin(time * breathe_speed) * breathe_amount;
    vec2 breathe_uv = base_uv * breathe_scale;

    // Применяем текстуру с новым UV
    ALBEDO = texture(texture_albedo, breathe_uv).rgb;
    ALPHA = texture(texture_albedo, breathe_uv).a;
}