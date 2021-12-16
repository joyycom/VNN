//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "ViewCtrl_Camera_GLRenderBase.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface ViewCtrl_GLRenderBase ()

@end

@implementation ViewCtrl_GLRenderBase

- (UIModalPresentationStyle)modalPresentationStyle {
    return UIModalPresentationFullScreen;
}

- (void)dealloc {
    if (_cvGlTextureCache) {
        CFRelease(_cvGlTextureCache);
    }
}

- (void)loadView {
    [super loadView];
    [self.view setBackgroundColor:UIColorFromRGB(0x292a2f)];
    [self setup_gl];
    [self.view addSubview:self.glUtils];
    [self.view addSubview:self.btnCapture];
    [self.view addSubview:self.btnSwitchCam];
    [self.view addSubview:self.btnBack];
    _sum_cpu_usage = 0;
    _prev_time = 0;
    _times = 0;
    _cameraOrientation = AVCaptureVideoOrientationPortrait;
    _cameraPosition = AVCaptureDevicePositionFront;
    _cameraPixelFormatType = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self motionManagerStartUpdateAccelerometerResult];
    [self setupCameraSession_With_Orientation:_cameraOrientation
                      AVCaptureDevicePosition:_cameraPosition
                         VideoPixelFormatType:_cameraPixelFormatType];
    [_captureSession startRunning];
}

- (CMMotionManager *)motionManager {
    if (_motionManager == nil) {
        _motionManager = [[CMMotionManager alloc] init];
    }
    return _motionManager;
}

- (void)motionManagerStopUpdate {
    if ([self.motionManager isAccelerometerActive] == YES) {
        [self.motionManager stopAccelerometerUpdates];
    }
}

- (void)motionManagerStartUpdateAccelerometerResult{
    if ([self.motionManager isAccelerometerAvailable] == YES) {
        [self.motionManager setAccelerometerUpdateInterval:0.05];
        [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                                 withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
            self.motionAcceleration = accelerometerData.acceleration;
        }];
    }
}

- (void)setup_gl {
    self.glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
#if COREVIDEO_USE_EAGLCONTEXT_CLASS_IN_API
    CVReturn ret = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.glContext, NULL, &_cvGlTextureCache);
#else
    CVReturn ret = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (__bridge void *)self.glContext, NULL, &_cvGlTextureCache);
#endif
    if (ret) {
        printf("Error(%d) at CVOpenGLESTextureCacheCreate.\n", ret);
    }
    _glTexLoader = [[GLKTextureLoader alloc] initWithSharegroup:self.glContext.sharegroup];
}

- (void)setupCameraSession_With_Orientation:(AVCaptureVideoOrientation) orientation
                    AVCaptureDevicePosition:(AVCaptureDevicePosition) position
                       VideoPixelFormatType:(int)kCVPixelFormatType {
    NSError *error = nil;
    _captureSession = [[AVCaptureSession alloc] init];//负责输入和输出设置之间的数据传递
    if (ACTUAL_SCREEN_HEIGHT == 480) {
        _captureSession.sessionPreset = AVCaptureSessionPreset640x480;//设置分辨率
    }
    else {
        _captureSession.sessionPreset = AVCaptureSessionPreset1280x720;//设置分辨率
    }
    _captureDevice = [self cameraDeviceWithPosition:position];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:_captureDevice error:&error];
    if ([_captureSession canAddInput:input]) {
        [_captureSession addInput:input];
    }
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];//创建一个视频数据输出流
    [_captureSession addOutput:output];
    _captureConnection = [output connectionWithMediaType:AVMediaTypeVideo];
    
    if ([_captureDevice position] == AVCaptureDevicePositionFront) {
        [_captureConnection setVideoMirrored:true];
    }
    [_captureConnection setVideoOrientation:orientation];
    [output setAlwaysDiscardsLateVideoFrames:YES]; // Probably want to set this to NO when recording
    [output setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    dispatch_queue_t bufferQueue = dispatch_queue_create("cameraDataOutputQueue", NULL); // dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0); //
    self.cameraDataOutputQueue = bufferQueue;
    [output setSampleBufferDelegate:self queue:_cameraDataOutputQueue];
    if (ACTUAL_SCREEN_HEIGHT != 480) {
        [_captureSession beginConfiguration];
        _captureDevice.activeVideoMinFrameDuration = CMTimeMake(1, 25);
        _captureDevice.activeVideoMaxFrameDuration = CMTimeMake(1, 25);
        [_captureSession commitConfiguration];
    }
}

