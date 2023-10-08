//
//  MHImage.h
//  MadHat
//
//  Created by Dan Romik on 10/18/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHExpression.h"
#import "MHCommand.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kMHImageCommandName;


@interface MHImage : MHExpression <MHCommand>

+ (instancetype)imageWithImageIdentifier:(NSString *)identifier;
+ (instancetype)imageWithMadHatLogo;

@end

NS_ASSUME_NONNULL_END
