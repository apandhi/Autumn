//
//  Shell.m
//  Autumn
//

#import "Shell.h"

/**
 * module Shell
 *
 * Run command line utilities.
 */
@implementation Shell

+ (void)startModule:(JSValue *)ctor {
}

+ (void)stopModule {
}

/**
 * static run(cmd: string): Promise<{
 *   code: number,
 *   stdout: string | null,
 *   stderr: string | null
 * }>;
 *
 * Runs the given command, and returns a promise that resolves to its exit code and stdout/stderr as UTF8 strings if possible & available.
 *
 * Tip: instead of using the promise directly, try using it in an async function like so:
 *
 *   (async function() {
 *     const result = await Shell.run('echo hello world');
 *     console.log(result)
 *   })()
 */
+ (id) run:(NSString*)cmd {
    NSPipe* outPipe = [NSPipe pipe];
    NSPipe* errPipe = [NSPipe pipe];
    
    NSTask* task = [[NSTask alloc] init];
    task.launchPath = @"/bin/bash";
    task.arguments = @[@"-c", cmd];
    task.standardOutput = outPipe;
    task.standardError = errPipe;
    
    JSValue* promise = [[JSContext currentContext][@"Promise"] constructWithArguments: @[^(JSValue* resolve) {
        task.terminationHandler = ^(NSTask* _Nonnull task) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString* output = [[NSString alloc] initWithData:outPipe.fileHandleForReading.readDataToEndOfFile encoding:NSUTF8StringEncoding];
                NSString* error = [[NSString alloc] initWithData:errPipe.fileHandleForReading.readDataToEndOfFile encoding:NSUTF8StringEncoding];
                [resolve callWithArguments: @[@{@"code": @(task.terminationStatus),
                                                @"stdout": output ?: NSNull.null,
                                                @"stderr": error ?: NSNull.null}]];
            });
        };
    }]];
    
    [task launch];
    
    return promise;
}

/**
 * static runSync(cmd: string): {
 *   code: number,
 *   stdout: string | null,
 *   stderr: string | null
 * };
 *
 * Runs the given command, and returns its exit code and stdout/stderr as UTF8 strings if possible & available.
 *
 * Note: this will halt Autumn until the shell command finishes, which may result in noticeable lag. If it may hang or take a while to complete, consider using the promise-based method above.
 */
+ (id) runSync:(NSString*)cmd {
    NSPipe* outPipe = [NSPipe pipe];
    NSPipe* errPipe = [NSPipe pipe];
    
    NSTask* task = [[NSTask alloc] init];
    task.launchPath = @"/bin/bash";
    task.arguments = @[@"-c", cmd];
    task.standardOutput = outPipe;
    task.standardError = errPipe;
    
    [task launch];
    [task waitUntilExit];
    
    NSString* output = [[NSString alloc] initWithData:outPipe.fileHandleForReading.readDataToEndOfFile encoding:NSUTF8StringEncoding];
    NSString* error = [[NSString alloc] initWithData:errPipe.fileHandleForReading.readDataToEndOfFile encoding:NSUTF8StringEncoding];
    return @{@"code": @(task.terminationStatus),
             @"stdout": output ?: NSNull.null,
             @"stderr": error ?: NSNull.null};
}

@end
