#import "AppDelegate.h"

#import "ConfigurationWindowController.h"

@import RoyalVNCKit;

@interface AppDelegate () <NSMenuDelegate>

@property (weak) IBOutlet NSMenu* menuConnection;

@property (weak) IBOutlet NSMenuItem* menuItemConnectionColorDepth8Bit;
@property (weak) IBOutlet NSMenuItem* menuItemConnectionColorDepth16Bit;
@property (weak) IBOutlet NSMenuItem* menuItemConnectionColorDepth24Bit;

@property (strong) ConfigurationWindowController* configurationWindowController;

@end

@implementation AppDelegate

- (instancetype)init {
	self = [super init];
	
	if (self) {
		self.configurationWindowController = [ConfigurationWindowController new];
	}
	
	return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[self.configurationWindowController showWindow:self];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	[self.configurationWindowController saveSettings];
}

- (void)menuNeedsUpdate:(NSMenu*)menu {
	if (menu != self.menuConnection) {
		return;
	}
	
	NSNumber* colorDepthNumber = self.configurationWindowController.colorDepthOfActiveConnection;
	VNCColorDepth colorDepth = colorDepthNumber != nil ? (VNCColorDepth)colorDepthNumber.unsignedCharValue : -1;
	
	self.menuItemConnectionColorDepth8Bit.state = colorDepth == VNCColorDepthDepth8Bit ? NSControlStateValueOn : NSControlStateValueOff;
	self.menuItemConnectionColorDepth16Bit.state = colorDepth == VNCColorDepthDepth16Bit ? NSControlStateValueOn : NSControlStateValueOff;
	self.menuItemConnectionColorDepth24Bit.state = colorDepth == VNCColorDepthDepth24Bit ? NSControlStateValueOn : NSControlStateValueOff;
}

@end
