//
//  MHTextParagraph.m
//  MadHat
//
//  Created by Dan Romik on 10/25/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "NSBezierPath+QuartzUtilities.h"
#import "MHTextParagraph.h"
#import "MHWhitespace.h"
#import "MHOldTextNode.h"
#import "MHTextAtom.h"
#import "MHStyleIncludes.h"
#import "MHCheckboxNode.h"
#import "MHStyledTextWrapper.h"
#import "MHLink.h"
#import <objc/runtime.h>


#define MHTextParagraphShouldSuppressIndentForReducedParagraphType(parType) (parType != MHParagraphNormal)
#define MHTextParagraphShouldSuppressIndentForReducedPrecedingParagraphType(parType) \
    (MHParagraphTypeIsMathParagraph(parType) || (parType == MHParagraphNone) || (parType == MHParagraphHeader) \
    || (parType == MHParagraphSubheader) || (parType == MHParagraphSubsubheader) || (parType == MHParagraphSuperheader) \
    || (parType != MHParagraphNormal))



static char kMHTextParagraphLineInfoAssociatedObjectKey;

NSString * const kMHParagraphCommandName = @"paragraph";

NSString * const kMHInteractiveEventOutlinerNodeToggledNotification = @"MHInteractiveEventOutlinerNodeToggledNotification";

static NSString * const kMHTextParagraphListMarkerNodeName = @"listmarker";
static NSString * const kMHTextParagraphCollapsibleSectionMarkerNodeName = @"collapsiblesectionmarker";

@interface MHTextParagraph () {
    // FIXME: it's probably possible to combine the _listItemType and _type variables into one variable using a bitwise encoding scheme. Will save a bit of memory and method calls but the coding will be slightly less simple/elegant
    MHListItemType _listItemType;
    MHParagraphType _type;

    CGFloat _uncollapsedHeight;
    CGFloat _collapsedHeight;
    MHExpression <MHOutlinerItemMarker> *_outlinerItemStartMarker;
    bool _addCollapsibleSectionMarkerAtEnd;
    
    NSMutableArray *lineInfoDicts;
}
@end

@implementation MHTextParagraph


#pragma mark - Properties

- (void)setNestingLevel:(NSUInteger)nestingLevel
{
    // In a text paragraph, a nesting level of 0 (TeX's mode "D") gets mapped to 2 (TeX's "T") and a nesting level of 1 (TeX's mode "D'" gets mapped to 3 (TeX's "T'")
    super.nestingLevel = (nestingLevel <= 1 ? nestingLevel + 2 : nestingLevel);
}

- (MHParagraphType)type
{
    return _type;
}



