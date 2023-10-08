//
//  MHMathGlyphAtom.m
//  MadHat
//
//  Created by Dan Romik on 7/10/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHMathGlyphAtom.h"

@interface MHMathGlyphAtom () {
    MHTypographyClass _typographyClass;
}
@end



@implementation MHMathGlyphAtom




#pragma mark - Constructor methods

- (instancetype)initWithGlyphName:(NSString *)glyphName typographyClass:(MHTypographyClass)typographyClass
{
    if (self = [super init]) {
        _glyphName = glyphName;
        _typographyClass = typographyClass;
    }
    return self;
}

+ (instancetype)mathGlyphAtomWithGlyphName:(NSString *)glyphName typographyClass:(MHTypographyClass)typographyClass
{
    return [[self alloc] initWithGlyphName:glyphName typographyClass:typographyClass];
}



#pragma mark - MHCommand protocol

// FIXME: this isn't currently implemented because math glyph commands are routed to the MHMathAtom class. This doesn't seem logical so I've made a note to fix this at some point and move those commands over to this class.
//+ (MHExpression *)commandNamed:(NSString *)name withParameters:(NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument
//{
//
//}

// FIXME: putting in something temporary until the issue described above is resolved
+ (NSArray <NSString *> *)recognizedCommands
{
    return @[ @"(FIXME)" ];
}



# pragma mark - Properties

// A small optimization here: since I'm using one of the bits of the _typographyClass field to store the isLimitsOperator boolean (see the -isLimitsOperator method), make sure to return the value with that bit (and the ones above it, which are not used) zeroed out
// FIXME: this code is also copy-pasted in the MHMathGlyphAtom class. Violates DRY, figure out a way to share code between the two classes
// FIXME: it may be a good idea to rename the _typographyClass instance variable to emphasize that it contains more than just the typographyClass-valued property. This could prevent confusion and bugs popping up in the future
- (MHTypographyClass)typographyClass
{
    return _typographyClass & 2047;
}

- (short int)italicCorrection
{
    // FIXME: a temporary hack - this information should be read from the font
    if ([self.glyphName isEqualToString:@"integral.v1"])
        return 300;
    if ([self.glyphName isEqualToString:@"contourintegral.v1"])
        return 300;
    NSLog(@"glyph name=%@", self.glyphName);
    return super.italicCorrection;
}

// A small optimization here: using one of the bits of the _typographyClass field to store the isLimitsOperator boolean
// FIXME: this code is also copy-pasted in the MHMathAtom class. Violates DRY, figure out a way to share code between the two classes
- (bool)isLimitsOperator
{
    return ((_typographyClass & 2048) == 2048 ? true : false);
}

- (void)setIsLimitsOperator:(bool)isLimitsOperator
{
    _typographyClass = (_typographyClass & 2047) | (isLimitsOperator ? 2048 : 0);
}


#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    MHMathGlyphAtom *myCopy = [[self class] mathGlyphAtomWithGlyphName:[_glyphName copy] typographyClass:_typographyClass];
    myCopy.codeRange = self.codeRange;
    return myCopy;
}


// DR: not sure about this - commenting out for now
//-(NSString *)exportedLaTeXValue
//{
//    return [_glyphName stringByAppendingString: @"!MHMathGlyphAtom!"];
//    //return _glyphName; //This is probably wrong. Just checking the output.
//}



@end
