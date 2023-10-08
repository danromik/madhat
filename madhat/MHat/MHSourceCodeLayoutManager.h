//
//  MHSourceCodeLayoutManager.h
//  MadHat
//
//  Created by Dan Romik on 8/7/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//
//  A layout manager to implement a custom text selection color which applies to an NSTextView regardless of whether it is in focus
//  The idea comes from this stack overflow question:
//  https://stackoverflow.com/questions/16073233/how-can-i-set-nstextview-selectedtextattributes-on-a-background-window
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface MHSourceCodeLayoutManager : NSLayoutManager

@property NSColor *textSelectionColor;

@end

NS_ASSUME_NONNULL_END
