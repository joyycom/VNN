//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "WindowCtrl_Picture_FaceReenactment.h"
#import "vnnimage_mac_kit.h"
#import "vnn_common.h"
#import "vnn_kit.h"
#import "vnn_common.h"
#import "OSXDemoHelper.h"

#if USE_FACE_REENACTMENT && USE_FACE
#   import "vnn_face.h"
#   import "vnn_face_reenactment.h"
#endif

#define FACE_WIDTH  (256)
#define FACE_HEIGHT (256)
#define FACE_CHANNEL (3)

@interface WindowCtrl_Picture_FaceReenactment ()
@property (nonatomic, assign) VNNHandle                    handle;
@property (nonatomic, assign) VNNHandle                    face_handle;
@property (nonatomic, assign) VnnU8BufferPtr               outBuffer;
@property (nonatomic, assign) VnnU8BufferPtr               bgraBuffer;
@property (nonatomic, assign) int                          WINDOW_WIDTH;
@property (nonatomic, assign) int                          WINDOW_HEIGHT;
@property (nonatomic, assign) bool                         is_first_run;
@property (nonatomic, strong) id<MTLTexture>               mtltexture_face;
@property (nonatomic, strong) NSButton*                    reRunBtn;
@property (nonatomic, strong) NSURL*                       imgURL;
@end

@implementation WindowCtrl_Picture_FaceReenactment

- (instancetype)initWithRootViewController:(NSViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    if(self){
        [self initModel];
        self.WINDOW_WIDTH = self.window.frame.size.width;
        self.WINDOW_HEIGHT = self.window.frame.size.height;
        self.is_first_run = true;
        if(!self.reRunBtn){
            self.reRunBtn = [[NSButton alloc] initWithFrame:NSMakeRect(self.WINDOW_WIDTH - 300, 20, 96, 64)];
            self.reRunBtn.wantsLayer = YES;
            self.reRunBtn.bezelStyle = NSBezelStyleRegularSquare;
            [self.reRunBtn setTitle:@"Rerun"];
            [self.reRunBtn setAction: @selector(onReRunBtnClick:)];
            [self.reRunBtn setHidden:true];
            [self.window.contentView  addSubview:self.reRunBtn];
            [self.reRunBtn setHidden:YES];
        }
    }
    return self;
}

- (void) onReRunBtnClick: (id)sender{
    
    CGFloat oriImageWidth = self.mtkView.mtltexture_srcImage.width;
    CGFloat oriImageHeight = self.mtkView.mtltexture_srcImage.height;
    
    unsigned char* dataBuffer = (unsigned char *)malloc(oriImageWidth*oriImageHeight*4);
    CVPixelBufferRef pixelBuffer = [self.mtkView createPixelBufferFromBGRAMTLTexture:self.mtkView.mtltexture_srcImage UseDataBuffer:dataBuffer];
    [self processPictureBufferCore:pixelBuffer URL:self.imgURL];
    CVPixelBufferRelease(pixelBuffer);
    free(dataBuffer);
    
    rectBox effectImageRegion;
    if(oriImageWidth > oriImageHeight){
        effectImageRegion.x0 = .5f;
        effectImageRegion.x1 = 1.f;
        
        CGFloat resizedH = oriImageHeight * (self.WINDOW_WIDTH/2) / oriImageWidth;
        CGFloat normResizedH = resizedH / self.WINDOW_HEIGHT;
        
        effectImageRegion.y0 = (1.f - normResizedH)/2;
        effectImageRegion.y1 = 1.f - ((1.f - normResizedH)/2);
    }
    else{
        effectImageRegion.y0 = 0.f;
        effectImageRegion.y1 = 1.f;
        
        CGFloat resizedW = oriImageWidth * (self.WINDOW_HEIGHT) / oriImageHeight;
        CGFloat normResizedW = resizedW / self.WINDOW_WIDTH;
        
        effectImageRegion.x0 = .5f + (.5f - normResizedW)/2;
        effectImageRegion.x1 = 1.f - (.5f - normResizedW)/2;
    }
    
    id <MTLCommandBuffer> mtlCmdBuff = [self.mtkView.mtlCmdQueue commandBuffer];
    if(self.mtkView.mtltexture_offScreenImage){
        [self.mtkView renderRectTextureToBackground_With_MTLCommandBuffer:mtlCmdBuff
                                                              rectTexture:self.mtkView.mtltexture_offScreenImage
                                                                  rectBox:effectImageRegion
                                                         offScreenTexture:self.mtkView.mtltexture_BGRA
                                                              clearScreen:false];
    }
    
    [mtlCmdBuff commit];
    [mtlCmdBuff waitUntilScheduled];
    [self.mtkView draw];
    
}

