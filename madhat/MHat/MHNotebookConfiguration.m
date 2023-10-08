//
//  MHNotebookConfiguration.m
//  MadHat
//
//  Created by Dan Romik on 11/20/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHNotebookConfiguration.h"
#import "MHTypesettingState.h"
#import "MHParagraphStyle.h"
#import <malloc/malloc.h>


NSString * const kMHPredefinedTypesettingStateNameNormalText = @"default";
NSString * const kMHPredefinedTypesettingStateNameURLHyperlink = @"url hyperlink";
NSString * const kMHPredefinedTypesettingStateNameTextHyperlink = @"text hyperlink";
NSString * const kMHPredefinedTypesettingStateNameIntralink = @"intralink";
NSString * const kMHPredefinedTypesettingStateNameHeader = @"header";
NSString * const kMHPredefinedTypesettingStateNameSubheader = @"subheader";
NSString * const kMHPredefinedTypesettingStateNameSubsubheader = @"subsubheader";
NSString * const kMHPredefinedTypesettingStateNameParagraphHeader = @"paraheader";
NSString * const kMHPredefinedTypesettingStateNameSuperheader = @"superheader";

static const CGFloat kMHQuotedCodeDefaultBeforeAndAfterHalfSpacing = 0.75;

static MHParagraphKerningMatrix defaultParagraphKerningMatrix = {
    0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00,
    0.00, 0.00, 3.50, 1.50, 1.00, 1.00, 4.50, 0.75, 1.25, 0.75, kMHQuotedCodeDefaultBeforeAndAfterHalfSpacing,
    0.00, 2.30, 4.80, 2.80, 2.30, 2.30, 5.80, 2.05, 0.00 ,0.00, kMHQuotedCodeDefaultBeforeAndAfterHalfSpacing,
    0.00, 2.00, 4.50, 2.50, 2.00, 2.00, 5.50, 1.75, 0.00, 0.00, kMHQuotedCodeDefaultBeforeAndAfterHalfSpacing,
    0.00, 1.50, 4.00, 2.00, 1.50, 1.50, 5.00, 1.25, 0.00, 0.00, kMHQuotedCodeDefaultBeforeAndAfterHalfSpacing,
    0.00, 1.00, 3.50, 1.50, 1.00, 1.00, 4.50, 0.75, 1.25, 0.75, kMHQuotedCodeDefaultBeforeAndAfterHalfSpacing,
    0.00, 3.00, 5.50, 3.50, 3.00, 3.00, 6.50, 2.75, 1.25, 0.75, kMHQuotedCodeDefaultBeforeAndAfterHalfSpacing,
    0.00, 1.05, 3.55, 1.55, 1.05, 1.05, 4.55, 0.80, 0.00, 0.00, kMHQuotedCodeDefaultBeforeAndAfterHalfSpacing,
    0.00, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.75, 0.00, 0.00, kMHQuotedCodeDefaultBeforeAndAfterHalfSpacing,
    0.00, 1.75, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, kMHQuotedCodeDefaultBeforeAndAfterHalfSpacing,
    0.00, kMHQuotedCodeDefaultBeforeAndAfterHalfSpacing,kMHQuotedCodeDefaultBeforeAndAfterHalfSpacing,
    kMHQuotedCodeDefaultBeforeAndAfterHalfSpacing,kMHQuotedCodeDefaultBeforeAndAfterHalfSpacing,
    kMHQuotedCodeDefaultBeforeAndAfterHalfSpacing,kMHQuotedCodeDefaultBeforeAndAfterHalfSpacing,
    kMHQuotedCodeDefaultBeforeAndAfterHalfSpacing,kMHQuotedCodeDefaultBeforeAndAfterHalfSpacing,
    kMHQuotedCodeDefaultBeforeAndAfterHalfSpacing, 0.00
};


@interface MHNotebookConfiguration ()
{
    NSMutableDictionary <NSString *, MHTypesettingState *> *_predefinedTypesettingStates;
    MHParagraphKerningMatrix _paragraphKerningMatrix;
    
    MHPageGeometryParameters _pageGeometryParameters;
}

@end

@implementation MHNotebookConfiguration

