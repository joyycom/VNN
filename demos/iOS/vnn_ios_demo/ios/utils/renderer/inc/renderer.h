//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#include <map>
#include <string>
#include <vector>
#include <memory>


namespace vnn {
namespace renderkit {

typedef int(*GLCONTEXT_SET_CURRENT_CALLBACK)(const int argc, const void *argv[]);
int Set_GLContext_SetCurrent_Callback(GLCONTEXT_SET_CURRENT_CALLBACK i_callback);
int Set_GLContext_SetCurrent_Argc_Argv(const int i_argc, const void *i_argv[]);


class VnGlTexture {
public:
    ~VnGlTexture();
    VnGlTexture() = default;
    VnGlTexture(unsigned int i_target, unsigned int i_format, int i_width, int i_height, unsigned int i_dtype, const void *i_data);
    VnGlTexture(unsigned int i_handle, unsigned int i_target, unsigned int i_format, int i_width, int i_height, unsigned int i_dtype, const void *i_data); // shadow init
    int setData(const void *i_data);
    int bindFBO(unsigned int i_fbo);
    
public:
    unsigned int _handle{0};
    unsigned int _target{0};
    unsigned int _format{0};
    unsigned int _dtype{0};
    int _width{0};
    int _height{0};
    bool _is_shadow{true};
};
typedef std::shared_ptr<VnGlTexture> VnGlTexturePtr;


class VnGlRenderProgram {
public:
    ~VnGlRenderProgram();
    VnGlRenderProgram() = default;
    VnGlRenderProgram(std::string i_vs_content, std::string i_fs_content, std::vector<std::string> i_attrib_names, std::vector<std::string> i_uniform_names);
    int Load(std::string i_vs_content, std::string i_fs_content, std::vector<std::string> i_attrib_names, std::vector<std::string> i_uniform_names);
    void Use();
    int ActivateBindTextureToUniformLocation(unsigned int i_unit_idx, VnGlTexture *i_tex, const char *i_uniform_name);
    int VertexAttribPointerAndEnable(const char *i_attrib_name, int i_size, unsigned int i_type, bool i_normalized, int i_stride, const void * i_pointer);
    int DrawArrays(unsigned int mode, int first, int count);
    int VertexAttribDisable(const char *i_attrib_name);
    
public:
    unsigned int _handle;
    std::string _vs_content;
    std::string _fs_context;
    std::map<std::string, int> _uniform_loc_dict;
    std::map<std::string, int> _attrib_loc_dict;
};
typedef std::shared_ptr<VnGlRenderProgram> VnGlRenderProgramPtr;


class VnGlFilter {
public:
    VnGlFilter();
    virtual ~VnGlFilter();
    
