//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "UIView_GLRenderUtils.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>

@implementation UIView_GLRenderUtils

+ (Class) layerClass {
    return [CAEAGLLayer class];
}

- (instancetype)init_With_Frame:(CGRect)frame EAGLContext:(EAGLContext *)context {
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    
    // Do OpenGL Core Animation layer setup
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    _glContext = context;
    if (!_glContext) {
        return nil;
    }
    if ([EAGLContext currentContext] != _glContext) {
        if (![EAGLContext setCurrentContext:_glContext]) {
            return nil;
        }
    }
    
    _covertYUV2RGBA = std::make_shared<VnGlYuv2Rgba>();
    _circlesDrawer = std::make_shared<VnGlCirclesDrawer>();
    _pointsDrawer = std::make_shared<VnGlPointsDrawer>();
    _linesDrawer = std::make_shared<VnGlLinesDrawer>();
    _rectsDrawer = std::make_shared<VnGlRectsDrawer>();
    _imagesDrawer = std::make_shared<VnGlImagesDrawer>();
    
    _rotate90LDrawer = std::make_shared<VnGlRotate90L>();
    _rotate90RDrawer = std::make_shared<VnGlRotate90R>();
    _rotate180Drawer = std::make_shared<VnGlRotate180>();;
    _hFlipDrawer = std::make_shared<VnGlHorizontalFlip>();
    _vFlipDrawer = std::make_shared<VnGlVerticalFlip>();
    
    if(!_drawProgramRGBA) {
        std::string vshContent = R"(
  attribute vec4 aPosition;
  attribute vec4 aTextureCoord;
  varying lowp vec2 vTexCoord;
  void main() {
   gl_Position = aPosition;
   vTexCoord = aTextureCoord.xy;
  }
  )";
        std::string fshContent = R"(
  precision mediump float;
  varying vec2 vTexCoord;
  uniform sampler2D uTexture;
  void main() {
   gl_FragColor = texture2D(uTexture, vTexCoord);
  }
  )";
        _drawProgramRGBA = VnGlRenderProgramPtr(new VnGlRenderProgram(vshContent, fshContent, {"aPosition", "aTextureCoord"}, {"uTexture"}));
    }
    
    if(!_drawProgramBGRA) {
        std::string vshContent = R"(
  attribute vec4 aPosition;
  attribute vec4 aTextureCoord;
  varying lowp vec2 vTexCoord;
  void main() {
   gl_Position = aPosition;
   vTexCoord = aTextureCoord.xy;
  }
  )";
        std::string fshContent = R"(
  precision mediump float;
  varying vec2 vTexCoord;
  uniform sampler2D uTexture;
  void main() {
   gl_FragColor = texture2D(uTexture, vTexCoord).bgra;
  }
  )";
        _drawProgramBGRA = VnGlRenderProgramPtr(new VnGlRenderProgram(vshContent, fshContent, {"aPosition", "aTextureCoord"}, {"uTexture"}));
    }
    
    if(!_drawTextrue) {
        unsigned char *dat = (unsigned char *)calloc(frame.size.width * frame.size.height * 4, sizeof(unsigned char));
        memset(dat, 0xff, frame.size.width * frame.size.height * 4 * sizeof(unsigned char));
        _drawTextrue = VnGlTexturePtr(new VnGlTexture(GL_TEXTURE_2D, GL_RGBA, frame.size.width, frame.size.height, GL_UNSIGNED_BYTE, dat));
        free(dat);
    }
    
    glDisable(GL_DEPTH_TEST);
    
    // Onscreen framebuffer object
    glGenFramebuffers(1, &_viewFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _viewFramebuffer);
    
    glGenRenderbuffers(1, &_viewRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _viewRenderbuffer);
    
    [_glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
    
    if(!_drawBackingSizeTextrue) {
        unsigned char *dat = (unsigned char *)calloc(_backingWidth * _backingHeight * 4, sizeof(unsigned char));
        memset(dat, 0xff, _backingWidth * _backingHeight * 4 * sizeof(unsigned char));
        _drawBackingSizeTextrue = VnGlTexturePtr(new VnGlTexture(GL_TEXTURE_2D, GL_RGBA, _backingWidth, _backingHeight, GL_UNSIGNED_BYTE, dat));
        free(dat);
    }
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _viewRenderbuffer);
    
    if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"UIViewGLDrawer : failure with framebuffer generation");
        return nil;
    }
    
    glGenRenderbuffers(1, &_viewDepthRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _viewDepthRenderbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, _backingWidth, _backingHeight);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _viewDepthRenderbuffer);
    
    // Offscreen render pass framebuffer object
    glGenFramebuffers(1, &_passFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _passFramebuffer);
    glGenRenderbuffers(1, &_passRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _passRenderbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8, _drawTextrue->_width, _drawTextrue->_height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _passRenderbuffer);
    
    return self;
}

