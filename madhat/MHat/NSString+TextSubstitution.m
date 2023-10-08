//
//  NSString+TextSubstitution.m
//  MadHat
//
//  Created by Dan Romik on 8/5/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "NSString+TextSubstitution.h"

#import <AppKit/AppKit.h>


@implementation NSString (TextSubstitution)

- (NSString *)stringByApplyingSubstitution:(MHTextSubstitutionType)substitutionType
{
    switch (substitutionType) {
        case MHTextSubstitutionNone:
            return self;
        case MHTextSubstitutionLowercase:
            return [self lowercaseString];     // FIXME: do I want to use the -localizedLowercaseString method instead?
        case MHTextSubstitutionUppercase:
            return [self uppercaseString];     // FIXME: do I want to use the -localizedUppercaseString method instead?
        case MHTextSubstitutionRedacted:
            return [@"" stringByPaddingToLength:self.length withString:@"*" startingAtIndex:0];
        case MHTextSubstitutionObfuscated: {
            NSUInteger myLength = self.length;
            NSMutableString *myMutableCopy = [self mutableCopy];
            for (NSUInteger charIndex = 0; charIndex < myLength; charIndex++) {
                unichar theChar = [self characterAtIndex:charIndex];
                if (theChar >= 'a' && theChar <= 'z') {
                    unichar theReplacementChar = (theChar == 'z' ? 'a' : theChar+1);
                    [myMutableCopy replaceCharactersInRange:NSMakeRange(charIndex, 1)
                                                 withString:[NSString stringWithFormat:@"%C", theReplacementChar]];
                }
                else if (theChar >= 'A' && theChar <= 'Z') {
                    unichar theReplacementChar = (theChar == 'Z' ? 'A' : theChar+1);
                    [myMutableCopy replaceCharactersInRange:NSMakeRange(charIndex, 1)
                                                 withString:[NSString stringWithFormat:@"%C", theReplacementChar]];
                }
                else if (theChar >= '0' && theChar <= '9') {
                    unichar theReplacementChar = '0' + ('9'-theChar);
                    [myMutableCopy replaceCharactersInRange:NSMakeRange(charIndex, 1)
                                                 withString:[NSString stringWithFormat:@"%C", theReplacementChar]];
                }
            }
            return myMutableCopy;
        }
    }
}

@end
