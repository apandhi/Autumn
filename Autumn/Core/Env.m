//
//  Env.m
//  Autumn
//

#import "Env.h"

#import <objc/runtime.h>
#import "JS.h"
#import "Module.h"
#import "Config.h"
#import "UiStyleManager.h"

static JS* js;
static BOOL running;
static id<EnvStatusDelegate> delegate;
static NSMutableArray<id<Module>>* modules;

@implementation Env

+ (void) setup {
    modules = [NSMutableArray array];
    unsigned int classCount;
    Class* classes = objc_copyClassList(&classCount);
    for (unsigned int i = 0; i < classCount; i++) {
        Class c = classes[i];
        if (class_conformsToProtocol(c, @protocol(Module))) {
            [modules addObject: (id)c];
        }
    }
    free(classes);
    
    [self startModules];
}

+ (id<EnvStatusDelegate>) envStatusDelegate {
    return delegate;
}

+ (void) setEnvStatusDelegate:(id<EnvStatusDelegate>)envStatusDelegate {
    delegate = envStatusDelegate;
    [delegate envStatusChanged];
}

+ (void) start {
    running = YES;
    [delegate envStatusChanged];
    NSString* userScript = [Config loadUserConfig];
    [js runString: userScript
           source: @"<user script>"];
    [delegate userScriptWasRun: userScript];
}

+ (void) stop {
    [self stopModules];
    [self startModules];
    running = NO;
    [delegate envStatusChanged];
    [delegate userScriptWasStopped];
}

+ (void) stopModules {
    for (id<Module> module in modules) {
        [module stopModule];
    }
}

+ (void) startModules {
    js = [[JS alloc] init];
    for (Class<Module> module in modules) {
        JSValue* moduleNamespace = [js addModule: module];
        [module startModule: moduleNamespace];
    }
    [js fixModules];
}

+ (BOOL) running {
    return running;
}

+ (JS*) js {
    return js;
}

@end
