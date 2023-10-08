//
//  MHPageViewerView.m
//  MadHat
//
//  Created by Dan Romik on 12/14/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import "MHPageViewerView.h"



@interface MHPageViewerView ()
{
    NSScrollView *_scrollView;
    NSView *_dummyContentView;
    
    NSSize _contentSize;
    
    NSUInteger _programmaticallyInitiatedScrollCounter;
    
    NSMutableArray <MHExpression <MHAnimatableExpression> *> *_currentlyAnimatingExpressions;  // keep track of expressions with animations in progress, to help coordinate various UI events (like navigating away from the page or entering text) and housekeeping tasks such as sending the view to sleep during periods of ianctivity to reduce CPU load
}

@end

@implementation MHPageViewerView

@dynamic scene;


#pragma mark - Initialization

- (instancetype)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect]) {

        _scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0.0, 0.0, frameRect.size.width, frameRect.size.height)];
        [_scrollView setBorderType:NSLineBorder];
        [_scrollView setHasVerticalScroller:YES];
        [_scrollView setHasHorizontalScroller:YES];
        _scrollView.autohidesScrollers = NO;
        
        // In an earlier version, magnification was enabled. Currently it is disabled, but may want to re-enable it in the future so leaving the code here:
//        _scrollView.allowsMagnification = true;
//        _scrollView.minMagnification = 0.5;
//        _scrollView.maxMagnification = 10.0;
        
        _scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        
        _scrollView.backgroundColor = [NSColor clearColor];
        [self addSubview:_scrollView];

        _dummyContentView = [[NSView alloc] initWithFrame:NSZeroRect];
        [_scrollView setDocumentView:_dummyContentView];
        _scrollView.drawsBackground = false;
        _scrollView.contentView.postsBoundsChangedNotifications = true;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(contentViewScrolled:)
                                                     name:NSViewBoundsDidChangeNotification
                                                   object:_scrollView.contentView];
        
        // This is recommended to optimize rendering performance in SpriteKit, see this page:
        // https://www.hackingwithswift.com/articles/184/tips-to-optimize-your-spritekit-game
//        self.ignoresSiblingOrder = YES;
        self.ignoresSiblingOrder = NO;  // commented out the optimization and replaced it with this for the time being, since ignoring sibling order resulted in incorrect layering of graphics primitives in a graphics canvas (speficially, an image was always on top relative to drawing primitives, which is not always the desired behavior)

        
        _currentlyAnimatingExpressions = [[NSMutableArray alloc] initWithCapacity:0];
        
        
//        self.showsDrawCount = true;       // can be useful for analyzing performance
//        self.showsFPS = true;             // can be useful for analyzing performance
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder]) {
        NSAssert1(false, @"Error: object of class %@ cannot be instantiated using initWithCoder", [self className]);
        return nil;
    }
    return self;
}


#pragma mark - Properties


- (NSScrollerKnobStyle)scrollerKnobStyle
{
    return _scrollView.scrollerKnobStyle;
}

- (void)setScrollerKnobStyle:(NSScrollerKnobStyle)scrollerKnobStyle
{
    _scrollView.scrollerKnobStyle = scrollerKnobStyle;
}


#pragma mark - Miscellaneous methods


// this method override is designed to work around an optimization in SpriteKit that prevents an SKView from re-rendering its contents during a live resize. We want it to re-render, so we pretend we are not in a live resize by overriding the property.
// FIXME: this may not be a future-proof method. is there a better solution?
- (BOOL)inLiveResize
{
    return NO;
}


- (void)contentViewScrolled:(NSNotification *)notification
{
    [self wakeUpForContentRefresh];
    [self.scene syncRootExpressionToContentView];
}

- (NSSize)contentSize
{
    // FIXME: when I try to generate a PDF there seems to be a bug where the width field of the contentSize is equal to 0. Investigate this.
    NSLog(@"Error: contentSize in %@ should not be called", self.className);
    return _contentSize;
}
- (void)setContentSize:(NSSize)contentSize
{
    _contentSize = contentSize;
    [self adjustDummyContentViewForContent];
    
    // adding this to cause scrollers to flash after switching pages. Not sure if it's the best place to put the call, but it works
    if (_dummyContentView.frame.size.height > self.bounds.size.height) {
        [_scrollView flashScrollers];
    }
}

