//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "ViewController.h"
#import "utils/DemoHelper.h"
#import "utils/ViewCtrl_Camera_GLRenderBase.h"
#import "CameraViewctrls/ViewCtrl_Camera_Face.h"
#import "CameraViewctrls/ViewCtrl_Camera_Gesture.h"
#import "CameraViewctrls/ViewCtrl_Camera_DocRect.h"
#import "CameraViewctrls/ViewCtrl_Camera_FaceCount_QRCodeDetect.h"
#import "CameraViewctrls/ViewCtrl_Camera_ObjectTracking.h"
#import "CameraViewctrls/ViewCtrl_Camera_FaceSegment.h"
#import "CameraViewctrls/ViewCtrl_Camera_GeneralSegment.h"
#import "CameraViewctrls/ViewCtrl_Camera_HeadSegment.h"
#import "CameraViewctrls/ViewCtrl_Camera_CartoonStylizing_ComicStylizing.h"
#import "CameraViewctrls/ViewCtrl_Camera_DisneyFaceStylizing.h"
#import "CameraViewctrls/ViewCtrl_Camera_3DGameFaceStylizing.h"
#import "CameraViewctrls/ViewCtrl_Camera_GeneralClassification.h"
#import "CameraViewctrls/ViewCtrl_Camera_PoseLandmarkDetection.h"

#import "PictureViewctrls/ViewCtrl_Picture_Face.h"
#import "PictureViewctrls/ViewCtrl_Picture_Gesture.h"
#import "PictureViewctrls/ViewCtrl_Picture_3DGameFaceStylizing.h"
#import "PictureViewctrls/ViewCtrl_Picture_DisneyFaceStylizing.h"
#import "PictureViewctrls/ViewCtrl_Picture_HeadSegment.h"
#import "PictureViewctrls/ViewCtrl_Picture_GeneralSegment.h"
#import "PictureViewctrls/ViewCtrl_Picture_FaceSegment.h"
#import "PictureViewctrls/ViewCtrl_Picture_FaceCount_QRCodeDetect.h"
#import "PictureViewctrls/ViewCtrl_Picture_CartoonStylizing_ComicStylizing.h"
#import "PictureViewctrls/ViewCtrl_Picture_DocRect.h"
#import "PictureViewctrls/ViewCtrl_Picture_GeneralClassification.h"
#import "PictureViewctrls/ViewCtrl_Picture_FaceReenactment.h"
#import "PictureViewctrls/ViewCtrl_Picture_PoseLandmarkDetection.h"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>
@property(nonatomic, strong) UIImageView *                                          Logo;
@property(nonatomic, strong) UILabel *                                              versionInfo;
@property(nonatomic, strong) UITableView *                                          mainTableView;
@property(nonatomic, strong) NSMutableArray<NSString *> *                           mainViewCtrlNames;
@property(nonatomic, strong) NSMutableArray *                                       mainCameraDemoViewCtrlObjs;
@property(nonatomic, strong) NSMutableArray *                                       mainPictureDemoViewCtrlObjs;
@end

@implementation ViewController

- (void)loadView {
    [super loadView];
    [self.view addSubview:self.Logo];
    [self.view addSubview:self.versionInfo];
    [self.view addSubview:self.mainTableView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (!_mainCameraDemoViewCtrlObjs && !_mainPictureDemoViewCtrlObjs && !_mainViewCtrlNames) {
        _mainCameraDemoViewCtrlObjs = [[NSMutableArray alloc] init];
        _mainPictureDemoViewCtrlObjs = [[NSMutableArray alloc] init];
        _mainViewCtrlNames = [[NSMutableArray alloc] init];
        
#       if USE_FACE
        [_mainCameraDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Camera_Face alloc] init];
        }];
        [_mainPictureDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Picture_Face alloc] init];
        }];
        [_mainViewCtrlNames addObject:@"Face Landmark Detection"];
#       endif
        
