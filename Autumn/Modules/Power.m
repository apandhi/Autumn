//
//  Power.m
//  Autumn
//

#import "Power.h"
#import <IOKit/ps/IOPSKeys.h>
#import <IOKit/pwr_mgt/IOPMLibDefs.h>
#import <IOKit/pwr_mgt/IOPMLib.h>

/**
 * module Power
 *
 * React to your Mac's power states.
 */
@implementation Power

/** group Power events */

/**
 * static onWake: () => void;
 *
 * Set a callback for when your computer wakes from sleep.
 *
 * Note: this doesn't get called when starting up.
 */

/**
 * static onSleep: () => void;
 *
 * Set a callback for when your computer falls asleep.
 *
 * Note: this doesn't get called when shutting down.
 */

/** group Get power info */

/**
 * static getBatteryInfo(): {
 *   isCharging: boolean,
 *   maxCapacity: number,
 *   currentCapacity: number,
 *   percent: number
 * };
 *
 * Get information about the current battery life.
 */
+ (NSDictionary*) getBatteryInfo {
    CFTypeRef info = IOPSCopyPowerSourcesInfo();
    if (!info) return nil;
    
    CFArrayRef list = IOPSCopyPowerSourcesList(info);
    if (!list) {
        CFRelease(info);
        return nil;
    }
    if (CFArrayGetCount(list) == 0) {
        CFRelease(list);
        CFRelease(info);
        return nil;
    }
    
    CFDictionaryRef battery = IOPSGetPowerSourceDescription(info, CFArrayGetValueAtIndex(list, 0));
    
    NSNumber* isCharging = (__bridge NSNumber*)CFDictionaryGetValue(battery, CFSTR(kIOPSIsChargingKey));
    NSNumber* maxCapacity = (__bridge NSNumber*)CFDictionaryGetValue(battery, CFSTR(kIOPSMaxCapacityKey));
    NSNumber* currentCapacity = (__bridge NSNumber*)CFDictionaryGetValue(battery, CFSTR(kIOPSCurrentCapacityKey));
    
    double percent = currentCapacity.doubleValue / maxCapacity.doubleValue;
    
    CFRelease(list);
    CFRelease(info);
    
    return @{@"isCharging": isCharging,
             @"maxCapacity": maxCapacity,
             @"currentCapacity": currentCapacity,
             @"percent": @(percent)};
}

static io_connect_t session;
static JSValue* module;

static void callback(void* refcon, io_service_t service, uint32_t messageType, void* messageArgument) {
    NSString* event = nil;
    BOOL needsResponse = NO;
    
    switch (messageType) {
        case kIOMessageSystemWillPowerOn:
            break;
        case kIOMessageSystemHasPoweredOn:
            event = @"onWake";
            break;
        case kIOMessageSystemWillNotSleep:
            break;
        case kIOMessageSystemWillSleep:
            event = @"onSleep";
            needsResponse = YES;
            break;
        case kIOMessageCanSystemSleep:
            needsResponse = YES;
            break;
        default:
            break;
    }
    
    if (needsResponse) {
        IOAllowPowerChange(session, (long)messageArgument);
    }
    
    if (event && module) {
        JSValue* fn = module[event];
        if ([fn isInstanceOf: fn.context[@"Function"]]) {
            [fn callWithArguments: @[]];
        }
    }
}

/** group Idle & sleep */

/**
 * static userIdleTime(): number;
 *
 * Returns the number of seconds since last user activity (keyboard, mouse, trackpad, etc).
 */
+ (CFTimeInterval) userIdleTime {
    return CGEventSourceSecondsSinceLastEventType(kCGEventSourceStateHIDSystemState, kCGAnyInputEventType);
}

static NSMutableArray<NSNumber*>* sleepPreventers;

/**
 * static preventSleep(): () => void;
 *
 * Prevents the computer from going into idle sleep until the returned function is called.
 */
+ (void(^)(void)) preventSleep {
    CFStringRef reasonForActivity = CFSTR("Autumn script requested sleep prevention");
    
    // kIOPMAssertionTypeNoDisplaySleep prevents display sleep,
    // kIOPMAssertionTypeNoIdleSleep prevents idle sleep
    
    IOPMAssertionID assertionID;
    IOReturn success = IOPMAssertionCreateWithName(kIOPMAssertPreventUserIdleDisplaySleep, kIOPMAssertionLevelOn, reasonForActivity, &assertionID);
    if (success != kIOReturnSuccess) {
        return nil;
    }
    
    NSNumber* aID = @(assertionID);
    
    [sleepPreventers addObject: aID];
    
    return ^{
        if ([sleepPreventers containsObject: aID]) {
            [sleepPreventers removeObject: aID];
            IOPMAssertionRelease(assertionID);
        }
    };
}

+ (void)startModule:(JSValue *)ctor {
    module = ctor;
    module[@"onWake"]  = [JSValue valueWithUndefinedInContext: module.context];
    module[@"onSleep"] = [JSValue valueWithUndefinedInContext: module.context];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        IONotificationPortRef thePortRef;
        io_object_t notifier;
        session = IORegisterForSystemPower(NULL, &thePortRef, callback, &notifier);
        if (session != MACH_PORT_NULL) {
            IONotificationPortSetDispatchQueue(thePortRef, dispatch_get_main_queue());
        }
    });
    
    sleepPreventers = [NSMutableArray array];
}

+ (void)stopModule {
    module = nil;
    
    for (NSNumber* assertionId in sleepPreventers) {
        IOPMAssertionRelease(assertionId.unsignedIntValue);
    }
    [sleepPreventers removeAllObjects];
}

@end
