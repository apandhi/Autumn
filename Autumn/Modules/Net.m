//
//  Net.m
//  Autumn
//

#import "Net.h"

/**
 * module Net
 *
 * Access the internet.
 */
@implementation Net

+ (void)startModule:(JSValue *)ctor {
}

+ (void)stopModule {
}

/**
 * static get(url: string): Promise<string>;
 *
 * Gets the contents of the given url, and returns a promise that resolves to it as a UTF8 string, throwing if anything goes wrong.
 *
 * Note: only HTTPS-based URLs are allowed at this time.
 */
+ (JSValue*) get:(NSString*)url {
    return [JSContext.currentContext[@"Promise"] constructWithArguments:@[^(JSValue* resolve, JSValue* reject) {
        [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString: url] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSString* content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            dispatch_sync(dispatch_get_main_queue(), ^{
                if (content && !error) {
                    [resolve callWithArguments: @[content]];
                }
                else {
                    NSLog(@"%@", error);
                    [reject callWithArguments: @[]];
                }
            });
        }] resume];
    }]];
}

/**
 * static getSync(url: string): string | null;
 *
 * Gets the contents of the given url, and returns it as a UTF8 string, or null if anything goes wrong.
 *
 * Note: only HTTPS-based URLs are allowed at this time.
 */
+ (id) getSync:(NSString*)url {
    NSString* content = [NSString stringWithContentsOfURL:[NSURL URLWithString: url] encoding:NSUTF8StringEncoding error:nil];
    return content ?: [NSNull null];
}

@end
