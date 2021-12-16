//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface DrawRect2D : NSObject
@property (nonatomic, assign) float left;
@property (nonatomic, assign) float top;
@property (nonatomic, assign) float right;
@property (nonatomic, assign) float bottom;
@property (nonatomic, assign) float thickness;
@property (nonatomic, assign) NSColor *color;
@end

@interface DrawCircle2D : NSObject
@property (nonatomic, assign) float x;
@property (nonatomic, assign) float y;
@property (nonatomic, assign) float r;
@property (nonatomic, assign) NSColor *color;
@end

@interface DrawPoint2D : NSObject
@property (nonatomic, assign) float x;
@property (nonatomic, assign) float y;
@property (nonatomic, assign) float thickness;
@property (nonatomic, assign) NSColor *color;
@end

@interface DrawLine2D : NSObject
@property (nonatomic, assign) float x0;
@property (nonatomic, assign) float y0;
@property (nonatomic, assign) float x1;
@property (nonatomic, assign) float y1;
@property (nonatomic, assign) float thickness;
@property (nonatomic, assign) NSColor *color;
@end

@interface DrawImage : NSObject
@property (nonatomic, assign) float left;
@property (nonatomic, assign) float top;
@property (nonatomic, assign) float right;
@property (nonatomic, assign) float bottom;
@property (nonatomic, retain) NSImage *img;
@end

NS_ASSUME_NONNULL_END
