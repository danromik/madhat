//
//  MHInlineMathContainer.m
//  MadHat
//
//  Created by Dan Romik on 12/29/21.
//  Copyright © 2021 Dan Romik. All rights reserved.
//

#import "MHInlineMathContainer.h"

@implementation MHInlineMathContainer

- (NSString *) exportedLaTeXValue   //RS
{
    NSString * superExportedLatexValue = [super exportedLaTeXValue];
    return [NSString stringWithFormat: @"$%@$",superExportedLatexValue];
}


@end
