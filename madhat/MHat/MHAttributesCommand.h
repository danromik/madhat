//
//  MadHattributesCommand.h
//  MadHat
//
//  Created by Dan Romik on 9/9/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHCommand.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHAttributesCommand : MHCommand

- (NSDictionary < NSString *, MHExpression *> *)attributesDictionary;

@end

NS_ASSUME_NONNULL_END
