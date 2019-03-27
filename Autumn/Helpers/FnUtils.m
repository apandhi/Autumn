//
//  FnUtils.m
//  Autumn
//

#import "FnUtils.h"

@implementation FnUtils

+ (NSArray*) map:(NSArray*)i with:(id(^)(id))fn {
    NSMutableArray* o = [NSMutableArray arrayWithCapacity: i.count];
    for (id x in i) {
        [o addObject: fn(x)];
    }
    return o;
}

+ (NSArray*) flatMap:(NSArray*)i with:(NSArray*(^)(id))fn {
    NSMutableArray* o = [NSMutableArray arrayWithCapacity: i.count];
    for (id x in i) {
        [o addObjectsFromArray: fn(x)];
    }
    return o;
}

+ (NSArray*) filter:(NSArray*)i with:(BOOL(^)(id))fn {
    NSMutableArray* o = [NSMutableArray arrayWithCapacity: i.count];
    for (id x in i) {
        if (fn(x)) [o addObject: x];
    }
    return o;
}

+ (id) findIn:(NSArray*)i where:(BOOL(^)(id))fn {
    for (id x in i) {
        if (fn(x)) return x;
    }
    return nil;
}

@end
