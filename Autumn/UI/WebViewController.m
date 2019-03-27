//
//  WebViewController.m
//  Autumn
//

#import "WebViewController.h"
#import "KeyValueObserver.h"
#import "DataUtils.h"


@interface CallbackBasedMessageHandler : NSObject <WKScriptMessageHandler>
@property void(^fn)(NSString*);
@end

@implementation CallbackBasedMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    _fn(message.body);
}

@end


@interface WebViewController () <WKNavigationDelegate>
@end

@implementation WebViewController {
    KeyValueObserver* appearanceObserver;
    WKUserContentController* userContentController;
    NSMutableArray* prelog;
}

- (void) makeWebView:(NSRect)bounds initialZoom:(double)zoom {
    prelog = [NSMutableArray array];
    
    userContentController = [[WKUserContentController alloc] init];
    
    [self runScriptAtStart: [NSString stringWithFormat: @"pageZoom = %.02f;", zoom]];
    
    [self setup];
    
    WKWebViewConfiguration* config = [[WKWebViewConfiguration alloc] init];
    config.userContentController = userContentController;
    
#if DEBUG
    [config.preferences setValue:@YES forKey:@"developerExtrasEnabled"];
#endif
    
    userContentController = nil;
    
    WKWebView* webView = [[WKWebView alloc] initWithFrame:bounds configuration:config];
    webView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    
    if (NSAppKitVersionNumber > 1500) {
        [webView setValue:@NO forKey:@"drawsBackground"];
    }
    else {
        [webView setValue:@YES forKey:@"drawsTransparentBackground"];
    }
    
    NSURL* url = [[NSBundle mainBundle] URLForResource: _resourceFilename.stringByDeletingPathExtension
                                         withExtension: _resourceFilename.pathExtension];
    [webView loadFileURL: url allowingReadAccessToURL: url.URLByDeletingLastPathComponent];
    webView.navigationDelegate = self;
    
    __weak typeof(self) weakSelf = self;
    appearanceObserver = [[KeyValueObserver alloc] init];
    [appearanceObserver observe:@"effectiveAppearance"
                             on:webView
                       callback:^(){
                           [weakSelf appearanceChanged];
                       }];
    
    self.webView = webView;
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSArray* backlog = prelog.copy;
    prelog = nil;
    
    for (NSArray* msg in backlog) {
        [self send: msg];
    }
    
    [_webViewControllerDelegate webViewLoaded];
}

- (void) appearanceChanged {
    [self reflectDarkMode];
    [self.class cancelPreviousPerformRequestsWithTarget:self selector:@selector(reflectDarkMode) object:nil];
    [self performSelector:@selector(reflectDarkMode) withObject:nil afterDelay:3.0];
}

- (void) reflectDarkMode {
    if (@available(macOS 10.14, *)) {
        BOOL darkMode = [NSApp.effectiveAppearance.name isEqualToString: NSAppearanceNameDarkAqua];
        [self send:@[@"autumn_darkmode", darkMode ? @YES : @NO]];
    }
}

- (void) send:(NSArray*)args {
    if (prelog) {
        [prelog addObject: args];
        return;
    }
    
    NSString* fn = args[0];
    args = [args subarrayWithRange: NSMakeRange(1, args.count - 1)];
    [self.webView evaluateJavaScript: [NSString stringWithFormat: @"%@(...%@)", fn, [DataUtils jsonFromObject: args]]
                   completionHandler: nil];
}

- (void) blur {
    [self.webView evaluateJavaScript:@"document.activeElement.blur();" completionHandler:nil];
}

// for subclasses to override

- (void) setup {
    // override
}

- (void) handleScript:(NSString*)name handler:(void(^)(NSString* input))fn {
    CallbackBasedMessageHandler* handler = [[CallbackBasedMessageHandler alloc] init];
    handler.fn = fn;
    [userContentController addScriptMessageHandler:handler name:name];
};

- (void) runScriptAtStart:(NSString*)script {
    [userContentController addUserScript: [[WKUserScript alloc] initWithSource: script
                                                                 injectionTime: WKUserScriptInjectionTimeAtDocumentStart
                                                              forMainFrameOnly: YES]];
}

- (void) zoomTo:(double)zoom {
    [self send: @[@"autumn_zoomPage", @(zoom)]];
}

@end
