//
//  MHMathParagraph.m
//  MadHat
//
//  Created by Dan Romik on 1/30/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "MHMathParagraph.h"
#import "MHWhitespace.h"
#import "NSBezierPath+QuartzUtilities.h"
#import "MHStyleIncludes.h"

@interface MHMathParagraph ()
{
    BOOL _isContinuation;
}

@end

@implementation MHMathParagraph

#pragma mark - Initialization

- (instancetype)init
{
    if (self = [super init]) {
        self.alignment = MHParagraphAlignmentCenter;
    }
    return self;
}


#pragma mark - typeset method

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    contextManager.paragraphType = MHParagraphNormal | MHParagraphIsMathParagraphBitMask;
    [super typesetWithContextManager:contextManager];     // this typesets the elements of the container in a linear fashion on a single line
    _isContinuation = contextManager.paragraphHasIndentSuppressed;
    MHExpressionPresentationMode presentationMode = self.presentationMode;
    
    MHParagraphAlignment myAlignment = self.alignment;
    
    SKNode *mySpriteKitNode = self.spriteKitNode;
    
    // Prepare some useful parameters related to the box type
    MHParagraphBoxType boxType = self.boxType;
    CGFloat indentFromLeft = 0.0;
    CGFloat indentFromRight = 0.0;
    if (boxType != MHParagraphBoxTypeNoBox) {
        indentFromLeft += kMHParagraphBoxLeftRightPadding;
        indentFromRight = kMHParagraphBoxLeftRightPadding;
    }

    // Set our initial dimensions
    MHDimensions myDimensions = self.dimensions;    // this contains the width we will use for typesetting
    myDimensions.depth = 0.0;               // a paragraph is all height, no depth
    
    CGFloat contentWidth = myDimensions.width - indentFromLeft - indentFromRight;

    NSArray *listOfSubexpressions = [self flattenedListOfUnsplittableComponents];     // the flat list of un-splittable objects to typeset

    CGFloat lineSpacing =  [contextManager absoluteLineSpacingForPresentationMode:presentationMode];
    CGFloat interSentenceLineSpacing = 10.0;                // FIXME: make this a configurable parameter
    CGFloat discretionaryLineBreakExtraRightShift = 50.0;   // FIXME: make this a configurable parameter
    CGFloat alternativeFirstLineBreakRightShift = 25.0;     // FIXME: make this a configurable parameter
    CGFloat thresholdForAlternativeFirstLineBreaking = 0.3; // FIXME: make this a configurable parameter
    bool usesAlternativeFirstLineBreak = false;

    NSMutableArray <NSMutableDictionary *> *mathSentences = [[NSMutableArray alloc] initWithCapacity:0];
    NSUInteger numberOfSentences = 0;
    NSMutableDictionary *mathSentenceDict;
    
    // First scan through the list: divide it into math sentences and record useful information for each sentence
    
    NSUInteger subexpIndex;
    NSUInteger numberOfSubexpressions = listOfSubexpressions.count;
    NSPoint subexpPosition;
    
    // Parameters to keep track of for each sentence
    NSRange mathSentenceRange;
    mathSentenceRange.location = 0;
    mathSentenceRange.length = 0;
    NSUInteger alignmentSubexpIndex = NSNotFound;
    CGFloat alignmentSubexpOffset = 0.0;
    CGFloat firstSentenceSubexpOffset = 0.0;

    CGFloat maxAlignmentSubexpOffsetForAllSentences = 0.0;
    CGFloat maxLineWidth = 0.0;

