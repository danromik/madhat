//
//  MHConfigurationCommand.h
//  MadHat
//
//  Created by Dan Romik on 10/29/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHCommand.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum {
    // Page geometry commands:
//    MHConfigurationPageWidthCommand,      // disabling this - seems not useful, delete this code eventually
//    MHConfigurationPageHeightCommand,     // disabling this - seems not useful, delete this code eventually
    MHConfigurationPageSizeCommand,
    MHConfigurationPageLeftMarginCommand,
    MHConfigurationPageRightMarginCommand,
    MHConfigurationPageTopMarginCommand,
    MHConfigurationExportedPageTopMarginCommand,
    MHConfigurationPageBottomMarginCommand,
    MHConfigurationExportedPageBottomMarginCommand,
    MHConfigurationExportedPageHeaderOffsetCommand,
    MHConfigurationExportedPageFooterOffsetCommand,
    //
    //
    MHConfigurationNotebookTitleCommand,
    MHConfigurationNotebookAuthorCommand,
    //
    MHConfigurationExportedPageHeaderCommand,
    MHConfigurationExportedPageFooterCommand,
    MHConfigurationExportedHeaderFooterRange,
    MHConfigurationDefineStyleCommand,
    MHConfigurationLineSpacingCommand,
    MHConfigurationBaseParagraphSpacingCommand,
    MHConfigurationParagraphKerningMatrixCommand,
    MHConfigurationPreparagraphSpacingsAtTopOfPageCommand,
    MHConfigurationParagraphIndentCommand,
} MHConfigurationCommandType;

typedef enum {
    MHStandardizedPageSizeDefault = 0,
    MHStandardizedPageSizeLetterPortrait = 1,
    MHStandardizedPageSizeLetterLandscape = 2,
    MHStandardizedPageSizeA4Portrait = 3,
    MHStandardizedPageSizeA4Landscape = 4,
    MHStandardizedPageSizeLarge = 5,
    MHStandardizedPageSizeOutOfTypedefBounds = 6
} MHStandardizedPageSize;
#define MHNumberOfStandardizedPageSizes         MHStandardizedPageSizeOutOfTypedefBounds



@interface MHConfigurationCommand : MHCommand


//+ (instancetype)pageWidthCommand:(CGFloat)pageWidth;
//+ (instancetype)pageHeightCommand:(CGFloat)pageHeight;
+ (instancetype)pageSizeCommand:(NSSize)pageSize;
+ (instancetype)standardizedPageSizeCommand:(MHStandardizedPageSize)standardizedPageSize;
+ (instancetype)notebookTitleCommand:(NSString *)notebookTitle;
+ (instancetype)notebookAuthorCommand:(NSString *)notebookAuthor;
+ (instancetype)pageHeaderCommand:(MHExpression *)pageHeader;
+ (instancetype)pageFooterCommand:(MHExpression *)pageFooter;
+ (instancetype)headerAndFooterRangeCommand:(NSRange)range;
+ (instancetype)defineStyleCommand:(NSString *)styleName
                styleToInheritFrom:(nullable NSString *)styleToInheritFromName
           styleDefiningExpression:(MHExpression *)expression;
+ (instancetype)lineSpacingCommand:(CGFloat)spacing;
+ (instancetype)baseParagraphSpacingCommand:(CGFloat)spacing;
+ (instancetype)paragraphKerningMatrixCommand:(MHParagraphKerningMatrix _Nonnull)matrix;
+ (instancetype)paragraphIndentCommand:(CGFloat)indent;




@end

NS_ASSUME_NONNULL_END