- (AVCaptureDevice *)cameraDeviceWithPosition:(AVCaptureDevicePosition)position {
    AVCaptureDevice *deviceRet = nil;
    if (position != AVCaptureDevicePositionUnspecified) {
        NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for (AVCaptureDevice *device in devices) {
            if ([device position] == position) {
                deviceRet = device;
            }
        }
    }
    return deviceRet;
}

- (UIButton *)btnBack {
    if (!_btnBack) {
        _btnBack = [UIButton buttonWithType:UIButtonTypeCustom];
        [_btnBack setFrame:CGRectMake((ACTUAL_SCREEN_WIDTH  - SCREEN_WIDTH) / 2 + SCREEN_WIDTH  * 0.1 / 9.0,
                                      (ACTUAL_SCREEN_HEIGHT - SCREEN_HEIGHT) / 2 + SCREEN_HEIGHT * 0.5 / 16.0 ,
                                      SCREEN_WIDTH  * 0.8 / 9.0,
                                      SCREEN_HEIGHT * 0.8 / 16.0
                                      )];
        [_btnBack setBackgroundColor:[UIColor clearColor]];
        [_btnBack setImage:[UIImage imageWithContentsOfFile:[[[[[NSBundle mainBundle] bundlePath]
                                                               stringByAppendingPathComponent:@"ui"]
                                                              stringByAppendingPathComponent:@"ViewCtrl_GLRenderBase"]
                                                             stringByAppendingPathComponent:@"btnBack.png"]]
                  forState:UIControlStateNormal];
        [_btnBack addTarget:self action:@selector(onBtnBack) forControlEvents:UIControlEventTouchUpInside];
    }
    return _btnBack;
}
- (void)onBtnBack { //first release resource in this view
    NSError *error;
    if ([self.captureDevice lockForConfiguration:&error]) {
        if ([self.captureDevice isExposureModeSupported:AVCaptureExposureModeLocked]) {
            [self.captureDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        }
        [self.captureDevice unlockForConfiguration];
    }
    [_captureSession stopRunning];
    glFinish();
    [self dismissViewControllerAnimated:YES completion:^{ NSLog(@"Back to main View."); }];
}

- (UIButton *)btnSwitchCam {
    if (!_btnSwitchCam) {
        _btnSwitchCam = [UIButton buttonWithType:UIButtonTypeCustom];
        [_btnSwitchCam setFrame:CGRectMake((ACTUAL_SCREEN_WIDTH  - SCREEN_WIDTH) / 2 + SCREEN_WIDTH  * 7.5 / 9.0,
                                           (ACTUAL_SCREEN_HEIGHT - SCREEN_HEIGHT) / 2 + SCREEN_HEIGHT * 0.5 / 16.0 ,
                                           SCREEN_WIDTH  * 0.8 / 9.0,
                                           SCREEN_HEIGHT * 0.8 / 16.0)];
        [_btnSwitchCam setBackgroundColor:[UIColor clearColor]];
        [_btnSwitchCam setImage:[UIImage imageWithContentsOfFile:[[[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"ui"] stringByAppendingPathComponent:@"ViewCtrl_GLRenderBase"] stringByAppendingPathComponent:@"btnSwitchCam.png"]]
                       forState:UIControlStateNormal];
        [_btnSwitchCam addTarget:self action:@selector(onBtnSwitchCam) forControlEvents:UIControlEventTouchUpInside];
    }
    return _btnSwitchCam;
}
- (void)onBtnSwitchCam {
    //first release resource in this view
    [_captureSession stopRunning];
    _cameraPosition = _cameraPosition == AVCaptureDevicePositionFront? AVCaptureDevicePositionBack : AVCaptureDevicePositionFront;
    [self setupCameraSession_With_Orientation:_cameraOrientation
                      AVCaptureDevicePosition:_cameraPosition
                         VideoPixelFormatType:_cameraPixelFormatType];
    [_captureSession startRunning];
}

- (UISwitch *)switchShow {
    if (!_switchShow) {
        _switchShow = [[UISwitch alloc] initWithFrame:CGRectMake(
                                                                 (ACTUAL_SCREEN_WIDTH  - SCREEN_WIDTH) / 2 + SCREEN_WIDTH  * 7.5 / 9.0,
                                                                 (ACTUAL_SCREEN_HEIGHT - SCREEN_HEIGHT) / 2 + SCREEN_HEIGHT * 15  / 16.0,
                                                                 SCREEN_WIDTH  / 9.0,
                                                                 SCREEN_HEIGHT / 16.0
                                                                 )];
        [_switchShow setOn:NO];
        [_switchShow addTarget:self action:@selector(onSwitchShow) forControlEvents:UIControlEventValueChanged];
        [self onSwitchShow];
    }
    return _switchShow;
}
- (void)onSwitchShow {
    [self.btnCapture setHidden:![self.switchShow isOn]];
    [self.btnSwitchCam setHidden:![self.switchShow isOn]];
    [self.btnSwitchCamOrientation setHidden:![self.switchShow isOn]];
}

- (UIView_GLRenderUtils *)glUtils {
    if (!_glUtils) {
        _glUtils = [[UIView_GLRenderUtils alloc] init_With_Frame:CGRectMake((ACTUAL_SCREEN_WIDTH - SCREEN_WIDTH) / 2,
                                                                            (ACTUAL_SCREEN_HEIGHT - SCREEN_HEIGHT) / 2,
                                                                            SCREEN_WIDTH,
                                                                            SCREEN_HEIGHT)
                                                     EAGLContext:self.glContext];
    }
    return _glUtils;
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    _devOriention = [UIDevice currentDevice].orientation;
    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer); // YCbCr or RGBA
    CFRetain(pixelBuffer);
    size_t planeCount = CVPixelBufferGetPlaneCount(pixelBuffer);
    
    //check if _cvGlTextureCache is nil
    if (!_cvGlTextureCache) {
        NSLog(@"No video texture cache");
        return;
    }
    
    //clean up textures
    if (_gltexture_Y) {
        CFRelease(_gltexture_Y);
        _gltexture_Y = NULL;
    }
    if (_gltexture_CbCr) {
        CFRelease(_gltexture_CbCr);
        _gltexture_CbCr = NULL;
    }
    if (_gltexture_BGRA) {
        CFRelease(_gltexture_BGRA);
        _gltexture_BGRA = NULL;
    }
    
    if (!_NSYTex) {
        _NSYTex = std::make_shared<VnGlTexture>();
    }
    if (!_NSUVTex) {
        _NSUVTex = std::make_shared<VnGlTexture>();
    }
    if (!_NSBGRATex) {
        _NSBGRATex = std::make_shared<VnGlTexture>();
    }
    
    if (planeCount != 0){
        if (_NSYTex) {//Y-Plane
            glActiveTexture(GL_TEXTURE0);
            size_t width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
            size_t height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
            CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                        _cvGlTextureCache,
                                                                        pixelBuffer,
                                                                        NULL,
                                                                        GL_TEXTURE_2D,
                                                                        GL_LUMINANCE,
                                                                        (GLsizei)width,
                                                                        (GLsizei)height,
                                                                        GL_LUMINANCE,
                                                                        GL_UNSIGNED_BYTE,
                                                                        0,
                                                                        &_gltexture_Y);
            
            if (err) {
                printf("CVOpenGLESTextureCacheCreateTextureFromImage failed. err(%d).\n", err);
                return;
            }
            glBindTexture(CVOpenGLESTextureGetTarget(_gltexture_Y), CVOpenGLESTextureGetName(_gltexture_Y));
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            _NSYTex->_width = (int)width;
            _NSYTex->_height = (int)height;
            _NSYTex->_target = GL_TEXTURE_2D;
            _NSYTex->_format = GL_LUMINANCE;
            _NSYTex->_handle = CVOpenGLESTextureGetName(_gltexture_Y);
        }
        if (_NSUVTex) { //CbCr-Plane
            glActiveTexture(GL_TEXTURE1);
            size_t width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1);
            size_t height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1);
            CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                        _cvGlTextureCache,
                                                                        pixelBuffer,
                                                                        NULL,
                                                                        GL_TEXTURE_2D,
                                                                        GL_LUMINANCE_ALPHA,
                                                                        (GLsizei)width,
                                                                        (GLsizei)height,
                                                                        GL_LUMINANCE_ALPHA,
                                                                        GL_UNSIGNED_BYTE,
                                                                        1,
                                                                        &_gltexture_CbCr);
            if (err) {
                printf("CVOpenGLESTextureCacheCreateTextureFromImage failed. err(%d).\n", err);
                return;
            }
            glBindTexture(CVOpenGLESTextureGetTarget(_gltexture_CbCr), CVOpenGLESTextureGetName(_gltexture_CbCr));
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            _NSUVTex->_width = (int)width;
            _NSUVTex->_height = (int)height;
            _NSUVTex->_target = GL_TEXTURE_2D;
            _NSUVTex->_format = GL_LUMINANCE_ALPHA;
            _NSUVTex->_handle = CVOpenGLESTextureGetName(_gltexture_CbCr);
        }
    }
    else {
        size_t width = CVPixelBufferGetWidth(pixelBuffer);
        size_t height = CVPixelBufferGetHeight(pixelBuffer);
        CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                    _cvGlTextureCache,
                                                                    pixelBuffer,
                                                                    NULL,
                                                                    GL_TEXTURE_2D,
                                                                    GL_RGBA,
                                                                    (GLsizei)width,
                                                                    (GLsizei)height,
                                                                    GL_RGBA,
                                                                    GL_UNSIGNED_BYTE,
                                                                    0,
                                                                    &_gltexture_BGRA);
        
        if (err) {
            printf("CVOpenGLESTextureCacheCreate failed. err(%d).\n", err);
        }
        glBindTexture(CVOpenGLESTextureGetTarget(_gltexture_BGRA), CVOpenGLESTextureGetName(_gltexture_BGRA));
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        _NSBGRATex->_target = GL_TEXTURE_2D;
        _NSBGRATex->_format = GL_RGBA;
        _NSBGRATex->_width = (int)width;
        _NSBGRATex->_height = (int)height;
        _NSBGRATex->_handle = CVOpenGLESTextureGetName(_gltexture_BGRA);
    }
    
    double t = CACurrentMediaTime();
    @autoreleasepool {
        [self videoCaptureCallback:pixelBuffer];
    }
    printf("videoCaptureCallback cost: %.1f ms\n", 1000 * (CACurrentMediaTime() - t));
    
    if ([NSStringFromClass(self.class) isEqualToString:@"ViewCtrl_GLRenderBase"]) {
        NSInteger rotateType = 0;
        NSInteger flipType = 0;
        if (self.cameraOrientation == AVCaptureVideoOrientationLandscapeRight) {
            rotateType = UIView_GLRenderUtils_RotateType_90R;
        }
        if (self.cameraOrientation == AVCaptureVideoOrientationLandscapeLeft) {
            rotateType = UIView_GLRenderUtils_RotateType_90L;
        }
        if (CVPixelBufferGetPlaneCount(pixelBuffer) != 0){
            [self.glUtils draw_With_YTexture:self.NSYTex UVTexture:self.NSUVTex RotateType:(NSInteger)rotateType FlipType:(NSInteger)flipType];
        } else {
            [self.glUtils draw_With_BGRATexture:self.NSBGRATex RotateType:(NSInteger)rotateType FlipType:(NSInteger)flipType];
        }
    }
    
    CFRelease(pixelBuffer);
    
    printf("Rendering Fps: %.1f\n", 1.0 / (CACurrentMediaTime() - _prev_time));
    _prev_time = CACurrentMediaTime();
    printf("CPU usage: %.1f %%\n", [DemoHelper getCpuUsage]);
    _times++;
    _sum_cpu_usage += [DemoHelper getCpuUsage];
    printf("Frame Count: %d\tAverage CPU usage: %.1f %%\n", _times, _sum_cpu_usage / _times);
}

- (void)videoCaptureCallback:(CVPixelBufferRef)pixelBuffer {
    
}

- (void)setNoticewithTitle:(NSString *)title Massage:(NSString *)massage{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:massage
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
