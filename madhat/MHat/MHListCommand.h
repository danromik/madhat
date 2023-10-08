//
//  MHListCommand.h
//  MadHat
//
//  Created by Dan Romik on 8/8/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHCommand.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum {
    MHListCommandListIndent,
    MHListCommandListUnindent,
    MHListCommandUnnumberedItem,
    MHListCommandNumberedItem,
    MHListCommandCheckboxItem,
    MHListCommandCollapsibleSectionStartMarker
} MHListCommandType;


@interface MHListCommand : MHCommand <MHOutlinerItemMarker>

@property (readonly) MHListCommandType type;

+ (instancetype)listCommandWithType:(MHListCommandType)type;

@end

NS_ASSUME_NONNULL_END
