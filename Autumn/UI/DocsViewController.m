//
//  DocsViewController.m
//  Autumn
//

#import "DocsViewController.h"
#import "Env.h"
#import "MainWindowController.h"
#import "Config.h"
#import "DataUtils.h"

@implementation DocsViewController

- (void) setup {
    self.resourceFilename = @"docs.html";
    
    NSString* playbook = [NSString stringWithFormat:@"%@%@%@%@",
                          [DataUtils fileAsString:@"playbook.ts"],
                          @"\n\n\n\n\n/**\n * Here's the sample code Autumn started with:\n */\n\n",
                          [DataUtils fileAsString:@"sample.ts"],
                          @"\n\n\n\n\n/**\n * This is the end of the Playbook\n */"];
    
    BOOL darkMode = NO;
    if (@available(macOS 10.14, *)) {
        darkMode = NSApp.effectiveAppearance == [NSAppearance appearanceNamed: NSAppearanceNameDarkAqua];
    }
    
    NSString* json = [DataUtils jsonFromObject: @{@"darkMode": darkMode ? @YES : @NO,
                                                  @"playbook": playbook}];
    
    [self runScriptAtStart: [NSString stringWithFormat: @"autumnConfig = %@;", json]];
    [self runScriptAtStart: [NSString stringWithFormat: @"docsJson = %@;", [DataUtils fileAsString:@"docs.json"]]];
    
    [self handleScript:@"clearSearch" handler:^(id null) {
        [MainWindowController.singleton clearSearch];
    }];
    
    [self handleScript:@"focusSearch" handler:^(id null) {
        [MainWindowController.singleton focusSearch];
    }];
    
    [self handleScript:@"didHidePlaybook" handler:^(id null) {
        [MainWindowController.singleton docsDidHidePlaybook];
    }];
}

- (void) searchDocs:(NSString*)str {
    [self send: @[@"autumn_searchDocs", str]];
}

- (void) togglePlaybook:(BOOL)visible {
    [self send: @[@"autumn_togglePlaybook", @(visible)]];
}

@end
