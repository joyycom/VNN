//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "ViewCtrl_Picture_GLRenderBase.h"
#import <AVFoundation/AVFoundation.h>
#import <MetalKit/MetalKit.h>
#import <GLKit/GLKit.h>
#import <CoreMotion/CoreMotion.h>
#import "DemoHelper.h"
#import "UIView_GLRenderUtils.h"

@interface ViewCtrl_Picture_GLRenderBase : UIViewController < AVCaptureVideoDataOutputSampleBufferDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate >

#pragma mark CMMotionManager

#pragma mark UI Controllers Properties
@property (nonatomic, strong) UIButton * _Nullable btnBack;
@property (nonatomic, strong) UIButton * _Nullable btnCapture;

#pragma mark Camera Properties

#pragma mark OpenGL ES Properties
//@property (nonatomic, assign) CVOpenGLESTextureRef _Nullable gltexture_Y;
//@property (nonatomic, assign) CVOpenGLESTextureRef _Nullable gltexture_CbCr;
@property (nonatomic, assign) CVOpenGLESTextureRef _Nullable gltexture_BGRA;
@property (nonatomic, assign) CVOpenGLESTextureCacheRef _Nullable cvGlTextureCache;
@property (nonatomic, strong) EAGLContext * _Nullable glContext;
@property (nonatomic, strong) GLKTextureLoader * _Nullable glTexLoader;

#pragma mark GL Render Properties
@property (nonatomic, strong) UIView_GLRenderUtils * _Nullable glUtils;
@property (nonatomic, assign) bool supportVideoImporting;
@property (nonatomic, assign) VnGlTexturePtr NSYTex;
@property (nonatomic, assign) VnGlTexturePtr NSUVTex;
@property (nonatomic, assign) VnGlTexturePtr NSBGRATex;
@property (nonatomic, assign) CVPixelBufferRef imageBuffer;

#pragma mark Fps & CPU Usage

- (void)videoCaptureCallback:(NSURL *)videoURL;
- (void)imageCaptureCallback:(CVPixelBufferRef _Nonnull )pixelBuffer;
- (void)initWithCVPixelBufferRef:(CVPixelBufferRef)pixelBuffer;
- (void)onBtnBack;
- (void)onBtnCapture;
- (void)setNoticewithTitle:(NSString *)title Massage:(NSString *)massage;

@end