- (void)adjustDummyContentViewForContent
{
    // Adjust the size of the dummy content view
    NSRect dummyContentViewFrame = _dummyContentView.frame;
    NSRect newDummyContentViewFrame;
    NSClipView *contentView = _scrollView.contentView;
    NSRect contentViewBounds = contentView.bounds;
    
    newDummyContentViewFrame.origin.x = 0.0;
    newDummyContentViewFrame.origin.y = 0.0;
    newDummyContentViewFrame.size.width = dummyContentViewFrame.size.width;
    newDummyContentViewFrame.size.height = _contentSize.height * (contentViewBounds.size.width+2.0) / _contentSize.width;       // FIXME: the +2.0 here is a temporary hack related to an inconsistency between the size of the content view and the _contentSize variable, which I fail to keep track of at other places. This hack seems to fix a problem of incorrect positioning of the dummy view, but I suspect that it creates (or will create in the future) other issues - IMPROVE
    
    // The new content width should be no smaller than the height of the viewable area
    CGFloat minContentHeight = self.bounds.size.height;
    if (newDummyContentViewFrame.size.height < minContentHeight) {
        newDummyContentViewFrame.size.height = minContentHeight;
    }
    else {
        // when the content view height changes, flash the scrollers
        CGFloat heightDifference = newDummyContentViewFrame.size.height - dummyContentViewFrame.size.height;
        if (fabs(heightDifference) > 0.01) {
            [_scrollView flashScrollers];
        }
    }

    _dummyContentView.frame = newDummyContentViewFrame;
}

- (void)setFrame:(NSRect)frame
{
    NSClipView *contentView = _scrollView.contentView;
    
    NSRect oldContentViewBounds = contentView.bounds;
    NSRect oldDummyContentViewFrame = _dummyContentView.frame;
    [super setFrame:frame];
    [self adjustDummyContentViewForContent];
    [self.scene syncRootExpressionToContentView];
    
    
    NSRect newContentViewBounds = contentView.bounds;
    NSRect newDummyContentViewFrame = _dummyContentView.frame;
    
    if (oldDummyContentViewFrame.size.height != newDummyContentViewFrame.size.height) {
        // The vertical height of the scrollable area changed
        
        // flash the scroll indicators
        [_scrollView flashScrollers];
        
        // Adjust the origin of the clip view to keep the scroll position (at the top of the view) the same
        newContentViewBounds.origin.y = (oldContentViewBounds.origin.y + oldContentViewBounds.size.height) / oldDummyContentViewFrame.size.height * newDummyContentViewFrame.size.height - newContentViewBounds.size.height;

        contentView.bounds = newContentViewBounds;
    }
}

- (NSRect)contentViewBounds
{
    return _scrollView.contentView.bounds;
}

- (void)scrollToTop:(bool)animated
{
    NSClipView *contentView = _scrollView.contentView;
    NSRect contentViewBounds = contentView.bounds;
    contentViewBounds.origin.y = _dummyContentView.bounds.size.height - _scrollView.bounds.size.height;
    if (animated) {
        [_scrollView flashScrollers];
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = kMHDefaultCoupledScrollingAnimationDuration;
            contentView.animator.bounds = contentViewBounds;
        }
        completionHandler:^{ }];
    }
    else {
        contentView.bounds = contentViewBounds;
    }
}

- (void)scrollToBottom:(bool)animated
{
    NSClipView *contentView = _scrollView.contentView;
    NSRect contentViewBounds = contentView.bounds;
    contentViewBounds.origin.y = 0.0;
    if (animated) {
        [_scrollView flashScrollers];
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = kMHDefaultCoupledScrollingAnimationDuration;
            contentView.animator.bounds = contentViewBounds;
        }
        completionHandler:^{ }];
    }
    else {
        contentView.bounds = contentViewBounds;
    }
}

- (void)scrollPageUp:(id)sender
{
    NSClipView *contentView = _scrollView.contentView;
    NSRect contentViewBounds = contentView.bounds;
    contentViewBounds.origin.y += contentViewBounds.size.height;
    [_scrollView flashScrollers];
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = kMHDefaultCoupledScrollingAnimationDuration;
        contentView.animator.bounds = contentViewBounds;
    }
    completionHandler:^{ }];
}

- (void)scrollPageDown:(id)sender
{
    NSClipView *contentView = _scrollView.contentView;
    NSRect contentViewBounds = contentView.bounds;
    contentViewBounds.origin.y -= contentViewBounds.size.height;
    if (contentViewBounds.origin.y < 0.0)
        contentViewBounds.origin.y = 0.0;
    [_scrollView flashScrollers];
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = kMHDefaultCoupledScrollingAnimationDuration;
        contentView.animator.bounds = contentViewBounds;
    }
    completionHandler:^{ }];
}


