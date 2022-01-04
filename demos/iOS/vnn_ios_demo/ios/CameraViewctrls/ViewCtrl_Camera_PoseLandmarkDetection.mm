//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "ViewCtrl_Camera_PoseLandmarkDetection.h"
#import "vnnimage_ios_kit.h"
#import "vnn_kit.h"

#if USE_POSE
#   import "vnn_pose.h"
#endif

@interface ViewCtrl_Camera_PoseLandmarkDetection ()
@property (nonatomic, assign) VNNHandle handle;
@end

@implementation ViewCtrl_Camera_PoseLandmarkDetection

- (void)viewDidLoad {
#   if USE_POSE
    VNN_SetLogLevel(VNN_LOG_LEVEL_ALL);
    const void *argv[] = {
        [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"files/models/vnn_pose_data/pose_landmarks[1.0.0].vnnmodel"].UTF8String,
    };
    const int argc = sizeof(argv)/sizeof(argv[0]);
    VNN_Create_Pose(&_handle, argc, argv);
#   endif
    
    [super viewDidLoad];
    [self onBtnSwitchCam];
}

- (void)onBtnBack {
    
#   if USE_POSE
    VNN_Destroy_Pose(&_handle);
#   endif
    [super onBtnBack];
}

- (void)videoCaptureCallback:(CVPixelBufferRef _Nullable)pixelBuffer {
#   if USE_POSE
    if (_handle > 0) {
        
        VNN_Image input;
        VNN_Create_VNNImage_From_PixelBuffer(pixelBuffer, &input, false);
        input.mode_fmt = VNN_MODE_FMT_VIDEO;
        input.ori_fmt = VNN_ORIENT_FMT_DEFAULT;
        
        VNN_BodyFrameDataArr output;
        VNN_Apply_Pose_CPU(_handle, &input, &output);
        VNN_Free_VNNImage(pixelBuffer, &input, false);
        
        const std::vector<std::vector<int>> skeleton = {
            {  0,  1 },
            {  1,  2 },
            {  2,  3 },
            {  3,  4 },
            {  4, 18 },
            {  1,  5 },
            {  5,  6 },
            {  6,  7 },
            {  7, 19 },
            {  2,  8 },
            {  8,  9 },
            {  9, 10 },
            { 10, 20 },
            {  5, 11 },
            { 11, 12 },
            { 12, 13 },
            { 13, 21 },
            {  0, 14 },
            { 14, 16 },
            {  0, 15 },
            { 15, 17 },
        };
        [self.glUtils rectsDrawer]->_rects.clear();
        [self.glUtils pointsDrawer]->_points.clear();
        [self.glUtils linesDrawer]->_lines.clear();
        for (auto i = 0; i < output.bodiesNum; i++) {
            [self.glUtils rectsDrawer]->_rects.emplace_back(
                                                            vnn::renderkit::DrawRect2D(
                                                                                       MIN(1.f, MAX(0, output.bodiesArr[i].bodyRect.x0)),    // left
                                                                                       MIN(1.f, MAX(0, output.bodiesArr[i].bodyRect.y0)),    // top
                                                                                       MIN(1.f, MAX(0, output.bodiesArr[i].bodyRect.x1)),    // right
                                                                                       MIN(1.f, MAX(0, output.bodiesArr[i].bodyRect.y1)),    // bottom
                                                                                       2.f,                                // thickness
                                                                                       vnn::renderkit::DrawColorRGBA(1.f, 1.f, 0.f, 1.f)
                                                                                       )
                                                            );
            for (auto j = 0; j < output.bodiesArr[i].bodyLandmarksNum; j++) {
                [self.glUtils pointsDrawer]->_points.emplace_back(
                                                                  vnn::renderkit::DrawPoint2D(
                                                                                              output.bodiesArr[i].bodyLandmarks[j].x,
                                                                                              output.bodiesArr[i].bodyLandmarks[j].y,
                                                                                              5,
                                                                                              output.bodiesArr[i].bodyLandmarkScores[j] > 0.5? vnn::renderkit::DrawColorRGBA(0.f, 1.f, 0.f, 1.f) : vnn::renderkit::DrawColorRGBA(1.f, 0.f, 0.f, .5f)
                                                                                              )
                                                                  );
            }
            for (auto k = 0; k < skeleton.size(); k++) {
                [self.glUtils linesDrawer]->_lines.emplace_back(
                                                                vnn::renderkit::DrawLine2D(
                                                                                           vnn::renderkit::DrawPoint2D(
                                                                                                                       output.bodiesArr[i].bodyLandmarks[skeleton[k][0]].x,
                                                                                                                       output.bodiesArr[i].bodyLandmarks[skeleton[k][0]].y,
                                                                                                                       10,
                                                                                                                       output.bodiesArr[i].bodyLandmarkScores[skeleton[k][0]] > 0.5? vnn::renderkit::DrawColorRGBA(0.f, 0.f, 1.f, 1.f) : vnn::renderkit::DrawColorRGBA(1.f, 0.f, 0.f, .5f)
                                                                                                                       ),
                                                                                           vnn::renderkit::DrawPoint2D(
                                                                                                                       output.bodiesArr[i].bodyLandmarks[skeleton[k][1]].x,
                                                                                                                       output.bodiesArr[i].bodyLandmarks[skeleton[k][1]].y,
                                                                                                                       5,
                                                                                                                       output.bodiesArr[i].bodyLandmarkScores[skeleton[k][1]] > 0.5? vnn::renderkit::DrawColorRGBA(0.f, 0.f, 1.f, 1.f) : vnn::renderkit::DrawColorRGBA(1.f, 0.f, 0.f, .5f)
                                                                                                                       ),
                                                                                           2.f
                                                                                           )
                                                                );
            }
        }
    }
#       endif
    
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
