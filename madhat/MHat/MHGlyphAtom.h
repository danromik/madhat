//
//  MHGlyphAtom.h
//  MadHat
//
//  Created by Dan Romik on 7/10/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHExpression.h"
#import "MHCommand.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHGlyphAtom : MHExpression <MHCommand>
{
@protected
    NSString *_glyphName;    // subclasses can access this
}

@property (nonatomic, readonly) NSString *glyphName;

+ (instancetype)glyphAtomWithGlyphName:(NSString *)glyphName;

@end

NS_ASSUME_NONNULL_END
