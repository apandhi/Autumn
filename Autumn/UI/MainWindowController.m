//
//  EditorWindow.m
//  Autumn
//

#import "MainWindowController.h"
#import "EditorViewController.h"
#import "ConsoleViewController.h"
#import "DocsViewController.h"
#import "Accessibility.h"
#import "Env.h"
#import "LoadingWordsBuilder.h"

@interface MainWindowController () <EnvStatusDelegate, AccessibilityStatusObserver, WebViewControllerDelegate, AccessibilityWarner, NSSplitViewDelegate>
@end

@implementation MainWindowController {
    IBOutlet __weak NSSegmentedControl* startStopButton;
    IBOutlet __weak NSSearchField* searchField;
    
    IBOutlet NSView* waitingView;
    IBOutlet __weak NSTextField* waitingLabel;
    IBOutlet __weak NSProgressIndicator* spinner;
    int doneLoadingCount;
    
    IBOutlet __weak NSSplitView* mainSplit;
    IBOutlet __weak NSSplitView* innerSplit;
    
    IBOutlet __weak NSView* editorContainer;
    IBOutlet __weak NSView* consoleContainer;
    IBOutlet __weak NSView* docsContainer;
    
    IBOutlet __weak NSButton* playbookButton;
    
    EditorViewController* editorVc;
    ConsoleViewController* consoleVc;
    DocsViewController* docsVc;
    
    double zoom;
}

- (NSString*) windowNibName {
    return [self className];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    if (@available(macOS 10.14, *)) {
        [self.window.toolbar insertItemWithItemIdentifier:NSToolbarFlexibleSpaceItemIdentifier atIndex:2];
        [self.window.toolbar setCenteredItemIdentifier:@"playPause"];
    }
    
    waitingView.frame = self.window.contentView.bounds;
    [self.window.contentView addSubview: waitingView
                             positioned: NSWindowAbove
                             relativeTo: nil];
    
    [self.window setMovableByWindowBackground:YES];
    
    [Accessibility setWarner: self];
    
    [Accessibility addObserver: self];
    Env.envStatusDelegate = self;
    
    waitingLabel.stringValue = [LoadingWordsBuilder makePhrase];
    [spinner startAnimation: nil];
    
    mainSplit.autosaveName = @"mainSplit";
    innerSplit.autosaveName = @"innerSplit";
    
    NSNumber* zoomObject = [NSUserDefaults.standardUserDefaults objectForKey: @"pageZoom"];
    zoom = zoomObject ? zoomObject.doubleValue : 1.0;
    
    editorVc = [[EditorViewController alloc] init];
    consoleVc = [[ConsoleViewController alloc] init];
    docsVc = [[DocsViewController alloc] init];
    
    editorVc.webViewControllerDelegate = self;
    [editorVc makeWebView: editorContainer.bounds initialZoom: zoom];
    [editorContainer addSubview: editorVc.webView];
    
    consoleVc.webViewControllerDelegate = self;
    [consoleVc makeWebView: consoleContainer.bounds initialZoom: zoom];
    [consoleContainer addSubview: consoleVc.webView];
    
    docsVc.webViewControllerDelegate = self;
    [docsVc makeWebView: docsContainer.bounds initialZoom: zoom];
    [docsContainer addSubview: docsVc.webView];
    
    innerSplit.delegate = self;
}

- (NSRect)splitView:(NSSplitView *)splitView effectiveRect:(NSRect)proposedEffectiveRect forDrawnRect:(NSRect)drawnRect ofDividerAtIndex:(NSInteger)dividerIndex {
    proposedEffectiveRect.size.height += (22.0 * zoom);
    return proposedEffectiveRect;
}

- (void)accessibilityNeedsVisibleWarning {
    [self.class cancelPreviousPerformRequestsWithTarget:self selector:@selector(accessibilityNeedsVisibleWarningMaybe) object:nil];
    [self performSelector:@selector(accessibilityNeedsVisibleWarningMaybe) withObject:nil afterDelay:0.1];
}

- (void) accessibilityNeedsVisibleWarningMaybe {
    BOOL avoidNotification = ([NSApp isActive] && self.window.keyWindow);
    [Env.js warnAndStop: avoidNotification];
    [self showAccessibilitySheet];
}

- (void)accessibilityStatusChanged:(BOOL)enabled {
    if (enabled) {
        NSUInteger removeIndex = [[self.window.toolbar.visibleItems valueForKey:@"itemIdentifier"] indexOfObject:@"fixIssues"];
        if (removeIndex != NSNotFound) {
            [self.window.toolbar removeItemAtIndex: removeIndex];
        }
    }
    else {
        NSUInteger insertIndex = [[self.window.toolbar.visibleItems valueForKey:@"itemIdentifier"] indexOfObject:@"playPause"];
        [self.window.toolbar insertItemWithItemIdentifier:@"fixIssues" atIndex:insertIndex];
    }
}

