//
//  MHCheckboxNode.m
//  MadHat
//
//  Created by Dan Romik on 11/1/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHCheckboxNode.h"
#import "MHTextNode.h"

@interface MHCheckboxNode ()
{
    bool _checked;
    MHTextNode *_checkboxInCheckedStateTextNode;
    MHTextNode *_checkboxInUncheckedStateTextNode;
}

@end

@implementation MHCheckboxNode

+ (instancetype)checkboxNode:(bool)checked
{
    return [[self alloc] initChecked:checked];
}

- (instancetype)initChecked:(bool)checked
{
    if (self = [super init]) {
        _checkboxInUncheckedStateTextNode = [MHTextNode textNodeWithString:@"☐"];
        _checkboxInCheckedStateTextNode = [MHTextNode textNodeWithString:@"☒"];
        [self addChild:_checkboxInUncheckedStateTextNode];
        [self addChild:_checkboxInCheckedStateTextNode];
        self.checked = checked;
    }
    return self;
}

- (bool)checked
{
    return _checked;
}

- (void)setChecked:(bool)checked
{
    _checked = checked;
    _checkboxInUncheckedStateTextNode.hidden = checked;
    _checkboxInCheckedStateTextNode.hidden = !checked;
}

- (void)toggle
{
    self.checked = !_checked;
}

- (void)configureWithFont:(NSFont *)font
                    color:(NSColor *)color
          backgroundColor:(NSColor *)backgroundColor
              underlining:(bool)underlining
            strikethrough:(bool)strikethrough
{
    NSFont *checkboxFont = [NSFont fontWithName:@"Apple Symbols" size:font.pointSize];
    [_checkboxInUncheckedStateTextNode configureWithFont:checkboxFont
                                                   color:color
                                         backgroundColor:backgroundColor
                                             underlining:underlining
                                           strikethrough:strikethrough];
    [_checkboxInCheckedStateTextNode configureWithFont:checkboxFont
                                                 color:color
                                       backgroundColor:backgroundColor
                                           underlining:underlining
                                         strikethrough:strikethrough];
    
    MHDimensions uncheckedDimensions = _checkboxInUncheckedStateTextNode.dimensions;
    MHDimensions checkedDimensions = _checkboxInCheckedStateTextNode.dimensions;
    _dimensions.width = fmax(uncheckedDimensions.width, checkedDimensions.width);
    _dimensions.height = fmax(uncheckedDimensions.height, checkedDimensions.height);
    _dimensions.depth = fmax(uncheckedDimensions.depth, checkedDimensions.depth);
}

- (void)renderInPDFContext:(CGContextRef)pdfContext
{
//#ifdef NEW_TEXT_NODE
    // FIXME: need to implement this
    NSLog(@"implement renderInPDFContext in MHCheckboxNode");
//#else
//    if (_checked)
//        [_checkboxInCheckedStateTextNode renderInPDFContext:context];
//    else
//        [_checkboxInUncheckedStateTextNode renderInPDFContext:context];
//#endif
}


@end
