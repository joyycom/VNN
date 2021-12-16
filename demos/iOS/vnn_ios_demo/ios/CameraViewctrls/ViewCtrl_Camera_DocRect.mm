//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "ViewCtrl_Camera_DocRect.h"
#import "vnn_kit.h"

#if USE_DOCRECT
#   import "vnn_docrect.h"
#endif

@interface ViewCtrl_Camera_DocRect ()
@property (nonatomic, assign) VNNHandle handle;
@end

@implementation ViewCtrl_Camera_DocRect

- (void)viewDidLoad {
#   if USE_DOCRECT
    VNN_SetLogLevel(VNN_LOG_LEVEL_ALL);
    const void *argv[] = {
        [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"files/models/vnn_docrect_data/document_rectification[1.0.0].vnnmodel"].UTF8String,
    };
    const int argc = sizeof(argv)/sizeof(argv[0]);
    VNN_Create_DocRect(&_handle, argc, argv);
#   endif
    
    [super viewDidLoad];
    [self onBtnSwitchCam];
}

- (void)onBtnBack {
    
#   if USE_DOCRECT
    VNN_Destroy_DocRect(&_handle);
#   endif
    [super onBtnBack];
}

- (void)videoCaptureCallback:(CVPixelBufferRef _Nullable)pixelBuffer {
#   if USE_DOCRECT
    if (_handle > 0) {
        
        VNN_Image input;
        VNN_Create_VNNImage_From_PixelBuffer(pixelBuffer, &input, false);
        
        VNN_Point2D output[4];
        memset(output, 0x00, sizeof(VNN_Point2D) * 4);
        VNN_Apply_DocRect_CPU(_handle, &input, output);
        
        VNN_Free_VNNImage(pixelBuffer, &input, false);
        
        [self.glUtils pointsDrawer]->_points.clear();
        for (auto j = 0; j < 4; j++) {
            [self.glUtils pointsDrawer]->_points.emplace_back(
                                                              vnn::renderkit::DrawPoint2D(
                                                                                            output[j].x,
                                                                                            output[j].y,
                                                                                            15,
                                                                                          vnn::renderkit::DrawColorRGBA(0.f, 1.f, 0.f, 1.f)
                                                                                            )
                                                              );
        }
    }
#   endif
    
    NSInteger rotateType = UIView_GLRenderUtils_RotateType_None;
    NSInteger flipType = UIView_GLRenderUtils_FlipType_None;
    if (self.cameraOrientation == AVCaptureVideoOrientationLandscapeRight) {
        rotateType = UIView_GLRenderUtils_RotateType_90R;
    }
    if (self.cameraOrientation == AVCaptureVideoOrientationLandscapeLeft) {
        rotateType = UIView_GLRenderUtils_RotateType_90L;
    }
    if (CVPixelBufferGetPlaneCount(pixelBuffer) != 0){
        [self.glUtils draw_With_YTexture:self.NSYTex UVTexture:self.NSUVTex RotateType:rotateType FlipType:flipType];
    } else {
        [self.glUtils draw_With_BGRATexture:self.NSBGRATex RotateType:rotateType FlipType:flipType];
    }
    
}

@end
