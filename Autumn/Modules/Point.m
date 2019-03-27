//
//  Point.m
//  Autumn
//

#import "Point.h"


/**
 * module PointLike
 *
 * Interface version of Point
 *
 * This is an interface, so any JavaScript object containing these keys is conformant, most notably Point, Rect, and RectLike.
 */

/** x: number; */
/** y: number; */


/**
 * module Point
 *
 * { x, y }
 *
 * You don't usually need to use this class since all methods take a PointLike instead of a Point, but it can be convenient if you need its methods.
 */
@implementation Point2d

+ (void)startModule:(JSValue *)ctor {
    
}

+ (void)stopModule {
    
}

+ (NSString*) overrideName {
    return @"Point";
}

/**
 * static empty(): Point;
 *
 * Returns a point with all zero fields.
 */
+ (Point2d*) empty {
    return [Point2d from: NSZeroPoint];
}

/**
 * static from(point: { x: number, y: number }): Point;
 */
+ (Point2d*) from:(NSPoint)point {
    Point2d* p = [[Point2d alloc] init];
    p->_p = point;
    return p;
}

/** x: number; */
/** y: number; */
- (double) x { return _p.x; }
- (double) y { return _p.y; }
- (void) setX:(double)newX { _p.x = newX; }
- (void) setY:(double)newY { _p.y = newY; }

/** equals(other: PointLike): boolean; */
- (NSNumber*) equals:(NSPoint)other {
    return NSEqualPoints(_p, other) ? @YES : @NO;
}

/**
 * isValid: boolean;
 *
 * True if none of its numbers are NaN or Infinity.
 */
- (NSNumber*) isValid {
    return (!isnan(_p.x) && !isnan(_p.y) && !isinf(_p.x) && !isinf(_p.y)) ? @YES : @NO;
}

/** offset(x: number, y: number): Point; */
- (Point2d*) offset:(CGFloat)x :(CGFloat)y {
    return [Point2d from: NSMakePoint(_p.x + x,
                                      _p.y + y)];
}

/** minus(other: PointLike): Point; */
- (Point2d*) minus:(NSPoint)other {
    return [Point2d from: NSMakePoint(_p.x - other.x, _p.y - other.y)];
}

/** plus(other: PointLike): Point; */
- (Point2d*) plus:(NSPoint)other {
    return [Point2d from: NSMakePoint(_p.x + other.x, _p.y + other.y)];
}

@end
