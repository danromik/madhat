//
//  NSAttributedString+QuickLineBreaking.m
//  MadHat
//
//  Created by Dan Romik on 8/18/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "NSAttributedString+QuickLineBreaking.h"

#import <AppKit/AppKit.h>


@implementation NSAttributedString (QuickLineBreaking)

- (NSArray <NSAttributedString *> *)layoutLinesWithWidth:(CGFloat)width
{
    static NSTextView *textView;
    NSRect frame = NSMakeRect(0.0, 0.0, width, 10000);
    if (!textView) {
        textView = [[NSTextView alloc] initWithFrame:frame];
    }
    else {
        textView.frame = frame;
    }
    [textView.textStorage setAttributedString:self];
    
    NSMutableArray *lines = [[NSMutableArray alloc] initWithCapacity:0];
    NSLayoutManager *layoutManager = [textView layoutManager];
    NSUInteger numberOfLines, index, numberOfGlyphs = [layoutManager numberOfGlyphs];
    NSRange lineRange;
    for (numberOfLines = 0, index = 0; index < numberOfGlyphs; numberOfLines++) {
        (void)[layoutManager lineFragmentRectForGlyphAtIndex:index effectiveRange:&lineRange];
        index = NSMaxRange(lineRange);
        NSRange characterRangeForLine = [layoutManager characterRangeForGlyphRange:lineRange actualGlyphRange:nil];
        NSAttributedString *line = [self attributedSubstringFromRange:characterRangeForLine];
        [lines addObject:line];
    }

    return lines;
}

@end
