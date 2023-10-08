//
//  MHCheckboxNode.h
//  MadHat
//
//  Created by Dan Romik on 11/1/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MadHat.h"
#import "MHTextualElementNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHCheckboxNode : MHTextualElementNode

@property bool checked;

+ (instancetype)checkboxNode:(bool)checked;

- (void)toggle;


@end

NS_ASSUME_NONNULL_END