- (void)envStatusChanged {
    BOOL running = Env.running;
    [startStopButton setEnabled:running forSegment:1];
}

- (void)webViewLoaded {
    spinner.animator.doubleValue = ++doneLoadingCount;
    if (doneLoadingCount < 3) return;
    
    NSRect f = waitingView.layer.frame;
    waitingView.layer.anchorPoint = CGPointMake(0.5, 0.5);
    waitingView.layer.frame = f;
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
        context.duration = 0.3;
        context.allowsImplicitAnimation = YES;
        
        self->waitingView.layer.affineTransform = CGAffineTransformMakeScale(1.5, 1.5);
        self->waitingView.animator.alphaValue = 0;
    } completionHandler:^{
        [self->waitingView removeFromSuperview];
        self->waitingView = nil;
    }];
}

- (void) userScriptWasRun:(NSString*)userScript {
    [consoleVc userScriptWasRun: userScript];
}

- (void) userScriptWasStopped {
    [consoleVc userScriptWasStopped];
}

- (IBAction) startStopScript:(NSSegmentedControl*)sender {
    if (sender.indexOfSelectedItem == 0) {
        [self startScript: nil];
    }
    else {
        [self stopScript: nil];
    }
}

- (IBAction) startScript:(id)sender {
    if (Env.running) [Env stop];
    [Env start];
}

- (IBAction) stopScript:(id)sender {
    [Env stop];
}

- (IBAction) focusConsole:(id)sender {
    [editorVc blur];
    [self.window makeFirstResponder: consoleVc.webView];
    [consoleVc focusConsole];
}

- (IBAction) focusEditor:(id)sender {
    [consoleVc blur];
    [self.window makeFirstResponder: editorVc.webView];
    [editorVc focusEditor];
}

- (void) focusSearch {
    [editorVc blur];
    [consoleVc blur];
    [self.window makeFirstResponder: searchField];
}

- (IBAction) focusDocs:(id)sender {
    [self focusSearch];
}

- (IBAction) sendSelectionToConsole:(id)sender {
    [editorVc runSelectionInConsole];
}

- (void) runInConsole:(NSString*)selection {
    [consoleVc runSelection: selection];
}

- (IBAction) fixIssues:(id)sender {
    [self showAccessibilitySheet];
}

- (void) showAccessibilitySheet {
    NSAlert* alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleWarning;
    alert.messageText = @"Accessibility is not enabled for Autumn";
    alert.informativeText = @"Many of Autumn's useful capabilities require Accessibility to be enabled, such as positioning windows in other apps.";
    [alert addButtonWithTitle: @"Enable Accessibility"];
    [alert addButtonWithTitle: @"Cancel"];
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (returnCode == NSAlertFirstButtonReturn) {
                [Accessibility openPanel];
                [NSWorkspace.sharedWorkspace launchAppWithBundleIdentifier:@"com.apple.systempreferences"
                                                                   options:(NSWorkspaceLaunchWithoutActivation)
                                            additionalEventParamDescriptor:nil
                                                          launchIdentifier:nil];
            }
        });
    }];
}

- (IBAction) showPlaybook:(id)sender {
    [docsVc togglePlaybook: (playbookButton.state == NSControlStateValueOn)];
}

- (IBAction) searchDocs:(NSSearchField*)sender {
    playbookButton.state = NSControlStateValueOff;
    [docsVc togglePlaybook: NO];
    [docsVc searchDocs: sender.stringValue];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if ([menuItem action] == @selector(startScript:)) return YES;
    if ([menuItem action] == @selector(stopScript:)) return Env.running;
    return YES;
}

- (void) logError:(NSString*)errorMessage
         location:(NSString*)errorLocation {
    [consoleVc logError:errorMessage
               location:errorLocation];
}

- (void) logInspectedObject:(NSString*)str {
    [consoleVc logInspectedObject: str];
}

- (void) clearConsole {
    [consoleVc clearConsole];
}

+ (MainWindowController*) singleton {
    static MainWindowController* singleton;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[MainWindowController alloc] init];
    });
    return singleton;
}

- (void) clearSearch {
    searchField.stringValue = @"";
}

- (void) docsDidHidePlaybook {
    playbookButton.state = NSControlStateValueOff;
}

- (IBAction) increaseMagnification:(id)sender {
    [self zoomTo: MIN(3.0, zoom + 0.1)];
}

- (IBAction) decreaseMagnification:(id)sender {
    [self zoomTo: MAX(0.5, zoom - 0.1)];
}

- (IBAction) resetMagnification:(id)sender {
    [self zoomTo: 1];
}

- (void) zoomTo:(double)zoomTo {
    zoom = zoomTo;
    [NSUserDefaults.standardUserDefaults setDouble:zoom forKey:@"pageZoom"];
    
    [docsVc zoomTo: zoom];
    [consoleVc zoomTo: zoom];
    [editorVc zoomTo: zoom];
    
    [self.window invalidateCursorRectsForView: innerSplit];
}

@end
