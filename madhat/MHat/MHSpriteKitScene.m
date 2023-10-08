//
//  MHSpriteKitScene.m
//  MadHat
//
//  Created by Dan Romik on 1/17/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHSpriteKitScene.h"
#import "MHTypesettingContextManager.h"
#import "MHTypesettingContextManager+TypingStyle.h"
#import "MHReformattingContextManager.h"
#import "MHVerticalLayoutContainer.h"
#import "MHPageViewerView.h"
#import "NSScroller+KnobStyleExtension.h"

NSString * const kMHSpriteKitSceneSelectionChangedNotification = @"MHSpriteKitSceneSelectionChangedNotification";
NSString * const kMHSpriteKitSceneSelectionCodeRangeKey = @"selectionCodeRange";
NSString * const kMHSpriteKitSceneScrolledNotification = @"MHSpriteKitSceneScrolledNotification";

NSString * const kMHSpriteKitSceneGoToPageNotification = @"MHSpriteKitSceneGoToPageNotification";
NSString * const kMHSpriteKitSceneGoToPageNotificationPageNameKey = @"pagename";
NSString * const kMHSpriteKitSceneGoToPageNotificationSlideNumberKey = @"slidenumber";



@interface MHSpriteKitScene ()
{
    MHTypesettingContextManager *_typesettingContextManager;
    MHReformattingContextManager *_formattingContextManager;
    MHVerticalLayoutContainer *_rootExpression;
    MHExpressionPresentationMode _presentationMode;
    
    CGFloat _pageWidth;
    CGFloat _pageTopMargin;
    CGFloat _pageBottomMargin;
    NSSize _contentSize;    // the current size of the page content rectangle. The width field will be the same as _pageWidth
    
    MHExpression *_selectedExpression;
    
    NSUInteger _numberOfSlideTransitions;
}

@property (readonly) MHPageViewerView *view;  // Let the compiler know the view property is an instance of the class MHDocumentView

@end

@implementation MHSpriteKitScene

@dynamic view;

- (instancetype)initWithPageWidth:(CGFloat)width
{
    if (self = [super initWithSize:CGSizeZero]) {
        // We'll be using the physics features of SpriteKit just for detection of nodes in the scene rectangle, so turn off the physics simulation to avoid unwanted effects (gravity, collisions etc)
        self.physicsWorld.speed = 0.0;
        
        _pageWidth = width;
        self.backgroundColor = [NSColor whiteColor];
        self.scaleMode = SKSceneScaleModeResizeFill;
        self.presentationMode = MHExpressionPresentationModePublishing;

        // Create and configure the typesetting context manager
        _typesettingContextManager = [[MHTypesettingContextManager alloc] init];
        
        
//        _typesettingContextManager.pageWidth = pageWidth;   // FIXME: is this useful for anything?
//        _typesettingContextManager.textWidth = textWidth;
//        _typesettingContextManager.leftMargin = leftMargin;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(documentGlobalParametersChanged:)
                                                     name:nil
                                                   object:_typesettingContextManager];

        // Create the formatting context manager
        _formattingContextManager = [[MHReformattingContextManager alloc] init];
    }
    return self;
}


- (void)documentGlobalParametersChanged:(NSNotification *)notification
{
    NSString *notificationName = notification.name;
    if ([notificationName isEqualToString:kMHPageBackgroundColorNotification]) {
        NSColor *color = notification.userInfo[kMHPageBackgroundColorKey];
        self.backgroundColor = color;
        
        // Adjust the scroller knob style to ensure a good contrast with the background color
        self.view.scrollerKnobStyle = [NSScroller knobStyleAdaptedToBackgroundColor:color];
    }
}

- (void)didMoveToView:(SKView *)view
{
    [super didMoveToView:view];

    [self adjustContentViewHeight];
    [self syncRootExpressionToContentView];
}


- (void)retypesetRootExpression
{
    if (_rootExpression) {
        MHVerticalLayoutContainer *savedRootExpression = _rootExpression;
        self.rootExpression = savedRootExpression;  // FIXME: probably not good practice
    }
}

