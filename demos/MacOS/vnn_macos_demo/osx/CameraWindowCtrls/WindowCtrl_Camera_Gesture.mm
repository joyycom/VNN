//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "WindowCtrl_Camera_Gesture.h"
#import "vnnimage_mac_kit.h"
#import "vnn_kit.h"

#if USE_GESTURE
#   import "vnn_gesture.h"
#endif

@interface WindowCtrl_Camera_Gesture ()
@property (nonatomic, assign) unsigned int mHandle;
@property (nonatomic, strong) NSMutableArray * lableImg;
@end

@implementation WindowCtrl_Camera_Gesture

- (instancetype)initWithRootViewController:(NSViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    if(self){
        [self initModel];
        [self initEffectImages];
    }
    return self;
}

- (void)initModel{
# if USE_GESTURE
    const void *argv[] = {
        [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_gesture_data/gesture[1.0.0].vnnmodel"].UTF8String,
    };
    const int argc = sizeof(argv)/sizeof(argv[0]);
    VNN_Create_Gesture(&_mHandle, argc, argv);
# endif
}

- (void)initEffectImages {
    NSArray * labelPath = [[NSArray alloc] initWithObjects:
                           [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/effects/gesture_label_imgs/unknow_gesture.png"],  // 1: 其他，未知,
                           [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/effects/gesture_label_imgs/v.jpg"],               // 2: 剪刀手
                           [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/effects/gesture_label_imgs/thumbup.jpg"],         // 3：点赞
                           [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/effects/gesture_label_imgs/onehandheart.jpg"],    // 4：单手比心
                           [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/effects/gesture_label_imgs/spiderman.png"],       // 5：蜘蛛侠 or 我爱你 or 摇滚
                           [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/effects/gesture_label_imgs/lift.jpg"],            // 6：托举
                           [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/effects/gesture_label_imgs/666.jpg"],             // 7：666 or 打电话
                           [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/effects/gesture_label_imgs/twohandsheart.jpg"],   // 8：双手比心
                           [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/effects/gesture_label_imgs/zuoyi.jpg"],           // 9：双手抱拳，作揖
                           [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/effects/gesture_label_imgs/palmopen.jpg"],        // 10：手掌张开
                           [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/effects/gesture_label_imgs/heshi.jpeg"],          // 11：合十
                           [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/effects/gesture_label_imgs/ok.jpg"],              // 12：OK 手势
                           nil];
    _lableImg = [NSMutableArray arrayWithCapacity:labelPath.count];
    for (auto i = 0; i < labelPath.count; i++) {
        [_lableImg addObject:[[NSImage alloc]initWithContentsOfFile:labelPath[i]]];
    }
}

- (void)windowShouldClose:(NSNotification *)notification {
    [super windowShouldClose:notification];
#   if USE_GESTURE
    VNN_Destroy_Gesture(&_mHandle);
#   endif
    [[NSApplication sharedApplication] stopModal];
}

- (void)processVideoFrameBuffer:(CVPixelBufferRef)pixelBuffer {
# if USE_GESTURE
    if (_mHandle) {
        auto frame_width = CVPixelBufferGetWidth(pixelBuffer);
        auto frame_height = CVPixelBufferGetHeight(pixelBuffer);
        
        VNN_Image input;
        VNN_Create_VNNImage_From_PixelBuffer(pixelBuffer, &input, false);
        input.mode_fmt = VNN_MODE_FMT_VIDEO;
        input.ori_fmt = VNN_ORIENT_FMT_DEFAULT;

        VNN_GestureFrameDataArr output;        
        VNN_Apply_Gesture_CPU(_mHandle, &input, &output);
        
        VNN_Free_VNNImage(pixelBuffer, &input, false);
        
        NSMutableArray<DrawRect2D *> * rects = [NSMutableArray array];
        NSMutableArray<DrawImage *> * labels = [NSMutableArray array];
        
        for (auto f = 0; f < output.gestureNum; f+=1) {
            auto gesture = output.gestureArr[f];
            
            auto gestureRect = [[DrawRect2D alloc] init];
            [gestureRect setLeft:gesture.rect.x0];
            [gestureRect setTop:gesture.rect.y0];
            [gestureRect setRight:gesture.rect.x1];
            [gestureRect setBottom:gesture.rect.y1];
            [gestureRect setThickness:0.0015f];
            [gestureRect setColor:[NSColor colorWithRed:0.f green:1.f blue:1.f alpha:1.f]];
            [rects addObject:gestureRect];
            
            auto gestureImg = [[DrawImage alloc] init];
            float len = fmin((gesture.rect.x1-gesture.rect.x0) * frame_width, (gesture.rect.y1-gesture.rect.y0) * frame_height);
            float cx = (gesture.rect.x0 + gesture.rect.x1) /2;
            float cy = (gesture.rect.y0 + gesture.rect.y1) /2;
            float paste_width  = len / frame_width * 0.5;
            float paste_height = len / frame_height * 0.5;
            [gestureImg setLeft:cx - paste_width/2];
            [gestureImg setTop:cy - paste_height/2];
            [gestureImg setRight:cx + paste_width/2];
            [gestureImg setBottom:cy + paste_height/2];
            [gestureImg setImg:_lableImg[gesture.type]];
            [labels addObject:gestureImg];
        }
        
        [self.mtkView setRects:[NSArray arrayWithArray:rects]];
        [self.mtkView setImgs:[NSArray arrayWithArray:labels]];
    }
# endif
}


@end
