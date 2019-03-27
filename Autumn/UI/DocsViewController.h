//
//  DocsViewController.h
//  Autumn
//

#import <Cocoa/Cocoa.h>
#import "WebViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface DocsViewController : WebViewController

- (void) searchDocs:(NSString*)str;
- (void) togglePlaybook:(BOOL)visible;

@end

NS_ASSUME_NONNULL_END
