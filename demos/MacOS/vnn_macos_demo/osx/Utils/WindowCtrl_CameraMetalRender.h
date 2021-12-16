//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import <MetalKit/MetalKit.h>
#import "NSView_ElementsDrawer.h"
#import "MTKView_CameraRenderer.h"

NS_ASSUME_NONNULL_BEGIN

@interface ViewCtrl_CameraMetalRender : NSViewController
@end

@interface WindowCtrl_CameraMetalRender : NSWindowController <AVCaptureVideoDataOutputSampleBufferDelegate/*, MTKViewDelegate */>

// Metal Properties ...
@property (nonatomic, strong) MTKViewX *                    mtkView;

// Video Stream ...
@property (nonatomic, assign) NSUInteger                    frameCount;
@property (nonatomic, assign) dispatch_queue_t              sessionQueue;
@property (nonatomic, assign) dispatch_queue_t              cameraDataOutputQueue;
@property (nonatomic, assign) dispatch_queue_t              videoDataOutputQueue;
@property (nonatomic, assign) AVCaptureVideoOrientation     cameraOrientation;
@property (nonatomic, assign) AVCaptureDevicePosition       cameraPosition;
@property (nonatomic, assign) int                           cameraPixelFormatType;
@property (nonatomic, strong) AVCaptureDevice *             captureDevice;
@property (nonatomic, strong) AVCaptureConnection *         captureConnection;
@property (nonatomic, strong) AVCaptureSession *            captureSession;

- (instancetype)initWithRootViewController:(NSViewController *)rootViewController;
- (void)processVideoFrameBuffer:(CVPixelBufferRef)frameBuffer;
- (void)windowShouldClose:(NSNotification *)notification;
@end

NS_ASSUME_NONNULL_END
