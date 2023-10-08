//
//  MHNotebookPage.m
//  MadHat
//
//  Created by Dan Romik on 6/13/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MadHat.h"
#import "MHNotebookPage.h"
#import "MHNotebook.h"
#import "MHNotebookConfiguration.h"
#import "MHNotebook+AssetLibrary.h"
#import "MHMathFontEditorController.h"
#import "MHTextNode.h"
#import "MHPDFRenderingContextManager.h"

NSString * const kMHNotebookPageDefaultFilenameLocalized = @"Untitled";

NSString * const kMHNotebookPageShowTransientStatusMessageNotification = @"MHNotebookPageShowTransientStatusMessageNotification";
NSString * const kMHNotebookPageShowTransientStatusMessageMessageKey = @"statusMessage";

@interface MHNotebookPage ()
{
    MHPageViewerView *_pageViewerView;
    MHSourceCodeTextView *_sourceCodeEditorView;
    
    MHNotebookConfiguration *_notebookConfiguration;

    NSString *_filename;
    __weak NSTextField *_codeStatusLabel;
    __weak NSTextField *_pageViewerStatusLabel;
    __weak BFPageControl *_slideTransitionPageControl;
    __weak NSProgressIndicator *_slideTransitionProgressIndicator;

    // Variables related to the state of the page
    // (Currently there's only the slide transition index, in the future there will be additional state data)
    NSUInteger _slideTransitionIndex;
    
    bool _pageIsActive;
    
    bool _slideTransitionIsInProgress;
    double _slideTransitionInProgressDelay;
    double _pausedSlideTransitionTimeElapsed;
    NSTimer *_slideTransitionTimer;
    NSTimer *_slideTransitionProgressUpdateTimer;   // FIXME: it might be better to subclass NSProgressIndicator and refactor/offload some of the complexity of handling these progress updates to the subclass
    
    bool _outlinerNodesMayBeCollapsed;  // quick and dirty mechanism to keep track of whether we have collapsed outliner nodes, to make the -snapToFullyExpandedStateAndStopAnimations method call more efficient. FIXME: will probably need to be replaced with something a bit more refined when I add more outliner-related features
}

@property MHSpriteKitScene *pageScene;

@end

@implementation MHNotebookPage

#pragma mark - Initialization

- (instancetype)initWithNotebookConfiguration:(MHNotebookConfiguration *)notebookConfiguration
{
    if (self = [super init]) {
        _notebookConfiguration = notebookConfiguration;
        NSSize pageSize = _notebookConfiguration.pageSize;
        
        // Create the Sprite Kit scene
        MHSpriteKitScene *pageScene = [[MHSpriteKitScene alloc] initWithPageWidth:pageSize.width];
        pageScene.presentationMode = MHExpressionPresentationModePublishing;   // Setting this as the default for now
        self.pageScene = pageScene;
        
        [pageScene setNotebookConfiguration:_notebookConfiguration];

        // Create the page viewer view
        MHPageViewerView *pageViewerView = [[MHPageViewerView alloc]
                                            initWithFrame:NSMakeRect(0,0, pageSize.width, pageSize.height)];
        _pageViewerView = pageViewerView;

        // Create the source code editor view
        _sourceCodeEditorView = [[MHSourceCodeTextView alloc] initWithFrame:NSZeroRect textContainer:nil];
        
        // Create a parser that would be assigned as a code editing delegate of the source code editor view, and for which the Sprite Kit scene would act as a delegate
        // FIXME: is this a logical structure? Re-examine the relationship between these classes and think if the setup can be improved
        MHParser *parser = [[MHParser alloc] init];
        parser.delegate = self.pageScene;
        self.sourceCodeEditorView.codeEditingDelegate = parser;

        // Initialize the filename to the default name and the code to an empty string
        self.filename = NSLocalizedString(kMHNotebookPageDefaultFilenameLocalized, @"");
        self.code = @"";
        
        // Present the Sprite Kit scene
        [self.pageViewerView presentScene:self.pageScene];
    }
    return self;
}



#pragma mark - User actions

- (void)selectionChangedInSourceCodeEditorView:(NSNotification *)notification
{
    MHExpression *expression = notification.userInfo[kMHSourceCodeTextViewSelectionExpression];
    if (expression && ![expression isMemberOfClass:[MHExpression class]]) { // FIXME: this is not a good way to test for the expression being something that can be scrolled to
        [self.pageViewerView wakeUpForContentRefresh];
        self.pageScene.selectedExpression = expression;
        [self.pageViewerView scrollToExpression:expression];
    }
}

