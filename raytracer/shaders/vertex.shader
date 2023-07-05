#version 330 core

layout(location = 0) in vec2 position;
layout(location = 1) in vec2 vertTextCoord;
out vec2 textCoord;

void main() {
	textCoord = vertTextCoord;
	gl_Position = vec4(position,0.0,0.0);
}

