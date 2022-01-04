//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#elif __APPLE__
#	include "TargetConditionals.h"
#	include <mach/mach_time.h>
#	if TARGET_IPHONE_SIMULATOR
// 		iOS Simulator
#		include <OpenGLES/ES1/gl.h>
#		include <OpenGLES/ES2/gl.h>
#		include <OpenGLES/ES3/gl.h>
#	elif TARGET_OS_IPHONE
// 		iOS device
#		include <OpenGLES/ES1/gl.h>
#		include <OpenGLES/ES2/gl.h>
#		include <OpenGLES/ES3/gl.h>
#	elif TARGET_OS_MAC
// 		Other kinds of Mac OS
#		include <OpenGLES/ES1/gl.h>
#		include <OpenGLES/ES2/gl.h>
#		include <OpenGLES/ES3/gl.h>
#	else
#   	error "Unknown Apple platform"
#	endif

#elif __linux__ // linux ...
#	include <malloc.h>
#	include <stdarg.h>
#	include "GL/glew.h"

#elif __unix__ // all unices not caught above
// Unix ...

#elif defined(_POSIX_VERSION)
// POSIX ...

#else
#   error "Unknown compiler"
#endif

#include "renderer.h"
#include <cassert>
#include <stdio.h>
#include <string.h>
#include <algorithm>
#include <cmath>

