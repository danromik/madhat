//
//  MHFormattingCommand.h
//  MadHat
//
//  Created by Dan Romik on 10/31/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import "MHCommand.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum {
    // Text formatting commands:
    MHFormattingCommandFontSize,
    MHFormattingCommandFont,
    MHFormattingCommandEditFont,
    MHFormattingCommandMathFont,
    MHFormattingCommandFontCluster,
    MHFormattingCommandBold,
    MHFormattingCommandUnbold,
    MHFormattingCommandItalic,
    MHFormattingCommandUnitalic,
    MHFormattingCommandHighlight,
    MHFormattingCommandUnhighlight,
    MHFormattingCommandUnderline,
    MHFormattingCommandNoUnderline,
    MHFormattingCommandStrikethrough,
    MHFormattingCommandNoStrikethrough,
    // Paragraph formatting commands:   // FIXME: maybe refactor to a separate class
    MHFormattingCommandSuppressParagraphIndent,
    MHFormattingCommandForceNewParagraph,
} MHFormattingCommandType;




@interface MHFormattingCommand : MHCommand

// Used for the formatting command that require no argument, such as Bold, Unbold, Italic
+ (instancetype)formattingCommandWithNoArgumentOfType:(MHFormattingCommandType)type;

// Used for commands to set a font (text font, edit font, math font)
+ (instancetype)fontFormattingCommandWithType:(MHFormattingCommandType)type fontName:(NSString *)fontName;

+ (instancetype)fontSizeCommand:(CGFloat)fontSize;

+ (instancetype)suppressParagraphIndentCommand;



@end

NS_ASSUME_NONNULL_END
