//
//  MHIssueReporterWindowController.h
//  MadHat
//
//  Created by Dan Romik on 8/14/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MHResourceDroppingView.h"


NS_ASSUME_NONNULL_BEGIN

@interface MHIssueReporterWindowController : NSWindowController <NSTextViewDelegate, NSTextFieldDelegate, MHResourceDroppingViewDelegate, NSURLSessionTaskDelegate>

@end

NS_ASSUME_NONNULL_END