#pragma mark - First pass
    // First pass through the list: breaking up the paragraph into sentences
    MHExpression *subexpression;
    for (subexpIndex = 0; subexpIndex <= numberOfSubexpressions; subexpIndex++) {
        if (subexpIndex < numberOfSubexpressions) {
            subexpression = [listOfSubexpressions objectAtIndex:subexpIndex];
        }
        
        bool subexpIsNewline = false;
        
        // FIXME: here, a newline expression will have the effect of starting a new math sentence. An inter-sentence vertical spacing is inserted, currently using the variable interSentenceLineSpacing to tell us how much space to insert, but need to look at the spacing of the newline expression to allow for customized spacing.
        if (subexpIndex == numberOfSubexpressions ||
            (subexpIsNewline = ([subexpression isKindOfClass:[MHWhitespace class]]
                                && ((MHWhitespace *)subexpression).orientation == MHWhitespaceOrientationVertical))) {
            if (alignmentSubexpIndex == NSNotFound) {
                // use the first subexpression as the default alignment symbol if an alignment symbol was not found
                alignmentSubexpIndex = 0;
                alignmentSubexpOffset = 0.0;
            }

//            if (alignmentSubexpOffset > thresholdForAlternativeFirstLineBreaking * myDimensions.width) {
            if (alignmentSubexpOffset > thresholdForAlternativeFirstLineBreaking * contentWidth) {
                usesAlternativeFirstLineBreak = true;
            }
            
            mathSentenceDict = [@{
                @"sentenceRange" : [NSValue valueWithRange:mathSentenceRange],
                @"alignmentIndex" : [NSNumber numberWithShort:alignmentSubexpIndex],
                @"alignmentOffset" : [NSNumber numberWithDouble:alignmentSubexpOffset],
                @"firstSubexpOffset" : [NSNumber numberWithDouble:firstSentenceSubexpOffset],
            } mutableCopy];
            alignmentSubexpIndex = NSNotFound;
            [mathSentences addObject:mathSentenceDict];
            mathSentenceRange.location = subexpIndex + 1;
            mathSentenceRange.length = 0;
            numberOfSentences++;
            
            if (subexpIndex+1 < numberOfSubexpressions) {
                MHExpression *nextSubexp = listOfSubexpressions[subexpIndex+1];
                NSPoint nextSubexpPosition = [mySpriteKitNode convertPoint:nextSubexp.position fromNode:nextSubexp.spriteKitNode.parent];
                firstSentenceSubexpOffset = nextSubexpPosition.x;
            }
        }
        else {
            if (alignmentSubexpIndex == NSNotFound && subexpression.mathParagraphAlignmentRole == MHMathParagraphTabStop) {
                alignmentSubexpIndex = subexpIndex;

                subexpPosition = [mySpriteKitNode convertPoint:subexpression.position fromNode:subexpression.spriteKitNode.parent];

                alignmentSubexpOffset = subexpPosition.x - firstSentenceSubexpOffset;
                if (alignmentSubexpOffset > maxAlignmentSubexpOffsetForAllSentences)
                    maxAlignmentSubexpOffsetForAllSentences = alignmentSubexpOffset;
            }
            mathSentenceRange.length++;
        }
    }
        
    CGFloat cumulativeHeight = 0.0;
    CGFloat currentLineHeight = 0.0;
    CGFloat currentLineDepth = 0.0;
    CGFloat currentLineWidth = 0.0;

