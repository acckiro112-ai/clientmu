#version 430 core

layout(location = 0) in vec3 aPos;
layout(location = 1) in vec3 aNorm;
layout(location = 2) in vec2 aTex;
layout(location = 3) in uint aBone;

layout(location = 4) in vec4 i_bodyLight;
layout(location = 5) in vec4 i_lightPosition;
layout(location = 6) in vec4 i_meshUV;      // (uAdd, vAdd, useTerrainTex, _)
layout(location = 7) in int  i_enableLight;
layout(location = 8) in int  i_boneBaseIndex;
layout(location = 9) in vec4 i_setting1;    // (sx, sy, planeZ, gradX)
layout(location = 10) in vec4 i_setting2;   // (origin.xyz, gradY)

uniform mat4 uProj;
uniform mat4 uView;

uniform sampler2D uBones;
uniform int uBonesW;
vec4 boneRow(int i){ return texelFetch(uBones, ivec2(i % uBonesW, i / uBonesW), 0); }

// Heightmap BackTerrainHeight 256x256 R32F (row = y, cell = 100 world unit) — unit 2.
// Bilinear làm tay y hệt RequestTerrainHeight (CPU CalcShadowPosition per-vertex).
uniform sampler2D uTerrain;
float terrainH(vec2 wxy) {
    vec2 g = wxy / 100.0;
    ivec2 i0 = ivec2(g);
    vec2 d = g - vec2(i0);
    ivec2 m = ivec2(255, 255);
    float h00 = texelFetch(uTerrain,  i0               & m, 0).r;
    float h01 = texelFetch(uTerrain, (i0 + ivec2(0,1)) & m, 0).r;
    float h10 = texelFetch(uTerrain, (i0 + ivec2(1,0)) & m, 0).r;
    float h11 = texelFetch(uTerrain, (i0 + ivec2(1,1)) & m, 0).r;
    return mix(mix(h00, h01, d.y), mix(h10, h11, d.y), d.x);
}

out vec4 v_color0;
out vec2 v_texcoord0;
out vec4 v_setting1;
out vec4 v_setting2;

void main() {
    // aBone đã là offset hàng đầu (đơn vị: vec4 row)
    int base = i_boneBaseIndex + int(aBone);
    vec4 r0 = boneRow(base + 0);
    vec4 r1 = boneRow(base + 1);
    vec4 r2 = boneRow(base + 2);

    // world position (1-bone)
    vec3 wp = vec3(dot(r0.xyz, aPos) + r0.w,
                   dot(r1.xyz, aPos) + r1.w,
                   dot(r2.xyz, aPos) + r2.w);

    // tham số chiếu
    float sx     = i_setting1.x;
    float sy     = i_setting1.y;
    float planeZ = i_setting1.z;
    vec3  origin = i_setting2.xyz;

    // chiếu (Z là up) giống CalcShadowPosition
    vec3 p = wp;
    p -= origin;
    p.x += p.z * (p.x + sx) / (p.z - sy);
    p += origin;
    // i_meshUV.z=1 → binary có bind heightmap: drape TỪNG VERTEX theo đất (chuẩn CPU,
    // hết chìm mép bóng ở đất cong). Binary cũ gửi 0 → plane nghiêng theo gradient
    // (vẫn hơn plane ngang); gradient cũng 0 → plane ngang y như bản gốc.
    if (i_meshUV.z > 0.5)
        p.z = terrainH(p.xy) + 5.0;
    else
        p.z = planeZ + i_setting1.w * (p.x - origin.x) + i_setting2.w * (p.y - origin.y);

    gl_Position = uProj * uView * vec4(p, 1.0);

    // bóng đen mờ; alpha lấy từ i_bodyLight.w
    v_color0    = vec4(0.0, 0.0, 0.0, clamp(i_bodyLight.w, 0.0, 0.2));
    v_texcoord0 = aTex + i_meshUV.xy;

    // pass-through để FS giữ giao diện thống nhất
    v_setting1 = i_setting1;
    v_setting2 = i_setting2;
}
