//
//  MHTypesettingContextManager.m
//  MadHat
//
//  Created by Dan Romik on 10/24/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import "MHTypesettingContextManager.h"
#import "MHStyleIncludes.h"


NSString * const kMHPageBackgroundColorNotification = @"MHPageBackgroundColorChanged";
NSString * const kMHPageBackgroundColorKey = @"MHPageBackgroundColor";



@interface MHTypesettingContextManager ()
{
    NSColor *_pageBackgroundColor;
    MHTypesettingState *_defaultState;
    
    MHNotebookConfiguration *_notebookConfiguration;

    NSUInteger _exportedPageNumber;

    MHExpression <MHOutlinerItemMarker> *_outlinerItemStartMarker;
    MHExpression *_collapsibleSectionStartMarker;
    
    NSUInteger _slideTransitionCounter;
}

@end

@implementation MHTypesettingContextManager




#pragma mark - Constructor method

- (instancetype)init
{
    if (self = [super init]) {
        typingStylesStack = [NSMutableArray arrayWithCapacity:0];
        typingStyleChangeDepthIndicesStack = [NSMutableArray arrayWithCapacity:0];

        _graphicsStylesStack = [NSMutableArray arrayWithCapacity:0];
        _graphicsStyleChangeDepthIndicesStack = [NSMutableArray arrayWithCapacity:0];

        _currentGraphicsStyle = nil;
        
        _defaultState = [MHTypesettingState defaultState];
        [self resetToDefaultState];
    }
    return self;
}


#pragma mark - Bulk state changes

- (void)resetToDefaultState
{
    // Set default values
    self.pageBackgroundColor = [NSColor whiteColor];
    
    [typingStylesStack removeAllObjects];
    [typingStyleChangeDepthIndicesStack removeAllObjects];
    typingStylesStackDepthCounter = 0;
    lastDepthWhenTypingStylePushed = 0;

    if (_currentGraphicsStyle) {
        _currentGraphicsStyle = nil;
        [_graphicsStylesStack removeAllObjects];
        [_graphicsStyleChangeDepthIndicesStack removeAllObjects];
        _graphicsStylesStackDepthCounter = 0;
        _lastDepthWhenGraphicsStylePushed = 0;
    }

    _currentTypingStyle = [_defaultState.typingStyle copy];
    _currentParagraphStyle = [_defaultState.paragraphStyle copy];
    _currentListStyle = [_defaultState.listStyle copy];

    _slideTransitionCounter = 0;
}

- (void)resetToMemoizedState:(MHTypesettingState *)state
{
    _currentTypingStyle = [state.typingStyle copy];
    _currentParagraphStyle = [state.paragraphStyle copy];
    _currentListStyle = [state.listStyle copy];
}

- (MHTypesettingState *)memoizedState
{
    MHTypesettingState *state = [[MHTypesettingState alloc] init];
    state.typingStyle = [_currentTypingStyle copy];
    state.paragraphStyle = [_currentParagraphStyle copy];
    state.listStyle = [_currentListStyle copy];
    return state;
}


- (MHTypesettingState *)defaultState
{
    return [_defaultState copy];
}

- (void)setDefaultState:(MHTypesettingState *)defaultState
{
    _defaultState = defaultState;
}




#pragma mark - Page geometry

- (NSSize)pageSize
{
    return self.notebookConfiguration.pageSize;
}

- (void)setPageSize:(NSSize)pageSize
{
    self.notebookConfiguration.pageSize = pageSize;
}

- (CGFloat)pageWidth
{
    return self.pageSize.width;
}

- (void)setPageWidth:(CGFloat)pageWidth
{
    NSSize myPageSize = self.notebookConfiguration.pageSize;
    myPageSize.width = pageWidth;
    self.notebookConfiguration.pageSize = myPageSize;
}

//
//- (CGFloat)pageHeight
//{
//    return self.pageSize.height;
//}
//
//- (void)setPageHeight:(CGFloat)pageHeight
//{
//    NSSize myPageSize = self.notebookConfiguration.pageSize;
//    myPageSize.height = pageHeight;
//    self.notebookConfiguration.pageSize = myPageSize;
//}

