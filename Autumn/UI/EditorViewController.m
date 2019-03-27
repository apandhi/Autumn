//
//  EditorViewController.m
//  Autumn
//

#import "EditorViewController.h"
#import "Env.h"
#import "MainWindowController.h"
#import "Config.h"
#import "DataUtils.h"

@implementation EditorViewController

- (void) setup {
    self.resourceFilename = @"editor.html";
    
    BOOL darkMode = NO;
    if (@available(macOS 10.14, *)) {
        darkMode = NSApp.effectiveAppearance == [NSAppearance appearanceNamed: NSAppearanceNameDarkAqua];
    }
    
    NSString* json = [DataUtils jsonFromObject: @{@"ecma": [DataUtils fileAsString:@"base.ts"],
                                                  @"apis": [DataUtils fileAsString:@"types.ts"],
                                                  @"code": [Config loadUserConfig],
                                                  @"darkMode": darkMode ? @YES : @NO}];
    
    [self runScriptAtStart: [NSString stringWithFormat: @"autumnConfig = %@;", json]];
    
    [self handleScript:@"editorCodeChanged" handler:^(NSString* text) {
        [Config saveUserConfig: text];
    }];
    
    [self handleScript:@"sendSelectionToConsole" handler:^(NSString* input) {
        [MainWindowController.singleton runInConsole: input];
    }];
}

- (void) focusEditor {
    [self.webView evaluateJavaScript:@"autumn_focus()" completionHandler:nil];
}

- (void) runSelectionInConsole {
    [self.webView evaluateJavaScript:@"autumn_sendSelection()" completionHandler:nil];
}

@end
