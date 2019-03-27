//
//  Point.h
//  Autumn
//

#import <Foundation/Foundation.h>
#import "Module.h"

@class Point2d;

@protocol JSExport_Point <JSExport>

+ (Point2d*) empty;
+ (Point2d*) from:(NSPoint)point;

@property double x;
@property double y;

- (NSNumber*) equals:(NSPoint)other;

@property (readonly) NSNumber* isValid;

- (Point2d*) offset:(CGFloat)x :(CGFloat)y;

- (Point2d*) minus:(NSPoint)other;
- (Point2d*) plus:(NSPoint)other;

@end

NS_ASSUME_NONNULL_BEGIN

@interface Point2d : NSObject <JSExport_Point, Module>

@property NSPoint p;

@end

NS_ASSUME_NONNULL_END
