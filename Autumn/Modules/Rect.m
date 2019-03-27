//
//  Rect.m
//  Autumn
//

#import "Rect.h"
#import "Point.h"

/**
 * module RectLike
 *
 * Interface version of Rect
 *
 * This is an interface, so any JavaScript object containing these keys is conformant, most notably Rect.
 */

/** x: number; */
/** y: number; */
/** width: number; */
/** height: number; */


/**
 * module Rect
 *
 * { x, y, width, height }
 *
 * You don't usually need to use this class since all methods take a RectLike instead of a Rect, but it can be convenient if you need its methods.
 */
@implementation Rect2d

+ (void)startModule:(JSValue *)ctor {
    
}

+ (void)stopModule {
    
}

+ (NSString*) overrideName {
    return @"Rect";
}

/**
 * static empty(): Rect;
 *
 * Returns a rect with all zero fields.
 */
+ (Rect2d*) empty {
    return [Rect2d from: NSZeroRect];
}

/**
 * static from(rect: { x: number, y: number, width: number, height: number }): Rect;
 */
+ (Rect2d*) from:(NSRect)rect {
    Rect2d* r = [[Rect2d alloc] init];
    r->_r = rect;
    return r;
}

/** x: number; */
/** y: number; */
/** width: number; */
/** height: number; */
- (double) x { return _r.origin.x; }
- (double) y { return _r.origin.y; }
- (double) width { return _r.size.width; }
- (double) height { return _r.size.height; }
- (void) setX:(double)newX { _r.origin.x = newX; }
- (void) setY:(double)newY { _r.origin.y = newY; }
- (void) setWidth:(double)newWidth { _r.size.width = newWidth; }
- (void) setHeight:(double)newHeight { _r.size.height = newHeight; }


/** equals(b: RectLike): boolean; */
- (NSNumber*) equals:(NSRect)other {
    return NSEqualRects(_r, other) ? @YES : @NO;
}





/** group Derived attributes */

/** leftX: number; */
- (double) leftX { return NSMinX(_r); }

/** topY: number; */
- (double) topY { return NSMinY(_r); }

/** rightX: number; */
- (double) rightX { return NSMaxX(_r); }

/** bottomY: number; */
- (double) bottomY { return NSMaxY(_r); }

/** centerX: number; */
- (double) centerX { return NSMidX(_r); }

/** centerY: number; */
- (double) centerY { return NSMidY(_r); }

/** centerPoint: Point; */
- (Point2d*) centerPoint { return [Point2d from: NSMakePoint(self.centerX, self.centerY)]; }










/** group Querying attributes */

/** isEmpty: boolean; */
- (NSNumber*) isEmpty {
    return NSIsEmptyRect(_r) ? @YES : @NO;
}

/**
 * isValid: boolean;
 *
 * True if none of its numbers are NaN or Infinity.
 */
- (NSNumber*) isValid {
    return (!isnan(_r.size.width) && !isnan(_r.size.height) && !isinf(_r.size.width) && !isinf(_r.size.height) &&
            !isnan(_r.origin.x) && !isnan(_r.origin.y) && !isinf(_r.origin.x) && !isinf(_r.origin.y)) ? @YES : @NO;
}


/** intersects(other: RectLike): boolean; */
- (NSNumber*) intersects:(NSRect)other {
    return NSIntersectsRect(_r, other) ? @YES : @NO;
}

/** contains(rect: RectLike): boolean; */
- (NSNumber*) containsRect:(NSRect)rect {
    return NSContainsRect(_r, rect) ? @YES : @NO;
}

/** containsPoint(point: PointLike): boolean; */
- (NSNumber*) containsPoint:(NSPoint)point {
    return NSPointInRect(point, _r) ? @YES : @NO;
}








/** group Deriving new rects */

/** union(other: RectLike): Rect; */
- (Rect2d*) union:(NSRect)other {
    return [Rect2d from: NSUnionRect(_r, other)];
}

/** intersection(other: RectLike): Rect; */
- (Rect2d*) intersection:(NSRect)other {
    return [Rect2d from: NSIntersectionRect(_r, other)];
}

/** inset(x: number, y?: number = x): Rect; */
- (Rect2d*) inset:(CGFloat)x :(JSValue*)y {
    return [self insetByX: x
                        Y: y.isNumber ? y.toNumber.doubleValue : x];
}

- (Rect2d*) insetByX:(CGFloat)x Y:(CGFloat)y {
    return [Rect2d from: NSInsetRect(_r, x, y)];
}

/** offset(x: number, y: number): Rect; */
- (Rect2d*) offset:(CGFloat)x :(CGFloat)y {
    return [Rect2d from: NSOffsetRect(_r, x, y)];
}

/** integralRect(): Rect */
- (Rect2d*) integralRect {
    return [Rect2d from: NSIntegralRect(_r)];
}

@end
