//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "WindowCtrl_Camera_PoseLandmarkDetection.h"
#import "vnnimage_mac_kit.h"
#import "vnn_kit.h"
#include <vector>

#if USE_POSE
#   import "vnn_pose.h"
#endif

@interface WindowCtrl_Camera_PoseLandmarkDetection ()
@property (nonatomic, assign) unsigned int mHandle;
@end

@implementation WindowCtrl_Camera_PoseLandmarkDetection

- (instancetype)initWithRootViewController:(NSViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    if(self){
        [self initModel];
    }
    return self;
}

- (void)initModel{
#   if USE_POSE
    const void *argv[] = {
        [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_pose_data/pose_landmarks[1.0.0].vnnmodel"].UTF8String,
    };
    const int argc = sizeof(argv)/sizeof(argv[0]);
    VNN_Create_Pose(&_mHandle, argc, argv);
#endif
}

- (void)windowShouldClose:(NSNotification *)notification {
    [super windowShouldClose:notification];
#   if USE_POSE
    VNN_Destroy_Pose(&_mHandle);
#   endif
    [[NSApplication sharedApplication] stopModal];
}

- (void)processVideoFrameBuffer:(CVPixelBufferRef)pixelBuffer {
#   if USE_POSE
    
    if (_mHandle) {
        
        VNN_Image input;
        VNN_Create_VNNImage_From_PixelBuffer(pixelBuffer, &input, false);
        input.mode_fmt = VNN_MODE_FMT_VIDEO;
        input.ori_fmt = VNN_ORIENT_FMT_DEFAULT;
        
        VNN_BodyFrameDataArr output;
        VNN_Apply_Pose_CPU(_mHandle, &input, &output);
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
        NSMutableArray<DrawPoint2D *> * points =    [NSMutableArray array];
        NSMutableArray<DrawRect2D *> *  rects =     [NSMutableArray array];
        NSMutableArray<DrawLine2D *> *  lines =     [NSMutableArray array];
        for (auto f = 0; f < output.bodiesNum; f+=1) {
            auto body = output.bodiesArr[f];
            auto bodyRect = [[DrawRect2D alloc] init];
            [bodyRect setLeft:body.bodyRect.x0];
            [bodyRect setTop:body.bodyRect.y0];
            [bodyRect setRight:body.bodyRect.x1];
            [bodyRect setBottom:body.bodyRect.y1];
            [bodyRect setThickness:0.0015f];
            [bodyRect setColor:[NSColor colorWithRed:0.f green:1.f blue:1.f alpha:1.f]];
            [rects addObject:bodyRect];
            
            for (auto j = 0; j < body.bodyLandmarksNum; j++) {
                DrawPoint2D *pointx = [[DrawPoint2D alloc] init];
                [pointx setX:body.bodyLandmarks[j].x];
                [pointx setY:body.bodyLandmarks[j].y];
                [pointx setThickness:0.004f];
                if(body.bodyLandmarkScores[j] > 0.5){
                    [pointx setColor:[NSColor colorWithRed:0.f green:1.f blue:0.f alpha:1.f]];
                }
                else{
                    [pointx setColor:[NSColor colorWithRed:1.f green:0.f blue:0.f alpha:1.f]];
                }
                [points addObject:pointx];
            }
            
            for (auto k = 0; k < skeleton.size(); k++) {
                DrawLine2D *linex = [[DrawLine2D alloc] init];
                [linex setX0:body.bodyLandmarks[skeleton[k][0]].x];
                [linex setY0:body.bodyLandmarks[skeleton[k][0]].y];
                [linex setX1:body.bodyLandmarks[skeleton[k][1]].x];
                [linex setY1:body.bodyLandmarks[skeleton[k][1]].y];
                [linex setThickness:0.0015f];
                [linex setColor:[NSColor colorWithRed:0.f green:0.f blue:1.f alpha:1.f]];
                [lines addObject:linex];
            }
        }
        
        [self.mtkView setPoints:[NSArray arrayWithArray:points]];
        [self.mtkView setRects:[NSArray arrayWithArray:rects]];
        [self.mtkView setLines:[NSArray arrayWithArray:lines]];
    }
#   endif
}

@end
