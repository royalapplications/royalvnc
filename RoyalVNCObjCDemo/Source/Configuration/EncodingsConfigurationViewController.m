#import "EncodingsConfigurationViewController.h"

@interface EncodingsConfigurationViewController () <NSTableViewDelegate, NSTableViewDataSource>

@property (readwrite, strong) NSMutableArray<NSNumber*>* _frameEncodings;

@property (readwrite, copy) NSArray<NSNumber*>* supportedFrameEncodings;
@property BOOL didLoad;

@property (weak) IBOutlet NSTableView* tableView;

@end

@implementation EncodingsConfigurationViewController

- (instancetype)initWithSupportedFrameEncodings:(NSArray<NSNumber*>*)supportedFrameEncodings {
	self = [super initWithNibName:@"EncodingsConfigurationView" bundle:NSBundle.mainBundle];
	
	if (self) {
		self.supportedFrameEncodings = supportedFrameEncodings;
		self.frameEncodings = supportedFrameEncodings;
	}
	
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	if (self.didLoad) {
		return;
	}
	
	self.didLoad = YES;
	
	self.tableView.dataSource = self;
	self.tableView.delegate = self;
}

- (NSArray<NSNumber*>*)frameEncodings {
	return [self._frameEncodings copy];
}

- (void)setFrameEncodings:(NSArray<NSNumber*>*)frameEncodings {
	NSMutableArray* copiedFrameEncodings = [NSMutableArray array];
	
	for (NSNumber* encodingNumber in frameEncodings) {
		[copiedFrameEncodings addObject:encodingNumber];
	}
	
	self._frameEncodings = copiedFrameEncodings;
	
	[self.tableView reloadData];
}

- (NSArray<NSNumber*>*)orderedFrameEncodings {
	return [self orderedFrameEncodings:self.supportedFrameEncodings
								 order:self._frameEncodings];
}

- (IBAction)checkBoxEncoding_action:(NSButton*)sender {
	NSInteger row = [self.tableView rowForView:sender];
	
	if (row == NSNotFound ||
		row < 0) {
		return;
	}
	
	VNCFrameEncodingType encoding = (VNCFrameEncodingType)self.orderedFrameEncodings[row].intValue;
	BOOL isEnabled = sender.state == NSControlStateValueOn;
	
	[self setEncoding:encoding
				index:row
			  enabled:isEnabled];
}

- (IBAction)buttonMoveUp_action:(NSButton*)sender {
	NSInteger row = self.tableView.selectedRow;
	
	if (row == NSNotFound ||
		row < 0) {
		return;
	}
	
	[self moveEncodingAtIndex:row
						   up:YES];
}

- (IBAction)buttonMoveDown_action:(NSButton*)sender {
	NSInteger row = self.tableView.selectedRow;
	
	if (row == NSNotFound ||
		row < 0) {
		return;
	}
	
	[self moveEncodingAtIndex:row
						   up:NO];
}

- (NSArray<NSNumber*>*)orderedFrameEncodings:(NSArray<NSNumber*>*)encodings
									   order:(NSArray<NSNumber*>*)order {
	NSMutableArray<NSNumber*>* filteredOrder = [NSMutableArray array];
	
	for (NSNumber* encodingNumber in order) {
		VNCFrameEncodingType encoding = (VNCFrameEncodingType)encodingNumber.intValue;
		
		if ([self isEncodingEnabled:encoding in:encodings]) {
			[filteredOrder addObject:encodingNumber];
		}
	}
	
	for (NSNumber* encodingNumber in encodings) {
		VNCFrameEncodingType encoding = (VNCFrameEncodingType)encodingNumber.intValue;
		
		if (![self isEncodingEnabled:encoding in:order]) {
			[filteredOrder addObject:encodingNumber];
		}
	}
	
	return [filteredOrder copy];
}

- (void)setEncoding:(VNCFrameEncodingType)encoding
			  index:(NSInteger)index
			enabled:(BOOL)isEnabled {
	if (isEnabled) {
		if (index < self._frameEncodings.count) {
			[self._frameEncodings insertObject:@(encoding) atIndex:index];
		} else {
			[self._frameEncodings addObject:@(encoding)];
		}
	} else {
		[self._frameEncodings removeObjectAtIndex:index];
	}
	
	[self.tableView reloadData];
}

- (void)moveEncodingAtIndex:(NSInteger)index
						 up:(BOOL)up {
	if (index < 0 ||
		index >= self._frameEncodings.count) {
		return;
	}
	
	NSInteger newIndex = up
		? MAX(index - 1, 0)
		: MIN(index + 1, self._frameEncodings.count - 1);
	
	VNCFrameEncodingType encoding = (VNCFrameEncodingType)self._frameEncodings[index].integerValue;
	
	[self._frameEncodings removeObjectAtIndex:index];
	[self._frameEncodings insertObject:@(encoding) atIndex:newIndex];
	
	[self.tableView reloadData];
	
	[self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:newIndex]
				byExtendingSelection:NO];
}

- (BOOL)isEncodingEnabled:(VNCFrameEncodingType)encoding
					   in:(NSArray<NSNumber*>*)encodings {
	for (NSNumber* encodingNumber in encodings) {
		VNCFrameEncodingType currentEncoding = (VNCFrameEncodingType)encodingNumber.intValue;
		
		if (currentEncoding == encoding) {
			return YES;
		}
	}
	
	return NO;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return self.orderedFrameEncodings.count;
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
				  row:(NSInteger)row {
	VNCFrameEncodingType encoding = (VNCFrameEncodingType)self.orderedFrameEncodings[row].intValue;
	
	NSTableCellView* cellView = [tableView makeViewWithIdentifier:@"EncodingCell" owner:nil];
	NSButton* checkBox = [cellView viewWithTag:450];
	
	if (!cellView ||
		!checkBox) {
		return nil;
	}
	
	NSString* title = [VNCFrameEncodingTypeUtils descriptionForFrameEncoding:encoding];
	
	BOOL isEnabled = [self isEncodingEnabled:encoding
										  in:self._frameEncodings];
	
	checkBox.title = title;
	checkBox.state = isEnabled ? NSControlStateValueOn : NSControlStateValueOff;
	
	checkBox.target = self;
	checkBox.action = @selector(checkBoxEncoding_action:);
	
	return cellView;
}

- (BOOL)tableView:(NSTableView *)tableView
	   isGroupRow:(NSInteger)row {
	return NO;
}

@end
