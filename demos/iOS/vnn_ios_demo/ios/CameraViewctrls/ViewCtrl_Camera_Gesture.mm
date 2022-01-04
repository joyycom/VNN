//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "ViewCtrl_Camera_Gesture.h"
#import "vnnimage_ios_kit.h"
#import "vnn_kit.h"

#if USE_GESTURE
#   import "vnn_gesture.h"
#endif

@interface ViewCtrl_Camera_Gesture ()
@property (nonatomic, assign) VNNHandle 					handle;
@property (nonatomic, strong) NSArray *						gestureClsLables;
@property (nonatomic, strong) NSMutableArray<UILabel *> *	textLabels;
@end

@implementation ViewCtrl_Camera_Gesture

- (void)loadView {
    [super loadView];
#   if USE_GESTURE
    _gestureClsLables = [[NSArray alloc] initWithObjects:
                         @"❓",    // 1: 其他，未知,
                         @"✌️",    // 2: 剪刀手
                         @"👍",    // 3：点赞
                         @"🤞💕",  // 4：单手比心
                         @"🤟",    // 5：蜘蛛侠 or 我爱你 or 摇滚
                         @"💁‍♂",    // 6：托举
                         @"🤙",    // 7：666 or 打电话
                         @"🙌💕",  // 8：双手比心
                         @"[抱拳]", // 9：双手抱拳，作揖
                         @"🖐",    // 10：手掌张开
                         @"🙏",    // 11：合十
                         @"👌",    // 12：OK 手势
                         nil];
    _textLabels = [NSMutableArray arrayWithCapacity:VNN_FRAMEDATAARR_MAX_GESTURE_NUM];
    for (auto k = 0; k < VNN_FRAMEDATAARR_MAX_GESTURE_NUM; k++) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        [label setTextColor:[UIColor greenColor]];
        [label setFont:[[label font] fontWithSize:40]];
        [label setTextAlignment:NSTextAlignmentCenter];
        [_textLabels addObject:label];
        [self.view addSubview:label];
    }
#   endif
}

- (void)viewDidLoad {
#   if USE_GESTURE
    VNN_SetLogLevel(VNN_LOG_LEVEL_ALL);
    const void *argv[] = {
        [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"files/models/vnn_gesture_data/gesture[1.0.0].vnnmodel"].UTF8String,
    };
    const int argc = sizeof(argv)/sizeof(argv[0]);
    VNN_Create_Gesture(&_handle, argc, argv);
#   endif
    
    [super viewDidLoad];
}

- (void)onBtnBack {
    
#   if USE_GESTURE
    VNN_Destroy_Gesture(&_handle);
#   endif
    
    [super onBtnBack];
}

- (void)videoCaptureCallback:(CVPixelBufferRef _Nullable)pixelBuffer {
    
#   if USE_GESTURE
    VNN_Image input;
    VNN_Create_VNNImage_From_PixelBuffer(pixelBuffer, &input, false);
    input.mode_fmt = VNN_MODE_FMT_VIDEO;
    input.ori_fmt = VNN_ORIENT_FMT_DEFAULT;
    
    VNN_GestureFrameDataArr output;
    VNN_Apply_Gesture_CPU(_handle, &input, &output);
    
    VNN_Free_VNNImage(pixelBuffer, &input, false);
    
    [self.glUtils rectsDrawer]->_rects.clear();
    for (auto i = 0; i < output.gestureNum; i++) {
        [self.glUtils rectsDrawer]->_rects.emplace_back(
                                                        vnn::renderkit::DrawRect2D(
                                                                                     MIN(1.f, MAX(0, output.gestureArr[i].rect.x0)),     // left
                                                                                     MIN(1.f, MAX(0, output.gestureArr[i].rect.y0)),     // top
                                                                                     MIN(1.f, MAX(0, output.gestureArr[i].rect.x1)),     // right
                                                                                     MIN(1.f, MAX(0, output.gestureArr[i].rect.y1)),     // bottom
                                                                                     3.f,                                                // thickness
                                                                                   vnn::renderkit::DrawColorRGBA(0.f, 1.f, 0.f, 1.f) // color
                                                                                     )
                                                        );
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        for (int i = 0; i < output.gestureNum; i++) {
            float rect_left   = MIN(1.f, MAX(0, output.gestureArr[i].rect.x0)) * SCREEN_WIDTH  + (ACTUAL_SCREEN_WIDTH  - SCREEN_WIDTH ) / 2;
            float rect_top    = MIN(1.f, MAX(0, output.gestureArr[i].rect.y0)) * SCREEN_HEIGHT + (ACTUAL_SCREEN_HEIGHT - SCREEN_HEIGHT) / 2;
            float rect_right  = MIN(1.f, MAX(0, output.gestureArr[i].rect.x1)) * SCREEN_WIDTH  + (ACTUAL_SCREEN_WIDTH  - SCREEN_WIDTH ) / 2;
            float rect_bottom = MIN(1.f, MAX(0, output.gestureArr[i].rect.y1)) * SCREEN_HEIGHT + (ACTUAL_SCREEN_HEIGHT - SCREEN_HEIGHT) / 2;
            float rect_width  = rect_right - rect_left;
            float rect_height = rect_bottom - rect_top;
            [self.textLabels[i] setFont:[[self.textLabels[i] font] fontWithSize:NSUInteger(MIN(rect_width, rect_height) * 0.3)]];
            [self.textLabels[i] setFrame:CGRectMake(rect_left, rect_top, rect_width, rect_height)];
            [self.textLabels[i] setText:[NSString stringWithFormat:@"%@", [self.gestureClsLables objectAtIndex:NSUInteger(output.gestureArr[i].type)]]];
            [self.textLabels[i] setHidden:NO];
        }
        for (int i = output.gestureNum; i < VNN_FRAMEDATAARR_MAX_GESTURE_NUM; i++) {
            [self.textLabels[i] setHidden:YES];
        }
    });
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