- (instancetype)init
{
    if (self = [super init]) {
        _pageGeometryParameters.pageSize = NSMakeSize(MHPageSizeDefaultWidth, MHPageSizeDefaultHeight);
        
        _exportedHeaderAndFooterRange = NSMakeRange(0, NSIntegerMax);
        _lineSpacing = 1.0;
        _baseParagraphSpacing = 1.0;
        _paragraphIndent = 0.0;
        
        _pageGeometryParameters.pageLeftMargin = 72.0;     // a default left margin of one inch
        _pageGeometryParameters.pageRightMargin = 72.0;     // a default right margin of one inch
        _pageGeometryParameters.pageTopMargin = 72.0;     // a default top margin of one inch
        _pageGeometryParameters.exportedPageTopMargin = 72.0;     // a default exported top margin of one inch
        _pageGeometryParameters.pageBottomMargin = 72.0;     // a default bottom margin of one inch
        _pageGeometryParameters.exportedPageBottomMargin = 72.0;     // a default exported bottom margin of one inch
        _pageGeometryParameters.exportedPageHeaderOffset = 18.0;     // a default exported header offset of 1/4 inch
        _pageGeometryParameters.exportedPageFooterOffset = 18.0;     // a default exported footer offset of 1/4 inch

        for (int i = 0; i < MHNumberOfEffectiveParagraphTypes; i++) {
            for (int j = 0; j < MHNumberOfEffectiveParagraphTypes; j++) {
                _paragraphKerningMatrix[i][j] = defaultParagraphKerningMatrix[i][j];
            }
        }
    }
    return self;
}

- (MHTypesettingState *)defaultTypesettingState
{
    return (MHTypesettingState *)[[self predefinedTypesettingStates]
                                  objectForKey:kMHPredefinedTypesettingStateNameNormalText];
}

- (NSMutableDictionary <NSString *, MHTypesettingState *> *)predefinedTypesettingStates
{
    if (!_predefinedTypesettingStates) {
        // instantiate the predefined typesetting states mutable dictionary
        _predefinedTypesettingStates = [[NSMutableDictionary alloc] initWithCapacity:0];
        
        // load the default predefined states for normal text, links, headers etc
        _predefinedTypesettingStates[kMHPredefinedTypesettingStateNameNormalText] = [MHTypesettingState defaultState];
        _predefinedTypesettingStates[kMHPredefinedTypesettingStateNameTextHyperlink] = [MHTypesettingState defaultStateForPredefinedStyleType:MHTypesettingStatePredefinedStyleTextHyperlink];
        _predefinedTypesettingStates[kMHPredefinedTypesettingStateNameURLHyperlink] = [MHTypesettingState defaultStateForPredefinedStyleType:MHTypesettingStatePredefinedStyleURLHyperlink];
        _predefinedTypesettingStates[kMHPredefinedTypesettingStateNameIntralink] = [MHTypesettingState defaultStateForPredefinedStyleType:MHTypesettingStatePredefinedStyleIntralink];
        _predefinedTypesettingStates[kMHPredefinedTypesettingStateNameHeader] = [MHTypesettingState defaultStateForPredefinedStyleType:MHTypesettingStatePredefinedStyleHeader];
        _predefinedTypesettingStates[kMHPredefinedTypesettingStateNameSubheader] = [MHTypesettingState defaultStateForPredefinedStyleType:MHTypesettingStatePredefinedStyleSubheader];
        _predefinedTypesettingStates[kMHPredefinedTypesettingStateNameSubsubheader] = [MHTypesettingState defaultStateForPredefinedStyleType:MHTypesettingStatePredefinedStyleSubsubheader];
        _predefinedTypesettingStates[kMHPredefinedTypesettingStateNameParagraphHeader] = [MHTypesettingState defaultStateForPredefinedStyleType:MHTypesettingStatePredefinedStyleParagraphHeader];
        _predefinedTypesettingStates[kMHPredefinedTypesettingStateNameSuperheader] = [MHTypesettingState defaultStateForPredefinedStyleType:MHTypesettingStatePredefinedStyleSuperheader];
    }
    return _predefinedTypesettingStates;
}

- (MHTypesettingState *)predefinedTypesettingStateWithName:(NSString *)styleName
{
    return [self.predefinedTypesettingStates objectForKey:styleName];
}

- (void)defineTypesettingStateWithName:(NSString *)styleName as:(MHTypesettingState *)state
{
    NSMutableDictionary <NSString *, MHTypesettingState *> *predefinedTypesettingStates = self.predefinedTypesettingStates;
    predefinedTypesettingStates[styleName] = state;
}




