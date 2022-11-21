@import Cocoa;
@import RoyalVNCKit;

#import "ConnectionViewControllerDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface ConnectionViewController : NSViewController

@property (readonly, nullable) VNCConnection* connection;
@property (readwrite, weak) id<ConnectionViewControllerDelegate> delegate;

- (instancetype)initWithSettings:(VNCConnectionSettings*)settings;

- (void)connect;
- (void)disconnect;

@end

NS_ASSUME_NONNULL_END
