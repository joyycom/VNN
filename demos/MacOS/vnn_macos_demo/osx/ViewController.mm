//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import <AppKit/AppKit.h>
#import "ViewController.h"
#import "WindowCtrl_CameraMetalRender.h"
#import "WindowCtrl_PictureMetalRender.h"

#import "PictureWindowCtrls/WindowCtrl_Picture_CartoonStylizing_ComicStylizing.h"
#import "PictureWindowCtrls/WindowCtrl_Picture_GeneralSegment.h"
#import "PictureWindowCtrls/WindowCtrl_Picture_FaceSegment.h"
#import "PictureWindowCtrls/WindowCtrl_Picture_HeadSegment.h"
#import "PictureWindowCtrls/WindowCtrl_Picture_DisneyFaceStylizing.h"
#import "PictureWindowCtrls/WindowCtrl_Picture_3DGameFaceStylizing.h"
#import "PictureWindowCtrls/WindowCtrl_Picture_FaceLandmarkDetection.h"
#import "PictureWindowCtrls/WindowCtrl_Picture_FaceCount_QRCodeDetect.h"
#import "PictureWindowCtrls/WindowCtrl_Picture_FaceReenactment.h"
#import "PictureWindowCtrls/WindowCtrl_Picture_Gesture.h"
#import "PictureWindowCtrls/WindowCtrl_Picture_GeneralClassification.h"
#import "PictureWindowCtrls/WindowCtrl_Picture_PoseLandmarkDetection.h"


#import "CameraWindowCtrls/WindowCtrl_Camera_FaceLandmarkDetection.h"
#import "CameraWindowCtrls/WindowCtrl_Camera_ObjectTracking.h"
#import "CameraWindowCtrls/WindowCtrl_Camera_FaceCount_QRCodeDetect.h"
#import "CameraWindowCtrls/WindowCtrl_Camera_Gesture.h"
#import "CameraWindowCtrls/WindowCtrl_Camera_CartoonStylizing_ComicStylizing.h"
#import "CameraWindowCtrls/WindowCtrl_Camera_FaceSegment.h"
#import "CameraWindowCtrls/WindowCtrl_Camera_HeadSegment.h"
#import "CameraWindowCtrls/WindowCtrl_Camera_GeneralSegment.h"
#import "CameraWindowCtrls/WindowCtrl_Camera_GeneralClassification.h"
#import "CameraWindowCtrls/WindowCtrl_Camera_3DGameFaceStylizing.h"
#import "CameraWindowCtrls/WindowCtrl_Camera_DisneyFaceStylizing.h"
#import "CameraWindowCtrls/WindowCtrl_Camera_PoseLandmarkDetection.h"

@interface ViewController ()
@property(nonatomic, strong) NSTextField *         verInfo;
@property(nonatomic, strong) NSMutableArray*       appButtons;
@property(nonatomic, strong) NSButton*             cameraDemoBtn;
@property(nonatomic, strong) NSButton*             pictureDemoBtn;
@property(nonatomic, strong) NSButton*             returnBtn;
@property(nonatomic, assign) NSString*             appType;
@end

@implementation ViewController

- (NSTextField *)verInfo {
    if (!_verInfo) {
        _verInfo = [[NSTextField alloc] init];
        NSString *ver = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        [_verInfo setStringValue:[NSString stringWithFormat:@"VNN (%@)", ver]];
        [_verInfo setBezeled:NO];
        [_verInfo setDrawsBackground:NO];
        [_verInfo setEditable:NO];
        [_verInfo setSelectable:NO];
    }
    return _verInfo;
}