- (void)draw_With_YTexture:(VnGlTexturePtr)y UVTexture:(VnGlTexturePtr)uv RotateType:(NSInteger)rotateType FlipType:(NSInteger)FlipType {
    if (!_viewFramebuffer) {
        NSLog(@"_viewFramebuffer is nil.");
        return;
    }
    if (!_glContext) {
        NSLog(@"_glContext is nil.");
        return;
    }
    [EAGLContext setCurrentContext:self.glContext];
    
    if(!_drawCvtRGBATextrue) {
        unsigned char *dat = (unsigned char *)calloc(y->_width * y->_height * 4, sizeof(unsigned char));
        memset(dat, 0xff, y->_width * y->_height * 4 * sizeof(unsigned char));
        _drawCvtRGBATextrue = VnGlTexturePtr(new VnGlTexture(GL_TEXTURE_2D, GL_RGBA, y->_width, y->_height, GL_UNSIGNED_BYTE, dat));
        free(dat);
    } else {
        if (_drawCvtRGBATextrue->_width != y->_width || _drawCvtRGBATextrue->_height != y->_height) {
            unsigned char *dat = (unsigned char *)calloc(y->_width * y->_height * 4, sizeof(unsigned char));
            memset(dat, 0xff, y->_width * y->_height * 4 * sizeof(unsigned char));
            _drawCvtRGBATextrue = VnGlTexturePtr(new VnGlTexture(GL_TEXTURE_2D, GL_RGBA, y->_width, y->_height, GL_UNSIGNED_BYTE, dat));
            free(dat);
        }
    }
    
    _covertYUV2RGBA->Apply(_passFramebuffer, {y.get(), uv.get()}, {_drawCvtRGBATextrue.get()});
    [self draw_With_RGBATexture:_drawCvtRGBATextrue RotateType:rotateType FlipType:FlipType];
}

static const GLfloat squareVertices[] = {
    -1.0f, -1.0f,
    1.0f, -1.0f,
    -1.0f,  1.0f,
    1.0f,  1.0f,
};
/*** for portrait ***/
static const GLfloat textureVertices[] = {
    0.0f, 1.0f,
    1.0f, 1.0f,
    0.0f,  0.0f,
    1.0f,  0.0f,
};

/*** for landscaperight ***/
static const GLfloat textureVertices_right[] = {
    1.0f, 1.0f,
    1.0f, 0.0f,
    0.0f, 1.0f,
    0.0f, 0.0f
};

/*** for landscapeleft ***/
static const GLfloat textureVertices_left[] = {
    0.0f, 0.0f,
    0.0f, 1.0f,
    1.0f, 0.0f,
    1.0f, 1.0f
};