- (CGFloat)pageLeftMargin
{
    return self.notebookConfiguration.pageLeftMargin;
}

- (void)setPageLeftMargin:(CGFloat)pageLeftMargin
{
    self.notebookConfiguration.pageLeftMargin = pageLeftMargin;
}

- (CGFloat)pageRightMargin
{
    return self.notebookConfiguration.pageRightMargin;
}

- (void)setPageRightMargin:(CGFloat)pageRightMargin
{
    self.notebookConfiguration.pageRightMargin = pageRightMargin;
}

- (CGFloat)textWidth
{
    MHNotebookConfiguration *notebookConfig = self.notebookConfiguration;
    NSSize pageSize = notebookConfig.pageSize;
    CGFloat leftMargin = notebookConfig.pageLeftMargin;
    CGFloat rightMargin = notebookConfig.pageRightMargin;
    return pageSize.width - leftMargin - rightMargin;
}

- (CGFloat)pageTopMargin
{
    return self.notebookConfiguration.pageTopMargin;
}

- (void)setPageTopMargin:(CGFloat)topMargin
{
    self.notebookConfiguration.pageTopMargin = topMargin;
}

- (CGFloat)exportedPageTopMargin
{
    return self.notebookConfiguration.exportedPageTopMargin;
}

- (void)setExportedPageTopMargin:(CGFloat)topMargin
{
    self.notebookConfiguration.exportedPageTopMargin = topMargin;
}

- (CGFloat)pageBottomMargin
{
    return self.notebookConfiguration.pageBottomMargin;
}

- (void)setPageBottomMargin:(CGFloat)bottomMargin
{
    self.notebookConfiguration.pageBottomMargin = bottomMargin;
}

- (CGFloat)exportedPageBottomMargin
{
    return self.notebookConfiguration.exportedPageBottomMargin;
}

- (void)setExportedPageBottomMargin:(CGFloat)bottomMargin
{
    self.notebookConfiguration.exportedPageBottomMargin = bottomMargin;
}

- (CGFloat)exportedPageHeaderOffset
{
    return self.notebookConfiguration.exportedPageHeaderOffset;
}

- (void)setExportedPageHeaderOffset:(CGFloat)headerOffset
{
    self.notebookConfiguration.exportedPageHeaderOffset = headerOffset;
}

- (CGFloat)exportedPageFooterOffset
{
    return self.notebookConfiguration.exportedPageFooterOffset;
}

- (void)setExportedPageFooterOffset:(CGFloat)footerOffset
{
    self.notebookConfiguration.exportedPageFooterOffset = footerOffset;
}

#pragma mark - Notebook configuration

- (MHNotebookConfiguration *)notebookConfiguration
{
    // lazily instantiate the notebook configuration
    if (!_notebookConfiguration) {
        _notebookConfiguration = [[MHNotebookConfiguration alloc] init];
    }
    return _notebookConfiguration;
}

- (void)setNotebookConfiguration:(MHNotebookConfiguration *)notebookConfiguration
{
    _notebookConfiguration = notebookConfiguration;
}

- (NSString *)notebookTitle
{
    return self.notebookConfiguration.notebookTitle;
}

- (void)setNotebookTitle:(NSString *)notebookTitle
{
    self.notebookConfiguration.notebookTitle = notebookTitle;
}

- (NSString *)notebookAuthor
{
    return self.notebookConfiguration.notebookAuthor;
}

- (void)setNotebookAuthor:(NSString *)notebookAuthor
{
    self.notebookConfiguration.notebookAuthor = notebookAuthor;
}

- (MHExpression *)exportedPageHeader
{
    return self.notebookConfiguration.exportedPageHeader;
}

- (void)setExportedPageHeader:(MHExpression *)exportedPageHeader
{
    self.notebookConfiguration.exportedPageHeader = exportedPageHeader;
}

- (MHExpression *)exportedPageFooter
{
    return self.notebookConfiguration.exportedPageFooter;
}

