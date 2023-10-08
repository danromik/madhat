//
//  MHSourceCodeLayoutManager.m
//  MadHat
//
//  Created by Dan Romik on 8/7/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHSourceCodeLayoutManager.h"

@interface MHSourceCodeLayoutManager ()
{
    NSColor *_textSelectionColor;
}

@end


@implementation MHSourceCodeLayoutManager

- (instancetype)init
{
    if (self = [super init]) {
        _textSelectionColor = [NSColor selectedTextColor];
    }
    return self;
}

- (void)fillBackgroundRectArray:(const NSRect *)rectArray count:(NSUInteger)rectCount forCharacterRange:(NSRange)charRange color:(NSColor *)color
{
    if ([color isEqualTo:[NSColor secondarySelectedControlColor]]) {
        // see this discussion:
        // https://stackoverflow.com/questions/16073233/how-can-i-set-nstextview-selectedtextattributes-on-a-background-window
        // for an explanation of why the calls to -setFill are necessary
        
        [_textSelectionColor setFill];
        [super fillBackgroundRectArray:rectArray count:rectCount forCharacterRange:charRange color:_textSelectionColor];
        [color setFill];
    }
    else {
        [super fillBackgroundRectArray:rectArray count:rectCount forCharacterRange:charRange color:color];
    }
}

- (NSColor *)textSelectionColor
{
    return _textSelectionColor;
}

- (void)setTextSelectionColor:(NSColor *)textSelectionColor
{
    _textSelectionColor = textSelectionColor;
}

@end
