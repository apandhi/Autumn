//
//  Hotkey.m
//  Autumn
//

#import "Hotkey.h"
#import "Keyboard.h"
#import <Carbon/Carbon.h>
#import "JS.h"

/**
 * module Hotkey
 *
 * Create custom global keyboard shortcuts.
 */
@implementation Hotkey {
    JSValue* callback;
    EventHotKeyRef carbonHotKey;
}

static EventHandlerRef eventHandler;
static UInt32 hotkeysNextKey;
static NSMutableDictionary<NSNumber*, Hotkey*>* hotkeys;

+ (void)startModule:(JSValue *)ctor {
    hotkeys = [NSMutableDictionary dictionary];
    hotkeysNextKey = 0;
    
    EventTypeSpec hotKeyPressedSpec[] = {
        {kEventClassKeyboard, kEventHotKeyPressed},
    };
    InstallEventHandler(GetEventDispatcherTarget(),
                        callback,
                        sizeof(hotKeyPressedSpec) / sizeof(EventTypeSpec),
                        hotKeyPressedSpec,
                        NULL,
                        &eventHandler);
    
    JSValue* mods = ctor[@"Mods"] = [JSValue valueWithNewObjectInContext: ctor.context];
    mods[@"Command"] = @(cmdKey);
    mods[@"Control"] = @(controlKey);
    mods[@"Option"]  = @(optionKey);
    mods[@"Shift"]   = @(shiftKey);
}

+ (void)stopModule {
    for (NSNumber* uid in hotkeys.allKeys.copy) {
        [self deactivate: uid];
    }
    
    hotkeys = nil;
    
    RemoveEventHandler(eventHandler);
}

/**
 * static activate(
 *   mods: ModString[],
 *   key: KeyString,
 *   callback: () => void
 * ): number | null;
 *
 * This installs and activates a global hotkey handler.
 *
 * Returns a unique ID that can be used to deactivate the hotkey later, or null if this hotkey already exists within Autumn.
 *
 * Note: hotkeys are automatically deactivated when User Scripts are stopped and/or restarted, so you don't need to manually deactivate them.
 */
+ (id) activate:(id)modStrings :(NSString*)keyString :(JSValue*)callback {
    UInt32 keyCode = [[Keyboard keyCodes][keyString] unsignedIntValue];
    UInt32 modFlags = 0;
    
    if ([modStrings isKindOfClass: [NSArray class]]) {
        for (NSString* mod in modStrings) {
            if      ([mod isEqualToString: @"command"]) modFlags |= cmdKey;
            else if ([mod isEqualToString: @"control"]) modFlags |= controlKey;
            else if ([mod isEqualToString: @"option"])  modFlags |= optionKey;
            else if ([mod isEqualToString: @"shift"])   modFlags |= shiftKey;
        }
    }
    else if ([modStrings isKindOfClass: [NSNumber class]]) {
        modFlags = ((NSNumber*)modStrings).intValue;
    }
    
    Hotkey* hotkey = [[Hotkey alloc] init];
    hotkey->callback = callback;
    
    UInt32 uid = hotkeysNextKey++;
    hotkeys[@(uid)] = hotkey;
    
    EventHotKeyID hotKeyID = { .signature = 'AUTM', .id = uid };
    hotkey->carbonHotKey = NULL;
    OSStatus err = RegisterEventHotKey(keyCode, modFlags, hotKeyID, GetEventDispatcherTarget(), kEventHotKeyExclusive, &hotkey->carbonHotKey);
    
    if (err == eventHotKeyExistsErr) {
        [hotkeys removeObjectForKey: @(uid)];
        return [NSNull null];
    }
    else {
        return @(uid);
    }
}

/**
 * static deactivate(uid: number);
 *
 * Deactivate the hotkey with this unique ID. The callback function will be released at the next GC.
 *
 * Note: hotkeys are automatically deactivated when User Scripts are stopped and/or restarted, so you don't need to manually deactivate them. But you can, if you want to.
 */
+ (void) deactivate:(NSNumber*)uid {
    Hotkey* hotkey = hotkeys[uid];
    UnregisterEventHotKey(hotkey->carbonHotKey);
    [hotkeys removeObjectForKey: uid];
    
    if (hotkeys.count == 0) hotkeysNextKey = 0;
}

static OSStatus callback(EventHandlerCallRef __attribute__ ((unused)) inHandlerCallRef, EventRef inEvent, void *inUserData) {
    EventHotKeyID eventID;
    GetEventParameter(inEvent, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof(eventID), NULL, &eventID);
    
    Hotkey* hotkey = hotkeys[@(eventID.id)];
    [hotkey->callback callWithArguments: @[]];
    
    return noErr;
}

@end
