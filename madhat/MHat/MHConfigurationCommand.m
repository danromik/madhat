//
//  MHConfigurationCommand.m
//  MadHat
//
//  Created by Dan Romik on 10/29/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHConfigurationCommand.h"
#import "MHTypesettingContextManager+TypingStyle.h"
#import "MHStyleIncludes.h"
#import <objc/runtime.h>

#define MHNumberOfParagraphTypesForCustomization   (MHNumberOfEffectiveParagraphTypes-2)
typedef CGFloat MHParagraphSpacingsConfigurationVector[MHNumberOfParagraphTypesForCustomization];

//static NSString * const kMHConfigurationCommandPageWidthCommandName = @"⌘page width";
//static NSString * const kMHConfigurationCommandPageHeightCommandName = @"⌘page height";
static NSString * const kMHConfigurationCommandPageSizeCommandName = @"⌘page size";
static NSString * const kMHConfigurationCommandPageLeftMarginCommandName = @"⌘left margin";
static NSString * const kMHConfigurationCommandPageRightMarginCommandName = @"⌘right margin";
static NSString * const kMHConfigurationCommandPageTopMarginCommandName = @"⌘top margin";
static NSString * const kMHConfigurationCommandExportedPageTopMarginCommandName = @"⌘exported top margin";
static NSString * const kMHConfigurationCommandPageBottomMarginCommandName = @"⌘bottom margin";
static NSString * const kMHConfigurationCommandExportedPageBottomMarginCommandName = @"⌘exported bottom margin";

static NSString * const kMHConfigurationCommandNotebookTitleCommandName = @"⌘notebook title";
static NSString * const kMHConfigurationCommandNotebookAuthorCommandName = @"⌘notebook author";

static NSString * const kMHConfigurationCommandExportedPageHeaderCommandName = @"⌘exported page header";
static NSString * const kMHConfigurationCommandExportedPageFooterCommandName = @"⌘exported page footer";
static NSString * const kMHConfigurationCommandExportedHeaderFooterRangeCommandName = @"⌘exported header and footer range";
static NSString * const kMHConfigurationCommandExportedHeaderOffsetCommandName = @"⌘exported header offset";
static NSString * const kMHConfigurationCommandExportedFooterOffsetCommandName = @"⌘exported footer offset";


static NSString * const kMHConfigurationCommandDefineStyleCommandName = @"⌘define style";
static NSString * const kMHConfigurationCommandLineSpacingCommandName   = @"⌘line spacing";
static NSString * const kMHConfigurationCommandBaseParagraphSpacingCommandName   = @"⌘base paragraph spacing";
static NSString * const kMHConfigurationCommandParagraphKerningCommandName = @"⌘paragraph spacings matrix";
static NSString * const kMHConfigurationCommandParagraphBeforeAfterSpacingsCommandName = @"⌘paragraph before and after spacings";
static NSString * const kMHConfigurationCommandPreparagraphSpacingsAtTopOfPageCommandName = @"⌘top of page preparagraph spacings";
static NSString * const kMHConfigurationCommandParagraphIndentCommandName   = @"⌘paragraph indent";

static NSString * const kMHConfigurationCommandInheritsFromStyleAttributeName = @"inherits from";

static NSString * const kMHStandardizedPageSizeCommandValueDefault = @"default";
static NSString * const kMHStandardizedPageSizeCommandValueLetterPortrait = @"letter portrait";
static NSString * const kMHStandardizedPageSizeCommandValueLetterPortraitAlias = @"letter";
static NSString * const kMHStandardizedPageSizeCommandValueLetterLandscape = @"letter landscape";
static NSString * const kMHStandardizedPageSizeCommandValueA4Portrait = @"a4 portrait";
static NSString * const kMHStandardizedPageSizeCommandValueA4PortraitAlias = @"a4";
static NSString * const kMHStandardizedPageSizeCommandValueA4Landscape = @"a4 landscape";
static NSString * const kMHStandardizedPageSizeCommandValueLarge = @"large";



@interface MHHorizontalLayoutContainerWithLocalScopingDisabled : MHHorizontalLayoutContainer
@end



@interface MHConfigurationCommand ()
{
    MHConfigurationCommandType _type;
    NSSize _pageSize;
    NSString *_stringInfo;   // used for notebook title and author, define style
    MHExpression *_expressionInfo;      // used for exported page header and footer, define style
    NSRange _headerAndFooterRange;  // used to specify the range of pages to add a header and footer to
    NSString *_styleToInheritFromName;  // used for style defining commands
    CGFloat *_vectorOrMatrix;   // used by commands that set the paragraph kerning matrix or some of its rows/columns
    CGFloat _floatValue;  // used for storing the line spacing, base paragraph spacing, and paragraph indent parameters
}

@end

@implementation MHConfigurationCommand

#pragma mark - Constructors

