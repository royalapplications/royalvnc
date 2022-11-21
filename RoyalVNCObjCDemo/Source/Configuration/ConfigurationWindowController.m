#import "ConfigurationWindowController.h"
#import "ConfigurationViewController.h"

#import "ConnectionWindowController.h"

@import RoyalVNCKit;

@interface ConfigurationWindowController () <ConnectionWindowControllerDelegate>

@property BOOL didLoad;

@property (strong) ConfigurationViewController* configurationViewController;
@property (strong) NSMutableArray<ConnectionWindowController*>* connectionWindowControllers;

@property (weak) IBOutlet NSView* viewPlaceholderConfiguration;
@property (weak) IBOutlet NSButton* buttonConnect;

@end

@implementation ConfigurationWindowController

- (NSNibName)windowNibName {
	return @"ConfigurationWindow";
}

- (instancetype)init {
	self = [super initWithWindow:nil];
	
	if (self) {
		VNCConnectionSettings* settings = [VNCConnectionSettings fromUserDefaults];
		
		self.configurationViewController = [[ConfigurationViewController alloc] initWithSettings:settings];
		self.connectionWindowControllers = [NSMutableArray array];
	}
	
	return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
	if (self.didLoad) {
		return;
	}
	
	self.didLoad = YES;
	
	[self configureUI];
}

- (void)configureUI {
	NSView* configView = self.configurationViewController.view;
	configView.frame = self.viewPlaceholderConfiguration.bounds;
	configView.autoresizingMask = NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin | NSViewWidthSizable | NSViewHeightSizable;

	[self.viewPlaceholderConfiguration addSubview:configView];

	[self.window recalculateKeyViewLoop];
	[self.window makeFirstResponder:self.configurationViewController];
}

- (IBAction)buttonConnect_action:(id)sender {
	[self connect];
}

- (void)saveSettings {
	[self.configurationViewController.settings saveToUserDefaults];
}

- (NSNumber*)colorDepthOfActiveConnection {
	VNCConnection* activeConnection = self.activeConnection;
	
	if (!activeConnection) {
		return nil;
	}
	
	VNCFramebuffer* framebuffer = activeConnection.framebuffer;
	
	if (!framebuffer) {
		return nil;
	}
	
	VNCColorDepth colorDepth = framebuffer.colorDepth;
	
	return @(colorDepth);
}

- (void)connect {
	NSWindow* window = self.window;
	
	if (!window) {
		return;
	}
	
	VNCConnectionSettings* settings = self.configurationViewController.settings;
	[settings saveToUserDefaults];
	
	if ([VNCInputModeUtils inputModeRequiresAccessibilityPermissions:settings.inputMode] &&
		!VNCAccessibilityUtils.hasAccessibilityPermissions) {
		// Requires accessibility permissions but don't have them right now so ask user
		
		NSAlert* alert = [NSAlert new];
		alert.messageText = @"Accessibility Permissions";
		alert.informativeText = @"Accessibility Permissions are required when the input mode is set to \"Forward all keyboard shortcuts and hot keys\". To continue, please open System Settings and grant the app accessibility permissions.";
		
		[alert addButtonWithTitle:@"Open System Settings"];
		[alert addButtonWithTitle:@"Continue without permissions"];
		[alert addButtonWithTitle:@"Cancel"];
		
		__weak ConfigurationWindowController* weakSelf = self;
		
		[alert beginSheetModalForWindow:window completionHandler:^(NSModalResponse response) {
			switch (response) {
				case NSAlertFirstButtonReturn:
					[VNCAccessibilityUtils openAccessibilityPermissionsPreferencePane];
					
					break;
				case NSAlertSecondButtonReturn:
					[weakSelf connectWithSettings:settings];
					
					break;
				default:
					return;
			}
		}];
	} else {
		[self connectWithSettings:settings];
	}
}

- (void)connectWithSettings:(VNCConnectionSettings*)settings {
	ConnectionWindowController* connectionWindowController = [[ConnectionWindowController alloc] initWithSettings:settings];
	connectionWindowController.delegate = self;
	
	[self.connectionWindowControllers addObject:connectionWindowController];
	
	[connectionWindowController showWindow:self];
	[connectionWindowController connect];
}

- (nullable VNCConnection*)activeConnection {
	ConnectionWindowController* activeConnectionWindowController = self.activeConnectionWindowController;
	
	if (!activeConnectionWindowController) {
		return nil;
	}
	
	return activeConnectionWindowController.connection;
}

- (nullable ConnectionWindowController*)activeConnectionWindowController {
	NSWindow* keyWindow = NSApplication.sharedApplication.keyWindow;
	
	if (!keyWindow) {
		return nil;
	}
	
	ConnectionWindowController* keyConnectionWindowController = nil;
	
	for (ConnectionWindowController* connectionWindowController in self.connectionWindowControllers) {
		if (connectionWindowController.window == keyWindow) {
			keyConnectionWindowController = connectionWindowController;
			
			break;
		}
	}
	
	return keyConnectionWindowController;
}

#pragma mark - ConnectionWindowControllerDelegate

- (void)connectionWindowControllerDidClose:(ConnectionWindowController*)connectionWindowController {
	connectionWindowController.delegate = nil;
	
	[self.connectionWindowControllers removeObject:connectionWindowController];
}

@end
