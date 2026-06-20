#version 430

in vec2 v_uv;
out vec4 o_color;

uniform bool      u_Textured;
uniform sampler2D u_tex;
uniform float     u_AlphaCut;
uniform float     u_Luminosity;  // Luminosity value (0.0-1.0)
uniform bool      u_IsBackFace;  // Whether this is back face rendering
uniform vec3      u_GlobalColor; // Global color modulation (from glColor3f)
uniform bool      u_Recolor;     // TRUE_ITEM_RECOLOR: gray(tex) * u_GlobalColor (mau nhuom)

void main()
{
    vec4 c = u_Textured ? texture(u_tex, v_uv) : vec4(1.0, 1.0, 1.0, 1.0);
    if (u_AlphaCut > 0.0 && c.a < u_AlphaCut) discard;
    
    // Apply global color modulation (giống CPU glColor3f)
    if (u_Recolor)
        c.rgb = vec3(max(max(c.r, c.g), c.b)) * u_GlobalColor;
    else
        c.rgb *= u_GlobalColor;
    
    // Apply additional luminosity modulation for back face (giống CPU RenderFace)
    if (u_IsBackFace && u_Luminosity != 1.0) {
        c.rgb *= u_Luminosity;
    }
    
    o_color = c;
}
