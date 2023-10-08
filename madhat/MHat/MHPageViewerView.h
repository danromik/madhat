//
//  MHPageViewerView.h
//  MadHat
//
//  Created by Dan Romik on 12/14/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <SpriteKit/SpriteKit.h>
#import "MHSpriteKitScene.h"

NS_ASSUME_NONNULL_BEGIN

@class MHExpression;

@interface MHPageViewerView : SKView

@property NSSize contentSize;
@property (readonly) NSRect contentViewBounds;

@property (readonly) NSUInteger programmaticallyInitiatedScrollCounter;

@property (readonly) MHSpriteKitScene *scene;   // let the compiler know we expect the scene to be a MHSpriteKitScene instance  // FIXME: try to make this private if possible

@property NSScrollerKnobStyle scrollerKnobStyle;

- (void)scrollToTop:(bool)animated;
- (void)scrollToBottom:(bool)animated;
- (void)scrollToExpression:(MHExpression *)expression;

- (void)wakeUpForContentRefresh;    // we generally pause the SpriteKit rendering whenever there is user activity to avoid unnecessary CPU load. Calling this method unpauses the view for a short time interval
- (void)stopAllCurrentlyRunningAnimations;

@end

NS_ASSUME_NONNULL_END