//+ (instancetype)pageWidthCommand:(CGFloat)pageWidth
//{
//    return [[self alloc] initWithPageWidth:pageWidth];
//}
//
//- (instancetype)initWithPageWidth:(CGFloat)pageWidth
//{
//    if (self = [super init]) {
//        _type = MHConfigurationPageWidthCommand;
//        _pageSize.width = (pageWidth < MHPageSizeMinimumWidth ? MHPageSizeMinimumWidth :
//                           (pageWidth > MHPageSizeMaximumWidth ? MHPageSizeMaximumWidth : pageWidth));
//    }
//    return self;
//}
//
//+ (instancetype)pageHeightCommand:(CGFloat)pageHeight
//{
//    return [[self alloc] initWithPageHeight:pageHeight];
//}
//
//- (instancetype)initWithPageHeight:(CGFloat)pageHeight
//{
//    if (self = [super init]) {
//        _type = MHConfigurationPageHeightCommand;
//        _pageSize.height = (pageHeight < MHPageSizeMinimumHeight ? MHPageSizeMinimumHeight :
//                            (pageHeight > MHPageSizeMaximumHeight ? MHPageSizeMaximumHeight : pageHeight));
//    }
//    return self;
//}

+ (instancetype)pageSizeCommand:(NSSize)pageSize
{
    return [[self alloc] initWithPageSize:pageSize];
}

- (instancetype)initWithPageSize:(NSSize)pageSize
{
    if (self = [super init]) {
        _type = MHConfigurationPageSizeCommand;
        _pageSize.width = (pageSize.width < MHPageSizeMinimumWidth ? MHPageSizeMinimumWidth :
                           (pageSize.width > MHPageSizeMaximumWidth ? MHPageSizeMaximumWidth : pageSize.width));
        _pageSize.height = (pageSize.height < MHPageSizeMinimumHeight ? MHPageSizeMinimumHeight :
                            (pageSize.height > MHPageSizeMaximumHeight ? MHPageSizeMaximumHeight : pageSize.height));

    }
    return self;
}

+ (instancetype)standardizedPageSizeCommand:(MHStandardizedPageSize)standardizedPageSize
{
    NSSize pageSize;

    switch (standardizedPageSize) {
        case MHStandardizedPageSizeLetterPortrait:
            pageSize = NSMakeSize(MHPageSizeLetterWidth, MHPageSizeLetterHeight);
            break;
        case MHStandardizedPageSizeLetterLandscape:
            pageSize = NSMakeSize(MHPageSizeLetterHeight, MHPageSizeLetterWidth);
            break;
        case MHStandardizedPageSizeA4Portrait:
            pageSize = NSMakeSize(MHPageSizeA4Width, MHPageSizeA4Height);
            break;
        case MHStandardizedPageSizeA4Landscape:
            pageSize = NSMakeSize(MHPageSizeA4Height, MHPageSizeA4Width);
            break;
        case MHStandardizedPageSizeLarge:
            pageSize = NSMakeSize(1600.0, 900.0);
            break;
        case MHStandardizedPageSizeDefault:
        default:
            pageSize = NSMakeSize(MHPageSizeDefaultWidth, MHPageSizeDefaultHeight);
            break;
    }

//    pageSize.width *= paperToScreenScalingFactor;
//    pageSize.height *= paperToScreenScalingFactor;
    
    return [self pageSizeCommand:pageSize];
}

+ (instancetype)pageLeftMarginCommand:(CGFloat)leftMargin
{
    return [[self alloc] initWithPageLeftMarginCommand:leftMargin];
}

- (instancetype)initWithPageLeftMarginCommand:(CGFloat)leftMargin
{
    if (self = [super init]) {
        _type = MHConfigurationPageLeftMarginCommand;
        _floatValue = leftMargin;
    }
    return self;
}

+ (instancetype)pageRightMarginCommand:(CGFloat)rightMargin
{
    return [[self alloc] initWithPageRightMarginCommand:rightMargin];
}

- (instancetype)initWithPageRightMarginCommand:(CGFloat)rightMargin
{
    if (self = [super init]) {
        _type = MHConfigurationPageRightMarginCommand;
        _floatValue = rightMargin;
    }
    return self;
}

+ (instancetype)pageTopMarginCommand:(CGFloat)topMargin
{
    return [[self alloc] initWithPageTopMarginCommand:topMargin];
}

- (instancetype)initWithPageTopMarginCommand:(CGFloat)topMargin
{
    if (self = [super init]) {
        _type = MHConfigurationPageTopMarginCommand;
        _floatValue = topMargin;
    }
    return self;
}

+ (instancetype)exportedPageTopMarginCommand:(CGFloat)topMargin
{
    return [[self alloc] initWithExportedPageTopMarginCommand:topMargin];
}

- (instancetype)initWithExportedPageTopMarginCommand:(CGFloat)topMargin
{
    if (self = [super init]) {
        _type = MHConfigurationExportedPageTopMarginCommand;
        _floatValue = topMargin;
    }
    return self;
}

+ (instancetype)pageBottomMarginCommand:(CGFloat)bottomMargin
{
    return [[self alloc] initWithPageBottomMarginCommand:bottomMargin];
}

