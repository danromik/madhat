//
//  MHVerticalLayoutContainer.m
//  MadHat
//
//  Created by Dan Romik on 10/31/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "MHVerticalLayoutContainer.h"
#import "MHParagraphEnumerator.h"
#import "MHParagraph.h"
#import "MHTextParagraph.h"
#import "MHStyleIncludes.h"
#import "MHPDFRenderingContextManager.h"


#import "MHListCommand.h"

// A definition to help signal when an NSRange variable refers to all paragraphs
static const NSRange MHAllParagraphsRange = { 0, NSIntegerMax };

// And a related macro for checking this (needed because C99 has no equality operator for structs)
#define IsAllParagraphsRange(range) (range.location == MHAllParagraphsRange.location && range.length == MHAllParagraphsRange.length)


// FIXME: some temporary values for paragraph spacings - make this customizable later
//static CGFloat preParagraphSpacingFactors[] = {
//    0.5,        // pre-paragraph spacing for a normal paragraph
//    3.0,        // pre-paragraph spacing for a header paragraph
//    1.0,        // pre-paragraph spacing for a subheader paragraph
//    0.5,        // pre-paragraph spacing for a subsubheader paragraph
//    0.5,        // pre-paragraph spacing for a paragraph with a paragraph header
//    4.0,        // pre-paragraph spacing for a superheader paragraph
//    0.25,        // pre-paragraph spacing for a list item paragraph
//    0,          // pre-paragraph spacing for a quoted code paragraph
//};
//static CGFloat postParagraphSpacingFactors[] = {
//    0.5,        // pose-paragraph spacing for a normal paragraph
//    1.8,        // post-paragraph spacing for a header paragraph
//    1.5,        // post-paragraph spacing for a subheader paragraph
//    1.0,        // post-paragraph spacing for a subsubheader paragraph
//    0.5,        // post-paragraph spacing for a paragraph with a paragraph header
//    2.5,        // post-paragraph spacing for a superheader paragraph
//    0.55,       // post-paragraph spacing for a list item paragraph
//    0,          // post-paragraph spacing for a quoted code paragraph
//};



@interface MHVerticalLayoutContainer ()
{
    NSUInteger _numberOfSlideTransitions;
}

@end



@implementation MHVerticalLayoutContainer


- (bool)locallyScoped
{
    return false;
}

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
//    CFAbsoluteTime timeInSeconds = CFAbsoluteTimeGetCurrent();        // can be used for performance profiling
    NSUInteger slideTransitionCounterAtBeginning = contextManager.slideTransitionCounter;
    [self retypesetParagraphsInRange:MHAllParagraphsRange withContextManager:contextManager];
    NSUInteger slideTransitionCounterAtEnd = contextManager.slideTransitionCounter;
    _numberOfSlideTransitions = slideTransitionCounterAtEnd - slideTransitionCounterAtBeginning;
//    NSLog(@"typesetting time=%f", CFAbsoluteTimeGetCurrent()-timeInSeconds);

}