- (void)setNotebookConfiguration:(MHNotebookConfiguration *)notebookConfiguration
{
    _pageWidth = notebookConfiguration.pageSize.width;
    _pageTopMargin = notebookConfiguration.pageTopMargin;
    _pageBottomMargin = notebookConfiguration.pageBottomMargin;
    
    _typesettingContextManager.notebookConfiguration = notebookConfiguration;
    _typesettingContextManager.defaultState = notebookConfiguration.defaultTypesettingState;
        
    [self retypesetRootExpression];
}

- (MHExpressionPresentationMode)presentationMode
{
    return _presentationMode;
}

- (void)setPresentationMode:(MHExpressionPresentationMode)presentationMode
{
    if (_presentationMode != presentationMode) {
        _presentationMode = presentationMode;
        if (_rootExpression) {
            MHVerticalLayoutContainer *savedRootExpression = _rootExpression;
            savedRootExpression.presentationMode = presentationMode;
            self.rootExpression = savedRootExpression;  // FIXME: probably not good practice
        }
    }
}


- (MHLinearContainer *)rootExpression
{
    return _rootExpression;
}

- (void)setRootExpression:(MHVerticalLayoutContainer *)rootExpression
{
    [self removeAllChildren];
    
    [self.view wakeUpForContentRefresh];
    _rootExpression = rootExpression;
    
    [_typesettingContextManager resetToDefaultState];
    
    rootExpression.presentationMode = self.presentationMode;

    SKNode *rootExpressionNode = rootExpression.spriteKitNode;
    [self addChild:rootExpressionNode];
    
    [rootExpression typesetWithContextManager:_typesettingContextManager];
    [self reformatRootExpressionWithSlideTransitionIndex:0 animationType:MHReformattingAnimationTypeNone];

    [self adjustContentViewHeight];
    MHPageViewerView *myView = self.view;
    [myView scrollToTop:false];
    [self syncRootExpressionToContentView];
}

- (void)reformatRootExpressionWithSlideTransitionIndex:(NSUInteger)slideTransitionIndex
                                         animationType:(MHReformattingAnimationType)animationType
{
    [_formattingContextManager resetToDefaultState];
    _formattingContextManager.currentSlideTransitionIndex = slideTransitionIndex;
    [self.rootExpression reformatWithContextManager:_formattingContextManager animationType:animationType];
//    _maxSlideTransitionIndex = _formattingContextManager.maxSlideCounter; // FIXME: disabling this, the idea was to allow slide fragments to influence the number of slides in the page, but for now maybe it's better to require adding "pause" commands explicitly. Maybe improve this at some later point, this would require taking a bit more care keeping track of slide fragments and their ranges of visible slides during incremental typesetting
    _slideTransitions = _formattingContextManager.slideTransitions;
    [self adjustContentViewHeight];
}

- (void)adjustContentViewHeight
{
    // Adjust the frame of the document view and the position of the root expression so the root expression content fits in the document view and we have the correct top and bottom margins
    MHDimensions rootExpressionDimensions = _rootExpression.dimensions;
    MHPageViewerView *myView = self.view;

    _contentSize = NSMakeSize(_pageWidth, rootExpressionDimensions.depth + _pageTopMargin + _pageBottomMargin);
    myView.contentSize = _contentSize;
}

