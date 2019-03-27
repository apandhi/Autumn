//
//  Wifi.m
//  Autumn
//

#import "Wifi.h"
#import <CoreWLAN/CoreWLAN.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "FnUtils.h"


@interface Wifi () <CWEventDelegate>
@end

/**
 * module Wifi
 *
 * Wifi network info and event handlers.
 */
@implementation Wifi

/**
 * static networkName(): string | null;
 *
 * The name of the network you're currently connected to, if any.
 */
+ (id) networkName {
    NSString* name = CWWiFiClient.sharedWiFiClient.interface.ssid;
    return name ?: [NSNull null];
}

/**
 * static onNetworkPowerChanged: () => void;
 *
 * Set a callback for when your wifi turns on or off.
 */
+ (void)powerStateDidChangeForWiFiInterfaceWithName:(NSString *)interfaceName {
    dispatch_sync(dispatch_get_main_queue(), ^{
        JSValue* fn = module[@"onNetworkPowerChanged"];
        if ([fn isInstanceOf: fn.context[@"Function"]]) {
            [fn callWithArguments: @[]];
        }
    });
}

/**
 * static onNetworkChanged: () => void;
 *
 * Set a callback for when your wifi network changes.
 */
+ (void)ssidDidChangeForWiFiInterfaceWithName:(NSString *)interfaceName {
    dispatch_async(dispatch_get_main_queue(), ^{
        JSValue* fn = module[@"onNetworkChanged"];
        if ([fn isInstanceOf: fn.context[@"Function"]]) {
            [fn callWithArguments: @[]];
        }
    });
}

static JSValue* module;

+ (void)startModule:(JSValue *)ctor {
    module = ctor;
    module[@"onNetworkPowerChanged"] = [JSValue valueWithUndefinedInContext: module.context];
    module[@"onNetworkChanged"] = [JSValue valueWithUndefinedInContext: module.context];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CWWiFiClient.sharedWiFiClient.delegate = self;
        [CWWiFiClient.sharedWiFiClient startMonitoringEventWithType:CWEventTypePowerDidChange error:nil];
        [CWWiFiClient.sharedWiFiClient startMonitoringEventWithType:CWEventTypeSSIDDidChange error:nil];
    });
}

+ (void)stopModule {
    module = nil;
}

@end