#pragma mark - Geometry parameters

- (NSSize)pageSize
{
    return _pageGeometryParameters.pageSize;
}

- (void)setPageSize:(NSSize)pageSize
{
    _pageGeometryParameters.pageSize = pageSize;
}

- (CGFloat)pageLeftMargin
{
    return _pageGeometryParameters.pageLeftMargin;
}

- (void)setPageLeftMargin:(CGFloat)pageLeftMargin
{
    _pageGeometryParameters.pageLeftMargin = pageLeftMargin;
}

- (CGFloat)pageRightMargin
{
    return _pageGeometryParameters.pageRightMargin;
}

- (void)setPageRightMargin:(CGFloat)pageRightMargin
{
    _pageGeometryParameters.pageRightMargin = pageRightMargin;
}

- (CGFloat)pageTopMargin
{
    return _pageGeometryParameters.pageTopMargin;
}

- (void)setPageTopMargin:(CGFloat)pageTopMargin
{
    _pageGeometryParameters.pageTopMargin = pageTopMargin;
}

- (CGFloat)pageBottomMargin
{
    return _pageGeometryParameters.pageBottomMargin;
}

- (void)setPageBottomMargin:(CGFloat)pageBottomMargin
{
    _pageGeometryParameters.pageBottomMargin = pageBottomMargin;
}

- (CGFloat)exportedPageTopMargin
{
    return _pageGeometryParameters.exportedPageTopMargin;
}

- (void)setExportedPageTopMargin:(CGFloat)exportedPageTopMargin
{
    _pageGeometryParameters.exportedPageTopMargin = exportedPageTopMargin;
}

- (CGFloat)exportedPageBottomMargin
{
    return _pageGeometryParameters.exportedPageBottomMargin;
}

- (void)setExportedPageBottomMargin:(CGFloat)exportedPageBottomMargin
{
    _pageGeometryParameters.exportedPageBottomMargin = exportedPageBottomMargin;
}

- (CGFloat)exportedPageHeaderOffset
{
    return _pageGeometryParameters.exportedPageHeaderOffset;
}

- (void)setExportedPageHeaderOffset:(CGFloat)exportedPageHeaderOffset
{
    _pageGeometryParameters.exportedPageHeaderOffset = exportedPageHeaderOffset;
}

- (CGFloat)exportedPageFooterOffset
{
    return _pageGeometryParameters.exportedPageFooterOffset;
}

- (void)setExportedPageFooterOffset:(CGFloat)exportedPageFooterOffset
{
    _pageGeometryParameters.exportedPageFooterOffset = exportedPageFooterOffset;
}



#pragma mark - Other properties

- (MHParagraphKerningMatrixCastAsPointer)paragraphKerningMatrix
{
    return (MHParagraphKerningMatrixCastAsPointer)_paragraphKerningMatrix;
}

//- (void)setParagraphKerningMatrix:(MHParagraphKerningMatrixCastAsPointer)paragraphKerningMatrix
//{
//    memcpy(_paragraphKerningMatrix, paragraphKerningMatrix, sizeof(CGFloat)*MHNumberOfEffectiveParagraphTypes*MHNumberOfEffectiveParagraphTypes);
//}

- (void)setParagraphKerningMatrixPrimaryRowsAndColumns:(MHParagraphKerningMatrixCastAsPointer)matrix
{
    for (int rowIndex = 1; rowIndex < MHNumberOfEffectiveParagraphTypes-1; rowIndex++) {
        for (int columnIndex = 1; columnIndex < MHNumberOfEffectiveParagraphTypes-1; columnIndex++) {
            _paragraphKerningMatrix[rowIndex][columnIndex] =
                            matrix[rowIndex * MHNumberOfEffectiveParagraphTypes + columnIndex];
        }
    }
}

- (void)setPreparagraphSpacingAtTopOfPage:(CGFloat[MHNumberOfEffectiveParagraphTypes-2])spacingsList
{
    for (int columnIndex = 0; columnIndex < MHNumberOfEffectiveParagraphTypes-2; columnIndex++) {
        _paragraphKerningMatrix[0][columnIndex+1] = spacingsList[columnIndex];
    }
}


@end
