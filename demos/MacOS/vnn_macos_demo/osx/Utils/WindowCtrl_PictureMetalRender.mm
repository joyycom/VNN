//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "WindowCtrl_PictureMetalRender.h"
#import "OSXDemoHelper.h"
#import "NSDrawElements.h"

#define WINDOW_HEIGHT (720)
#define WINDOW_WIDTH (1280)

@implementation ViewCtrl_PictureMetalRender
- (instancetype)initWithNibName:(NSNibName)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)];
    return [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}
@end

@implementation WindowCtrl_PictureMetalRender

- (instancetype)initWithRootViewController:(NSViewController *)rootViewController {
    self = [super init];
    if (self) {
        self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT) styleMask:(NSWindowStyleMaskTitled) backing:(NSBackingStoreBuffered) defer:YES];
        [self.window setWindowController:self];
        [self.window setMovableByWindowBackground:NO];
        [self.window setStyleMask:NSClosableWindowMask|NSTitledWindowMask];
        [[self.window standardWindowButton:NSWindowZoomButton] setHidden:YES];
        [[self.window standardWindowButton:NSWindowMiniaturizeButton] setHidden:YES];
        [self.window setReleasedWhenClosed:NO];
        self.contentViewController = rootViewController;
    }
    
    [self.window.contentView addSubview:self.mtkView];
    [self initBackGroundTextureWithWidth:WINDOW_WIDTH Height:WINDOW_HEIGHT];
    
    if(!self.openBtn){
        self.openBtn = [[NSButton alloc] initWithFrame:NSMakeRect(WINDOW_WIDTH - 150, 20, 96, 64)];
        self.openBtn.wantsLayer = YES;
        self.openBtn.bezelStyle = NSBezelStyleRegularSquare;
        [self.openBtn setTitle:@"Open"];
        [self.openBtn setAction: @selector(onOpenBtnClick)];
        [self.window.contentView  addSubview:self.openBtn];
    }
    
//    TODO: Surpport - Save OffScreen MeatlTexture to Image File
//    if(!self.saveBtn){
//        self.saveBtn = [[NSButton alloc] initWithFrame:NSMakeRect(WINDOW_WIDTH - 300, 20, 96, 64)];
//        self.saveBtn.wantsLayer = YES;
//        self.saveBtn.bezelStyle = NSBezelStyleRegularSquare;
//        [self.saveBtn setTitle:@"Save"];
//        [self.saveBtn setAction: @selector(onSaveBtnClick)];
//        [self.saveBtn setHidden:true];
//        [self.window.contentView  addSubview:self.saveBtn];
//    }
    
    [self.window.sheetParent endSheet:self.window];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowShouldClose:)
                                                 name:NSWindowWillCloseNotification
                                               object:nil];
    
    return self;
}

- (void)onOpenBtnClick {
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    
    [panel setAllowsOtherFileTypes:YES];
    [panel setAllowedFileTypes:@[@"jpg",@"png",@"jpeg"]];
    [panel setExtensionHidden:NO];
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
        if (result == NSModalResponseOK)
        {
            [self clearBackGroundTexture];

            self.mtkView.mtltexture_srcImage = [self.mtkView generateOffScreenTextureFromImageURL:[panel URL]];
            
            if(self.mtkView.mtltexture_srcImage == nil){
                NSAlert *alert = [NSAlert alertWithMessageText:@"Image Open Failed" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", @"Please retry with another image"];
                [alert beginSheetModalForWindow:[NSApp mainWindow] completionHandler: nil];
                return;
            }
            
            if(self.mtkView.mtltexture_srcImage.pixelFormat != MTLPixelFormatBGRA8Unorm){
                NSAlert *alert = [NSAlert alertWithMessageText:@"Not Support Image" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", @"VNN Demo currently does not support images of graysacle or 16bit color mode，please retry with another image"];
                [alert beginSheetModalForWindow:[NSApp mainWindow] completionHandler: nil];
                return;
            }
            
            CGFloat oriImageWidth = self.mtkView.mtltexture_srcImage.width;
            CGFloat oriImageHeight = self.mtkView.mtltexture_srcImage.height;
            
            unsigned char* dataBuffer = (unsigned char *)malloc(oriImageWidth*oriImageHeight*4);
            CVPixelBufferRef pixelBuffer = [self.mtkView createPixelBufferFromBGRAMTLTexture:self.mtkView.mtltexture_srcImage UseDataBuffer:dataBuffer];
            [self processPictureBuffer:pixelBuffer URL:[panel URL]];
            CVPixelBufferRelease(pixelBuffer);
            free(dataBuffer);
            
            rectBox originalImageRegion, effectImageRegion;
            if(oriImageWidth > oriImageHeight){
                originalImageRegion.x0 = 0.f;
                originalImageRegion.x1 = .5f;
                effectImageRegion.x0 = .5f;
                effectImageRegion.x1 = 1.f;
                
                CGFloat resizedH = oriImageHeight * (WINDOW_WIDTH/2) / oriImageWidth;
                CGFloat normResizedH = resizedH / WINDOW_HEIGHT;
                
                originalImageRegion.y0 = (1.f - normResizedH)/2;
                originalImageRegion.y1 = 1.f - ((1.f - normResizedH)/2);
                effectImageRegion.y0 = originalImageRegion.y0;
                effectImageRegion.y1 = originalImageRegion.y1;
            }
            else{
                originalImageRegion.y0 = 0.f;
                originalImageRegion.y1 = 1.f;
                effectImageRegion.y0 = 0.f;
                effectImageRegion.y1 = 1.f;
                
                CGFloat resizedW = oriImageWidth * (WINDOW_HEIGHT) / oriImageHeight;
                CGFloat normResizedW = resizedW / WINDOW_WIDTH;
                
                originalImageRegion.x0 = (.5f - normResizedW)/2;
                originalImageRegion.x1 = .5f - (.5f - normResizedW)/2;
                effectImageRegion.x0 = .5f + (.5f - normResizedW)/2;
                effectImageRegion.x1 = 1.f - (.5f - normResizedW)/2;
            }
            
            id <MTLCommandBuffer> mtlCmdBuff = [self.mtkView.mtlCmdQueue commandBuffer];
            [self.mtkView renderRectTextureToBackground_With_MTLCommandBuffer:mtlCmdBuff
                                                                  rectTexture:self.mtkView.mtltexture_srcImage
                                                                      rectBox:originalImageRegion
                                                             offScreenTexture:self.mtkView.mtltexture_BGRA
                                                                  clearScreen:false];
            if(self.mtkView.mtltexture_offScreenImage){
                [self.mtkView renderRectTextureToBackground_With_MTLCommandBuffer:mtlCmdBuff
                                                                      rectTexture:self.mtkView.mtltexture_offScreenImage
                                                                          rectBox:effectImageRegion
                                                                 offScreenTexture:self.mtkView.mtltexture_BGRA
                                                                      clearScreen:false];
                // TODO: Surpport - Save OffScreen MeatlTexture to Image File
                // [self.saveBtn setHidden:false];
            }
            
            [mtlCmdBuff commit];
            [mtlCmdBuff waitUntilScheduled];
            [self.mtkView draw];
        }
    }];
}

