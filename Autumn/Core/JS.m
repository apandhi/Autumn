//
//  JavaScriptBridge.m
//  Autumn
//

#import "JS.h"
#import "Notification.h"
#import "MainWindowController.h"
#import "DataUtils.h"
#import "MainWindowController.h"
#import "Env.h"
#import "Alert.h"

@implementation RunResult
@end

@implementation JS {
    JSContext* ctx;
    NSMutableArray<NSString*>* requireStack;
    NSMutableArray* timers;
    NSMutableArray* saveIds;
}

- (JSValue*) loadFile:(NSString*)path {
    if (![path hasSuffix: @".js"]) path = [path stringByAppendingPathExtension: @"js"];
    if (![path hasPrefix: @"/"])   path = [requireStack.lastObject.stringByDeletingLastPathComponent stringByAppendingPathComponent: path];
    path = path.stringByStandardizingPath;
    
    __autoreleasing NSError* error;
    NSString* script = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if (!script) {
        [self showError: [NSString stringWithFormat:@"Error loading config file: %@", path]
               location: error.localizedDescription
      avoidNotification: NO];
        
        NSLog(@"error loading file at [%@]: %@", path, error);
        return nil;
    }
    
    JSValue* lastModule = ctx[@"module"];
    ctx[@"module"] = @{};
    
    [requireStack addObject: path];
    [self evalTypeScript: script];
    [requireStack removeLastObject];
    
    JSValue* result = ctx[@"module"][@"exports"];
    
    ctx[@"module"] = lastModule;
    
    return result;
}

- (NSNumber*) saveResult:(JSValue*)result {
    if (result.isUndefined || result.isNull || result.isBoolean) return nil;
    if (![saveIds containsObject: result]) {
        [saveIds addObject: result];
    }
    NSNumber* saveId = @([saveIds indexOfObject: result] + 1);
    ctx[[NSString stringWithFormat:@"$%@", saveId]] = result;
    return saveId;
}

- (RunResult*) runString:(NSString*)str source:(NSString*)source {
    RunResult* runResult = [[RunResult alloc] init];
    
    [requireStack addObject: source];
    runResult.object = [self evalTypeScript: str];
    [requireStack removeLastObject];
    
    runResult.jsonInspectableObject = [ctx[@"_inspect"] callWithArguments: @[runResult.object]].toString;
    
    return runResult;
}

- (JSValue*) evalTypeScript:(NSString*)ts {
    if ([ts hasPrefix: @"{"] && [ts hasSuffix: @"}"]) ts = [NSString stringWithFormat:@"(%@)", ts];
    JSValue* result = [ctx[@"tsc"] callWithArguments: @[ts]];
    return [ctx evaluateScript: result[@"outputText"].toString];
}

- (void) showError:(NSString*)errorMessage location:(NSString*)errorLocation avoidNotification:(BOOL)avoidNotification {
    [MainWindowController.singleton logError:errorMessage
                                    location:errorLocation];
    
    NSUserNotification* note = [[NSUserNotification alloc] init];
    note.title = @"Autumn script error";
    note.subtitle = errorMessage;
    note.informativeText = errorLocation;
    
    if (!avoidNotification) {
        [Notification deliverNotification:note
                                  onClick:^{
                                      [MainWindowController.singleton showWindow: nil];
                                  }
                                forceShow:!(NSApp.isActive
                                            && MainWindowController.singleton.windowLoaded
                                            && MainWindowController.singleton.window.isKeyWindow)];
    }
}

- (void) showErrorFromException:(JSValue*)exception {
    NSString* errorMessage = exception.toString;
    NSLog(@"%@:%@ %@", exception[@"line"], exception[@"column"], exception);
    NSString* errorLocation = [NSString stringWithFormat:@"%@ %@:%@", [requireStack.lastObject lastPathComponent], exception[@"line"], exception[@"column"]];
    [self showError:errorMessage
           location:errorLocation
  avoidNotification:exception[@"avoidNotification"].toBool];
}


- (NSNumber*) createTimer:(JSValue*)fn delay:(NSNumber*)seconds repeats:(BOOL)repeats {
    NSTimer* timer = [NSTimer scheduledTimerWithTimeInterval:seconds.doubleValue/1000.0 repeats:repeats block:^(NSTimer * _Nonnull timer) {
        [fn callWithArguments: @[]];
    }];
    NSUInteger timerId = timers.count;
    [timers addObject: timer];
    return @(timerId);
}