#pragma mark - Second pass
    // Second pass through the list: lay out each sentence in several lines in a greedy fashion, and record useful parameters for each line that will be used on the third pass
    NSUInteger sentenceIndex;
    NSUInteger lineIndex;
    for (sentenceIndex = 0; sentenceIndex < numberOfSentences; sentenceIndex++) {
        NSMutableArray <NSDictionary *> *sentenceLinesDicts = [[NSMutableArray alloc] initWithCapacity:0];
        
        mathSentenceDict = mathSentences[sentenceIndex];
        mathSentenceRange = [mathSentenceDict[@"sentenceRange"] rangeValue];
        alignmentSubexpIndex = [mathSentenceDict[@"alignmentIndex"] shortValue];
        alignmentSubexpOffset = [mathSentenceDict[@"alignmentOffset"] doubleValue];
        firstSentenceSubexpOffset = [mathSentenceDict[@"firstSubexpOffset"] doubleValue];
        CGFloat firstLineSubexpOffset = firstSentenceSubexpOffset;
        NSUInteger firstLineSubexpIndex = mathSentenceRange.location;
        
        // FIXME: these variables should be renamed
        NSUInteger indexOfLastAlignmentSymbol = NSNotFound;          // typically a binary relation
        NSUInteger indexOfLastFallbackOverflowSymbol = NSNotFound;   // typically a binary operator
        CGFloat lastAlignmentSymbolOffset = 0.0;
        CGFloat currentLineDepthBeforeLastAlignmentSymbol = 0.0;
        CGFloat currentLineHeightBeforeLastAlignmentSymbol = 0.0;
        CGFloat currentLineWidthBeforeLastAlignmentSymbol = 0.0;
        CGFloat currentLineHeightSinceLastAlignmentSymbol = 0.0;
        CGFloat currentLineDepthSinceLastAlignmentSymbol = 0.0;

        CGFloat lastFallbackOverflowSymbolOffset = 0.0;
        CGFloat currentLineDepthBeforeLastFallbackOverflowSymbol = 0.0;
        CGFloat currentLineHeightBeforeLastFallbackOverflowSymbol = 0.0;
        CGFloat currentLineWidthBeforeLastFallbackOverflowSymbol = 0.0;
        CGFloat currentLineHeightSinceLastFallbackOverflowSymbol = 0.0;
        CGFloat currentLineDepthSinceLastFallbackOverflowSymbol = 0.0;
        
        lineIndex = 0;
        
        for (subexpIndex = mathSentenceRange.location; subexpIndex < mathSentenceRange.location + mathSentenceRange.length; subexpIndex++) {
            subexpression = [listOfSubexpressions objectAtIndex:subexpIndex];

            MHDimensions subexpDimensions = subexpression.dimensions;

            subexpPosition = [mySpriteKitNode convertPoint:subexpression.position fromNode:subexpression.spriteKitNode.parent];

            // Look at the subexpression's alignment role and see if we need to record anything related to tab stops or discretionary line breaks
            MHMathParagraphAlignmentRole alignmentRole = subexpression.mathParagraphAlignmentRole;
            if (alignmentRole == MHMathParagraphTabStop && (lineIndex != 0 || subexpIndex > alignmentSubexpIndex
                                                            || usesAlternativeFirstLineBreak)) {
                indexOfLastAlignmentSymbol = subexpIndex;
                lastAlignmentSymbolOffset = subexpPosition.x;
                currentLineDepthBeforeLastAlignmentSymbol = currentLineDepth;
                currentLineHeightBeforeLastAlignmentSymbol = currentLineHeight;
                currentLineWidthBeforeLastAlignmentSymbol = currentLineWidth;
                currentLineDepthSinceLastAlignmentSymbol = subexpDimensions.depth;
                currentLineHeightSinceLastAlignmentSymbol = subexpDimensions.height;
            }
            else if (alignmentRole == MHMathParagraphDiscretionaryLineBreaking && (lineIndex != 0 || subexpIndex > alignmentSubexpIndex)) {
                indexOfLastFallbackOverflowSymbol = subexpIndex;
                lastFallbackOverflowSymbolOffset = subexpPosition.x;
                currentLineDepthBeforeLastFallbackOverflowSymbol = currentLineDepth;
                currentLineHeightBeforeLastFallbackOverflowSymbol = currentLineHeight;
                currentLineWidthBeforeLastFallbackOverflowSymbol = currentLineWidth;
                currentLineDepthSinceLastFallbackOverflowSymbol = subexpDimensions.depth;
                currentLineHeightSinceLastFallbackOverflowSymbol = subexpDimensions.height;
            }
            
            // Update the variables keeping track of width and height of the entire line and (if applicable) the segment of it since the tab stop and discretionary line breaking symbol
            if (subexpDimensions.height > currentLineHeight)
                currentLineHeight = subexpDimensions.height;
            if (subexpDimensions.depth > currentLineDepth)
                currentLineDepth = subexpDimensions.depth;
            
            if (indexOfLastAlignmentSymbol != NSNotFound) {
                if (subexpDimensions.height > currentLineHeightSinceLastAlignmentSymbol)
                    currentLineHeightSinceLastAlignmentSymbol = subexpDimensions.height;
                if (subexpDimensions.depth > currentLineDepthSinceLastAlignmentSymbol)
                    currentLineDepthSinceLastAlignmentSymbol = subexpDimensions.depth;
            }
            if (indexOfLastFallbackOverflowSymbol != NSNotFound) {
                if (subexpDimensions.height > currentLineHeightSinceLastFallbackOverflowSymbol)
                    currentLineHeightSinceLastFallbackOverflowSymbol = subexpDimensions.height;
                if (subexpDimensions.depth > currentLineDepthSinceLastFallbackOverflowSymbol)
                    currentLineDepthSinceLastFallbackOverflowSymbol = subexpDimensions.depth;
            }

            CGFloat adjustedSubexpPositionX = subexpPosition.x - firstLineSubexpOffset;
            if (usesAlternativeFirstLineBreak) {
                if (lineIndex > 0)
                    adjustedSubexpPositionX += alternativeFirstLineBreakRightShift;
            }
            else if (lineIndex == 0) {
                adjustedSubexpPositionX += maxAlignmentSubexpOffsetForAllSentences - alignmentSubexpOffset;
            }
            else {
                adjustedSubexpPositionX += maxAlignmentSubexpOffsetForAllSentences;
            }

            if (adjustedSubexpPositionX + subexpDimensions.width > contentWidth) {
                // Overflow to the next line, starting from either the last tab stop symbol, or last discretionary line break symbol, or, if neither of those two symbols are found, from the current subexpression
                
                lineIndex++;
                
                NSUInteger beginningOfNextLineIndex;
                CGFloat beginningOfNextLineOffset;
                CGFloat currentLineDepthBeforeOverflow;
                CGFloat currentLineHeightBeforeOverflow;
                CGFloat currentLineWidthBeforeOverflow;
                CGFloat currentLineHeightSinceOverflow;
                CGFloat currentLineDepthSinceOverflow;
                
                if (indexOfLastAlignmentSymbol != NSNotFound) {
                    beginningOfNextLineIndex = indexOfLastAlignmentSymbol;
                    beginningOfNextLineOffset = lastAlignmentSymbolOffset;
                    currentLineDepthBeforeOverflow = currentLineDepthBeforeLastAlignmentSymbol;
                    currentLineHeightBeforeOverflow = currentLineHeightBeforeLastAlignmentSymbol;
                    currentLineWidthBeforeOverflow = currentLineWidthBeforeLastAlignmentSymbol;
                    currentLineHeightSinceOverflow = currentLineHeightSinceLastAlignmentSymbol;
                    currentLineDepthSinceOverflow = currentLineDepthSinceLastAlignmentSymbol;
                }
                else if (indexOfLastFallbackOverflowSymbol != NSNotFound) {
                    beginningOfNextLineIndex = indexOfLastFallbackOverflowSymbol;
                    beginningOfNextLineOffset = lastFallbackOverflowSymbolOffset - discretionaryLineBreakExtraRightShift;
                    currentLineDepthBeforeOverflow = currentLineDepthBeforeLastFallbackOverflowSymbol;
                    currentLineHeightBeforeOverflow = currentLineHeightBeforeLastFallbackOverflowSymbol;
                    currentLineWidthBeforeOverflow = currentLineWidthBeforeLastFallbackOverflowSymbol;
                    currentLineHeightSinceOverflow = currentLineHeightSinceLastFallbackOverflowSymbol;
                    currentLineDepthSinceOverflow = currentLineDepthSinceLastFallbackOverflowSymbol;
                }
                else {
                    beginningOfNextLineIndex = subexpIndex;
                    beginningOfNextLineOffset = subexpPosition.x - discretionaryLineBreakExtraRightShift;
                    currentLineDepthBeforeOverflow = currentLineDepth;
                    currentLineHeightBeforeOverflow = currentLineHeight;
                    currentLineWidthBeforeOverflow = currentLineWidth;
                    currentLineHeightSinceOverflow = subexpDimensions.height;
                    currentLineDepthSinceOverflow = subexpDimensions.depth;
                }

                // keep track of where the line started
                CGFloat prevFirstLineSubexpOffset = firstLineSubexpOffset;
                firstLineSubexpOffset = beginningOfNextLineOffset;
                
                // Reposition all the subexpressions starting from the index where the next line begins and ending at the current index by moving them to the left and down
                NSUInteger overflowBlockIndex;
                for (overflowBlockIndex = beginningOfNextLineIndex; overflowBlockIndex < subexpIndex; overflowBlockIndex++) {
                    MHExpression *overflowSubexp = [listOfSubexpressions objectAtIndex:overflowBlockIndex];
                    NSPoint overflowSubexpPosition = [mySpriteKitNode convertPoint:overflowSubexp.position
                                                                          fromNode:overflowSubexp.spriteKitNode.parent];
                    overflowSubexpPosition.x += prevFirstLineSubexpOffset - firstLineSubexpOffset
                    + (lineIndex == 1 ? (usesAlternativeFirstLineBreak ? alternativeFirstLineBreakRightShift : alignmentSubexpOffset) : 0);
                    overflowSubexpPosition.y -= (currentLineHeightBeforeOverflow + currentLineDepthBeforeOverflow + lineSpacing);
                    overflowSubexp.position = [mySpriteKitNode convertPoint:overflowSubexpPosition
                                                                     toNode:overflowSubexp.spriteKitNode.parent];
                }
                adjustedSubexpPositionX += prevFirstLineSubexpOffset - firstLineSubexpOffset
                + (lineIndex == 1 ? (usesAlternativeFirstLineBreak ? alternativeFirstLineBreakRightShift : alignmentSubexpOffset) : 0);

                if (maxLineWidth < currentLineWidthBeforeOverflow)
                    maxLineWidth = currentLineWidthBeforeOverflow;

                // Keep track of the cumulative height of the paragraph
                cumulativeHeight += currentLineDepthBeforeOverflow + currentLineHeightBeforeOverflow + lineSpacing;
                
                NSDictionary *lineDict = @{
                    @"lineRange" : [NSValue valueWithRange:NSMakeRange(firstLineSubexpIndex, beginningOfNextLineIndex-firstLineSubexpIndex)],
                    @"lineHeight" : [NSNumber numberWithDouble:currentLineHeight],
//                    @"lineDepth" : [NSNumber numberWithDouble:currentLineDepth],
                };
                firstLineSubexpIndex = beginningOfNextLineIndex;

                currentLineDepth = currentLineDepthSinceOverflow;
                currentLineHeight = currentLineHeightSinceOverflow;
//                currentLineWidth = 0.0;

                [sentenceLinesDicts addObject:lineDict];
                
                indexOfLastAlignmentSymbol = NSNotFound;
                indexOfLastFallbackOverflowSymbol = NSNotFound;
            }
            currentLineWidth = adjustedSubexpPositionX + subexpDimensions.width;

            subexpPosition.x = adjustedSubexpPositionX + indentFromLeft;
            subexpPosition.y = -cumulativeHeight;
            subexpression.position = [mySpriteKitNode convertPoint:subexpPosition toNode:subexpression.spriteKitNode.parent];
        }
        
        // Record the current line that's still pending at the end of the sentence:
        NSDictionary *lineDict = @{
            @"lineRange" : [NSValue valueWithRange:NSMakeRange(firstLineSubexpIndex, subexpIndex-firstLineSubexpIndex)],
            @"lineHeight" : [NSNumber numberWithDouble:currentLineHeight],
//            @"lineDepth" : [NSNumber numberWithDouble:currentLineDepth],
        };
        
        
        
//        // FIXME: experimental code, should be removed at some point
//        if (presentationMode == MHExpressionPresentationModeEditing) {
//            CGFloat mathAxisHeight = [contextManager mathAxisHeightForNestingLevel:0];
//            SKShapeNode *decorationNode = [SKShapeNode shapeNodeWithRect:CGRectMake(0.0, cumulativeHeight+ currentLineDepth+mathAxisHeight-0.5, myDimensions.width, 1.0)];
//            decorationNode.fillColor = [NSColor grayColor];
//            decorationNode.zPosition = -100.0;
//            [_spriteKitNode addChild:decorationNode];
//        }
        
        

        if (maxLineWidth < currentLineWidth)
            maxLineWidth = currentLineWidth;

        [sentenceLinesDicts addObject:lineDict];
        mathSentenceDict[@"lineDicts"] = sentenceLinesDicts;

        cumulativeHeight += interSentenceLineSpacing + currentLineDepth + currentLineHeight;
    }
    cumulativeHeight -= interSentenceLineSpacing;   // We added this once too many
    
