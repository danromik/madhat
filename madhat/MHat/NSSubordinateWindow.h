//
//  NSSubordinateWindow.h
//  MadHat
//
//  Created by Dan Romik on 7/29/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//
//  Implements a window that is subordinate to another window in the application, called
//  the primary window, such that attempting to close the window doesn't close it but
//  instead sends the performClose message to the primary window.
//  It is the responsibility of the primary window to actually close the subordinate
//  window by sending it an -actuallyClose message.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSSubordinateWindow : NSWindow

@property IBOutlet NSWindow *primaryWindow;

- (void)close;  // this overrides the default NSWindow functionality by sending a -performClose message to the primary window

- (void)actuallyClose;  // this actually closes the window by sending a -close message to the superclass

@end

NS_ASSUME_NONNULL_END