#pragma mark - typeset method

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    
    // Check the attributes dictionary
    NSString *alignmentAttribute = [self.attributes[kMHParagraphAlignmentAttributeName] stringValue];
    if (alignmentAttribute) {
        if ([alignmentAttribute isEqualToString:kMHParagraphAlignmentAttributeCenter]) {
            self.alignment = MHParagraphAlignmentCenter;
        }
        else if ([alignmentAttribute isEqualToString:kMHParagraphAlignmentAttributeRaggedRight]) {
            self.alignment = MHParagraphAlignmentRaggedRight;
        }
        else if ([alignmentAttribute isEqualToString:kMHParagraphAlignmentAttributeRaggedLeft]) {
            self.alignment = MHParagraphAlignmentRaggedLeft;
        }
    }
    
    MHParagraphType paragraphTypeBeforeTypesetting = contextManager.paragraphType;
    contextManager.paragraphType = MHParagraphNormal;
    
    [super typesetWithContextManager:contextManager];     // this typesets the elements of the container in a linear fashion on a single line
    
    _outlinerItemStartMarker = [contextManager readAndResetOutlinerItemStartMarker];
    MHExpression *collapsibleSectionStartMarker = [contextManager readAndResetCollapsibleSectionStartMarker];
    
    MHParagraphBoxType boxType = self.boxType;
    
    _addCollapsibleSectionMarkerAtEnd = false;

    MHExpressionPresentationMode presentationMode = self.presentationMode;

    // Prepare some useful parameters related to the logical indentation level and box type
    static const CGFloat bulletLeftShift = 16.0;             // FIXME: make this configurable
    NSUInteger logicalIndentLevel = contextManager.logicalIndentLevel;
    CGFloat indentFromLeft = kMHParagraphLogicalIndentationMultiplier * logicalIndentLevel;
    CGFloat indentFromRight = 0.0;
    if (boxType != MHParagraphBoxTypeNoBox) {
        indentFromLeft += kMHParagraphBoxLeftRightPadding;
        indentFromRight = kMHParagraphBoxLeftRightPadding;
    }

    _listItemType = [contextManager readAndResetListItemType];
    
    MHParagraphType paragraphTypeAfterTypesetting = contextManager.paragraphType;

    // Set our initial dimensions
    MHDimensions myDimensions = self.dimensions;    // this contains the width we will use for typesetting
    myDimensions.depth = 0.0;               // a paragraph is all height, no depth
    CGFloat contentWidth = myDimensions.width - indentFromLeft - indentFromRight;
    
    
    NSArray *listOfSubexpressions = [self flattenedListOfUnsplittableComponents];     // the flat list of un-splittable objects to typeset
    
    MHParagraphType reducedParTypeBeforeTypesetting = MHParagraphTypeIgnoringBitMask(paragraphTypeBeforeTypesetting);
    MHParagraphType reducedParTypeAfterTypesetting = MHParagraphTypeIgnoringBitMask(paragraphTypeAfterTypesetting);
    
    // should we suppress the beginning-of-paragraph indentation?
    BOOL suppressIndentation = MHParagraphTypeIndentShouldBeSuppressed(paragraphTypeAfterTypesetting)
        || MHTextParagraphShouldSuppressIndentForReducedParagraphType(reducedParTypeAfterTypesetting)
        || MHParagraphTypeIsMathParagraph(paragraphTypeBeforeTypesetting)
        || MHTextParagraphShouldSuppressIndentForReducedPrecedingParagraphType(reducedParTypeBeforeTypesetting);
    BOOL forceIndentation = MHParagraphTypeNewParagraphShouldBeForced(paragraphTypeAfterTypesetting);

    // if the indentation should be suppressed and the paragraph does not contain a command to force adding an indentation, the paragraph indent will be 0, otherwise set it to the correct value
    CGFloat paragraphIndent = (suppressIndentation&&(!forceIndentation)) ? 0.0 : contextManager.paragraphIndent * contextManager.baseFontSize;
    
    float lineSpacing = [contextManager absoluteLineSpacingForPresentationMode:presentationMode];
    float actualLineSpacing = 0.0;

    // As we scan the list we will keep track of the dimensions of the line currently being typeset
    float currentLineWidth = paragraphIndent;
    float currentLineDepth = 0.0;
    float currentLineHeight = 0.0;

    float accumulatedParagraphHeight = 0.0;     // this will get updated each time we overflow to the next line

    // As we scan the list we will keep track of the position (left and right endpoints) of the current expression and the endpoint of the previous one
    float xCoordinateAtExpressionBeginning = 0.0;
    float xCoordinateAtExpressionEnd = 0.0;
    float xCoordinateAtExpressionEndPreviousValue = 0.0;
    float xCoordinateAtLineEnd = 0.0;
    
    // We'll also keep track of where the current line started
    float xCoordinateAtLineBeginning = -paragraphIndent;

    // Information about each line will be recorded in the variable lineInfo and added to a mutable array for use during the second pass
    NSDictionary *lineInfo;
//    NSMutableArray *lineInfoDicts = [NSMutableArray arrayWithCapacity:0];
    lineInfoDicts = [NSMutableArray arrayWithCapacity:0];

    CGPoint subexpPosition;
    
    SKNode *mySpriteKitNode = self.spriteKitNode;
    
    
    
