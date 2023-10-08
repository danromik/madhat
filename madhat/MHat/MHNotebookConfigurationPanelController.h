//
//  MHNotebookConfigurationPanelController.h
//  MadHat
//
//  Created by Dan Romik on 8/28/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MHNotebook.h"
#import "MHParser.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHNotebookConfigurationPanelController : NSWindowController <MHParserDelegate>

@property MHSourceCodeTextView *configurationCodeEditorView;

@property (weak) MHNotebook *parentNotebook;
@property NSString *configurationCode;
@property MHSourceCodeEditorTheme *editorTheme;

@end

NS_ASSUME_NONNULL_END
