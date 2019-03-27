//
//  Brightness.m
//  Autumn
//

#import "Brightness.h"

/**
 * module Brightness
 *
 * Control the brightness of your screen.
 */
@implementation Brightness

+ (void)startModule:(JSValue *)ctor {
    
}

+ (void)stopModule {
    
}

/**
 * static getLevel(): number;
 *
 * Returns the current brightness, between 0.0 and 1.0
 */
+ (NSNumber*) getLevel {
    io_iterator_t iterator;
    if (IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("IODisplayConnect"), &iterator) != kIOReturnSuccess)
        return nil;
    
    io_object_t service;
    float brightness = 0.0;
    BOOL found = NO;
    while ((service = IOIteratorNext(iterator))) {
        IODisplayGetFloatParameter(service, kNilOptions, CFSTR(kIODisplayBrightnessKey), &brightness);
        IOObjectRelease(service);
        found = YES;
        break;
    }
    
    IOObjectRelease(iterator);
    
    return found ? @(brightness) : nil;
}

/**
 * static setLevel(brightness: number): void;
 *
 * Sets the current brightness, between 0.0 and 1.0
 */
+ (void) setLevel:(NSNumber*)percentage {
    double level = percentage.doubleValue;
    
    io_iterator_t iterator;
    if (IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("IODisplayConnect"), &iterator) != kIOReturnSuccess)
        return;
    
    io_object_t service;
    while ((service = IOIteratorNext(iterator))) {
        IODisplaySetFloatParameter(service, kNilOptions, CFSTR(kIODisplayBrightnessKey), level);
        IOObjectRelease(service);
        break;
    }
    
    IOObjectRelease(iterator);
}

@end
