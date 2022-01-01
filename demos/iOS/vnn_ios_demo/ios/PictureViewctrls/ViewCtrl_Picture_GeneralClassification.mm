//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "ViewCtrl_Picture_GeneralClassification.h"
#import "vnnimage_ios_kit.h"
#import "DemoHelper.h"
#import "vnn_kit.h"

#if USE_CLASSIFYING
#   import "vnn_classifying.h"
#endif

#if USE_FACE
#   import "vnn_face.h"
#endif

@interface ViewCtrl_Picture_GeneralClassification ()
@property (nonatomic, assign) VNNHandle handle;
@property (nonatomic, assign) VNNHandle handle_face;
@property (nonatomic, retain) NSString* task;
@property (nonatomic, retain) NSString* model;
@property (nonatomic, retain) NSString* cfg;
@property (nonatomic, retain) NSString* label;
@property (nonatomic, strong) NSMutableArray<UILabel *> * textLabels;
@end

#define N_LABEL_DISPLAY_AREA 5
#define TOP_N 5
#define LABEL_DISPLAY_AREA_WIDTH (SCREEN_WIDTH/2)
#define LABEL_DISPLAY_AREA_HEIGHT (SCREEN_HEIGHT/N_LABEL_DISPLAY_AREA)

@implementation ViewCtrl_Picture_GeneralClassification

-(id)initWithFunctionType:(NSString *)type
{
    self = [super init] ;
    if (self) {
        _task = type;
        if([type isEqual:@"Scene&Weather"]){
            _model = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/files/models/vnn_classification_data/scene_weather[1.0.0].vnnmodel"];
            _label = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/files/models/vnn_classification_data/scene_weather[1.0.0]_label.json"];
        }
        else if([type isEqual:@"PersonAttribute"]){
            _model = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/files/models/vnn_classification_data/person_attribute[1.0.0].vnnmodel"];
            _label = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/files/models/vnn_classification_data/person_attribute[1.0.0]_label.json"];
        }
        else if([type isEqual:@"Object"]){
            _model = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/files/models/vnn_classification_data/object_classification[1.0.0].vnnmodel"];
            _label = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/files/models/vnn_classification_data/object_classification[1.0.0]_label.json"];
        }
        else{
            NSAssert(false, @"Error Function Type");
        }
    }
    return self;
}

- (void)viewDidLoad {
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
            [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"files/models/vnn_face278_data/face_mobile[1.0.0].vnnmodel"].UTF8String,
        };
        const int argc = sizeof(argv)/sizeof(argv[0]);
        VNN_Create_Face(&_handle_face, argc, argv);
#endif
    }
    
    [self initLabels];
    [super viewDidLoad];
}

- (void)onBtnBack {
    
#   if USE_CLASSIFYING
    VNN_Destroy_Classifying(&_handle);
#   endif
    if([_task isEqual:@"PersonAttribute"]){
        VNN_Destroy_Face(&_handle_face);
    }
    
    [super onBtnBack];
}

