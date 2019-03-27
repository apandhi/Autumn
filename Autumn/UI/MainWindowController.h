//
//  EditorWindow.h
//  Autumn
//

#import <Cocoa/Cocoa.h>

@interface MainWindowController : NSWindowController

+ (MainWindowController*) singleton;

- (void) logError:(NSString*)errorMessage
         location:(NSString*)errorLocation;

- (void) logInspectedObject:(NSString*)str;

- (void) clearConsole;

- (void) clearSearch;
- (void) focusSearch;
- (void) docsDidHidePlaybook;

- (void) runInConsole:(NSString*)selection;

@end
