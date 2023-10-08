//
//  MHHelpNotebook.h
//  MadHat
//
//  Created by Dan Romik on 8/8/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHNotebook.h"
#import "MHHelpNotebookSearchField.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHHelpNotebook : MHNotebook <NSToolbarDelegate, MHHelpNotebookSearchFieldDelegate>

- (void)goToHomeHelpPage:(nullable id)sender;

@end

NS_ASSUME_NONNULL_END