- (void)syncRootExpressionToContentView
{
    MHPageViewerView *myView = self.view;
    NSRect myViewBounds = myView.bounds;
    NSRect contentViewBounds = myView.contentViewBounds;
    
    CGFloat magnification = myViewBounds.size.width / _contentSize.width;
    
    NSPoint newPosition = NSMakePoint(-contentViewBounds.origin.x * magnification
                                           ,(_contentSize.height - _pageTopMargin) * magnification - contentViewBounds.origin.y);
    
    bool contentFitsInOneScreen = (_contentSize.height * magnification < myViewBounds.size.height);
    if (contentFitsInOneScreen) {
        newPosition.y += myViewBounds.size.height - _contentSize.height * magnification;
    }
    
    _rootExpression.position = newPosition;
    [_rootExpression.spriteKitNode setScale:magnification];
    

    if (myView.programmaticallyInitiatedScrollCounter == 0) {
        // this code calculates the text range in the source code corresponding to the currently visible paragraphs
        // it is based on the -enumerateBodiesInRect:usingBlock: method of SKPhysicsWorld
        
        // FIXME: this works pretty well but there is some room for improvement, for example we scan each paragraph from the beginning and end to find expressions that have a code range of length more than zero. But it would be better if all expressions mapped to the code (something I still need to fix in the MHParser+TextMode and MHParser+MathMode class files). Also, this calculation would make more sense as a separate method in MHParagraph or one of the other container classes that works out the union of code ranges of the component subexpressions. So, it would be good to address these issues at some point.
        
        CGSize mySize = self.size;
        static const CGFloat verticalPaddingForScrolling = 20.0;
        CGRect myBoundsEnlarged = NSMakeRect(0.0, -verticalPaddingForScrolling, mySize.width, mySize.height + verticalPaddingForScrolling);
        static NSRange codeRangeForVisibleExpressions;
        codeRangeForVisibleExpressions = NSMakeRange(0, 0);
        static bool firstParagraphEncountered;
        firstParagraphEncountered = false;
        [self.physicsWorld enumerateBodiesInRect:myBoundsEnlarged usingBlock:^(SKPhysicsBody *physicsBody, BOOL *stop) {
            SKNode *physicsBodyNode = physicsBody.node;
            MHParagraph *paragraph = (MHParagraph *)(physicsBodyNode.ownerExpression); // it's okay to assume it's an MHParagraph, since only expressions of that type have a physics body
            NSRange paragraphCodeRange;
            NSArray <MHExpression *> *paragraphSubexpressions = paragraph.subexpressions;
            NSUInteger numberOfSubexpressions = paragraphSubexpressions.count;
            if (numberOfSubexpressions > 0) {
                NSUInteger subexpIndex = 0;
                MHExpression *subexp;
                NSRange subexpCodeRange = NSMakeRange(0, 0);
                while (subexpCodeRange.length == 0 && subexpIndex < numberOfSubexpressions) {
                    subexp = paragraphSubexpressions[subexpIndex];
                    subexpCodeRange = subexp.codeRange;
                    subexpIndex++;
                }
                if (subexpIndex == numberOfSubexpressions) {
                    paragraphCodeRange = subexpCodeRange;
                }
                else if (subexpIndex < numberOfSubexpressions) {
                    NSUInteger secondSubexpIndex = numberOfSubexpressions-1;
                    MHExpression *secondSubexp;
                    NSRange secondSubexpCodeRange = NSMakeRange(0, 0);
                    while (secondSubexpCodeRange.length == 0 && secondSubexpIndex >= subexpIndex) {
                        secondSubexp = paragraphSubexpressions[subexpIndex];
                        secondSubexpCodeRange = secondSubexp.codeRange;
                        secondSubexpIndex--;
                    }
                    if (secondSubexpCodeRange.length > 0) {
                        paragraphCodeRange = NSUnionRange(subexpCodeRange, secondSubexpCodeRange);
                    }
                    else {
                        paragraphCodeRange = subexpCodeRange;
                    }
                }
                
                if (paragraphCodeRange.length > 0) {
                    if (codeRangeForVisibleExpressions.length > 0) {
                        codeRangeForVisibleExpressions = NSUnionRange(codeRangeForVisibleExpressions, paragraphCodeRange);
                    }
                    else {
                        codeRangeForVisibleExpressions = paragraphCodeRange;
                    }
                }
            };
        }];
        
        if (codeRangeForVisibleExpressions.length > 0) {
            NSValue *rangeValue = [NSValue valueWithRange:codeRangeForVisibleExpressions];
            NSDictionary *userInfo = @{ kMHSpriteKitSceneSelectionCodeRangeKey : rangeValue };
            [[NSNotificationCenter defaultCenter] postNotificationName:kMHSpriteKitSceneScrolledNotification
                                                                object:self
                                                              userInfo:userInfo];
        }
    }
}


