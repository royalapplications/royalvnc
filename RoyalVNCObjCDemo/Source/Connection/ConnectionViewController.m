#import "ConnectionViewController.h"
#import "CredentialWindowController.h"

@interface ConnectionViewController () <VNCConnectionDelegate>

@property (weak) IBOutlet NSProgressIndicator* progressIndicator;
@property (weak) IBOutlet NSTextField* textFieldStatus;
@property (weak) IBOutlet VNCScrollView* framebufferScrollView;

@property (strong) VNCConnection* connection;
@property (strong, nullable) VNCCAFramebufferView* framebufferView;
@property (strong, nullable) CredentialWindowController* credentialWindowController;

@end

@implementation ConnectionViewController

- (instancetype)initWithSettings:(VNCConnectionSettings*)settings {
	self = [super initWithNibName:@"ConnectionView"
						   bundle:NSBundle.mainBundle];
	
	if (self) {
		self.connection = [[VNCConnection alloc] initWithSettings:settings];
		self.connection.delegate = self;
	}
	
	return self;
}

- (void)dealloc {
	self.connection.delegate = nil;
}

- (void)connect {
	[self.connection connect];
}

- (void)disconnect {
	if (self.connection.connectionState.status == VNCConnectionStatusDisconnected) {
		return;
	}
	
	[self.connection disconnect];
}

- (void)showProgressWithStatusText:(NSString*)statusText {
	[self.progressIndicator startAnimation:nil];
	self.progressIndicator.hidden = NO;

	self.textFieldStatus.stringValue = statusText;
	self.textFieldStatus.hidden = NO;
}

- (void)hideProgress {
	[self.progressIndicator stopAnimation:nil];
	self.progressIndicator.hidden = YES;
	
	self.textFieldStatus.hidden = YES;
}

- (void)createFramebufferViewForConnection:(VNCConnection*)connection
							   framebuffer:(VNCFramebuffer*)framebuffer {
	[self createFramebufferViewForConnection:connection
								 framebuffer:framebuffer
								inScrollView:self.framebufferScrollView
						  makeFirstResponder:YES];
}

- (id<VNCFramebufferView>)createFramebufferViewForConnection:(VNCConnection*)connection
												 framebuffer:(VNCFramebuffer*)framebuffer
												inScrollView:(VNCScrollView*)scrollView
										  makeFirstResponder:(BOOL)makeFirstResponder {
	[self destroyFramebufferView];
	
	BOOL isScalingEnabled = connection.settings.isScalingEnabled;
	
	CGSize viewSize = isScalingEnabled
		? scrollView.bounds.size
		: framebuffer.size;
	
	CGRect rect = CGRectMake(0, 0,
							 viewSize.width, viewSize.height);
	
	VNCCAFramebufferView* view = [[VNCCAFramebufferView alloc] initWithFrame:rect
																 framebuffer:framebuffer
																  connection:connection];
	
	if (isScalingEnabled) {
		view.autoresizingMask = NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin | NSViewWidthSizable | NSViewHeightSizable;
		
		scrollView.hasVerticalScroller = NO;
		scrollView.hasHorizontalScroller = NO;
	} else {
		scrollView.hasVerticalScroller = YES;
		scrollView.hasHorizontalScroller = YES;
	}
	
	scrollView.documentView = view;
	
	self.framebufferView = view;
	
	if (makeFirstResponder) {
		[view.window makeFirstResponder:view];
	}
	
	return view;
}

- (void)destroyFramebufferView {
	if (!self.framebufferView) {
		return;
	}
	
	[(NSView*)self.framebufferView removeFromSuperview];
	self.framebufferView = nil;
}

- (void)handleConnectionStateDidChange:(VNCConnectionState*)connectionState {
	NSString* statusText = nil;
	
	BOOL didCloseConnection = NO;
	
	switch (connectionState.status) {
		case VNCConnectionStatusConnecting:
			statusText = @"Connecting…";
			break;
		case VNCConnectionStatusDisconnecting:
			statusText = @"Disconnecting…";
			break;
		case VNCConnectionStatusConnected:
			statusText = nil;
			break;
		case VNCConnectionStatusDisconnected:
			statusText = nil;
			didCloseConnection = YES;
			break;
	}
	
	if (statusText) {
		[self showProgressWithStatusText:statusText];
	} else {
		[self hideProgress];
	}
	
	if (!didCloseConnection) {
		return;
	}
	
	[self handleConnectionDidCloseWithError:connectionState.error];
}

- (void)handleConnectionDidCloseWithError:(nullable NSError*)error {
	self.connection.delegate = nil;
	
	[self destroyFramebufferView];
	
	[self presentError:error completionHandler:^{
		[self.delegate connectionViewControllerDidDisconnect:self];
	}];
}