- (void)rotate_With_Texture:(VnGlTexturePtr)inTex RotateType:(NSInteger)rotateType {
    [EAGLContext setCurrentContext:self.glContext];
    if (rotateType == UIView_GLRenderUtils_RotateType_None) {
        _drawRotatedTextrue = inTex;
    }
    else if (rotateType == UIView_GLRenderUtils_RotateType_90L) {
        if(!_drawRotatedTextrue) {
            unsigned char *dat = (unsigned char *)calloc(inTex->_height * inTex->_width * 4, sizeof(unsigned char));
            memset(dat, 0xff, inTex->_height * inTex->_width * 4 * sizeof(unsigned char));
            _drawRotatedTextrue = VnGlTexturePtr(new VnGlTexture(GL_TEXTURE_2D, GL_RGBA, inTex->_height, inTex->_width, GL_UNSIGNED_BYTE, dat));
            free(dat);
        } else {
            if (_drawRotatedTextrue->_width != inTex->_height || _drawRotatedTextrue->_height != inTex->_width) {
                unsigned char *dat = (unsigned char *)calloc(inTex->_width * inTex->_height * 4, sizeof(unsigned char));
                memset(dat, 0xff, inTex->_width * inTex->_height * 4 * sizeof(unsigned char));
                _drawRotatedTextrue = VnGlTexturePtr(new VnGlTexture(GL_TEXTURE_2D, GL_RGBA, inTex->_height, inTex->_width, GL_UNSIGNED_BYTE, dat));
                free(dat);
            }
        }
        _rotate90LDrawer->Apply(_passFramebuffer, {inTex.get()}, {_drawRotatedTextrue.get()});
    }
    else if (rotateType == UIView_GLRenderUtils_RotateType_90R) {
        if(!_drawRotatedTextrue) {
            unsigned char *dat = (unsigned char *)calloc(inTex->_height * inTex->_width * 4, sizeof(unsigned char));
            memset(dat, 0xff, inTex->_height * inTex->_width * 4 * sizeof(unsigned char));
            _drawRotatedTextrue = VnGlTexturePtr(new VnGlTexture(GL_TEXTURE_2D, GL_RGBA, inTex->_height, inTex->_width, GL_UNSIGNED_BYTE, dat));
            free(dat);
        } else {
            if (_drawRotatedTextrue->_width != inTex->_height || _drawRotatedTextrue->_height != inTex->_width) {
                unsigned char *dat = (unsigned char *)calloc(inTex->_width * inTex->_height * 4, sizeof(unsigned char));
                memset(dat, 0xff, inTex->_width * inTex->_height * 4 * sizeof(unsigned char));
                _drawRotatedTextrue = VnGlTexturePtr(new VnGlTexture(GL_TEXTURE_2D, GL_RGBA, inTex->_height, inTex->_width, GL_UNSIGNED_BYTE, dat));
                free(dat);
            }
        }
        _rotate90RDrawer->Apply(_passFramebuffer, {inTex.get()}, {_drawRotatedTextrue.get()});
    }
    else if (rotateType == UIView_GLRenderUtils_RotateType_180) {
        if(!_drawRotatedTextrue) {
            unsigned char *dat = (unsigned char *)calloc(inTex->_height * inTex->_width * 4, sizeof(unsigned char));
            memset(dat, 0xff, inTex->_height * inTex->_width * 4 * sizeof(unsigned char));
            _drawRotatedTextrue = VnGlTexturePtr(new VnGlTexture(GL_TEXTURE_2D, GL_RGBA, inTex->_width, inTex->_height, GL_UNSIGNED_BYTE, dat));
            free(dat);
        } else {
            if (_drawRotatedTextrue->_height != inTex->_height || _drawRotatedTextrue->_width != inTex->_width) {
                unsigned char *dat = (unsigned char *)calloc(inTex->_width * inTex->_height * 4, sizeof(unsigned char));
                memset(dat, 0xff, inTex->_width * inTex->_height * 4 * sizeof(unsigned char));
                _drawRotatedTextrue = VnGlTexturePtr(new VnGlTexture(GL_TEXTURE_2D, GL_RGBA, inTex->_width, inTex->_height, GL_UNSIGNED_BYTE, dat));
                free(dat);
            }
        }
        _rotate180Drawer->Apply(_passFramebuffer, {inTex.get()}, {_drawRotatedTextrue.get()});
    }
    
}

