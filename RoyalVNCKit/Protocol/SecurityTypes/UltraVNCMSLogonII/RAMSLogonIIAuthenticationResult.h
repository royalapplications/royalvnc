#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RAMSLogonIIAuthenticationResult : NSObject

@property (strong, readonly, nullable) NSData* publicKey;
@property (strong, readonly, nullable) NSData* credentials;

- (instancetype)initWithPublicKey:(NSData* _Nullable)publicKey
					  credentials:(NSData* _Nullable)credentials;

+ (instancetype)emptyResult;

@end

NS_ASSUME_NONNULL_END