namespace vnn {
namespace renderkit {

static const GLfloat squareVertices[] = {
    -1.0f, -1.0f,
    1.0f, -1.0f,
    -1.0f,  1.0f,
    1.0f,  1.0f,
};

static const GLfloat textureVertices[] = {
    0.0f,  0.0f,
    1.0f,  0.0f,
    0.0f, 1.0f,
    1.0f, 1.0f,
};

const GLfloat textureVertices_90L[] = {
    1.0f,  0.0f,
    1.0f, 1.0f,
    0.0f,  0.0f,
    0.0f, 1.0f,
};

const GLfloat textureVertices_90R[] = {
    0.0f, 1.0f,
    0.0f,  0.0f,
    1.0f, 1.0f,
    1.0f,  0.0f,
};

const GLfloat textureVertices_180[] = {
    1.0f, 1.0f,
    0.0f, 1.0f,
    1.0f,  0.0f,
    0.0f,  0.0f,
};

const GLfloat textureVertices_HFlip[] = {
    1.0f,  0.0f,
    0.0f,  0.0f,
    1.0f, 1.0f,
    0.0f, 1.0f,
};

const GLfloat textureVertices_VFlip[] = {
    0.0f, 1.0f,
    1.0f, 1.0f,
    0.0f,  0.0f,
    1.0f,  0.0f,
};

static int ArgcForSettingGLContextCurrent = 0;
static void **ArgvForSettingGLContextCurrent = NULL;
static GLCONTEXT_SET_CURRENT_CALLBACK GLContext_SetCurrent_Callback = [](const int i_argc, const void *i_argv[]) -> int { return 0; };

int Set_GLContext_SetCurrent_Callback(GLCONTEXT_SET_CURRENT_CALLBACK i_callback) {
    GLContext_SetCurrent_Callback = i_callback;
    return 0;
}

int Set_GLContext_SetCurrent_Argc_Argv(const int i_argc, const void *i_argv[]) {
    ArgcForSettingGLContextCurrent = i_argc;
    ArgvForSettingGLContextCurrent = const_cast<void **>(i_argv);
    return 0;
}

VnGlTexture::~VnGlTexture() {
    if(GLContext_SetCurrent_Callback) {
        int ret = GLContext_SetCurrent_Callback(ArgcForSettingGLContextCurrent, (const void **)ArgvForSettingGLContextCurrent);
        assert(ret == 0);
    }
    glDeleteTextures(1, &_handle);
}

VnGlTexture::VnGlTexture(
                         unsigned int i_handle,
                         unsigned int i_target,
                         unsigned int i_format,
                         int i_width,
                         int i_height,
                         unsigned int i_dtype,
                         const void *i_data)
:
_handle(i_handle),
_target(i_target),
_format(i_format),
_width(i_width),
_height(i_height),
_dtype(i_dtype),
_is_shadow(true) {
    if (i_data) {
        glBindTexture(GL_TEXTURE_2D, _handle);
        glTexImage2D(i_target, 0, GLint(i_format), i_width, i_height, 0, i_format, i_dtype, i_data);
    }
}

VnGlTexture::VnGlTexture(
                         unsigned int i_target,
                         unsigned int i_format,
                         int i_width,
                         int i_height,
                         unsigned int i_dtype,
                         const void *i_data
                         ) : _is_shadow(false), _target(i_target), _format(i_format), _width(i_width), _height(i_height), _dtype(i_dtype) {
                             if(GLContext_SetCurrent_Callback) {
                                 int ret = GLContext_SetCurrent_Callback(ArgcForSettingGLContextCurrent, (const void **)ArgvForSettingGLContextCurrent);
                                 assert(ret == 0);
                             }
                             //
                             glGenTextures(1, &_handle);
                             glBindTexture(i_target, _handle);
                             glTexParameteri(i_target, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
                             glTexParameteri(i_target, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
                             glTexParameteri(i_target, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                             glTexParameteri(i_target, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
                             glPixelStorei(GL_PACK_ALIGNMENT, 4);
                             glTexImage2D(i_target, 0, GLint(i_format), i_width, i_height, 0, i_format, i_dtype, i_data);
                         }

int VnGlTexture::setData(const void *i_data) {
    if(!i_data) {
        return -1;
    }
    glBindTexture(_target, _handle);
    glTexImage2D(_target, 0, GLint(_format), _width, _height, 0, _format, _dtype, i_data);
    return 0;
}

int VnGlTexture::bindFBO(unsigned int i_fbo) {
    glBindFramebuffer(GL_FRAMEBUFFER, i_fbo);
    glBindTexture(_target, _handle);
    if (_format == GL_DEPTH_COMPONENT) {
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, _target, _handle, 0);
    } else {
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, _target, _handle, 0);
    }
    return 0;
}

VnGlRenderProgram::~VnGlRenderProgram() {
    if(GLContext_SetCurrent_Callback) {
        int ret = GLContext_SetCurrent_Callback(ArgcForSettingGLContextCurrent, (const void **)ArgvForSettingGLContextCurrent);
        assert(ret == 0);
    }
    glDeleteProgram(_handle);
}

VnGlRenderProgram::VnGlRenderProgram(std::string i_vs_content, std::string i_fs_content, std::vector<std::string> i_attrib_names, std::vector<std::string> i_uniform_names) {
    int ret = this->Load(i_vs_content, i_fs_content, i_attrib_names, i_uniform_names);
    assert(ret == 0);
}

inline bool compile(GLuint * i_shader, GLenum i_type, const char * i_content_utf8) {
    //get utf8 type string(char *)
    *i_shader = glCreateShader(i_type);
    glShaderSource(*i_shader, 1, &i_content_utf8, NULL);
    glCompileShader(*i_shader);
    GLint status;
    GLint logLength;
    glGetShaderiv(*i_shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*i_shader, logLength, &logLength, log);
        printf("Shader compile log: \n%s", log);
        free(log);
    }
    glGetShaderiv(*i_shader, GL_COMPILE_STATUS, &status);
    if (0 == status) {
        glDeleteShader(*i_shader);
        return false;
    }
    return true;
}

inline bool linkProgram(GLuint i_program) {
    glLinkProgram(i_program);
    
    GLint logLength;
    glGetProgramiv(i_program, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(i_program, logLength, &logLength, log);
        printf("Program link log:\n%s", log);
        free(log);
    }
    
    GLint linkSuccess;
    glGetProgramiv(i_program, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(i_program, sizeof(messages), 0, &messages[0]);
        printf("error(%@) in link the program.", messages);
        return false;
    }
    printf("link ok\n");
    glUseProgram(i_program);
    return true;
}

int VnGlRenderProgram::Load(std::string i_vs_content, std::string i_fs_content, std::vector<std::string> i_attrib_names, std::vector<std::string> i_uniform_names) {
    if(GLContext_SetCurrent_Callback) {
        int ret = GLContext_SetCurrent_Callback(ArgcForSettingGLContextCurrent, (const void **)ArgvForSettingGLContextCurrent);
        if(ret) {
            assert(ret == 0);
            return -5;
        }
    }
    
    _vs_content = i_vs_content;
    _fs_context = i_fs_content;
    
    _handle = glCreateProgram();
    
    // compile vertex and fragment shaders ...
    GLuint vsh = 0, fsh = 0;
    bool ret0 = compile(&vsh, GL_VERTEX_SHADER, i_vs_content.c_str());
    bool ret1 = compile(&fsh, GL_FRAGMENT_SHADER, i_fs_content.c_str());
    if(!(ret0 && ret1)) {
        assert(ret0 && ret1);
        return -1;
    }
    
    glAttachShader(_handle, vsh);
    glAttachShader(_handle, fsh);
    
    // link the shaders ...
    bool ret2 = linkProgram(_handle);
    if(!ret2) {
        assert(ret2);
        return -2;
    }
    
    // bind attributes and it's locations ...
    for (size_t i = 0; i < i_attrib_names.size(); i++) {
        GLint loc = glGetAttribLocation(_handle, i_attrib_names[i].c_str());
        if(loc < 0) {
            assert(loc >= 0);
            return -3;
        }
        glBindAttribLocation(_handle, GLuint(loc), i_attrib_names[i].c_str());
        _attrib_loc_dict.insert(std::make_pair(i_attrib_names[i], loc));
    }
    
    // get uniform locations ...
    for (size_t i = 0; i < i_uniform_names.size(); i++) {
        GLint loc = glGetUniformLocation(_handle, i_uniform_names[i].c_str());
        if(loc < 0) {
            assert(loc >= 0);
            return -4;
        }
        _uniform_loc_dict.insert(std::make_pair(i_uniform_names[i], loc));
    }
    
    // detach shaders ...
    glDetachShader(_handle, vsh);
    glDeleteShader(vsh);
    glDetachShader(_handle, fsh);
    glDeleteShader(fsh);
    
    return 0;
}

void VnGlRenderProgram::Use() {
    glUseProgram(_handle);
}

int VnGlRenderProgram::ActivateBindTextureToUniformLocation(unsigned int i_unit_idx, VnGlTexture *i_tex, const char *i_uniform_name) {
    glActiveTexture(GL_TEXTURE0 + i_unit_idx);
    glBindTexture(GL_TEXTURE_2D, i_tex->_handle);
    auto iter = _uniform_loc_dict.find(i_uniform_name);
    if(iter != _uniform_loc_dict.end()) {
        GLint loc = glGetUniformLocation(_handle, i_uniform_name);
        if(loc == iter->second) {
            glUniform1i(loc, GLint(i_unit_idx));
        }
        else {
            return -2;
        }
    }
    else {
        return -1;
    }
    return 0;
}

int VnGlRenderProgram::VertexAttribPointerAndEnable(const char *i_attrib_name, int i_size, unsigned int i_type, bool i_normalized, int i_stride, const void * i_pointer) {
    auto iter = _attrib_loc_dict.find(i_attrib_name);
    if(iter != _attrib_loc_dict.end()) {
        GLint loc = glGetAttribLocation(_handle, i_attrib_name);
        if(loc == iter->second) {
            glVertexAttribPointer(GLuint(loc), i_size, i_type, i_normalized, i_stride, i_pointer);
            glEnableVertexAttribArray(GLuint(loc));
        }
        else {
            return -2;
        }
    }
    else {
        return -1;
    }
    return 0;
}

int VnGlRenderProgram::DrawArrays(unsigned int mode, int first, int count) {
    glDrawArrays(mode, first, count);
    return 0;
}

int VnGlRenderProgram::VertexAttribDisable(const char *i_attrib_name) {
    auto iter = _attrib_loc_dict.find(i_attrib_name);
    if(iter == _attrib_loc_dict.end()) {
        return -1;
    }
    glDisableVertexAttribArray(GLuint(iter->second));
    return 0;
}

VnGlFilter::VnGlFilter() {
    
}

VnGlFilter::~VnGlFilter() {
    if (_program) {
        delete _program;
    }
}

int VnGlFilter::Draw(void) {
    if(!_program) {
        return -11;
    }
    glVertexAttribPointer(GLuint(_program->_attrib_loc_dict["aPosition"]), 2, GL_FLOAT, 0, 0, squareVertices);
    glEnableVertexAttribArray(GLuint(_program->_attrib_loc_dict["aPosition"]));
    glVertexAttribPointer(GLuint(_program->_attrib_loc_dict["aTextureCoord"]), 2, GL_FLOAT, 0, 0, textureVertices);
    glEnableVertexAttribArray(GLuint(_program->_attrib_loc_dict["aTextureCoord"]));
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glDisableVertexAttribArray(GLuint(_program->_attrib_loc_dict["aPosition"]));
    glDisableVertexAttribArray(GLuint(_program->_attrib_loc_dict["aTextureCoord"]));
    return 0;
}

VnGlYuv2Rgba::VnGlYuv2Rgba() {
    const char * vertex_shader_content = R"(
            attribute vec4 aPosition;
            attribute vec4 aTextureCoord;
            varying lowp vec2 vTexCoord;
            void main() {
                gl_Position = aPosition;
                vTexCoord = aTextureCoord.xy;
            }
            )";
    const char * fragment_shader_content = R"(
            precision mediump float;
            varying vec2 vTexCoord;
            uniform sampler2D uTextureY;
            uniform sampler2D uTextureUV;
            void main() {
                vec3 yuv;
                vec3 rgb;
                yuv.x = texture2D(uTextureY, vTexCoord).r;
                yuv.yz = texture2D(uTextureUV, vTexCoord).ra - vec2(0.5, 0.5);
                rgb = mat3(      1,       1,      1,
                           0, -.18732, 1.8556,
                           1.57481, -.46813,      0) * yuv;
                gl_FragColor = vec4(rgb, 1);
            }
            )";
    _program = new VnGlRenderProgram(vertex_shader_content, fragment_shader_content, {"aPosition", "aTextureCoord"}, {"uTextureY", "uTextureUV"});
}

int VnGlYuv2Rgba::Apply(unsigned int i_fbo, std::vector<VnGlTexture *> i_texs, std::vector<VnGlTexture *> o_texs) {
    
    if(i_texs.size() != 2) {
        return -1;
    }
    
    if(o_texs.size() != 1) {
        return -1;
    }
    
    VnGlTexture *y = i_texs[0];
    VnGlTexture *uv = i_texs[1];
    VnGlTexture *dst = o_texs[0];
    
    dst->bindFBO(i_fbo);
    glViewport(0, 0, dst->_width, dst->_height);
    glDisable(GL_BLEND);
    if(!_program) {
        assert(0);
        return -1;
    }
    
    _program->Use();
    _program->ActivateBindTextureToUniformLocation(0, y, "uTextureY");
    _program->ActivateBindTextureToUniformLocation(1, uv, "uTextureUV");
    _program->VertexAttribPointerAndEnable("aPosition", 2, GL_FLOAT, 0, 0, squareVertices);
    _program->VertexAttribPointerAndEnable("aTextureCoord", 2, GL_FLOAT, 0, 0, textureVertices);
    _program->DrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    _program->VertexAttribDisable("aPosition");
    _program->VertexAttribDisable("aTextureCoord");
    
    return 0;
}

VnGlCirclesDrawer::VnGlCirclesDrawer() {
    const char * vertex_shader_content = R"(
            attribute vec4 av4_Position;
            attribute vec4 av4_Color;
            varying vec4 vColor;
            void main()
            {
                gl_Position = av4_Position;
                vColor = av4_Color;
            }
            )";
    const char * fragment_shader_content = R"(
            precision mediump float;
            varying vec4 vColor;
            void main()
            {
                gl_FragColor = vColor;
            }
            )";
    _program = new VnGlRenderProgram(vertex_shader_content, fragment_shader_content, {"av4_Position", "av4_Color"}, { });
    // set draw needed params
    const float m_pi_180 = float(M_PI / 180);
    float angle = 0.f;
    for (int i = 0; i < 360; i+=1) {
        _sin_angles[i] = std::sin(angle);
        _cos_angles[i] = std::cos(angle);
        angle += m_pi_180;
    }
}