- (void)sourceCodeEditorViewScrolled:(NSNotification *)notification
{
    MHExpression *expression = notification.userInfo[kMHSourceCodeTextViewSelectionExpression];
    if (expression && ![expression isMemberOfClass:[MHExpression class]]) { // FIXME: this is not a good way to test for the expression being something that can be scrolled to
//        self.pageScene.selectedExpression = expression;     // can be useful for debugging
        [self.pageViewerView scrollToExpression:expression];
    }
}

- (void)selectionChangedInPageScene:(NSNotification *)notification
{
    [self.pageViewerView wakeUpForContentRefresh];
    NSValue *rangeValue = notification.userInfo[kMHSpriteKitSceneSelectionCodeRangeKey];
    NSRange range = [rangeValue rangeValue];
    self.sourceCodeEditorView.selectedRange = range;
    [self.sourceCodeEditorView scrollRangeToVisibleWithAnimation:range];
}

- (void)pageSceneScrolled:(NSNotification *)notification
{
    NSValue *rangeValue = notification.userInfo[kMHSpriteKitSceneSelectionCodeRangeKey];
    NSRange range = [rangeValue rangeValue];
    [self.sourceCodeEditorView scrollRangeToVisibleWithAnimation:range];
}


// note: this gets called after the code text changed, but before the new code got reparsed/typeset
- (void)textDidChange:(NSNotification *)notification
{
    [self snapToFullyExpandedStateAndStopAnimations];
    [self.pageViewerView wakeUpForContentRefresh];
    [self.notebook contentsChangedForPage:self];
}

- (void)codeWasRetypesetFollowingTextChange:(NSNotification *)notification
{
    [self updatePageStatusUserInterfaceElements];
    [self moveToLastSlide];     // this will usually have no effect since snapToFullyExpandedStateAndStopAnimations was called just before, but it will make a difference when the user enters a new "pause" command, in which case the number of slides will increase during retypesetting
}

- (void)pageControl: (BFPageControl *)pageControl didSelectPageAtIndex: (NSInteger)index
{
    [self setSlideTransitionIndex:index animated:false];
}

- (void)outlinerNodeToggled:(NSNotification *)notification
{
    MHExpression <MHOutlinerItemParagraph> *outlinerItemParagraph = notification.object;
    MHExpression *rootAncestor = outlinerItemParagraph.rootAncestor;
    if ([rootAncestor isEqual:self.pageScene.rootExpression]) {     // check if the notification is from our page
        [self.pageViewerView wakeUpForContentRefresh];
        [self.pageScene reformatRootExpressionWithSlideTransitionIndex:_slideTransitionIndex animationType:MHReformattingAnimationTypeOutliner];
        _outlinerNodesMayBeCollapsed = true;
    }
}

- (void)showTransientStatusMessage:(NSNotification *)notification
{
    MHExpression *sendingExpression = notification.object;
    MHExpression *rootAncestor = sendingExpression.rootAncestor;
    if ([rootAncestor isEqual:self.pageScene.rootExpression]) {     // check if the notification is from our page
        [self.pageViewerView wakeUpForContentRefresh];
        NSString *statusMessage = notification.userInfo[kMHNotebookPageShowTransientStatusMessageMessageKey];
        
        NSView *viewerWindowContentView = self.pageViewerView.window.contentView;
        NSRect viewerWindowContentViewBounds = viewerWindowContentView.bounds;
        
        // FIXME: make this adjustable to fit messages of different lengths
        static double statusMessageViewWidth = 200.0;
        static double statusMessageViewHeight = 100.0;
        
        NSRect statusMessageViewBounds = NSMakeRect((viewerWindowContentViewBounds.size.width - statusMessageViewWidth)/2.0,
                                                    (viewerWindowContentViewBounds.size.height - statusMessageViewHeight)/2.0,
                                                    statusMessageViewWidth,
                                                    statusMessageViewHeight);
        NSView *statusMessageView = [[NSView alloc] initWithFrame:statusMessageViewBounds];
        statusMessageView.wantsLayer = YES;
        statusMessageView.layer.backgroundColor = [[NSColor colorWithWhite:0.25 alpha:0.95] CGColor];
        statusMessageView.layer.cornerRadius = 20.0;
        
        NSRect textFieldBounds = NSMakeRect(0.0, 0.0, statusMessageViewWidth, statusMessageViewHeight);
        NSTextField *textField = [[NSTextField alloc] initWithFrame:textFieldBounds];
        textField.stringValue = statusMessage;
        textField.textColor = [NSColor colorWithWhite:0.75 alpha:1.0];
        textField.font = [NSFont systemFontOfSize:24.0];
        textField.alignment = NSTextAlignmentCenter;
        textField.editable = NO;
        textField.bordered = NO;
        textField.drawsBackground = NO;
        [textField sizeToFit];
        textFieldBounds = textField.bounds;
        textFieldBounds.origin.x = (statusMessageViewWidth - textFieldBounds.size.width) / 2.0;
        textFieldBounds.origin.y = (statusMessageViewHeight - textFieldBounds.size.height) / 2.0;
        textField.frame = textFieldBounds;

        [statusMessageView addSubview:textField];

        
        [viewerWindowContentView addSubview:statusMessageView];
        [self performSelector:@selector(removeTransientStatusMessage:)
                   withObject:statusMessageView
                   afterDelay:1.0];
    }
}

