//
//  Size.m
//  Autumn
//

#import "Size.h"


/**
 * module SizeLike
 *
 * Interface version of Size
 *
 * This is an interface, so any JavaScript object containing these keys is conformant, most notably Size, Rect, and RectLike.
 */

/** width: number; */
/** height: number; */


/**
 * module Size
 *
 * { width, height }
 *
 * You don't usually need to use this class since all methods take a SizeLike instead of a Size, but it can be convenient if you need its methods.
 */
@implementation Size2d

+ (void)startModule:(JSValue *)ctor {
    
}

+ (void)stopModule {
    
}

+ (NSString*) overrideName {
    return @"Size";
}

/**
 * static empty(): Size;
 *
 * Returns a size with all zero fields.
 */
+ (Size2d*) empty {
    return [Size2d from: NSZeroSize];
}

/**
 * static from(size: { width: number, height: number }): Size;
 */
+ (Size2d*) from:(NSSize)size {
    Size2d* s = [[Size2d alloc] init];
    s->_s = size;
    return s;
}

/** width: number; */
/** height: number; */
- (double) width { return _s.width; }
- (double) height { return _s.height; }
- (void) setWidth:(double)newWidth { _s.width = newWidth; }
- (void) setHeight:(double)newHeight { _s.height = newHeight; }

/** equals(other: SizeLike): boolean; */
- (NSNumber*) equals:(NSSize)other {
    return NSEqualSizes(_s, other) ? @YES : @NO;
}

/**
 * isValid: boolean;
 *
 * True if none of its numbers are NaN or Infinity.
 */
- (NSNumber*) isValid {
    return (!isnan(_s.width) && !isnan(_s.height) && !isinf(_s.width) && !isinf(_s.height)) ? @YES : @NO;
}

/** resizedBy(w: number, h: number): Size; */
- (Size2d*) resizedBy:(CGFloat)w :(CGFloat)h {
    return [Size2d from: NSMakeSize(_s.width + w,
                                    _s.height + h)];
}

@end