- (void)retypesetParagraphsInRange:(NSRange)range withContextManager:(MHTypesettingContextManager *)contextManager
{

#pragma mark - setup
    MHDimensions myDimensions;
    myDimensions.width = 0.0;
    myDimensions.height = 0.0;
    myDimensions.depth = 0.0;
    
    MHParagraphKerningMatrixCastAsPointer paragraphKerningMatrix = contextManager.paragraphKerningMatrix;
    
    
    // Are we doing incremental typesetting or typesetting everything?
    bool typesetAllParagraphs = IsAllParagraphsRange(range);
    
    // FIXME: this assumes the value doesn't change between paragraphs. Need to improve code to take into account possibility of the value changing
    // FIXME: even with the assumption that the value doesn't change between paragraphs, this is buggy and doesn't work well with incremental typesetting - fix
    CGFloat paragraphSpacing;

    CGFloat leftMargin = contextManager.pageLeftMargin;
    CGFloat baseFontSize = contextManager.baseFontSize;

    bool locallyScoped = self.locallyScoped;
    if (locallyScoped)      // FIXME: not good OO practice - find a way to inherit this behavior
        [contextManager beginLocalScope];
    
    // Set the typing style to what it needs to be before typesetting the paragraphs in the range we were passed
    if (range.location == 0) {
        [contextManager resetToDefaultState];
        paragraphSpacing = contextManager.baseParagraphSpacing * baseFontSize;
        myDimensions.depth = 0.0;
    }
    else {
        // FIXME: this next bit can maybe be made shorter/more readable by iterating using an MHParagraphEnumerator
        
        MHParagraph *paragraphBeforeRange = [self expressionAtIndex:range.location-1];
        MHDimensions paragraphBeforeRangeDimensions = paragraphBeforeRange.dimensions;
        [contextManager resetToMemoizedState:paragraphBeforeRange.memoizedStateAfterTypesetting];
        paragraphSpacing = contextManager.baseParagraphSpacing * baseFontSize;
        
        NSArray <MHExpression *> *parBeforeRangeAttachedContent = paragraphBeforeRange.attachedContent;
        if (parBeforeRangeAttachedContent) {
            MHParagraph *lastAttachedParagraph = (MHParagraph *)(parBeforeRangeAttachedContent.lastObject); // FIXME: cast alert. Not good to assume things
            
            myDimensions.depth = -paragraphBeforeRange.position.y - lastAttachedParagraph.position.y;
        }
        else {
            myDimensions.depth = -paragraphBeforeRange.position.y + paragraphBeforeRangeDimensions.depth;
        }
    }
    
    MHParagraphType previousParagraphType = contextManager.paragraphType;

    NSUInteger paragraphIndex;
    MHTypesettingState *typesettingState;
    MHParagraph *paragraph;
    MHParagraph *previousParagraph = nil;
    
    NSUInteger numberOfParagraphs = [self numberOfSubexpressions];
    NSUInteger startingParagraphIndex;
    NSUInteger maxParagraphIndexPlusOne;
    if (typesetAllParagraphs) {
        startingParagraphIndex = 0;
        maxParagraphIndexPlusOne = numberOfParagraphs;
    }
    else {
        startingParagraphIndex = range.location;
        maxParagraphIndexPlusOne = range.location + range.length;
    }

#pragma mark - typesetting
    // Typeset the range of paragraphs, recording the typing styles before and after typesetting each paragraph
    for (paragraphIndex = startingParagraphIndex; paragraphIndex < maxParagraphIndexPlusOne; paragraphIndex++) {
        
        paragraph = [self expressionAtIndex:paragraphIndex];   // We know this is of kind MHParagraph from the MHIncrementalTypesetting protocol
        typesettingState = [contextManager memoizedState];
        previousParagraph.memoizedStateAfterTypesetting = typesettingState;
        paragraph.memoizedStateBeforeTypesetting = typesettingState;

        _numberOfSlideTransitions -= paragraph.numberOfSlideTransitions;    // with the current setup this number will always be 0 I think since the paragraph object is actually being typeset for the first time, but it's safer to include this
        [paragraph typesetWithContextManager:contextManager];
        _numberOfSlideTransitions += paragraph.numberOfSlideTransitions;
        
        previousParagraph = paragraph;
    }
    typesettingState = [contextManager memoizedState];
    previousParagraph.memoizedStateAfterTypesetting = typesettingState;

    // Now start looping through the paragraphs following the end of the range (in the incremental typesetting scenario),
    // checking for each one to see if there was a change in the typing style that requires that paragraph to be retypeset
    MHTypesettingState *newTypesettingState = typesettingState;
    MHTypesettingState *oldTypesettingState;
    while (paragraphIndex < numberOfParagraphs) {
        
        paragraph = [self expressionAtIndex:paragraphIndex];
        oldTypesettingState = paragraph.memoizedStateBeforeTypesetting;
        if ([oldTypesettingState isEqual:newTypesettingState])
            break;
        
        // If we're still in the loop, need to retypeset the paragraph
        paragraph.memoizedStateBeforeTypesetting = newTypesettingState;

        // commenting out, this will be correct but the adjustment for a possible change in the number of slide transitions is unnecessary since that number is unrelated to a change in the typing style so will not change
//        _numberOfSlideTransitions -= paragraph.numberOfSlideTransitions;
//        [paragraph typesetWithContextManager:contextManager];
//        _numberOfSlideTransitions += paragraph.numberOfSlideTransitions;
        
        // this is more efficient than the above commented out code
        [paragraph typesetWithContextManager:contextManager];

        newTypesettingState = [contextManager memoizedState];
        paragraph.memoizedStateAfterTypesetting = newTypesettingState;

        paragraphIndex++;
    }
    
    NSUInteger lastParagraphTypesetIndex = paragraphIndex-1;
    
//    NSLog(@"retypeset paragraphs %lu-%lu", startingParagraphIndex, lastParagraphTypesetIndex);
    
    bool totalDepthUnchangedFlag = false;
        
    
#pragma mark - layout
    // Now that all the paragraphs are typeset, lay out all the newly retypeset paragraphs vertically, cycling through them in order.
    // If the position of the next paragraph after the newly retypeset paragraphs changed, continue and lay out all the subsequent paragraphs as well (this is a small optimization: most of the time when typing the paragraphs below the insertion point aren't moving so don't need to be re-laid out).

    MHParagraphEnumerator *paragraphEnumerator = [[MHParagraphEnumerator alloc]
                                                  initWithArrayOfParagraphsWithAttachedContent:(NSArray <MHParagraph *>*)_subexpressions
                                                  startingParagraphIndex:startingParagraphIndex];   // FIXME: casting
        
    while ((paragraph = [paragraphEnumerator nextParagraph])) {
        
        MHParagraphType paragraphType = paragraph.type;
        
        MHDimensions parDimensions = paragraph.dimensions;

        CGFloat paragraphKern = 0.0;

        if (paragraphType != MHParagraphNone) {
            
            // FIXME: consider making these values customizable
            static CGFloat kernFromTextParagraphToMathParagraph = 0.6;
            static CGFloat kernFromMathParagraphToTextParagraph = 0.6;
            
            BOOL previousParagraphIsMath = MHParagraphTypeIsMathParagraph(previousParagraphType);
            BOOL thisParagraphIsMath = MHParagraphTypeIsMathParagraph(paragraphType);

            BOOL forceNewParagraph = MHParagraphTypeNewParagraphShouldBeForced(paragraphType);
            
            MHParagraphType prevParTypeFromBelow = MHParagraphEffectiveParagraphTypeFromBelow(previousParagraphType);
            MHParagraphType thisParTypeFromAbove = MHParagraphEffectiveParagraphTypeFromAbove(paragraphType);
            
            if ((!previousParagraphIsMath) && thisParagraphIsMath) {
                // transitioning from a text paragraph to a math paragraph
                paragraphKern = kernFromTextParagraphToMathParagraph * baseFontSize;
            }
            else if (previousParagraphIsMath && (!thisParagraphIsMath) && (!forceNewParagraph)) {
                // transitioning from a math paragraph to a text paragraph, and the text paragraph isn't marked as forcing a new paragraph
                paragraphKern = kernFromMathParagraphToTextParagraph * baseFontSize;
            }
            else {
                // all other transitions are kerned according to the paragraph kerning matrix
                paragraphKern = paragraphKerningMatrix[prevParTypeFromBelow * MHNumberOfEffectiveParagraphTypes + thisParTypeFromAbove] * paragraphSpacing;
                
                if (previousParagraphIsMath && (!thisParagraphIsMath)) {
                    // transitioning from a math paragraph to a text paragraph, and the text paragraph is marked as forcing a new paragraph -- in this scenario add the appropriate vertical spacing
                    paragraphKern += kernFromMathParagraphToTextParagraph * baseFontSize;
                }
            }
            myDimensions.depth += paragraphKern;
            
//            if (forceNewParagraph) {
//                paragraphKern = paragraphKerningMatrix[prevParTypeFromBelow * MHNumberOfEffectiveParagraphTypes + thisParTypeFromAbove] * paragraphSpacing;
//                myDimensions.depth += paragraphKern;
//            }
//            else {        // FIXME: for continuation paragraphs, should there be no kerning at all? The whole idea is to allow for math displays being contained in a single text paragraph, and no kerning doesn't produce very nice looking results, so this needs to be improved
//                // do nothing?
//            }
            
            previousParagraphType = paragraphType;
        }

        CGPoint paragraphNewPosition = NSMakePoint(leftMargin, -myDimensions.depth-parDimensions.height);

        if (typesetAllParagraphs) {
            paragraph.position = paragraphNewPosition;
            paragraph.uncollapsedYPosition = paragraphNewPosition.y;
        }
        else {
            CGPoint paragraphOldPosition = paragraph.position;
            if ((paragraphOldPosition.x != paragraphNewPosition.x) || (paragraphOldPosition.y != paragraphNewPosition.y)) {
                paragraph.position = paragraphNewPosition;
                paragraph.uncollapsedYPosition = paragraphNewPosition.y;
            }
            else if (paragraphIndex == lastParagraphTypesetIndex+1) {
                totalDepthUnchangedFlag = true;
                break;
            }
        }
        
        // FIXME: This is useful to get paragraph backgrounds working, and I'm also using this information in the -reformatWithContextManager: method below as part of the outliner feature implementation. But it's maybe not so much in the spirit of object-oriented programming, so think about whether the logic can be improved.
        MHParagraphVerticalPadding padding;
        padding.preParagraphSpacing = (paragraphType == MHParagraphBeginBox ? 0.0 : paragraphKern);
        padding.postParagraphSpacing = 0.0; // 0. * paragraphSpacing;
        paragraph.verticalPadding = padding;

        myDimensions.depth += parDimensions.depth + parDimensions.height;
        if (myDimensions.width < parDimensions.width)
            myDimensions.width = parDimensions.width;
    }
    
    if (totalDepthUnchangedFlag) {
        myDimensions.depth = self.dimensions.depth;     // no need to change the depth
    }
    else {
//        myDimensions.depth -= actualParagraphSpacing;   // if we got all the way to the last paragraph, no need to add the last spacing, so subtract it out
        myDimensions.depth -= paragraphSpacing;   // if we got all the way to the last paragraph, no need to add the last spacing, so subtract it out
    }
    
    if (locallyScoped)
        [contextManager endLocalScope];

    self.dimensions = myDimensions;
}

