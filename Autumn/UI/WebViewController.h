//
//  WebViewController.h
//  Autumn
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WebViewControllerDelegate <NSObject>
- (void) webViewLoaded;
@end

@interface WebViewController : NSObject

@property id<WebViewControllerDelegate> webViewControllerDelegate;
@property WKWebView* webView;

- (void) makeWebView:(NSRect)bounds initialZoom:(double)zoom;
- (void) blur;

- (void) zoomTo:(double)zoomTo;

// for subclasses

@property NSString* resourceFilename;

- (void) send:(NSArray*)args;
- (void) setup;
- (void) handleScript:(NSString*)name handler:(void(^)(NSString* input))fn;
- (void) runScriptAtStart:(NSString*)script;

@end

NS_ASSUME_NONNULL_END