- (void)removeTransientStatusMessage:(NSView *)statusMessageView
{
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.75;
        statusMessageView.animator.alphaValue = 0.0;
    } completionHandler:^{
        [statusMessageView removeFromSuperview];
    }];
}

- (void)goToPageNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSString *pageName = userInfo[kMHSpriteKitSceneGoToPageNotificationPageNameKey];
    NSNumber *slideNumberObject = userInfo[kMHSpriteKitSceneGoToPageNotificationSlideNumberKey];
    if (!slideNumberObject) {
        [self.notebook goToPageNamed:pageName];
    }
    else {
        NSInteger slideNumber = [slideNumberObject integerValue];
        [self.notebook goToPageNamed:pageName slideNumber:slideNumber];
    }
}


#pragma mark - Miscellaneous methods


- (void)updatePageStatusUserInterfaceElements
{
    NSTextField *codeStatusLabel = self.codeStatusLabel;
    if (codeStatusLabel) {
        codeStatusLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"%@ (%lu characters)",@""),
                                       self.filenameWithExtension, (unsigned long)self.sourceCodeEditorView.string.length];
    }

    NSTextField *pageViewerStatusLabel = self.pageViewerStatusLabel;
    if (pageViewerStatusLabel) {
        pageViewerStatusLabel.stringValue = self.filename;
        [pageViewerStatusLabel sizeToFit];
        NSRect pageViewerStatusLabelFrame = pageViewerStatusLabel.frame;
        BFPageControl *slideTransitionPageControl = self.slideTransitionPageControl;
        NSUInteger numberOfPages = self.pageScene.maxSlideTransitionIndex+1;
        slideTransitionPageControl.numberOfPages = numberOfPages;
        slideTransitionPageControl.currentPage = self.slideTransitionIndex;
        slideTransitionPageControl.frame = NSZeroRect;
        NSSize slideTransitionPageControlSize = [slideTransitionPageControl sizeForNumberOfPages:numberOfPages];
        NSRect newSlideTransitionPageControlFrame =
            NSMakeRect(pageViewerStatusLabelFrame.origin.x + pageViewerStatusLabelFrame.size.width + 12.0,
                       pageViewerStatusLabelFrame.origin.y + pageViewerStatusLabelFrame.size.height/2.0
                       - slideTransitionPageControlSize.height/2.0,
                       slideTransitionPageControlSize.width, slideTransitionPageControlSize.height);
        slideTransitionPageControl.frame = newSlideTransitionPageControlFrame;
        
        NSRect slideTransitionProgressIndicatorFrame = _slideTransitionProgressIndicator.frame;
        NSRect newSlideTransitionProgressIndicatorFrame = slideTransitionProgressIndicatorFrame;
        newSlideTransitionProgressIndicatorFrame.origin.x = newSlideTransitionPageControlFrame.origin.x
                                                                + newSlideTransitionPageControlFrame.size.width + 10.0;
        _slideTransitionProgressIndicator.frame = newSlideTransitionProgressIndicatorFrame;
    }
}

- (void)mathFontParametersChanged:(NSNotification *)notification
{
//    NSLog(@"mathFontParametersChanged");
    self.pageScene.rootExpression = self.pageScene.rootExpression;    // FIXME: bad coding alert - temporary
}