#pragma mark - First pass
    // First pass through the list, to determine where lines wrap, record the necessary information, and compute the total paragraph height
    unsigned int subexpIndex = 0;
    signed int collapsibleSectionMarkerIndex = -1;
    for (MHExpression *subexpression in listOfSubexpressions) {

        // save the value of xCoordinateAtExpressionEnd from the previous iteration
        xCoordinateAtExpressionEndPreviousValue = xCoordinateAtExpressionEnd;

        // get dimensions of the subexpression
        MHDimensions subexpDimensions = subexpression.dimensions;
        
        // get position of the subexpression in the current container's coordinate system
        subexpPosition = [mySpriteKitNode convertPoint:subexpression.position fromNode:subexpression.spriteKitNode.parent];

        // compute new values for xCoordinateAtExpressionBeginning and xCoordinateAtExpressionEnd
        xCoordinateAtExpressionBeginning = subexpPosition.x;
        xCoordinateAtExpressionEnd = subexpPosition.x + subexpDimensions.width;

        // compute new value for currentLineWidth
        currentLineWidth += xCoordinateAtExpressionEnd - xCoordinateAtExpressionEndPreviousValue;
        
        bool isWhitespace = [subexpression isKindOfClass:[MHWhitespace class]];
        MHSpaceOrientationType whitespaceOrientation = 0;   // meaningless initial value to eliminate a compiler warning
        if (isWhitespace)
            whitespaceOrientation = ((MHWhitespace *)subexpression).orientation;
        bool isLineBreak = (isWhitespace && (whitespaceOrientation == MHWhitespaceOrientationVertical));
        
        bool isCollapsibleSectionMarker = false;
        
        if ([collapsibleSectionStartMarker isEqualTo:subexpression]) {
            isCollapsibleSectionMarker = true;
            collapsibleSectionMarkerIndex = subexpIndex;
        }
        
        // Now check if the content should overflow to the next line
        if (currentLineWidth <= contentWidth && !isLineBreak) {
            // No overflow, so just update the current line depth and height
            if (currentLineDepth < subexpDimensions.depth)
                currentLineDepth = subexpDimensions.depth;
            if (currentLineHeight < subexpDimensions.height)
                currentLineHeight = subexpDimensions.height;
            
            if (isCollapsibleSectionMarker) {
                _collapsedHeight = accumulatedParagraphHeight + currentLineDepth + currentLineHeight + lineSpacing;
            }
        }
        else {
            // Overflow to the next line
            actualLineSpacing = (isLineBreak ?
                [(MHWhitespace *)subexpression dimensionsWithContextManager:contextManager].height : lineSpacing);
            
            // Is the expression causing the overflow a space?
            bool isSpace = (isWhitespace && (whitespaceOrientation == MHWhitespaceOrientationHorizontal));
                        
            // save the relevant parameters calculated for the current line, for use in the second pass
            lineInfo = @{
                @"last_subexp_index":[NSNumber numberWithUnsignedInt:subexpIndex-1],  // index of last subexpression in line
                @"line_depth":[NSNumber numberWithFloat:currentLineDepth],
                @"line_height":[NSNumber numberWithFloat:currentLineHeight],
                @"line_x_beginning":[NSNumber numberWithFloat:xCoordinateAtLineBeginning],
                @"line_x_end":[NSNumber numberWithFloat:xCoordinateAtExpressionEndPreviousValue],
                @"line_spacing":[NSNumber numberWithFloat:actualLineSpacing]
            };
            [lineInfoDicts addObject:lineInfo];
            
            // update accumulatedParagraphHeight
            accumulatedParagraphHeight += currentLineDepth + currentLineHeight + actualLineSpacing;
            
            if (isCollapsibleSectionMarker) {
                _collapsedHeight = accumulatedParagraphHeight;
            }

            // Reset currentLineWidth to the appropriate value
            currentLineWidth = (isSpace ? 0.0 : subexpDimensions.width); // if the previous line ended with a space, ignore it and set the current line width to 0
            
            // Reset the current line depth and height to the depth and height of the current subexpression
            currentLineDepth = subexpDimensions.depth;
            currentLineHeight = subexpDimensions.height;
            
            // Reset xCoordinateAtLineBeginning to its correct value for the next line
            xCoordinateAtLineBeginning = (isSpace ? xCoordinateAtExpressionEnd : xCoordinateAtExpressionBeginning);
        }
        
        // Update the counting index
        subexpIndex++;
    }

    // When we exit the loop we still need to record the information for the very last (only partialy filled) line, so do that
    lineInfo = @{
        @"last_subexp_index":[NSNumber numberWithUnsignedInt:subexpIndex],
        @"line_depth":[NSNumber numberWithFloat:currentLineDepth],
        @"line_height":[NSNumber numberWithFloat:currentLineHeight],
        @"line_x_beginning":[NSNumber numberWithFloat:xCoordinateAtLineBeginning],
        @"line_x_end":[NSNumber numberWithFloat:xCoordinateAtExpressionEnd],
        @"line_spacing":[NSNumber numberWithFloat:lineSpacing]
    };
    [lineInfoDicts addObject:lineInfo];
    
    // we can now set the total paragraph height to its correct value
    _uncollapsedHeight = accumulatedParagraphHeight + currentLineDepth + currentLineHeight;
    
//    if (myDimensions.height < 0.0)
//        myDimensions.height = 0.0;  // FIXME: this resolves an issue that caused crashing but does not address the underlying issue that caused this variable to be set to a negative value - fix this at some point
    if (_uncollapsedHeight < 0.0) {
        NSLog(@"FIXME: negative paragraph height %f", _uncollapsedHeight);
        _uncollapsedHeight = 0.0;  // FIXME: this resolves an issue that caused crashing but does not address the underlying issue that caused this variable to be set to a negative value - fix this at some point
    }
    
    myDimensions.height = _uncollapsedHeight;

    float accumulatedParagraphDepth = 0.0;
    
    unsigned int indexOfLastSubexpressionInLine = 0;    // giving an initial value just to avoid an unhelpful compiler warning
    
    // add comment
    [mySpriteKitNode removeChildrenInArray:[mySpriteKitNode objectForKeyedSubscript:@"linenode"]];
    
    
    
