//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "OSXDemoHelper.h"
#import "NSView_ElementsDrawer.h"
#import <CoreGraphics/CoreGraphics.h>

@interface NSView_ElementsDrawer ()
@property (nonatomic, assign) int screen_h;
@property (nonatomic, assign) int screen_w;
@end

@implementation NSView_ElementsDrawer

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    _screen_h = frameRect.size.height;
    _screen_w = frameRect.size.width;
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    CGContextRef context = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetAllowsAntialiasing(context, true);
    CGContextSetShouldAntialias(context, true);

    if (self.imgs != nil) {
        if (self.imgs.count) {
            CGContextSaveGState(context);
            CGContextTranslateCTM(context, 0, _screen_h);
            CGContextScaleCTM(context, 1.0, -1.0);
            CGContextRestoreGState(context);
        }
    }

    if (self.rects != nil) {
        if (self.rects.count) {
            for (DrawRect2D *box in self.rects) {
                // [box.color set];
                CGContextSetLineWidth(context, box.thickness);
                CGContextSetStrokeColorWithColor(context, box.color.CGColor);
                CGContextStrokeRect(
                                    context,
                                    CGRectMake(
                                               box.left * _screen_w,
                                               box.top * _screen_h,
                                               (box.right - box.left) * _screen_w,
                                               (box.bottom - box.top) * _screen_h
                                               )
                                    );
                CGContextStrokePath(context);
            }
        }
    }

    if (self.lines != nil) {
        if (self.lines.count) {
            for (DrawLine2D *l in self.lines) {
                CGContextSetLineWidth(context, l.thickness);
                [l.color set];
                CGPoint ps[2] = {
                    CGPointMake(l.x0 * _screen_w,
                                l.y0 * _screen_h),
                    CGPointMake(l.x1 * _screen_w,
                                l.y1 * _screen_h)
                };
                //draw lines:
                CGContextSetStrokeColorWithColor(context, l.color.CGColor);
                CGContextAddLines(context, ps, 2);
                CGContextStrokePath(context);
            }
        }
    }

    if (self.points != nil) {
        if (self.points.count) {
            CGFloat startAngle = -((float)M_PI / 2);
            CGFloat endAngle = ((2 * (float)M_PI) + startAngle);
            for (DrawPoint2D *p in self.points) {
                CGContextSetLineWidth(context, p.thickness);
                CGContextSetStrokeColorWithColor(context, p.color.CGColor);
                CGContextMoveToPoint(context, p.x * _screen_w, (1.f - p.y) * _screen_h);
                CGContextAddArc(context, p.x * _screen_w, (1.f - p.y) * _screen_h, p.thickness, startAngle, endAngle, 1);
                CGContextStrokePath(context);
            }
        }
    }
}

@end