- (NSString *)exportedLaTeXValue
{
    return self.pageScene.rootExpression.exportedLaTeXValue;
}

#pragma mark - Navigation

- (void)scrollToTop
{
    [self.pageViewerView scrollToTop:true];
}

- (void)scrollToBottom
{
    [self.pageViewerView scrollToBottom:true];
}



- (void)moveToFirstSlide
{
    self.slideTransitionIndex = 0;
}

- (bool)moveToNextSlide
{
    NSUInteger slideTransitionIndex = self.slideTransitionIndex;
    if (slideTransitionIndex < self.pageScene.maxSlideTransitionIndex) {
        [self setSlideTransitionIndex:slideTransitionIndex+1 animated:true];
        return true;
    }
    return false;
}

- (bool)moveToPreviousSlide
{
    NSUInteger slideTransitionIndex = self.slideTransitionIndex;
    if (slideTransitionIndex > 0) {
        [self setSlideTransitionIndex:slideTransitionIndex-1 animated:false];   // skip the animations when going back
        return true;
    }
    return false;
}

- (void)transitionForward
{
    if (![self moveToNextSlide]) {
        [self.notebook programmaticallyGoToNextPage];
    }
}

- (void)transitionBackwards
{
    if (![self moveToPreviousSlide]) {
        if ([self.notebook programmaticallyGoToPreviousPage]) {
            [self.notebook.currentPage moveToLastSlide];
        }
    }
}

- (void)moveToLastSlide
{
    self.slideTransitionIndex = self.pageScene.maxSlideTransitionIndex;
}

- (void)snapToFullyExpandedStateAndStopAnimations
{
    [self.pageViewerView stopAllCurrentlyRunningAnimations];
    [self moveToLastSlide];
    if (_outlinerNodesMayBeCollapsed) {
        MHVerticalLayoutContainer *rootExpression = self.pageScene.rootExpression;
        for (MHParagraph *paragraph in rootExpression.subexpressions) {
            if ([paragraph conformsToProtocol:@protocol(MHOutlinerItemParagraph)]) {
                ((id <MHOutlinerItemParagraph>)paragraph).outlinerItemIsCollapsed = false;
            }
        }
        [self.pageScene reformatRootExpressionWithSlideTransitionIndex:_slideTransitionIndex animationType:MHReformattingAnimationTypeNone];
        
        _outlinerNodesMayBeCollapsed = false;
    }
}

- (void)expandContentAndStopAnimations
{
    [self.pageViewerView wakeUpForContentRefresh];
    [self snapToFullyExpandedStateAndStopAnimations];
}


- (void)pageWillBecomeActive
{
    // FIXME: I added this because I discovered this method is being called twice in succession. While this boolean helps avoid duplicate work, it might be better to address the core of the problem at some point and figure out why the method is called twice
    if (_pageIsActive)
        return;         // the page is already active, so no need to do anything

    // FIXME: is this the right place to register the resource provider?
    self.pageScene.resourceProvider = self.notebook;

    // Register for a bunch of notifications to keep informed of different user actions
    // FIXME: we're registering for a lot of notifications each time the page becomes active -- is this really the best approach from either a design or performance perspective?
    
    // Change in the source code text
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textDidChange:)
                                                 name:NSTextDidChangeNotification
                                               object:self.sourceCodeEditorView];

    // Code was retypeset
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(codeWasRetypesetFollowingTextChange:)
                                                 name:kMHSourceCodeTextViewSelectionCodeRecompiledNotification
                                               object:self.sourceCodeEditorView];

    // Change in selection in the source code editor
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(selectionChangedInSourceCodeEditorView:) name:kMHSourceCodeTextViewSelectionChangedNotification
                                               object:self.sourceCodeEditorView];

    // Change in selection in the page viewer
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(selectionChangedInPageScene:)
                                                 name:kMHSpriteKitSceneSelectionChangedNotification
                                               object:self.pageScene];
    
    // Scrolling the source code text
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sourceCodeEditorViewScrolled:) name:kMHSourceCodeTextViewScrolledNotification object:self.sourceCodeEditorView];
    
    // Scrolling in the page viewer
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(pageSceneScrolled:)
                                                 name:kMHSpriteKitSceneScrolledNotification
                                               object:self.pageScene];
        
    // Intralinks
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(goToPageNotification:)
                                                 name:kMHSpriteKitSceneGoToPageNotification
                                               object:self.pageScene];

    // Interactive toggles
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(outlinerNodeToggled:)
                                                 name:kMHInteractiveEventOutlinerNodeToggledNotification
                                               object:nil]; // FIXME: Maybe set it up so the notification is sent by the page scene view so we can give a specific object?
    
    // Status messages
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showTransientStatusMessage:)
                                                 name:kMHNotebookPageShowTransientStatusMessageNotification
                                               object:nil]; // The object of the notification is the string of the status message

    // Change in the math font parameters
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mathFontParametersChanged:)
                                                 name:kMHMathFontParametersChangedNotification
                                               object:nil];
    
}

