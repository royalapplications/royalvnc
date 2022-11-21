@import Cocoa;
@import RoyalVNCKit;

NS_ASSUME_NONNULL_BEGIN

@interface ConfigurationViewController : NSViewController

@property (strong) VNCConnectionSettings* settings;

- (instancetype)initWithSettings:(VNCConnectionSettings*)settings;

@end

NS_ASSUME_NONNULL_END
