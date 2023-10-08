//
//  MHHorizontalLayoutContainer.m
//  MadHat
//
//  Created by Dan Romik on 10/23/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "MHHorizontalLayoutContainer.h"
#import "MHWhitespace.h"
#import "MHTextAtom.h"
#import "MHBracket.h"
#import "MHMathFontSystem.h"





@implementation MHHorizontalLayoutContainer



+ (instancetype)formattedContainerWithArrayOfPlainTextStrings:(NSArray *)array
{
    return [[self alloc] initWithArrayOfPlainTextStrings:array];
}

- (instancetype)initWithArrayOfPlainTextStrings:(NSArray <NSString *> *)array
{
    if (self = [super init]) {
        for (NSString *plainText in array) {
            [self addSubexpression:[MHHorizontalLayoutContainer containerWithPlainTextString:[NSString stringWithFormat:@"• %@",plainText]]];
            [self addSubexpression:[MHWhitespace newline]];
        }
    }
    return self;
}



#pragma mark - Properties

- (bool)splittable
{
    return true;
}

- (bool)atomicForReformatting
{
    return false;
}

- (MHTypographyClass)leftTypographyClass
{
    for (MHExpression *expression in _subexpressions) {
        MHTypographyClass subexpTypoClass = expression.leftTypographyClass;
        if (subexpTypoClass != MHTypographyClassNone)
            return subexpTypoClass;
    }
    return MHTypographyClassNone;
}

- (MHTypographyClass)rightTypographyClass
{
    NSInteger index;
    NSInteger subexpCount = _subexpressions.count;
    for (index = subexpCount-1; index >= 0; index--) {
        MHExpression *expression = _subexpressions[index];
        MHTypographyClass subexpTypoClass = expression.rightTypographyClass;
        if (subexpTypoClass != MHTypographyClassNone)
            return subexpTypoClass;
    }
    return MHTypographyClassNone;
}






#pragma mark - typesetting and reformatting

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    MHDimensions myDimensions;
    myDimensions.width = 0.0;
    myDimensions.height = 0.0;
    myDimensions.depth = 0.0;

    MHDimensions bracketedSubblockDimensions;
    bracketedSubblockDimensions.height = 0.0;
    bracketedSubblockDimensions.depth = 0.0;
    
    bool locallyScoped = self.locallyScoped;
    if (locallyScoped)
        [contextManager beginLocalScope];
    
    NSUInteger numberOfSubexpressions = _subexpressions.count;
    NSUInteger index;
    
    NSMutableArray <NSDictionary *> *bracketsInfoStack;
    
    NSUInteger myNestingLevel = self.nestingLevel;
    
    MHBracketOrientation orientationForNextDirectionallyAmbiguousBracket = MHBracketLeftOrientation;