#pragma mark - Third pass
    // A final pass to shift all the subexpressions vertically, making adjustment for the total height of the paragraph and the dimensions of the current line
    for (sentenceIndex = 0; sentenceIndex < numberOfSentences; sentenceIndex++) {
        mathSentenceDict = mathSentences[sentenceIndex];
        mathSentenceRange = [mathSentenceDict[@"sentenceRange"] rangeValue];
        alignmentSubexpIndex = [mathSentenceDict[@"alignmentIndex"] shortValue];
        alignmentSubexpOffset = [mathSentenceDict[@"alignmentOffset"] doubleValue];
        firstSentenceSubexpOffset = [mathSentenceDict[@"firstSubexpOffset"] doubleValue];
        NSArray <NSDictionary *> *sentenceLinesDicts = mathSentenceDict[@"lineDicts"];
        for (NSDictionary *lineDict in sentenceLinesDicts) {
            NSRange lineRange = [lineDict[@"lineRange"] rangeValue];
//            CGFloat lineDepth = [lineDict[@"lineDepth"] doubleValue];
            CGFloat lineHeight = [lineDict[@"lineHeight"] doubleValue];
            for (subexpIndex = lineRange.location; subexpIndex < lineRange.location + lineRange.length; subexpIndex++) {
                subexpression = [listOfSubexpressions objectAtIndex:subexpIndex];
                subexpPosition = subexpression.position;
                subexpPosition.y += cumulativeHeight - lineHeight;// - lineDepth;
                if (myAlignment == MHParagraphAlignmentCenter) {
                    subexpPosition.x += (contentWidth - maxLineWidth) / 2.0;
                }
                subexpression.position = subexpPosition;
            }
        }
    }
    
    myDimensions.height = cumulativeHeight;
    self.dimensions = myDimensions;
    
    // background color
    // FIXME: code is identical to code in MHTextParagraph - violates DRY, refactor. Also related to verticalPadding hack in MHParagraph, invoked from MHVerticalLayoutContainer

    SKNode *oldBackgroundColorNode = [_spriteKitNode childNodeWithName:kMHParagraphFrameNodeName];
    [oldBackgroundColorNode removeFromParent];

    if (boxType != MHParagraphBoxTypeNoBox) {
        NSColor *backgroundColor = [contextManager paragraphBackgroundColor];
        NSColor *frameColor = [contextManager paragraphFrameColor];
        CGFloat frameThickness = [contextManager paragraphFrameThickness];

        if ((backgroundColor || frameColor)) {
            SKShapeNode *backgroundColorNode = [self newParagraphBackgroundNodeWithBoxType:boxType
                                                                                frameColor:frameColor
                                                                           backgroundColor:backgroundColor
                                                                            frameThickness:frameThickness];
            [_spriteKitNode addChild:backgroundColorNode];
        }
    }
    
    
    if (presentationMode == MHExpressionPresentationModeEditing) {
        
        NSBezierPath *path = [NSBezierPath bezierPath];

        [path moveToPoint:NSMakePoint(-4.0, -myDimensions.depth)];
        [path lineToPoint:NSMakePoint(12.0, -myDimensions.depth)];
        [path moveToPoint:NSMakePoint(0.0, -4.0-myDimensions.depth)];
        [path lineToPoint:NSMakePoint(0.0, 12.0-myDimensions.depth)];
        
        [path moveToPoint:NSMakePoint(myDimensions.width+4.0, -myDimensions.depth)];
        [path lineToPoint:NSMakePoint(myDimensions.width-12.0, -myDimensions.depth)];
        [path moveToPoint:NSMakePoint(myDimensions.width, -4.0-myDimensions.depth)];
        [path lineToPoint:NSMakePoint(myDimensions.width, 12.0-myDimensions.depth)];

        [path moveToPoint:NSMakePoint(-4.0, myDimensions.height)];
        [path lineToPoint:NSMakePoint(12.0, myDimensions.height)];
        [path moveToPoint:NSMakePoint(0.0, 4.0+myDimensions.height)];
        [path lineToPoint:NSMakePoint(0.0, -12.0+myDimensions.height)];
        
        [path moveToPoint:NSMakePoint(myDimensions.width+4.0, myDimensions.height)];
        [path lineToPoint:NSMakePoint(myDimensions.width-12.0, myDimensions.height)];
        [path moveToPoint:NSMakePoint(myDimensions.width, 4.0+myDimensions.height)];
        [path lineToPoint:NSMakePoint(myDimensions.width, -12.0+myDimensions.height)];
        
        SKShapeNode *decorationNode = [SKShapeNode shapeNodeWithPath:[path quartzPath]];

//        SKShapeNode *decorationNode = [SKShapeNode shapeNodeWithRect:CGRectMake(0.0, -myDimensions.depth, myDimensions.width, myDimensions.height+myDimensions.depth)];
        decorationNode.strokeColor = [NSColor redColor];
        decorationNode.name = @"decoration";
        [[_spriteKitNode childNodeWithName:@"decoration"] removeFromParent];
        [_spriteKitNode addChild:decorationNode];
    }

    [self doPostTypesettingHousekeeping];
}



- (MHParagraphType)type
{
    MHParagraphType myType = super.type;
    return (MHParagraphIsMathParagraphBitMask
            | (_isContinuation ? (myType|MHParagraphSuppressParagraphIndentBitMask) : (myType&MHParagraphDoNotSuppressParagraphIndentBitMask)));
}


- (NSString *) exportedLaTeXValue //RS - alignment is not implemented, newline doesn't export to latex
{
    return [NSString stringWithFormat: @"\\begin{align*}%@\\end{align*}",[super exportedLaTeXValue]];
}


@end