- (void)setExportedPageFooter:(MHExpression *)exportedPageFooter
{
    self.notebookConfiguration.exportedPageFooter = exportedPageFooter;
}

- (NSRange)exportedHeaderAndFooterRange
{
    return self.notebookConfiguration.exportedHeaderAndFooterRange;
}

- (void)setExportedHeaderAndFooterRange:(NSRange)range
{
    self.notebookConfiguration.exportedHeaderAndFooterRange = range;
}

- (CGFloat)lineSpacing
{
    return self.notebookConfiguration.lineSpacing;
}

- (void)setLineSpacing:(CGFloat)lineSpacing
{
    self.notebookConfiguration.lineSpacing = lineSpacing;
}

- (CGFloat)baseParagraphSpacing
{
    return self.notebookConfiguration.baseParagraphSpacing;
}

- (void)setBaseParagraphSpacing:(CGFloat)spacing
{
    self.notebookConfiguration.baseParagraphSpacing = spacing;
}

- (CGFloat)paragraphIndent
{
    return self.notebookConfiguration.paragraphIndent;
}

- (void)setParagraphIndent:(CGFloat)indent
{
    self.notebookConfiguration.paragraphIndent = indent;
}

- (MHParagraphKerningMatrixCastAsPointer)paragraphKerningMatrix
{
    return self.notebookConfiguration.paragraphKerningMatrix;
}

//- (void)setParagraphKerningMatrix:(MHParagraphKerningMatrixCastAsPointer)matrix
//{
//    self.notebookConfiguration.paragraphKerningMatrix = matrix;
//}

- (void)setParagraphKerningMatrixPrimaryRowsAndColumns:(MHParagraphKerningMatrixCastAsPointer)matrix
{
    [self.notebookConfiguration setParagraphKerningMatrixPrimaryRowsAndColumns:matrix];
}

- (void)setPreparagraphSpacingAtTopOfPage:(CGFloat[MHNumberOfEffectiveParagraphTypes-2])spacingsList
{
    [self.notebookConfiguration setPreparagraphSpacingAtTopOfPage:spacingsList];
}

- (void)saveCurrentTypesettingStateWithStyleName:(NSString *)styleName
{
    MHTypesettingState *memoizedState = [self memoizedState];
    memoizedState.paragraphStyle.paragraphType = MHParagraphNone;   // when saving a state as part of the notebook configuration, set its paragraph type to MHParagraphNone to avoid interfering with paragraph kerning during vertical layout (see the code in MHVerticalLayoutContainer)
    [self.notebookConfiguration defineTypesettingStateWithName:styleName as:memoizedState];
}

- (void)loadSavedTypesettingStateWithStyleName:(NSString *)styleName
{
    MHTypesettingState *state = [self.notebookConfiguration predefinedTypesettingStateWithName:styleName];
    if (state) {
        // FIXME: I'm only actually applying the typing style. So it doesn't make sense to save the entire MHTypesettingState - change it so I'm only saving MHTypingStyle objects
        
        [self typingStyleWillChange];
        _currentTypingStyle = [state.typingStyle copy]; // FIXME: code copied from resetToMemoizedState: method, but probably there should be a method call to set the typing style
//        [self resetToMemoizedState:state];
    }
}



#pragma mark - Properties

- (NSUInteger)exportedPageNumber
{
    return _exportedPageNumber;
}

- (void)setExportedPageNumber:(NSUInteger)exportedPageNumber
{
    _exportedPageNumber = exportedPageNumber;
}


- (NSColor *)pageBackgroundColor
{
    return _pageBackgroundColor;
}

- (void)setPageBackgroundColor:(NSColor *)pageBackgroundColor
{
    _pageBackgroundColor = pageBackgroundColor;
    [[NSNotificationCenter defaultCenter] postNotificationName:kMHPageBackgroundColorNotification
                                                        object:self
                                                      userInfo:@{ kMHPageBackgroundColorKey : pageBackgroundColor }];
}