- (instancetype) init {
    if (self = [super init]) {
        requireStack = [NSMutableArray array];
        saveIds = [NSMutableArray array];
        
        ctx = [[JSContext alloc] init];
        
        __weak typeof(self) weakSelf = self;
        ctx.exceptionHandler = ^(JSContext *context, JSValue *exception) {
            [weakSelf showErrorFromException: exception];
        };
        
        static NSString* prelude;
        static dispatch_once_t preludeToken;
        dispatch_once(&preludeToken, ^{
            prelude = [DataUtils fileAsString: @"prelude.js"];
        });
        [ctx evaluateScript: prelude];
        
        static NSString* tsc;
        static dispatch_once_t tscToken;
        dispatch_once(&tscToken, ^{
            tsc = [DataUtils fileAsString: @"tsc.js"];
        });
        [ctx evaluateScript: tsc];
        
        ctx[@"_localStorageGet"] = ^() {
            return [NSUserDefaults.standardUserDefaults stringForKey: @"_localStorage"];
        };
        
        ctx[@"_localStorageSet"] = ^(JSValue* blob) {
            if (blob.isString)
                [NSUserDefaults.standardUserDefaults setObject:blob.toString forKey:@"_localStorage"];
            else
                [NSUserDefaults.standardUserDefaults removeObjectForKey: @"_localStorage"];
        };
        
        ctx[@"global"] = ctx.globalObject;
        
        ctx[@"_print"] = ^(NSString* json) {
            [MainWindowController.singleton logInspectedObject: json];
        };
        
        // docs are in (global) section
        // types are in base.ts
        ctx[@"alert"] = ^(NSString* oneLineMsg) {
            NSArray<JSValue*>* args = JSContext.currentArguments;
            CGFloat duration = (args.count >= 2 && args[1].isNumber) ? args[1].toNumber.doubleValue : 2.0;
            [Alert show: oneLineMsg
               duration: duration];
        };
        
        ctx[@"require"] = ^JSValue*(NSString* path) {
            return [weakSelf loadFile: path];
        };
        
        ctx[@"console"][@"clear"] = ^() {
            [MainWindowController.singleton clearConsole];
        };
        
        timers = [NSMutableArray array];
        
        ctx[@"setTimeout"] = ^(JSValue* fn, NSNumber* delay) { return [weakSelf createTimer:fn delay:delay repeats:NO]; };
        ctx[@"setInterval"] = ^(JSValue* fn, NSNumber* delay) { return [weakSelf createTimer:fn delay:delay repeats:YES]; };
        ctx[@"clearInterval"] = ctx[@"clearTimeout"] = ^(NSNumber* timerId) {
            if (!weakSelf) return;
            typeof(self) strongSelf = weakSelf;
            NSMutableArray* timers = strongSelf->timers;
            NSUInteger i = timerId.unsignedIntegerValue;
            if (i >= timers.count) return;
            NSTimer* timer = timers[i];
            if ([timer isKindOfClass: [NSTimer class]]) {
                [timer invalidate];
                timers[i] = [NSNull null];
            }
        };
    }
    return self;
}

- (void) dealloc {
    for (id timer in timers) {
        if ([timer isKindOfClass: [NSTimer class]]) {
            [timer invalidate];
        }
    }
}

- (void) warnAndStop:(BOOL)avoidNotification {
    JSValue* e = [JSValue valueWithNewErrorFromMessage:@"This function needs accessibility to be enabled." inContext:ctx];
    e[@"avoidNotification"] = avoidNotification ? @YES : @NO;
    ctx.exception = e;
}

- (JSValue*) addModule:(id)module {
    NSString* name = [module respondsToSelector:@selector(overrideName)] ? [module overrideName] : [module className];
    ctx[name] = module;
    return ctx[name];
}

- (void) fixModules {
    static NSString* docsJson;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        docsJson = [DataUtils fileAsString: @"docs.json"];
    });
    [ctx[@"_fixModules"] callWithArguments: @[ctx.globalObject, docsJson]];
}

@end