    virtual int Apply(unsigned int i_fbo, std::vector<VnGlTexture *> i_texs, std::vector<VnGlTexture *> o_texs) = 0;
    virtual int Draw(void);
    
protected:
    int _backingW;
    int _backingH;
    VnGlRenderProgram *_program;
};
typedef std::shared_ptr<VnGlFilter> VnGlFilterPtr;


class VnGlYuv2Rgba : public VnGlFilter {
public:
    VnGlYuv2Rgba();
    int Apply(unsigned int i_fbo, std::vector<VnGlTexture *> i_texs, std::vector<VnGlTexture *> o_texs);
};
typedef std::shared_ptr<VnGlYuv2Rgba> VnGlYuv2RgbaPtr;


struct DrawColorRGBA {
    DrawColorRGBA(const float& i_r,
                  const float& i_g,
                  const float& i_b,
                  const float& i_a) : _r(i_r), _g(i_g), _b(i_b), _a(i_a) {
    }
    float _r;
    float _g;
    float _b;
    float _a;
};


struct DrawCircle2D {
    DrawCircle2D(const float& i_x,
                 const float& i_y,
                 const float& i_d,
                 const DrawColorRGBA& i_color) : _x(i_x), _y(i_y), _d(i_d), _color(i_color) {
    }
    float _x;
    float _y;
    float _d;
    DrawColorRGBA _color;
};


struct DrawPoint2D {
    DrawPoint2D(const float& i_x,
                const float& i_y,
                const float& i_thickness,
                const DrawColorRGBA& i_color) : _x(i_x), _y(i_y), _thickness(i_thickness), _color(i_color) {
    }
    float _x;
    float _y;
    float _thickness;
    DrawColorRGBA _color;
};


struct DrawLine2D {
    DrawLine2D(const DrawPoint2D& i_p0,
               const DrawPoint2D& i_p1,
               const float& i_thickness) : _p0(i_p0), _p1(i_p1), _thickness(i_thickness) {
    }
    DrawPoint2D _p0;
    DrawPoint2D _p1;
    float _thickness;
};


struct DrawRect2D {
    DrawRect2D(const float& i_left,
               const float& i_top,
               const float& i_right,
               const float& i_bottom,
               const float& i_thickness,
               const DrawColorRGBA& i_color) : _left(i_left), _top(i_top), _right(i_right), _bottom(i_bottom), _thickness(i_thickness), _color(i_color) {
    }
    float _left;
    float _top;
    float _right;
    float _bottom;
    float _thickness;
    DrawColorRGBA _color;
};


struct DrawImgPos2D {
    DrawImgPos2D(const float& i_left,
                 const float& i_top,
                 const float& i_right,
                 const float& i_bottom) : _left(i_left), _top(i_top), _right(i_right), _bottom(i_bottom) {
    }
    float _left;
    float _top;
    float _right;
    float _bottom;
};


class VnGlCirclesDrawer : public VnGlFilter {
public:
    VnGlCirclesDrawer();
    int Apply(unsigned int i_fbo, std::vector<VnGlTexture *> i_texs, std::vector<VnGlTexture *> o_texs);
    
public:
    std::vector<DrawCircle2D> _circles;
    
protected:
    float _sin_angles[360];
    float _cos_angles[360];
};
typedef std::shared_ptr<VnGlCirclesDrawer> VnGlCirclesDrawerPtr;


class VnGlPointsDrawer : public VnGlFilter {
public:
    VnGlPointsDrawer();
    int Apply(unsigned int i_fbo, std::vector<VnGlTexture *> i_texs, std::vector<VnGlTexture *> o_texs);
    
public:
    std::vector<DrawPoint2D> _points;
};
typedef std::shared_ptr<VnGlPointsDrawer> VnGlPointsDrawerPtr;


class VnGlLinesDrawer : public VnGlFilter {
public:
    VnGlLinesDrawer();
    int Apply(unsigned int i_fbo, std::vector<VnGlTexture *> i_texs, std::vector<VnGlTexture *> o_texs);
public:
    std::vector<DrawLine2D> _lines;
};
typedef std::shared_ptr<VnGlLinesDrawer> VnGlLinesDrawerPtr;


class VnGlRectsDrawer : public VnGlFilter {
public:
    ~VnGlRectsDrawer();
    VnGlRectsDrawer();
    int Apply(unsigned int i_fbo, std::vector<VnGlTexture *> i_texs, std::vector<VnGlTexture *> o_texs);
public:
    std::vector<DrawRect2D> _rects;
    
protected:
    VnGlLinesDrawer *_lines_drawer;
};
typedef std::shared_ptr<VnGlRectsDrawer> VnGlRectsDrawerPtr;


class VnGlImagesDrawer : public VnGlFilter {
public:
    VnGlImagesDrawer();
    int Apply(unsigned int i_fbo, std::vector<VnGlTexture *> i_texs, std::vector<VnGlTexture *> o_texs);
    void SetPositions(std::vector<DrawImgPos2D> &positions);
public:
    std::vector<DrawImgPos2D> _positions;
};
typedef std::shared_ptr<VnGlImagesDrawer> VnGlImagesDrawerPtr;


class VnGlAlphaBlending : public VnGlFilter {
public:
    VnGlAlphaBlending();
    int Apply(unsigned int i_fbo, std::vector<VnGlTexture *> i_texs, std::vector<VnGlTexture *> o_texs);
};
typedef std::shared_ptr<VnGlAlphaBlending> VnGlAlphaBlendingPtr;

class VnGlTextureCopy : public VnGlFilter {
public:
    VnGlTextureCopy();
    int Apply(unsigned int i_fbo, std::vector<VnGlTexture *> i_texs, std::vector<VnGlTexture *> o_texs);
};
typedef std::shared_ptr<VnGlTextureCopy> VnGlTextureCopyPtr;

class VnGlBgra2Rgba : public VnGlFilter {
public:
    VnGlBgra2Rgba();
    int Apply(unsigned int i_fbo, std::vector<VnGlTexture *> i_texs, std::vector<VnGlTexture *> o_texs);
};
typedef std::shared_ptr<VnGlBgra2Rgba> VnGlBgra2RgbaPtr;

class VnGlRotate90R : public VnGlFilter {
public:
    VnGlRotate90R();
    int Apply(unsigned int i_fbo, std::vector<VnGlTexture *> i_texs, std::vector<VnGlTexture *> o_texs);
};
typedef std::shared_ptr<VnGlRotate90R> VnGlRotate90RPtr;

class VnGlRotate90L : public VnGlFilter {
public:
    VnGlRotate90L();
    int Apply(unsigned int i_fbo, std::vector<VnGlTexture *> i_texs, std::vector<VnGlTexture *> o_texs);
};
typedef std::shared_ptr<VnGlRotate90L> VnGlRotate90LPtr;

class VnGlRotate180 : public VnGlFilter {
public:
    VnGlRotate180();
    int Apply(unsigned int i_fbo, std::vector<VnGlTexture *> i_texs, std::vector<VnGlTexture *> o_texs);
};
typedef std::shared_ptr<VnGlRotate180> VnGlRotate180Ptr;

class VnGlHorizontalFlip : public VnGlFilter {
public:
    VnGlHorizontalFlip();
    int Apply(unsigned int i_fbo, std::vector<VnGlTexture *> i_texs, std::vector<VnGlTexture *> o_texs);
};
typedef std::shared_ptr<VnGlHorizontalFlip> VnGlHFlipPtr;

class VnGlVerticalFlip : public VnGlFilter {
public:
    VnGlVerticalFlip();
    int Apply(unsigned int i_fbo, std::vector<VnGlTexture *> i_texs, std::vector<VnGlTexture *> o_texs);
};
typedef std::shared_ptr<VnGlVerticalFlip> VnGlVFlipPtr;

class VnU8Buffer {
public:
    VnU8Buffer(size_t dataSize){
        data = (unsigned char *)malloc(dataSize);
    }
    ~VnU8Buffer(){
        if(data){
            free(data);
            data = nullptr;
        }
    }
    
public:
    unsigned char* data;
};
typedef std::shared_ptr<VnU8Buffer> VnU8BufferPtr;


}
}