- (void)compiledExpressionChangedTo:(MHVerticalLayoutContainer *)newExpression
                         changeType:(MHExpressionCompiledExpressionUpdateType)changeType
             firstAffectedParagraph:(MHParagraph * _Nullable)firstParagraph
                     paragraphIndex:(NSUInteger)paragraphIndex
            secondAffectedParagraph:(MHParagraph * _Nullable)secondParagraph
{
    switch (changeType) {
        case MHCompiledExpressionUpdateTypeCompilation:
            self.rootExpression = newExpression;
            break;
        case MHCompiledExpressionUpdateTypeParagraphUpdate:
        case MHCompiledExpressionUpdateTypeParagraphInsertion:
        case MHCompiledExpressionUpdateTypeParagraphDeletion:
        case MHCompiledExpressionUpdateTypeParagraphMerge: {
            if ([_rootExpression conformsToProtocol:@protocol(MHIncrementalTypesetting)]) {
                [(MHHorizontalLayoutContainer <MHIncrementalTypesetting> *)_rootExpression
                 retypesetParagraphsInRange:NSMakeRange(paragraphIndex, 1) withContextManager:_typesettingContextManager];
                [self adjustContentViewHeight];
            }
        }
            break;
        case MHCompiledExpressionUpdateTypeParagraphSplit: {
            if ([_rootExpression conformsToProtocol:@protocol(MHIncrementalTypesetting)]) {
                [(MHHorizontalLayoutContainer <MHIncrementalTypesetting> *)_rootExpression
                 retypesetParagraphsInRange:NSMakeRange(paragraphIndex, 2) withContextManager:_typesettingContextManager];
                [self adjustContentViewHeight];
            }
        }
            break;
        default:
            NSLog(@"not expecting this to happen");
    }
    
    _maxSlideTransitionIndex = newExpression.numberOfSlideTransitions;
}


#pragma mark - User actions


- (void)mouseMoved:(NSEvent *)event
{
    CGPoint point = [event locationInNode:self];
    
    SKNode *eventNode = [self nodeAtPoint:point];
    
    SKNode *eventNodeAncestor = eventNode.mouseClickAcceptingAncestor;
    
    MHExpression *eventExpression = eventNode.ownerExpression;
    self.selectedExpression = eventExpression;
   
    // FIXME: badly written code to implement useful mouse cursor behavior for links - improve, and see the setHighlighted method of MHLink
    while (eventExpression) {
        if (eventExpression.spriteKitNode.ownerExpressionAcceptsMouseClicks) {
            [[NSCursor pointingHandCursor] set];
            self.selectedExpression = eventExpression;
            NSString *auxiliaryText = [eventExpression mouseHoveringAuxiliaryTextWithHoveringNode:eventNode];
            self.mouseHoveringAuxiliaryText = auxiliaryText;
            return;
        }
        eventExpression = eventExpression.parent;
    }
    if (eventNodeAncestor) {
        [[NSCursor pointingHandCursor] set];
        NSString *auxiliaryText = [eventNodeAncestor.ownerExpression mouseHoveringAuxiliaryTextWithHoveringNode:eventNode];
        self.mouseHoveringAuxiliaryText = auxiliaryText;
    }
    else {
        [[NSCursor arrowCursor] set];
        self.mouseHoveringAuxiliaryText = nil;
    }
}

- (void)mouseDown:(NSEvent *)event
{
    CGPoint point = [event locationInNode:self];
    
    SKNode *clickedNode = [self nodeAtPoint:point];
    
    SKNode *ancestor = clickedNode.mouseClickAcceptingAncestor;
    if (ancestor) {
        MHExpression *ownerExpression = ancestor.ownerExpression;
        [ownerExpression mouseClickWithEvent:event subnode:ancestor];
        
        // Update the mouse hovering auxiliary text
        NSString *auxiliaryText = [ancestor.ownerExpression mouseHoveringAuxiliaryTextWithHoveringNode:clickedNode];
        self.mouseHoveringAuxiliaryText = auxiliaryText;
        return;
    }
    
    MHExpression *clickedExpression = clickedNode.ownerExpression;
    self.selectedExpression = clickedExpression;
    
    if (clickedExpression != nil) {
        NSRange codeRange = clickedExpression.codeRange;
        if (codeRange.length > 0) {
            NSValue *rangeValue = [NSValue valueWithRange:codeRange];
            NSDictionary *userInfo = @{ kMHSpriteKitSceneSelectionCodeRangeKey : rangeValue };
            [[NSNotificationCenter defaultCenter] postNotificationName:kMHSpriteKitSceneSelectionChangedNotification
                                                                object:self
                                                              userInfo:userInfo];
        }
    }
}

