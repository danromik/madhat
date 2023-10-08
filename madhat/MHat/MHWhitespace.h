//
//  MHWhitespace.h
//  MadHat
//
//  Created by Dan Romik on 8/24/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHExpression.h"
#import "MHCommand.h"

typedef enum {
    // Horizontal spaces
    MHHorizontalSpaceNormal,      // A normal space such as the one between two words
    MHHorizontalSpaceWide,        // A wider space, which can be used for example to separate between sentences in a text paragraph
    MHHorizontalSpaceQuad,
    MHHorizontalSpaceDoubleQuad,
    MHHorizontalSpaceHalf,
    MHHorizontalSpaceLogical,     // in math mode, an invisible space that signals a semantic separation between different quantities. In certain algebra contexts it will be interpteted as an implicit multiplication operator
    MHHorizontalSpaceCustom,     // a custom horizontal space, specified in points
    //
    // Vertical spaces - all of them are interpreted logically as newlines by layout classes
    MHVerticalSpaceNormal,       // a normal vertical space such as the one between two successive lines in a paragraph
    MHVerticalSpaceParagraphSpacing, // a vertical space equal to the inter-paragraph spacing
    MHVerticalSpaceSmall,
    MHVerticalSpaceMedium,
    MHVerticalSpaceLarge,
    MHVerticalSpaceHuge,
    MHVerticalSpaceCustom       // a custom vertical space, specified in points
} MHWhitespaceType;

typedef enum {
    MHWhitespaceOrientationHorizontal,
    MHWhitespaceOrientationVertical
} MHSpaceOrientationType;

NS_ASSUME_NONNULL_BEGIN

@interface MHWhitespace : MHExpression <MHCommand>

// convenience constructors for a simple space (MHHorizontalSpaceNormal) and a simple newline (MHVerticalSpaceNormal)
+ (instancetype)space;
+ (instancetype)newline;

// a constructor for general, non-custom horizontal/vertical spaces:
+ (instancetype)spaceWithType:(MHWhitespaceType)type;

// constructor for custom spaces:
+ (instancetype)customHorizontalSpaceWithWidth:(CGFloat)width;
+ (instancetype)customVerticalSpaceWithHeight:(CGFloat)height;

@property (readonly) MHWhitespaceType type;
@property (readonly) MHSpaceOrientationType orientation;

- (MHDimensions)dimensionsWithContextManager:(MHTypesettingContextManager *)contextManager;

- (void)makeLarger;


@end

NS_ASSUME_NONNULL_END