- (void)reformatWithContextManager:(MHReformattingContextManager *)contextManager animationType:(MHReformattingAnimationType)animationType
{
    MHParagraphEnumerator *paragraphEnumerator = [[MHParagraphEnumerator alloc]
                                                  initWithArrayOfParagraphsWithAttachedContent:(NSArray <MHParagraph *>*)_subexpressions];  // FIXME: casting
    MHParagraph *paragraph;
    
    while ((paragraph = [paragraphEnumerator nextParagraph])) {
        // Reposition the paragraph vertically based on the cumulative vertical offset reported from the context manager
        CGPoint paragraphNewPosition = paragraph.position;
        paragraphNewPosition.y = paragraph.uncollapsedYPosition + [contextManager currentVerticalOffsetOfCollapsedSections];
        [paragraph setPosition:paragraphNewPosition animated:(animationType == MHReformattingAnimationTypeOutliner)];
        
        [paragraph reformatWithContextManager:contextManager animationType:animationType];
                
        MHParagraphVerticalPadding paragraphVerticalPadding = paragraph.verticalPadding;
        MHOutlinerVisibilityState visiblityState = [contextManager currentOutlinerVisibilityState];
        if ((visiblityState & MHOutlinerVisibilityStateHiddenDueToAncestorNodeCollapsedPart)
            || ((visiblityState & MHOutlinerVisibilityStateHiddenDueToCurrentNodeCollapsedPart) &&
                ![paragraph hasVisibleContentWhenCollapsed])) {
            [contextManager incrementCollapsedSectionsVerticalOffsetBy:paragraphVerticalPadding.preParagraphSpacing + paragraphVerticalPadding.postParagraphSpacing];
        }
    }

}




