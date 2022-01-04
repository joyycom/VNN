//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "WindowCtrl_Picture_GeneralClassification.h"
#import "vnnimage_mac_kit.h"
#include <string>
#include <sstream>
#include <vector>
#import "vnn_kit.h"
#import "OSXDemoHelper.h"

#if USE_CLASSIFYING
#   import "vnn_classifying.h"
#endif

#if USE_FACE
#   import "vnn_face.h"
#endif

@interface WindowCtrl_Picture_GeneralClassification ()
@property (nonatomic, assign) VNNHandle handle;
@property (nonatomic, assign) VNNHandle handle_face;
@property (nonatomic, retain) NSString* task;
@property (nonatomic, retain) NSString* model;
@property (nonatomic, retain) NSString* cfg;
@property (nonatomic, retain) NSString* label;
@end

#define N_LABEL_DISPLAY_AREA        (5)
#define TOP_N                       (5)
#define SCREEN_WIDTH                (1280)
#define SCREEN_HEIGHT               (720)
#define LABEL_DISPLAY_AREA_WIDTH    (SCREEN_WIDTH/4)
#define LABEL_DISPLAY_AREA_HEIGHT   (SCREEN_HEIGHT/N_LABEL_DISPLAY_AREA)

@implementation WindowCtrl_Picture_GeneralClassification

- (instancetype)initWithRootViewController:(NSViewController *)rootViewController
                          WithFunctionType:(NSString *)type{
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        _task = type;
        if([type isEqual:@"Scene&Weather"]){
            _model = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_classification_data/scene_weather[1.0.0].vnnmodel"];
            _label = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_classification_data/scene_weather[1.0.0]_label.json"];
        }
        else if([type isEqual:@"PersonAttribute"]){
            _model = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_classification_data/person_attribute[1.0.0].vnnmodel"];
            _label = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_classification_data/person_attribute[1.0.0]_label.json"];
        }
        else if([type isEqual:@"Object"]){
            _model = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_classification_data/object_classification[1.0.0].vnnmodel"];
            _label = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_classification_data/object_classification[1.0.0]_label.json"];
        }
        else{
            NSAssert(false, @"Error Function Type");
        }
    }
    [self initModel];
    return self;
}

