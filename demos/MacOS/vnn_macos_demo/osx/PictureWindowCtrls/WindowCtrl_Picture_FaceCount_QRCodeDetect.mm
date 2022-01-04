//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "WindowCtrl_Picture_FaceCount_QRCodeDetect.h"
#import "vnnimage_mac_kit.h"
#import "vnn_kit.h"
#import "OSXDemoHelper.h"

#if USE_OBJCOUNT
#   import "vnn_objcount.h"
#endif

@interface WindowCtrl_Picture_FaceCount_QRCodeDetect ()
@property (nonatomic, assign) VNNHandle handle;
@property (nonatomic, retain) NSString* model;
@property (nonatomic, retain) NSString* cfg;
@end

@implementation WindowCtrl_Picture_FaceCount_QRCodeDetect

- (instancetype)initWithRootViewController:(NSViewController *)rootViewController WithFunctionType:(NSString *)type {
    self = [super initWithRootViewController:rootViewController];
    if(self){
        if([type isEqual:@"FaceCount"]){
            _model = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_face_count_data/face_count[1.0.0].vnnmodel"];
        }
        else if([type isEqual:@"QRCodeDetect"]){
            _model = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_qrcode_detection_data/qrcode_detection[1.0.0].vnnmodel"];
        }
        else{
            NSAssert(false, @"Error Function Type");
        }
        [self initModel];
    }
    return self;
}

- (void)initModel{
#   if USE_OBJCOUNT
    VNN_SetLogLevel(VNN_LOG_LEVEL_ALL);
    
    const void *argv[] = { _model.UTF8String };
    const int argc = sizeof(argv)/sizeof(argv[0]);
    VNN_Create_ObjCount(&_handle, argc, argv);
#   endif
}

- (void)windowShouldClose:(NSNotification *)notification {
    [super windowShouldClose:notification];
#   if USE_OBJCOUNT
    VNN_Destroy_ObjCount(&_handle);
#   endif
    [[NSApplication sharedApplication] stopModal];
}

- (void)processPictureBuffer:(CVPixelBufferRef)pixelBuffer URL:(NSURL *)url {
#   if USE_OBJCOUNT
    if (_handle > 0) {
        VNN_Image input;
        VNN_Create_VNNImage_From_PixelBuffer(pixelBuffer, &input, false);
        input.mode_fmt = VNN_MODE_FMT_PICTURE;
        input.ori_fmt = VNN_ORIENT_FMT_DEFAULT;
        
        VNN_ObjCountDataArr outputs;
        VNN_Apply_ObjCount_CPU(_handle, &input, &outputs);
        
        VNN_Free_VNNImage(pixelBuffer, &input, false);
                
        NSMutableArray<DrawRect2D *> * rects = [NSMutableArray array];
        for (auto j = 0; j < outputs.count; j++) {
            VNN_Rect2D vnnRect = outputs.objRectArr[j];
            auto mtlRect = [[DrawRect2D alloc] init];
            [mtlRect setLeft:vnnRect.x0];
            [mtlRect setTop:vnnRect.y0];
            [mtlRect setRight:vnnRect.x1];
            [mtlRect setBottom:vnnRect.y1];
            [mtlRect setThickness:0.0015f];
            [mtlRect setColor:[NSColor colorWithRed:0.f green:1.f blue:1.f alpha:1.f]];
            [rects addObject:mtlRect];
        }
        
        VNN_ObjCountDataArr_Free(&outputs);
        
        
        self.mtkView.mtltexture_offScreenImage = [self.mtkView generateOffScreenTextureFromImageURL:url];
            
        id <MTLCommandBuffer> mtlCmdBuff = [self.mtkView.mtlCmdQueue commandBuffer];
        
        [self.mtkView drawHollowRect2DToOffscreen_With_MTLCommandBuffer:mtlCmdBuff
                                                                Rect2Ds:rects
                                                       offScreenTexture:self.mtkView.mtltexture_offScreenImage
                                                            clearScreen:false];
        
        [mtlCmdBuff commit];
        [mtlCmdBuff waitUntilScheduled];
    }
#   endif
}

@end
