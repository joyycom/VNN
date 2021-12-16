//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import <Cocoa/Cocoa.h>
#import <MetalKit/MetalKit.h>
#import "NSView_ElementsDrawer.h"
#import "MTKView_CameraRenderer.h"

NS_ASSUME_NONNULL_BEGIN

@interface ViewCtrl_PictureMetalRender : NSViewController
@end

@interface WindowCtrl_PictureMetalRender : NSWindowController

// Metal Properties ...
@property (nonatomic, strong) MTKViewX *                    mtkView;
@property (nonatomic, strong) NSButton *                    openBtn;
@property (nonatomic, strong) NSButton *                    saveBtn;

- (instancetype)initWithRootViewController:(NSViewController *)rootViewController;
- (void)processPictureBuffer:(CVPixelBufferRef)pixelBuffer URL:(NSURL *)url;
- (void)windowShouldClose:(NSNotification *)notification;
@end

NS_ASSUME_NONNULL_END
