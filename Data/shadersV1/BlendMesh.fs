#version 430 core
in vec4 v_color0;
in vec2 v_texcoord0;
in vec4 v_setting2;
uniform sampler2D s0;
out vec4 FragColor;
void main(){
    vec4 t = texture(s0, v_texcoord0);
    vec4 c;
    // TRUE_ITEM_RECOLOR: nhu Model.fs — hue = mau nhuom, texture+v_color0 chi gop do sang
    if(v_setting2.w > 0.5){
        float tv = max(max(t.r, t.g), t.b);
        float lv = max(max(v_color0.r, v_color0.g), v_color0.b);
        c = vec4(tv * lv * v_setting2.rgb, t.a * v_color0.a);
    } else {
        c = t * v_color0;
    }
    if(c.a < 0.2) discard;
    FragColor = c;
}