- (void)pageDidBecomeActive
{
    _pageIsActive = true;
    [self.sourceCodeEditorView viewWasInstalledAsScrollViewDocumentView];
}

- (void)pageWillBecomeInactive
{
    // Unregister from notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.pageViewerView scrollToTop:false];
    
    _pageIsActive = false;
}



#pragma mark - Accessor methods

- (MHSourceCodeTextView *)sourceCodeEditorView
{
    return _sourceCodeEditorView;
}

- (MHPageViewerView *)pageViewerView
{
    return _pageViewerView;
}

- (NSString *)code
{
    return self.sourceCodeEditorView.string;
}

- (void)setCode:(NSString *)code
{
    self.sourceCodeEditorView.string = code;
}

- (MHNotebookConfiguration *)notebookConfiguration
{
    return _notebookConfiguration;
}

- (void)setNotebookConfiguration:(MHNotebookConfiguration *)notebookConfiguration
{
    _notebookConfiguration = notebookConfiguration;
    [self.pageScene setNotebookConfiguration:notebookConfiguration];
    [self.pageViewerView wakeUpForContentRefresh];
}

- (void)setPageStatusInterfaceElementsWithCodeStatusLabel:(NSTextField *)codeStatusLabel
                                    pageViewerStatusLabel:(NSTextField *)pageViewerStatusLabel
                               slideTransitionPageControl:(BFPageControl *)slideTransitionPageControl
                         slideTransitionProgressIndicator:(NSProgressIndicator *)slideTransitionProgressIndicator
{
    _codeStatusLabel = codeStatusLabel;
    _pageViewerStatusLabel = pageViewerStatusLabel;
    _slideTransitionPageControl = slideTransitionPageControl;
    _slideTransitionPageControl.delegate = self;
    _slideTransitionProgressIndicator = slideTransitionProgressIndicator;
    [self updatePageStatusUserInterfaceElements];
}

- (NSTextField *)codeStatusLabel
{
    return _codeStatusLabel;
}

- (NSTextField *)pageViewerStatusLabel
{
    return _pageViewerStatusLabel;
}

- (BFPageControl *)slideTransitionPageControl
{
    return _slideTransitionPageControl;
}

- (NSString *)filename
{
    return _filename;
}

- (void)setFilename:(NSString *)filename
{
    _filename = filename;
    
    [self updatePageStatusUserInterfaceElements];

//    // FIXME: this doesn't seem like a correct approach since the filename might be set when the page viewer view is not associated with a window
//    self.pageViewerView.window.title = filename;  // FIXME: also done in MHNotebook.m setCurrentPageIndexWithoutChangingFirstResponder method, violates DRY principle
}

- (NSString *)filenameWithExtension
{
    return [self.filename stringByAppendingPathExtension:@"txt"];
}

- (MHExpressionPresentationMode)presentationMode
{
    return self.pageScene.presentationMode;
}

- (void)setPresentationMode:(MHExpressionPresentationMode)presentationMode
{
    self.pageScene.presentationMode = presentationMode;
}


- (NSUInteger)slideTransitionIndex
{
    return _slideTransitionIndex;
}

- (void)setSlideTransitionIndex:(NSUInteger)newSlideTransitionIndex
{
    [self setSlideTransitionIndex:newSlideTransitionIndex animated:false];
}