- (void)flip_With_Texture:(VnGlTexturePtr)inTex FlipType:(NSInteger)flipType {
    [EAGLContext setCurrentContext:self.glContext];
    if (flipType == UIView_GLRenderUtils_FlipType_None) {
        _drawFlippedTextrue = inTex;
    }
    else if (flipType == UIView_GLRenderUtils_FlipType_Horizontal) {
        
        if(!_drawFlippedTextrue) {
            unsigned char *dat = (unsigned char *)calloc(inTex->_height * inTex->_width * 4, sizeof(unsigned char));
            memset(dat, 0xff, inTex->_height * inTex->_width * 4 * sizeof(unsigned char));
            _drawFlippedTextrue = VnGlTexturePtr(new VnGlTexture(GL_TEXTURE_2D, GL_RGBA, inTex->_width, inTex->_height, GL_UNSIGNED_BYTE, dat));
            free(dat);
        } else {
            if (_drawFlippedTextrue->_height != inTex->_height || _drawFlippedTextrue->_width != inTex->_width) {
                unsigned char *dat = (unsigned char *)calloc(inTex->_width * inTex->_height * 4, sizeof(unsigned char));
                memset(dat, 0xff, inTex->_width * inTex->_height * 4 * sizeof(unsigned char));
                _drawFlippedTextrue = VnGlTexturePtr(new VnGlTexture(GL_TEXTURE_2D, GL_RGBA, inTex->_width, inTex->_height, GL_UNSIGNED_BYTE, dat));
                free(dat);
            }
        }
        
        _hFlipDrawer->Apply(_passFramebuffer, {inTex.get()}, {_drawFlippedTextrue.get()});
    }
    else if (flipType == UIView_GLRenderUtils_FlipType_Vertical) {
        
        if(!_drawFlippedTextrue) {
            unsigned char *dat = (unsigned char *)calloc(inTex->_height * inTex->_width * 4, sizeof(unsigned char));
            memset(dat, 0xff, inTex->_height * inTex->_width * 4 * sizeof(unsigned char));
            _drawFlippedTextrue = VnGlTexturePtr(new VnGlTexture(GL_TEXTURE_2D, GL_RGBA, inTex->_width, inTex->_height, GL_UNSIGNED_BYTE, dat));
            free(dat);
        } else {
            if (_drawFlippedTextrue->_height != inTex->_height || _drawFlippedTextrue->_width != inTex->_width) {
                unsigned char *dat = (unsigned char *)calloc(inTex->_width * inTex->_height * 4, sizeof(unsigned char));
                memset(dat, 0xff, inTex->_width * inTex->_height * 4 * sizeof(unsigned char));
                _drawFlippedTextrue = VnGlTexturePtr(new VnGlTexture(GL_TEXTURE_2D, GL_RGBA, inTex->_width, inTex->_height, GL_UNSIGNED_BYTE, dat));
                free(dat);
            }
        }
        
        _vFlipDrawer->Apply(_passFramebuffer, {inTex.get()}, {_drawFlippedTextrue.get()});
    }
}

