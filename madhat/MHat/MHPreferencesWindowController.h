//
//  MHPreferencesWindowController.h
//  MadHat
//
//  Created by Dan Romik on 12/6/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSTableViewWithDeleteShortcut.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHPreferencesWindowController : NSWindowController <NSWindowDelegate, NSTableViewDelegate, NSTableViewWithDeleteShortcutDelegate, NSTableViewDataSource, NSTextFieldDelegate, NSColorChanging>

@end

NS_ASSUME_NONNULL_END