int VnGlCirclesDrawer::Apply(unsigned int i_fbo, std::vector<VnGlTexture *> i_texs, std::vector<VnGlTexture *> o_texs) {
    if(!_circles.size()) {
        return 0;
    }
    
    if(o_texs.size() != 1 or i_texs.size() != 0) {
        return -1;
    }
    
    VnGlTexture *dst = o_texs[0];
    dst->bindFBO(i_fbo);
    glViewport(0, 0, dst->_width, dst->_height);
    glDisable(GL_BLEND);
    if(!_program) {
        assert(0);
        return -1;
    }
    
#ifndef M_PI
    constexpr double M_PI = 3.14159265358979323846264338327950288;
#endif
    for (size_t i = 0; i < _circles.size(); i++) {
        DrawCircle2D circle = _circles[i];
        
        GLfloat colors  [361 * 4] = { 1.f };
        GLfloat vertices[361 * 4] = { 0.f };
        
        vertices[0] = circle._x + circle._x - 1.f;
        vertices[1] = circle._y + circle._y - 1.f;
        vertices[2] = 0;
        vertices[3] = 1;
        
        colors[0] = 1.f;
        colors[1] = 1.f;
        colors[2] = 1.f;
        colors[3] = 1.f;
        
        const float r_y = circle._d * 0.5f / dst->_height;
        const float r_x = circle._d * 0.5f / dst->_width;
        
        for (int j = 0, k = 4; j < 360; j+=1, k+=4) {
            float y = circle._y +  r_y * _cos_angles[j];
            float x = circle._x +  r_x * _sin_angles[j];
            // set vertices:
            vertices[k + 0] = x + x - 1.f;
            vertices[k + 1] = y + y - 1.f;
            vertices[k + 2] = 0;
            vertices[k + 3] = 1;
            // set colors:
            colors[k + 0] = circle._color._r;
            colors[k + 1] = circle._color._g;
            colors[k + 2] = circle._color._b;
            colors[k + 3] = circle._color._a;
        }
        
        _program->Use();
        _program->VertexAttribPointerAndEnable("av4_Position", 4, GL_FLOAT, GL_FALSE, 0, vertices);
        _program->VertexAttribPointerAndEnable("av4_Color", 4, GL_FLOAT, GL_FALSE, 0, colors);
        _program->DrawArrays(GL_TRIANGLE_FAN, 0, 361);
        _program->VertexAttribDisable("av4_Position");
        _program->VertexAttribDisable("av4_Color");
    }
    //
    // GL_TRIANGLES
    return 0;
}

