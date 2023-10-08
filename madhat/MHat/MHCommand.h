//
//  MHCommand.h
//  MadHat
//
//  Created by Dan Romik on 10/31/19.
//  Copyright © 2019 Dan Romik. All rights reserved.
//

#import "MHContainer.h"
#import "MHHorizontalLayoutContainer.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MHCommand

// FIXME: think about whether the argument should be an MHExpression or an MHHorizontalLayoutContainer (currently going with MHHorizontalLayoutContainer)
+ (MHExpression *)commandNamed:(NSString *)name withParameters:(nullable NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument;


+ (NSArray <NSString *> *)recognizedCommands;   // returns an array of the commands the class knows how to handle

@end



@interface MHCommand : MHContainer <MHCommand>

@property (readonly) NSString *name;
@property (readonly) NSDictionary *parameters;
@property MHHorizontalLayoutContainer *argument;
@property (readonly) MHExpression *resolvedArgument;    // default behavior is to return the argument as is. Subclasses can implement to do more interesting things with their arguments


+ (instancetype)commandNamed:(NSString *)name withParameters:(nullable NSDictionary *)parameters argument:(MHHorizontalLayoutContainer *)argument;


@end

NS_ASSUME_NONNULL_END
