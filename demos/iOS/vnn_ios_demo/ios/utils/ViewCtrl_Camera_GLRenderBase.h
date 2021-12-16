//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "ViewCtrl_Camera_GLRenderBase.h"
#import <AVFoundation/AVFoundation.h>
#import <MetalKit/MetalKit.h>
#import <GLKit/GLKit.h>
#import <CoreMotion/CoreMotion.h>
#import "DemoHelper.h"
#import "UIView_GLRenderUtils.h"

@interface ViewCtrl_GLRenderBase : UIViewController < AVCaptureVideoDataOutputSampleBufferDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate >

#pragma mark CMMotionManager
@property (nonatomic, strong) CMMotionManager * motionManager;
@property (nonatomic, assign) CMAcceleration    motionAcceleration;

#pragma mark UI Controllers Properties
@property (nonatomic, strong) UIButton * _Nullable btnBack;
@property (nonatomic, strong) UIButton * _Nullable btnSwitchCam;
@property (nonatomic, strong) UIButton * _Nullable btnSwitchCamOrientation;
@property (nonatomic, strong) UISwitch * _Nullable switchShow;
@property (nonatomic, strong) UIButton * _Nullable btnCapture;
@property (nonatomic, strong) UIButton * _Nullable btnSaveVideo;
@property (nonatomic, strong) UIButton * _Nullable btnContinueCameraCapture;
@property (nonatomic, assign) UIDeviceOrientation devOriention;

#pragma mark Camera Properties
@property (nonatomic, assign) dispatch_queue_t _Nullable sessionQueue;
@property (nonatomic, assign) dispatch_queue_t _Nullable cameraDataOutputQueue;
@property (nonatomic, assign) dispatch_queue_t _Nullable videoDataOutputQueue;
@property (nonatomic, assign) AVCaptureVideoOrientation cameraOrientation;
@property (nonatomic, assign) AVCaptureDevicePosition cameraPosition;
@property (nonatomic, assign) int cameraPixelFormatType;
@property (nonatomic, strong) AVCaptureDevice * _Nullable captureDevice;
@property (nonatomic, strong) AVCaptureConnection * _Nullable  captureConnection;
@property (nonatomic, strong) AVCaptureSession * _Nullable captureSession;

#pragma mark OpenGL ES Properties
@property (nonatomic, assign) CVOpenGLESTextureRef _Nullable gltexture_Y;
@property (nonatomic, assign) CVOpenGLESTextureRef _Nullable gltexture_CbCr;
@property (nonatomic, assign) CVOpenGLESTextureRef _Nullable gltexture_BGRA;
@property (nonatomic, assign) CVOpenGLESTextureCacheRef _Nullable cvGlTextureCache;
@property (nonatomic, strong) EAGLContext * _Nullable glContext;
@property (nonatomic, strong) GLKTextureLoader * _Nullable glTexLoader;

#pragma mark GL Render Properties
@property (nonatomic, strong) UIView_GLRenderUtils * _Nullable glUtils;
@property (nonatomic, assign) VnGlTexturePtr NSYTex;
@property (nonatomic, assign) VnGlTexturePtr NSUVTex;
@property (nonatomic, assign) VnGlTexturePtr NSBGRATex;

#pragma mark Fps & CPU Usage
@property (nonatomic, assign) double prev_time;
@property (nonatomic, assign) double sum_cpu_usage;
@property (nonatomic, assign) int times;

- (void)setupCameraSession_With_Orientation:(AVCaptureVideoOrientation) orientation AVCaptureDevicePosition:(AVCaptureDevicePosition) position VideoPixelFormatType:(int)kCVPixelFormatType;
- (void)captureOutput:(AVCaptureOutput * _Nullable )output didOutputSampleBuffer:(CMSampleBufferRef _Nullable)sampleBuffer fromConnection:(AVCaptureConnection * _Nullable )connection;
- (void)videoCaptureCallback:(CVPixelBufferRef _Nullable)pixelBuffer;
- (void)setNoticewithTitle:(NSString *)title Massage:(NSString *)massage;
- (void)onBtnBack;
- (void)onSwitchShow;
- (void)onBtnSwitchCam;

@end


