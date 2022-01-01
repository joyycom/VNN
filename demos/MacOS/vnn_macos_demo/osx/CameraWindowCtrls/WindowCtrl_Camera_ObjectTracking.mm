//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "WindowCtrl_Camera_ObjectTracking.h"
#import "vnnimage_mac_kit.h"
#include <vector>
#include "vnn_kit.h"

#if USE_OBJTRACKING
#   include "vnn_objtracking.h"
#endif

#define WAIT_BBOX_STAGE 0
#define INIT_STAGE      1
#define TRACK_STAGE     2


@interface WindowCtrl_Camera_ObjectTracking ()
@property (nonatomic, assign) VNNHandle handle_objtracking;
@property (atomic, assign) volatile int                                 stage;
@property (atomic, assign) volatile bool                                is_dragged;
@property (atomic, assign) std::vector<float>                           init_bbox;
@property (atomic, assign) CGFloat                                      start_x;
@property (atomic, assign) CGFloat                                      start_y;
@property (atomic, assign) CGFloat                                      end_x;
@property (atomic, assign) CGFloat                                      end_y;
@property (atomic, assign) CGFloat                                      FRAME_WIDTH;
@property (atomic, assign) CGFloat                                      FRAME_HEIGHT;
@property (atomic, assign) bool                                         is_first_run;

@end

@implementation WindowCtrl_Camera_ObjectTracking

- (instancetype)initWithRootViewController:(NSViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    if(self){
        [self initModel];
        _stage = WAIT_BBOX_STAGE;
        _is_dragged = false;
        _is_first_run = true;
    }
    return self;
}

