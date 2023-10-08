//
//  NSTableViewWitkKeyPressDelegation.h
//  MadHat
//
//  Created by Dan Romik on 7/3/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class NSTableViewWitkKeyPressDelegation;

@protocol NSTableViewKeyPressDelegate <NSObject>

- (BOOL)tableView:(NSTableViewWitkKeyPressDelegation *)tableView keyDown:(NSEvent *)event;     // delegate returns YES if it wants to take charge of the key down event, otherwise returns NO and the table view will handle it

@end


@interface NSTableViewWitkKeyPressDelegation : NSTableView

@property(weak) id<NSTableViewDelegate, NSTableViewKeyPressDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
