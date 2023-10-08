//
//  MHDocumentController.h
//  MadHat
//
//  Created by Dan Romik on 8/11/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface MHDocumentController : NSDocumentController

- (NSURL *)urlForHelpPagesNotebook;

+ (BOOL)appConfigurationComplete;

@end

NS_ASSUME_NONNULL_END
