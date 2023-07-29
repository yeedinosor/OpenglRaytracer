
#include <GL/glew.h>
#include <GLFW/glfw3.h>
#include <iostream>
#include <fstream>
#include <string>
#include <sstream>
#include <glm/vec3.hpp>
#include <cstdlib>

#define STB_IMAGE_IMPLEMENTATION
#include "stb/stb_image.h"

void processInput(GLFWwindow* window)
{
    if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS)
        glfwSetWindowShouldClose(window, true);
}

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

    float positions[] = {
        -1, -1, 0.0, 0.0, 
        1, -1, 1.0, 0.0,
        1, 1, 1.0, 1.0,
        -1, 1, 0.0, 1.0
    };
    
    unsigned int indicies[] = {
        0, 1, 2,
        2, 3, 0
    };

    stbi_set_flip_vertically_on_load(true);
    int texWidth, texHeight, nrChannels;
    unsigned int texture;
    glGenTextures(1, &texture);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture);
    // set the texture wrapping/filtering options (on the currently bound texture object)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    unsigned char* stbData = stbi_load("neuron.jpeg", &texWidth, &texHeight, &nrChannels, 0);
    if (stbData)
    {
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, texWidth, texHeight, 0, GL_RGB, GL_UNSIGNED_BYTE, stbData);
        glGenerateMipmap(GL_TEXTURE_2D);
    }
    else
    {
        std::cout << "Failed to load texture" << std::endl;
    }
    stbi_image_free(stbData);

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
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, sizeof(float) * 4, 0);

    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, sizeof(float) * 4, (void*)(2 * sizeof(float)));

    unsigned int ibo;
    glGenBuffers(1, &ibo);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, 6 * sizeof(unsigned int), indicies, GL_STATIC_DRAW);


    std::string vertexShader = ParseShader("shaders/vertex.shader");
    std::string fragmentShader = ParseShader("shaders/fragment.shader");

    unsigned int shader = CreateShader(vertexShader, fragmentShader);
    glUseProgram(shader);


    float r = 0.01f;
    float increment = 1.0f;

    float previousTime = glfwGetTime();
    int fps = 0;



    while (!glfwWindowShouldClose(window)) {

        processInput(window);

        fps++;
        float currentTime = glfwGetTime();
        if (currentTime-previousTime >= 1.0) {
            std::cout << fps << " fps, "<<1000/fps<<" ms"<< std::endl;
            fps = 0;
            previousTime = currentTime;
        }
        glClear(GL_COLOR_BUFFER_BIT);
        glUniform1f(glGetUniformLocation(shader, "sphereVertical"), r);
        glUniform3f(glGetUniformLocation(shader, "camPos"), r/6, 0.0, 0.0);
        if (r < -10.0f || r>20.0f) {
            increment *= -1;
        }
        
        //glDrawArrays(GL_TRIANGLES, 0, 3);
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, nullptr);
        r += increment;

        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    glDeleteProgram(shader);

    glfwTerminate();
    return 0;
}


