//
//  Keycodes.m
//  Autumn
//

#import "Keyboard.h"
#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import "Accessibility.h"
#import "App.h"

static NSMutableDictionary<NSString*, NSNumber*>* keyCodes;
static NSMutableDictionary<NSNumber*, NSString*>* codeKeys;
static JSValue* module;

/**
 * module Keyboard
 *
 * For sending and receiving keyboard events.
 */
@implementation Keyboard

/**
 * static onModsChanged: (currentMods: {
 *   Command: boolean,
 *   Control: boolean,
 *   Option: boolean,
 *   Shift: boolean,
 *   Fn: boolean,
 * }) => void;
 *
 * Set a callback for when any modifier keys are pressed or released, passing a table of which keys are currently pressed.
 */
static CFMachPortRef modsChangedPort;
static CFRunLoopSourceRef modsChangedSource;
static JSValue* onModsChanged;

static CGEventRef modsChangedCallback(CGEventTapProxy  proxy, CGEventType type, CGEventRef event, void * __nullable userInfo) {
    CGEventFlags flags = CGEventGetFlags(event);
    
    [onModsChanged callWithArguments: @[@{@"Command": (flags & kCGEventFlagMaskCommand) ? @YES : @NO,
                                          @"Control": (flags & kCGEventFlagMaskControl) ? @YES : @NO,
                                          @"Option":  (flags & kCGEventFlagMaskAlternate) ? @YES : @NO,
                                          @"Shift":   (flags & kCGEventFlagMaskShift) ? @YES : @NO,
                                          @"Fn":      (flags & kCGEventFlagMaskSecondaryFn) ? @YES : @NO}]];
    
    return NULL;
}

static void unregisterModsChanged(void) {
    if (!modsChangedPort) return;
    CFRunLoopRemoveSource(CFRunLoopGetMain(), modsChangedSource, kCFRunLoopCommonModes);
    CFMachPortInvalidate(modsChangedPort);
    CFRelease(modsChangedSource);
    CFRelease(modsChangedPort);
    modsChangedPort = NULL;
}

static void useOnModsChangedCallback(JSValue* fn) {
    unregisterModsChanged();
    
    onModsChanged = fn;
    if ([onModsChanged isInstanceOf: onModsChanged.context[@"Function"]]) {
        if (!modsChangedPort) {
            modsChangedPort = CGEventTapCreate(kCGSessionEventTap, kCGTailAppendEventTap, kCGEventTapOptionListenOnly, CGEventMaskBit(kCGEventFlagsChanged), modsChangedCallback, NULL);
            modsChangedSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, modsChangedPort, 0);
            CFRunLoopAddSource(CFRunLoopGetMain(), modsChangedSource, kCFRunLoopCommonModes);
        }
    }
}

/**
 * static onKeyPressed: (
 *   key: KeyString,
 *   state: 'down' | 'up',
 *   isRepeat: boolean
 * ) => KeyString | null | void;
 *
 * Set a callback for when any key is pressed and released.
 *
 * Defaults to passive: if you return nothing or undefined, the event passes through unchanged. If you return a string, the system thinks you pressed that physical key. If you return null, this key event is hidden from the rest of the system.
 */
static CFMachPortRef keyPressedPort;
static CFRunLoopSourceRef keyPressedSource;
static JSValue* onKeyPressed;

static CGEventRef keyPressedCallback(CGEventTapProxy  proxy, CGEventType type, CGEventRef event, void * __nullable userInfo) {
    int64_t keyCode = CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
    
    BOOL isDown = CGEventGetType(event) == kCGEventKeyDown;
    BOOL isRepeat = CGEventGetIntegerValueField(event, kCGKeyboardEventAutorepeat);
    
    JSValue* result = [onKeyPressed callWithArguments: @[codeKeys[@(keyCode)], isDown ? @"down" : @"up", isRepeat ? @YES : @NO]];
    
    if (result.isNull) return NULL;
    if (result.isString) {
        keyCode = keyCodes[result.toString].integerValue;
        CGEventSetIntegerValueField(event, kCGKeyboardEventKeycode, keyCode);
    }
    return event;
}

static void unregisterKeyPressed(void) {
    if (!keyPressedPort) return;
    CFRunLoopRemoveSource(CFRunLoopGetMain(), keyPressedSource, kCFRunLoopCommonModes);
    CFMachPortInvalidate(keyPressedPort);
    CFRelease(keyPressedSource);
    CFRelease(keyPressedPort);
    keyPressedPort = NULL;
}

