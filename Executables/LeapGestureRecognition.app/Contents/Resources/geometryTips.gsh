#version 410 core

layout(points) in;
layout(triangle_strip) out;
layout (max_vertices = 18) out;

const float PI = 3.14159265358979323846264;
const int steps = 8; // max_vertices/2 - 1
const float radius = .015;

void main()
{
    vec4 pos = gl_in[0].gl_Position;

   //Creat a triangle strip of a circle
   vec2 leftmost = pos.xy + vec2(-1.0, 0.0) * radius;
    gl_Position = vec4(leftmost,pos.zw);
    EmitVertex();

    for(float phi = -PI/2; phi < PI/2; phi += PI/steps)
    {
        float x = radius * sin(phi);
        float y = radius * cos(phi);
        vec2 vertup = pos.xy + vec2(x, y);
        gl_Position = vec4(vertup.xy, pos.zw);
        EmitVertex();
        vec2 vertdown = pos.xy + vec2(x, -y);
        gl_Position = vec4(vertdown.xy, pos.zw);
        EmitVertex();
    }

   vec2 rightmost = pos.xy + vec2(1.0, 0.0) * radius;
    gl_Position = vec4(rightmost,pos.zw);
    EmitVertex();

  EndPrimitive();
}