#       if USE_FACE && USE_FACE_PARSER
        [_mainCameraDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Camera_DisneyFaceStylizing alloc] init];
        }];
        [_mainPictureDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Picture_DisneyFaceStylizing  alloc] init];
        }];
        [_mainViewCtrlNames addObject:@"Disney Face Stylizing"];
#       endif
        
#       if USE_FACE && USE_STYLIZING
        [_mainCameraDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Camera_3DGameFaceStylizing alloc] init];
        }];
        [_mainPictureDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Picture_3DGameFaceStylizing alloc] init];
        }];
        [_mainViewCtrlNames addObject:@"3D Game Face Stylizing"];
#       endif
        
#       if USE_GENERAL
        [_mainCameraDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Camera_CartoonStylizing_ComicStylizing alloc] initWithStyleType:@"Cartoon"];
        }];
        [_mainPictureDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Picture_CartoonStylizing_ComicStylizing alloc] initWithStyleType:@"Cartoon"];
        }];
        [_mainViewCtrlNames addObject:@"Cartoon Stylizing"];
#       endif
        
#       if USE_GENERAL
        [_mainCameraDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Camera_CartoonStylizing_ComicStylizing alloc] initWithStyleType:@"Comic"];
        }];
        [_mainPictureDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Picture_CartoonStylizing_ComicStylizing alloc] initWithStyleType:@"Comic"];
        }];
        [_mainViewCtrlNames addObject:@"Comic Stylizing"];
#       endif
        
#       if USE_GENERAL
        [_mainCameraDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Camera_GeneralSegment alloc] initWithSegmentType:@"HQ_Portrait"];
        }];
        [_mainPictureDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Picture_GeneralSegment alloc] initWithSegmentType:@"HQ_Portrait"];
        }];
        [_mainViewCtrlNames addObject:@"High Quality Portrait Segmentation"];
#       endif
        
#       if USE_GENERAL
        [_mainCameraDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Camera_GeneralSegment alloc] initWithSegmentType:@"Fast_Portrait"];
        }];
        [_mainPictureDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Picture_GeneralSegment alloc] initWithSegmentType:@"Fast_Portrait"];
        }];
        [_mainViewCtrlNames addObject:@"Fast Portrait Segmentation"];
#       endif
        
#       if USE_FACE && USE_FACE_PARSER
        [_mainCameraDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Camera_FaceSegment alloc] init];
        }];
        [_mainPictureDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Picture_FaceSegment alloc] init];
        }];
        [_mainViewCtrlNames addObject:@"Face Segmentation"];
#       endif
        
#       if USE_GENERAL
        [_mainCameraDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Camera_HeadSegment alloc] init];
        }];
        [_mainPictureDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Picture_HeadSegment alloc] init];
        }];
        [_mainViewCtrlNames addObject:@"Head Segmentation"];
#       endif
        
#       if USE_GENERAL
        [_mainCameraDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Camera_GeneralSegment alloc] initWithSegmentType:@"Hair"];
        }];
        [_mainPictureDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Picture_GeneralSegment alloc] initWithSegmentType:@"Hair"];
        }];
        [_mainViewCtrlNames addObject:@"Hair Segmentation"];
#       endif
        
#       if USE_GENERAL
        [_mainCameraDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Camera_GeneralSegment alloc] initWithSegmentType:@"Clothes"];
        }];
        [_mainPictureDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Picture_GeneralSegment alloc] initWithSegmentType:@"Clothes"];
        }];
        [_mainViewCtrlNames addObject:@"Clothes Segmentation"];
#       endif
        
#       if USE_GENERAL
        [_mainCameraDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Camera_GeneralSegment alloc] initWithSegmentType:@"Sky"];
        }];
        [_mainPictureDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Picture_GeneralSegment alloc] initWithSegmentType:@"Sky"];
        }];
        [_mainViewCtrlNames addObject:@"Sky Segmentation"];
#       endif
        
