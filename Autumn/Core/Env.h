//
//  Env.h
//  Autumn
//

#import <Foundation/Foundation.h>
#import "JS.h"

@protocol EnvStatusDelegate
- (void) envStatusChanged;
- (void) userScriptWasRun:(NSString*)userScript;
- (void) userScriptWasStopped;
@end

@interface Env : NSObject

+ (void) setup;

+ (void) start;
+ (void) stop;

+ (BOOL) running;
+ (JS*) js;

@property (class) id<EnvStatusDelegate> envStatusDelegate;

@end