- (void)initModel{
#   if USE_OBJTRACKING
    const void *argv[] = {
        [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_objtracking_data/object_tracking[1.0.0].vnnmodel"].UTF8String,
    };
    const int argc = sizeof(argv)/sizeof(argv[0]);
    VNN_Create_ObjTracking(&_handle_objtracking, argc, argv);
#   endif
}

- (void)windowShouldClose:(NSNotification *)notification {
    [super windowShouldClose:notification];
#if USE_OBJTRACKING
    VNN_Destroy_ObjTracking(&_handle_objtracking);
#   endif
    [[NSApplication sharedApplication] stopModal];
}

- (void)mouseDown:(NSEvent *)theEvent {
    
    if(_stage == TRACK_STAGE){
        _init_bbox.clear();
        _is_dragged = false;
        _stage = WAIT_BBOX_STAGE;
    }
    
    NSPoint mouseDownPos = [theEvent locationInWindow];
    NSLog(@"got Ponit(%f, %f)", mouseDownPos.x, mouseDownPos.y);
    
    _start_x = mouseDownPos.x;
    _start_y = _FRAME_HEIGHT - mouseDownPos.y;
    
}

- (void)mouseDragged:(NSEvent *)theEvent {
    NSPoint mouseDraggedPos = [theEvent locationInWindow];
    NSLog(@"mouseDragged got Ponit(%f, %f)", mouseDraggedPos.x, mouseDraggedPos.y);
    
    _end_x = mouseDraggedPos.x;
    _end_y = _FRAME_HEIGHT - mouseDraggedPos.y;
    
    float left, right, bottom, top;
    
    if(_start_x < _start_y){
        left = _start_x;
        right = _end_x;
    }
    else{
        left = _end_x;
        right = _start_x;
    }
    
    if(_start_y < _end_y){
        top = _start_y;
        bottom = _end_y;
    }
    else{
        top = _end_y;
        bottom = _start_y;
    }
    
    left /= _FRAME_WIDTH;
    right /= _FRAME_WIDTH;
    top /= _FRAME_HEIGHT;
    bottom /= _FRAME_HEIGHT;
    
    NSMutableArray<DrawRect2D *> *  rects =     [NSMutableArray array];
    auto rect = [[DrawRect2D alloc] init];
    [rect setLeft: 1.f - left];
    [rect setTop:top];
    [rect setRight: 1.f - right];
    [rect setBottom:bottom];
    [rect setThickness:0.0015f];
    [rect setColor:[NSColor colorWithRed:0.f green:1.f blue:1.f alpha:1.f]];
    [rects addObject:rect];
    [self.mtkView setRects:[NSArray arrayWithArray:rects]];
    
    _is_dragged = true;
}

- (void)mouseUp:(NSEvent *)theEvent {
    
    if(!_is_dragged){
        return;
    }
    
    NSPoint mouseUPPos = [theEvent locationInWindow];
    NSLog(@"mouseUP got Ponit(%f, %f)", mouseUPPos.x, mouseUPPos.y);
    
    _end_x = mouseUPPos.x;
    _end_y = _FRAME_HEIGHT - mouseUPPos.y;
    
    float left, right, bottom, top;
    
    if(_start_x < _start_y){
        left = _start_x;
        right = _end_x;
    }
    else{
        left = _end_x;
        right = _start_x;
    }
    
    if(_start_y < _end_y){
        top = _start_y;
        bottom = _end_y;
    }
    else{
        top = _end_y;
        bottom = _start_y;
    }
    
    if(right - left < 100 || bottom - top < 100){
        _is_dragged = false;
    }
    
    left /= _FRAME_WIDTH;
    right /= _FRAME_WIDTH;
    top /= _FRAME_HEIGHT;
    bottom /= _FRAME_HEIGHT;
    
    _init_bbox.push_back(left);
    _init_bbox.push_back(top);
    _init_bbox.push_back(right);
    _init_bbox.push_back(bottom);
    _stage = INIT_STAGE;
    NSLog(@"Got Valid Rect, Ready to Init");
}

- (void)processVideoFrameBuffer:(CVPixelBufferRef)pixelBuffer{
# if USE_OBJTRACKING
    _FRAME_WIDTH = CVPixelBufferGetWidth(pixelBuffer);
    _FRAME_HEIGHT = CVPixelBufferGetHeight(pixelBuffer);
    
    if(_is_first_run){
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [NSAlert alertWithMessageText:@"Demo Usage" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", @"Drag a rectangle for the object to start tracking\nLeft-Click to stopping tracking"];
            [alert beginSheetModalForWindow:[NSApp mainWindow] completionHandler: nil];
        });
        _is_first_run = false;
    }
    
    NSMutableArray<DrawRect2D *> *  rects =     [NSMutableArray array];
    
    if (_handle_objtracking > 0) {
        
        if(_stage == WAIT_BBOX_STAGE){
            if(!_is_dragged){
                [self.mtkView setRects:[NSArray arrayWithArray:rects]];
            }
            return;
        }
        
        VNN_Image input;
        VNN_Create_VNNImage_From_PixelBuffer(pixelBuffer, &input, false);
        input.mode_fmt = VNN_MODE_FMT_VIDEO;
        input.ori_fmt = VNN_ORIENT_FMT_DEFAULT;

        if(_stage == INIT_STAGE){
            NSLog(@"Start to Init");
            auto faceRect = [[DrawRect2D alloc] init];
            [faceRect setLeft: 1.f - _init_bbox[0]];
            [faceRect setTop:_init_bbox[1]];
            [faceRect setRight: 1.f - _init_bbox[2]];
            [faceRect setBottom:_init_bbox[3]];
            [faceRect setThickness:0.0015f];
            [faceRect setColor:[NSColor colorWithRed:0.f green:1.f blue:0.f alpha:1.f]];
            [rects addObject:faceRect];
            
            // 预览画面与采集画面是水平镜像关系
            // 鼠标点击获得的坐标需要调整一下
            float left = 1.f - _init_bbox[0];
            float right = 1.f - _init_bbox[2];
            if(left > right){
                float temp = left;
                left = right;
                right = temp;
            }
            
            VNN_Rect2D template_bbox = {left, _init_bbox[1], right, _init_bbox[3]};
            VNN_Set_ObjTracking_Attr(_handle_objtracking, "_objRect", &template_bbox);
            VNN_Set_ObjTracking_Attr(_handle_objtracking, "_targetImage", &input);
            _stage = TRACK_STAGE;
            NSLog(@"Init done, ready to Track");
        }
        else if(_stage == TRACK_STAGE){
            
            VNN_ObjCountDataArr tracking_result_bbox;
            VNN_Apply_ObjTracking_CPU(_handle_objtracking, &input, &tracking_result_bbox);
            
            if(tracking_result_bbox.count == 1){
                auto bbox = tracking_result_bbox.objRectArr[0];
                auto faceRect = [[DrawRect2D alloc] init];
                [faceRect setLeft: bbox.x0];
                [faceRect setTop: bbox.y0];
                [faceRect setRight: bbox.x1];
                [faceRect setBottom:bbox.y1];
                [faceRect setThickness:0.0015f];
                [faceRect setColor:[NSColor colorWithRed:0.f green:1.f blue:0.f alpha:1.f]];
                [rects addObject:faceRect];
            }
        }
        VNN_Free_VNNImage(pixelBuffer, &input, false);
        [self.mtkView setRects:[NSArray arrayWithArray:rects]];
    }
# endif
}

@end