- (void)initModel{
#   if USE_FACE_REENACTMENT && USE_FACE
    const void *face_detection_argv[] = {
        [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_face278_data/face_pc[1.0.0].vnnmodel"].UTF8String,
    };
    const int face_detection_argc = sizeof(face_detection_argv)/sizeof(face_detection_argv[0]);
    VNN_Create_Face(&_face_handle, face_detection_argc, face_detection_argv);
    int use_278pts = 1;
    VNN_Set_Face_Attr(_face_handle, "_use_278pts", &use_278pts);
    
    const void *face_reenactment_argv[] = {
        [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_face_reenactment_data/face_reenactment[1.0.0].vnnmodel"].UTF8String,
    };
    const int face_reenactment_argc = sizeof(face_reenactment_argv)/sizeof(face_reenactment_argv[0]);
    VNN_Create_FaceReenactment(&_handle, face_reenactment_argc, face_reenactment_argv);
    const char *_driving_json_path = (const char *)[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_face_reenactment_data/driving.kps.json"].UTF8String;
    VNN_Set_FaceReenactment_Attr(_handle, "_kpJsonsPath", _driving_json_path);
    
    size_t outDataSize = FACE_CHANNEL *  FACE_HEIGHT * FACE_WIDTH;
    _outBuffer = VnnU8BufferPtr(new VnnU8Buffer(outDataSize));
    
    size_t rgbaDataSize = FACE_HEIGHT * FACE_WIDTH * 4;
    _bgraBuffer = VnnU8BufferPtr(new VnnU8Buffer(rgbaDataSize));
    
    _mtltexture_face = [self.mtkView
                        generateOffScreenTextureWithFormat:MTLPixelFormatBGRA8Unorm
                        width:FACE_WIDTH
                        height:FACE_HEIGHT];
#   endif
}

- (void)windowShouldClose:(NSNotification *)notification {
    [super windowShouldClose:notification];
#   if USE_FACE_REENACTMENT && USE_FACE
    VNN_Destroy_Face(&_face_handle);
    VNN_Destroy_FaceReenactment(&_handle);
#   endif
    [[NSApplication sharedApplication] stopModal];
}

- (void)processPictureBuffer:(CVPixelBufferRef)pixelBuffer URL:(NSURL *)url {
    if(self.is_first_run){
        [self.reRunBtn setHidden:NO];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [NSAlert alertWithMessageText:@"Demo Usage" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", @"This Demo will pick a face randomly(if exist) and generate a new random emotion. Click the \"ReRun\" Button to generate more emotions for the same picture"];
            [alert beginSheetModalForWindow:[NSApp mainWindow] completionHandler: nil];
        });
        self.is_first_run = false;
    }
    self.imgURL = url;
    [self processPictureBufferCore:pixelBuffer URL:url];
}

- (void)processPictureBufferCore:(CVPixelBufferRef)pixelBuffer URL:(NSURL *)url {
#   if USE_FACE_REENACTMENT && USE_FACE
    if (_handle > 0 && _face_handle > 0) {
        VNN_Image input;
        VNN_Create_VNNImage_From_PixelBuffer(pixelBuffer, &input, false);
        input.mode_fmt = VNN_MODE_FMT_PICTURE;
        input.ori_fmt = VNN_ORIENT_FMT_DEFAULT;
        
        VNN_FaceFrameDataArr face_data, detection_data;
        VNN_Apply_Face_CPU(_face_handle, &input, &face_data);
        
        if(face_data.facesNum == 0){
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert *alert = [NSAlert alertWithMessageText:@"No Face Detectd" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", @"Face Reenactment need a picture containing at least ONE face"];
                [alert beginSheetModalForWindow:[NSApp mainWindow] completionHandler: nil];
            });
            return;
        }
        
        VNN_Get_Face_Attr(_face_handle, "_detection_data", &detection_data);
        
        int selected_face_idx = arc4random() % face_data.facesNum;
        
        VNN_Rect2D vnn_rect = detection_data.facesArr[selected_face_idx].faceRect;
        
        VNN_Set_FaceReenactment_Attr(_handle, "_faceRect", &vnn_rect);
        
        VNN_Set_FaceReenactment_Attr(_handle, "_targetImage", &input);
        
        int frameCount = 0;
        VNN_Get_FaceReenactment_Attr(_handle, "_frameCount", &frameCount);
        
        VNN_Image faceImg;
        faceImg.width = FACE_WIDTH;
        faceImg.height = FACE_HEIGHT;
        faceImg.channels = FACE_CHANNEL;
        faceImg.pix_fmt = VNN_PIX_FMT_RGB888;
        faceImg.data = _outBuffer.get()->data;
        
        int selected_emotion_idx = arc4random() % frameCount + 1; // valid emotion index range [1, frameCount]
        VNN_Apply_FaceReenactment_CPU(_handle, &selected_emotion_idx, &faceImg);
        
        const size_t face_n_pixel = FACE_HEIGHT * FACE_WIDTH;
        convertRGBToBGRA(_outBuffer.get()->data, _bgraBuffer.get()->data, face_n_pixel);
        [_mtltexture_face replaceRegion:MTLRegionMake2D(0, 0, FACE_WIDTH, FACE_HEIGHT)
                            mipmapLevel:0 withBytes:_bgraBuffer.get()->data bytesPerRow:FACE_WIDTH*4];
        
        self.mtkView.mtltexture_offScreenImage = [self.mtkView generateOffScreenTextureFromImageURL:url];
        
        id <MTLCommandBuffer> mtlCmdBuff = [self.mtkView.mtlCmdQueue commandBuffer];
        
        rectBox mtl_rect;
        mtl_rect.x0 = faceImg.rect.x0;
        mtl_rect.y0 = faceImg.rect.y0;
        mtl_rect.x1 = faceImg.rect.x1;
        mtl_rect.y1 = faceImg.rect.y1;
        
        [self.mtkView renderRectTextureToBackground_With_MTLCommandBuffer:mtlCmdBuff
                                                              rectTexture:_mtltexture_face
                                                                  rectBox:mtl_rect
                                                         offScreenTexture:self.mtkView.mtltexture_offScreenImage
                                                              clearScreen:false];
        [mtlCmdBuff commit];
        [mtlCmdBuff waitUntilScheduled];
    }
#   endif
}

@end
