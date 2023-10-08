//
//  MHMiscCommand.h
//  MadHat
//
//  Created by Dan Romik on 12/2/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import "MHCommand.h"

NS_ASSUME_NONNULL_BEGIN

// FIXME: not sure if it's better to inherit from MHCommand or MHExpression. Currently doing MHExpression to give me the freedom to return an object of a different class from a call to the +commandNamed:... factory method.
// FIXME: if the class inherits from MHExpression, the source file should be moved outside the "MHCommand and subclasses" folder, and the class should probably be renamed
//@interface MHMiscCommand : MHCommand
@interface MHMiscCommand : MHExpression <MHCommand>

@end

NS_ASSUME_NONNULL_END