#       if USE_GENERAL
        [_mainCameraDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Camera_GeneralSegment alloc] initWithSegmentType:@"Animal"];
        }];
        [_mainPictureDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Picture_GeneralSegment alloc] initWithSegmentType:@"Animal"];
        }];
        [_mainViewCtrlNames addObject:@"Animal Segmentation"];
#       endif
        
#       if USE_GESTURE
        [_mainCameraDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Camera_Gesture alloc] init];
        }];
        [_mainPictureDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Picture_Gesture alloc] init];
        }];
        [_mainViewCtrlNames addObject:@"Gesture Detection"];
#       endif
        
#       if USE_POSE
        [_mainCameraDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Camera_PoseLandmarkDetection alloc] init];
        }];
        [_mainPictureDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Picture_PoseLandmarkDetection alloc] init];
        }];
        [_mainViewCtrlNames addObject:@"Pose Landmark Detection"];
#       endif
        
#       if USE_OBJCOUNT
        [_mainCameraDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Camera_FaceCount_QRCodeDetect alloc] initWithFunctionType:@"QRCodeDetect"];
        }];
        [_mainPictureDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Picture_FaceCount_QRCodeDetect alloc] initWithFunctionType:@"QRCodeDetect"];
        }];
        [_mainViewCtrlNames addObject:@"QR Code Detection"];
#       endif
        
#       if USE_OBJCOUNT
        [_mainCameraDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Camera_FaceCount_QRCodeDetect alloc] initWithFunctionType:@"FaceCount"];
        }];
        [_mainPictureDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Picture_FaceCount_QRCodeDetect alloc] initWithFunctionType:@"FaceCount"];
        }];
        [_mainViewCtrlNames addObject:@"Face Count"];
#       endif
        
#       if USE_DOCRECT
        [_mainCameraDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Camera_DocRect alloc] init];
        }];
        [_mainPictureDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Picture_DocRect alloc] init];
        }];
        [_mainViewCtrlNames addObject:@"Document Rectifying"];
#       endif
        
#       if USE_CLASSIFYING
        [_mainCameraDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Camera_GeneralClassification alloc] initWithFunctionType:@"Scene&Weather"];
        }];
        [_mainPictureDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Picture_GeneralClassification alloc] initWithFunctionType:@"Scene&Weather"];
        }];
        [_mainViewCtrlNames addObject:@"Scene&Weather Recognition"];
#       endif
        
#       if USE_CLASSIFYING && USE_FACE
        [_mainCameraDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Camera_GeneralClassification alloc] initWithFunctionType:@"PersonAttribute"];
        }];
        [_mainPictureDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Picture_GeneralClassification alloc] initWithFunctionType:@"PersonAttribute"];
        }];
        [_mainViewCtrlNames addObject:@"Person Attribute Recognition"];
#       endif
        
#       if USE_CLASSIFYING
        [_mainCameraDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Camera_GeneralClassification alloc] initWithFunctionType:@"Object"];
        }];
        [_mainPictureDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Picture_GeneralClassification alloc] initWithFunctionType:@"Object"];
        }];
        [_mainViewCtrlNames addObject:@"Vlog Object Recognition"];
#       endif
        
#if     USE_FACE_REENACTMENT && USE_FACE
        [_mainCameraDemoViewCtrlObjs addObject:[NSNull null]];
        [_mainPictureDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Picture_FaceReenactment alloc] init];
        }];
        [_mainViewCtrlNames addObject:@"Face Reenactment"];
#       endif
        
#       if USE_OBJTRACKING
        [_mainCameraDemoViewCtrlObjs addObject:^(UIViewController **res) {
            *res = [[ViewCtrl_Camera_ObjTracking alloc] init];
        }];
        [_mainPictureDemoViewCtrlObjs addObject: [NSNull null]];
        [_mainViewCtrlNames addObject:@"Object Tracking"];
#       endif
        
        [_mainTableView reloadData];
    }
    NSLog(@"view did load.");
}

- (UIModalPresentationStyle)modalPresentationStyle {
    return UIModalPresentationFullScreen;
}