- (void)keyDown:(NSEvent *)event
{
    // Here I am intercepting " " ("space bar") keystrokes and on such a keystroke scroll the page viewer view down a screen
    // This should be unnecessary since there is also a menu item in the Navigate menu that does the same thing, but it seems
    // impossible to assign a menu item a keyboard shortcut of "space"
    // See this related discussion: https://stackoverflow.com/questions/11155239/nsmenuitem-keyequivalent-space-bug
    NSString *characters = [event characters];
    if ([characters isEqualToString:@" "]) {
        NSEventModifierFlags modifierFlags = event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask;
        if (modifierFlags == 0)
            [self.view scrollPageDown:nil];
        else if (modifierFlags == NSEventModifierFlagFunction)
            [self.view scrollPageUp:nil];
        else
            [super keyDown:event];
    }
    else {
        [super keyDown:event];
    }
}



#pragma mark - Other

- (MHExpression *)selectedExpression
{
    return _selectedExpression;
}

- (void)setSelectedExpression:(MHExpression *)selectedExpression
{
    if (selectedExpression != _selectedExpression) {
        [self.view wakeUpForContentRefresh];
        if (_selectedExpression)
            _selectedExpression.highlighted = false;
        _selectedExpression = selectedExpression;
        _selectedExpression.highlighted = true;
    }
}

- (NSString *)mouseHoveringAuxiliaryText
{
    NSTextField *hoveringLabel = (NSTextField *)[self.view viewWithTag:333];
    return hoveringLabel.stringValue;
}

- (void)setMouseHoveringAuxiliaryText:(NSString *)text
{
    NSView *myView = self.view;
    NSTextField *hoveringLabel = (NSTextField *)[myView viewWithTag:333];
    if (!text) {
        [hoveringLabel removeFromSuperview];
        return;
    }
    if (!hoveringLabel) {
        hoveringLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(0.0, 10.0, 0.0, 0.0)];
        hoveringLabel.bordered = false;
        hoveringLabel.editable = NO;
        hoveringLabel.tag = 333;
        hoveringLabel.textColor = [NSColor blackColor];
        hoveringLabel.backgroundColor = [NSColor colorWithWhite:0.9 alpha:0.85];
        hoveringLabel.cell.truncatesLastVisibleLine = true;
        [myView addSubview:hoveringLabel];
    }
    hoveringLabel.stringValue = text;
    [hoveringLabel sizeToFit];
    NSRect myViewBounds = myView.bounds;
    NSRect hoveringLabelFrame = hoveringLabel.frame;
    if (hoveringLabelFrame.size.width + 20.0 > myViewBounds.size.width)
        hoveringLabelFrame.size.width = myViewBounds.size.width - 20.0;
    hoveringLabelFrame.origin.x = myViewBounds.size.width - 6.0 - hoveringLabelFrame.size.width;
    hoveringLabel.frame = hoveringLabelFrame;
}

- (void)invokeIntralinkToNotebookPage:(NSString *)pageName slideNumber:(NSInteger)slideNumber
{
    NSDictionary *goToPageNotificationInfo = @{
        kMHSpriteKitSceneGoToPageNotificationPageNameKey : pageName,
        kMHSpriteKitSceneGoToPageNotificationSlideNumberKey : [NSNumber numberWithInteger:slideNumber]
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:kMHSpriteKitSceneGoToPageNotification
                                                        object:self
                                                      userInfo:goToPageNotificationInfo];
}

- (NSObject <MHResourceProvider> *)resourceProvider
{
    return _typesettingContextManager.resourceProvider;
}

- (void)setResourceProvider:(NSObject<MHResourceProvider> *)resourceProvider
{
    _typesettingContextManager.resourceProvider = resourceProvider;
}





@end
