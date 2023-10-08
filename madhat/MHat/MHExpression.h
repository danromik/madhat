//
//  MHExpression.h
//  MadHat
//
//  Created by Dan Romik on 10/20/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MadHat.h"
#import "MHTypesettingContextManager.h"
#import "MHReformattingContextManager.h"
#import "SKNode+MHSomeConvenienceMethods.h"
#import "MHPDFRenderingContextManager.h"

NS_ASSUME_NONNULL_BEGIN

@class SKNode, MHHorizontalLayoutContainer;
@protocol MHSourceCodeString;


@interface MHExpression : NSObject {
@protected
    SKNode *_spriteKitNode;
}

@property (weak) MHExpression *parent;
@property (readonly) MHExpression *rootAncestor;    // climbs up the parent chain all the way to the root

// Most important read-write properties
@property NSPoint position;
- (void)setPosition:(NSPoint)position animated:(bool)animated;

@property MHDimensions dimensions;
@property MHExpressionPresentationMode presentationMode;
@property NSUInteger nestingLevel;
@property NSRange codeRange;

// Main read only properties
@property (readonly) NSString *stringValue;
@property (readonly) float floatValue;
@property (readonly) int intValue;
@property (readonly) bool boolValue;

@property (readonly) NSString *exportedLaTeXValue;

@property (readonly) SKNode *spriteKitNode;         // Needs to be overridden by any subclass that wants to present itself graphically using a sprite kit node


@property (readonly) MHMathParagraphAlignmentRole mathParagraphAlignmentRole;

// Properties that need to be overridden by subclasses to enhance typesetting functionality
@property (readonly) MHTypographyClass typographyClass;         // defaults to MHTypographyClassUnknown, subclasses should implement behavior
@property (readonly) MHTypographyClass leftTypographyClass;     // defaults to self.typographyClass. Some classes will override to implement left-right asymmetric kerning behavior
@property (readonly) MHTypographyClass rightTypographyClass;    // defaults to self.typographyClass. Some classes will override to implement left-right asymmetric kerning behavior

@property (readonly) short int italicCorrection;    // measured in one-thousandths of an em width. defaults to 0
@property (readonly) short int leftItalicCorrection;    // measured in one-thousandths of an em width. defaults to self.italicCorrection
@property (readonly) short int rightItalicCorrection;    // measured in one-thousandths of an em width. defaults to self.italicCorrection

@property (readonly) bool isLimitsOperator;                     // Defaults to false, subclasses can override to change behavior

@property (readonly) short int topDecorationPositioningOffset;    // measured in one-thousandths of an em width. defaults to 0

// Defaults to false. Override to return true for classes that have complex expressions that can be split across line boundaries
@property (readonly) bool splittable;   // a class that returns true is required to conform to the MHSplittableExpression protocol

// Defaults to true. Override to return false for classes that might have multiple components that behave differently during reformatting
- (bool)atomicForReformatting;      // a class that returns false is required to conform to the MHDecomposableForReformatting protocol

@property bool highlighted;




+ (instancetype)expression;             // Convenience constructor

+ (instancetype)booleanExpressionWithValue:(bool)value;

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager;

- (void)reformatWithContextManager:(MHReformattingContextManager *)contextManager animationType:(MHReformattingAnimationType)animationType;

- (void)mouseClickWithEvent:(NSEvent *)event subnode:(SKNode *)node;   // Default implementation does nothing


- (void)renderToPDFWithContextManager:(MHPDFRenderingContextManager *)contextManager;

// Expression copying
- (instancetype)logicalCopy;    // this copies just the logical structure, without the typesetting and sprite kit derived objects and information. It is also expected to copy the codeRange variable. All subclasses must implement this or be adapted to behave correctly with an implementation of one of their superclasses.

// Code linkbacks
// This method is invoked in the parser classes to link from source code characters to the expressions they map to. It is needed because parsing operations sometimes create copies of expressions they generate (currently only when creating expressions from commands), at which time the original code->expression linkback would be lost unless it is copied.
// FIXME: it's not a very elegant solution to the linkback problem, but it works. Think whether it can be improved/refactored.
- (void)applyCodeRangeLinkbackToCode:(NSObject <MHSourceCodeString> *)code;


// Experimental stuff
- (MHLayoutType)layoutPreference;   // does the expression prefer to be laid out horizontally or vertically? Default is horizontally

@property (readonly, nullable) NSArray <MHExpression *> *attachedContent;     // returns nil by default, can be implemented by subclasses


- (nullable NSString *)mouseHoveringAuxiliaryTextWithHoveringNode:(SKNode *)node;  // defaults to nil, can be implemented by expressions that receive mouse clicks

@end





// a class that returns true to a call to the 'splittable' method is required to conform to the MHSplittableExpression protocol
@protocol MHSplittableExpression
- (NSArray <MHExpression *> *)flattenedListOfUnsplittableComponents;
@end


// a class that returns false to a call to the 'atomicForReformatting' method is required to conform to the MHDecomposableForReformatting protocol
@protocol MHDecomposableForReformatting
- (NSArray <MHExpression *> *)flattenedListOfAtomicComponentsForSlideTransitions;
@end




typedef enum {
    MHOutlinerItemStartMarker,      // start markers are the ones that store the collapsed/expanded boolean state bit
    MHOutlinerItemBeginningOfCollapsibleSectionMarker,
    MHOutlinerItemOther     // used for any situation other than the ones above
} MHOutlinerItemMarkerType;

@protocol MHOutlinerItemMarker
@property bool isCollapsed;
//- (NSString *)mouseHoveringAuxiliaryText;
@end


@protocol MHAnimatableExpression
- (void)stopAnimating;
@end


NS_ASSUME_NONNULL_END
