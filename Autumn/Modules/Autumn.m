//
//  Autumn.m
//  Autumn
//

#import "Autumn.h"

#import <Cocoa/Cocoa.h>
#import "JS.h"
#import "Env.h"
#import "MainWindowController.h"
#import "UiStyleManager.h"

/**
 * module Autumn
 *
 * Functionality specific to Autumn.app.
 */
@implementation Autumn

static NSMapTable<NSMenuItem*,JSValue*>* fns;

+ (void)startModule:(JSValue *)ctor {
    fns = [NSMapTable weakToStrongObjectsMapTable];
}

+ (void)stopModule {
    [UiStyleManager.sharedManager removeCustomStatusMenuItems: fns.keyEnumerator.allObjects];
    [fns removeAllObjects];
}

/**
 * static showWindow(): void;
 *
 * Show this window, and make Autumn the focused app.
 */
+ (void) showWindow {
    [NSApp activateIgnoringOtherApps:YES];
    [MainWindowController.singleton showWindow: nil];
}

/**
 * static reloadUserScripts(): void;
 *
 * This also resets the JavaScript VM and removes all callbacks.
 */
+ (void) reloadUserScripts {
    dispatch_async(dispatch_get_main_queue(), ^{
        [Env stop];
        [Env start];
    });
}

/**
 * static stop(): void;
 *
 * Stop all callbacks and scripts, reset the JavaScript VM, and remove all callbacks.
 *
 * The same as pressing the Stop button in the main window.
 */
+ (void) stop {
    dispatch_async(dispatch_get_main_queue(), ^{
        [Env stop];
    });
}

/**
 * static setStatusMenuItems(items: Array<{
 *   title: string,
 *   onClick?: () => void
 * }>): void;
 *
 * Adds menu items to the status item icon's menu that's visible when you hide the Dock icon in Preferences.
 *
 * Each item requires at least a title, but usually also have an onClick handler.
 *
 * To create a separator, pass "-" (dash) as the title and omit onClick.
 */

+ (void) setStatusMenuItems:(JSValue*)items {
    if (!items.isArray) {
        items.context.exception = [JSValue valueWithNewErrorFromMessage:@"showStatusMenu requires an array" inContext:items.context];
        return;
    }
    
    [UiStyleManager.sharedManager removeCustomStatusMenuItems: fns.keyEnumerator.allObjects];
    [fns removeAllObjects];
    
    NSMutableArray* menuItems = [NSMutableArray array];
    
    for (int i = 0; i < items[@"length"].toNumber.intValue; i++) {
        JSValue* item = items[i];
        NSString* title = item[@"title"].toString;
        
        if ([title isEqualToString: @"-"]) {
            [menuItems addObject: [NSMenuItem separatorItem]];
        }
        else {
            JSValue* fn = item[@"onClick"];
            
            NSMenuItem* menuItem = [[NSMenuItem alloc] initWithTitle:title action:@selector(runItem:) keyEquivalent:@""];
            menuItem.target = self;
            
            [menuItems addObject: menuItem];
            [fns setObject:fn forKey:menuItem];
        }
    }
    
    [UiStyleManager.sharedManager addCustomStatusMenuItems: menuItems];
}

+ (void) runItem:(NSMenuItem*)item {
    JSValue* fn = [fns objectForKey: item];
    if ([fn isInstanceOf: fn.context[@"Function"]]) {
        [fn callWithArguments: @[]];
    }
}

@end



/**
 * module localStorage
 *
 * Persist data between launches.
 */

/**
 * length: number;
 *
 * Returns the number of key/value pairs currently present in the list associated with the object.
 */

/**
 * clear(): void;
 *
 * Empties the list associated with the object of all key/value pairs, if there are any.
 */

/**
 * getItem(key: string): JSONValue | null;
 *
 * value = storage[key]
 */

/**
 * removeItem(key: string): void;
 *
 * delete storage[key]
 */

/**
 * setItem(key: string, value: JSONValue): void;
 *
 * storage[key] = value
 */



/**
 * module console
 *
 * For logging and inspecting data.
 */

/**
 * log(...args: any[]): void;
 *
 * Add values into the console.
 */

/**
 * clear(): void;
 *
 * Resets all the logs in the console.
 */



/**
 * module (global)
 *
 * Global utility functions.
 */

/**
 * alert(msg: any, duration: number = 2): void;
 *
 * Show msg for `duration` seconds in the middle of the screen.
 */

/** group Modularizing your scripts */

/**
 * require(path: string): any;
 *
 * Load a file at the relative or absolute path. Tilde (~) represents $HOME.
 *
 * Returns any value set by module.exports in that file, if any.
 */

/** group Scheduling functions */

/**
 * setTimeout(
 *   fn: () => void,
 *   delay: number
 * ): number;
 *
 * Run the function after [delay] milliseconds. Returns a unique ID suitable for clearTimeout.
 */

/**
 * setInterval(
 *   fn: () => void,
 *   delay: number
 * ): number;
 *
 * Run the function ever [delay] milliseconds. Returns a unique ID suitable for clearInterval.
 */

/**
 * clearTimeout(id: number): void;
 *
 * Cancel the scheduled function.
 */

/**
 * clearInterval(id: number): void;
 *
 * Cancel the recurring function.
 */
