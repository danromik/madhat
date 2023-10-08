//
//  MHWrapper.m
//  MadHat
//
//  Created by Dan Romik on 7/31/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHWrapper.h"

@interface MHWrapper ()
{
    MHExpression *_contents;
}
@end


@implementation MHWrapper

- (instancetype)initWithContents:(MHExpression *)contents
{
    if (self = [super init]) {
        self.contents = contents;
    }
    return self;
}



- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    [super typesetWithContextManager:contextManager];
    
    // A wrapper expression takes on the dimensions of its contents by default
    self.dimensions = _contents.dimensions;
}


- (MHExpression *)contents
{
    return _contents;
}

- (void)setContents:(MHExpression *)contents
{
    _contents.parent = nil;
    _contents = contents;
    _contents.parent = self;
    contents.nestingLevel = self.nestingLevel;
    contents.presentationMode = self.presentationMode;
}

- (bool)splittable
{
    return _contents.splittable;
}

- (bool)atomicForReformatting
{
    return _contents.atomicForReformatting;
}


- (NSArray <MHExpression *> *)subexpressions
{
    return @[ _contents ];
}

- (NSArray <MHExpression *> *)flattenedListOfUnsplittableComponents
{
    // if this method was called, we must have returned 'true' to a call to 'splittable', and this means that _contents.splittable is true, and therefore _contents can be safely assumed to conform to the MHSplittableExpression protocol
    return [(MHExpression <MHSplittableExpression> *)_contents flattenedListOfUnsplittableComponents];
}

- (NSArray <MHExpression *> *)flattenedListOfAtomicComponentsForSlideTransitions
{
    // if this method was called, we must have returned 'false' to a call to 'atomicForReformatting', and this means that _contents.atomicForReformatting is false, and therefore _contents can be safely assumed to conform to the MHDecomposableForReformatting protocol
    return [(MHExpression <MHDecomposableForReformatting> *)_contents flattenedListOfAtomicComponentsForSlideTransitions];
}


- (MHTypographyClass)typographyClass
{
    return _contents.typographyClass;
}
- (MHTypographyClass)leftTypographyClass
{
    return _contents.leftTypographyClass;
}
- (MHTypographyClass)rightTypographyClass
{
    return _contents.rightTypographyClass;
}

- (NSString *)stringValue
{
    return _contents.stringValue;
}

- (NSString *)exportedLaTeXValue
{
    // usually a wrapper subclass will wrap the contents inside some latex command, e.g., "\textbf{...}", but if the subclass doesn't implement the export method, the least we can do is return the exported latex string for the contents without wrapping it in anything
    return self.contents.exportedLaTeXValue;
}


@end
