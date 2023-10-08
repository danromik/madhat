//
//  MHBracket.h
//  MadHat
//
//  Created by Dan Romik on 1/11/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHExpression.h"
#import "MHCommand.h"

NS_ASSUME_NONNULL_BEGIN

#define MHBracketDynamicallyDeterminedSize                        1000



@protocol MHBracket

@optional
// these methods are required if the heightIsAdjustable property returns TRUE
@property MHBracketOrientation orientation;  // should only be changed from "dynamically determined" to the left or right orientations
@property MHDimensions dimensionsIgnoringWidth;       // only the height and depth information is used

// FIXME: this property probably shouldn't be exposed in the public header
// FIXME: would this work better as a typedef enum?
@property NSUInteger sizeVariant;   // either a value between 0 and kMHBracketNumberOfGlyphVariants-1, or MHBracketDynamicallyDeterminedSize


@required
@property (readonly) bool heightIsAdjustable;
@property MHBracketType type;
@end





@interface MHBracket : MHExpression <MHCommand, MHBracket>

@property MHBracketType type;


+ (instancetype)bracketWithType:(MHBracketType)type
                    orientation:(MHBracketOrientation)orientation
                        variant:(NSUInteger)variant;

- (instancetype)initWithType:(MHBracketType)type
                 orientation:(MHBracketOrientation)orientation
                     variant:(NSUInteger)variant;


@end

NS_ASSUME_NONNULL_END
