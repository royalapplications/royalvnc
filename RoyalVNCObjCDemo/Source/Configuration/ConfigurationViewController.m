#import "ConfigurationViewController.h"
#import "EncodingsConfigurationViewController.h"

@interface ConfigurationViewController ()

@property (strong) VNCConnectionSettings* initialSettings;

@property (strong) EncodingsConfigurationViewController* encodingsConfigurationViewController;
@property BOOL didLoad;

@property (weak) IBOutlet NSTextField* textFieldHostname;
@property (weak) IBOutlet NSTextField* textFieldPort;

@property (weak) IBOutlet NSButton* checkBoxShared;
@property (weak) IBOutlet NSButton* checkBoxClipboardRedirection;
@property (weak) IBOutlet NSButton* checkBoxScaling;
@property (weak) IBOutlet NSButton* checkBoxUseDisplayLink;
@property (weak) IBOutlet NSButton* checkBoxDebugLogging;

@property (weak) IBOutlet NSPopUpButton* popupButtonInputMode;
@property (weak) IBOutlet NSPopUpButton* popupButtonColorDepth;
@property (weak) IBOutlet NSView* placeholderViewEncodings;

@end

@implementation ConfigurationViewController

- (instancetype)initWithSettings:(VNCConnectionSettings *)settings {
	self = [super initWithNibName:@"ConfigurationView"
						   bundle:NSBundle.mainBundle];
	
	if (self) {
		self.initialSettings = settings;
		
		NSArray<NSNumber*>* supportedFrameEncodings = VNCFrameEncodingTypeUtils.defaultFrameEncodings;
		
		self.encodingsConfigurationViewController = [[EncodingsConfigurationViewController alloc] initWithSupportedFrameEncodings:supportedFrameEncodings];
	}
	
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	if (self.didLoad) {
		return;
	}
	
	self.didLoad = YES;
	
	NSView* encodingsConfigurationView = self.encodingsConfigurationViewController.view;
	encodingsConfigurationView.frame = self.placeholderViewEncodings.bounds;
	
	[self.placeholderViewEncodings addSubview:encodingsConfigurationView];
	
	self.settings = self.initialSettings;
}

- (BOOL)becomeFirstResponder {
	return [self.textFieldHostname becomeFirstResponder];
}

- (VNCConnectionSettings *)settings {
	return [[VNCConnectionSettings alloc] initWithIsDebugLoggingEnabled:self.isDebugLoggingEnabled
															   hostname:self.hostname
																   port:self.port
															   isShared:self.isShared
													   isScalingEnabled:self.isScalingEnabled
														 useDisplayLink:self.useDisplayLink
															  inputMode:self.inputMode
										  isClipboardRedirectionEnabled:self.isClipboardRedirectionEnabled
															 colorDepth:self.colorDepth
														 frameEncodings:self.frameEncodings];
}

- (void)setSettings:(VNCConnectionSettings *)settings {
	self.isDebugLoggingEnabled = settings.isDebugLoggingEnabled;
	self.hostname = settings.hostname;
	self.port = settings.port;
	self.isShared = settings.isShared;
	self.isScalingEnabled = settings.isScalingEnabled;
	self.useDisplayLink = settings.useDisplayLink;
	self.inputMode = settings.inputMode;
	self.isClipboardRedirectionEnabled = settings.isClipboardRedirectionEnabled;
	self.colorDepth = settings.colorDepth;
	self.frameEncodings = settings.frameEncodings;
}

- (BOOL)isDebugLoggingEnabled {
	return self.checkBoxDebugLogging.state == NSControlStateValueOn;
}
- (void)setIsDebugLoggingEnabled:(BOOL)isDebugLoggingEnabled {
	self.checkBoxDebugLogging.state = isDebugLoggingEnabled ? NSControlStateValueOn : NSControlStateValueOff;
}

- (NSString*)hostname {
	return self.textFieldHostname.stringValue;
}
- (void)setHostname:(NSString*)hostname {
	self.textFieldHostname.stringValue = hostname;
}

- (uint16_t)port {
	return (uint16_t)self.textFieldPort.intValue;
}
- (void)setPort:(uint16_t)port {
	self.textFieldPort.intValue = port;
}

- (BOOL)isShared {
	return self.checkBoxShared.state == NSControlStateValueOn;
}
- (void)setIsShared:(BOOL)isShared {
	self.checkBoxShared.state = isShared ? NSControlStateValueOn : NSControlStateValueOff;
}

- (BOOL)isScalingEnabled {
	return self.checkBoxScaling.state == NSControlStateValueOn;
}
- (void)setIsScalingEnabled:(BOOL)isScalingEnabled {
	self.checkBoxScaling.state = isScalingEnabled ? NSControlStateValueOn : NSControlStateValueOff;
}

- (BOOL)useDisplayLink {
	return self.checkBoxUseDisplayLink.state == NSControlStateValueOn;
}
- (void)setUseDisplayLink:(BOOL)useDisplayLink {
	self.checkBoxUseDisplayLink.state = useDisplayLink ? NSControlStateValueOn : NSControlStateValueOff;
}

- (VNCInputMode)inputMode {
	return (VNCInputMode)self.popupButtonInputMode.indexOfSelectedItem;
}
- (void)setInputMode:(VNCInputMode)inputMode {
	[self.popupButtonInputMode selectItemAtIndex:inputMode];
}

- (BOOL)isClipboardRedirectionEnabled {
	return self.checkBoxClipboardRedirection.state == NSControlStateValueOn;
}
- (void)setIsClipboardRedirectionEnabled:(BOOL)isClipboardRedirectionEnabled {
	self.checkBoxClipboardRedirection.state = isClipboardRedirectionEnabled ? NSControlStateValueOn : NSControlStateValueOff;
}

- (VNCColorDepth)colorDepth {
	switch (self.popupButtonColorDepth.indexOfSelectedItem) {
		case 0:
			return VNCColorDepthDepth8Bit;
		case 1:
			return VNCColorDepthDepth16Bit;
		case 2:
			return VNCColorDepthDepth24Bit;
		default:
			return VNCColorDepthDepth24Bit;
	}
}
- (void)setColorDepth:(VNCColorDepth)colorDepth {
	switch (colorDepth) {
		case VNCColorDepthDepth8Bit:
			[self.popupButtonColorDepth selectItemAtIndex:0];
			break;
		case VNCColorDepthDepth16Bit:
			[self.popupButtonColorDepth selectItemAtIndex:1];
			break;
		case VNCColorDepthDepth24Bit:
			[self.popupButtonColorDepth selectItemAtIndex:2];
			break;
	}
}

- (NSArray<NSNumber*>*)frameEncodings {
	return self.encodingsConfigurationViewController.frameEncodings;
}
- (void)setFrameEncodings:(NSArray<NSNumber*>*)frameEncodings {
	self.encodingsConfigurationViewController.frameEncodings = frameEncodings;
}

@end
