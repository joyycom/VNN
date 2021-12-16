//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "WindowCtrl_CameraMetalRender.h"

@implementation ViewCtrl_CameraMetalRender
- (instancetype)initWithNibName:(NSNibName)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 1280, 720)];
    return [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}
@end

@implementation WindowCtrl_CameraMetalRender

- (instancetype)initWithRootViewController:(NSViewController *)rootViewController {
    self = [super init];
    if (self) {
        self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 1280, 720) styleMask:(NSWindowStyleMaskTitled) backing:(NSBackingStoreBuffered) defer:YES];
        [self.window setWindowController:self];
        [self.window setMovableByWindowBackground:NO];
        [self.window setStyleMask:NSClosableWindowMask|NSTitledWindowMask];
        [[self.window standardWindowButton:NSWindowZoomButton] setHidden:YES];
        [[self.window standardWindowButton:NSWindowMiniaturizeButton] setHidden:YES];
        [self.window setReleasedWhenClosed:NO];
        self.contentViewController = rootViewController;
    }
    [self.window.contentView addSubview:self.mtkView];
    [self.window.sheetParent endSheet:self.window];
    [self setupAVCap];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowShouldClose:)
                                                 name:NSWindowWillCloseNotification
                                               object:nil];
    return self;
}

- (void)windowShouldClose:(NSNotification *)notification {
    [self.captureSession stopRunning];
    self.mtkView = nil;
    self.captureDevice = nil;
    self.captureConnection = nil;
    self.captureSession = nil;
    self.window = nil;
    self.contentViewController = nil;
}

- (MTKViewX *)mtkView {
    if (!_mtkView) {
        _mtkView = [[MTKViewX alloc] initWithFrame:CGRectMake(0, 0, 1280, 720) device:MTLCreateSystemDefaultDevice()];
        [_mtkView setPaused:YES];
        [_mtkView setNeedsDisplay:NO];
        [_mtkView setAutoResizeDrawable:YES];
        [_mtkView setDrawableSize:CGSizeMake(1280, 720)];
        [_mtkView setMirror:true];
    }
    return _mtkView;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    // Do view setup here.
    
}

- (void)setupAVCap {
    NSError *error = nil;
    if (!_captureSession) {
        _captureSession = [[AVCaptureSession alloc] init]; //负责输入和输出设置之间的数据传递
    }
    [_captureSession setSessionPreset:AVCaptureSessionPresetiFrame1280x720];
    
    _frameCount = 0;
    
    // set the 1st device from system devices list
    if (!_captureDevice) {
        NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        _captureDevice = devices[0];
    }
    
    // set av capture device input
    AVCaptureDeviceInput *capDevInput = [AVCaptureDeviceInput deviceInputWithDevice:_captureDevice error:&error];
    if ([_captureSession canAddInput:capDevInput]) {
        [_captureSession addInput:capDevInput];
    }
    else {
        NSLog(@"Error in adding AVCaptureDeviceInput to AVCaptureSession.");
        return;
    }
    
    // set av capture video data output
    AVCaptureVideoDataOutput *capDatOutput = [[AVCaptureVideoDataOutput alloc] init];
    if ([_captureSession canAddOutput:capDatOutput]) {
        [_captureSession addOutput:capDatOutput];
    }
    else {
        NSLog(@"Error in adding AVCaptureVideoDataOutput to AVCaptureSession.");
        return;
    }
    
    // set connection of AVCaptureVideoDataOutput
    AVCaptureConnection *capConnection = [capDatOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([capConnection isVideoMinFrameDurationSupported]) {
        [capConnection setVideoMinFrameDuration:CMTimeMake(1, 25)];
    }
    if ([capConnection isVideoMaxFrameDurationSupported]) {
        [capConnection setVideoMaxFrameDuration:CMTimeMake(1, 25)];
    }
    
    [capDatOutput setAlwaysDiscardsLateVideoFrames:YES];
    NSDictionary<NSString *, id> *videoSettings = @{
        (id) kCVPixelBufferMetalCompatibilityKey: @(TRUE),
        (id) kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)
    };
    [capDatOutput setVideoSettings:videoSettings];
    
    [capDatOutput setSampleBufferDelegate:self queue:dispatch_queue_create("cameraDataOutputQueue", NULL)]; //
    
    [_captureSession beginConfiguration];
    [_captureSession commitConfiguration];
    
    [_captureSession startRunning];
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);//YCbCr or RGBA
    CFRetain(pixelBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    
    [_mtkView resetTextures:pixelBuffer];
    
    [self processVideoFrameBuffer:pixelBuffer];
    
    [self.mtkView draw];
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    CFRelease(pixelBuffer);
    
}

- (void)viewWillDisappear {
    printf("viewWillDisappear");
}

- (void)processVideoFrameBuffer:(CVPixelBufferRef)pixelBuffer {
    
}

@end
