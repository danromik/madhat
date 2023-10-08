//
//  MHTypesettingState.m
//  MadHat
//
//  Created by Dan Romik on 8/31/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHTypesettingState.h"
#import "MHStyleIncludes.h"


@implementation MHTypesettingState


+ (instancetype)defaultState;
{
    return [[self alloc] initWithDefaultStateForPredefinedStyleType:MHTypesettingStatePredefinedStyleNormalText];
}

+ (instancetype)defaultStateForPredefinedStyleType:(MHTypesettingStatePredefinedStyleType)styleType
{
    return [[self alloc] initWithDefaultStateForPredefinedStyleType:styleType];
}

- (instancetype)initWithDefaultStateForPredefinedStyleType:(MHTypesettingStatePredefinedStyleType)predefinedStyle
{
    if (self = [super init]) {
        switch (predefinedStyle) {
            case MHTypesettingStatePredefinedStyleNormalText:
                self.typingStyle = [MHTypingStyle defaultStyle];
                break;
            case MHTypesettingStatePredefinedStyleTextHyperlink:
                self.typingStyle = [MHTypingStyle defaultStyleForTextType:MHTypingStyleTextHyperlink];
                break;
            case MHTypesettingStatePredefinedStyleURLHyperlink:
                self.typingStyle = [MHTypingStyle defaultStyleForTextType:MHTypingStyleURLHyperlink];
                break;
            case MHTypesettingStatePredefinedStyleIntralink:
                self.typingStyle = [MHTypingStyle defaultStyleForTextType:MHTypingStyleIntralink];
                break;
            case MHTypesettingStatePredefinedStyleHeader:
                self.typingStyle = [MHTypingStyle defaultStyleForTextType:MHTypingStyleHeader];
                break;
            case MHTypesettingStatePredefinedStyleSubheader:
                self.typingStyle = [MHTypingStyle defaultStyleForTextType:MHTypingStyleSubheader];
                break;
            case MHTypesettingStatePredefinedStyleSubsubheader:
                self.typingStyle = [MHTypingStyle defaultStyleForTextType:MHTypingStyleSubsubheader];
                break;
            case MHTypesettingStatePredefinedStyleParagraphHeader:
                self.typingStyle = [MHTypingStyle defaultStyleForTextType:MHTypingStyleParagraphHeader];
                break;
            case MHTypesettingStatePredefinedStyleSuperheader:
                self.typingStyle = [MHTypingStyle defaultStyleForTextType:MHTypingStyleSuperheader];
                break;
        }
        
        // the paragraph style and list style are the same, for now - maybe change this later if we add more predefined style types where it makes sense to have different default paragraph/list styles
        self.paragraphStyle = [MHParagraphStyle defaultStyle];
        self.listStyle = [MHListStyle defaultStyle];
    }
    return self;
}

- (BOOL)isEqual:(id)object
{
    return [object isMemberOfClass:[self class]]
    && [((MHTypesettingState *)object).typingStyle isEqual:self.typingStyle]
    && [((MHTypesettingState *)object).paragraphStyle isEqual:self.paragraphStyle]
    && [((MHTypesettingState *)object).listStyle isEqual:self.listStyle];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    MHTypesettingState *myCopy = [[[self class] alloc] init];
    myCopy.typingStyle = [self.typingStyle copy];
    myCopy.paragraphStyle = [self.paragraphStyle copy];
    myCopy.listStyle = [self.listStyle copy];
    return myCopy;
}

@end