- (CGFloat)mathAxisHeightForNestingLevel:(NSUInteger)nestingLevel
{
    return [self fontSizeForNestingLevel:nestingLevel]
    *((CGFloat)(_currentTypingStyle.mathFontSystem.mathAxisHeight))/1000.0;
}

- (CGFloat)fractionLineThicknessForNestingLevel:(NSUInteger)nestingLevel
{
    return [self fontSizeForNestingLevel:nestingLevel]
    *((CGFloat)(_currentTypingStyle.mathFontSystem.fractionLineThickness))/1000.0;
}

- (CGFloat)radicalOverlineThicknessForNestingLevel:(NSUInteger)nestingLevel
{
    // FIXME: is this necessary? Maybe merge with the fraction line thickness and give it a name that covers both
    return [self fractionLineThicknessForNestingLevel:nestingLevel];
}

- (CGFloat)mathTrackingFactorForNestingLevel:(NSUInteger)nestingLevel
{
    NSUInteger cappedNestingLevel = (nestingLevel < kMHNumberOfNestingLevels
                                     ? nestingLevel : kMHNumberOfNestingLevels-1);
    return ((CGFloat)(_currentTypingStyle.mathFontSystem.nestingLevelMathTrackingFactors[cappedNestingLevel]))/1000.0;
}

- (CGFloat)mathKernWidthForLeftTypographyClass:(MHTypographyClass)leftClass
                          rightTypographyClass:(MHTypographyClass)rightClass
                                  nestingLevel:(NSUInteger)nestingLevel
{
    return [self fontSizeForNestingLevel:nestingLevel] * (float)(_currentTypingStyle.mathFontSystem.mathKerningMatrix)[leftClass*MHTypographyNumberOfClasses+rightClass]/1000.0 * [self mathTrackingFactorForNestingLevel:nestingLevel];
}


#pragma mark - Various methods


- (void)beginLocalScope
{
    // The commented out code is a simple-minded implementation of a stack of typing styles
//    MHTypingStyle *styleCopy = [_currentTypingStyle copy];
//    [typingStylesStack addObject:_currentTypingStyle];
//    _currentTypingStyle = styleCopy;

    // The actual implementation optimizes the stack idea by using lazy copying of resources: the _currentTypingStyle gets copied and pushed into the stack only if it is about to be modified (this happens during a call to the styleWillChange method), so that most of the time copying the style is unnecessary
    typingStylesStackDepthCounter++;

    // Added later: doing the same thing with the graphics styles stack, with a separate stack and depth counter
    if (_currentGraphicsStyle)
        _graphicsStylesStackDepthCounter++;
}

- (void)endLocalScope
{
    // The commented out code is from the unoptimized stack implementation
//    _currentTypingStyle = [typingStylesStack lastObject];
//    [typingStylesStack removeLastObject];
    
    // The current implementation is an optimized stack with lazy copying - see the explanation in beginLocalScope
    if (lastDepthWhenTypingStylePushed == typingStylesStackDepthCounter) {
        _currentTypingStyle = [typingStylesStack lastObject];
        [typingStylesStack removeLastObject];
        lastDepthWhenTypingStylePushed = [[typingStyleChangeDepthIndicesStack lastObject] shortValue];
        [typingStyleChangeDepthIndicesStack removeLastObject];
    }
    typingStylesStackDepthCounter--;
    
    // Added later: doing the same thing with the graphics styles stack, with a separate stack and depth counter
    if (_currentGraphicsStyle) {
        if (_lastDepthWhenGraphicsStylePushed == _graphicsStylesStackDepthCounter) {
            _currentGraphicsStyle = [_graphicsStylesStack lastObject];
            [_graphicsStylesStack removeLastObject];
            _lastDepthWhenGraphicsStylePushed = [[_graphicsStyleChangeDepthIndicesStack lastObject] shortValue];
            [_graphicsStyleChangeDepthIndicesStack removeLastObject];
        }
        _graphicsStylesStackDepthCounter--;
    }
}