- (void) imageCaptureCallback:(CVPixelBufferRef)pixelBuffer {
    
#   if USE_CLASSIFYING
    if (_handle) {
        VNN_Image input;
        VNN_Create_VNNImage_From_PixelBuffer(pixelBuffer, &input, false);
        input.mode_fmt = VNN_MODE_FMT_PICTURE;
        input.ori_fmt = VNN_ORIENT_FMT_DEFAULT;
        
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
            
            [self.glUtils rectsDrawer]->_rects.clear();
            for(int i = 0; i < face_data.facesNum; i++){
                float r,g,b;
                getRectColor(i, &r, &g, &b);
                [self.glUtils rectsDrawer]->_rects.emplace_back(
                                                                vnn::renderkit::DrawRect2D(
                                                                                             MIN(1.f, MAX(0, face_data.facesArr[i].faceRect.x0)),     // left
                                                                                             MIN(1.f, MAX(0, face_data.facesArr[i].faceRect.y0)),    // top
                                                                                             MIN(1.f, MAX(0, face_data.facesArr[i].faceRect.x1)),    // right
                                                                                             MIN(1.f, MAX(0, face_data.facesArr[i].faceRect.y1)),    // bottom
                                                                                             3.f,                                // thickness
                                                                                           vnn::renderkit::DrawColorRGBA(b, g, r, 1.f)
                                                                                             )
                                                                );
            }
            
#   endif
        }
        else{
            VNN_Apply_Classifying_CPU(_handle, &input, NULL, &outResult);
        }
        
        VNN_Free_VNNImage(pixelBuffer, &input, false);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            int N_ACTUAL_DISPLAY_AREA = 0;
            if([self->_task isEqual:@"Object"]){
                N_ACTUAL_DISPLAY_AREA = 1;
                for(int i = 0; i < N_ACTUAL_DISPLAY_AREA; i++){
                    std::string outStr("Object\n");
                    for(int j=0; j < TOP_N; j++){
                        outStr += outResult.multiClsArr[0].clsArr[0].labels[j];
                        outStr += prob2str(outResult.multiClsArr[0].clsArr[0].probabilities[j]);
                        if(j < TOP_N - 1){
                            outStr += "\n";
                        }
                    }
                    [self.textLabels[i] setText:[NSString stringWithCString:outStr.c_str() encoding:[NSString defaultCStringEncoding]]];
                }
            }
            else if([self->_task isEqual:@"Scene&Weather"]){
                N_ACTUAL_DISPLAY_AREA = 2;
                for(int i = 0; i < N_ACTUAL_DISPLAY_AREA; i++){
                    std::string outStr;
                    outStr = i == 0 ? "Weather\n" : "Scene\n";
                    for(int j=0; j < TOP_N; j++){
                        outStr += outResult.multiClsArr[0].clsArr[i].labels[j];
                        outStr += prob2str(outResult.multiClsArr[0].clsArr[i].probabilities[j]);
                        if(j < TOP_N - 1){
                            outStr += "\n";
                        }
                    }
                    [self.textLabels[i] setText:[NSString stringWithCString:outStr.c_str() encoding:[NSString defaultCStringEncoding]]];
                }
            }
            else if([self->_task isEqual:@"PersonAttribute"]){
                N_ACTUAL_DISPLAY_AREA = outResult.numOut;
                for(int i = 0; i < N_ACTUAL_DISPLAY_AREA; i++){
                    std::string outStr;
                    outStr += "Gender\n";
                    outStr += outResult.multiClsArr[i].clsArr[0].labels[0];
                    outStr += prob2str(outResult.multiClsArr[i].clsArr[0].probabilities[0]);
                    outStr += "\n";
                    
                    outStr += "Beauty\n";
                    outStr += outResult.multiClsArr[i].clsArr[1].labels[0];
                    outStr += prob2str(outResult.multiClsArr[i].clsArr[1].probabilities[0]);
                    outStr += "\n";
                    
                    outStr += "Age\n";
                    outStr += outResult.multiClsArr[i].clsArr[2].labels[0];
                    outStr += prob2str(outResult.multiClsArr[i].clsArr[2].probabilities[0]);
                    
                    [self.textLabels[i] setText:[NSString stringWithCString:outStr.c_str() encoding:[NSString defaultCStringEncoding]]];
                }
            }
            for(int i = 0; i < N_LABEL_DISPLAY_AREA; i++){
                if(i < N_ACTUAL_DISPLAY_AREA){
                    [self.textLabels[i] setHidden:NO];
                    
                }
                else{
                    [self.textLabels[i] setHidden:YES];
                }
            }
        });
        
    }
#   endif
    
    NSInteger rotateType = UIView_GLRenderUtils_RotateType_None;
    NSInteger flipType = UIView_GLRenderUtils_FlipType_None;
    if (CVPixelBufferGetPlaneCount(pixelBuffer) != 0){
        [self.glUtils draw_With_YTexture:self.NSYTex UVTexture:self.NSUVTex RotateType:rotateType FlipType:flipType];
    } else {
        [self.glUtils draw_With_BGRATexture:self.NSBGRATex RotateType:rotateType FlipType:flipType];
    }
    
}

-(void)initLabels {
    _textLabels = [NSMutableArray arrayWithCapacity:N_LABEL_DISPLAY_AREA];
    for (auto k = 0; k < N_LABEL_DISPLAY_AREA; k++) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, LABEL_DISPLAY_AREA_WIDTH, LABEL_DISPLAY_AREA_HEIGHT)];
        switch (k){
            case 0:
                [label setTextColor:[UIColor greenColor]];
                break;
            case 1:
                [label setTextColor:[UIColor blueColor]];
                break;
            case 2:
                [label setTextColor:[UIColor purpleColor]];
                break;
            case 3:
                [label setTextColor:[UIColor redColor]];
                break;
            case 4:
                [label setTextColor:[UIColor orangeColor]];
                break;
        }
        float rect_top =  (ACTUAL_SCREEN_HEIGHT - SCREEN_HEIGHT) / 2 + LABEL_DISPLAY_AREA_HEIGHT* (N_LABEL_DISPLAY_AREA - k - 1);
        float rect_left = (ACTUAL_SCREEN_WIDTH - SCREEN_WIDTH) / 2;
        [label setFrame:CGRectMake(rect_left, rect_top, LABEL_DISPLAY_AREA_WIDTH, LABEL_DISPLAY_AREA_HEIGHT)];
        [label setFont:[[label font] fontWithSize:16]];
        [label setTextAlignment:NSTextAlignmentLeft];
        label.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.4];
        label.numberOfLines = 0;
        [label setHidden:YES];
        [_textLabels addObject:label];
        [self.view addSubview:label];
    }
}

static void getRectColor(int rect_idx, float* r, float* g, float* b){
    switch(rect_idx){
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
