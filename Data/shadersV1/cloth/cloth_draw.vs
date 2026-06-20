#version 430

// ===== Input =====
// Pos SSBO bind thang lam attribute 0 (xyz = vi tri, w = invMass — bo qua).
// Index stream cu gio la GL_ELEMENT_ARRAY_BUFFER -> glDrawElements tu fetch pos[index],
// het copy SSBO->texture moi frame (glTexSubImage2D tu PIXEL_UNPACK stall ~5ms/frame
// tren driver mobile — do bisect 2026-07-13).
layout(location=0) in vec4 a_pos;

// ===== Uniforms =====
uniform mat4 u_MVP;   // Model-View-Projection
uniform int  u_GridW; // số đỉnh theo trục X của tấm vải
uniform int  u_GridH; // số đỉnh theo trục Y của tấm vải

// ===== Varyings =====
out vec2 v_uv;

void main()
{
    // glDrawElements: gl_VertexID = gia tri index vua fetch = vertexID cu
    uint vid = uint(gl_VertexID);

    // Tính UV theo grid position thực tế của vertex
    uint x = (u_GridW > 0) ? (vid % uint(u_GridW)) : 0u;
    uint y = (u_GridH > 0 && u_GridW > 0) ? (vid / uint(u_GridW)) : 0u;

    float u = (u_GridW > 1) ? float(x) / float(u_GridW - 1) : 0.0;
    float v = (u_GridH > 1) ? min(0.99f, float(y) / float(u_GridH - 1)) : 0.0;

    v_uv = vec2(u, v);

    gl_Position = u_MVP * vec4(a_pos.xyz, 1.0);
}