//    for (MHExpression *subexpression in _subexpressions) {
    for (index = 0; index < numberOfSubexpressions; index++) {
        MHExpression *subexpression = [_subexpressions objectAtIndex:index];
        MHExpression *nextSubexpression;
        
        // Is the subexpression an adjustable height symbol?
        bool subexpIsAdjustableHeight = [subexpression conformsToProtocol:@protocol(MHBracket)] &&
        ((id <MHBracket>)subexpression).heightIsAdjustable;

        // If it is, look up its orientation
        MHBracketOrientation adjustableHeightSubexpOrientation = MHBracketDynamicallyDeterminedOrientation;
        if (subexpIsAdjustableHeight)
            adjustableHeightSubexpOrientation = ((id <MHBracket>)subexpression).orientation;
        
        // Now determine the typography class of the subexpression and the one that will follow it
        MHTypographyClass thisSubexpressionClass = subexpression.rightTypographyClass;
        MHTypographyClass nextSubexpressionClass = MHTypographyClassNone;

        CGFloat kernWidth = 0.0;
        
//        if (thisSubexpressionClass == MHTypographyClassUnknown) {
            // Unknown typography class: need to figure out how to handle the situation
            // this is handled below for dynamically determined orientation brackets, which is currently the only case that will lead to an unknown typography class
//        }
            
        // Now check whether we're dealing a bracket symbol with the "dynamically determined" orientation
        if (subexpIsAdjustableHeight && adjustableHeightSubexpOrientation == MHBracketDynamicallyDeterminedOrientation) {
            // Set the orientation to what we're expecting it based on the brackets we encountered so far
            adjustableHeightSubexpOrientation = orientationForNextDirectionallyAmbiguousBracket;
            ((id <MHBracket>)subexpression).orientation = adjustableHeightSubexpOrientation;

            // Adjust our expectations for the future
            orientationForNextDirectionallyAmbiguousBracket =
            (orientationForNextDirectionallyAmbiguousBracket == MHBracketLeftOrientation ?
             MHBracketRightOrientation : MHBracketLeftOrientation);

            if (thisSubexpressionClass == MHTypographyClassUnknown) {
                // Read the typography class again (should give the correct value now)
                thisSubexpressionClass = subexpression.rightTypographyClass;
            }
        }
            
        // If the typography class is still unknown at this point, just leave it as is and don't do kerning (this shouldn't happen, but if it does at least we'll handle the situation gracefully)

        if (thisSubexpressionClass != MHTypographyClassWhiteSpace &&
            thisSubexpressionClass != MHTypographyClassNone &&
            thisSubexpressionClass != MHTypographyClassUnknown && index != numberOfSubexpressions-1) {
        
            // Since the subexpression has a non-space typography class and isn't the last element of the subexpressions array, we look at its typography class
            // and that of the next subexpression with a typography class in order to calculate kerning
            
            NSUInteger nextSubexpIndex = index+1;
            
            // FIXME: it's inefficient here to look up the next subexpression via the "objectAtIndex:" method but not keep it around for the next loop iteration where we'll be looking it up again - improve
            while (nextSubexpIndex < numberOfSubexpressions &&
                   (nextSubexpressionClass = (nextSubexpression=[_subexpressions objectAtIndex:nextSubexpIndex]).leftTypographyClass)
                   == MHTypographyClassNone) {
                nextSubexpIndex++;
            }
            
            if (nextSubexpressionClass == MHTypographyClassUnknown) {
                // The typography class for the next subexpression is unknown. Try to decide the class based on the scenarios where that might happen
                
                // The first (and currently only) scenario is if the subexpression is an adjustable height symbol with the "dynamically determined" orientation. Check if this case applies:
                bool nextSubexpIsAdjustableHeight = [nextSubexpression conformsToProtocol:@protocol(MHBracket)] &&
                ((id <MHBracket>)nextSubexpression).heightIsAdjustable;

                if (nextSubexpIsAdjustableHeight) {
                    MHBracketOrientation nextSubExpOrientation = ((id <MHBracket>)nextSubexpression).orientation;
                    if (nextSubExpOrientation == MHBracketDynamicallyDeterminedOrientation) {
                        // Yes, our hunch was correct. In this case we can predict what the orientation will end up being:
                        nextSubexpressionClass =
                        (orientationForNextDirectionallyAmbiguousBracket == MHBracketLeftOrientation ?
                         MHTypographyClassLeftBracket : MHTypographyClassRightBracket);
                    }
                }
                
                // If we reached this far and were not able to decide the next subexpression's typography class, leave it as is. There will be no kerning in that case. (This shouldn't happen if I am correctly handling all scenarios.)
            }
            
            if (nextSubexpressionClass != MHTypographyClassNone
                && nextSubexpressionClass != MHTypographyClassWhiteSpace
                && nextSubexpressionClass != MHTypographyClassUnknown) {
                kernWidth = [contextManager mathKernWidthForLeftTypographyClass:thisSubexpressionClass
                                                           rightTypographyClass:nextSubexpressionClass
                                                                   nestingLevel:myNestingLevel];
            }
        }

        MHDimensions zeroDimensions;
        zeroDimensions.depth = 0.0;
        zeroDimensions.height = 0.0;
        if (subexpIsAdjustableHeight) {
            if (adjustableHeightSubexpOrientation == MHBracketLeftOrientation) {
                ((id <MHBracket>)subexpression).dimensionsIgnoringWidth = zeroDimensions;
                NSDictionary *bracketInfo = @{
                    @"bracketIndex" : [NSNumber numberWithUnsignedInt:(unsigned int)index],
                    @"bracketedSubblockCurrentHeight" : [NSNumber numberWithFloat:bracketedSubblockDimensions.height],
                    @"bracketedSubblockCurrentDepth" : [NSNumber numberWithFloat:bracketedSubblockDimensions.depth],
                    @"bracketXPosition" : [NSNumber numberWithFloat:myDimensions.width]
                };
                if (!bracketsInfoStack) {
                    bracketsInfoStack = [[NSMutableArray alloc] initWithCapacity:0];
                }
                [bracketsInfoStack addObject:bracketInfo];
                bracketedSubblockDimensions.height = 0.0;
                bracketedSubblockDimensions.depth = 0.0;
            }
            else if (bracketsInfoStack.count > 0) {
                
                if (adjustableHeightSubexpOrientation == MHBracketMiddleOrientation) {
                    // For middle brackets, we add their info to the top item in the brackets info stack and retypeset them later when we process the closing bracket
                    
                    ((id <MHBracket>)subexpression).dimensionsIgnoringWidth = zeroDimensions;

                    NSDictionary *openBracketInfo = [bracketsInfoStack lastObject];
                    NSDictionary *newOpenBracketInfo = @{
                        @"bracketIndex" : openBracketInfo[@"bracketIndex"],
                        @"bracketedSubblockCurrentHeight" : openBracketInfo[@"bracketedSubblockCurrentHeight"],
                        @"bracketedSubblockCurrentDepth" : openBracketInfo[@"bracketedSubblockCurrentDepth"],
                        @"bracketXPosition" : openBracketInfo[@"bracketXPosition"],
                        @"middleBracketIndex" : [NSNumber numberWithUnsignedInt:(unsigned int)index]
                    };

                    [bracketsInfoStack replaceObjectAtIndex:bracketsInfoStack.count-1 withObject:newOpenBracketInfo];
                }
                else {
                
                    // The block below is also copied verbatim outside the loop to take care of closing the brackets after exiting the loop
                    // (FIXME: is there a better way to do this without violating the DRY principle?)

                    NSDictionary *bracketInfo = [bracketsInfoStack lastObject];
                    [bracketsInfoStack removeLastObject];
                    NSUInteger openBracketIndex = [(NSNumber *)(bracketInfo[@"bracketIndex"]) unsignedIntValue];
                    MHBracket *openBracketSubexpression = (MHBracket *)[_subexpressions objectAtIndex:openBracketIndex];
                    
                    CGFloat openBracketWidthBeforeResizing = openBracketSubexpression.dimensions.width;
                    CGFloat middleBracketWidthBeforeResizing = 0.0;

                    openBracketSubexpression.dimensionsIgnoringWidth = bracketedSubblockDimensions;
                    [openBracketSubexpression typesetWithContextManager:contextManager];
                    
                    CGFloat openBracketXOrigin = [(NSNumber *)(bracketInfo[@"bracketXPosition"]) floatValue];
                    openBracketSubexpression.position = NSMakePoint(openBracketXOrigin, 0.0);
                                    
                    CGFloat openBracketWidthAfterResizing = openBracketSubexpression.dimensions.width;
                    CGFloat middleBracketWidthAfterResizing = 0.0;
                    CGFloat resizingOffset = openBracketWidthAfterResizing - openBracketWidthBeforeResizing;
                    CGFloat resizingOffsetAfterMiddleBracket = resizingOffset;

                    NSNumber *middleBracketIndexEntry = (NSNumber *)(bracketInfo[@"middleBracketIndex"]);
                    MHBracket *middleBracketSubexpression = nil;
                    NSUInteger middleBracketIndex = index+1;
                    if (middleBracketIndexEntry) {
                        middleBracketIndex = [middleBracketIndexEntry unsignedIntValue];
                        middleBracketSubexpression = (MHBracket *)[_subexpressions objectAtIndex:middleBracketIndex];
                        middleBracketWidthBeforeResizing = middleBracketSubexpression.dimensions.width;
                        middleBracketSubexpression.dimensionsIgnoringWidth = bracketedSubblockDimensions;
                        [middleBracketSubexpression typesetWithContextManager:contextManager];
                        middleBracketWidthAfterResizing = middleBracketSubexpression.dimensions.width;
                        resizingOffsetAfterMiddleBracket = resizingOffset + middleBracketWidthAfterResizing - middleBracketWidthBeforeResizing;
                    }

                    ((id <MHBracket>)subexpression).dimensionsIgnoringWidth = bracketedSubblockDimensions;
                    
                    // FIXME: Violates OO good practice - refactor
                    if (((id <MHBracket>)subexpression).sizeVariant == MHBracketDynamicallyDeterminedSize)
                        ((id <MHBracket>)subexpression).sizeVariant = openBracketSubexpression.sizeVariant;

                    if (((id <MHBracket>)subexpression).type == MHBracketTypeMatchOpposingBracket)
                        ((id <MHBracket>)subexpression).type = openBracketSubexpression.type;

                    
                    
                    MHDimensions newDimensions;
                    newDimensions.height = [(NSNumber *)(bracketInfo[@"bracketedSubblockCurrentHeight"]) floatValue];
                    newDimensions.depth = [(NSNumber *)(bracketInfo[@"bracketedSubblockCurrentDepth"]) floatValue];
                    bracketedSubblockDimensions.height = (bracketedSubblockDimensions.height > newDimensions.height ?
                                                          bracketedSubblockDimensions.height : newDimensions.height);
                    bracketedSubblockDimensions.depth = (bracketedSubblockDimensions.depth > newDimensions.depth ?
                                                          bracketedSubblockDimensions.depth : newDimensions.depth);
                    
                    NSUInteger blockLoopIndex;
                    for (blockLoopIndex = openBracketIndex+1; blockLoopIndex < index; blockLoopIndex++) {
                        MHExpression *subexp = [_subexpressions objectAtIndex:blockLoopIndex];
                        NSPoint oldPosition = subexp.position;
                        
                        // FIXME: in the next line, should it be "blockLoopIndex < middleBracketIndex" or "blockLoopIndex <= middleBracketIndex"? In practice the middle bracket width seems to stays the same after resizing so I didn't bother to think about this too much
                        subexp.position = NSMakePoint(oldPosition.x + (!middleBracketSubexpression || blockLoopIndex < middleBracketIndex ? resizingOffset : resizingOffsetAfterMiddleBracket),
                                                      oldPosition.y);
                    }
                    myDimensions.width += resizingOffsetAfterMiddleBracket;
                }
            }
        }
        
        [subexpression typesetWithContextManager:contextManager];
        MHDimensions subexpDimensions = subexpression.dimensions;
        subexpression.position = NSMakePoint(myDimensions.width, 0.0);
        myDimensions.width += subexpDimensions.width + kernWidth;

        if (myDimensions.height < subexpDimensions.height)
            myDimensions.height = subexpDimensions.height;
        if (myDimensions.depth < subexpDimensions.depth)
            myDimensions.depth = subexpDimensions.depth;

        if (bracketedSubblockDimensions.height < subexpDimensions.height)
            bracketedSubblockDimensions.height = subexpDimensions.height;
        if (bracketedSubblockDimensions.depth < subexpDimensions.depth)
            bracketedSubblockDimensions.depth = subexpDimensions.depth;
    }
    
    // At the end of the loop, there might be some unclosed brackets, so close them
    while (bracketsInfoStack.count > 0) {
        // This block of code copied and pasted from the subexpression loop above, make sure to change it if I change something there
        // (FIXME: is there a better way to do this without violating the DRY principle?)
        // FIXME: I didn't copy over the code for handling middle brackets - seems redundant since in practice there doesn't seem to be a realistic use case for  an open bracket followed by a middle bracket without the presence of a closing bracket at the end
        NSDictionary *bracketInfo = [bracketsInfoStack lastObject];
        [bracketsInfoStack removeLastObject];
        NSUInteger openBracketIndex = [(NSNumber *)(bracketInfo[@"bracketIndex"]) unsignedIntValue];
        MHBracket *openBracketSubexpression = (MHBracket *)[_subexpressions objectAtIndex:openBracketIndex];
        
        CGFloat openBracketWidthBeforeResizing = openBracketSubexpression.dimensions.width;
        
        openBracketSubexpression.dimensionsIgnoringWidth = bracketedSubblockDimensions;
        [openBracketSubexpression typesetWithContextManager:contextManager];
        
        CGFloat openBracketXOrigin = [(NSNumber *)(bracketInfo[@"bracketXPosition"]) floatValue];
        openBracketSubexpression.position = NSMakePoint(openBracketXOrigin, 0.0);
                        
        CGFloat openBracketWidthAfterResizing = openBracketSubexpression.dimensions.width;
        CGFloat resizingOffset = openBracketWidthAfterResizing - openBracketWidthBeforeResizing;

//        ((id <MHBracket>)subexpression).dimensionsIgnoringWidth = bracketedSubblockDimensions;
        MHDimensions newDimensions;
        newDimensions.height = [(NSNumber *)(bracketInfo[@"bracketedSubblockCurrentHeight"]) floatValue];
        newDimensions.depth = [(NSNumber *)(bracketInfo[@"bracketedSubblockCurrentDepth"]) floatValue];
        bracketedSubblockDimensions.height = (bracketedSubblockDimensions.height > newDimensions.height ?
                                              bracketedSubblockDimensions.height : newDimensions.height);
        bracketedSubblockDimensions.depth = (bracketedSubblockDimensions.depth > newDimensions.depth ?
                                              bracketedSubblockDimensions.depth : newDimensions.depth);
        
        NSUInteger blockLoopIndex;
        for (blockLoopIndex = openBracketIndex+1; blockLoopIndex < index; blockLoopIndex++) {
            MHExpression *subexp = [_subexpressions objectAtIndex:blockLoopIndex];
            NSPoint oldPosition = subexp.position;
            subexp.position = NSMakePoint(oldPosition.x + resizingOffset, oldPosition.y);
        }
        myDimensions.width += resizingOffset;
    }
    
    if (locallyScoped)
        [contextManager endLocalScope];

    self.dimensions = myDimensions;
    
}





