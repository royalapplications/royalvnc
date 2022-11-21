#import "ConnectionWindowController.h"

#import "ConnectionViewController.h"
#import "ConnectionViewControllerDelegate.h"

@interface ConnectionWindowController () <NSWindowDelegate, ConnectionViewControllerDelegate>

@property (readwrite, strong) VNCConnectionSettings* settings;
@property (strong) ConnectionViewController* connectionViewController;

@property BOOL didLoad;

@end

@implementation ConnectionWindowController

- (NSNibName)windowNibName {
	return @"ConnectionWindow";
}

- (instancetype)initWithSettings:(VNCConnectionSettings *)settings {
	self = [super initWithWindow:nil];
	
	if (self) {
		self.settings = settings;
		
		self.connectionViewController = [[ConnectionViewController alloc] initWithSettings:settings];
		self.connectionViewController.delegate = self;
	}
	
	return self;
}

- (void)dealloc {
	self.delegate = nil;
}

- (void)windowDidLoad {
	[super windowDidLoad];
	
	if (self.didLoad) {
		return;
	}
	
	self.didLoad = YES;
	
	if (!self.window ||
		!self.window.contentView) {
		return;
	}
	
	self.window.title = [NSString stringWithFormat:@"Connection to %@", self.settings.hostname];
	
	NSView* connectionView = self.connectionViewController.view;
	connectionView.frame = self.window.contentView.bounds;
	connectionView.autoresizingMask = NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin | NSViewWidthSizable | NSViewHeightSizable;

	[self.window.contentView addSubview:connectionView];
}

- (void)connect {
	[self.connectionViewController connect];
}

- (void)disconnect {
	[self.connectionViewController disconnect];
}

- (BOOL)windowShouldClose:(NSWindow*)sender {
	[self disconnect];
	
	return NO;
}

- (VNCConnection*)connection {
	return self.connectionViewController.connection;
}

- (void)connectionViewControllerDidDisconnect:(ConnectionViewController*)connectionViewController {
	self.connectionViewController.delegate = nil;

	[self close];

	[self.delegate connectionWindowControllerDidClose:self];
}

@end
