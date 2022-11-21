@import Cocoa;

NS_ASSUME_NONNULL_BEGIN

@interface ConfigurationWindowController : NSWindowController

@property (readonly, nullable) NSNumber* colorDepthOfActiveConnection;

- (void)saveSettings;

@end

NS_ASSUME_NONNULL_END
