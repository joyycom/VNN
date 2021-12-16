//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "WindowCtrl_Picture_DocRect.h"
#import "vnn_kit.h"
#import "OSXDemoHelper.h"

#if USE_FACE
#   import "vnn_face.h"
#endif

@interface WindowCtrl_Picture_DocRect ()
@property (nonatomic, assign) unsigned int mHandle;
@property (nonatomic, assign) int          mUse278Pts;
@end

@implementation WindowCtrl_Picture_DocRect

- (instancetype)initWithRootViewController:(NSViewController *)rootViewController {
    self = [super initWithRootViewController:rootViewController];
    if(self){
        [self initModel];
    }
    return self;
}

- (void)dealloc {
#   if USE_FACE
    VNN_Destroy_Face(&_mHandle);
#   endif
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

- (void)processPictureBuffer:(CVPixelBufferRef)pixelBuffer URL:(NSURL *)url {
    VNN_Image input;
    VNN_Create_VNNImage_From_PixelBuffer(pixelBuffer, &input, false);
    input.mode_fmt = VNN_MODE_FMT_PICTURE;
    
    VNN_FaceFrameDataArr output;
    memset(&output, 0x00, sizeof(VNN_FaceFrameDataArr));
    
    VNN_Apply_Face_CPU(_mHandle, &input, &output);
        
    NSMutableArray<DrawPoint2D *> * points =    [NSMutableArray array];
    NSMutableArray<DrawRect2D *> *  rects =     [NSMutableArray array];
    
    VNN_Free_VNNImage(pixelBuffer, &input, false);

    VNN_FaceFrameDataArr_Result_Mirror(&output);
    
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
        auto rectx = [[DrawRect2D alloc] init];
        [rectx setLeft:face.faceRect.x0];
        [rectx setTop:face.faceRect.y0];
        [rectx setRight:face.faceRect.x1];
        [rectx setBottom:face.faceRect.y1];
        [rectx setThickness:0.0015f];
        [rectx setColor:[NSColor colorWithRed:0.f green:1.f blue:1.f alpha:1.f]];
        [rects addObject:rectx];
    }
    
    self.mtkView.mtltexture_offScreenImage = [self.mtkView generateOffScreenTextureFromImageURL:url];
        
    id <MTLCommandBuffer> mtlCmdBuff = [self.mtkView.mtlCmdQueue commandBuffer];
    
    [self.mtkView drawHollowRect2DToOffscreen_With_MTLCommandBuffer:mtlCmdBuff
                                                            Rect2Ds:rects
                                                   offScreenTexture:self.mtkView.mtltexture_offScreenImage
                                                        clearScreen:false];
    
    [mtlCmdBuff commit];
    [mtlCmdBuff waitUntilScheduled];
}

@end
