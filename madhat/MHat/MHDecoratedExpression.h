//
//  MHDecoratedExpression.h
//  MadHat
//
//  Created by Dan Romik on 12/21/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import "MHWrapper.h"
#import "MHCommand.h"


typedef enum {
    MHDecorationOverbar,
    MHDecorationUnderbar,
    MHDecorationCustomStringOverscript  // used for hat, tilde, arrow, dot, etc. overscript decorations
} MHDecorationType;



NS_ASSUME_NONNULL_BEGIN

@interface MHDecoratedExpression : MHWrapper <MHCommand>

@property MHExpression *body;

// Constructor for any decoration type that is not of the custom string type
+ (instancetype)decoratedExpressionWithContents:(MHExpression *)contents
                                 decorationType:(MHDecorationType)decorationType
                                 verticalOffset:(short int)offset;

// Constructor for custom string decorations
+ (instancetype)decoratedExpressionWithContents:(MHExpression *)contents
                               decorationString:(NSString *)decorationString
                                 verticalOffset:(short int)offset;


@end

NS_ASSUME_NONNULL_END
