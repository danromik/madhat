//
//  AppDelegate.h
//  MadHat
//
//  Created by Dan Romik on 12/22/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate>

- (void)openHelpPage:(NSString *)pageName;
- (void)openHelpPageForCommandName:(NSString *)commandName;
- (void)openHelpPagesForSpecialSymbols;
- (void)openHelpPagesForNotebookConfiguration;


@end