VnGlPointsDrawer::VnGlPointsDrawer() {
    const char * vertex_shader_content = R"(
            attribute vec4 av4_Position;
            attribute vec4 av4_Color;
            attribute float af_PointSize;
            varying vec4 vv4_Color;
            void main() {
                gl_Position = av4_Position;
                gl_PointSize = af_PointSize;
                vv4_Color = av4_Color;
            }
            )";
    const char * fragment_shader_content = R"(
            precision mediump float;
            varying vec4 vv4_Color;
            void main() {
                gl_FragColor = vv4_Color;
            }
            )";
    _program = new VnGlRenderProgram(vertex_shader_content, fragment_shader_content, {"av4_Position", "av4_Color", "af_PointSize"}, { });
}

int VnGlPointsDrawer::Apply(unsigned int i_fbo, std::vector<VnGlTexture *> i_texs, std::vector<VnGlTexture *> o_texs) {
    if(!_points.size()) {
        return 0;
    }
    
    if(o_texs.size() != 1 or i_texs.size() != 0) {
        return -1;
    }
    
    VnGlTexture *dst = o_texs[0];
    if(dst) {
        dst->bindFBO(i_fbo);
        glViewport(0, 0, dst->_width, dst->_height);
        glDisable(GL_BLEND);
#ifdef GL_VERTEX_PROGRAM_POINT_SIZE
        glEnable(GL_VERTEX_PROGRAM_POINT_SIZE);
#endif
    }
    
    if(_program) {
        _program->Use();
    }
    else {
        assert(0);
        return -1;
    }
    
    
    GLfloat *positions = new GLfloat[4 * _points.size()];
    GLfloat *colors = new GLfloat[4 * _points.size()];
    GLfloat *point_sizes = new GLfloat[_points.size()];
    
    for (size_t i = 0, k = 0; i < _points.size(); i+=1, k+=4) {
        //transform positions
        positions[ k + 0] = _points[i]._x + _points[i]._x - 1.f;
        positions[ k + 1] = _points[i]._y + _points[i]._y - 1.f;
        positions[ k + 2] = 0;
        positions[ k + 3] = 1;
        //get points color
        colors[k + 0] = _points[i]._color._r;
        colors[k + 1] = _points[i]._color._g;
        colors[k + 2] = _points[i]._color._b;
        colors[k + 3] = _points[i]._color._a;
        //get points thickness
        point_sizes[i] = _points[i]._thickness;
    }
    
    _program->VertexAttribPointerAndEnable("av4_Position", 4, GL_FLOAT, GL_FALSE, 0, positions);
    _program->VertexAttribPointerAndEnable("av4_Color", 4, GL_FLOAT, GL_FALSE, 0, colors);
    _program->VertexAttribPointerAndEnable("af_PointSize", 1, GL_FLOAT, GL_FALSE, 0, point_sizes);
    _program->DrawArrays(GL_POINTS, 0, GLint(_points.size()));
    _program->VertexAttribDisable("av4_Position");
    _program->VertexAttribDisable("av4_Color");
    _program->VertexAttribDisable("af_PointSize");
    
    delete[] positions;
    delete[] colors;
    delete[] point_sizes;
    
    return 0;
}

VnGlLinesDrawer::VnGlLinesDrawer() {
    const char * vertex_shader_content = R"(
            attribute vec4 av4_Position;
            attribute vec4 av4_Color;
            varying vec4 vColor;
            void main() {
                gl_Position = av4_Position;
                vColor = av4_Color;
            }
            )";
    const char * fragment_shader_content = R"(
            precision mediump float;
            varying vec4 vColor;
            void main() {
                gl_FragColor = vColor;
            }
            )";
    _program = new VnGlRenderProgram(vertex_shader_content, fragment_shader_content, {"av4_Position", "av4_Color"}, { });
}