#pragma mark - Miscellaneous


// FIXME: these two methods are substantially similar to each other. A possibly better solution would be to create a custom enumerator class that recursively iterates through the tree of subexpressions and can be configured to not go deeper than the levels specified by either the "splittable" or "atomicForReformatting" parameters

- (NSArray *)flattenedListOfUnsplittableComponents
{
    NSMutableArray *listOfSubexpressions = [NSMutableArray arrayWithCapacity:0];
    for (MHExpression *subexpression in _subexpressions) {
        if (subexpression.splittable) {
            // An expression that identifies itself as splittable is assumed to belong to a class that conforms to the MHSplittableExpression protocol
            [listOfSubexpressions addObjectsFromArray:[(id <MHSplittableExpression>)subexpression flattenedListOfUnsplittableComponents]];
        }
        else {
            [listOfSubexpressions addObject:subexpression];
        }
    }
    return listOfSubexpressions;
}


- (NSArray *)flattenedListOfAtomicComponentsForSlideTransitions
{
    NSMutableArray *listOfSubexpressions = [NSMutableArray arrayWithCapacity:0];
    for (MHExpression *subexpression in _subexpressions) {
        if (!subexpression.atomicForReformatting) {
            // An expression that identifies itself as not atomic is assumed to belong to a class that conforms to the MHDecomposableForReformatting protocol
            [listOfSubexpressions addObjectsFromArray:[(id <MHDecomposableForReformatting>)subexpression flattenedListOfAtomicComponentsForSlideTransitions]];
        }
        else {
            [listOfSubexpressions addObject:subexpression];
        }
    }
    return listOfSubexpressions;
}



