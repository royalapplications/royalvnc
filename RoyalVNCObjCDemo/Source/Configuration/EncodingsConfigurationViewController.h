@import Cocoa;
@import RoyalVNCKit;

NS_ASSUME_NONNULL_BEGIN

@interface EncodingsConfigurationViewController : NSViewController

@property (readonly, copy) NSArray<NSNumber*>* supportedFrameEncodings;
@property (copy) NSArray<NSNumber*>* frameEncodings;

- (instancetype)initWithSupportedFrameEncodings:(NSArray<NSNumber*>*)supportedFrameEncodings;

@end

NS_ASSUME_NONNULL_END
