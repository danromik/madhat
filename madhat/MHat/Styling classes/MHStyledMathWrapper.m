//
//  MHStyledMathWrapper.m
//  MadHat
//
//  Created by Dan Romik on 8/10/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHStyledMathWrapper.h"
#import "MHStyleIncludes.h"

NSString * const kMHStyledBoldMathCommandName = @"bold math";                    // alias bmath
NSString * const kMHStyledItalicMathCommandName = @"italic math";                // alias itmath
NSString * const kMHStyledBlackboardMathCommandName = @"blackboard math";        // alias bbmath
NSString * const kMHStyledCalligraphyMathCommandName = @"calligraphy math";      // alias calmath
NSString * const kMHStyledFrakturMathCommandName = @"fraktur math";              // alias frakmath
NSString * const kMHStyledRomanMathCommandName = @"roman math";
NSString * const kMHStyledMonospaceMathCommandName = @"mono math";
NSString * const kMHStyledSansSerifMathCommandName = @"sans math";




@interface MHStyledMathWrapper ()
{
    MHMathFontVariant _mathFontVariant;
}
@end


@implementation MHStyledMathWrapper



#pragma mark - Constructors

+ (instancetype)styledMathWrapperWithMathFontVariant:(MHMathFontVariant)mathFontVariant contents:(MHExpression *)contents
{
    return [[self alloc] initWithMathFontVariant:mathFontVariant contents:contents];
}

- (instancetype)initWithMathFontVariant:(MHMathFontVariant)mathFontVariant contents:(MHExpression *)contents
{
    if (self = [super initWithContents:contents]) {
        _mathFontVariant = mathFontVariant;
    }
    return self;
}



#pragma mark - MHCommand protocol

+ (MHExpression *)commandNamed:(NSString *)name
                withParameters:(nullable NSDictionary *)parameters
                      argument:(MHHorizontalLayoutContainer *)argument
{
    if ([name isEqualToString:kMHStyledBoldMathCommandName]) {
        return [self styledMathWrapperWithMathFontVariant:MHMathFontVariantBold contents:argument];
    }
    if ([name isEqualToString:kMHStyledItalicMathCommandName]) {
        return [self styledMathWrapperWithMathFontVariant:MHMathFontVariantItalic contents:argument];
    }
    if ([name isEqualToString:kMHStyledBlackboardMathCommandName]) {
        return [self styledMathWrapperWithMathFontVariant:MHMathFontVariantBlackboard contents:argument];
    }
    if ([name isEqualToString:kMHStyledCalligraphyMathCommandName]) {
        return [self styledMathWrapperWithMathFontVariant:MHMathFontVariantCalligraphy contents:argument];
    }
    if ([name isEqualToString:kMHStyledFrakturMathCommandName]) {
        return [self styledMathWrapperWithMathFontVariant:MHMathFontVariantFraktur contents:argument];
    }
    if ([name isEqualToString:kMHStyledMonospaceMathCommandName]) {
        return [self styledMathWrapperWithMathFontVariant:MHMathFontVariantMonospace contents:argument];
    }
    if ([name isEqualToString:kMHStyledSansSerifMathCommandName]) {
        return [self styledMathWrapperWithMathFontVariant:MHMathFontVariantSansSerif contents:argument];
    }
    if ([name isEqualToString:kMHStyledRomanMathCommandName]) {
        return [self styledMathWrapperWithMathFontVariant:MHMathFontVariantRoman contents:argument];
    }
    return nil;
}

+ (NSArray <NSString *> *)recognizedCommands
{
    return @[
        kMHStyledBoldMathCommandName,
        kMHStyledItalicMathCommandName,
        kMHStyledBlackboardMathCommandName,
        kMHStyledCalligraphyMathCommandName,
        kMHStyledFrakturMathCommandName,
        kMHStyledRomanMathCommandName,
        kMHStyledMonospaceMathCommandName,
        kMHStyledSansSerifMathCommandName
    ];
}



#pragma mark - Typesetting

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{

//    [contextManager beginLocalScope];   // FIXME: do we need this?

    MHMathFontVariant currentMathFontVariant = contextManager.mathFontVariant;
    contextManager.mathFontVariant = _mathFontVariant;
    [super typesetWithContextManager:contextManager];
    contextManager.mathFontVariant = currentMathFontVariant;

//    [contextManager endLocalScope];   // FIXME: do we need this?
}




#pragma mark - Expression copying

- (instancetype)logicalCopy
{
    MHStyledMathWrapper *myCopy = [[self class] styledMathWrapperWithMathFontVariant:_mathFontVariant contents:[self.contents logicalCopy]];
    myCopy.codeRange = self.codeRange;
    return myCopy;
}


- (NSString *) exportedLaTeXValue
{
    if (_mathFontVariant == MHMathFontVariantBold)
        return [NSString stringWithFormat: @"\\mathbf{%@}", self.contents.exportedLaTeXValue];
    if (_mathFontVariant == MHMathFontVariantItalic)
        return [NSString stringWithFormat: @"\\mathit{%@}", self.contents.exportedLaTeXValue];
    if (_mathFontVariant == MHMathFontVariantFraktur)
        return [NSString stringWithFormat: @"\\mathfrak{%@}", self.contents.exportedLaTeXValue];
    if (_mathFontVariant == MHMathFontVariantBlackboard)
        return [NSString stringWithFormat: @"\\mathbb{%@}", self.contents.exportedLaTeXValue];
    if (_mathFontVariant == MHMathFontVariantCalligraphy)
        return [NSString stringWithFormat: @"\\mathcal{%@}", self.contents.exportedLaTeXValue];
    
    // if we got this far, not sure what to do, so let the super method handle it
    return super.exportedLaTeXValue;
}


@end
