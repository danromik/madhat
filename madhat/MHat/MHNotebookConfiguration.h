//
//  MHNotebookConfiguration.h
//  MadHat
//
//  Created by Dan Romik on 11/20/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MadHat.h"

extern NSString * _Nonnull const kMHPredefinedTypesettingStateNameNormalText;
extern NSString * _Nonnull const kMHPredefinedTypesettingStateNameURLHyperlink;
extern NSString * _Nonnull const kMHPredefinedTypesettingStateNameTextHyperlink;
extern NSString * _Nonnull const kMHPredefinedTypesettingStateNameIntralink;
extern NSString * _Nonnull const kMHPredefinedTypesettingStateNameHeader;
extern NSString * _Nonnull const kMHPredefinedTypesettingStateNameSubheader;
extern NSString * _Nonnull const kMHPredefinedTypesettingStateNameSubsubheader;
extern NSString * _Nonnull const kMHPredefinedTypesettingStateNameParagraphHeader;
extern NSString * _Nonnull const kMHPredefinedTypesettingStateNameSuperheader;


typedef struct {
    NSSize pageSize;
    CGFloat pageLeftMargin;
    CGFloat pageRightMargin;
    CGFloat pageTopMargin;
    CGFloat exportedPageTopMargin;
    CGFloat pageBottomMargin;
    CGFloat exportedPageBottomMargin;
    CGFloat exportedPageHeaderOffset;
    CGFloat exportedPageFooterOffset;
} MHPageGeometryParameters;




NS_ASSUME_NONNULL_BEGIN

@class MHExpression;
@class MHTypesettingState;
@interface MHNotebookConfiguration : NSObject


// page geometry settings
@property (readonly) MHPageGeometryParameters pageGeometryParameters;
@property NSSize pageSize;  // the page width and height in points
@property CGFloat pageLeftMargin;
@property CGFloat pageRightMargin;
@property CGFloat pageTopMargin;
@property CGFloat exportedPageTopMargin;
@property CGFloat pageBottomMargin;
@property CGFloat exportedPageBottomMargin;
@property CGFloat exportedPageHeaderOffset;
@property CGFloat exportedPageFooterOffset;




@property (nullable) NSString *notebookTitle;
@property (nullable) NSString *notebookAuthor;
@property (nullable) MHExpression *exportedPageHeader;
@property (nullable) MHExpression *exportedPageFooter;
@property NSRange exportedHeaderAndFooterRange;
@property (readonly) MHTypesettingState *defaultTypesettingState;
@property (readonly) NSMutableDictionary <NSString *, MHTypesettingState *> *predefinedTypesettingStates;

@property CGFloat lineSpacing;              // measured in multiples of the current font's line height (ascender+(-descender)+leading), note that the descender returned by the NSFont API is negative so it gets added with a minus sign in front  // FIXME: leading returns 0, not sure why
@property CGFloat baseParagraphSpacing;     // measured in multiples of the current font's point size
@property CGFloat paragraphIndent;          // measured in multiples of the current font's point size

@property (readonly) MHParagraphKerningMatrixCastAsPointer paragraphKerningMatrix;
- (void)setParagraphKerningMatrixPrimaryRowsAndColumns:(MHParagraphKerningMatrixCastAsPointer)matrix;   // this uses matrix to set the primary submatrix of the paragraph kerning matrix (excluding the first and last row and column)
- (void)setPreparagraphSpacingAtTopOfPage:(CGFloat[_Nonnull MHNumberOfEffectiveParagraphTypes-2])spacingsList;    // the vector gets copied


- (MHTypesettingState *)predefinedTypesettingStateWithName:(NSString *)styleName;
- (void)defineTypesettingStateWithName:(NSString *)styleName as:(MHTypesettingState *)state;

@end

NS_ASSUME_NONNULL_END
