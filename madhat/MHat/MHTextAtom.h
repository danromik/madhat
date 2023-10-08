//
//  MHTextAtom.h
//  MadHat
//
//  Created by Dan Romik on 7/9/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHExpression.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHTextAtom : MHExpression
{
@protected
    NSString *_text;    // subclasses can access this
}


@property (nonatomic, readonly) NSString *text;

+ (instancetype)textAtomWithString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