#pragma mark - Second pass
    // Second pass through the list. This is when subexpressions actually get moved to their correct positions
    subexpIndex = 0;
    NSUInteger numberOfSubexpressions = listOfSubexpressions.count;
    
    bool recordedFirstLineBaseY = false;
    CGFloat firstLineBaseY = myDimensions.height - 18.0;    // a fallback value that will be used if for some strange reason we do not record the y position of the first line
    actualLineSpacing = 0.0;
    for (MHExpression *subexpression in listOfSubexpressions) {

        if (subexpIndex == 0 || subexpIndex > indexOfLastSubexpressionInLine) {     // Need to get information for the next line
            lineInfo = [lineInfoDicts firstObject];
            indexOfLastSubexpressionInLine = [lineInfo[@"last_subexp_index"] unsignedIntValue];
            currentLineDepth = [lineInfo[@"line_depth"] floatValue];
            currentLineHeight = [lineInfo[@"line_height"] floatValue];
            xCoordinateAtLineBeginning = [lineInfo[@"line_x_beginning"] floatValue];
            xCoordinateAtLineEnd = [lineInfo[@"line_x_end"] floatValue];
            [lineInfoDicts removeObjectAtIndex:0];
            accumulatedParagraphDepth += currentLineDepth + currentLineHeight + (subexpIndex != 0 ? actualLineSpacing : 0.0);
            actualLineSpacing = [lineInfo[@"line_spacing"] floatValue];
            
            objc_setAssociatedObject(subexpression, &kMHTextParagraphLineInfoAssociatedObjectKey, lineInfo, OBJC_ASSOCIATION_RETAIN);

            if (presentationMode == MHExpressionPresentationModeEditing) {
                SKShapeNode *baselineNode = [SKShapeNode shapeNodeWithRect:
                                             CGRectMake(0.0, myDimensions.height+currentLineDepth-accumulatedParagraphDepth, myDimensions.width, 2.0)];
                baselineNode.name = @"linenode";
                baselineNode.fillColor = [NSColor colorWithWhite:0.75 alpha:1.0];
                baselineNode.zPosition = -1.0;
                [mySpriteKitNode addChild:baselineNode];

                
                SKShapeNode *lineBottomNode = [SKShapeNode shapeNodeWithRect:
                                               CGRectMake(0.0, myDimensions.height-accumulatedParagraphDepth, myDimensions.width, 2.0)];
                lineBottomNode.name = @"linenode";
                lineBottomNode.fillColor = [NSColor colorWithWhite:0.55 alpha:1.0];
                lineBottomNode.zPosition = -1.0;
                [mySpriteKitNode addChild:lineBottomNode];

                SKShapeNode *lineTopNode = [SKShapeNode shapeNodeWithRect:
                                            CGRectMake(0.0, myDimensions.height-accumulatedParagraphDepth+currentLineDepth+currentLineHeight,
                                                       myDimensions.width, 2.0)];
                lineTopNode.name = @"linenode";
                lineTopNode.fillColor = [NSColor colorWithWhite:0.55 alpha:1.0];
                lineTopNode.zPosition = -1.0;
                [mySpriteKitNode addChild:lineTopNode];

            }
        }
        
        // get position of the subexpression in the current container's coordinate system
        subexpPosition = [mySpriteKitNode convertPoint:subexpression.position fromNode:subexpression.spriteKitNode.parent];

        // adjust the x coordinate to shift the expression left to its correct position on the current line, and offset by the rightIndent
        subexpPosition.x = subexpPosition.x - xCoordinateAtLineBeginning + indentFromLeft;
        
        // set the y coordinate
        subexpPosition.y = myDimensions.height - accumulatedParagraphDepth + currentLineDepth;
        
        if (!recordedFirstLineBaseY) {
            firstLineBaseY = subexpPosition.y;
            recordedFirstLineBaseY = true;
        }

        MHParagraphAlignment alignment = self.alignment;
        if (alignment == MHParagraphAlignmentCenter) {
            subexpPosition.x += (myDimensions.width - (xCoordinateAtLineEnd-xCoordinateAtLineBeginning))/2.0;
        }
        else if (alignment == MHParagraphAlignmentRaggedRight) {
            subexpPosition.x += myDimensions.width - (xCoordinateAtLineEnd-xCoordinateAtLineBeginning);
        }

        // convert the position coordinates back to the parent's coordinate system and set the position
        CGPoint convertedSubexpPosition = [mySpriteKitNode convertPoint:subexpPosition toNode:subexpression.spriteKitNode.parent];
        subexpression.position = convertedSubexpPosition;
        
        if (subexpIndex == collapsibleSectionMarkerIndex
            || (_outlinerItemStartMarker && subexpIndex+1 == numberOfSubexpressions && collapsibleSectionMarkerIndex == -1)) {
            // FIXME: quick and dirty code to add a marker for the collapsible section. Improve
            NSRect rect;
            rect.size = NSMakeSize(32.0, 18.0);
            rect.origin = subexpPosition;
            if (collapsibleSectionMarkerIndex == -1) {
                // This is the scenario where the marker is added automatically at the end of the paragraph
                rect.origin.x += subexpression.dimensions.width;
            }
            rect.origin.x += 12.0;
            rect.origin.y -= 1.0;

            SKLabelNode *textNode = [SKLabelNode labelNodeWithText:@"•••"];
            textNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
            textNode.fontName = @"Courier";
            textNode.fontSize = 12.0;
            textNode.fontColor = [NSColor blackColor];
            textNode.position = NSMakePoint(5.0 + rect.origin.x, 4.0 + rect.origin.y); // FIXME: I don't understand why the translation is what produces the right behavior, but it seems to work

            SKShapeNode *markerNode = [SKShapeNode shapeNodeWithRect:rect cornerRadius:6.0];
            markerNode.name = kMHTextParagraphCollapsibleSectionMarkerNodeName;
            markerNode.fillColor = [NSColor colorWithRed:0.84 green:0.84 blue:0.84 alpha:1.0];
//            markerNode.strokeColor = [NSColor blackColor];
            [markerNode addChild:textNode];
            markerNode.hidden = true;
            markerNode.ownerExpressionAcceptsMouseClicks = true;
            [[mySpriteKitNode childNodeWithName:kMHTextParagraphCollapsibleSectionMarkerNodeName] removeFromParent];
            [mySpriteKitNode addChild:markerNode];
        }
        
        subexpIndex++;
    }

    // FIXME: temporary code, improve all the messy node names and the logic involving them
    [[mySpriteKitNode childNodeWithName:kMHTextParagraphListMarkerNodeName] removeFromParent];

    // Add the list item marker, if applicable
    if (_listItemType != MHListItemNone) {
        
        MHExpression *listItemMarker = [contextManager listItemMarkerExpressionForType:_listItemType];
        [listItemMarker typesetWithContextManager:contextManager];
        
        SKNode *bulletNode = listItemMarker.spriteKitNode;
        
        // FIXME: this is to address a flaw in my system for adding marker items where the MHTextParagraph instance takes the spritekitnode of the returned marker item expression and adds it as a child to its spritekit node. If I don't set the owner expression property to nil then mouse clicks don't register. Find a way to make this unnecessary
        bulletNode.ownerExpression = nil;
        
        bulletNode.position = NSMakePoint(indentFromLeft - bulletLeftShift - listItemMarker.dimensions.width, firstLineBaseY);

        bulletNode.name = kMHTextParagraphListMarkerNodeName;
        bulletNode.ownerExpressionAcceptsMouseClicks = true;

        [mySpriteKitNode addChild:bulletNode];
    }
    
    if (_outlinerItemStartMarker && collapsibleSectionMarkerIndex == -1) {
        // The paragraph is associated with an outliner item but doesn't have a collapsible section marker. In that case we will automatically add such a marker at the end of the paragraph during reformatting
        _addCollapsibleSectionMarkerAtEnd = true;
        
        _collapsedHeight = _uncollapsedHeight;  // FIXME: this is already done above in a separate if clause - probably those if clauses can be combined
    }
    
    if (myDimensions.depth == 0.0 && myDimensions.height == 0.0
        && paragraphTypeAfterTypesetting != MHParagraphBeginBox
        && paragraphTypeAfterTypesetting != MHParagraphBoxDivider
        && paragraphTypeAfterTypesetting != MHParagraphEndBox) {
        contextManager.paragraphType = paragraphTypeBeforeTypesetting;
        _type = MHParagraphNone;    // this paragraph won't participate in paragraph kerning
    }
    else {
        _type = paragraphTypeAfterTypesetting;
    }

    self.dimensions = myDimensions;
    
    
    // background color
    // FIXME: code is identical to code in MHMathParagraph - violates DRY, refactor. Also related to verticalPadding hack in MHParagraph, invoked from MHVerticalLayoutContainer

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
        decorationNode.strokeColor = [NSColor colorWithRed:0.75 green:0.2 blue:0.2 alpha:1.0];
        decorationNode.name = @"decoration";
        [[_spriteKitNode childNodeWithName:@"decoration"] removeFromParent];
        [_spriteKitNode addChild:decorationNode];
    }
    
    [self doPostTypesettingHousekeeping];
}


