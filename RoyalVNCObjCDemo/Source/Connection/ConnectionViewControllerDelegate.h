#ifndef ConnectionViewControllerDelegate_h
#define ConnectionViewControllerDelegate_h

@class ConnectionViewController;

@protocol ConnectionViewControllerDelegate <NSObject>

- (void)connectionViewControllerDidDisconnect:(ConnectionViewController*)connectionViewController;

@end

#endif /* ConnectionViewControllerDelegate_h */
