//
//  ConsoleViewController.h
//  Autumn
//

#import <Cocoa/Cocoa.h>
#import "WebViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface ConsoleViewController : WebViewController

- (void) logError:(NSString*)errorMessage
         location:(NSString*)errorLocation;

- (void) logInspectedObject:(NSString*)str;

- (void) clearConsole;
- (void) focusConsole;

- (void) userScriptWasRun:(NSString*)userScript;
- (void) userScriptWasStopped;

- (void) runSelection:(NSString*)selection;

@end

NS_ASSUME_NONNULL_END
