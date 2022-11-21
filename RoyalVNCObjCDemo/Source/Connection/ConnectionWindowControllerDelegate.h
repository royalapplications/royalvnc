#ifndef ConnectionWindowControllerDelegate_h
#define ConnectionWindowControllerDelegate_h

@class ConnectionWindowController;

@protocol ConnectionWindowControllerDelegate <NSObject>

- (void)connectionWindowControllerDidClose:(ConnectionWindowController*)connectionWindowController;

@end

#endif /* ConnectionWindowControllerDelegate_h */