int VnGlLinesDrawer::Apply(unsigned int i_fbo, std::vector<VnGlTexture *> i_texs, std::vector<VnGlTexture *> o_texs) {
    if(!_lines.size()) {
        return 0;
    }
    
    if(o_texs.size() != 1 or i_texs.size() != 0) {
        return -1;
    }
    
    VnGlTexture *dst = o_texs[0];
    dst->bindFBO(i_fbo);
    glViewport(0, 0, dst->_width, dst->_height);
    glDisable(GL_BLEND);
    if(!_program) {
        assert(0);
        return -1;
    }
    
#ifndef M_PI
    constexpr double M_PI = 3.14159265358979323846264338327950288;
#endif
    for (size_t i = 0; i < _lines.size(); i++) {
        DrawLine2D line = _lines[i];
        float theta = std::atan( std::abs( (line._p1._x - line._p0._x) / (line._p1._y - line._p0._y) ) );
        float dx = std::cos(theta) * line._thickness * 0.5f / dst->_width;
        float dy = std::sin(theta) * line._thickness * 0.5f / dst->_height;
        //
        std::vector<DrawPoint2D> corner;
        corner.emplace_back(DrawPoint2D(line._p0._x - dx, line._p0._y + dy, 0, line._p0._color));
        corner.emplace_back(DrawPoint2D(line._p0._x + dx, line._p0._y - dy, 0, line._p0._color));
        corner.emplace_back(DrawPoint2D(line._p1._x + dx, line._p1._y - dy, 0, line._p1._color));
        corner.emplace_back(DrawPoint2D(line._p1._x - dx, line._p1._y + dy, 0, line._p1._color));
        //
        GLfloat colors[4 * 4] = { 1.f };
        GLfloat vertices[4 * 4] = { 0.f };
        for (size_t j = 0, k = 0; j < 4; j+=1, k+=4) {
            // set triangle corners:
            vertices[k + 0] = corner[j]._x + corner[j]._x - 1.f;
            vertices[k + 1] = corner[j]._y + corner[j]._y - 1.f;
            vertices[k + 2] = 0;
            vertices[k + 3] = 1;
            // set color:
            colors[k + 0] = corner[j]._color._r;
            colors[k + 1] = corner[j]._color._g;
            colors[k + 2] = corner[j]._color._b;
            colors[k + 3] = corner[j]._color._a;
        }
        _program->Use();
        _program->VertexAttribPointerAndEnable("av4_Position", 4, GL_FLOAT, GL_FALSE, 0, vertices);
        _program->VertexAttribPointerAndEnable("av4_Color", 4, GL_FLOAT, GL_FALSE, 0, colors);
        _program->DrawArrays(GL_TRIANGLE_FAN, 0, 4);
        _program->VertexAttribDisable("av4_Position");
        _program->VertexAttribDisable("av4_Color");
    }
    return 0;
}

VnGlRectsDrawer::~VnGlRectsDrawer() {
    if(_lines_drawer) {
        delete _lines_drawer;
    }
}

VnGlRectsDrawer::VnGlRectsDrawer() {
    _program = nullptr;
    _lines_drawer = new VnGlLinesDrawer();
}

int VnGlRectsDrawer::Apply(unsigned int i_fbo, std::vector<VnGlTexture *> i_texs, std::vector<VnGlTexture *> o_texs) {
    if(_rects.size() == 0) {
        return 0;
    }
    _lines_drawer->_lines.clear();
    for (size_t i = 0; i < _rects.size(); ++i) {
        _lines_drawer->_lines.emplace_back(
                                           DrawLine2D(
                                                      DrawPoint2D(_rects[i]._left,    _rects[i]._top,     _rects[i]._thickness, _rects[i]._color),
                                                      DrawPoint2D(_rects[i]._right,   _rects[i]._top,     _rects[i]._thickness, _rects[i]._color),
                                                      _rects[i]._thickness
                                                      )
                                           );
        _lines_drawer->_lines.emplace_back(
                                           DrawLine2D(
                                                      DrawPoint2D(_rects[i]._right,   _rects[i]._top,     _rects[i]._thickness, _rects[i]._color),
                                                      DrawPoint2D(_rects[i]._right,   _rects[i]._bottom,  _rects[i]._thickness, _rects[i]._color),
                                                      _rects[i]._thickness
                                                      )
                                           );
        _lines_drawer->_lines.emplace_back(
                                           DrawLine2D(
                                                      DrawPoint2D(_rects[i]._right,   _rects[i]._bottom,  _rects[i]._thickness, _rects[i]._color),
                                                      DrawPoint2D(_rects[i]._left,    _rects[i]._bottom,  _rects[i]._thickness, _rects[i]._color),
                                                      _rects[i]._thickness
                                                      )
                                           );
        _lines_drawer->_lines.emplace_back(
                                           DrawLine2D(
                                                      DrawPoint2D(_rects[i]._left,    _rects[i]._bottom, _rects[i]._thickness, _rects[i]._color),
                                                      DrawPoint2D(_rects[i]._left,    _rects[i]._top,    _rects[i]._thickness, _rects[i]._color),
                                                      _rects[i]._thickness
                                                      )
                                           );
    }
    _lines_drawer->Apply(i_fbo, i_texs, o_texs);
    return 0;
}

VnGlImagesDrawer::VnGlImagesDrawer() {
    const char * vertex_shader_content = R"(
            attribute vec4 aPosition;
            attribute vec4 aTextureCoord;
            varying vec2 vTexCoord;
            void main() {
                gl_Position = aPosition;
                vTexCoord = aTextureCoord.xy;
            }
            )";
    const char * fragment_shader_content = R"(
            precision mediump float;
            varying vec2 vTexCoord;
            uniform sampler2D uTexture;
            void main() {
                gl_FragColor = texture2D(uTexture, vTexCoord);
            }
            )";
    _program = new VnGlRenderProgram(vertex_shader_content, fragment_shader_content, {"aPosition", "aTextureCoord"}, {"uTexture"});
}

void VnGlImagesDrawer::SetPositions(std::vector<DrawImgPos2D> &positions){
    _positions = positions;
}

