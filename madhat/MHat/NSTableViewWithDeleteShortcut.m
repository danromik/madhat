//
//  NSTableViewWithDeleteShortcut.m
//  MadHat
//
//  Created by Dan Romik on 7/29/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//
//  Adapted from code at https://www.generacodice.com/en/articolo/1010554/NSTableView-+-Delete-Key
//


#import "NSTableViewWithDeleteShortcut.h"

@implementation NSTableViewWithDeleteShortcut
@dynamic delegate;

- (void)keyDown:(NSEvent *)event
{
    unichar key = [[event charactersIgnoringModifiers] characterAtIndex:0];
    if(key == NSDeleteCharacter)
    {
        if (self.selectedRow == -1) {
            NSBeep();
        }
        [self.delegate tableViewDeleteRowShortcutInvoked:self];
        return;
    }

    // still here?
    [super keyDown:event];
}



@end
