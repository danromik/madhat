//
//  MHSourceCodeTextView+UserEditingHandler.h
//  MadHat
//
//  Created by Dan Romik on 1/14/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import <AppKit/AppKit.h>


#import "MHSourceCodeTextView.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHSourceCodeTextView (UserEditingHandler) <MHSourceCodeTextStorageSmallEditsDelegate>

@end

NS_ASSUME_NONNULL_END
