//
//  ConsoleViewController.m
//  Autumn
//

#import "ConsoleViewController.h"
#import "Env.h"
#import "MainWindowController.h"
#import "Config.h"
#import "DataUtils.h"
#import "UiStyleManager.h"

@implementation ConsoleViewController

- (void) setup {
    self.resourceFilename = @"console.html";
    
    BOOL darkMode = NO;
    if (@available(macOS 10.14, *)) {
        darkMode = NSApp.effectiveAppearance == [NSAppearance appearanceNamed: NSAppearanceNameDarkAqua];
    }
    
    NSString* json = [DataUtils jsonFromObject: @{@"ecma": [DataUtils fileAsString:@"base.ts"],
                                                  @"apis": [DataUtils fileAsString:@"types.ts"],
                                                  @"darkMode": darkMode ? @YES : @NO}];
    
    [self runScriptAtStart: [NSString stringWithFormat: @"autumnConfig = %@;", json]];
    
     
    __weak typeof(self) weakSelf = self;
    
    [self handleScript:@"eval" handler:^(NSString* input) {
        RunResult* output = [Env.js runString: input
                                       source: @"<console>"];
        
        NSNumber* saveId = [Env.js saveResult: output.object];
        
        [weakSelf logInspectedObject: output.jsonInspectableObject
                           fromInput: input
                          withSaveId: saveId ?: [NSNull null]];
        
        
    }];
}

- (void) logError:(NSString*)errorMessage
         location:(NSString*)errorLocation
{
    [self send: @[@"autumn_logError", errorMessage, errorLocation]];
}

- (void) logInspectedObject:(NSString*)str {
    [self send: @[@"autumn_logInspectedObject", str]];
}

- (void) logInspectedObject:(NSString*)str fromInput:(NSString*)input withSaveId:(id)saveId {
    [self send: @[@"autumn_logInspectedObjectSaved", str, input, saveId]];
}

- (void) clearConsole {
    [self send:@[@"autumn_clearConsole"]];
}

- (void) focusConsole {
    [self.webView evaluateJavaScript:@"autumn_focus()" completionHandler:nil];
}

- (void) userScriptWasRun:(NSString*)userScript {
    [self send: @[@"autumn_userScriptWasRun", userScript]];
}

- (void) userScriptWasStopped {
    [self.webView evaluateJavaScript:@"autumn_userScriptWasStopped()" completionHandler:nil];
}

- (void) runSelection:(NSString*)selection {
    [self send: @[@"autumn_runEditorSelection", selection]];
}

@end
