shader_type canvas_item;

// 0.0 = colorido   1.0 = cinza total
uniform float gray_amount : hint_range(0.0, 1.0) = 1.0;
// 1.0 = normal   0.6 = escurecido
uniform float brightness : hint_range(0.5, 1.5) = 0.6;

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    vec3 result = mix(color.rgb, vec3(gray), gray_amount);
    result *= brightness;
    COLOR = vec4(result, color.a);
}