- (void)addSubexpression:(MHExpression *)expression
{
    [super addSubexpression:expression];
    NSArray <MHExpression *> *attachedContent = expression.attachedContent;
    if (attachedContent) {
        for (MHExpression *attachedExpression in attachedContent) {
            attachedExpression.parent = self;
            attachedExpression.nestingLevel = self.nestingLevel;
            attachedExpression.presentationMode = self.presentationMode;
            if (_spriteKitNode) {
                [_spriteKitNode addChild:attachedExpression.spriteKitNode];
            }
        }
    }
}

- (void)replaceExpressionAtIndex:(NSUInteger)index withExpression:(MHExpression *)newExpression
{
    MHExpression *oldExpression = [_subexpressions objectAtIndex:index];
    NSArray <MHExpression *> *oldExpressionAttachedContent = oldExpression.attachedContent;
    NSArray <MHExpression *> *newExpressionAttachedContent = newExpression.attachedContent;

    for (MHExpression *attachedExpression in oldExpressionAttachedContent) {
        attachedExpression.parent = nil;
        if (_spriteKitNode) {
            [attachedExpression.spriteKitNode removeFromParent];
        }
    }

    for (MHExpression *attachedExpression in newExpressionAttachedContent) {
        attachedExpression.parent = self;
        attachedExpression.nestingLevel = self.nestingLevel;
        attachedExpression.presentationMode = self.presentationMode;
        if (_spriteKitNode) {
            [_spriteKitNode addChild:attachedExpression.spriteKitNode];
        }
    }

    [super replaceExpressionAtIndex:index withExpression:newExpression];
}