- (instancetype)initWithPageBottomMarginCommand:(CGFloat)bottomMargin
{
    if (self = [super init]) {
        _type = MHConfigurationPageBottomMarginCommand;
        _floatValue = bottomMargin;
    }
    return self;
}

+ (instancetype)exportedPageBottomMarginCommand:(CGFloat)bottomMargin
{
    return [[self alloc] initWithExportedPageBottomMarginCommand:bottomMargin];
}

- (instancetype)initWithExportedPageBottomMarginCommand:(CGFloat)bottomMargin
{
    if (self = [super init]) {
        _type = MHConfigurationExportedPageBottomMarginCommand;
        _floatValue = bottomMargin;
    }
    return self;
}

+ (instancetype)exportedPageHeaderOffsetCommand:(CGFloat)headerOffset
{
    return [[self alloc] initWithExportedPageHeaderOffsetCommand:headerOffset];
}

- (instancetype)initWithExportedPageHeaderOffsetCommand:(CGFloat)headerOffset
{
    if (self = [super init]) {
        _type = MHConfigurationExportedPageHeaderOffsetCommand;
        _floatValue = headerOffset;
    }
    return self;
}

+ (instancetype)exportedPageFooterOffsetCommand:(CGFloat)footerOffset
{
    return [[self alloc] initWithExportedPageFooterOffsetCommand:footerOffset];
}

- (instancetype)initWithExportedPageFooterOffsetCommand:(CGFloat)footerOffset
{
    if (self = [super init]) {
        _type = MHConfigurationExportedPageFooterOffsetCommand;
        _floatValue = footerOffset;
    }
    return self;
}





+ (instancetype)notebookTitleCommand:(NSString *)notebookTitle
{
    return [[self alloc] initWithNotebookTitle:notebookTitle];
}

- (instancetype)initWithNotebookTitle:(NSString *)notebookTitle
{
    if (self = [super init]) {
        _type = MHConfigurationNotebookTitleCommand;
        _stringInfo = notebookTitle;
    }
    return self;
}


+ (instancetype)notebookAuthorCommand:(NSString *)notebookAuthor
{
    return [[self alloc] initWithNotebookAuthor:notebookAuthor];
}

- (instancetype)initWithNotebookAuthor:(NSString *)notebookAuthor
{
    if (self = [super init]) {
        _type = MHConfigurationNotebookAuthorCommand;
        _stringInfo = notebookAuthor;
    }
    return self;
}

+ (instancetype)defineStyleCommand:(NSString *)styleName
                styleToInheritFrom:(NSString *)styleToInheritFromName
           styleDefiningExpression:(MHExpression *)expression
{
    return [[self alloc] initWithDefineStyleCommand:styleName
                                 styleToInheritFrom:styleToInheritFromName
                            styleDefiningExpression:expression];
}

- (instancetype)initWithDefineStyleCommand:(NSString *)styleName
                        styleToInheritFrom:(NSString *)styleToInheritFromName
                   styleDefiningExpression:expression
{
    if (self = [super init]) {
        _type = MHConfigurationDefineStyleCommand;
        _stringInfo = styleName;
        _styleToInheritFromName = styleToInheritFromName;
        _expressionInfo = expression;
    }
    return self;
}

+ (instancetype)pageHeaderCommand:(MHExpression *)pageHeader
{
    return [[self alloc] initWithPageHeader:pageHeader];
}

- (instancetype)initWithPageHeader:(MHExpression *)pageHeader
{
    if (self = [super init]) {
        _type = MHConfigurationExportedPageHeaderCommand;
        _expressionInfo = pageHeader;
    }
    return self;
}

+ (instancetype)pageFooterCommand:(MHExpression *)pageFooter
{
    return [[self alloc] initWithPageFooter:pageFooter];
}

- (instancetype)initWithPageFooter:(MHExpression *)pageFooter
{
    if (self = [super init]) {
        _type = MHConfigurationExportedPageFooterCommand;
        _expressionInfo = pageFooter;
    }
    return self;
}

+ (instancetype)headerAndFooterRangeCommand:(NSRange)range
{
    return [[self alloc] initWithHeaderAndFooterRangeCommand:range];
}

- (instancetype)initWithHeaderAndFooterRangeCommand:(NSRange)range
{
    if (self = [super init]) {
        _type = MHConfigurationExportedHeaderFooterRange;
        _headerAndFooterRange = range;
    }
    return self;
}

+ (instancetype)lineSpacingCommand:(CGFloat)spacing
{
    return [[self alloc] initWithLineSpacingCommand:spacing];
}

- (instancetype)initWithLineSpacingCommand:(CGFloat)spacing
{
    if (self = [super init]) {
        _type = MHConfigurationLineSpacingCommand;
        _floatValue = spacing;
    }
    return self;
}

+ (instancetype)baseParagraphSpacingCommand:(CGFloat)spacing
{
    return [[self alloc] initWithBaseParagraphSpacingCommand:spacing];
}

