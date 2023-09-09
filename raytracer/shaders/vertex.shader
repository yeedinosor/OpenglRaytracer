#version 460

layout(location = 0) in vec4 position;
layout(location = 1) in vec2 vertTextCoord;
out vec2 textCoord;

void main() {
	textCoord = vertTextCoord;
	gl_Position = position;
}

