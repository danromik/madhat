//
//  NSTableViewWithDeleteShortcut.h
//  MadHat
//
//  Created by Dan Romik on 7/29/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//
//  Adapted from code at https://www.generacodice.com/en/articolo/1010554/NSTableView-+-Delete-Key
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol NSTableViewWithDeleteShortcutDelegate;

@interface NSTableViewWithDeleteShortcut : NSTableView


@property (weak) id <NSTableViewDelegate, NSTableViewWithDeleteShortcutDelegate> delegate;  // the delegate must also conform to a new protocol defined below in addition to the usual NSTableViewDelegate


@end





@protocol NSTableViewWithDeleteShortcutDelegate <NSObject>

- (void)tableViewDeleteRowShortcutInvoked:(NSTableView *)tableView;

@end


NS_ASSUME_NONNULL_END