int VnGlImagesDrawer::Apply(unsigned int i_fbo, std::vector<VnGlTexture *> i_texs, std::vector<VnGlTexture *> o_texs) {
    
    if(_positions.size() != i_texs.size()) {
        return -2;
    }
    
    if(_positions.size() == 0) {
        return 0;
    }
    
    if(o_texs.size() != 1) {
        return -1;
    }
    
    VnGlTexture *dst = o_texs[0];
    dst->bindFBO(i_fbo);
    glViewport(0, 0, dst->_width, dst->_height);
    glDisable(GL_BLEND);
    if(!_program) {
        assert(0);
        return -1;
    }
    
    for (size_t i = 0; i < _positions.size(); i++) {
        
        float left = _positions[i]._left + _positions[i]._left - 1.f;
        float top = _positions[i]._top + _positions[i]._top - 1.f;
        float right = _positions[i]._right + _positions[i]._right - 1.f;
        float bottom = _positions[i]._bottom + _positions[i]._bottom - 1.f;
        
        float square_vertices[8] = {
            left,   top,   // left-top
            right,  top,    // right-top
            left,   bottom,   // left-bottom
            right,  bottom,    // right-bottom
        };
        
        float texture_vertices[8] = {
            0.0f,  0.0f,
            1.0f,  0.0f,
            0.0f,  1.0f,
            1.0f,  1.0f,
        };
        
        _program->Use();
        _program->ActivateBindTextureToUniformLocation(0, i_texs[i], "uTexture");
        _program->VertexAttribPointerAndEnable("aPosition", 2, GL_FLOAT, 0, 0, square_vertices);
        _program->VertexAttribPointerAndEnable("aTextureCoord", 2, GL_FLOAT, 0, 0, texture_vertices);
        _program->DrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        _program->VertexAttribDisable("aPosition");
        _program->VertexAttribDisable("aTextureCoord");
    }
    
    return 0;
}

VnGlAlphaBlending::VnGlAlphaBlending() {
    const char * vertex_shader_content = R"(
            precision mediump float;
            attribute vec4 aPosition;
            attribute vec4 aTextureCoord;
            varying vec2 vTexCoord;
            void main() {
                gl_Position = aPosition;
                vTexCoord = aTextureCoord.xy;
            }
            )";
    const char * fragment_shader_content = R"(
            precision mediump float;
            varying vec2 vTexCoord;
            uniform sampler2D uTextureForeground;
            uniform sampler2D uTextureMask;
            uniform sampler2D uTextureBackground;
            void main() {
                vec4 mask = texture2D(uTextureMask, vTexCoord);
                vec4 background = texture2D(uTextureBackground, vTexCoord);
                vec4 foreground = texture2D(uTextureForeground, vTexCoord);
                gl_FragColor=mix(background, foreground, mask.r);
            }
            )";
    _program = new VnGlRenderProgram(vertex_shader_content, fragment_shader_content, {"aPosition", "aTextureCoord"}, {"uTextureForeground", "uTextureMask", "uTextureBackground"});
}

int VnGlAlphaBlending::Apply(unsigned int i_fbo, std::vector<VnGlTexture *> i_texs, std::vector<VnGlTexture *> o_texs) {
    
    if(i_texs.size() != 3) {
        return -1;
    }
    
    if(o_texs.size() != 1) {
        return -1;
    }
    
    VnGlTexture *foreground = i_texs[0];
    VnGlTexture *mask = i_texs[1];
    VnGlTexture *background = i_texs[2];
    VnGlTexture *dst = o_texs[0];
    
    dst->bindFBO(i_fbo);
    glViewport(0, 0, dst->_width, dst->_height);
    glDisable(GL_BLEND);
    if(!_program) {
        assert(0);
        return -1;
    }
    
    _program->Use();
    _program->ActivateBindTextureToUniformLocation(0, foreground, "uTextureForeground");
    _program->ActivateBindTextureToUniformLocation(1, mask, "uTextureMask");
    _program->ActivateBindTextureToUniformLocation(2, background, "uTextureBackground");
    _program->VertexAttribPointerAndEnable("aPosition", 2, GL_FLOAT, 0, 0, squareVertices);
    _program->VertexAttribPointerAndEnable("aTextureCoord", 2, GL_FLOAT, 0, 0, textureVertices);
    _program->DrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    _program->VertexAttribDisable("aPosition");
    _program->VertexAttribDisable("aTextureCoord");
    
    return 0;
}

VnGlBgra2Rgba::VnGlBgra2Rgba() {
    const char * vertex_shader_content =
   R"(
   attribute vec4 aPosition;
   attribute vec4 aTextureCoord;
   varying vec2 vTexCoord;
   void main() {
    gl_Position = aPosition;
    vTexCoord = aTextureCoord.xy;
   }
   )";
    const char * fragment_shader_content =
   R"(
   precision mediump float;
   varying vec2 vTexCoord;
   uniform sampler2D uTexture;
   void main() {
    gl_FragColor = texture2D(uTexture, vTexCoord).bgra;
   }
   )";
    _program = new VnGlRenderProgram(vertex_shader_content, fragment_shader_content, {"aPosition", "aTextureCoord"}, {"uTexture"});
}

int VnGlBgra2Rgba::Apply(unsigned int i_fbo, std::vector<VnGlTexture *> i_texs, std::vector<VnGlTexture *> o_texs) {
    
    if(i_texs.size() != 1) {
        return -1;
    }
    
    if(o_texs.size() != 1) {
        return -2;
    }
    
    VnGlTexture *src = i_texs[0];
    VnGlTexture *dst = o_texs[0];
    
    dst->bindFBO(i_fbo);
    glViewport(0, 0, dst->_width, dst->_height);
    glDisable(GL_BLEND);
    if(!_program) {
        assert(0);
        return -1;
    }
    
    _program->Use();
    _program->ActivateBindTextureToUniformLocation(0, src, "uTexture");
    _program->VertexAttribPointerAndEnable("aPosition", 2, GL_FLOAT, 0, 0, squareVertices);
    _program->VertexAttribPointerAndEnable("aTextureCoord", 2, GL_FLOAT, 0, 0, textureVertices);
    _program->DrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    _program->VertexAttribDisable("aPosition");
    _program->VertexAttribDisable("aTextureCoord");
    
    return 0;
}