// TODO: Surpport - Save OffScreen MeatlTexture to Image File
//- (void)onSaveBtnClick {
//    NSSavePanel *panel = [NSSavePanel savePanel];
//
//    [panel setAllowsOtherFileTypes:YES];
//    [panel setAllowedFileTypes:@[@"png"]];
//    [panel setExtensionHidden:NO];
//    [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
//        if (result == NSModalResponseOK)
//        {
//            NSString *path = [[panel URL] path];
//            int height = int(self.mtkView.mtltexture_offScreenImage.height);
//            int width  = int(self.mtkView.mtltexture_offScreenImage.width);
//            unsigned char *buffer = (unsigned char *)malloc(height * width * 4);
//
//            [self.mtkView.mtltexture_offScreenImage getBytes:buffer bytesPerRow:width*4 fromRegion:MTLRegionMake2D(0, 0, width, height) mipmapLevel:0];
//
//            NSImage* saveImage = [OSXDemoHelper U8RGBABufferToNSImage:buffer withHeight:height withWidth:width];
//
//            free(buffer);
//            [OSXDemoHelper saveNSImage:saveImage atPath:path];
//
//        }
//    }];
//}

- (void)windowShouldClose:(NSNotification *)notification {
    self.mtkView = nil;
    self.openBtn = nil;
    self.saveBtn = nil;
    self.window = nil;
    self.contentViewController = nil;
}

- (MTKViewX *)mtkView {
    if (!_mtkView) {
        _mtkView = [[MTKViewX alloc] initWithFrame:CGRectMake(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT) device:MTLCreateSystemDefaultDevice()];
        [_mtkView setPaused:YES];
        [_mtkView setNeedsDisplay:NO];
        [_mtkView setAutoResizeDrawable:YES];
        [_mtkView setDrawableSize:CGSizeMake(WINDOW_WIDTH, WINDOW_HEIGHT)];
        [_mtkView setMirror:false];
    }
    return _mtkView;
}

- (void)initBackGroundTextureWithWidth:(int)width Height:(int)height {
    _mtkView.mtltexture_BGRA= [_mtkView generateOffScreenTextureWithFormat:MTLPixelFormatBGRA8Unorm width:width height:height];
    [self clearBackGroundTexture];
}

- (void)clearBackGroundTexture{
    if(_mtkView.mtltexture_BGRA == nil){
        return;
    }
    int width = int(_mtkView.mtltexture_BGRA.width);
    int height = int(_mtkView.mtltexture_BGRA.height);
    const size_t dataSize = width * height * 4;
    unsigned char* bgColorBuffer = (unsigned char *)malloc(dataSize);
    memset(bgColorBuffer, 32, dataSize);
    [_mtkView.mtltexture_BGRA replaceRegion:MTLRegionMake2D(0, 0, width, height) mipmapLevel:0 withBytes:bgColorBuffer bytesPerRow:width * 4];
    free(bgColorBuffer);
}

- (void)processPictureBuffer:(CVPixelBufferRef)pixelBuffer URL:(NSURL *)url{
}

@end