- (instancetype)initWithBaseParagraphSpacingCommand:(CGFloat)spacing
{
    if (self = [super init]) {
        _type = MHConfigurationBaseParagraphSpacingCommand;
        _floatValue = spacing;
    }
    return self;
}

+ (instancetype)paragraphIndentCommand:(CGFloat)indent
{
    return [[self alloc] initWithParagraphIndentCommand:indent];
}

- (instancetype)initWithParagraphIndentCommand:(CGFloat)indent
{
    if (self = [super init]) {
        _type = MHConfigurationParagraphIndentCommand;
        _floatValue = indent;
    }
    return self;
}


+ (instancetype)paragraphKerningMatrixCommand:(MHParagraphKerningMatrix)matrix
{
    return [[self alloc] initWithParagraphKerningMatrixCommand:matrix];
}

- (instancetype)initWithParagraphKerningMatrixCommand:(MHParagraphKerningMatrix)matrix
{
    if (self = [super init]) {
        _type = MHConfigurationParagraphKerningMatrixCommand;
        _vectorOrMatrix = malloc(sizeof(CGFloat)*MHNumberOfEffectiveParagraphTypes*MHNumberOfEffectiveParagraphTypes);
        memcpy(_vectorOrMatrix, matrix,
               sizeof(CGFloat)*MHNumberOfEffectiveParagraphTypes*MHNumberOfEffectiveParagraphTypes);
    }
    return self;
}

+ (instancetype)preparagraphSpacingsAtTopOfPageCommandWithSpacings:(MHParagraphSpacingsConfigurationVector)spacings
{
    return [[self alloc] initWithPreparagraphSpacingsAtTopOfPageCommandWithSpacings:spacings];
}

- (instancetype)initWithPreparagraphSpacingsAtTopOfPageCommandWithSpacings:
                        (MHParagraphSpacingsConfigurationVector)spacings
{
    if (self = [super init]) {
        _type = MHConfigurationPreparagraphSpacingsAtTopOfPageCommand;
        _vectorOrMatrix = malloc(sizeof(CGFloat)*MHNumberOfParagraphTypesForCustomization);
        memcpy(_vectorOrMatrix, spacings,
               sizeof(CGFloat)*MHNumberOfParagraphTypesForCustomization);
    }
    return self;
}

- (void)dealloc
{
    if ((_type == MHConfigurationParagraphKerningMatrixCommand)
        || (_type == MHConfigurationPreparagraphSpacingsAtTopOfPageCommand)) {
        free(_vectorOrMatrix);
    }
}



#pragma mark - MHCommand protocol

