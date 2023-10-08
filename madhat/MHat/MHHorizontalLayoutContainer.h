//
//  MHHorizontalLayoutContainer.h
//  MadHat
//
//  Created by Dan Romik on 10/23/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import "MadHat.h"
#import "MHLinearContainer.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHHorizontalLayoutContainer : MHLinearContainer <MHSplittableExpression, MHDecomposableForReformatting>


@property NSDictionary < NSString *, MHExpression * > *attributes;



// Some convenience constructors to create containers from text strings or arrays of strings:
+ (instancetype)containerWithPlainTextString:(NSString *)string;
+ (instancetype)formattedContainerWithArrayOfPlainTextStrings:(NSArray *)array;


@end


NS_ASSUME_NONNULL_END
