//
//  MHNotebookPage.h
//  MadHat
//
//  Created by Dan Romik on 6/13/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MHParser.h"
#import "MHSpriteKitScene.h"
#import "MHSourceCodeTextView.h"
#import "MHPageViewerView.h"
#import "BFPageControl.h"

NS_ASSUME_NONNULL_BEGIN

@class MHNotebook, MHNotebookConfiguration, MHPDFRenderingContextManager;

@interface MHNotebookPage : NSObject <NSTextViewDelegate, BFPageControlDelegate>

@property (weak) MHNotebook *notebook;


@property MHExpressionPresentationMode presentationMode;

@property NSString *filename;   // the page's filename, also used as a short display title for the page
@property (readonly) NSString *filenameWithExtension;
@property NSString *code;       // The source code of the page

@property MHNotebookConfiguration *notebookConfiguration;

// The two main views - source code editor and page viewer
@property (readonly) MHSourceCodeTextView *sourceCodeEditorView;
@property (readonly) MHPageViewerView *pageViewerView;

@property NSUInteger slideTransitionIndex;

// User interface elements the page has control over
// set the values for these properties together using the method call setPageStatusInterfaceElementsWith... below
@property (weak, readonly) NSTextField *codeStatusLabel;
@property (weak, readonly) NSTextField *pageViewerStatusLabel;
@property (weak, readonly) BFPageControl *slideTransitionPageControl;


- (instancetype)initWithNotebookConfiguration:(MHNotebookConfiguration *)notebookConfiguration; // Designated initializer


- (void)updatePageStatusUserInterfaceElements;  // FIXME: not sure if exposing this method is good OO practice
- (void)setPageStatusInterfaceElementsWithCodeStatusLabel:(nullable NSTextField *)codeStatusLabel
                                    pageViewerStatusLabel:(nullable NSTextField *)pageViewerStatusLabel
                               slideTransitionPageControl:(nullable BFPageControl *)slideTransitionPageControl
                         slideTransitionProgressIndicator:(nullable NSProgressIndicator *)slideTransitionProgressIndicator;



- (void)scrollToTop;
- (void)scrollToBottom;

- (void)moveToFirstSlide;             // Go to the page's initial state
- (bool)moveToNextSlide;        // Returns true if there was a next slide to move to
- (bool)moveToPreviousSlide;    // Returns true if there was a previous slide to move to
- (void)moveToLastSlide;

- (void)pauseSlidePresentation;
- (void)startOrResumeSlidePresentation;

- (void)expandContentAndStopAnimations;

- (void)pageWillBecomeActive;   // sent by the notebook to let the page know it is about to become active
- (void)pageDidBecomeActive;    // sent by the notebook to let the page know it became active
- (void)pageWillBecomeInactive; // sent by the notebook to let the page know it is about to become inactive


// PDF output rendering
- (void)renderToPDFWithContextManager:(MHPDFRenderingContextManager *)contextManager;

- (void)retypeset;


// Search feature implementation
- (NSUInteger)relevanceScoreForSearchString:(NSString *)searchString;       // a relevance score of 0 means the page should not be considered relevant for the search string


// Feature in development: exporting to LaTeX
- (NSString *)exportedLaTeXValue;

@end

NS_ASSUME_NONNULL_END