- (UILabel *)versionInfo {
    if (!_versionInfo) {
        _versionInfo = [[UILabel alloc] initWithFrame:CGRectMake((ACTUAL_SCREEN_WIDTH - SCREEN_WIDTH) / 2 + 0,
                                                                 ACTUAL_SCREEN_HEIGHT - (ACTUAL_SCREEN_HEIGHT - SCREEN_HEIGHT) / 2 - 16,
                                                                 SCREEN_WIDTH,
                                                                 16)];
        NSString *ver = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        [_versionInfo setText:[NSString stringWithFormat:@"VNN (Version %@)", ver]];
        [_versionInfo setFont:[UIFont fontWithName:@"PingFangSC-Light" size:10.0]];
        [_versionInfo setTextColor:UIColorFromRGB(0x808080)];
    }
    return _versionInfo;
}

- (UIView *)Logo {
    if (!_Logo)
    {
        _Logo = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:[[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"ui"] stringByAppendingPathComponent:@"vnn.png"]]];
        [_Logo setFrame:CGRectMake((ACTUAL_SCREEN_WIDTH  - SCREEN_WIDTH ) / 2 + SCREEN_WIDTH * 1.5 / 9.0,
                                   (ACTUAL_SCREEN_HEIGHT - SCREEN_HEIGHT) / 2 + SCREEN_HEIGHT * 0.5 / 16.0,
                                   SCREEN_WIDTH * 6.0 / 9.0,
                                   SCREEN_HEIGHT * 6.0 / 16.0)];
    }
    return _Logo;
}

- (UITableView *)mainTableView {
    if (!_mainTableView) {
        CGRect frame = CGRectMake((ACTUAL_SCREEN_WIDTH - SCREEN_WIDTH) / 2 + SCREEN_WIDTH * 0.5 / 9.0,
                                  (ACTUAL_SCREEN_HEIGHT - SCREEN_HEIGHT) / 2 + SCREEN_HEIGHT * 7.0 / 16.0 ,
                                  SCREEN_WIDTH * 8.0 / 9.0,
                                  SCREEN_HEIGHT * 8.5 / 16.0);
        _mainTableView = [[UITableView alloc] initWithFrame:frame];
        [_mainTableView setBackgroundColor:[UIColor clearColor]];
        [_mainTableView setDelegate:self];
        [_mainTableView setDataSource:self];
    }
    return _mainTableView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.mainCameraDemoViewCtrlObjs.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Select a demo form"
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {[self.mainTableView reloadData];}];
    [alertController addAction:cancelAction];
    if(![[self.mainCameraDemoViewCtrlObjs objectAtIndex:indexPath.row] isEqual:[NSNull null]]){
        UIAlertAction *cameraDemoAction = [UIAlertAction actionWithTitle:@"Camera Demo"
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction * _Nonnull action) {
            void (^ iblock)(UIViewController **) = [self.mainCameraDemoViewCtrlObjs objectAtIndex:indexPath.row];
            UIViewController * viewctrl = nil;
            iblock(&viewctrl);
            [self presentViewController:viewctrl animated:YES completion:^{
                [self.mainTableView reloadData];
            }];}];
        [alertController addAction:cameraDemoAction];
    }
    if(![[self.mainPictureDemoViewCtrlObjs objectAtIndex:indexPath.row] isEqual:[NSNull null]]){
        UIAlertAction *pictureDemoAction = [UIAlertAction actionWithTitle:@"Picture Demo"
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * _Nonnull action) {
            void (^ iblock)(UIViewController **) = [self.mainPictureDemoViewCtrlObjs objectAtIndex:indexPath.row];
            UIViewController * viewctrl = nil;
            iblock(&viewctrl);
            [self presentViewController:viewctrl animated:YES completion:^{
                [self.mainTableView reloadData];
            }];}];
        [alertController addAction:pictureDemoAction];
    }
    
    [self presentViewController:alertController animated:YES completion:nil];
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell;
    if(!cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.text = [self.mainViewCtrlNames objectAtIndex:indexPath.row];
    return cell;
}

@end