- (void)removeExpressionAtIndex:(NSUInteger)index
{
    MHExpression *oldExpression = [_subexpressions objectAtIndex:index];
    NSArray <MHExpression *> *oldExpressionAttachedContent = oldExpression.attachedContent;

    for (MHExpression *attachedExpression in oldExpressionAttachedContent) {
        attachedExpression.parent = nil;
        if (_spriteKitNode) {
            [attachedExpression.spriteKitNode removeFromParent];
        }
    }
    [super removeExpressionAtIndex:index];
}

- (void)insertExpression:(MHExpression *)expression atIndex:(NSUInteger)index
{
    NSArray <MHExpression *> *attachedContent = expression.attachedContent;

    for (MHExpression *attachedExpression in attachedContent) {
        attachedExpression.parent = self;
        attachedExpression.nestingLevel = self.nestingLevel;
        attachedExpression.presentationMode = self.presentationMode;
        if (_spriteKitNode) {
            [_spriteKitNode addChild:attachedExpression.spriteKitNode];
        }
    }
    [super insertExpression:expression atIndex:index];
}

- (void)replaceParagraphAtIndex:(NSUInteger)index withParagraph:(MHParagraph *)newParagraph
{
    MHParagraph *oldParagraph = (MHParagraph *)[_subexpressions objectAtIndex:index];       // FIXME: casting - bad to make assumptions
    NSUInteger oldParagraphNumberOfSlideTransitions = oldParagraph.numberOfSlideTransitions;
    NSUInteger newParagraphNumberOfSlideTransitions = newParagraph.numberOfSlideTransitions;
    [self replaceExpressionAtIndex:index withExpression:newParagraph];
    _numberOfSlideTransitions += newParagraphNumberOfSlideTransitions - oldParagraphNumberOfSlideTransitions;
}

- (void)removeParagraphAtIndex:(NSUInteger)index
{
    MHParagraph *oldParagraph = (MHParagraph *)[_subexpressions objectAtIndex:index];       // FIXME: casting - bad to make assumptions
    NSUInteger oldParagraphNumberOfSlideTransitions = oldParagraph.numberOfSlideTransitions;
    [self removeExpressionAtIndex:index];
    _numberOfSlideTransitions -= oldParagraphNumberOfSlideTransitions;
}