- (void)initModel{
    VNN_SetLogLevel(VNN_LOG_LEVEL_ALL);
    
#   if USE_CLASSIFYING
    const void *argv[] = { _model.UTF8String};
    const int argc = sizeof(argv)/sizeof(argv[0]);
    VNN_Create_Classifying(&_handle, argc, argv);
    if(_handle){
        VNN_Set_Classifying_Attr(_handle, "_classLabelPath", _label.UTF8String);
    }
#   endif
    
    if([_task isEqual:@"PersonAttribute"]){
#if USE_FACE
        const void *argv[] = {
            [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/files/models/vnn_face278_data/face_pc[1.0.0].vnnmodel"].UTF8String,
        };
        const int argc = sizeof(argv)/sizeof(argv[0]);
        VNN_Create_Face(&_handle_face, argc, argv);
#endif
    }
}

- (void)windowShouldClose:(NSNotification *)notification {
    [super windowShouldClose:notification];
#   if USE_CLASSIFYING
    VNN_Destroy_Classifying(&_handle);
#   endif
    if([_task isEqual:@"PersonAttribute"]){
#   if USE_FACE
        VNN_Destroy_Face(&_handle_face);
#   endif
    }
    [[NSApplication sharedApplication] stopModal];
}

- (void)processPictureBuffer:(CVPixelBufferRef)pixelBuffer URL:(NSURL *)url {
    
#   if USE_CLASSIFYING
    if (_handle) {
        
        VNN_Image input;
        VNN_Create_VNNImage_From_PixelBuffer(pixelBuffer, &input, false);
        input.mode_fmt = VNN_MODE_FMT_PICTURE;
        input.ori_fmt = VNN_ORIENT_FMT_DEFAULT;
        
        int oriImageWidth = input.width;
        int oriImageHeight = input.height;
        float normLabel_x0;
        
        if(oriImageWidth > oriImageHeight){
            normLabel_x0 = 0.5f;
        }
        else{
            CGFloat resizedW = oriImageWidth * (SCREEN_HEIGHT) / oriImageHeight;
            CGFloat normResizedW = resizedW / SCREEN_WIDTH;
            normLabel_x0 = .5f + (.5f - normResizedW)/2;
        }
        NSMutableArray<DrawImage *> *labelImageArr = [NSMutableArray array];
        
        
        VNN_MultiClsTopNAccArr outResult;
        if([_task isEqual:@"PersonAttribute"]){
            NSAssert(_handle_face, @"To get Person Attribute, Face SDK is required and initialized correctly.");
#   if USE_FACE
            VNN_FaceFrameDataArr face_data, detection_data;
            VNN_Apply_Face_CPU(_handle_face, &input, &face_data);
            VNN_Get_Face_Attr(_handle_face, "_detection_data", &detection_data);
            
            if(face_data.facesNum>0){
                VNN_Apply_Classifying_CPU(_handle, &input, &detection_data, &outResult);
            }
            NSMutableArray<DrawRect2D *> *  rects =     [NSMutableArray array];
            for (auto f = 0; f < face_data.facesNum; f+=1) {
                float r,g,b;
                getColorByIdx(f, &r, &g, &b);
                auto face = face_data.facesArr[f];
                auto faceRect = [[DrawRect2D alloc] init];
                [faceRect setLeft:face.faceRect.x0];
                [faceRect setTop:face.faceRect.y0];
                [faceRect setRight:face.faceRect.x1];
                [faceRect setBottom:face.faceRect.y1];
                [faceRect setThickness:0.0015f];
                [faceRect setColor:[NSColor colorWithRed:r green:g blue:b alpha:1.f]];
                [rects addObject:faceRect];
            }
            id <MTLCommandBuffer> mtlCmdBuff = [self.mtkView.mtlCmdQueue commandBuffer];
            [self.mtkView drawHollowRect2DToOffscreen_With_MTLCommandBuffer:mtlCmdBuff
                                                                    Rect2Ds:rects
                                                           offScreenTexture:self.mtkView.mtltexture_srcImage
                                                                clearScreen:false];
            [mtlCmdBuff commit];
            [mtlCmdBuff waitUntilScheduled];
#   endif
        }
        else{
            VNN_Apply_Classifying_CPU(_handle, &input, NULL, &outResult);
        }
        VNN_Free_VNNImage(pixelBuffer, &input, false);
        
        
        
        int N_ACTUAL_DISPLAY_AREA = 0;
        if([self->_task isEqual:@"Object"]){
            N_ACTUAL_DISPLAY_AREA = 1;
            for(int i = 0; i < N_ACTUAL_DISPLAY_AREA; i++){
                std::vector<std::string> outStrVec{"Object"};
                for(int j=0; j < TOP_N; j++){
                    std::string outStr = outResult.multiClsArr[0].clsArr[0].labels[j];
                    outStr += prob2str(outResult.multiClsArr[0].clsArr[0].probabilities[j]);
                    outStrVec.push_back(outStr);
                }
                NSImage * labelImage = [self genLabelNSImageWithText:outStrVec AtPositionIndex:i];
                
                DrawImage* drawLabelImage = [[DrawImage alloc] init];
                [drawLabelImage setLeft:normLabel_x0];
                [drawLabelImage setRight:normLabel_x0 + 0.25];
                [drawLabelImage setTop: (N_LABEL_DISPLAY_AREA - i -1) * 1.f/ N_LABEL_DISPLAY_AREA];
                [drawLabelImage setBottom: (N_LABEL_DISPLAY_AREA - i) * 1.f/ N_LABEL_DISPLAY_AREA];
                [drawLabelImage setImg:labelImage];
                [labelImageArr addObject:drawLabelImage];
            }
        }
        else if([self->_task isEqual:@"Scene&Weather"]){
            N_ACTUAL_DISPLAY_AREA = 2;
            for(int i = 0; i < N_ACTUAL_DISPLAY_AREA; i++){
                std::vector<std::string> outStrVec{i == 0 ? "Weather" : "Scene"};
                for(int j=0; j < TOP_N; j++){
                    std::string outStr = outResult.multiClsArr[0].clsArr[i].labels[j];
                    outStr += prob2str(outResult.multiClsArr[0].clsArr[i].probabilities[j]);
                    outStrVec.push_back(outStr);
                }
                NSImage * labelImage = [self genLabelNSImageWithText:outStrVec AtPositionIndex:i];
                
                DrawImage* drawLabelImage = [[DrawImage alloc] init];
                [drawLabelImage setLeft:normLabel_x0];
                [drawLabelImage setRight:normLabel_x0 + 0.25];
                [drawLabelImage setTop: (N_LABEL_DISPLAY_AREA - i -1) * 1.f/ N_LABEL_DISPLAY_AREA];
                [drawLabelImage setBottom: (N_LABEL_DISPLAY_AREA - i) * 1.f/ N_LABEL_DISPLAY_AREA];
                [drawLabelImage setImg:labelImage];
                [labelImageArr addObject:drawLabelImage];
            }
        }
        else if([self->_task isEqual:@"PersonAttribute"]){
            N_ACTUAL_DISPLAY_AREA = outResult.numOut;
            for(int i = 0; i < N_ACTUAL_DISPLAY_AREA; i++){
                std::vector<std::string> outStrVec;
                outStrVec.push_back("Gender");
                outStrVec.push_back(outResult.multiClsArr[i].clsArr[0].labels[0]);
                outStrVec[1] += prob2str(outResult.multiClsArr[i].clsArr[0].probabilities[0]);
                outStrVec.push_back("");
                
                outStrVec.push_back("Beauty");
                outStrVec.push_back(outResult.multiClsArr[i].clsArr[1].labels[0]);
                outStrVec[4] += prob2str(outResult.multiClsArr[i].clsArr[1].probabilities[0]);
                outStrVec.push_back("");
                
                outStrVec.push_back("Age");
                outStrVec.push_back(outResult.multiClsArr[i].clsArr[2].labels[0]);
                outStrVec[7] += prob2str(outResult.multiClsArr[i].clsArr[2].probabilities[0]);
                
                NSImage * labelImage = [self genLabelNSImageWithText:outStrVec AtPositionIndex:i];
                
                DrawImage* drawLabelImage = [[DrawImage alloc] init];
                [drawLabelImage setLeft:normLabel_x0];
                [drawLabelImage setRight:normLabel_x0 + 0.25];
                [drawLabelImage setTop: (N_LABEL_DISPLAY_AREA - i -1) * 1.f/ N_LABEL_DISPLAY_AREA];
                [drawLabelImage setBottom: (N_LABEL_DISPLAY_AREA - i) * 1.f/ N_LABEL_DISPLAY_AREA];
                [drawLabelImage setImg:labelImage];
                [labelImageArr addObject:drawLabelImage];
            }
        }
        [self.mtkView setImgs:labelImageArr];
    }
    
#   endif
}

-(NSImage *) genLabelNSImageWithText:(std::vector<std::string>)textVec AtPositionIndex:(const int)idx {
    NSSize rectSize = NSMakeSize(LABEL_DISPLAY_AREA_WIDTH, LABEL_DISPLAY_AREA_HEIGHT);
    NSImage* labelImage =  [[NSImage alloc] initWithSize: rectSize];
    [labelImage lockFocus];
    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGFloat bgColorCompoment[] = {1.f, 1.f, 1.f, 1.f};
    CGColorRef bgColor = CGColorCreate(CGColorSpaceCreateDeviceRGB(), bgColorCompoment);
    CGContextSetFillColorWithColor(context, bgColor);
    CGRect rect = CGRectMake( 0.0, 0.0, LABEL_DISPLAY_AREA_WIDTH, LABEL_DISPLAY_AREA_HEIGHT);
    CGContextFillRect(context, rect);
    float r, g, b;
    getColorByIdx(idx, &r, &g, &b);
    [OSXDemoHelper drawTextToNSImage:context
                            WithText:textVec
                            FontSize:15
                               FontR:r
                               FontG:g
                               FontB:b
                               FontX:20
                               FontY:LABEL_DISPLAY_AREA_HEIGHT - 20];
    [labelImage unlockFocus];
    return labelImage;
}

static void getColorByIdx(int idx, float* r, float* g, float* b){
    switch(idx){
        case 0: // greenColor
            *r = 0.f;
            *g = 1.f;
            *b = 0.f;
            break;
        case 1: // blueColor
            *r = 0.f;
            *g = 0.f;
            *b = 1.f;
            break;
        case 2: // purpleColor
            *r = 0.5f;
            *g = 0.f;
            *b = 0.5f;
            break;
        case 3: // redColor
            *r = 1.f;
            *g = 0.f;
            *b = 0.f;
            break;
        case 4: // orangeColor
            *r = 1.f;
            *g = 0.5f;
            *b = 0.f;
    }
}

static std::string prob2str(float prob){
    std::ostringstream oss;
    oss.precision(2);
    oss<< " (" << floor(prob * 100)/100 << ")";
    return oss.str();
}

@end
