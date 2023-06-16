
#include <GL/glew.h>
#include <GLFW/glfw3.h>
#include <iostream>
#include <fstream>
#include <string>
#include <sstream>
#include <glm/vec3.hpp>
#include <cstdlib>
#include "stb/stb_image.h"

static std::string ParseShader(const std::string& filepath) {
    std::ifstream stream(filepath);
    std::string line;
    std::stringstream ss;
    while (getline(stream, line)) {
        ss << line << "\n";
    }
    return ss.str();
}

static unsigned int CompileShader(unsigned int type, const std::string& source) {
    unsigned int id = glCreateShader(type);
    const char* src = source.c_str();
    glShaderSource(id, 1, &src, nullptr);
    glCompileShader(id);

    int result;
    glGetShaderiv(id, GL_COMPILE_STATUS, &result);
    if (result == GL_FALSE) {
        int length;
        glGetShaderiv(id, GL_INFO_LOG_LENGTH, &length);
        char* message = (char*)alloca(length * sizeof(char));
        glGetShaderInfoLog(id, length, &length, message);
        std::cout << "Failed to compile " << (type == GL_VERTEX_SHADER ? "vertex" : "fragment") << "shader!" << std::endl;
        std::cout << message << std::endl;
        glDeleteShader(id);
        return 0;
    }

    return id;

}

static unsigned int CreateShader(const std::string& vertexShader, const std::string& fragmentShader) {
    unsigned int program = glCreateProgram();
    unsigned int vs = CompileShader(GL_VERTEX_SHADER, vertexShader);
    unsigned int fs = CompileShader(GL_FRAGMENT_SHADER, fragmentShader);

    glAttachShader(program, vs);
    glAttachShader(program, fs);
    glLinkProgram(program);
    glValidateProgram(program);

    glDeleteShader(vs);
    glDeleteShader(fs);

    return program;
}

static void CreateUniform3Floats(unsigned int shader, const std::string& name, unsigned int count, float* value) {
    int location = glGetUniformLocation(shader, name.c_str());
    //glUniform3f(location, 0.2f, 0.3f, 0.8f);
    glUniform3fv(location, count, value);
}
static void CreateUniform1Float(unsigned int shader, const std::string& name, float value) {
    int location = glGetUniformLocation(shader, name.c_str());
    //glUniform3f(location, 0.2f, 0.3f, 0.8f);
    glUniform1f(location, value);
}

int main(void) {
    GLFWmonitor* monitor = glfwGetPrimaryMonitor();

    GLFWwindow* window;
    const int height = 1080;
    const int width = 1080;

    if (!glfwInit())
        return -1;

    //fullscreen
    //window = glfwCreateWindow(width, height, "Hello World", glfwGetPrimaryMonitor(), NULL);

    window = glfwCreateWindow(width, height, "Hello World", monitor, NULL);
    if (!window) {
        glfwTerminate();
        return -1;
    }

    glfwMakeContextCurrent(window);
    glfwSwapInterval(1);

    if (glewInit() != GLEW_OK) {
        std::cout << "Error";
    }

    float positions[8] = {
        1, 1,
        1, -1,
        -1, -1,
        -1, 1,
    };

    //unsigned int fbo;
    //glGenFramebuffers(1, &fbo);
    //glBindFramebuffer(GL_FRAMEBUFFER, fbo);

    //unsigned int screenTexture;
    //glGenTextures(1, &screenTexture);
    //glBindTexture(GL_TEXTURE_2D, screenTexture);
    //// Set texture parameters and allocate storage if needed
    //glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, nullptr);
    //glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, screenTexture, 0);

    //if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
    //    std::cout << "FRAMEBUFFER ERROR" << std::endl;
    //}

    //glBindFramebuffer(GL_FRAMEBUFFER, fbo);

    unsigned int buffer;
    glGenBuffers(1, &buffer);
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(positions), positions, GL_STATIC_DRAW);

    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, sizeof(float) * 2, 0);

    std::string vertexShader = ParseShader("shaders/vertex.shader");
    std::string fragmentShader = ParseShader("shaders/fragment.shader");

    unsigned int shader = CreateShader(vertexShader, fragmentShader);
    glUseProgram(shader);

    float colorData[] = { 1,0,0,0,0,1 };

    //CreateUniform3Floats(shader, "uColor", 2, colorData);
    CreateUniform1Float(shader, "sphereVertical", 0.0);

    glUniform3f(glGetUniformLocation(shader, "camPos"),0.0,0.0,0.0);

    float r = 0.01f;
    float increment = 1.0f;

    float previousTime = glfwGetTime();
    int fps = 0;

    while (!glfwWindowShouldClose(window)) {
        fps++;
        float currentTime = glfwGetTime();
        if (currentTime-previousTime >= 1.0) {
            std::cout << fps << " fps, "<<1000/fps<<" ms"<< std::endl;
            fps = 0;
            previousTime = currentTime;
        }
        glClear(GL_COLOR_BUFFER_BIT);
        CreateUniform1Float(shader, "sphereVertical", r);
        glUniform3f(glGetUniformLocation(shader, "camPos"), r/4, 0.0, 0.0);
        if (r < -10.0f || r>20.0f) {
            increment *= -1;
        }
        
        glDrawArrays(GL_QUADS, 0, 4);
        r += increment;

        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    glDeleteProgram(shader);

    glfwTerminate();
    return 0;
}