+ (MHExpression *)commandNamed:(NSString *)name withParameters:(NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument
{
    // FIXME: configuration commands should only be interpreted by the parser in the configuration code, not in a normal notebook page
    
//    if ([name isEqualToString:kMHConfigurationCommandPageWidthCommandName]) {
//        return [MHConfigurationCommand pageWidthCommand:[argument floatValue]];
//    }
//    if ([name isEqualToString:kMHConfigurationCommandPageHeightCommandName]) {
//        return [MHConfigurationCommand pageHeightCommand:[argument floatValue]];
//    }
    if ([name isEqualToString:kMHConfigurationCommandPageSizeCommandName]) {
        if ([argument numberOfDelimitedBlocks] == 1) {
            // look for a keyword describing one of the standardized page sizes
            NSString *standardizedPageSizeKeyword = [argument stringValue];
            MHStandardizedPageSize standardizedPageSize;
            if ([standardizedPageSizeKeyword isEqualToString:kMHStandardizedPageSizeCommandValueDefault])
                standardizedPageSize = MHStandardizedPageSizeDefault;
            else if ([standardizedPageSizeKeyword isEqualToString:kMHStandardizedPageSizeCommandValueLetterPortrait]
                     || [standardizedPageSizeKeyword isEqualToString:kMHStandardizedPageSizeCommandValueLetterPortraitAlias])
                standardizedPageSize = MHStandardizedPageSizeLetterPortrait;
            else if ([standardizedPageSizeKeyword isEqualToString:kMHStandardizedPageSizeCommandValueLetterLandscape])
                standardizedPageSize = MHStandardizedPageSizeLetterLandscape;
            else if ([standardizedPageSizeKeyword isEqualToString:kMHStandardizedPageSizeCommandValueA4Portrait]
                     || [standardizedPageSizeKeyword isEqualToString:kMHStandardizedPageSizeCommandValueA4PortraitAlias])
                standardizedPageSize = MHStandardizedPageSizeA4Portrait;
            else if ([standardizedPageSizeKeyword isEqualToString:kMHStandardizedPageSizeCommandValueA4Landscape])
                standardizedPageSize = MHStandardizedPageSizeA4Landscape;
            else if ([standardizedPageSizeKeyword isEqualToString:kMHStandardizedPageSizeCommandValueLarge])
                standardizedPageSize = MHStandardizedPageSizeLarge;
            else
                return nil;     // couldn't find a valid keyword
            
            return [self standardizedPageSizeCommand:standardizedPageSize];
        }
        else {
            // we have at least two arguments, so read the first argument as the page width and the second as the page height
            MHExpression *widthBlock = [argument expressionFromDelimitedBlockAtIndex:0];
            MHExpression *heightBlock = [argument expressionFromDelimitedBlockAtIndex:1];
            return [self pageSizeCommand:NSMakeSize([widthBlock floatValue], [heightBlock floatValue])];
        }
    }
    if ([name isEqualToString:kMHConfigurationCommandPageLeftMarginCommandName]) {
        return [MHConfigurationCommand pageLeftMarginCommand:[argument floatValue]];
    }
    if ([name isEqualToString:kMHConfigurationCommandPageRightMarginCommandName]) {
        return [MHConfigurationCommand pageRightMarginCommand:[argument floatValue]];
    }
    if ([name isEqualToString:kMHConfigurationCommandPageTopMarginCommandName]) {
        return [MHConfigurationCommand pageTopMarginCommand:[argument floatValue]];
    }
    if ([name isEqualToString:kMHConfigurationCommandExportedPageTopMarginCommandName]) {
        return [MHConfigurationCommand exportedPageTopMarginCommand:[argument floatValue]];
    }
    if ([name isEqualToString:kMHConfigurationCommandPageBottomMarginCommandName]) {
        return [MHConfigurationCommand pageBottomMarginCommand:[argument floatValue]];
    }
    if ([name isEqualToString:kMHConfigurationCommandExportedPageBottomMarginCommandName]) {
        return [MHConfigurationCommand exportedPageBottomMarginCommand:[argument floatValue]];
    }
    if ([name isEqualToString:kMHConfigurationCommandExportedHeaderOffsetCommandName]) {
        return [MHConfigurationCommand exportedPageHeaderOffsetCommand:[argument floatValue]];
    }
    if ([name isEqualToString:kMHConfigurationCommandExportedFooterOffsetCommandName]) {
        return [MHConfigurationCommand exportedPageFooterOffsetCommand:[argument floatValue]];
    }
    if ([name isEqualToString:kMHConfigurationCommandNotebookTitleCommandName]) {
        return [MHConfigurationCommand notebookTitleCommand:[argument stringValue]];
    }
    if ([name isEqualToString:kMHConfigurationCommandNotebookAuthorCommandName]) {
        return [MHConfigurationCommand notebookAuthorCommand:[argument stringValue]];
    }
    if ([name isEqualToString:kMHConfigurationCommandExportedPageHeaderCommandName]) {
        return [MHConfigurationCommand pageHeaderCommand:argument];
    }
    if ([name isEqualToString:kMHConfigurationCommandExportedPageFooterCommandName]) {
        return [MHConfigurationCommand pageFooterCommand:argument];
    }
    if ([name isEqualToString:kMHConfigurationCommandExportedHeaderFooterRangeCommandName]) {
        if ([argument numberOfDelimitedBlocks] >= 2) {
            NSRange range;
            MHExpression *firstArgument = [argument expressionFromDelimitedBlockAtIndex:0];
            MHExpression *secondArgument = [argument expressionFromDelimitedBlockAtIndex:1];
            range.location = [firstArgument intValue];
            NSString *secondArgumentString = [secondArgument stringValue];
            if (secondArgumentString.length == 0)
                range.length = NSIntegerMax;
            else
                range.length = [secondArgumentString integerValue] - range.location + 1;
            return [MHConfigurationCommand headerAndFooterRangeCommand:range];
        }
    }
    if ([name isEqualToString:kMHConfigurationCommandDefineStyleCommandName]) {
        if ([argument numberOfDelimitedBlocks] >= 2) {
            MHExpression *styleNameArgument = [argument expressionFromDelimitedBlockAtIndex:0];
            MHExpression *styleDefiningExpression = [argument expressionFromDelimitedBlockAtIndex:1];
            NSString *styleName = [styleNameArgument stringValue];
            
            NSDictionary *attributes = argument.attributes;
            MHExpression *inheritsFromExpression = attributes[kMHConfigurationCommandInheritsFromStyleAttributeName];
            NSString *styleToInheritFromName = [inheritsFromExpression stringValue];
            
            return [MHConfigurationCommand defineStyleCommand:styleName
                                           styleToInheritFrom:styleToInheritFromName
                                      styleDefiningExpression:styleDefiningExpression];
        }
    }
    if ([name isEqualToString:kMHConfigurationCommandLineSpacingCommandName]) {
        return [self lineSpacingCommand:[argument floatValue]];
    }
    if ([name isEqualToString:kMHConfigurationCommandBaseParagraphSpacingCommandName]) {
        return [self baseParagraphSpacingCommand:[argument floatValue]];
    }
    if ([name isEqualToString:kMHConfigurationCommandParagraphIndentCommandName]) {
        return [self paragraphIndentCommand:[argument floatValue]];
    }
    if ([name isEqualToString:kMHConfigurationCommandParagraphKerningCommandName]) {
        NSArray <NSArray <MHExpression *> *> *argumentMatrix = [argument delimitedBlockTable];
        // check that the dimensions of the table are correct
        NSUInteger numberOfRows = argumentMatrix.count;
        if (numberOfRows == MHNumberOfParagraphTypesForCustomization) {
            // we have the correct number of rows, now check that each row contains the right number of entries
            BOOL tableOfCorrectDimensions = YES;
            NSUInteger rowIndex;
            for (rowIndex = 0; rowIndex < MHNumberOfParagraphTypesForCustomization; rowIndex++) {
                if (argumentMatrix[rowIndex].count != MHNumberOfParagraphTypesForCustomization) {
                    tableOfCorrectDimensions = NO;
                    break;
                }
            }
            
            if (tableOfCorrectDimensions) {
                
                // If we reached this part of the code, we have a square array of numbers of width and height MHNumberOfParagraphTypesForCustomization provided to us as arguments. We will use it to fill up most of the rows and columns of the paragraph kerning matrix, with the following exceptions:
                // 1. The first row of the matrix is not filled. The entries of that row correspond to spacings inserted before a paragraph of a given type at the top of the page, so we'll have a separate configuration command kMHConfigurationCommandPreparagraphSpacingsAtTopOfPageCommandName to customize those spacings (but still ultimately store them in the paragraph kerning matrix)
                // 2. The first column of the matrix is not filled. Those numbers are in any case not used by the paragraph kerning algorithm
                // 3. The last row and column of the matrix is not filled, since that corresponds to spacings between various types of paragraphs and a quoted code paragraph (paragraph type MHParagraphQuotedCodeParagraph). Quoted code paragraphs are not designed to be a user-facing feature so those spacings are not configurable from the notebook configuration code
                
                MHParagraphKerningMatrix matrix;
                for (rowIndex = 0; rowIndex < MHNumberOfParagraphTypesForCustomization; rowIndex++) {
                    NSArray <MHExpression *> *row = argumentMatrix[rowIndex];
                    for (NSUInteger columnIndex = 0; columnIndex < MHNumberOfParagraphTypesForCustomization; columnIndex++) {
                        MHExpression *matrixEntry = row[columnIndex];
                        CGFloat matrixEntryValue = [matrixEntry floatValue];
                        matrix[rowIndex+1][columnIndex+1] = matrixEntryValue;
                    }
                }
                return [self paragraphKerningMatrixCommand:matrix];
            }
        }
    }
    if ([name isEqualToString:kMHConfigurationCommandParagraphBeforeAfterSpacingsCommandName]) {
        NSArray <NSArray <MHExpression *> *> *argumentMatrix = [argument delimitedBlockTable];
        // check that the dimensions of the table are correct - we are expecting 2 rows and MHNumberOfParagraphTypesForCustomization columns
        NSUInteger numberOfRows = argumentMatrix.count;
        if (numberOfRows == 2) {
            // we have the correct number of rows, now check that each row contains the right number of entries
            BOOL tableOfCorrectDimensions = YES;
            NSUInteger rowIndex, columnIndex;
            for (rowIndex = 0; rowIndex < 2; rowIndex++) {
                if (argumentMatrix[rowIndex].count != MHNumberOfParagraphTypesForCustomization) {
                    tableOfCorrectDimensions = NO;
                    break;
                }
            }
            
            if (tableOfCorrectDimensions) {
                
                // If we reached this part of the code, we have an array of numbers with two rows and MHNumberOfParagraphTypesForCustomization columns provided to us as arguments. We interpret the first row as giving pre-paragraph spacing values for the customizable spacing types, and the second row as giving post-paragraph spacing values. These values are used to fill the customizable-part of the paragraph kerning matrix (the same part that is filled by the kMHConfigurationCommandParagraphKerningCommandName command, as described above)
                
                MHParagraphSpacingsConfigurationVector preParagraphSpacings;
                MHParagraphSpacingsConfigurationVector postParagraphSpacings;
                NSArray <MHExpression *> *row;
                
                // read the preparagraph spacings row
                row = argumentMatrix[0];
                for (columnIndex = 0; columnIndex < MHNumberOfParagraphTypesForCustomization; columnIndex++) {
                    MHExpression *spacingExpression = row[columnIndex];
                    preParagraphSpacings[columnIndex] = [spacingExpression floatValue];
                }

                // read the postparagraph spacings row
                row = argumentMatrix[1];
                for (columnIndex = 0; columnIndex < MHNumberOfParagraphTypesForCustomization; columnIndex++) {
                    MHExpression *spacingExpression = row[columnIndex];
                    postParagraphSpacings[columnIndex] = [spacingExpression floatValue];
                }

                // now create the matrix using the values from these two spacing value vectors
                MHParagraphKerningMatrix matrix;
                for (rowIndex = 0; rowIndex < MHNumberOfParagraphTypesForCustomization; rowIndex++) {
                    for (columnIndex = 0; columnIndex < MHNumberOfParagraphTypesForCustomization; columnIndex++) {
                        matrix[rowIndex+1][columnIndex+1] =
                                    postParagraphSpacings[rowIndex] + preParagraphSpacings[columnIndex];
                    }
                }
                return [self paragraphKerningMatrixCommand:matrix];
            }
        }
    }
    if ([name isEqualToString:kMHConfigurationCommandPreparagraphSpacingsAtTopOfPageCommandName]) {
        if ([argument numberOfDelimitedBlocks] == MHNumberOfParagraphTypesForCustomization) {
            MHParagraphSpacingsConfigurationVector spacingsList;
//            CGFloat spacingsList[MHNumberOfEffectiveParagraphTypes-2];
            for (NSUInteger index = 0; index < MHNumberOfParagraphTypesForCustomization; index++) {
                MHExpression *blockExpression = [argument expressionFromDelimitedBlockAtIndex:index];
                spacingsList[index] = [blockExpression floatValue];
            }
            return [self preparagraphSpacingsAtTopOfPageCommandWithSpacings:spacingsList];
        }
    }
    return nil;
}

+ (NSArray <NSString *> *)recognizedCommands
{
    return @[
        kMHConfigurationCommandPageSizeCommandName,
        kMHConfigurationCommandPageLeftMarginCommandName,
        kMHConfigurationCommandPageRightMarginCommandName,
        kMHConfigurationCommandPageTopMarginCommandName,
        kMHConfigurationCommandExportedPageTopMarginCommandName,
        kMHConfigurationCommandPageBottomMarginCommandName,
        kMHConfigurationCommandExportedHeaderOffsetCommandName,
        kMHConfigurationCommandExportedFooterOffsetCommandName,
        kMHConfigurationCommandExportedPageBottomMarginCommandName,
        kMHConfigurationCommandNotebookTitleCommandName,
        kMHConfigurationCommandNotebookAuthorCommandName,
        kMHConfigurationCommandExportedPageHeaderCommandName,
        kMHConfigurationCommandExportedPageFooterCommandName,
        kMHConfigurationCommandExportedHeaderFooterRangeCommandName,
        kMHConfigurationCommandDefineStyleCommandName,
        kMHConfigurationCommandLineSpacingCommandName,
        kMHConfigurationCommandBaseParagraphSpacingCommandName,
        kMHConfigurationCommandParagraphIndentCommandName,
        kMHConfigurationCommandParagraphBeforeAfterSpacingsCommandName,
        kMHConfigurationCommandPreparagraphSpacingsAtTopOfPageCommandName,
        kMHConfigurationCommandParagraphKerningCommandName
    ];
}


#pragma mark - Typesetting

- (void)typesetWithContextManager:(MHTypesettingContextManager *)contextManager
{
    switch (_type) {
//        case MHConfigurationPageWidthCommand:
//            [contextManager setPageWidth:_pageSize.width];
//            break;
//        case MHConfigurationPageHeightCommand:
//            [contextManager setPageHeight:_pageSize.height];
//            break;
        case MHConfigurationPageSizeCommand:
            [contextManager setPageSize:_pageSize];
            break;
        case MHConfigurationPageLeftMarginCommand:
            [contextManager setPageLeftMargin:_floatValue];
            break;
        case MHConfigurationPageRightMarginCommand:
            [contextManager setPageRightMargin:_floatValue];
            break;
        case MHConfigurationPageTopMarginCommand:
            [contextManager setPageTopMargin:_floatValue];
            break;
        case MHConfigurationExportedPageTopMarginCommand:
            [contextManager setExportedPageTopMargin:_floatValue];
            break;
        case MHConfigurationPageBottomMarginCommand:
            [contextManager setPageBottomMargin:_floatValue];
            break;
        case MHConfigurationExportedPageBottomMarginCommand:
            [contextManager setExportedPageBottomMargin:_floatValue];
            break;
        case MHConfigurationExportedPageHeaderOffsetCommand:
            [contextManager setExportedPageHeaderOffset:_floatValue];
            break;
        case MHConfigurationExportedPageFooterOffsetCommand:
            [contextManager setExportedPageFooterOffset:_floatValue];
            break;
        case MHConfigurationNotebookTitleCommand:
            [contextManager setNotebookTitle:_stringInfo];
            break;
        case MHConfigurationNotebookAuthorCommand:
            [contextManager setNotebookAuthor:_stringInfo];
            break;
        case MHConfigurationExportedPageHeaderCommand:
            [contextManager setExportedPageHeader:_expressionInfo];
            break;
        case MHConfigurationExportedPageFooterCommand:
            [contextManager setExportedPageFooter:_expressionInfo];
            break;
        case MHConfigurationExportedHeaderFooterRange:
            [contextManager setExportedHeaderAndFooterRange:_headerAndFooterRange];
            break;
        case MHConfigurationDefineStyleCommand:
            [contextManager beginLocalScope];
            
            if (_styleToInheritFromName) {
                [contextManager loadSavedTypesettingStateWithStyleName:_styleToInheritFromName];
            }
            
            //
            // In the code block below we want to typeset _expressionInfo and afterwards save the typesetting state.
            // Here we need a special hack to work around the fact that MHHorizontalLayoutContainer instances are locally
            // scoped, which prevents saving the typesetting state from working (since a locally scoped expression
            // restores the typesetting state at the end of the typesetWithContextManager: method call).
            // The solution is to create a copy of the _expressionInfo expression, then modify its class from
            // MHHorizontalLayoutContainer to a tweaked version of the MHHorizontalLayoutContainer class called
            // MHHorizontalLayoutContainerWithLocalScopingDisabled that was modified to return false to its locallyScoped
            // method
            //
            // It's not particularly elegant, but it works, and saves the need to add more instance variables to
            // the MHHorizontalLayoutContainer class, which would increase memory usage with the only benefit being in
            // this very specialized use
            //
            // The disadvantage is that we're using the "isa-swizzling" (changing the class of an object at runtime)
            // which is a low-level objective-C technique and goes against normal object oriented programming practice.
            // This may create in theory problems in the future (confusion for people reading the code, lack of
            // portability to Swift or other languages, unexpected bugs coming up when the app's functionality is enhanced
            // in some way I'm not anticipating right now, etc), but it seems like a decent solution to a very specific
            // problem, so I'm sticking with it for now.
            //
            if ([_expressionInfo isKindOfClass:[MHHorizontalLayoutContainer class]]) {
                MHHorizontalLayoutContainer *expressionToTypeset = (MHHorizontalLayoutContainer *)[_expressionInfo logicalCopy];
                object_setClass(expressionToTypeset, [MHHorizontalLayoutContainerWithLocalScopingDisabled class]);
                [expressionToTypeset typesetWithContextManager:contextManager];
            }
            else {
                [_expressionInfo typesetWithContextManager:contextManager];
            }
            
            [contextManager saveCurrentTypesettingStateWithStyleName:_stringInfo];
            [contextManager endLocalScope];
            break;
        case MHConfigurationLineSpacingCommand:
            contextManager.lineSpacing = _floatValue;
            break;
        case MHConfigurationBaseParagraphSpacingCommand:
            contextManager.baseParagraphSpacing = _floatValue;
            break;
        case MHConfigurationParagraphIndentCommand:
            contextManager.paragraphIndent = _floatValue;
            break;
        case MHConfigurationParagraphKerningMatrixCommand:
            [contextManager setParagraphKerningMatrixPrimaryRowsAndColumns:_vectorOrMatrix];
            break;
        case MHConfigurationPreparagraphSpacingsAtTopOfPageCommand:
            [contextManager setPreparagraphSpacingAtTopOfPage:_vectorOrMatrix];
            break;
    }
}


#pragma mark - Expression copying

- (instancetype)initWithType:(MHConfigurationCommandType)type
                    pageSize:(NSSize)size
                  stringInfo:(NSString *)stringInfo
              expressionInfo:(MHExpression *)expressionInfo
        headerAndFooterRange:(NSRange)range
                  floatValue:(CGFloat)floatValue
      styleToInheritFromName:(NSString *)styleToInheritFromName
      paragraphKerningMatrix:(MHParagraphKerningMatrixCastAsPointer)matrix
{
    if (self = [super init]) {
        _type = type;
        _pageSize = size;
        _stringInfo = [stringInfo copy];
        _expressionInfo = [expressionInfo logicalCopy];
        _headerAndFooterRange = range;
        _floatValue = floatValue;
        _styleToInheritFromName = [styleToInheritFromName copy];
        if (_type == MHConfigurationParagraphKerningMatrixCommand) {
            _vectorOrMatrix = malloc(sizeof(CGFloat)*MHNumberOfEffectiveParagraphTypes*MHNumberOfEffectiveParagraphTypes);
            memcpy(_vectorOrMatrix, matrix,
                   sizeof(CGFloat)*MHNumberOfEffectiveParagraphTypes*MHNumberOfEffectiveParagraphTypes);
        }
    }
    return self;
}

- (instancetype)logicalCopy
{
    // FIXME: test this
    MHConfigurationCommand *myCopy = [[[self class] alloc] initWithType:_type
                                                               pageSize:_pageSize
                                                             stringInfo:_stringInfo
                                                         expressionInfo:_expressionInfo
                                                   headerAndFooterRange:_headerAndFooterRange
                                                             floatValue:_floatValue
                                                 styleToInheritFromName:_styleToInheritFromName
                                                 paragraphKerningMatrix:_vectorOrMatrix];
    myCopy.codeRange = self.codeRange;
    return myCopy;
}

@end








@implementation MHHorizontalLayoutContainerWithLocalScopingDisabled : MHHorizontalLayoutContainer

- (bool)locallyScoped
{
    return false;
}

@end

