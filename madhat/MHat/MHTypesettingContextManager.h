//
//  MHTypesettingContextManager.h
//  MadHat
//
//  Created by Dan Romik on 10/24/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#import "MadHat.h"
#import "MHMathFontSystem.h"
#import "MHTypingStyle.h"
#import "MHParagraphStyle.h"
#import "MHGraphicsStyle.h"
#import "MHListStyle.h"
#import "MHTypesettingState.h"
#import "MHNotebookConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kMHPageBackgroundColorNotification;
extern NSString * const kMHPageBackgroundColorKey;


@protocol MHResourceProvider, MHOutlinerItemMarker;

@interface MHTypesettingContextManager : NSObject
{
@private
    // These variables are in the public header since they are used by the various categories associated with styles
    MHTypingStyle *_currentTypingStyle;

    MHParagraphStyle *_currentParagraphStyle;
    MHListStyle *_currentListStyle;

    NSMutableArray <MHTypingStyle *> *typingStylesStack;
    NSMutableArray <NSNumber *> *typingStyleChangeDepthIndicesStack;
    NSUInteger typingStylesStackDepthCounter;
    NSUInteger lastDepthWhenTypingStylePushed;
    
    MHGraphicsStyle *_currentGraphicsStyle;

    NSMutableArray <MHGraphicsStyle *> *_graphicsStylesStack;
    NSMutableArray <NSNumber *> *_graphicsStyleChangeDepthIndicesStack;
    NSUInteger _graphicsStylesStackDepthCounter;
    NSUInteger _lastDepthWhenGraphicsStylePushed;
}


- (instancetype)init;               // Initialization

@property (copy) MHTypesettingState *defaultState;

- (void)resetToDefaultState;

- (MHTypesettingState *)memoizedState;            // this creates a copy of the current state, which can be used for memoization
- (void)resetToMemoizedState:(MHTypesettingState *)state;

- (void)saveCurrentTypesettingStateWithStyleName:(NSString *)styleName;
- (void)loadSavedTypesettingStateWithStyleName:(NSString *)styleName;


// Page geometry properties
//@property (readonly) CGFloat pageHeight;
@property CGFloat pageWidth;
@property NSSize pageSize;
@property CGFloat pageLeftMargin;
@property CGFloat pageRightMargin;
@property CGFloat pageTopMargin;
@property CGFloat exportedPageTopMargin;
@property CGFloat pageBottomMargin;
@property CGFloat exportedPageBottomMargin;
@property CGFloat exportedPageHeaderOffset;
@property CGFloat exportedPageFooterOffset;
@property (readonly) CGFloat textWidth;     // this property is derived from the page width, left margin and right margin

@property NSColor *pageBackgroundColor;


// Outliner and collapsible sections
- (void)setOutlinerItemStartMarker:(MHExpression <MHOutlinerItemMarker> *)outlinerItemStartMarker;
- (MHExpression <MHOutlinerItemMarker> *)readAndResetOutlinerItemStartMarker;
- (void)setCollapsibleSectionStartMarker:(MHExpression *)collapsibleSectionStartMarker;
- (MHExpression *)readAndResetCollapsibleSectionStartMarker;


// Document properties
@property MHNotebookConfiguration *notebookConfiguration;   // the defaultTypesettingState property of the configuration object returned from this property will be nil and needs to be manually set
@property NSString *notebookTitle;
@property NSString *notebookAuthor;
@property MHExpression *exportedPageHeader;
@property MHExpression *exportedPageFooter;
@property NSUInteger exportedPageNumber;    // returns the current page number during PDF export
@property NSRange exportedHeaderAndFooterRange; // range of notebook pages to apply headers and footers to during export
@property CGFloat lineSpacing;      // measured in multiples of the current font's line height (ascender+(-descender)+leading), note that the descender returned by the NSFont API is negative so it gets added with a minus sign in front  // FIXME: leading returns 0, not sure why
@property CGFloat baseParagraphSpacing;     // measured in multiples of the current font's point size
@property CGFloat paragraphIndent;          // measured in multiples of the current font's point size
@property (readonly) MHParagraphKerningMatrixCastAsPointer paragraphKerningMatrix;
- (void)setParagraphKerningMatrixPrimaryRowsAndColumns:(MHParagraphKerningMatrixCastAsPointer)matrix;  // the matrix gets copied
- (void)setPreparagraphSpacingAtTopOfPage:(CGFloat[_Nonnull MHNumberOfEffectiveParagraphTypes-2])spacingsList;    // the vector gets copied

// Math font properties
// FIXME: some of these properties won't change during typesetting so it may be inefficient to have them provided by the context manager - improve
- (CGFloat)mathAxisHeightForNestingLevel:(NSUInteger)nestingLevel;  // measured in points
- (CGFloat)fractionLineThicknessForNestingLevel:(NSUInteger)nestingLevel;
- (CGFloat)radicalOverlineThicknessForNestingLevel:(NSUInteger)nestingLevel;
- (CGFloat)mathKernWidthForLeftTypographyClass:(MHTypographyClass)leftClass
                          rightTypographyClass:(MHTypographyClass)rightClass
                                  nestingLevel:(NSUInteger)nestingLevel;


// These methods get called during typesetting by expressions that want to do typesetting operations that may change the style, but want to keep those changes local to the expression so they don't influence the style after the locally scoped expression has finished typesetting
- (void)beginLocalScope;
- (void)endLocalScope;


// Graphics canvasses
- (bool)graphicsCanvasCurrentlyActive;
- (void)beginGraphicsCanvas:(MHDimensions)dimensions viewRectangle:(MHGraphicsRectangle)viewRectangle;
- (void)endGraphicsCanvas;

- (CGPoint)convertPointFromCanvasToNodeCoordinates:(CGPoint)pointInCanvasCoordinates;
- (CGVector)convertVectorFromCanvasToNodeCoordinates:(CGVector)vectorInCanvasCoordinates;


@property (weak) NSObject <MHResourceProvider> *resourceProvider;
- (NSImage *)imageResourceForIdentifier:(NSString *)identifier;
- (NSURL *)videoResourceForIdentifier:(NSString *)identifier;


// a counter for slide transitions, so that an MHParagraph object can easily determine how many slide transitions it contains
@property (readonly) NSUInteger slideTransitionCounter;
- (void)incrementSlideTransitionCounter;


@end


@protocol MHResourceProvider <NSObject>

- (nullable NSImage *)imageResourceForIdentifier:(NSString *)identifier;
- (nullable NSURL *)videoResourceForIdentifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