- (void)insertParagraph:(MHParagraph *)paragraph atIndex:(NSUInteger)index
{
    NSUInteger newParagraphNumberOfSlideTransitions = paragraph.numberOfSlideTransitions;
    [self insertExpression:paragraph atIndex:index];
    _numberOfSlideTransitions += newParagraphNumberOfSlideTransitions;
}

- (NSUInteger)numberOfSlideTransitions
{
    return _numberOfSlideTransitions;
}



- (SKNode *)spriteKitNode
{
    if (!_spriteKitNode) {
        _spriteKitNode = super.spriteKitNode;
        for (MHParagraph *paragraph in _subexpressions) {
            for (MHParagraph *attachedParagraph in paragraph.attachedContent) {
                [_spriteKitNode addChild:attachedParagraph.spriteKitNode];
            }
        }
    }
    return _spriteKitNode;
}

- (void)setNestingLevel:(NSUInteger)nestingLevel
{
    super.nestingLevel = nestingLevel;
    for (MHParagraph *paragraph in _subexpressions) {
        for (MHParagraph *attachedParagraph in paragraph.attachedContent) {
            attachedParagraph.nestingLevel = nestingLevel;
        }
    }
}

- (void)setPresentationMode:(MHExpressionPresentationMode)presentationMode
{
    super.presentationMode = presentationMode;
    for (MHParagraph *paragraph in _subexpressions) {
        for (MHParagraph *attachedParagraph in paragraph.attachedContent) {
            attachedParagraph.presentationMode = presentationMode;
        }
    }
}



// Experimental

- (MHLayoutType)layoutPreference
{
    return MHLayoutVertical;
}


- (void)setHighlighted:(bool)highlighted
{
    // FIXME: disabling this for now - improve
}


- (void)renderToPDFWithContextManager:(MHPDFRenderingContextManager *)contextManager
{
    CGContextRef pdfContext = contextManager.pdfContext;
                
    BOOL firstParagraphFlag = YES;

    MHParagraphEnumerator *paragraphEnumerator = [[MHParagraphEnumerator alloc]
                                                  initWithArrayOfParagraphsWithAttachedContent:(NSArray <MHParagraph *>*)_subexpressions];  // FIXME: casting

    MHParagraph *paragraph;
    CGPoint paragraphPosition = { 0.0, 0.0 };
    CGPoint previousParagraphPosition;
    MHDimensions paragraphDimensions = { 0.0, 0.0, 0.0 };
    MHDimensions previousParagraphDimensions;
    while ((paragraph = [paragraphEnumerator nextParagraph])) {
        previousParagraphPosition = paragraphPosition;
        paragraphPosition = paragraph.position;
        previousParagraphDimensions = paragraphDimensions;
        paragraphDimensions = paragraph.dimensions;
        CGFloat paragraphDepthPlusHeight = paragraphDimensions.depth + paragraphDimensions.height;
        
        if (firstParagraphFlag) {
            firstParagraphFlag = NO;
        }
        else {
            CGFloat filledSpaceIncrement = previousParagraphPosition.y - paragraphPosition.y - paragraphDepthPlusHeight;
            
            // increment the filled vertical space counter by the vertical distance between the typesetting origin of the previous paragraph and the top of the current paragraph
            [contextManager incrementFilledVerticalSpaceBy:filledSpaceIncrement];
            
            // move the rendering origin down by the same amount
            CGContextTranslateCTM(pdfContext, 0.0, -filledSpaceIncrement);
        }
        
        CGContextTranslateCTM(pdfContext, paragraphPosition.x, -paragraphDepthPlusHeight);  // move the rendering origin to the typesetting origin of the paragraph
        
        // render the paragraph
        [paragraph renderToPDFWithContextManager:contextManager];
        
        // move the rendering origin to the left to get it back to the edge of the page, but leaving it at the same vertical position
        CGContextTranslateCTM(pdfContext, -paragraphPosition.x, 0.0);
    }
}






@end

