//
//  MHSpriteKitScene.h
//  MadHat
//
//  Created by Dan Romik on 1/17/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "MHExpression.h"
#import "MHParser.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kMHSpriteKitSceneSelectionChangedNotification;
extern NSString * const kMHSpriteKitSceneSelectionCodeRangeKey;
extern NSString * const kMHSpriteKitSceneScrolledNotification;

extern NSString * const kMHSpriteKitSceneGoToPageNotification;
extern NSString * const kMHSpriteKitSceneGoToPageNotificationPageNameKey;
extern NSString * const kMHSpriteKitSceneGoToPageNotificationSlideNumberKey;


@interface MHSpriteKitScene : SKScene <MHParserDelegate>

@property MHVerticalLayoutContainer *rootExpression;

@property MHExpressionPresentationMode presentationMode;

@property MHExpression *selectedExpression;

@property NSUInteger maxSlideTransitionIndex;
@property NSArray <MHSlideTransition *> *slideTransitions;


@property (weak) NSObject <MHResourceProvider> *resourceProvider;

- (instancetype)initWithPageWidth:(CGFloat)width;      // Designated initializer

- (void)reformatRootExpressionWithSlideTransitionIndex:(NSUInteger)slideTransitionIndex
                                         animationType:(MHReformattingAnimationType)animationType;
- (void)syncRootExpressionToContentView;

- (void)invokeIntralinkToNotebookPage:(NSString *)pageName slideNumber:(NSInteger)slideNumber;

- (void)retypesetRootExpression;

- (void)setNotebookConfiguration:(MHNotebookConfiguration *)notebookConfiguration;

@property (nullable) NSString *mouseHoveringAuxiliaryText;  // FIXME: do I want to publicly expose this? Doing this to give access to the owner MHPageViewerView, but this doesn't seem like good OO practice

@end

NS_ASSUME_NONNULL_END
