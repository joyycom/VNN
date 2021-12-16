//-------------------------------------------------------------------------------------------------------
// Copyright (c) 2021 Guangzhou Joyy Information Technology Co., Ltd. All rights reserved.
// Licensed under the MIT license. See license.txt file in the project root for full license information.
//-------------------------------------------------------------------------------------------------------

#import "NSDrawElements.h"

@implementation DrawRect2D
- (instancetype)init {
    self = [super init];
    self.left = 0.25f;
    self.top = 0.25f;
    self.right = 0.75f;
    self.bottom = 0.75f;
    self.thickness = 1.0f;
    self.color = [NSColor colorWithRed:1.f green:1.f blue:1.f alpha:1.f];
    return self;
}
@end

@implementation DrawCircle2D : NSObject
- (instancetype)init {
    self = [super init];
    self.x = 0.5f;
    self.y = 0.5f;
    self.r = 0.5f;
    self.color = [NSColor colorWithRed:1.f green:1.f blue:1.f alpha:1.f];
    return self;
}
@end

@implementation DrawPoint2D : NSObject
- (instancetype)init {
    self = [super init];
    self.x = 0.5f;
    self.y = 0.5f;
    self.thickness = 5.0;
    self.color = [NSColor colorWithRed:1.f green:1.f blue:1.f alpha:1.f];
    return self;
}
@end

@implementation DrawLine2D : NSObject
- (instancetype)init {
    self = [super init];
    self.x0 = 0.25f;
    self.y0 = 0.25f;
    self.x1 = 0.75f;
    self.y1 = 0.75f;
    self.thickness = 5.0;
    self.color = [NSColor colorWithRed:1.f green:1.f blue:1.f alpha:1.f];
    return self;
}
@end

@implementation DrawImage : NSObject
- (instancetype)init {
    self = [super init];
    self.left = 0.f;
    self.top = 0.f;
    self.right = 1.f;
    self.bottom = 1.f;
    self.img = nil;
    return self;
}
@end