- (void)setSlideTransitionIndex:(NSUInteger)newSlideTransitionIndex animated:(bool)animated
{
    if (_slideTransitionIndex == newSlideTransitionIndex || newSlideTransitionIndex > self.pageScene.maxSlideTransitionIndex)
        return;
    
    [self.pageViewerView wakeUpForContentRefresh];
    
    _slideTransitionIndex = newSlideTransitionIndex;
    [self.pageScene reformatRootExpressionWithSlideTransitionIndex:_slideTransitionIndex
                                                     animationType:(animated ? MHReformattingAnimationTypeSlideTransition :                 MHReformattingAnimationTypeNone)];
    [self updatePageStatusUserInterfaceElements];
    if (_slideTransitionIsInProgress) {
        _slideTransitionIsInProgress = false;
        [_slideTransitionTimer invalidate];
        _slideTransitionTimer = nil;
        [_slideTransitionProgressUpdateTimer invalidate];
        _slideTransitionProgressUpdateTimer = nil;
    }
    _slideTransitionInProgressDelay = 0.0;
    _pausedSlideTransitionTimeElapsed = 0.0;
    _slideTransitionProgressIndicator.doubleValue = 0.0;
    
    if (self.notebook.timedSlidePresentationRunning)
        [self startOrResumeSlidePresentation];
}

- (void)slideTransitionTimerFinished:(NSTimer *)timer
{
    _slideTransitionProgressIndicator.doubleValue = 0.0;
    _slideTransitionTimer = nil;
    [_slideTransitionProgressUpdateTimer invalidate];
    _slideTransitionProgressUpdateTimer = nil;
    _slideTransitionIsInProgress = false;
    [self transitionForward];
}

- (void)updateSlideTransitionProgressIndicator:(NSTimer *)timer
{
    _pausedSlideTransitionTimeElapsed += 0.01 * _slideTransitionInProgressDelay;
    [_slideTransitionProgressIndicator incrementBy:1.0];
}

- (void)pauseSlidePresentation
{
    if (_slideTransitionIsInProgress) {
        [_slideTransitionTimer invalidate];
        _slideTransitionTimer = nil;
        [_slideTransitionProgressUpdateTimer invalidate];
        _slideTransitionProgressUpdateTimer = nil;
        _slideTransitionIsInProgress = false;
    }
}

- (void)startOrResumeSlidePresentation
{
    NSArray <MHSlideTransition *> *slideTransitions = self.pageScene.slideTransitions;
    if (_slideTransitionIndex < slideTransitions.count) {
        MHSlideTransition *slideTransition = [self.pageScene.slideTransitions objectAtIndex:_slideTransitionIndex];
        NSTimeInterval delay = slideTransition.delayUntilTransition;
        if (delay > 0.0) {
            _slideTransitionIsInProgress = true;
            _slideTransitionInProgressDelay = delay;
            _slideTransitionTimer = [NSTimer scheduledTimerWithTimeInterval:_slideTransitionInProgressDelay - _pausedSlideTransitionTimeElapsed
                                                                     target:self
                                                                   selector:@selector(slideTransitionTimerFinished:)
                                                                   userInfo:nil
                                                                    repeats:NO];

            _slideTransitionProgressUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:_slideTransitionInProgressDelay/100.0
                                                                                   target:self
                                                                                 selector:@selector(updateSlideTransitionProgressIndicator:)
                                                                                 userInfo:nil
                                                                                  repeats:YES];
//            _slideTransitionProgressIndicator.hidden = NO;
        }
        else {
//            _slideTransitionProgressIndicator.hidden = YES;
        }
    }
    else {
//        _slideTransitionProgressIndicator.hidden = YES;
    }
}



#pragma mark - PDF output rendering

- (void)renderToPDFWithContextManager:(MHPDFRenderingContextManager *)contextManager
{
    [contextManager beginPDFPage];

    // add a PDF destination to serve as a target for notebook intralinks
    CGContextRef pdfContext = contextManager.pdfContext;
    NSString *destinationName = self.filename;
    static CGPoint point = { 100000.0, 100000.0 };
    CGPDFContextAddDestinationAtPoint(pdfContext, (__bridge CFStringRef)destinationName, point);

    [self.pageScene.rootExpression renderToPDFWithContextManager:contextManager];

    [contextManager endPDFPage];
}









- (void)retypeset
{
    [self.pageScene retypesetRootExpression];
}



#pragma mark - Search feature

- (NSUInteger)relevanceScoreForSearchString:(NSString *)searchString
{
    // FIXME: not a very good implementation. Improve
    
    NSRange searchStringRange = [self.filename rangeOfString:searchString options:NSCaseInsensitiveSearch];
    if (searchStringRange.location != NSNotFound)
        return 20;
    
    searchStringRange = [self.code rangeOfString:searchString options:NSCaseInsensitiveSearch];
    if (searchStringRange.location != NSNotFound)
        return 10;

    // if we reached this far, the page is not relevant for the search string
    return 0;
}


@end
