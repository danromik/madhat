//
//  MHAnnotatedHorizontalExtensibleSymbol.h
//  MadHat
//
//  Created by Dan Romik on 10/6/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHContainer.h"
#import "MHCommand.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHAnnotatedHorizontalExtensibleSymbol : MHContainer <MHCommand>


+ (instancetype)horizontalExtensibleSymbolWithSymbolType:(MHHorizontalExtensibleSymbolType)symbolType
                                           topAnnotation:(MHExpression *)topAnnotation
                                        bottomAnnotation:(MHExpression *)bottomAnnotation
                                             positioning:(MHHorizontalExtensibleSymbolPositioning)positioning;


@end

NS_ASSUME_NONNULL_END
