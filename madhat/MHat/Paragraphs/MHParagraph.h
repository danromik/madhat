//
//  MHParagraph.h
//  MadHat
//
//  Created by Dan Romik on 11/3/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import "MHHorizontalLayoutContainer.h"


NS_ASSUME_NONNULL_BEGIN


extern NSString * const kMHParagraphFrameNodeName;
extern NSString * const kMHParagraphFrameLinesNodeName;

extern const CGFloat kMHParagraphLogicalIndentationMultiplier;      // FIXME: make this configurable
extern const CGFloat kMHParagraphBoxLeftRightPadding;                      // FIXME: make this configurable

typedef enum {
    MHParagraphAlignmentRaggedLeft = 0,
    MHParagraphAlignmentCenter,
    MHParagraphAlignmentRaggedRight,
    // FIXME: add more alignment modes, including a mode for math paragraphs to have the display aligned to some given fraction of the paragraph width
} MHParagraphAlignment;

extern NSString * const kMHParagraphAlignmentAttributeName;
extern NSString * const kMHParagraphAlignmentAttributeRaggedLeft;
extern NSString * const kMHParagraphAlignmentAttributeCenter;
extern NSString * const kMHParagraphAlignmentAttributeRaggedRight;


typedef struct {
    CGFloat preParagraphSpacing;
    CGFloat postParagraphSpacing;       // currently this field is set to 0 and not used, but leaving this for possible future use
} MHParagraphVerticalPadding;


// FIXME: moved this typedef to MadHat.h to avoid having to #import this header file in MHParagraphStyle.h, creating a cyclic import loop
// it still seems more logical to include the typedef here - fix
//// the paragraph type affects the spacing inserted before and after the paragraph by the vertical layout class
//typedef enum {
//    MHParagraphNormal,      // default type
//    MHParagraphHeader,
//    MHParagraphSubheader,
//    MHParagraphListItem
//} MHParagraphType;


@interface MHParagraph : MHHorizontalLayoutContainer

@property MHParagraphAlignment alignment;

@property MHDimensions dimensions;          // redeclaring this from MHExpression in order to document some important notes:
// 1. dimensions.width will be set by MHParagraph during the typesetWithContextManager: method to a value read from
// the context manager.
// 2. The depth and the height will be set to 0 since MHParagraph does not have its own line breaking algorithm. So,
// 3. subclasses should call the super typesetWithContextManager: method and then use the width field of the dimensions property
// as the basis for their own typesetting, and set the depth and height field to the correct values

@property (readonly) MHParagraphType type;

@property MHTypesettingState *memoizedStateBeforeTypesetting;
@property MHTypesettingState *memoizedStateAfterTypesetting;

// FIXME: a bit of a hack to get paragraph backgrounds working - can this setup be improved?
@property MHParagraphVerticalPadding verticalPadding;   // currently only the preParagraphSpacing is used, i.e., the setup is that each paragraph owns the vertical kern between it and the paragraph preceding it, and is responsible for rendering the background node for that area (currently applies to paragraphs that are part of a box). The postParagraphSpacing is ignored, but maybe in the future it would be nice (that is, a bit more logical and potentially more robust) to have a setup where each paragraph owns the bottom half of the vertical kern above it, and the bottom half of the vertical kern below it.


- (void)doPostTypesettingHousekeeping; // subclasses should call this at the end of their typesetWithContextManager: method. (Explanation of why this is needed: calling the super implementation of typesetWithContextManager: isn't enough, since there are some housekeeping actions that need to be done after the paragraph has been typeset, and the super method is called at the beginning.)

@property MHParagraphBoxType boxType;


@property NSArray <MHExpression *> *attachedContent;   // this property can be used by the parser to store expressions the paragraph wants to have the parser add after the paragraph. maybe in the future can be used for storing footnotes, margin notes, popup comments and other such things


@property CGFloat uncollapsedYPosition;     // stores the y coordinate of the position property in the totally uncollapsed state


- (CGFloat)verticalOffsetOfFollowingContentWhenCollapsedAtCurrentHierarchyLevel;    // FIXME: clunky name, maybe improve
- (bool)hasVisibleContentWhenCollapsed;


@property (readonly) NSUInteger numberOfSlideTransitions;


// Paragraph frames
- (SKShapeNode *)newParagraphBackgroundNodeWithBoxType:(MHParagraphBoxType)boxType
                                            frameColor:(nullable NSColor *)frameColor
                                       backgroundColor:(nullable NSColor *)backgroundColor
                                        frameThickness:(CGFloat)frameThickness;




@end


@protocol MHOutlinerItemParagraph
@property (readonly) bool containsOutlinerItem;
@property bool outlinerItemIsCollapsed;
@end


NS_ASSUME_NONNULL_END