- (void)scrollToExpression:(MHExpression *)expression
{
    MHSpriteKitScene *myScene = self.scene;
    MHExpression *rootExpression = myScene.rootExpression;
    
    // Test if the expression's sprite kit node is in the hierarchy of descendant nodes of the root expression's node
    SKNode *rootNode = rootExpression.spriteKitNode;
    SKNode *node = expression.spriteKitNode;
    if (![node inParentHierarchy:rootNode])     // not in the root node's hierarchy, so do nothing
        return;
        
    NSPoint expressionPosition = [rootExpression.spriteKitNode convertPoint:expression.position fromNode:expression.spriteKitNode.parent];
    
    NSClipView *contentView = _scrollView.contentView;
    NSRect contentViewBounds = contentView.bounds;
    
    CGFloat minYOriginForContentView = _dummyContentView.bounds.size.height - _scrollView.bounds.size.height + expressionPosition.y + 100;
    CGFloat maxYOriginForContentView = _dummyContentView.bounds.size.height + expressionPosition.y - 100;
    
    CGFloat actualYOriginForContentView;
    if (contentViewBounds.origin.y < minYOriginForContentView)
        actualYOriginForContentView = minYOriginForContentView;
    else if (contentViewBounds.origin.y > maxYOriginForContentView)
        actualYOriginForContentView = maxYOriginForContentView;
    else {
        // the expression is already visible
        return;
    }
    
    [_scrollView flashScrollers];
    
    _programmaticallyInitiatedScrollCounter++;
    
    contentViewBounds.origin.y = actualYOriginForContentView;
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = kMHDefaultCoupledScrollingAnimationDuration;
        contentView.animator.bounds = contentViewBounds;
    }
    completionHandler:^{
        if (self->_programmaticallyInitiatedScrollCounter > 0)
            self->_programmaticallyInitiatedScrollCounter--;
        
    }];
}


- (void)viewWillMoveToSuperview:(NSView *)newSuperview
{
    // Remove any hovering auxiliary text that happens to be currently displayed
    self.scene.mouseHoveringAuxiliaryText = nil;
    
    if (!newSuperview) {
        // being removed from the superview - stop any running animations and remove ourselves as observers to animation start/end notifications
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:kMHInteractiveEventAnimationStartedNotification
                                                      object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:kMHInteractiveEventAnimationEndedNotification
                                                      object:nil];
        
        for (MHExpression <MHAnimatableExpression> *animatingExpression in _currentlyAnimatingExpressions) {
            [animatingExpression stopAnimating];
        }

        [_currentlyAnimatingExpressions removeAllObjects];
    }
}

- (void)viewDidMoveToSuperview
{
    if (self.superview) {
        // being added to a superview - start listening for animation start/end notifications
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(expressionAnimationStarted:)
                                                     name:kMHInteractiveEventAnimationStartedNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(expressionAnimationEnded:)
                                                     name:kMHInteractiveEventAnimationEndedNotification
                                                   object:nil];
    }
}

- (void)expressionAnimationStarted:(NSNotification *)notification
{
    MHExpression <MHAnimatableExpression> *animatingExpression = (MHExpression <MHAnimatableExpression> *)(notification.object);
    if ([animatingExpression.rootAncestor isEqual:self.scene.rootExpression]) {     // make sure the expression belongs to us
        [_currentlyAnimatingExpressions addObject:animatingExpression];
    }
}

- (void)expressionAnimationEnded:(NSNotification *)notification
{
    MHExpression <MHAnimatableExpression> *animatingExpression = (MHExpression <MHAnimatableExpression> *)(notification.object);
    NSUInteger animatingExpressionIndex = [_currentlyAnimatingExpressions indexOfObject:animatingExpression];
    if (animatingExpressionIndex != NSNotFound) {     // make sure the expression belongs to us
        [_currentlyAnimatingExpressions removeObjectAtIndex:animatingExpressionIndex];
        if (_currentlyAnimatingExpressions.count == 0)
            [self wakeUpForContentRefresh];
    }
}




- (void)wakeUpForContentRefresh
{
    static const CGFloat renderingIntervalLengthAfterActivity = 5.0;
    self.paused = NO;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(goToSleep) object:nil];
    [self performSelector:@selector(goToSleep) withObject:nil afterDelay:renderingIntervalLengthAfterActivity];
}

- (void)goToSleep
{
    if (_currentlyAnimatingExpressions.count == 0) {
        self.paused = YES;
    }
}

- (void)stopAllCurrentlyRunningAnimations
{
    for (MHExpression <MHAnimatableExpression> *animatingExpression in _currentlyAnimatingExpressions) {
        [animatingExpression stopAnimating];
    }
}



@end