VnGlRotate90R::VnGlRotate90R() {
    const char * vertex_shader_content =
   R"(
   attribute vec4 aPosition;
   attribute vec4 aTextureCoord;
   varying vec2 vTexCoord;
   void main() {
    gl_Position = aPosition;
    vTexCoord = aTextureCoord.xy;
   }
   )";
    const char * fragment_shader_content =
   R"(
   precision mediump float;
   varying vec2 vTexCoord;
   uniform sampler2D uTexture;
   void main() {
    gl_FragColor = texture2D(uTexture, vTexCoord);
   }
   )";
    _program = new VnGlRenderProgram(vertex_shader_content, fragment_shader_content, {"aPosition", "aTextureCoord"}, {"uTexture"});
}

int VnGlRotate90R::Apply(unsigned int i_fbo, std::vector<VnGlTexture *> i_texs, std::vector<VnGlTexture *> o_texs) {
    
    if(i_texs.size() != 1) {
        return -1;
    }
    
    if(o_texs.size() != 1) {
        return -2;
    }
    
    VnGlTexture *src = i_texs[0];
    VnGlTexture *dst = o_texs[0];
    
    dst->bindFBO(i_fbo);
    glViewport(0, 0, dst->_width, dst->_height);
    glDisable(GL_BLEND);
    if(!_program) {
        assert(0);
        return -1;
    }
    
    _program->Use();
    _program->ActivateBindTextureToUniformLocation(0, src, "uTexture");
    _program->VertexAttribPointerAndEnable("aPosition", 2, GL_FLOAT, 0, 0, squareVertices);
    _program->VertexAttribPointerAndEnable("aTextureCoord", 2, GL_FLOAT, 0, 0, textureVertices_90R);
    _program->DrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    _program->VertexAttribDisable("aPosition");
    _program->VertexAttribDisable("aTextureCoord");
    
    return 0;
    
}

VnGlRotate90L::VnGlRotate90L() {
    const char * vertex_shader_content =
   R"(
   attribute vec4 aPosition;
   attribute vec4 aTextureCoord;
   varying vec2 vTexCoord;
   void main() {
    gl_Position = aPosition;
    vTexCoord = aTextureCoord.xy;
   }
   )";
    const char * fragment_shader_content =
   R"(
   precision mediump float;
   varying vec2 vTexCoord;
   uniform sampler2D uTexture;
   void main() {
    gl_FragColor = texture2D(uTexture, vTexCoord);
   }
   )";
    _program = new VnGlRenderProgram(vertex_shader_content, fragment_shader_content, {"aPosition", "aTextureCoord"}, {"uTexture"});
}

int VnGlRotate90L::Apply(unsigned int i_fbo, std::vector<VnGlTexture *> i_texs, std::vector<VnGlTexture *> o_texs) {
    
    if(i_texs.size() != 1) {
        return -1;
    }
    
    if(o_texs.size() != 1) {
        return -2;
    }
    
    VnGlTexture *src = i_texs[0];
    VnGlTexture *dst = o_texs[0];
    
    dst->bindFBO(i_fbo);
    glViewport(0, 0, dst->_width, dst->_height);
    glDisable(GL_BLEND);
    if(!_program) {
        assert(0);
        return -1;
    }
    
    _program->Use();
    _program->ActivateBindTextureToUniformLocation(0, src, "uTexture");
    _program->VertexAttribPointerAndEnable("aPosition", 2, GL_FLOAT, 0, 0, squareVertices);
    _program->VertexAttribPointerAndEnable("aTextureCoord", 2, GL_FLOAT, 0, 0, textureVertices_90L);
    _program->DrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    _program->VertexAttribDisable("aPosition");
    _program->VertexAttribDisable("aTextureCoord");
    
    return 0;
    
}


VnGlRotate180::VnGlRotate180() {
    const char * vertex_shader_content =
   R"(
   attribute vec4 aPosition;
   attribute vec4 aTextureCoord;
   varying vec2 vTexCoord;
   void main() {
    gl_Position = aPosition;
    vTexCoord = aTextureCoord.xy;
   }
   )";
    const char * fragment_shader_content =
   R"(
   precision mediump float;
   varying vec2 vTexCoord;
   uniform sampler2D uTexture;
   void main() {
    gl_FragColor = texture2D(uTexture, vTexCoord);
   }
   )";
    _program = new VnGlRenderProgram(vertex_shader_content, fragment_shader_content, {"aPosition", "aTextureCoord"}, {"uTexture"});
}

int VnGlRotate180::Apply(unsigned int i_fbo, std::vector<VnGlTexture *> i_texs, std::vector<VnGlTexture *> o_texs) {
    
    if(i_texs.size() != 1) {
        return -1;
    }
    
    if(o_texs.size() != 1) {
        return -2;
    }
    
    VnGlTexture *src = i_texs[0];
    VnGlTexture *dst = o_texs[0];
    
    dst->bindFBO(i_fbo);
    glViewport(0, 0, dst->_width, dst->_height);
    glDisable(GL_BLEND);
    if(!_program) {
        assert(0);
        return -1;
    }
    
    _program->Use();
    _program->ActivateBindTextureToUniformLocation(0, src, "uTexture");
    _program->VertexAttribPointerAndEnable("aPosition", 2, GL_FLOAT, 0, 0, squareVertices);
    _program->VertexAttribPointerAndEnable("aTextureCoord", 2, GL_FLOAT, 0, 0, textureVertices_180);
    _program->DrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    _program->VertexAttribDisable("aPosition");
    _program->VertexAttribDisable("aTextureCoord");
    
    return 0;
    
}



