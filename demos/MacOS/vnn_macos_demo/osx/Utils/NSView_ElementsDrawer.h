#import <Cocoa/Cocoa.h>
#import "NSDrawElements.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSView_ElementsDrawer : NSView

@property (nonatomic, strong) NSArray< DrawRect2D *  > *rects;
@property (nonatomic, strong) NSArray< DrawPoint2D * > *points;
@property (nonatomic, strong) NSArray< DrawLine2D *  > *lines;
@property (nonatomic, strong) NSArray< DrawImage *   > *imgs;

@end

NS_ASSUME_NONNULL_END
