//
//  EditorViewController.h
//  Autumn
//

#import <Cocoa/Cocoa.h>
#import "WebViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface EditorViewController : WebViewController

- (void) focusEditor;
- (void) runSelectionInConsole;

@end

NS_ASSUME_NONNULL_END
