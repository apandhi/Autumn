//
//  SetupWindowController.m
//  Autumn
//

#import "PreferencesController.h"
#import "Accessibility.h"
#import "LoginLauncher.h"
#import "Config.h"
#import "UiStyleManager.h"

static PreferencesController* singleton;

@interface PreferencesController () <NSWindowDelegate, AccessibilityStatusObserver>
@end

@implementation PreferencesController {
    IBOutlet __weak NSButton* accessibilityButton;
    IBOutlet __weak NSButton* launchAtLoginButton;
    
    IBOutlet __weak NSButton* saveButtonUserDefaults;
    IBOutlet __weak NSButton* saveButtonHomeDirectory;
    
    IBOutlet __weak NSButton* uiStyleDockButton;
    IBOutlet __weak NSButton* uiStyleMenuButton;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    [Accessibility addObserver: self];
    launchAtLoginButton.state = LoginLauncher.isEnabled ? NSControlStateValueOn : NSControlStateValueOff;
    
    BOOL storeInFile = [Config shouldStoreInFile];
    (storeInFile ? saveButtonHomeDirectory : saveButtonUserDefaults).state = NSControlStateValueOn;
    
    (UiStyleManager.sharedManager.useStatusMenu ? uiStyleMenuButton : uiStyleDockButton).state = NSControlStateValueOn;
    
    [self.window center];
}

- (NSString*) windowNibName {
    return [self className];
}

- (void) accessibilityStatusChanged:(BOOL)enabled {
    accessibilityButton.enabled = !enabled;
    accessibilityButton.image = [NSImage imageNamed: enabled ? NSImageNameStatusAvailable : NSImageNameStatusPartiallyAvailable];
    accessibilityButton.title = enabled ? @"Accessibility is Enabled" : @"Enable Accessibility";
    [accessibilityButton sizeToFit];
}

- (IBAction) toggleLaunchAtLogin:(NSButton*)sender {
    [LoginLauncher setEnabled: sender.state == NSControlStateValueOn];
}

- (IBAction) enableAccessibility:(id)sender {
    [Accessibility openPanel];
}

- (IBAction) changeUiStyle:(NSButton*)sender {
    UiStyleManager.sharedManager.useStatusMenu = (sender == uiStyleMenuButton);
}

- (IBAction) changeStorageMethod:(NSButton*)sender {
    NSString* config = [Config loadUserConfig];
    
    BOOL oldShouldStoreInFile = [Config shouldStoreInFile];
    BOOL newShouldStoreInFile = (sender == saveButtonHomeDirectory);
    
    if (!oldShouldStoreInFile && newShouldStoreInFile) {
        BOOL isDir;
        BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:Config.configPath isDirectory:&isDir];
        
        if (exists) {
            if (isDir) {
                saveButtonUserDefaults.state = NSControlStateValueOn;
                NSAlert* alert = [[NSAlert alloc] init];
                alert.messageText = @"There's a directory at this location.";
                alert.informativeText = [NSString stringWithFormat: @"Changing where your user script is stored has been canceled to prevent data loss. To store the contents of your user script at \"%@\", move the directory and try again.", Config.configPath];
                [alert beginSheetModalForWindow:self.window completionHandler:nil];
                return;
            }
            
            NSString* onDiskConfig = [NSString stringWithContentsOfFile:Config.configPath encoding:NSUTF8StringEncoding error:nil];
            if (!onDiskConfig || ![onDiskConfig isEqualToString: Config.latestUserScript]) {
                saveButtonUserDefaults.state = NSControlStateValueOn;
                NSAlert* alert = [[NSAlert alloc] init];
                alert.messageText = @"There's already a file at this location.";
                alert.informativeText = [NSString stringWithFormat: @"Changing where your user script is stored has been canceled to prevent data loss. To store the contents of your user script at \"%@\", move the file and try again.", Config.configPath];
                [alert beginSheetModalForWindow:self.window completionHandler:nil];
                return;
            }
        }
    }
    
    [Config setShouldStoreInFile: newShouldStoreInFile];
    [Config saveUserConfig: config];
}

- (void) windowWillClose:(NSNotification *)notification {
    [Accessibility removeObserver: self];
    singleton = nil;
}

+ (void) show {
    if (!singleton) {
        singleton = [[PreferencesController alloc] init];
    }
    
    [singleton showWindow: nil];
}

@end
