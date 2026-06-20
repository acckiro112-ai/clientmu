#version 430 core

layout(location = 0) in vec3 aPos;
layout(location = 1) in vec3 aNorm;
layout(location = 2) in vec2 aTex;
layout(location = 3) in uint aBone;

layout(location = 4) in vec4 i_bodyLight;
layout(location = 5) in vec4 i_lightPosition;
layout(location = 6) in vec4 i_meshUV;      // (uAdd, vAdd, _, _)
layout(location = 7) in int  i_enableLight;
layout(location = 8) in int  i_boneBaseIndex;
layout(location = 9) in vec4 i_setting1;    // pass-through (nếu FS cần)
layout(location = 10) in vec4 i_setting2;   // pass-through (nếu FS cần)

uniform mat4 uProj;
uniform mat4 uView;

uniform sampler2D uBones;
uniform int uBonesW;
vec4 boneRow(int i){ return texelFetch(uBones, ivec2(i % uBonesW, i / uBonesW), 0); }

out vec4 v_color0;
out vec2 v_texcoord0;
out vec4 v_setting1;
out vec4 v_setting2;

void main() 
{
    int base = i_boneBaseIndex + int(aBone);
    vec4 r0 = boneRow(base + 0);
    vec4 r1 = boneRow(base + 1);
    vec4 r2 = boneRow(base + 2);

    // normal (guard chia 0 — normal rỗng thì không extrude, tránh NaN vị trí)
    vec3 nw = vec3(dot(r0.xyz, aNorm),
                   dot(r1.xyz, aNorm),
                   dot(r2.xyz, aNorm));
    vec3 n = nw / max(length(nw), 1e-5);

    // position — i_setting1.x = khoảng extrude viền select (0 với draw thường)
    vec3 p = vec3(dot(r0.xyz, aPos) + r0.w,
                  dot(r1.xyz, aPos) + r1.w,
                  dot(r2.xyz, aPos) + r2.w) + n * i_setting1.x;
    gl_Position = uProj * uView * vec4(p, 1.0);

    // lighting — khớp công thức 330
    float lit = ((dot(n, i_lightPosition.xyz) * 0.8) + 0.4) * i_lightPosition.w + (1.0 - i_lightPosition.w);
    lit = max(lit, 0.2);
    v_color0 = (i_enableLight != 0)
        ? clamp(i_bodyLight * vec4(lit, lit, lit, i_lightPosition.w), 0.0, 1.0)
        : i_bodyLight;

    // UV gốc + offset
    v_texcoord0 = aTex + i_meshUV.xy;

    v_setting1 = i_setting1;
    v_setting2 = i_setting2;
}
