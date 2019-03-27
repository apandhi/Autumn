//
//  Rect.h
//  Autumn
//

#import <Foundation/Foundation.h>
#import "Module.h"

@class Point2d;
@class Rect2d;

@protocol JSExport_Rect <JSExport>

+ (Rect2d*) empty;
+ (Rect2d*) from:(NSRect)rect;

@property double x;
@property double y;
@property double width;
@property double height;

- (NSNumber*) equals:(NSRect)other;

@property (readonly) double leftX;
@property (readonly) double topY;
@property (readonly) double rightX;
@property (readonly) double bottomY;
@property (readonly) double centerX;
@property (readonly) double centerY;
@property (readonly) Point2d* centerPoint;

@property (readonly) NSNumber* isEmpty;
@property (readonly) NSNumber* isValid;
- (NSNumber*) intersects:(NSRect)other;
- (NSNumber*) containsRect:(NSRect)rect;
- (NSNumber*) containsPoint:(NSPoint)point;

- (Rect2d*) union:(NSRect)other;
- (Rect2d*) intersection:(NSRect)other;
- (Rect2d*) inset:(CGFloat)x :(JSValue*)y;
- (Rect2d*) offset:(CGFloat)x :(CGFloat)y;
- (Rect2d*) integralRect;

@end


NS_ASSUME_NONNULL_BEGIN

@interface Rect2d : NSObject <JSExport_Rect, Module>

@property NSRect r;

- (Rect2d*) insetByX:(CGFloat)x Y:(CGFloat)y;

@end

NS_ASSUME_NONNULL_END
