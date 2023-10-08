//
//  MHTypesettingState.h
//  MadHat
//
//  Created by Dan Romik on 8/31/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    MHTypesettingStatePredefinedStyleNormalText,
    MHTypesettingStatePredefinedStyleTextHyperlink,
    MHTypesettingStatePredefinedStyleURLHyperlink,
    MHTypesettingStatePredefinedStyleIntralink,
    MHTypesettingStatePredefinedStyleHeader,
    MHTypesettingStatePredefinedStyleSubheader,
    MHTypesettingStatePredefinedStyleSubsubheader,
    MHTypesettingStatePredefinedStyleParagraphHeader,
    MHTypesettingStatePredefinedStyleSuperheader
} MHTypesettingStatePredefinedStyleType;



NS_ASSUME_NONNULL_BEGIN

@class MHTypingStyle;
@class MHParagraphStyle;
@class MHListStyle;

@interface MHTypesettingState : NSObject <NSCopying>

@property MHTypingStyle *typingStyle;
@property MHParagraphStyle *paragraphStyle;
@property MHListStyle *listStyle;


// default typesetting states
+ (instancetype)defaultState;
+ (instancetype)defaultStateForPredefinedStyleType:(MHTypesettingStatePredefinedStyleType)styleType;

@end

NS_ASSUME_NONNULL_END