VnGlHorizontalFlip::VnGlHorizontalFlip() {
    const char * vertex_shader_content =
   R"(
   attribute vec4 aPosition;
   attribute vec4 aTextureCoord;
   varying vec2 vTexCoord;
   void main() {
    gl_Position = aPosition;
    vTexCoord = aTextureCoord.xy;
   }
   )";
    const char * fragment_shader_content =
   R"(
   precision mediump float;
   varying vec2 vTexCoord;
   uniform sampler2D uTexture;
   void main() {
    gl_FragColor = texture2D(uTexture, vTexCoord);
   }
   )";
    _program = new VnGlRenderProgram(vertex_shader_content, fragment_shader_content, {"aPosition", "aTextureCoord"}, {"uTexture"});
}

int VnGlHorizontalFlip::Apply(unsigned int i_fbo, std::vector<VnGlTexture *> i_texs, std::vector<VnGlTexture *> o_texs) {
    
    if(i_texs.size() != 1) {
        return -1;
    }
    
    if(o_texs.size() != 1) {
        return -2;
    }
    
    VnGlTexture *src = i_texs[0];
    VnGlTexture *dst = o_texs[0];
    
    dst->bindFBO(i_fbo);
    glViewport(0, 0, dst->_width, dst->_height);
    glDisable(GL_BLEND);
    if(!_program) {
        assert(0);
        return -1;
    }
    
    _program->Use();
    _program->ActivateBindTextureToUniformLocation(0, src, "uTexture");
    _program->VertexAttribPointerAndEnable("aPosition", 2, GL_FLOAT, 0, 0, squareVertices);
    _program->VertexAttribPointerAndEnable("aTextureCoord", 2, GL_FLOAT, 0, 0, textureVertices_HFlip);
    _program->DrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    _program->VertexAttribDisable("aPosition");
    _program->VertexAttribDisable("aTextureCoord");
    
    return 0;
    
}



VnGlVerticalFlip::VnGlVerticalFlip() {
    const char * vertex_shader_content =
   R"(
   attribute vec4 aPosition;
   attribute vec4 aTextureCoord;
   varying vec2 vTexCoord;
   void main() {
    gl_Position = aPosition;
    vTexCoord = aTextureCoord.xy;
   }
   )";
    const char * fragment_shader_content =
   R"(
   precision mediump float;
   varying vec2 vTexCoord;
   uniform sampler2D uTexture;
   void main() {
    gl_FragColor = texture2D(uTexture, vTexCoord);
   }
   )";
    _program = new VnGlRenderProgram(vertex_shader_content, fragment_shader_content, {"aPosition", "aTextureCoord"}, {"uTexture"});
}

int VnGlVerticalFlip::Apply(unsigned int i_fbo, std::vector<VnGlTexture *> i_texs, std::vector<VnGlTexture *> o_texs) {
    
    if(i_texs.size() != 1) {
        return -1;
    }
    
    if(o_texs.size() != 1) {
        return -2;
    }
    
    VnGlTexture *src = i_texs[0];
    VnGlTexture *dst = o_texs[0];
    
    dst->bindFBO(i_fbo);
    glViewport(0, 0, dst->_width, dst->_height);
    glDisable(GL_BLEND);
    if(!_program) {
        assert(0);
        return -1;
    }
    
    _program->Use();
    _program->ActivateBindTextureToUniformLocation(0, src, "uTexture");
    _program->VertexAttribPointerAndEnable("aPosition", 2, GL_FLOAT, 0, 0, squareVertices);
    _program->VertexAttribPointerAndEnable("aTextureCoord", 2, GL_FLOAT, 0, 0, textureVertices_VFlip);
    _program->DrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    _program->VertexAttribDisable("aPosition");
    _program->VertexAttribDisable("aTextureCoord");
    
    return 0;
    
}

VnGlTextureCopy::VnGlTextureCopy() {
    const char * vertex_shader_content =
   R"(
   attribute vec4 aPosition;
   attribute vec4 aTextureCoord;
   varying vec2 vTexCoord;
   void main() {
    gl_Position = aPosition;
    vTexCoord = aTextureCoord.xy;
   }
   )";
    const char * fragment_shader_content =
   R"(
   precision mediump float;
   varying vec2 vTexCoord;
   uniform sampler2D uTexture;
   void main() {
    gl_FragColor = texture2D(uTexture, vTexCoord);
   }
   )";
    _program = new VnGlRenderProgram(vertex_shader_content, fragment_shader_content, {"aPosition", "aTextureCoord"}, {"uTexture"});
}

int VnGlTextureCopy::Apply(unsigned int i_fbo, std::vector<VnGlTexture *> i_texs, std::vector<VnGlTexture *> o_texs) {
    
    if(i_texs.size() != 1) {
        return -1;
    }
    
    if(o_texs.size() != 1) {
        return -2;
    }
    
    VnGlTexture *src = i_texs[0];
    VnGlTexture *dst = o_texs[0];
    
    dst->bindFBO(i_fbo);
    glViewport(0, 0, dst->_width, dst->_height);
    glDisable(GL_BLEND);
    if(!_program) {
        assert(0);
        return -1;
    }
    
    _program->Use();
    _program->ActivateBindTextureToUniformLocation(0, src, "uTexture");
    _program->VertexAttribPointerAndEnable("aPosition", 2, GL_FLOAT, 0, 0, squareVertices);
    _program->VertexAttribPointerAndEnable("aTextureCoord", 2, GL_FLOAT, 0, 0, textureVertices);
    _program->DrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    _program->VertexAttribDisable("aPosition");
    _program->VertexAttribDisable("aTextureCoord");
    
    return 0;
    
}

}
}

