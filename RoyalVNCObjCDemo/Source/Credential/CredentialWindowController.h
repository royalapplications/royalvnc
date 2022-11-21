@import Cocoa;
@import RoyalVNCKit;

NS_ASSUME_NONNULL_BEGIN

@interface CredentialWindowController : NSWindowController

@property (readonly) VNCAuthenticationType authenticationType;
@property (readonly, strong) NSString* previousUsername;
@property (readonly, strong) NSString* previousPassword;

- (instancetype)initWithAuthenticationType:(VNCAuthenticationType)authenticationType
						  previousUsername:(NSString*)previousUsername
						  previousPassword:(NSString*)previousPassword;

- (void)beginSheetForParentWindow:(NSWindow*)parentWindow
				completionHandler:(void (^)(__nullable id<VNCCredential> credential))completionHandler;

@end

NS_ASSUME_NONNULL_END
