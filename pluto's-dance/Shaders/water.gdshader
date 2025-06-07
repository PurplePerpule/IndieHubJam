shader_type spatial;

uniform vec3 albedo : source_color;
uniform vec3 albedo2 : source_color;
uniform float metallic : hint_range(0.0, 1.0) = 0;
uniform float roughness : hint_range(0.0, 1.0) = 0.02;
uniform sampler2D texture_normal;
uniform sampler2D texture_normal2;
uniform vec2 wave_direction = vec2(2.0, 0.0);
uniform vec2 wave_direction2 = vec2(0.0, 1.0);
uniform float time_scale : hint_range(0.000, 0.2, 0.005) = 0.025;
uniform sampler2D wave;
uniform float noise_scale = 10.0;
uniform float height_scale = 0.15;

varying float height;
varying vec3 world_pos;

uniform vec4 color_deep : source_color;
uniform vec4 color_shallow : source_color;
uniform float beers_law = 2.0;
uniform float depth_offset = -0.75;

uniform float edge_scale = 0.005; // Уменьшено для более тонкой обводки
uniform vec3 edge_color : source_color = vec3(0.0, 1.0, 1.0); // Голубой для контраста

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

float fresnel(float amount, vec3 normal, vec3 view) {
    return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    height = texture(wave, world_pos.xz / noise_scale + TIME * time_scale).r;
    VERTEX.y += height * height_scale;
}

void fragment() {
    // Получение глубины сцены и текущего фрагмента
    float depth_texture = texture(DEPTH_TEXTURE, SCREEN_UV).r;
    float frag_depth = FRAGCOORD.z;

    // Преобразование глубины в линейное пространство для большей точности
    float z_near = 0.05; // Установите значение near из настроек камеры
    float z_far = 1000.0; // Установите значение far из настроек камеры
    float linear_depth_texture = z_near * z_far / (z_far + depth_texture * (z_near - z_far));
    float linear_frag_depth = z_near * z_far / (z_far + frag_depth * (z_near - z_far));

    // Расчет разницы глубины для обводки
    float depth_diff = abs(linear_depth_texture - linear_frag_depth);
    float edge_factor = smoothstep(0.0, edge_scale, depth_diff);

    // Расчет цвета воды
    float depth_blend = exp((linear_frag_depth + VERTEX.z + depth_offset) * -beers_law);
    depth_blend = clamp(1.0 - depth_blend, 0.0, 1.0);
    float depth_blend_power = clamp(pow(depth_blend, 2.5), 0.0, 1.0);

    vec3 screen_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, depth_blend_power * 2.5).rgb;
    vec3 depth_color = mix(color_shallow.rgb, color_deep.rgb, depth_blend_power);
    vec3 color = mix(screen_color * depth_color, depth_color * 0.25, depth_blend_power * 0.5);

    // Нормали и френель
    vec2 time = (TIME * wave_direction) * time_scale;
    vec2 time2 = (TIME * wave_direction2) * time_scale;
    vec3 normal_blend = mix(texture(texture_normal, UV + time).rgb, texture(texture_normal2, UV + time2).rgb, 0.5);
    float fresnel = fresnel(5.0, NORMAL, VIEW);
    vec3 surface_color = mix(albedo, albedo2, fresnel);

    // Обводка
    vec3 final_color = mix(edge_color, color, edge_factor);

    // Финальный цвет
    ALBEDO = clamp(surface_color + final_color, vec3(0.0), vec3(1.0));
    METALLIC = metallic;
    ROUGHNESS = roughness;
    NORMAL_MAP = normal_blend;

    // Для отладки: визуализация edge_factor или depth_diff
    //ALBEDO = vec3(edge_factor); // Раскомментируйте для проверки edge_factor
    //ALBEDO = vec3(clamp(depth_diff * 10.0, 0.0, 1.0)); // Раскомментируйте для проверки depth_diff
}