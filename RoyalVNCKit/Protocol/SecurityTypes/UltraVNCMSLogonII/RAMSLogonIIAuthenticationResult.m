#import "RAMSLogonIIAuthenticationResult.h"

@interface RAMSLogonIIAuthenticationResult ()

@property (strong, readwrite, nullable) NSData* publicKey;
@property (strong, readwrite, nullable) NSData* credentials;

@end

@implementation RAMSLogonIIAuthenticationResult

- (instancetype)initWithPublicKey:(NSData* _Nullable)publicKey
					  credentials:(NSData* _Nullable)credentials {
	self = [super init];
	
	if (self) {
		self.publicKey = publicKey;
		self.credentials = credentials;
	}
	
	return self;
}

+ (instancetype)emptyResult {
	return [[self alloc] initWithPublicKey:nil credentials:nil];
}

@end
