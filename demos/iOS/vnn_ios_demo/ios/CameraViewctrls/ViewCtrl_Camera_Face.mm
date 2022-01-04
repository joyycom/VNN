//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "ViewCtrl_Camera_Face.h"
#import "vnnimage_ios_kit.h"
#import "vnn_kit.h"
#if USE_FACE
#   import "vnn_face.h"
#endif

@interface ViewCtrl_Camera_Face ()
@property (nonatomic, assign) NSUInteger                                segctrl_num_pts_select_index;
@property (nonatomic, strong) UISegmentedControl *                      segctrl_num_pts;
@property (nonatomic, assign) VNNHandle 				                handle;
@property (nonatomic, assign) int                                       use_278pts;
@end

@implementation ViewCtrl_Camera_Face

- (UISegmentedControl *)segctrl_num_pts {
    if (!_segctrl_num_pts) {
        _segctrl_num_pts = [[UISegmentedControl alloc] initWithFrame:CGRectMake(SCREEN_WIDTH * 1.0 / 9.0,
                                                                                (ACTUAL_SCREEN_HEIGHT - SCREEN_HEIGHT) / 2 + SCREEN_HEIGHT * 15 / 16.0,
                                                                                SCREEN_WIDTH * 7 / 9.0,
                                                                                SCREEN_HEIGHT * 0.75 / 16.0)];
        if (@available(iOS 13.0, *)) {
            [_segctrl_num_pts setSelectedSegmentTintColor:UIColorFromRGB(0x0000f0)];
        }
        [_segctrl_num_pts setApportionsSegmentWidthsByContent:YES];
        [_segctrl_num_pts insertSegmentWithTitle:@"104点" atIndex:0 animated:YES];
        [_segctrl_num_pts insertSegmentWithTitle:@"278点" atIndex:1 animated:YES];
        _segctrl_num_pts_select_index = 0;
        [_segctrl_num_pts setSelectedSegmentIndex:_segctrl_num_pts_select_index];
        
    }
    return _segctrl_num_pts;
}

- (void)loadView {
    [super loadView];
    [self.view addSubview:self.segctrl_num_pts];
}

- (void)viewDidLoad {
#   if USE_FACE
    VNN_SetLogLevel(VNN_LOG_LEVEL_ALL);
    const void *argv[] = {
        [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"files/models/vnn_face278_data/face_mobile[1.0.0].vnnmodel"].UTF8String,
    };
    const int argc = sizeof(argv)/sizeof(argv[0]);
    VNN_Create_Face(&_handle, argc, argv);
#   endif
    
    [super viewDidLoad];
}

- (void)onBtnBack {
    
#   if USE_FACE
    VNN_Destroy_Face(&_handle);
#   endif
    
    [super onBtnBack];
}

- (void)videoCaptureCallback:(CVPixelBufferRef _Nullable)pixelBuffer {
    
#   if USE_FACE
    if (_handle > 0) {
        
        _use_278pts = (int)_segctrl_num_pts_select_index;
        VNN_Set_Face_Attr(_handle, "_use_278pts", &_use_278pts);
        
        VNN_Image input;
        VNN_Create_VNNImage_From_PixelBuffer(pixelBuffer, &input, false);
        input.mode_fmt = VNN_MODE_FMT_VIDEO;
        input.ori_fmt = VNN_ORIENT_FMT_DEFAULT;
        
        VNN_FaceFrameDataArr output;
        VNN_Apply_Face_CPU(_handle, &input, &output);
        
        VNN_Free_VNNImage(pixelBuffer, &input, false);
        
        [self.glUtils rectsDrawer]->_rects.clear();
        [self.glUtils circlesDrawer]->_circles.clear();
        for (auto i = 0; i < output.facesNum; i++) {
            [self.glUtils rectsDrawer]->_rects.emplace_back(
                                                            vnn::renderkit::DrawRect2D(
                                                                                         MIN(1.f, MAX(0, output.facesArr[i].faceRect.x0)),     // left
                                                                                         MIN(1.f, MAX(0, output.facesArr[i].faceRect.y0)),    // top
                                                                                         MIN(1.f, MAX(0, output.facesArr[i].faceRect.x1)),    // right
                                                                                         MIN(1.f, MAX(0, output.facesArr[i].faceRect.y1)),    // bottom
                                                                                         3.f,                                // thickness
                                                                                       vnn::renderkit::DrawColorRGBA(1.f, 1.f, 0.f, 1.f)
                                                                                         )
                                                            );
            for (auto j = 0; j < output.facesArr[i].faceLandmarksNum; j++) {
                [self.glUtils circlesDrawer]->_circles.emplace_back(
                                                                    vnn::renderkit::DrawCircle2D(
                                                                                                   output.facesArr[i].faceLandmarks[j].x,
                                                                                                   output.facesArr[i].faceLandmarks[j].y,
                                                                                                   8,
                                                                                                   output.facesArr[i].faceLandmarkScores[j] > 0.5? vnn::renderkit::DrawColorRGBA(0.f, 1.f, 0.f, 1.f) : vnn::renderkit::DrawColorRGBA(1.f, 0.f, 0.f, .5f)
                                                                                                   )
                                                                    );
            }
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
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.segctrl_num_pts_select_index = (int)self.segctrl_num_pts.selectedSegmentIndex;
    });
    
}

@end