- (void)draw_With_BGRATexture:(VnGlTexturePtr)bgra RotateType:(NSInteger)rotateType FlipType:(NSInteger)flipType {
    [self rotate_With_Texture:bgra RotateType:rotateType];
    [self flip_With_Texture:_drawRotatedTextrue FlipType:flipType];
    
    [EAGLContext setCurrentContext:self.glContext];
    _rectsDrawer->Apply(_passFramebuffer, {}, {_drawFlippedTextrue.get()});
    _linesDrawer->Apply(_passFramebuffer, {}, {_drawFlippedTextrue.get()});
    _circlesDrawer->Apply(_passFramebuffer, {}, {_drawFlippedTextrue.get()});
    _pointsDrawer->Apply(_passFramebuffer, {}, {_drawFlippedTextrue.get()});
    glBindFramebuffer(GL_FRAMEBUFFER, _viewFramebuffer);
    glViewport(0, 0, _backingWidth, _backingHeight);
    glClear(GL_COLOR_BUFFER_BIT);
    _drawProgramBGRA->Use();
    _drawProgramBGRA->ActivateBindTextureToUniformLocation(0, _drawFlippedTextrue.get(), "uTexture");
    _drawProgramBGRA->VertexAttribPointerAndEnable("aPosition", 2, GL_FLOAT, 0, 0, squareVertices);
    _drawProgramBGRA->VertexAttribPointerAndEnable("aTextureCoord", 2, GL_FLOAT, 0, 0, textureVertices);
    _drawProgramBGRA->DrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    _drawProgramBGRA->VertexAttribDisable("aPosition");
    _drawProgramBGRA->VertexAttribDisable("aTextureCoord");
    
    // Render
    BOOL isSuccess = NO;
    if (_glContext) {
        glBindRenderbuffer(GL_RENDERBUFFER, _viewRenderbuffer);
        isSuccess = [_glContext presentRenderbuffer:GL_RENDERBUFFER];
        if (!isSuccess) {
            NSLog(@"Error in %s(%d), presentRenderbuffer is failed.\n", __FUNCTION__, __LINE__);
            return;
        }
        glFlush();
    } else {
        NSLog(@"Error in %s(%d), EAGLContext is nil.\n", __FUNCTION__, __LINE__);
        return;
    }
}

- (void)draw_With_RGBATexture:(VnGlTexturePtr)rgba RotateType:(NSInteger)rotateType FlipType:(NSInteger)flipType {
    [self rotate_With_Texture:rgba RotateType:rotateType];
    [self flip_With_Texture:_drawRotatedTextrue FlipType:flipType];
    
    [EAGLContext setCurrentContext:self.glContext];
    _rectsDrawer->Apply(_passFramebuffer, {}, {_drawFlippedTextrue.get()});
    _linesDrawer->Apply(_passFramebuffer, {}, {_drawFlippedTextrue.get()});
    _circlesDrawer->Apply(_passFramebuffer, {}, {_drawFlippedTextrue.get()});
    _pointsDrawer->Apply(_passFramebuffer, {}, {_drawFlippedTextrue.get()});
    glBindFramebuffer(GL_FRAMEBUFFER, _viewFramebuffer);
    glViewport(0, 0, _backingWidth, _backingHeight);
    glClear(GL_COLOR_BUFFER_BIT);
    _drawProgramRGBA->Use();
    _drawProgramRGBA->ActivateBindTextureToUniformLocation(0, _drawFlippedTextrue.get(), "uTexture");
    _drawProgramRGBA->VertexAttribPointerAndEnable("aPosition", 2, GL_FLOAT, 0, 0, squareVertices);
    _drawProgramRGBA->VertexAttribPointerAndEnable("aTextureCoord", 2, GL_FLOAT, 0, 0, textureVertices);
    _drawProgramRGBA->DrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    _drawProgramRGBA->VertexAttribDisable("aPosition");
    _drawProgramRGBA->VertexAttribDisable("aTextureCoord");
    
    // Render
    BOOL isSuccess = NO;
    if (_glContext) {
        glBindRenderbuffer(GL_RENDERBUFFER, _viewRenderbuffer);
        isSuccess = [_glContext presentRenderbuffer:GL_RENDERBUFFER];
        if (!isSuccess) {
            NSLog(@"Error in %s(%d), presentRenderbuffer is failed.\n", __FUNCTION__, __LINE__);
            return;
        }
        glFlush();
    } else {
        NSLog(@"Error in %s(%d), EAGLContext is nil.\n", __FUNCTION__, __LINE__);
        return;
    }
}

@end