static void useOnKeyPressedCallback(JSValue* fn) {
    if ([Accessibility warn]) return;
    
    unregisterKeyPressed();
    
    onKeyPressed = fn;
    if ([onKeyPressed isInstanceOf: onKeyPressed.context[@"Function"]]) {
        if (!keyPressedPort) {
            keyPressedPort = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, kCGEventTapOptionDefault, CGEventMaskBit(kCGEventKeyDown) | CGEventMaskBit(kCGEventKeyUp), keyPressedCallback, NULL);
            keyPressedSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, keyPressedPort, 0);
            CFRunLoopAddSource(CFRunLoopGetMain(), keyPressedSource, kCFRunLoopCommonModes);
        }
    }
}

/**
 * static press(key: KeyString, mods: ModString[], opts?: {
 * // app?: App, // (experimental, feel free to try but no guarantees -- using this with 'command' seems to only rarely work)
 *   fn?: () => void
 * }): void;
 *
 * Sends a key-event to the currently focused app, optionally calling your function between "pressing" and "releasing" the keys.
 */
+ (void) press:(NSString*)keyString :(NSArray*)mods :(JSValue*)opts {
    if ([Accessibility warn]) return;
    
    NSMutableArray* keys = [NSMutableArray array];
    [keys addObjectsFromArray: mods];
    [keys addObject: keyString];
    
    int modFlags = 0;
    
    App* app = opts.isObject ? opts[@"app"].toObject : nil;
    JSValue* fn = opts.toObject ? opts[@"fn"] : nil;
    
    for (NSString* mod in mods) {
        if ([mod isEqualToString: @"command"]) modFlags |= kCGEventFlagMaskCommand;
        if ([mod isEqualToString: @"control"]) modFlags |= kCGEventFlagMaskControl;
        if ([mod isEqualToString: @"option"]) modFlags |= kCGEventFlagMaskAlternate;
        if ([mod isEqualToString: @"shift"]) modFlags |= kCGEventFlagMaskShift;
    }
    
    CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStateCombinedSessionState);
    
    for (NSString* key in keys) {
        int keyCode = keyCodes[key].intValue;
        CGEventRef keyEvent = CGEventCreateKeyboardEvent(source, keyCode, true);
        CGEventSetFlags(keyEvent, modFlags);
        if (app) {
            CGEventPostToPid(app.pid, keyEvent);
        }
        else {
            CGEventPost(kCGSessionEventTap, keyEvent);
        }
        CFRelease(keyEvent);
    }
    
    if ([fn isInstanceOf: fn.context[@"Function"]]) {
        [fn callWithArguments: @[]];
    }
    
    for (NSString* key in keys.reverseObjectEnumerator) {
        int keyCode = keyCodes[key].intValue;
        CGEventRef keyEvent = CGEventCreateKeyboardEvent(source, keyCode, false);
        CGEventSetFlags(keyEvent, modFlags);
        if (app) {
            CGEventPostToPid(app.pid, keyEvent);
        }
        else {
            CGEventPost(kCGSessionEventTap, keyEvent);
        }
        CFRelease(keyEvent);
    }
    
    CFRelease(source);
}

/**
 * static onLayoutChanged: () => void;
 *
 * Set the callback for when the keyboard layout changes (i.e. from Qwerty to Colemak)
 */

+ (void)startModule:(JSValue *)ctor {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(inputSourceChanged:)
                                                 name:NSTextInputContextKeyboardSelectionDidChangeNotification
                                               object:nil];
    
    module = ctor;
    module[@"onLayoutChanged"] = [JSValue valueWithUndefinedInContext: module.context];
    
    [self recacheKeycodes];
    
    [ctor defineProperty:@"onModsChanged"
              descriptor:@{JSPropertyDescriptorConfigurableKey: @YES,
                           JSPropertyDescriptorGetKey: ^() { return onModsChanged; },
                           JSPropertyDescriptorSetKey: ^(JSValue* fn) { useOnModsChangedCallback(fn); }}];
    
    [ctor defineProperty:@"onKeyPressed"
              descriptor:@{JSPropertyDescriptorConfigurableKey: @YES,
                           JSPropertyDescriptorGetKey: ^() { return onKeyPressed; },
                           JSPropertyDescriptorSetKey: ^(JSValue* fn) { useOnKeyPressedCallback(fn); }}];
}