#pragma mark - Convenience constructors

+ (instancetype)containerWithPlainTextString:(NSString *)string
{
    return [[self alloc] initWithPlainTextString:string];
}

- (instancetype)initWithPlainTextString:(NSString *)string
{
    if (self = [super init]) {
        NSArray <NSString *> *components = [string componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSUInteger index = 0;
        NSUInteger count = components.count;
        for (NSString *component in components) {
            if (component.length > 0) {
                [self addSubexpression:[MHTextAtom textAtomWithString:component]];
            }
            if (index < count - 1) {
                [self addSubexpression:[MHWhitespace space]];    // FIXME: improve
            }
            index++;
        }
    }
    return self;
}




#pragma mark - Debugging

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ subexpressions=%@>",
            [self className], (_subexpressions ? self.subexpressions.description : @"[none]")];
}


// DR: commented out implementation. put the code in MHLinearContainer which is the correct place for this
//- (NSString *)exportedLaTeXValue
////Dan did this method definition.
////RS - Maybe insert some condition here to see if we really want to append the next expression,
////motivated by problem with binomial and quasifraction.
//{
//   NSMutableString *aString = [NSMutableString stringWithCapacity:0];
//    for (MHExpression *subexpression in _subexpressions)
//    {
//    [aString appendFormat:@"%@",subexpression.exportedLaTeXValue];
//    }
//    return aString;
//}


@end