- (void)loadView {
    [super loadView];
    [self.view addSubview:self.verInfo];
    self.appButtons = [[NSMutableArray alloc] init];

#       if USE_FACE
    {
        NSButton * button = [[NSButton alloc] init];
        [button setTitle:@"Face Landmark Detection"];
        [self.appButtons addObject:button];
    }
#       endif

#       if USE_FACE && USE_FACE_PARSER
    {
        NSButton * button = [[NSButton alloc] init];
        [button setTitle:@"Disney Face Stylizing"];
        [self.appButtons addObject:button];
    }
#       endif
    
#       if USE_FACE && USE_STYLIZING
    {
        NSButton * button = [[NSButton alloc] init];
        [button setTitle:@"3D Game Face Stylizing"];
        [self.appButtons addObject:button];
    }
#       endif
    
#       if USE_GENERAL
    {
        NSButton * button = [[NSButton alloc] init];
        [button setTitle:@"Cartoon Stylizing"];
        [self.appButtons addObject:button];
    }
#       endif
    
#       if USE_GENERAL
    {
        NSButton * button = [[NSButton alloc] init];
        [button setTitle:@"Comic Stylizing"];
        [self.appButtons addObject:button];
    }
#       endif
    
#       if USE_GENERAL
    {
        NSButton * button = [[NSButton alloc] init];
        [button setTitle:@"High Quality Portrait Segmentation"];
        [self.appButtons addObject:button];
    }
#       endif
    
#       if USE_GENERAL
    {
        NSButton * button = [[NSButton alloc] init];
        [button setTitle:@"Fast Portrait Segmentation"];
        [self.appButtons addObject:button];
    }
#       endif
    
#       if USE_FACE && USE_FACE_PARSER
    {
        NSButton * button = [[NSButton alloc] init];
        [button setTitle:@"Face Segmentation"];
        [self.appButtons addObject:button];
    }
#       endif
    
#       if USE_FACE && USE_GENERAL
    {
        NSButton * button = [[NSButton alloc] init];
        [button setTitle:@"Head Segmentation"];
        [self.appButtons addObject:button];
    }
#       endif
    
#       if USE_GENERAL
    {
        NSButton * button = [[NSButton alloc] init];
        [button setTitle:@"Hair Segmentation"];
        [self.appButtons addObject:button];
    }
#       endif
    
#       if USE_GENERAL
    {
        NSButton * button = [[NSButton alloc] init];
        [button setTitle:@"Clothes Segmentation"];
        [self.appButtons addObject:button];
    }
#       endif
    
#       if USE_GENERAL
    {
        NSButton * button = [[NSButton alloc] init];
        [button setTitle:@"Sky Segmentation"];
        [self.appButtons addObject:button];
    }
#       endif
    
#       if USE_GENERAL
    {
        NSButton * button = [[NSButton alloc] init];
        [button setTitle:@"Animal Segmentation"];
        [self.appButtons addObject:button];
    }
#       endif
    
#       if USE_GESTURE
    {
        NSButton * button = [[NSButton alloc] init];
        [button setTitle:@"Gesture Detection"];
        [self.appButtons addObject:button];
    }
#       endif
        
#       if USE_POSE
    {
        NSButton * button = [[NSButton alloc] init];
        [button setTitle:@"Pose Landmark Detection"];
        [self.appButtons addObject:button];
    }
#       endif
    
#       if USE_OBJCOUNT
    {
        NSButton * button = [[NSButton alloc] init];
        [button setTitle:@"QR Code Detection"];
        [self.appButtons addObject:button];
    }
#       endif
        
#       if USE_OBJCOUNT
    {
        NSButton * button = [[NSButton alloc] init];
        [button setTitle:@"Face Count"];
        [self.appButtons addObject:button];
    }
#       endif
        
#       if USE_CLASSIFYING
    {
        NSButton * button = [[NSButton alloc] init];
        [button setTitle:@"Scene&Weather Recognition"];
        [self.appButtons addObject:button];
    }
#       endif
        
#       if USE_CLASSIFYING && USE_FACE
    {
        NSButton * button = [[NSButton alloc] init];
        [button setTitle:@"Person Attribute Recognition"];
        [self.appButtons addObject:button];
    }
#       endif
        
#       if USE_CLASSIFYING
    {
        NSButton * button = [[NSButton alloc] init];
        [button setTitle:@"Vlog Object Recognition"];
        [self.appButtons addObject:button];
    }
#       endif
        
#if     USE_FACE_REENACTMENT && USE_FACE
    {
        NSButton * button = [[NSButton alloc] init];
        [button setTitle:@"Face Reenactment"];
        [self.appButtons addObject:button];
    }
#       endif
        
#       if USE_OBJTRACKING
    {
        NSButton * button = [[NSButton alloc] init];
        [button setTitle:@"Object Tracking"];
        [self.appButtons addObject:button];
    }
#       endif

    for(NSButton* btn in self.appButtons){
        [btn setBezelStyle:NSBezelStyleInline];
        [btn setAction:@selector(onAppBtnClicked:)];
        [self.view addSubview:btn];
    }
    
    
    {
        NSButton * button = [[NSButton alloc] init];
        [button setTitle:@"Camera Demo"];
        [button setBezelStyle:NSBezelStyleInline];
        [button setAction:@selector(onCameraDemoBtnClicked:)];
        [self.view addSubview:button];
        self.cameraDemoBtn = button;
    }
    
    {
        NSButton * button = [[NSButton alloc] init];
        [button setTitle:@"Picture Demo"];
        [button setBezelStyle:NSBezelStyleInline];
        [button setAction:@selector(onPictureDemoBtnClicked:)];
        [self.view addSubview:button];
        self.pictureDemoBtn = button;
    }
    
    {
        NSButton * button = [[NSButton alloc] init];
        [button setTitle:@"Return"];
        [button setBezelStyle:NSBezelStyleInline];
        [button setAction:@selector(onReturnBtnClicked:)];
        [self.view addSubview:button];
        self.returnBtn = button;
    }
    
}

