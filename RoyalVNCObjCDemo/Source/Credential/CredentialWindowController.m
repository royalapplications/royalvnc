#import "CredentialWindowController.h"

@interface CredentialWindowController ()

@property (readwrite) VNCAuthenticationType authenticationType;
@property (readwrite, strong) NSString* previousUsername;
@property (readwrite, strong) NSString* previousPassword;

@property (strong, nullable) NSWindow* parentWindow;
@property BOOL didLoad;

@property (weak) IBOutlet NSTextField* textFieldUsername;
@property (weak) IBOutlet NSSecureTextField* textFieldPassword;

@property (weak) IBOutlet NSButton* buttonOK;
@property (weak) IBOutlet NSButton* buttonCancel;

@end

@implementation CredentialWindowController

- (NSNibName)windowNibName {
	return @"CredentialWindow";
}

- (instancetype)initWithAuthenticationType:(VNCAuthenticationType)authenticationType
						  previousUsername:(NSString *)previousUsername
						  previousPassword:(NSString *)previousPassword {
	self = [super initWithWindow:nil];
	
	if (self) {
		self.authenticationType = authenticationType;
		self.previousUsername = previousUsername;
		self.previousPassword = previousPassword;
	}
	
	return self;
}

- (void)beginSheetForParentWindow:(NSWindow*)parentWindow
				completionHandler:(void (^)(__nullable id<VNCCredential> credential))completionHandler {
	if (!self.window) {
		completionHandler(nil);
		
		return;
	}
	
	self.parentWindow = parentWindow;
	
	__weak CredentialWindowController* weakSelf = self;
	
	[parentWindow beginSheet:self.window completionHandler:^(NSModalResponse modalResponse) {
		if (!weakSelf ||
			modalResponse != NSModalResponseOK) {
			completionHandler(nil);
			
			return;
		}
		
		CredentialWindowController* strongSelf = weakSelf;
		
		completionHandler(strongSelf.credential);
	}];
}

- (void)windowDidLoad {
	[super windowDidLoad];
	
	if (self.didLoad) {
		return;
	}
	
	self.didLoad = YES;
	
	[self configureUI];
}

- (IBAction)buttonOK_action:(id)sender {
	[self handleButtonClicked:NSModalResponseOK];
}

- (IBAction)buttonCancel_action:(id)sender {
	[self handleButtonClicked:NSModalResponseCancel];
}

- (void)configureUI {
	VNCAuthenticationType authenticationType = self.authenticationType;
	
	BOOL requiresUsername = [VNCAuthenticationTypeUtils authenticationTypeRequiresUsername:authenticationType];
	BOOL requiresPassword = [VNCAuthenticationTypeUtils authenticationTypeRequiresPassword:authenticationType];
	
	self.textFieldUsername.enabled = requiresUsername;
	self.textFieldPassword.enabled = requiresPassword;
	
	self.username = self.previousUsername;
	self.password = self.previousPassword;
	
	if (requiresUsername) {
		[self.window makeFirstResponder:self.textFieldUsername];
	} else {
		[self.window makeFirstResponder:self.textFieldPassword];
	}
}

- (void)handleButtonClicked:(NSModalResponse)modalResponse {
	if (!self.parentWindow ||
		!self.window) {
		return;
	}
	
	[self.parentWindow endSheet:self.window
					 returnCode:modalResponse];
}

- (NSString*)username {
	return self.textFieldUsername.stringValue;
}

- (void)setUsername:(NSString *)username {
	self.textFieldUsername.stringValue = username;
}

- (NSString*)password {
	return self.textFieldPassword.stringValue;
}

- (void)setPassword:(NSString *)password {
	self.textFieldPassword.stringValue = password;
}

- (id<VNCCredential>)credential {
	VNCAuthenticationType authenticationType = self.authenticationType;
	BOOL requiresUsername = [VNCAuthenticationTypeUtils authenticationTypeRequiresUsername:authenticationType];
	
	if (requiresUsername) {
		return [[VNCUsernamePasswordCredential alloc] initWithUsername:self.username
															  password:self.password];
	} else {
		return [[VNCPasswordCredential alloc] initWithPassword:self.password];
	}
}

@end
