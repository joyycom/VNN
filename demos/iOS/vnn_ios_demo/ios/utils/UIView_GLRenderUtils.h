//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import <UIKit/UIKit.h>
#import <memory>
#import "renderer.h"

using namespace vnn::renderkit;


#define UIView_GLRenderUtils_RotateType_None 0x00
#define UIView_GLRenderUtils_RotateType_90R  0x01
#define UIView_GLRenderUtils_RotateType_90L  0x02
#define UIView_GLRenderUtils_RotateType_180  0x04

#define UIView_GLRenderUtils_FlipType_None 			0x00
#define UIView_GLRenderUtils_FlipType_Horizontal  	0x10
#define UIView_GLRenderUtils_FlipType_Vertical  	0x20


@interface UIView_GLRenderUtils : UIView

/* render frame objects */
@property (nonatomic, strong) EAGLContext *glContext;
@property (nonatomic, assign) VnGlTexturePtr drawTextrue;
@property (nonatomic, assign) VnGlTexturePtr drawCvtRGBATextrue;
@property (nonatomic, assign) VnGlTexturePtr drawRotatedTextrue;
@property (nonatomic, assign) VnGlTexturePtr drawFlippedTextrue;
@property (nonatomic, assign) VnGlTexturePtr drawBackingSizeTextrue;
@property (nonatomic, assign) VnGlRenderProgramPtr drawProgramRGBA;
@property (nonatomic, assign) VnGlRenderProgramPtr drawProgramBGRA;
@property (nonatomic, assign) VnGlYuv2RgbaPtr covertYUV2RGBA;
@property (nonatomic, assign) VnGlCirclesDrawerPtr circlesDrawer;
@property (nonatomic, assign) VnGlPointsDrawerPtr pointsDrawer;
@property (nonatomic, assign) VnGlLinesDrawerPtr linesDrawer;
@property (nonatomic, assign) VnGlRectsDrawerPtr rectsDrawer;
@property (nonatomic, assign) VnGlImagesDrawerPtr imagesDrawer;

@property (nonatomic, assign) VnGlRotate90LPtr rotate90LDrawer;
@property (nonatomic, assign) VnGlRotate90RPtr rotate90RDrawer;
@property (nonatomic, assign) VnGlRotate180Ptr rotate180Drawer;

@property (nonatomic, assign) VnGlHFlipPtr hFlipDrawer;
@property (nonatomic, assign) VnGlVFlipPtr vFlipDrawer;

/* The pixel dimensions of the backbuffer */
@property (nonatomic, assign) GLint backingWidth;
@property (nonatomic, assign) GLint backingHeight;

/* OpenGL names for the renderbuffer and framebuffers used to render to this view */
@property (nonatomic, assign) GLuint viewFramebuffer;
@property (nonatomic, assign) GLuint viewRenderbuffer;
@property (nonatomic, assign) GLuint viewDepthRenderbuffer;
@property (nonatomic, assign) GLuint passRenderbuffer;
@property (nonatomic, assign) GLuint passFramebuffer;

- (instancetype)init_With_Frame:(CGRect)frame EAGLContext:(EAGLContext *)context;
- (void)draw_With_YTexture:(VnGlTexturePtr)y UVTexture:(VnGlTexturePtr)uv RotateType:(NSInteger)rotateType FlipType:(NSInteger)flipType;
- (void)draw_With_BGRATexture:(VnGlTexturePtr)bgra RotateType:(NSInteger)rotateType FlipType:(NSInteger)flipType;
- (void)draw_With_RGBATexture:(VnGlTexturePtr)rgba RotateType:(NSInteger)rotateType FlipType:(NSInteger)flipType;

@end
