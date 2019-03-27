//
//  AppDelegate.m
//  Autumn
//

#import "AppDelegate.h"

#import "Env.h"
#import "Accessibility.h"
#import "PreferencesController.h"
#import "Notification.h"
#import "MainWindowController.h"
#import "Config.h"
#import "AppRegistrar.h"
#import "WindowRegistrar.h"
#import "ScreenRegistrar.h"
#import "UiStyleManager.h"

static void MoveIfNeeded(void);

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [[NSUserDefaults standardUserDefaults] registerDefaults:
     @{@"openWindowAtLaunch": @YES}];
    
    MoveIfNeeded();
    
    [Accessibility setup];
    [ScreenRegistrar.sharedRegistrar setup];
    [WindowRegistrar.sharedRegistrar setup];
    [AppRegistrar.sharedRegistrar setup];
    [Env setup];
    
    // Force the window to exist, even if the window isn't opened at launch,
    // so that the user's scripts can log to the console.
    MainWindowController* mainWindowController = MainWindowController.singleton;
    [mainWindowController window];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey: @"openWindowAtLaunch"]) {
        [mainWindowController showWindow: nil];
    }
    
    // start app
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey: @"runConfigsAtLaunch"] && Accessibility.enabled) {
        [Env start];
    }
    
    [UiStyleManager.sharedManager setup];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    [Config saveUserConfigImmediately];
    [Notification removeNotifications];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    if (!MainWindowController.singleton.window.visible) {
        [MainWindowController.singleton showWindow: nil];
    }
    return YES;
}






- (IBAction) showPreferences:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    [PreferencesController show];
}

- (IBAction) showAboutWindow:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    [NSApp orderFrontStandardAboutPanel:nil];
}

- (IBAction) showMainWindow:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    [MainWindowController.singleton showWindow: nil];
}

@end

static void MoveIfNeeded(void) {
    if ([NSUserDefaults.standardUserDefaults boolForKey: @"dontAskToMoveToAppsFolder"]) return;
    
    NSString* oldPath = NSBundle.mainBundle.bundlePath;
    if ([oldPath rangeOfString:@"/Applications/"].location != NSNotFound) return;
    
    NSString* userAppsPath = @"~/Applications/".stringByStandardizingPath;
    NSString* mainAppsPath = @"/Applications/".stringByStandardizingPath;
    BOOL isDir;
    BOOL userAppsExists = [NSFileManager.defaultManager fileExistsAtPath:userAppsPath isDirectory:&isDir];
    NSString* appsPath = (userAppsExists && isDir) ? userAppsPath : mainAppsPath;
    NSString* newPath = [appsPath stringByAppendingPathComponent: NSBundle.mainBundle.bundlePath.lastPathComponent];
    
    if ([NSFileManager.defaultManager fileExistsAtPath: newPath]) return;
    
    NSAlert* alert = [[NSAlert alloc] init];
    alert.messageText = [NSString stringWithFormat: @"Would you like Autumn to move itself to %s/Applications?", appsPath == userAppsPath ? "~" : ""];
    alert.informativeText = @"That way your Downloads folder stays decluttered.";
    [alert addButtonWithTitle: @"Move to Applications Folder"];
    [alert addButtonWithTitle: @"Do Not Move"];
    alert.showsSuppressionButton = YES;
    alert.suppressionButton.controlSize = NSControlSizeMini;
    alert.buttons.lastObject.keyEquivalent = @"\033";
    
    if ([alert runModal] != NSAlertFirstButtonReturn) {
        if (alert.suppressionButton.state == NSControlStateValueOn) {
            [NSUserDefaults.standardUserDefaults setBool:YES forKey:@"dontAskToMoveToAppsFolder"];
        }
        return;
    }
    
    BOOL worked = [NSFileManager.defaultManager moveItemAtPath: oldPath
                                                        toPath: newPath
                                                         error: nil];
    
    if (worked) {
        NSTask* restart = [[NSTask alloc] init];
        restart.launchPath = @"/bin/bash";
        restart.arguments = @[@"-c", [NSString stringWithFormat:@"while kill -0 %d; do true; done; open '%@'", NSProcessInfo.processInfo.processIdentifier, [newPath stringByReplacingOccurrencesOfString:@"'" withString:@"\'"]]];
        [restart launch];
        exit(0);
    }
    else {
        NSAlert* alert = [[NSAlert alloc] init];
        alert.messageText = @"Could not move to Applications folder.";
        alert.informativeText = @"There was an error trying to move the app for you.";
        [alert runModal];
    }
}