- (void)presentError:(nullable NSError*)error
   completionHandler:(void (^)(void))completionHandler {
	if (!error) {
		completionHandler();
		
		return;
	}
	
	BOOL shouldDisplayError = [VNCErrorUtils shouldDisplayErrorToUser:error];
	
	if (!shouldDisplayError) {
		completionHandler();
		
		return;
	}
	
	NSString* errorText = error.localizedDescription;
	
	NSAlert* alert = [NSAlert new];
	alert.alertStyle = NSAlertStyleWarning;
	alert.messageText = @"Disconnected with Error";
	alert.informativeText = errorText;
	
	[alert addButtonWithTitle:@"OK"];
	
	if (self.view.window) {
		[alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
			completionHandler();
		}];
	} else {
		[alert runModal];
		
		completionHandler();
	}
}

- (void)credentialForAuthenticationType:(VNCAuthenticationType)authenticationType
					  completionHandler:(void (^)(__nullable id<VNCCredential> credential))completionHandler {
	NSWindow* window = self.view.window;
	
	if (!window) {
		completionHandler(nil);
		
		return;
	}
	
	VNCConnectionSettings* settings = self.connection.settings;
	
	NSString* cachedUsername = settings.cachedUsername;
	NSString* cachedPassword = settings.cachedPassword;
	
	CredentialWindowController* windowController = [[CredentialWindowController alloc] initWithAuthenticationType:authenticationType
																								 previousUsername:cachedUsername
																								 previousPassword:cachedPassword];
	
	self.credentialWindowController = windowController;
	
	__weak ConnectionViewController* weakSelf = self;
	
	[windowController beginSheetForParentWindow:window
							  completionHandler:^(id<VNCCredential>  _Nullable credential) {
		weakSelf.credentialWindowController = nil;
		
		if (credential) {
			if ([(NSObject*)credential isKindOfClass:VNCUsernamePasswordCredential.class]) {
				VNCUsernamePasswordCredential* userPassCred = (VNCUsernamePasswordCredential*)credential;
				
				if (![userPassCred.username isEqualToString:cachedUsername]) {
					settings.cachedUsername = userPassCred.username;
				}
				
				if (![userPassCred.password isEqualToString:cachedPassword]) {
					settings.cachedPassword = userPassCred.password;
				}
			} else if ([(NSObject*)credential isKindOfClass:VNCPasswordCredential.class]) {
				VNCPasswordCredential* passCred = (VNCPasswordCredential*)credential;
				
				if (![passCred.password isEqualToString:cachedPassword]) {
					settings.cachedPassword = passCred.password;
				}
			}
		}
		
		completionHandler(credential);
	}];
}

- (IBAction)setColorDepth8Bit:(id)sender {
	[self.connection updateColorDepth:VNCColorDepthDepth8Bit];
}

- (IBAction)setColorDepth16Bit:(id)sender {
	[self.connection updateColorDepth:VNCColorDepthDepth16Bit];
}

- (IBAction)setColorDepth24Bit:(id)sender {
	[self.connection updateColorDepth:VNCColorDepthDepth24Bit];
}

#pragma mark VNCConnectionDelegate

- (void)connection:(VNCConnection*)connection
	stateDidChange:(VNCConnectionState*)connectionState {
	__weak ConnectionViewController* weakSelf = self;
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[weakSelf handleConnectionStateDidChange:connectionState];
	});
}

- (void)connection:(VNCConnection*)connection
	 credentialFor:(enum VNCAuthenticationType)authenticationType
		completion:(void (^)(id<VNCCredential> _Nullable))completion {
	__weak ConnectionViewController* weakSelf = self;
	
	dispatch_async(dispatch_get_main_queue(), ^{
		if (!weakSelf) {
			completion(nil);
			
			return;
		}
		
		[weakSelf credentialForAuthenticationType:authenticationType
								completionHandler:completion];
	});
}

- (void)connection:(VNCConnection*)connection didCreateFramebuffer:(VNCFramebuffer*)framebuffer {
	__weak ConnectionViewController* weakSelf = self;
	
	dispatch_async(dispatch_get_main_queue(), ^{
		if (!weakSelf) {
			return;
		}
		
		[weakSelf createFramebufferViewForConnection:connection
										 framebuffer:framebuffer];
	});
}

- (void)connection:(VNCConnection*)connection didResizeFramebuffer:(VNCFramebuffer*)framebuffer {
	__weak ConnectionViewController* weakSelf = self;
	
	dispatch_async(dispatch_get_main_queue(), ^{
		if (!weakSelf) {
			return;
		}
		
		[weakSelf createFramebufferViewForConnection:connection
										 framebuffer:framebuffer];
	});
}

- (void)connection:(VNCConnection*)connection
	   framebuffer:(VNCFramebuffer*)framebuffer
   didUpdateRegion:(CGRect)updatedRegion {
	[self.framebufferView connection:connection
						 framebuffer:framebuffer
					 didUpdateRegion:updatedRegion];
}

- (void)connection:(VNCConnection*)connection
   didUpdateCursor:(VNCCursor*)cursor {
	[self.framebufferView connection:connection
					 didUpdateCursor:cursor];
}

@end