#pragma mark - MHCommand protocol

+ (MHExpression *)commandNamed:(NSString *)name withParameters:(NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument
{
    if ([name isEqualToString:kMHParagraphCommandName]) {
        MHParagraph *paragraph = [[self class] expression];
        
        NSUInteger numBlocks = argument.numberOfDelimitedBlocks;
        if (numBlocks <= 1) {
            [paragraph addSubexpression:argument];
        }
        else {
            NSMutableArray *attachedParagraphs = [[NSMutableArray alloc] initWithCapacity:numBlocks];
            for (NSUInteger index = 0; index < numBlocks; index++) {
                MHExpression *block = [argument expressionFromDelimitedBlockAtIndex:index];
                MHTextParagraph *textParagraph = [MHTextParagraph expression];
                [textParagraph addSubexpression:block];
                [attachedParagraphs addObject:textParagraph];
            }
            paragraph.attachedContent = attachedParagraphs;
        }
        return paragraph;
    }

    return nil;
}

+ (NSArray <NSString *> *)recognizedCommands
{
    return @[ kMHParagraphCommandName ];
}





#pragma mark - Interactivity

- (bool)containsOutlinerItem
{
    return (_outlinerItemStartMarker != nil);
}

- (bool)outlinerItemIsCollapsed
{
    return (_outlinerItemStartMarker ? _outlinerItemStartMarker.isCollapsed : false);
}

- (void)setOutlinerItemIsCollapsed:(bool)state
{
    if (_outlinerItemStartMarker) {
        _outlinerItemStartMarker.isCollapsed = state;
        
        if (state) {
            SKNode *markerNode = [self.spriteKitNode childNodeWithName:kMHTextParagraphCollapsibleSectionMarkerNodeName];
            markerNode.hidden = false;
        }
        else {
            SKNode *markerNode = [self.spriteKitNode childNodeWithName:kMHTextParagraphCollapsibleSectionMarkerNodeName];
            markerNode.hidden = true;
        }
    }
}

- (void)mouseClickWithEvent:(NSEvent *)event subnode:(SKNode *)node
{
    if (_listItemType == MHListItemCheckbox) {
        SKNode *checkboxNode = [self.spriteKitNode childNodeWithName:kMHTextParagraphListMarkerNodeName];
        if ([checkboxNode isKindOfClass:[MHCheckboxNode class]]) {
            [(MHCheckboxNode *)checkboxNode toggle];
        }
        return;
    }

    if (self.containsOutlinerItem) {
        self.outlinerItemIsCollapsed = !(_outlinerItemStartMarker.isCollapsed);
        NSNotification *notification = [NSNotification notificationWithName:kMHInteractiveEventOutlinerNodeToggledNotification object:self];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
    }
}

- (NSString *)mouseHoveringAuxiliaryTextWithHoveringNode:(SKNode *)node
{
    return _listItemType == MHListItemCheckbox ? NSLocalizedString(@"Toggle checkbox", @"") : [_outlinerItemStartMarker mouseHoveringAuxiliaryTextWithHoveringNode:node];
    
    // Moved the code below to MHListCommand. Also added code in MHStyledTextWrapper, to provide different hovering text depending on the type of node (section header/outliner item)
//    if (_listItemType == MHListItemCheckbox)
//        return NSLocalizedString(@"Toggle checkbox", @"");
//    bool isCollapsed = _outlinerItemStartMarker.isCollapsed;
//    return isCollapsed ? NSLocalizedString(@"Expand outliner item", @"") :
//                            NSLocalizedString(@"Collapse outliner item", @"");
}



- (void)reformatWithContextManager:(MHReformattingContextManager *)contextManager animationType:(MHReformattingAnimationType)animationType
{
    MHOutlinerVisibilityState previousVisibilityState = [contextManager currentOutlinerVisibilityState];
    [super reformatWithContextManager:contextManager animationType:animationType];
    MHOutlinerVisibilityState visibilityState = [contextManager currentOutlinerVisibilityState];
    SKNode *mySpriteKitNode = self.spriteKitNode;

    if (_addCollapsibleSectionMarkerAtEnd) {
        [contextManager markBeginningOfMainPartOfCurrentNode];

        
        // the snippet below is designed to make the bullet and collapse section markers hide or show correctly according to the slide transition state
        // FIXME: this isn't well-designed and whether it works depends on where the \pause command is inserted. Also the code is a copy-paste of the code below in the else {...} clause. Improve
        NSUInteger slideCounter = contextManager.slideCounter;
        NSUInteger currentSlideTransitionIndex = contextManager.currentSlideTransitionIndex;
        bool hideBulletNode = slideCounter > currentSlideTransitionIndex;
        SKNode *bulletNode = [mySpriteKitNode childNodeWithName:kMHTextParagraphListMarkerNodeName];
        SKNode *markerNode = [mySpriteKitNode childNodeWithName:kMHTextParagraphCollapsibleSectionMarkerNodeName];
        if (animationType != MHReformattingAnimationTypeNone) {
            // We do a fade in/out animation for both a slide transition and an outliner action
            SKAction *bulletNodeAction = [SKAction fadeAlphaTo:(hideBulletNode ? 0.0 : 1.0) duration:kMHDefaultOutlinerFadeAnimationDuration];
            [bulletNode runAction:bulletNodeAction];

            SKAction *markerNodeAction = [SKAction fadeAlphaTo:(hideBulletNode ? 0.0 : 1.0) duration:kMHDefaultOutlinerFadeAnimationDuration];
            [markerNode runAction:markerNodeAction];
        }
        else {
            CGFloat newAlpha = (hideBulletNode ? 0.0 : 1.0);
            bulletNode.alpha = newAlpha;
            markerNode.alpha = newAlpha;
        }

        
        
        // The part below is needed since in the scenario where the if condition is satisfied, the paragraph was not hidden during the call to the super method

        bool hideEntireParagraph = visibilityState & MHOutlinerVisibilityStateHiddenDueToAncestorNodeCollapsedPart;
        
        if (animationType == MHReformattingAnimationTypeOutliner) {
            SKAction *action = [SKAction fadeAlphaTo:(hideEntireParagraph ? 0.0 : 1.0) duration:kMHDefaultOutlinerFadeAnimationDuration];
            [mySpriteKitNode runAction:action];
        }
        else {
            mySpriteKitNode.alpha = (hideEntireParagraph ? 0.0 : 1.0);
        }
    }
    else {      // added this code to fix a bug that caused bullet and marker nodes in a collapsed section to sometimes not be hidden when they should be
        bool hideBulletNode = (previousVisibilityState != MHOutlinerVisibilityStateVisible);
        SKNode *bulletNode = [mySpriteKitNode childNodeWithName:kMHTextParagraphListMarkerNodeName];
        SKNode *markerNode = [mySpriteKitNode childNodeWithName:kMHTextParagraphCollapsibleSectionMarkerNodeName];

        if (animationType != MHReformattingAnimationTypeNone) {
            // We do a fade in/out animation for both a slide transition and an outliner action
            SKAction *bulletNodeAction = [SKAction fadeAlphaTo:(hideBulletNode ? 0.0 : 1.0) duration:kMHDefaultOutlinerFadeAnimationDuration];
            [bulletNode runAction:bulletNodeAction];

            SKAction *markerNodeAction = [SKAction fadeAlphaTo:(hideBulletNode ? 0.0 : 1.0) duration:kMHDefaultOutlinerFadeAnimationDuration];
            [markerNode runAction:markerNodeAction];
        }
        else {
            CGFloat newAlpha = (hideBulletNode ? 0.0 : 1.0);
            bulletNode.alpha = newAlpha;
            markerNode.alpha = newAlpha;
        }
    }
}


- (CGFloat)verticalOffsetOfFollowingContentWhenCollapsedAtCurrentHierarchyLevel
{
    if (_outlinerItemStartMarker != nil && !_addCollapsibleSectionMarkerAtEnd) {
        return _uncollapsedHeight - _collapsedHeight;
    }
    return [super verticalOffsetOfFollowingContentWhenCollapsedAtCurrentHierarchyLevel];
}


- (bool)hasVisibleContentWhenCollapsed
{
    return (_outlinerItemStartMarker != nil);
}



#pragma mark - Rendering to a PDF context

- (void)renderToPDFWithContextManager:(MHPDFRenderingContextManager *)contextManager
{
    BOOL allowMidParagraphPagination = (self.boxType == MHParagraphBoxTypeNoBox); // FIXME: can this be improved?
    
    if (allowMidParagraphPagination) {
        // new code
        
        CGContextRef pdfContext = contextManager.pdfContext;
        NSSize pageSize = contextManager.pageSize;
        CGFloat topMargin = contextManager.topMargin;
        CGFloat bottomMargin = contextManager.bottomMargin;
        CGFloat contentHeight = pageSize.height - topMargin - bottomMargin;

        BOOL firstLineFlag = YES;
        BOOL previousFirstLineFlag = NO;
        CGFloat thisLineBottomYOffset = 0.0;
        CGFloat previousLineBottomYOffset = 0.0;

        NSArray <MHExpression *> *listOfSubexpressions = [self flattenedListOfUnsplittableComponents];
        SKNode *mySpriteKitNode = self.spriteKitNode;
        
        for (MHExpression *subexpression in listOfSubexpressions) {
            // see if the subexpression has an associated object, marking it as the first subexpression in its line
            NSDictionary *lineInfo = objc_getAssociatedObject(subexpression, &kMHTextParagraphLineInfoAssociatedObjectKey);
            if (lineInfo) {
                // the subexpression is the first one in its line, so check whether we need to add a page break before rendering
                CGFloat lineDepth = [(NSNumber *)(lineInfo[@"line_depth"]) floatValue];
                CGFloat lineHeight = [(NSNumber *)(lineInfo[@"line_height"]) floatValue];
                CGFloat lineDepthPlusHeight = lineDepth + lineHeight;
                
                CGPoint point = [mySpriteKitNode convertPoint:CGPointZero fromNode:subexpression.spriteKitNode];
                previousLineBottomYOffset = thisLineBottomYOffset;
                thisLineBottomYOffset = point.y - lineDepth;

                if (firstLineFlag) {
                    previousFirstLineFlag = YES;
                    firstLineFlag = NO;
                }
                else {
                    previousFirstLineFlag = NO;
                    CGFloat filledSpaceIncrement = previousLineBottomYOffset - thisLineBottomYOffset - lineDepthPlusHeight; // the vertical distance from the bottom of the previous line to the top of the current one
                    [contextManager incrementFilledVerticalSpaceBy:filledSpaceIncrement];
                }

                if (contextManager.filledVerticalSpaceOnCurrentPage + lineDepthPlusHeight > contentHeight) {
                    // Close the current page
                    [contextManager endPDFPage];

                    // Start a new page and move the rendering origin to coincide with where our typesetting origin should appear on the page
                    [contextManager beginPDFPage];
                    CGFloat thisLineTopYOffset = thisLineBottomYOffset + lineDepthPlusHeight;
                    CGContextTranslateCTM(pdfContext, self.position.x, -thisLineTopYOffset);
                }
                [contextManager incrementFilledVerticalSpaceBy:lineDepthPlusHeight];
                
                // dealing with lists
                if (previousFirstLineFlag && _listItemType != MHListItemNone) { // this should only run once, while rendering the first line
                    SKNode *listMarkerNode = [self.spriteKitNode childNodeWithName:kMHTextParagraphListMarkerNodeName];

                    CGPoint position = listMarkerNode.position;

                    if (_listItemType == MHListItemUnnumbered) {
                        for (SKNode *child in listMarkerNode.children) {
                            CGContextTranslateCTM(pdfContext, position.x, position.y);
                            [child renderInPDFContext:pdfContext];
                            CGContextTranslateCTM(pdfContext, -position.x, -position.y);
                        }
                    }
                    else {
                        CGContextTranslateCTM(pdfContext, position.x, position.y);
                        [listMarkerNode renderInPDFContext:pdfContext];
                        CGContextTranslateCTM(pdfContext, -position.x, -position.y);
                    }
                }
            }
            
            MHLink *subexpressionLink = objc_getAssociatedObject(subexpression, &kMHLinkLinkedExpressionAssociatedObjectKey);
            
            CGPoint subexpPosition = [mySpriteKitNode convertPoint:CGPointZero fromNode:subexpression.spriteKitNode];
            CGContextTranslateCTM(pdfContext, subexpPosition.x, subexpPosition.y);
            if (subexpressionLink) {
                [subexpressionLink addPDFLinkForExpression:subexpression withContextManager:contextManager];
            }
            [subexpression renderToPDFWithContextManager:contextManager];
            CGContextTranslateCTM(pdfContext, -subexpPosition.x, -subexpPosition.y);
        }
    }
    else {
        // original code - uses super implementation of rendering and pagination, with some added code to deal with lists
        
        [super renderToPDFWithContextManager:contextManager];

        CGContextRef pdfContext = contextManager.pdfContext;

        // FIXME: temporary, ad hoc code. Needs refactoring

        // dealing with lists
        if (_listItemType != MHListItemNone) {
            SKNode *listMarkerNode = [self.spriteKitNode childNodeWithName:kMHTextParagraphListMarkerNodeName];

            CGPoint position = listMarkerNode.position;

            if (_listItemType == MHListItemUnnumbered) {
                for (SKNode *child in listMarkerNode.children) {
                    CGContextTranslateCTM(pdfContext, position.x, position.y);
                    [child renderInPDFContext:pdfContext];
                    CGContextTranslateCTM(pdfContext, -position.x, -position.y);
                }
            }
            else {
                CGContextTranslateCTM(pdfContext, position.x, position.y);
                [listMarkerNode renderInPDFContext:pdfContext];
                CGContextTranslateCTM(pdfContext, -position.x, -position.y);
            }
        }
    }
}



@end