+ (void)stopModule {
    unregisterModsChanged();
    unregisterKeyPressed();
    
    module = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSTextInputContextKeyboardSelectionDidChangeNotification
                                                  object:nil];
}

+ (void) inputSourceChanged:(NSNotification*)note {
    [self recacheKeycodes];
    
    JSValue* callback = module[@"onLayoutChanged"];
    if ([callback isInstanceOf: module.context[@"Function"]]) {
        [callback callWithArguments:@[]];
    }
}

+ (NSDictionary*) keyCodes {
    return keyCodes;
}

static void MapKeyCode(NSString* key, int code) {
    keyCodes[key] = @(code);
    codeKeys[@(code)] = key;
}

+ (void) recacheKeycodes {
    keyCodes = [NSMutableDictionary dictionary];
    codeKeys = [NSMutableDictionary dictionary];
    
    int relocatableKeyCodes[] = {
        kVK_ANSI_A, kVK_ANSI_B, kVK_ANSI_C, kVK_ANSI_D, kVK_ANSI_E, kVK_ANSI_F,
        kVK_ANSI_G, kVK_ANSI_H, kVK_ANSI_I, kVK_ANSI_J, kVK_ANSI_K, kVK_ANSI_L,
        kVK_ANSI_M, kVK_ANSI_N, kVK_ANSI_O, kVK_ANSI_P, kVK_ANSI_Q, kVK_ANSI_R,
        kVK_ANSI_S, kVK_ANSI_T, kVK_ANSI_U, kVK_ANSI_V, kVK_ANSI_W, kVK_ANSI_X,
        kVK_ANSI_Y, kVK_ANSI_Z, kVK_ANSI_0, kVK_ANSI_1, kVK_ANSI_2, kVK_ANSI_3,
        kVK_ANSI_4, kVK_ANSI_5, kVK_ANSI_6, kVK_ANSI_7, kVK_ANSI_8, kVK_ANSI_9,
        kVK_ANSI_Grave, kVK_ANSI_Equal, kVK_ANSI_Minus, kVK_ANSI_RightBracket,
        kVK_ANSI_LeftBracket, kVK_ANSI_Quote, kVK_ANSI_Semicolon, kVK_ANSI_Backslash,
        kVK_ANSI_Comma, kVK_ANSI_Slash, kVK_ANSI_Period,
    };
    
    TISInputSourceRef currentKeyboard = TISCopyCurrentKeyboardInputSource();
    CFDataRef layoutData = TISGetInputSourceProperty(currentKeyboard, kTISPropertyUnicodeKeyLayoutData);
    
    if (layoutData) {
        const UCKeyboardLayout *keyboardLayout = (const UCKeyboardLayout *)CFDataGetBytePtr(layoutData);
        UInt32 keysDown = 0;
        UniChar chars[4];
        UniCharCount realLength;
        
        for (int i = 0 ; i < (int)(sizeof(relocatableKeyCodes)/sizeof(relocatableKeyCodes[0])) ; i++) {
            UCKeyTranslate(keyboardLayout,
                           relocatableKeyCodes[i],
                           kUCKeyActionDisplay,
                           0,
                           LMGetKbdType(),
                           kUCKeyTranslateNoDeadKeysBit,
                           &keysDown,
                           sizeof(chars) / sizeof(chars[0]),
                           &realLength,
                           chars);
            
            NSString* name = [NSString stringWithCharacters:chars length:1];
            
            MapKeyCode(name, relocatableKeyCodes[i]);
        }
    }
    else {
        MapKeyCode(@"a", kVK_ANSI_A);
        MapKeyCode(@"b", kVK_ANSI_B);
        MapKeyCode(@"c", kVK_ANSI_C);
        MapKeyCode(@"d", kVK_ANSI_D);
        MapKeyCode(@"e", kVK_ANSI_E);
        MapKeyCode(@"f", kVK_ANSI_F);
        MapKeyCode(@"g", kVK_ANSI_G);
        MapKeyCode(@"h", kVK_ANSI_H);
        MapKeyCode(@"i", kVK_ANSI_I);
        MapKeyCode(@"j", kVK_ANSI_J);
        MapKeyCode(@"k", kVK_ANSI_K);
        MapKeyCode(@"l", kVK_ANSI_L);
        MapKeyCode(@"m", kVK_ANSI_M);
        MapKeyCode(@"n", kVK_ANSI_N);
        MapKeyCode(@"o", kVK_ANSI_O);
        MapKeyCode(@"p", kVK_ANSI_P);
        MapKeyCode(@"q", kVK_ANSI_Q);
        MapKeyCode(@"r", kVK_ANSI_R);
        MapKeyCode(@"s", kVK_ANSI_S);
        MapKeyCode(@"t", kVK_ANSI_T);
        MapKeyCode(@"u", kVK_ANSI_U);
        MapKeyCode(@"v", kVK_ANSI_V);
        MapKeyCode(@"w", kVK_ANSI_W);
        MapKeyCode(@"x", kVK_ANSI_X);
        MapKeyCode(@"y", kVK_ANSI_Y);
        MapKeyCode(@"z", kVK_ANSI_Z);
        MapKeyCode(@"0", kVK_ANSI_0);
        MapKeyCode(@"1", kVK_ANSI_1);
        MapKeyCode(@"2", kVK_ANSI_2);
        MapKeyCode(@"3", kVK_ANSI_3);
        MapKeyCode(@"4", kVK_ANSI_4);
        MapKeyCode(@"5", kVK_ANSI_5);
        MapKeyCode(@"6", kVK_ANSI_6);
        MapKeyCode(@"7", kVK_ANSI_7);
        MapKeyCode(@"8", kVK_ANSI_8);
        MapKeyCode(@"9", kVK_ANSI_9);
        MapKeyCode(@"`", kVK_ANSI_Grave);
        MapKeyCode(@"=", kVK_ANSI_Equal);
        MapKeyCode(@"-", kVK_ANSI_Minus);
        MapKeyCode(@"]", kVK_ANSI_RightBracket);
        MapKeyCode(@"[", kVK_ANSI_LeftBracket);
        MapKeyCode(@"\"", kVK_ANSI_Quote);
        MapKeyCode(@";", kVK_ANSI_Semicolon);
        MapKeyCode(@"\\", kVK_ANSI_Backslash);
        MapKeyCode(@",", kVK_ANSI_Comma);
        MapKeyCode(@"/", kVK_ANSI_Slash);
        MapKeyCode(@".", kVK_ANSI_Period);
    }
    
    CFRelease(currentKeyboard);
    
    MapKeyCode(@"f1", kVK_F1);
    MapKeyCode(@"f2", kVK_F2);
    MapKeyCode(@"f3", kVK_F3);
    MapKeyCode(@"f4", kVK_F4);
    MapKeyCode(@"f5", kVK_F5);
    MapKeyCode(@"f6", kVK_F6);
    MapKeyCode(@"f7", kVK_F7);
    MapKeyCode(@"f8", kVK_F8);
    MapKeyCode(@"f9", kVK_F9);
    MapKeyCode(@"f10", kVK_F10);
    MapKeyCode(@"f11", kVK_F11);
    MapKeyCode(@"f12", kVK_F12);
    MapKeyCode(@"f13", kVK_F13);
    MapKeyCode(@"f14", kVK_F14);
    MapKeyCode(@"f15", kVK_F15);
    MapKeyCode(@"f16", kVK_F16);
    MapKeyCode(@"f17", kVK_F17);
    MapKeyCode(@"f18", kVK_F18);
    MapKeyCode(@"f19", kVK_F19);
    MapKeyCode(@"f20", kVK_F20);
    
    MapKeyCode(@"pad.", kVK_ANSI_KeypadDecimal);
    MapKeyCode(@"pad*", kVK_ANSI_KeypadMultiply);
    MapKeyCode(@"pad+", kVK_ANSI_KeypadPlus);
    MapKeyCode(@"pad/", kVK_ANSI_KeypadDivide);
    MapKeyCode(@"pad-", kVK_ANSI_KeypadMinus);
    MapKeyCode(@"pad=", kVK_ANSI_KeypadEquals);
    MapKeyCode(@"pad0", kVK_ANSI_Keypad0);
    MapKeyCode(@"pad1", kVK_ANSI_Keypad1);
    MapKeyCode(@"pad2", kVK_ANSI_Keypad2);
    MapKeyCode(@"pad3", kVK_ANSI_Keypad3);
    MapKeyCode(@"pad4", kVK_ANSI_Keypad4);
    MapKeyCode(@"pad5", kVK_ANSI_Keypad5);
    MapKeyCode(@"pad6", kVK_ANSI_Keypad6);
    MapKeyCode(@"pad7", kVK_ANSI_Keypad7);
    MapKeyCode(@"pad8", kVK_ANSI_Keypad8);
    MapKeyCode(@"pad9", kVK_ANSI_Keypad9);
    MapKeyCode(@"padclear", kVK_ANSI_KeypadClear);
    MapKeyCode(@"padenter", kVK_ANSI_KeypadEnter);
    
    MapKeyCode(@"return", kVK_Return);
    MapKeyCode(@"tab", kVK_Tab);
    MapKeyCode(@"space", kVK_Space);
    MapKeyCode(@"delete", kVK_Delete);
    MapKeyCode(@"escape", kVK_Escape);
    MapKeyCode(@"help", kVK_Help);
    MapKeyCode(@"home", kVK_Home);
    MapKeyCode(@"pageup", kVK_PageUp);
    MapKeyCode(@"forwarddelete", kVK_ForwardDelete);
    MapKeyCode(@"end", kVK_End);
    MapKeyCode(@"pagedown", kVK_PageDown);
    MapKeyCode(@"left", kVK_LeftArrow);
    MapKeyCode(@"right", kVK_RightArrow);
    MapKeyCode(@"down", kVK_DownArrow);
    MapKeyCode(@"up", kVK_UpArrow);
    
    MapKeyCode(@"command", kVK_Command);
    MapKeyCode(@"control", kVK_Control);
    MapKeyCode(@"option", kVK_Option);
    MapKeyCode(@"shift", kVK_Shift);
}

