//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "WindowCtrl_Picture_Gesture.h"
#import "vnnimage_mac_kit.h"
#import "vnn_kit.h"
#import "OSXDemoHelper.h"
#include <vector>

#if USE_GESTURE
#   import "vnn_gesture.h"
#endif

@interface WindowCtrl_Picture_Gesture ()
@property (nonatomic, assign) VNNHandle         handle;
@property (nonatomic, strong) NSMutableArray*   lableImgTexture;


@end

@implementation WindowCtrl_Picture_Gesture

- (instancetype)initWithRootViewController:(NSViewController *)rootViewController {
    self = [super initWithRootViewController:rootViewController];
    if(self){
        [self initModel];
    }
    return self;
}

- (void)initModel{
#   if USE_GESTURE
    VNN_SetLogLevel(VNN_LOG_LEVEL_ALL);
    const void *argv[] = {
        [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_gesture_data/gesture[1.0.0].vnnmodel"].UTF8String,
    };
    const int argc = sizeof(argv)/sizeof(argv[0]);
    VNN_Create_Gesture(&_handle, argc, argv);
    
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
    _lableImgTexture = [NSMutableArray arrayWithCapacity:labelPath.count];
    for (auto i = 0; i < labelPath.count; i++) {
        NSURL* url = [NSURL URLWithString: [NSString stringWithFormat:@"%@%@", @"file://", labelPath[i]]];
        [_lableImgTexture addObject: [self.mtkView generateOffScreenTextureFromImageURL:url]];
    }
#   endif
}

- (void)windowShouldClose:(NSNotification *)notification {
    [super windowShouldClose:notification];
#   if USE_GESTURE
    VNN_Destroy_Gesture(&_handle);
#   endif
    [[NSApplication sharedApplication] stopModal];
}

- (void)processPictureBuffer:(CVPixelBufferRef)pixelBuffer URL:(NSURL *)url {
#   if USE_GESTURE
    VNN_Image input;
    VNN_Create_VNNImage_From_PixelBuffer(pixelBuffer, &input, false);
    input.mode_fmt = VNN_MODE_FMT_PICTURE;
    input.ori_fmt = VNN_ORIENT_FMT_DEFAULT;
    const int img_height = input.height;
    const int img_width = input.width;
    
    VNN_GestureFrameDataArr output;
    VNN_Apply_Gesture_CPU(_handle, &input, &output);
    
    VNN_Free_VNNImage(pixelBuffer, &input, false);
    
    NSMutableArray<DrawRect2D *> *  hand_rects =     [NSMutableArray array];
    std::vector<rectBox> texture_rects;
        
    for (auto f = 0; f < output.gestureNum; f+=1) {
        auto gesture = output.gestureArr[f];
        
        auto hand_rectx = [[DrawRect2D alloc] init];
        [hand_rectx setLeft:gesture.rect.x0];
        [hand_rectx setTop:gesture.rect.y0];
        [hand_rectx setRight:gesture.rect.x1];
        [hand_rectx setBottom:gesture.rect.y1];
        [hand_rectx setThickness:0.0015f];
        [hand_rectx setColor:[NSColor colorWithRed:0.f green:1.f blue:1.f alpha:1.f]];
        [hand_rects addObject:hand_rectx];
        
        rectBox texture_rectx;
        float len = fmin((gesture.rect.x1-gesture.rect.x0) * img_width, (gesture.rect.y1-gesture.rect.y0) * img_height);
        float cx = (gesture.rect.x0 + gesture.rect.x1) /2;
        float cy = (gesture.rect.y0 + gesture.rect.y1) /2;
        float paste_width  = len / img_width * 0.5;
        float paste_height = len / img_height * 0.5;
        texture_rectx.x0 = cx - paste_width/2;
        texture_rectx.y0 = cy - paste_height/2;
        texture_rectx.x1 = cx + paste_width/2;
        texture_rectx.y1 = cy + paste_height/2;
        texture_rects.emplace_back(texture_rectx);
    }
    
    self.mtkView.mtltexture_offScreenImage = [self.mtkView generateOffScreenTextureFromImageURL:url];
    
    id <MTLCommandBuffer> mtlCmdBuff = [self.mtkView.mtlCmdQueue commandBuffer];
    
    [self.mtkView drawHollowRect2DToOffscreen_With_MTLCommandBuffer:mtlCmdBuff
                                                            Rect2Ds:hand_rects
                                                   offScreenTexture:self.mtkView.mtltexture_offScreenImage
                                                        clearScreen:false];
    
    for (auto f = 0; f < output.gestureNum; f+=1) {
        [self.mtkView renderRectTextureToBackground_With_MTLCommandBuffer:mtlCmdBuff
                                                              rectTexture:_lableImgTexture[output.gestureArr[f].type]
                                                                  rectBox:texture_rects[f]
                                                         offScreenTexture:self.mtkView.mtltexture_offScreenImage
                                                              clearScreen:false];
    }
    
    [mtlCmdBuff commit];
    [mtlCmdBuff waitUntilScheduled];
    
#   endif
}

@end
