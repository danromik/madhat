//
//  NSString+MathConversion.m
//  MadHat
//
//  Created by Dan Romik on 1/9/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "NSString+MathConversion.h"

#import <AppKit/AppKit.h>

//
// A useful reference:
// https://en.wikipedia.org/wiki/Mathematical_Alphanumeric_Symbols
//


@implementation NSString (MathConversion)

+ (NSString *)stringByConvertingRomanCharactersInString:(NSString *)string toMathFontVariant:(MHMathFontVariant)mathFontVariant
{
    if (mathFontVariant == MHMathFontVariantRoman)
        return string;
    
    // FIXME: this method is inefficient, and is used a lot, so there is a lot of room to gain performance improvement by implementing a highly optimized version of it
    
    // FIXME: add additional math font variants (italic-bold, blackboard, fraktur, sans serif)
    
    NSUInteger stringLength = string.length;
    NSMutableString *transformedString = [NSMutableString stringWithCapacity:stringLength];
    NSUInteger charIndex;
    
    // Italic math alphabet
    static __weak NSString *NSStringMathConversionUppercaseItalicMathAlphabet[26] = {
        @"𝐴", @"𝐵", @"𝐶", @"𝐷", @"𝐸", @"𝐹", @"𝐺", @"𝐻", @"𝐼", @"𝐽", @"𝐾", @"𝐿", @"𝑀",
        @"𝑁", @"𝑂", @"𝑃", @"𝑄", @"𝑅", @"𝑆", @"𝑇", @"𝑈", @"𝑉", @"𝑊", @"𝑋", @"𝑌", @"𝑍"
    };
    static __weak NSString *NSStringMathConversionLowercaseItalicMathAlphabet[26] = {
        @"𝑎", @"𝑏", @"𝑐", @"𝑑", @"𝑒", @"𝑓", @"𝑔", @"ℎ", @"𝑖", @"𝑗", @"𝑘", @"𝑙", @"𝑚",
        @"𝑛", @"𝑜", @"𝑝", @"𝑞", @"𝑟", @"𝑠", @"𝑡", @"𝑢", @"𝑣", @"𝑤", @"𝑥", @"𝑦", @"𝑧"
    };

    // Bold math alphabet
    static __weak NSString *NSStringMathConversionUppercaseBoldMathAlphabet[26] = {
        @"𝐀", @"𝐁", @"𝐂", @"𝐃", @"𝐄", @"𝐅", @"𝐆", @"𝐇", @"𝐈", @"𝐉", @"𝐊", @"𝐋", @"𝐌",
        @"𝐍", @"𝐎", @"𝐏", @"𝐐", @"𝐑", @"𝐒", @"𝐓", @"𝐔", @"𝐕", @"𝐖", @"𝐗", @"𝐘", @"𝐙"
    };
    static __weak NSString *NSStringMathConversionLowercaseBoldMathAlphabet[26] = {
        @"𝐚", @"𝐛", @"𝐜", @"𝐝", @"𝐞", @"𝐟", @"𝐠", @"𝐡", @"𝐢", @"𝐣", @"𝐤", @"𝐥", @"𝐦",
        @"𝐧", @"𝐨", @"𝐩", @"𝐪", @"𝐫", @"𝐬", @"𝐭", @"𝐮", @"𝐯", @"𝐰", @"𝐱", @"𝐲", @"𝐳"
    };
    
    // Blackboard math alphabet
    static __weak NSString *NSStringMathConversionUppercaseBlackboardMathAlphabet[26] = {
        @"𝔸", @"𝔹", @"ℂ", @"𝔻", @"𝔼", @"𝔽", @"𝔾", @"ℍ", @"𝕀", @"𝕁", @"𝕂", @"𝕃", @"𝕄",
        @"ℕ", @"𝕆", @"ℙ", @"ℚ", @"ℝ", @"𝕊", @"𝕋", @"𝕌", @"𝕍", @"𝕎", @"𝕏", @"𝕐", @"ℤ"
    };
    static __weak NSString *NSStringMathConversionLowercaseBlackboardMathAlphabet[26] = {
        @"𝕒", @"𝕓", @"𝕔", @"𝕕", @"𝕖", @"𝕗", @"𝕘", @"𝕙", @"𝕚", @"𝕛", @"𝕜", @"𝕝", @"𝕞",
        @"𝕟", @"𝕠", @"𝕡", @"𝕢", @"𝕣", @"𝕤", @"𝕥", @"𝕦", @"𝕧", @"𝕨", @"𝕩", @"𝕪", @"𝕫"
    };


    // Calligraphy math alphbet
    static __weak NSString *NSStringMathConversionUppercaseCalligraphyMathAlphabet[26] = {
        @"𝒜", @"ℬ", @"𝒞", @"𝒟", @"ℰ", @"ℱ", @"𝒢", @"ℋ", @"ℐ", @"𝒥", @"𝒦", @"ℒ", @"ℳ",
        @"𝒩", @"𝒪", @"𝒫", @"𝒬", @"ℛ", @"𝒮", @"𝒯", @"𝒰", @"𝒱", @"𝒲", @"𝒳", @"𝒴", @"𝒵"
    };

    static __weak NSString *NSStringMathConversionLowercaseCalligraphyMathAlphabet[26] = {
        // FIXME: This seems correct in the sense that I am using the correct unicode glyphs for lowercase calligraphic math letters
        // However, the letters don't render correctly in the Latin Modern Math font, probably because they are missing from
        // the font
        // In the TeX Gyre math fonts the symbols appear correctly
        @"𝒶", @"𝒷", @"𝒸", @"𝒹", @"ℯ", @"𝒻", @"ℊ", @"𝒽", @"𝒾", @"𝒿", @"𝓀", @"𝓁", @"𝓂",
        @"𝓃", @"ℴ", @"𝓅", @"𝓆", @"𝓇", @"𝓈", @"𝓉", @"𝓊", @"𝓋", @"𝓌", @"𝓍", @"𝓎", @"𝓏"
    };

    // Fraktur math alphabet
    static __weak NSString *NSStringMathConversionUppercaseFrakturMathAlphabet[26] = {
        @"𝔄", @"𝔅", @"ℭ", @"𝔇", @"𝔈", @"𝔉", @"𝔊", @"ℌ", @"ℑ", @"𝔍", @"𝔎", @"𝔏", @"𝔐",
        @"𝔑", @"𝔒", @"𝔓", @"𝔔", @"ℜ", @"𝔖", @"𝔗", @"𝔘", @"𝔙", @"𝔚", @"𝔛", @"𝔜", @"ℨ"
    };

    static __weak NSString *NSStringMathConversionLowercaseFrakturMathAlphabet[26] = {
        @"𝔞", @"𝔟", @"𝔠", @"𝔡", @"𝔢", @"𝔣", @"𝔤", @"𝔥", @"𝔦", @"𝔧", @"𝔨", @"𝔩", @"𝔪",
        @"𝔫", @"𝔬", @"𝔭", @"𝔮", @"𝔯", @"𝔰", @"𝔱", @"𝔲", @"𝔳", @"𝔴", @"𝔵", @"𝔶", @"𝔷"
    };

    // Monospace math alphabet
    static __weak NSString *NSStringMathConversionUppercaseMonospaceMathAlphabet[26] = {
        @"𝙰", @"𝙱", @"𝙲", @"𝙳", @"𝙴", @"𝙵", @"𝙶", @"𝙷", @"𝙸", @"𝙹", @"𝙺", @"𝙻", @"𝙼",
        @"𝙽", @"𝙾", @"𝙿", @"𝚀", @"𝚁", @"𝚂", @"𝚃", @"𝚄", @"𝚅", @"𝚆", @"𝚇", @"𝚈", @"𝚉"
    };

    static __weak NSString *NSStringMathConversionLowercaseMonospaceMathAlphabet[26] = {
        @"𝚊", @"𝚋", @"𝚌", @"𝚍", @"𝚎", @"𝚏", @"𝚐", @"𝚑", @"𝚒", @"𝚓", @"𝚔", @"𝚕", @"𝚖",
        @"𝚗", @"𝚘", @"𝚙", @"𝚚", @"𝚛", @"𝚜", @"𝚝", @"𝚞", @"𝚟", @"𝚠", @"𝚡", @"𝚢", @"𝚣"
    };

    // Sans serif math alphabet
    static __weak NSString *NSStringMathConversionUppercaseSansSerifMathAlphabet[26] = {
        @"𝖠", @"𝖡", @"𝖢", @"𝖣", @"𝖤", @"𝖥", @"𝖦", @"𝖧", @"𝖨", @"𝖩", @"𝖪", @"𝖫", @"𝖬",
        @"𝖭", @"𝖮", @"𝖯", @"𝖰", @"𝖱", @"𝖲", @"𝖳", @"𝖴", @"𝖵", @"𝖶", @"𝖷", @"𝖸", @"𝖹"
    };

    static __weak NSString *NSStringMathConversionLowercaseSansSerifMathAlphabet[26] = {
        @"𝖺", @"𝖻", @"𝖼", @"𝖽", @"𝖾", @"𝖿", @"𝗀", @"𝗁", @"𝗂", @"𝗃", @"𝗄", @"𝗅", @"𝗆",
        @"𝗇", @"𝗈", @"𝗉", @"𝗊", @"𝗋", @"𝗌", @"𝗍", @"𝗎", @"𝗏", @"𝗐", @"𝗑", @"𝗒", @"𝗓"
    };

    NSString __weak **uppercaseConvertedCharSet = NSStringMathConversionUppercaseItalicMathAlphabet;
    NSString __weak **lowercaseConvertedCharSet = NSStringMathConversionLowercaseItalicMathAlphabet;

    
    switch (mathFontVariant) {
        case MHMathFontVariantItalic:
            uppercaseConvertedCharSet = NSStringMathConversionUppercaseItalicMathAlphabet;
            lowercaseConvertedCharSet = NSStringMathConversionLowercaseItalicMathAlphabet;
            break;
        case MHMathFontVariantBold:
            uppercaseConvertedCharSet = NSStringMathConversionUppercaseBoldMathAlphabet;
            lowercaseConvertedCharSet = NSStringMathConversionLowercaseBoldMathAlphabet;
            break;
        case MHMathFontVariantBlackboard:
            uppercaseConvertedCharSet = NSStringMathConversionUppercaseBlackboardMathAlphabet;
            lowercaseConvertedCharSet = NSStringMathConversionLowercaseBlackboardMathAlphabet;
            break;
        case MHMathFontVariantFraktur:
            uppercaseConvertedCharSet = NSStringMathConversionUppercaseFrakturMathAlphabet;
            lowercaseConvertedCharSet = NSStringMathConversionLowercaseFrakturMathAlphabet;
            break;
        case MHMathFontVariantCalligraphy:
            uppercaseConvertedCharSet = NSStringMathConversionUppercaseCalligraphyMathAlphabet;
            lowercaseConvertedCharSet = NSStringMathConversionLowercaseCalligraphyMathAlphabet;
            break;
        case MHMathFontVariantMonospace:
            uppercaseConvertedCharSet = NSStringMathConversionUppercaseMonospaceMathAlphabet;
            lowercaseConvertedCharSet = NSStringMathConversionLowercaseMonospaceMathAlphabet;
            break;
        case MHMathFontVariantSansSerif:
            uppercaseConvertedCharSet = NSStringMathConversionUppercaseSansSerifMathAlphabet;
            lowercaseConvertedCharSet = NSStringMathConversionLowercaseSansSerifMathAlphabet;
            break;
        default:
            return [NSString stringWithString:string];
            break;
    }

    for (charIndex = 0; charIndex < stringLength; charIndex++) {
        unichar originalChar = [string characterAtIndex:charIndex];
        NSString *transformedCharString;
        if (originalChar >= 'A' && originalChar <= 'Z')
            transformedCharString = uppercaseConvertedCharSet[originalChar-'A'];
        else if (originalChar >= 'a' && originalChar <= 'z')
            transformedCharString = lowercaseConvertedCharSet[originalChar-'a'];
        else
            transformedCharString = [NSString stringWithFormat:@"%C", originalChar];
        [transformedString appendString:transformedCharString];
    }
    return [NSString stringWithString:transformedString];

    
    // Older code - delete this at some point
//    static NSString *NSStringMathConversionUppercaseItalicMathAlphabet = @"𝐴𝐵𝐶𝐷𝐸𝐹𝐺𝐻𝐼𝐽𝐾𝐿𝑀𝑁𝑂𝑃𝑄𝑅𝑆𝑇𝑈𝑉𝑊𝑋𝑌𝑍";
//    static NSString *NSStringMathConversionLowercaseItalicMathAlphabet = @"𝑎𝑏𝑐𝑑𝑒𝑓𝑔ℎ𝑖𝑗𝑘𝑙𝑚𝑛𝑜𝑝𝑞𝑟𝑠𝑡𝑢𝑣𝑤𝑥𝑦𝑧";
//
//    static NSString *NSStringMathConversionUppercaseBoldMathAlphabet = @"𝐀𝐁𝐂𝐃𝐄𝐅𝐆𝐇𝐈𝐉𝐊𝐋𝐌𝐍𝐎𝐏𝐐𝐑𝐒𝐓𝐔𝐕𝐖𝐗𝐘𝐙";
//    static NSString *NSStringMathConversionLowercaseBoldMathAlphabet = @"𝐚𝐛𝐜𝐝𝐞𝐟𝐠𝐡𝐢𝐣𝐤𝐥𝐦𝐧𝐨𝐩𝐪𝐫𝐬𝐭𝐮𝐯𝐰𝐱𝐲𝐳";
//
//    static NSString *NSStringMathConversionUppercaseBlackboardMathAlphabet = @"𝔸𝔹ℂ𝔻𝔼𝔽𝔾ℍ𝕀𝕁𝕂𝕃𝕄ℕ𝕆ℙℚℝ𝕊𝕋𝕌𝕍𝕎𝕏𝕐ℤ";
//    static NSString *NSStringMathConversionLowercaseBlackboardMathAlphabet = @"𝕒𝕓𝕔𝕕𝕖𝕗𝕘𝕙𝕚𝕛𝕜𝕝𝕞𝕟𝕠𝕡𝕢𝕣𝕤𝕥𝕦𝕧𝕨𝕩𝕪𝕫";
//
//    static NSString *NSStringMathConversionUppercaseFrakturMathAlphabet = @"𝔄𝔅ℭ𝔇𝔈𝔉𝔊ℌℑ𝔍𝔎𝔏𝔐𝔑𝔒𝔓𝔔ℜ𝔖𝔗𝔘𝔙𝔚𝔛𝔜ℨ";
//    static NSString *NSStringMathConversionLowercaseFrakturMathAlphabet = @"𝔞𝔟𝔠𝔡𝔢𝔣𝔤𝔥𝔦𝔧𝔨𝔩𝔪𝔫𝔬𝔭𝔮𝔯𝔰𝔱𝔲𝔳𝔴𝔵𝔶𝔷";
//
//    static NSString *NSStringMathConversionUppercaseCalligraphyMathAlphabet = @"𝒜ℬ𝒞𝒟ℰℱ𝒢ℋℐ𝒥𝒦ℒℳ𝒩𝒪𝒫𝒬ℛ𝒮𝒯𝒰𝒱𝒲𝒳𝒴𝒵";
//    static NSString *NSStringMathConversionLowercaseCalligraphyMathAlphabet = @"𝒶𝒷𝒸𝒹ℯ𝒻ℊ𝒽𝒾𝒿𝓀𝓁𝓂𝓃ℴ𝓅𝓆𝓇𝓈𝓉𝓊𝓋𝓌𝓍𝓎𝓏";

//    NSString *uppercaseConvertedCharSet;
//    NSString *lowercaseConvertedCharSet;
    
//    char planckConstantOffset;  // this is needed to address a quirk in the unicode Mathematical Alphanumeric Symbols block (the mathematical italic h symbol uses a different number of bytes than the other italic letters, since it was added to the standard earlier due to its connection to Planck's constant)
    
//    if (mathFontVariant == MHMathFontVariantRoman)
//        return [NSString stringWithString:string];

//    switch (mathFontVariant) {
//        case MHMathFontVariantItalic:
//            uppercaseConvertedCharSet = NSStringMathConversionUppercaseItalicMathAlphabet;
//            lowercaseConvertedCharSet = NSStringMathConversionLowercaseItalicMathAlphabet;
//            planckConstantOffset = 1;
//            break;
//        case MHMathFontVariantBold:
//            uppercaseConvertedCharSet = NSStringMathConversionUppercaseBoldMathAlphabet;
//            lowercaseConvertedCharSet = NSStringMathConversionLowercaseBoldMathAlphabet;
//            planckConstantOffset = 0;
//            break;
//        case MHMathFontVariantBlackboard:
//            uppercaseConvertedCharSet = NSStringMathConversionUppercaseBlackboardMathAlphabet;
//            lowercaseConvertedCharSet = NSStringMathConversionLowercaseBlackboardMathAlphabet;
//            planckConstantOffset = 0;
//            break;
//        case MHMathFontVariantFraktur:
//            uppercaseConvertedCharSet = NSStringMathConversionUppercaseFrakturMathAlphabet;
//            lowercaseConvertedCharSet = NSStringMathConversionLowercaseFrakturMathAlphabet;
//            planckConstantOffset = 0;
//            break;
//        case MHMathFontVariantCalligraphy:
//            uppercaseConvertedCharSet = NSStringMathConversionUppercaseCalligraphyMathAlphabet;
//            lowercaseConvertedCharSet = NSStringMathConversionLowercaseCalligraphyMathAlphabet;
//            planckConstantOffset = 0;
//            break;
//        default:
//            return [NSString stringWithString:string];
//            break;
//    }
    
    
//    for (charIndex = 0; charIndex < stringLength; charIndex++) {
//        unichar c = [string characterAtIndex:charIndex];
//        [transformedString appendString:(c-'A' >= 0 && c-'A' <= 25 ? [uppercaseConvertedCharSet substringWithRange:NSMakeRange(2*(c-'A'), 2)] :
//                                         (c-'a' >= 0 && c-'a' <= 25 ? [lowercaseConvertedCharSet substringWithRange:NSMakeRange(2*(c-'a')-(c>'h'?planckConstantOffset:0), (c=='h'?2-planckConstantOffset:2))] :
//                                          [NSString stringWithFormat:@"%C", c]))];
//    }
//    return [NSString stringWithString:transformedString];
}

@end