- (void)beginGraphicsCanvas:(MHDimensions)dimensions viewRectangle:(MHGraphicsRectangle)viewRectangle
{
    // FIXME: add a stack to handle nested graphics canvasses
    _currentGraphicsStyle = [MHGraphicsStyle defaultStyleWithDimensions:dimensions viewRectangle:viewRectangle];
    [_graphicsStylesStack removeAllObjects];
    [_graphicsStyleChangeDepthIndicesStack removeAllObjects];
    _graphicsStylesStackDepthCounter = 0;
    _lastDepthWhenGraphicsStylePushed = 0;
}

- (void)endGraphicsCanvas
{
    _currentGraphicsStyle = nil;
    [_graphicsStylesStack removeAllObjects];
    [_graphicsStyleChangeDepthIndicesStack removeAllObjects];
    _graphicsStylesStackDepthCounter = 0;
    _lastDepthWhenGraphicsStylePushed = 0;
}

- (bool)graphicsCanvasCurrentlyActive
{
    return (_currentGraphicsStyle != nil);
}



- (CGPoint)convertPointFromCanvasToNodeCoordinates:(CGPoint)pointInCanvasCoordinates
{
    // If there is no active graphics canvas, we consider the canvas coordinate system to be identical to the screen coordinates
    if (!self.graphicsCanvasCurrentlyActive)
        return pointInCanvasCoordinates;
    
    CGPoint convertedPoint;
    MHGraphicsRectangle viewRectangle = self.graphicsViewRectangle;
    MHDimensions canvasDimensions = self.graphicsCanvasDimensions;
    convertedPoint.x = canvasDimensions.width * (pointInCanvasCoordinates.x - viewRectangle.minX) / (viewRectangle.maxX - viewRectangle.minX);
    convertedPoint.y = canvasDimensions.height * (pointInCanvasCoordinates.y - viewRectangle.minY) / (viewRectangle.maxY - viewRectangle.minY);
    return convertedPoint;
}

- (CGVector)convertVectorFromCanvasToNodeCoordinates:(CGVector)vectorInCanvasCoordinates
{
    // If there is no active graphics canvas, we consider the canvas coordinate system to be identical to the screen coordinates
    if (!self.graphicsCanvasCurrentlyActive)
        return vectorInCanvasCoordinates;
    
    CGVector convertedVector;
    MHGraphicsRectangle viewRectangle = self.graphicsViewRectangle;
    MHDimensions canvasDimensions = self.graphicsCanvasDimensions;
    convertedVector.dx = canvasDimensions.width * vectorInCanvasCoordinates.dx / (viewRectangle.maxX - viewRectangle.minX);
    convertedVector.dy = canvasDimensions.height * vectorInCanvasCoordinates.dy / (viewRectangle.maxY - viewRectangle.minY);
    return convertedVector;
}





- (NSImage *)imageResourceForIdentifier:(NSString *)identifier
{
    return [self.resourceProvider imageResourceForIdentifier:identifier];
}

- (NSURL *)videoResourceForIdentifier:(NSString *)identifier
{
    return [self.resourceProvider videoResourceForIdentifier:identifier];
}


- (NSUInteger)slideTransitionCounter
{
    return _slideTransitionCounter;
}

- (void)incrementSlideTransitionCounter
{
    _slideTransitionCounter++;
}



#pragma mark - Support for outliner and collapsible sections

- (void)setOutlinerItemStartMarker:(MHExpression<MHOutlinerItemMarker> *)outlinerItemStartMarker
{
    _outlinerItemStartMarker = outlinerItemStartMarker;
}

- (MHExpression <MHOutlinerItemMarker> *)readAndResetOutlinerItemStartMarker
{
    MHExpression <MHOutlinerItemMarker> *marker = _outlinerItemStartMarker;
    _outlinerItemStartMarker = nil;
    return marker;
}

- (void)setCollapsibleSectionStartMarker:(MHExpression *)collapsibleSectionStartMarker
{
    _collapsibleSectionStartMarker = collapsibleSectionStartMarker;
}

- (MHExpression *)readAndResetCollapsibleSectionStartMarker
{
    MHExpression *marker = _collapsibleSectionStartMarker;
    _collapsibleSectionStartMarker = nil;
    return marker;
}


@end