@end

/**
 * module KeyString
 *
 * A string representing a valid keyboard key.
 *
 * For use with functions like Hotkey.activate and Keyboard.press. Normally you don't need to reference this list. Instead, start typing a string where a KeyString is expected, and press Control-Space to see a list of Autumn's auto-completion suggestions.
 *
 * We say it's "stringly typed" because it's just a string, but it may only have any of these values, and Autumn will automatically warn you if you pass anything else to a function that requires a KeyString.
 */

/**
 * type KeyString =
 *   "a" | "b" | "c" | "d" | "e" | "f"
 * | "g" | "h" | "i" | "j" | "k" | "l"
 * | "m" | "n" | "o" | "p" | "q" | "r"
 * | "s" | "t" | "u" | "v" | "w" | "x"
 * | "y" | "z" | "." | "," | ";"
 * | "=" | "-" | "]" | "[" | "\""
 * | "\\"| "/"| "'" | "`"
 * | "0" | "1" | "2" | "3" | "4"
 * | "5" | "6" | "7" | "8" | "9"
 * | "f1" | "f2" | "f3" | "f4"
 * | "f5" | "f6" | "f7" | "f8"
 * | "f9" | "f10"| "f11" | "f12"
 * | "f13" | "f14" | "f15" | "f16"
 * | "f17" | "f18" | "f19" | "f20"
 * | "pad." | "pad*" | "pad+"
 * | "pad-" | "pad=" | "pad/"
 * | "pad0" | "pad1" | "pad2"
 * | "pad3" | "pad4" | "pad5"
 * | "pad6" | "pad7" | "pad8"
 * | "pad9" | "padenter" | "padclear"
 * | "return" | "tab" | "space" | "delete"
 * | "escape" | "help" | "forwarddelete"
 * | "home" | "end" | "pageup" | "pagedown"
 * | "left" | "right" | "down" | "up";
 */

/**
 * module ModString
 *
 * A string representing a valid modifier key.
 *
 * For use with functions like Hotkey.activate and Keyboard.press. Normally you don't need to reference this list. Instead, start typing a string where a ModString is expected, and press Control-Space to see a list of Autumn's auto-completion suggestions.
 *
 * We say it's "stringly typed" because it's just a string, but it may only have any of these values, and Autumn will automatically warn you if you pass anything else to a function that requires a KeyString.
 */

/**
 * type ModString = 'command'
 *                | 'control'
 *                | 'option'
 *                | 'shift';
 */
