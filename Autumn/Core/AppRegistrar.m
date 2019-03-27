//
//  AppRegistrar.m
//  Autumn
//

#import "AppRegistrar.h"
#import "Accessibility.h"
#import "KeyValueObserver.h"
#import "FnUtils.h"

@interface AppRegistrar () <AccessibilityStatusObserver>
@end

@implementation AppRegistrar {
    NSArray* currentRunningApps;
    KeyValueObserver* appsObserver;
    NSMapTable<NSRunningApplication*,App*>* appRegistry;
}

+ (AppRegistrar*) sharedRegistrar {
    static AppRegistrar* singleton;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[AppRegistrar alloc] init];
    });
    return singleton;
}

- (void) setup {
    appRegistry = [NSMapTable strongToStrongObjectsMapTable];
    
    currentRunningApps = [self getFilteredRunningApplications];
    
    appsObserver = [[KeyValueObserver alloc] init];
    [appsObserver observe:@"runningApplications" on:NSWorkspace.sharedWorkspace callback:^{
        [self appsChanged];
    }];
    
    [Accessibility addObserver: self];
}

- (void) accessibilityStatusChanged:(BOOL)enabled {
    if (enabled) {
        for (NSRunningApplication* runningApp in currentRunningApps) {
            App* app = [[App alloc] initWithRunningApplication: runningApp];
            
            [app startObservingWindowsSeeding: YES];
            
            [appRegistry setObject: app
                            forKey: runningApp];
        }
    }
    else {
        for (App* app in appRegistry.objectEnumerator) {
            [app stopObservingWindows];
        }
        [appRegistry removeAllObjects];
    }
}

- (void) appsChanged {
    NSArray* runningApps = [self getFilteredRunningApplications];
    
    NSMutableArray* oldApps = currentRunningApps.mutableCopy;
    [oldApps removeObjectsInArray: runningApps];
    
    NSMutableArray* newApps = runningApps.mutableCopy;
    [newApps removeObjectsInArray: currentRunningApps];
    
    currentRunningApps = runningApps;
    
    if (Accessibility.enabled) {
        for (NSRunningApplication* runningApp in oldApps) {
            [self appRemoved: runningApp];
        }
        
        for (NSRunningApplication* runningApp in newApps) {
            [self appAdded: runningApp];
        }
    }
}

- (void) appAdded:(NSRunningApplication*)runningApp {
    App* app = [[App alloc] initWithRunningApplication: runningApp];
    
    [app startObservingWindowsSeeding: NO];
    
    [appRegistry setObject: app
                    forKey: runningApp];
    
    [App appLaunched: app];
}

- (void) appRemoved:(NSRunningApplication*)runningApp {
    App* app = [appRegistry objectForKey: runningApp];
    
    [app appIsTerminating];
    [app stopObservingWindows];
    
    [App appTerminated: app];
    
    [appRegistry removeObjectForKey:runningApp];
}

- (App*) appForRunningApp:(NSRunningApplication*)runningApp {
    return [appRegistry objectForKey: runningApp];
}

- (NSArray<NSRunningApplication*>*) getFilteredRunningApplications {
    return [FnUtils filter:NSWorkspace.sharedWorkspace.runningApplications with:^BOOL(NSRunningApplication* app) {
        return app.processIdentifier != -1 && ![app.bundleIdentifier hasPrefix: @"com.apple.WebKit."];
    }];
}

- (NSArray<App*>*) apps {
    return appRegistry.objectEnumerator.allObjects;
}

@end
