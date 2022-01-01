//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "WindowCtrl_Camera_FaceLandmarkDetection.h"
#import "vnnimage_mac_kit.h"
#import "vnn_kit.h"

#if USE_FACE
#   import "vnn_face.h"
#endif

@interface WindowCtrl_Camera_FaceLandmarkDetection ()
@property (nonatomic, assign) unsigned int mHandle;
@property (nonatomic, assign) int          mUse278Pts;
@end

@implementation WindowCtrl_Camera_FaceLandmarkDetection

- (instancetype)initWithRootViewController:(NSViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    if(self){
        [self initModel];
    }
    return self;
}

- (void)initModel{
#   if USE_FACE
    const void *argv[] = {
        [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_face278_data/face_pc[1.0.0].vnnmodel"].UTF8String,
    };
    const int argc = sizeof(argv)/sizeof(argv[0]);
    VNN_Create_Face(&_mHandle, argc, argv);
    _mUse278Pts = 1;
    VNN_Set_Face_Attr(_mHandle, "_use_278pts", &_mUse278Pts);
#endif
}

- (void)windowShouldClose:(NSNotification *)notification {
    [super windowShouldClose:notification];
#   if USE_FACE
    VNN_Destroy_Face(&_mHandle);
#   endif
    [[NSApplication sharedApplication] stopModal];
}

- (void)processVideoFrameBuffer:(CVPixelBufferRef)pixelBuffer {
#   if USE_FACE
    
    if (_mHandle) {
        
        VNN_Image input;
        VNN_Create_VNNImage_From_PixelBuffer(pixelBuffer, &input, false);
        input.mode_fmt = VNN_MODE_FMT_VIDEO;
        input.ori_fmt = VNN_ORIENT_FMT_DEFAULT;
        
        VNN_FaceFrameDataArr output;        
        VNN_Apply_Face_CPU(_mHandle, &input, &output);
        
        VNN_Free_VNNImage(pixelBuffer, &input, false);
        
        NSMutableArray<DrawPoint2D *> * points =    [NSMutableArray array];
        NSMutableArray<DrawRect2D *> *  rects =     [NSMutableArray array];
        
        for (auto f = 0; f < output.facesNum; f+=1) {
            auto face = output.facesArr[f];
            for (auto p = 0; p < face.faceLandmarksNum; p+=1) {
                DrawPoint2D *pointx = [[DrawPoint2D alloc] init];
                [pointx setX:face.faceLandmarks[p].x];
                [pointx setY:face.faceLandmarks[p].y];
                [pointx setThickness:0.0015f];
                [pointx setColor:[NSColor colorWithRed:0.f green:1.f blue:0.f alpha:1.f]];
                [points addObject:pointx];
            }
            auto faceRect = [[DrawRect2D alloc] init];
            [faceRect setLeft:face.faceRect.x0];
            [faceRect setTop:face.faceRect.y0];
            [faceRect setRight:face.faceRect.x1];
            [faceRect setBottom:face.faceRect.y1];
            [faceRect setThickness:0.0015f];
            [faceRect setColor:[NSColor colorWithRed:0.f green:1.f blue:1.f alpha:1.f]];
            [rects addObject:faceRect];
        }
        
        [self.mtkView setPoints:[NSArray arrayWithArray:points]];
        [self.mtkView setRects:[NSArray arrayWithArray:rects]];
    }
#   endif
}

@end
