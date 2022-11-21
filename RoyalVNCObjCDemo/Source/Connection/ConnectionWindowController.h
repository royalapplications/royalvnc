@import Cocoa;
@import RoyalVNCKit;

#import "ConnectionWindowControllerDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface ConnectionWindowController : NSWindowController

@property (readonly, strong) VNCConnectionSettings* settings;
@property (readonly, nullable) VNCConnection* connection;
@property (readwrite, weak) id<ConnectionWindowControllerDelegate> delegate;

- (instancetype)initWithSettings:(VNCConnectionSettings*)settings;

- (void)connect;
- (void)disconnect;

@end

NS_ASSUME_NONNULL_END