- (void)onCameraDemoBtnClicked: (id)sender {
    [self setControlButtonsHidden:YES];
    [self setAppButtonsHidden:NO];
    ViewCtrl_CameraMetalRender *vc = [[ViewCtrl_CameraMetalRender alloc] init];
    WindowCtrl_CameraMetalRender* wc;
    
    if([self.appType isEqualToString:@"Face Landmark Detection"]){
        wc = [[WindowCtrl_Camera_FaceLandmarkDetection alloc] initWithRootViewController:vc];
    }
    else if([self.appType isEqualToString:@"Disney Face Stylizing"]){
        wc = [[WindowCtrl_Camera_DisneyFaceStylizing alloc] initWithRootViewController:vc];
    }
    else if([self.appType isEqualToString:@"3D Game Face Stylizing"]){
        wc = [[WindowCtrl_Camera_3DGameFaceStylizing alloc] initWithRootViewController:vc];
    }
    else if([self.appType isEqualToString:@"Cartoon Stylizing"]){
        wc = [[WindowCtrl_Camera_CartoonStylizing_ComicStylizing alloc] initWithRootViewController:vc WithStyleType:@"Cartoon"];
    }
    else if([self.appType isEqualToString:@"Comic Stylizing"]){
        wc = [[WindowCtrl_Camera_CartoonStylizing_ComicStylizing alloc] initWithRootViewController:vc WithStyleType:@"Comic"];
    }
    else if([self.appType isEqualToString:@"High Quality Portrait Segmentation"]){
        wc = [[WindowCtrl_Camera_GeneralSegment alloc] initWithRootViewController:vc WithSegmentType:@"HQ_Portrait"];
    }
    else if([self.appType isEqualToString:@"Fast Portrait Segmentation"]){
        wc = [[WindowCtrl_Camera_GeneralSegment alloc] initWithRootViewController:vc WithSegmentType:@"Fast_Portrait"];
    }
    else if([self.appType isEqualToString:@"Face Segmentation"]){
        wc = [[WindowCtrl_Camera_FaceSegment alloc] initWithRootViewController:vc];
    }
    else if([self.appType isEqualToString:@"Head Segmentation"]){
        wc = [[WindowCtrl_Camera_HeadSegment alloc] initWithRootViewController:vc];
    }
    else if([self.appType isEqualToString:@"Hair Segmentation"]){
        wc = [[WindowCtrl_Camera_GeneralSegment alloc] initWithRootViewController:vc WithSegmentType:@"Hair"];
    }
    else if([self.appType isEqualToString:@"Clothes Segmentation"]){
        wc = [[WindowCtrl_Camera_GeneralSegment alloc] initWithRootViewController:vc WithSegmentType:@"Clothes"];
    }
    else if([self.appType isEqualToString:@"Sky Segmentation"]){
        wc = [[WindowCtrl_Camera_GeneralSegment alloc] initWithRootViewController:vc WithSegmentType:@"Sky"];
    }
    else if([self.appType isEqualToString:@"Animal Segmentation"]){
        wc = [[WindowCtrl_Camera_GeneralSegment alloc] initWithRootViewController:vc WithSegmentType:@"Animal"];
    }
    else if([self.appType isEqualToString:@"Gesture Detection"]){
        wc = [[WindowCtrl_Camera_Gesture alloc] initWithRootViewController:vc];
    }
    else if([self.appType isEqualToString:@"Pose Landmark Detection"]){
        wc = [[WindowCtrl_Camera_PoseLandmarkDetection alloc] initWithRootViewController:vc];
    }
    else if([self.appType isEqualToString:@"QR Code Detection"]){
        wc = [[WindowCtrl_Camera_FaceCount_QRCodeDetect alloc] initWithRootViewController:vc WithFunctionType:@"QRCodeDetect"];
    }
    else if([self.appType isEqualToString:@"Face Count"]){
        wc = [[WindowCtrl_Camera_FaceCount_QRCodeDetect alloc] initWithRootViewController:vc WithFunctionType:@"FaceCount"];
    }
    else if([self.appType isEqualToString:@"Scene&Weather Recognition"]){
        wc = [[WindowCtrl_Camera_GeneralClassification alloc] initWithRootViewController:vc WithFunctionType:@"Scene&Weather"];
    }
    else if([self.appType isEqualToString:@"Person Attribute Recognition"]){
        wc = [[WindowCtrl_Camera_GeneralClassification alloc] initWithRootViewController:vc WithFunctionType:@"PersonAttribute"];
    }
    else if([self.appType isEqualToString:@"Vlog Object Recognition"]){
        wc = [[WindowCtrl_Camera_GeneralClassification alloc] initWithRootViewController:vc WithFunctionType:@"Object"];
    }
    else if([self.appType isEqualToString:@"Face Reenactment"]){
        NSAlert *alert = [NSAlert alertWithMessageText:@"Not Camera Demo" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", @"Camera is not a suitable form for demonstrating Face Reenactment, please turn to the corresponding picture demo"];
        [alert beginSheetModalForWindow:[NSApp mainWindow] completionHandler: nil];
        [self setAppButtonsHidden:YES];
        [self setControlButtonsHidden:NO];
        return;
    }
    else if([self.appType isEqualToString:@"Object Tracking"]){
        wc = [[WindowCtrl_Camera_ObjectTracking alloc] initWithRootViewController:vc];
    }
    else{
        NSAssert(false, @"Unrecongized appType");
    }
    [wc.window center];
    [wc.window setTitle:self.appType];
    [[NSApplication sharedApplication] runModalForWindow:wc.window];
}

- (void)onPictureDemoBtnClicked: (id)sender {
    [self setControlButtonsHidden:YES];
    [self setAppButtonsHidden:NO];
    ViewCtrl_PictureMetalRender *vc = [[ViewCtrl_PictureMetalRender alloc] init];
    WindowCtrl_PictureMetalRender* wc;
    
    if([self.appType isEqualToString:@"Face Landmark Detection"]){
        wc = [[WindowCtrl_Picture_FaceLandmarkDetection alloc] initWithRootViewController:vc];
    }
    else if([self.appType isEqualToString:@"Disney Face Stylizing"]){
        wc = [[WindowCtrl_Picture_DisneyFaceStylizing alloc] initWithRootViewController:vc];
    }
    else if([self.appType isEqualToString:@"3D Game Face Stylizing"]){
        wc = [[WindowCtrl_Picture_3DGameFaceStylizing alloc] initWithRootViewController:vc];
    }
    else if([self.appType isEqualToString:@"Cartoon Stylizing"]){
        wc = [[WindowCtrl_Picture_CartoonStylizing_ComicStylizing alloc] initWithRootViewController:vc WithStyleType:@"Cartoon"];
    }
    else if([self.appType isEqualToString:@"Comic Stylizing"]){
        wc = [[WindowCtrl_Picture_CartoonStylizing_ComicStylizing alloc] initWithRootViewController:vc WithStyleType:@"Comic"];
    }
    else if([self.appType isEqualToString:@"High Quality Portrait Segmentation"]){
        wc = [[WindowCtrl_Picture_GeneralSegment alloc] initWithRootViewController:vc WithSegmentType:@"HQ_Portrait"];
    }
    else if([self.appType isEqualToString:@"Fast Portrait Segmentation"]){
        wc = [[WindowCtrl_Picture_GeneralSegment alloc] initWithRootViewController:vc WithSegmentType:@"Fast_Portrait"];
    }
    else if([self.appType isEqualToString:@"Face Segmentation"]){
        wc = [[WindowCtrl_Picture_FaceSegment alloc] initWithRootViewController:vc];
    }
    else if([self.appType isEqualToString:@"Head Segmentation"]){
        wc = [[WindowCtrl_Picture_HeadSegment alloc] initWithRootViewController:vc];
    }
    else if([self.appType isEqualToString:@"Hair Segmentation"]){
        wc = [[WindowCtrl_Picture_GeneralSegment alloc] initWithRootViewController:vc WithSegmentType:@"Hair"];
    }
    else if([self.appType isEqualToString:@"Clothes Segmentation"]){
        wc = [[WindowCtrl_Picture_GeneralSegment alloc] initWithRootViewController:vc WithSegmentType:@"Clothes"];
    }
    else if([self.appType isEqualToString:@"Sky Segmentation"]){
        wc = [[WindowCtrl_Picture_GeneralSegment alloc] initWithRootViewController:vc WithSegmentType:@"Sky"];
    }
    else if([self.appType isEqualToString:@"Animal Segmentation"]){
        wc = [[WindowCtrl_Picture_GeneralSegment alloc] initWithRootViewController:vc WithSegmentType:@"Animal"];
    }
    else if([self.appType isEqualToString:@"Gesture Detection"]){
        wc = [[WindowCtrl_Picture_Gesture alloc] initWithRootViewController:vc];
    }
    else if([self.appType isEqualToString:@"Pose Landmark Detection"]){
        wc = [[WindowCtrl_Picture_PoseLandmarkDetection alloc] initWithRootViewController:vc];
    }
    else if([self.appType isEqualToString:@"QR Code Detection"]){
        wc = [[WindowCtrl_Picture_FaceCount_QRCodeDetect alloc] initWithRootViewController:vc WithFunctionType:@"QRCodeDetect"];
    }
    else if([self.appType isEqualToString:@"Face Count"]){
        wc = [[WindowCtrl_Picture_FaceCount_QRCodeDetect alloc] initWithRootViewController:vc WithFunctionType:@"FaceCount"];
    }
    else if([self.appType isEqualToString:@"Scene&Weather Recognition"]){
        wc = [[WindowCtrl_Picture_GeneralClassification alloc] initWithRootViewController:vc WithFunctionType:@"Scene&Weather"];
    }
    else if([self.appType isEqualToString:@"Person Attribute Recognition"]){
        wc = [[WindowCtrl_Picture_GeneralClassification alloc] initWithRootViewController:vc WithFunctionType:@"PersonAttribute"];
    }
    else if([self.appType isEqualToString:@"Vlog Object Recognition"]){
        wc = [[WindowCtrl_Picture_GeneralClassification alloc] initWithRootViewController:vc WithFunctionType:@"Object"];
    }
    else if([self.appType isEqualToString:@"Face Reenactment"]){
        wc = [[WindowCtrl_Picture_FaceReenactment alloc] initWithRootViewController:vc];
    }
    else if([self.appType isEqualToString:@"Object Tracking"]){
        NSAlert *alert = [NSAlert alertWithMessageText:@"Not Picture Demo" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", @"Picture is not a suitable form for demonstrating Face Reenactment, please turn to the corresponding camera demo"];
        [alert beginSheetModalForWindow:[NSApp mainWindow] completionHandler: nil];
        [self setAppButtonsHidden:YES];
        [self setControlButtonsHidden:NO];
        return;
    }
    else{
        NSAssert(false, @"Unrecongized appType");
    }
    [wc.window center];
    [wc.window setTitle:self.appType];
    [[NSApplication sharedApplication] runModalForWindow:wc.window];
}

- (void)onReturnBtnClicked: (id)sender {
    [self setControlButtonsHidden:YES];
    [self setAppButtonsHidden:NO];
}

- (void)onAppBtnClicked: (id)sender {
    NSButton* button = sender;
    NSString* appType = button.title;
    self.appType = appType;
    [self setAppButtonsHidden:YES];
    [self setControlButtonsHidden:NO];
}

-(void)setAppButtonsHidden:(BOOL) flag{
    for(NSButton *btn in self.appButtons){
        [btn setHidden:flag];
    }
}

-(void)setControlButtonsHidden:(BOOL) flag{
    [self.cameraDemoBtn setHidden:flag];
    [self.pictureDemoBtn setHidden:flag];
    [self.returnBtn setHidden:flag];
}

- (void)viewWillLayout {
    [super viewWillLayout];
    const int btnHeight = 34;
    const int y_offset = 36;

    for(int i = 0; i < self.appButtons.count; i++){
        [self.appButtons[i]   setFrame:NSMakeRect(CURRENT_VIEW_W / 100 * 5, CURRENT_VIEW_H / 100 * 94 - y_offset * i, CURRENT_VIEW_W / 100 * 90, btnHeight)];
    }
    [_verInfo setFrame:NSMakeRect(CURRENT_VIEW_W / 100 * 5, CURRENT_VIEW_H / 100 * 94 - y_offset * self.appButtons.count, CURRENT_VIEW_W / 100 * 98, btnHeight)];
    [self.cameraDemoBtn   setFrame:NSMakeRect(CURRENT_VIEW_W / 100 * 5, CURRENT_VIEW_H / 100 * 94 - y_offset * 0, CURRENT_VIEW_W / 100 * 90, btnHeight)];
    [self.pictureDemoBtn  setFrame:NSMakeRect(CURRENT_VIEW_W / 100 * 5, CURRENT_VIEW_H / 100 * 94 - y_offset * 1, CURRENT_VIEW_W / 100 * 90, btnHeight)];
    [self.returnBtn   setFrame:NSMakeRect(CURRENT_VIEW_W / 100 * 5, CURRENT_VIEW_H / 100 * 94 - y_offset * 2, CURRENT_VIEW_W / 100 * 90, btnHeight)];

    [self setControlButtonsHidden:YES];
    [self setAppButtonsHidden:NO];

}

- (void)viewWillAppear {
    [super viewWillAppear];
    [self setPreferredContentSize:CGSizeMake(240, 38 * self.appButtons.count)];
}

- (void)viewDidAppear {
    [super viewDidAppear];
    [self.view.window setLevel:NSFloatingWindowLevel];
    [self.view.window setTitle:@"VNN Demo"];
}

- (void)viewDidDisappear {
    [super viewDidDisappear];
    exit(0);
}

@end
