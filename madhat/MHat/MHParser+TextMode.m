//
//  MHParser+TextMode.m
//  MadHat
//
//  Created by Dan Romik on 1/5/20.
//  Copyright © 2020 Dan Romik. All rights reserved.
//

#import "MHParser+TextMode.h"
#import "MHParser+MathMode.h"
#import "MHTextAtom.h"
#import "MHWhitespace.h"
#import "MHScriptedExpression.h"
#import "MHPlaceholderCommand.h"
#import "MHVerticalLayoutContainer.h"
#import "MHListCommand.h"
#import "MHAttributesCommand.h"
#import "MHQuotedCodeExpression.h"
#import "MHQuotedCodeParagraph.h"

#import <AppKit/AppKit.h>



// FIXME: a major todo item is to refactor the code in a way that eliminates all cast operations, they are bad practice and represent assumptions about the way objects behave that aren't guaranteed by the interface


@implementation MHParser (TextMode)

- (MHHorizontalLayoutContainer *)parseTextModeCodeInRange:(NSRange)charRange
                               actuallyScannedRange:(NSRange *)scannedRangePointer
                                      rootContainer:(nullable MHHorizontalLayoutContainer *)rootContainer
{
    NSUInteger index;
    NSUInteger minIndex = charRange.location;
    NSUInteger maxIndex = charRange.location + charRange.length;
    NSUInteger beginningOfSemanticUnitIndex = 0;
    NSUInteger endOfSemanticUnitIndex = 0;
    
    NSMutableArray <MHExpression *> *attachedContentExpressions = [[NSMutableArray alloc] initWithCapacity:0];
    
    bool scanningDoubleQuotedBlock = false;
    
    char *codeColoringBuffer = [_characterTypeBytesMutableBuffer mutableBytes];
    
    MHHorizontalLayoutContainer *compiledTextExpression = (rootContainer != nil ? rootContainer : [MHHorizontalLayoutContainer expression]);
    
    MHHorizontalLayoutContainer *currentContainer = compiledTextExpression;
    MHParserState currentState = MHParserStateGeneric;
    MHParserCharType currentCharType;
    NSMutableString *currentWord;
    NSMutableString *currentCommand;
    unichar currentChar = 0;
    MHWhitespace *currentSpace;
    unichar currentMatchingCloseBracket = 0;        // used only for quoted code blocks and code annotation blocks
    MHListDelimiterType currentDelimiterType = MHListDelimiterTypePrimary;
    
    // Substitutions at the beginning of a paragraph
    if (rootContainer != nil) {
        // FIXME: this condition is what I'm using to test if we are parsing a paragraph or a block, but that relationship is not documented - improve
        
        if (charRange.length >=2
                    && [_codeString characterAtIndex:charRange.location]==kMHParserCharUnnumberedListItemFirstChar
                    && [_codeString characterAtIndex:charRange.location+1]==kMHParserCharUnnumberedListItemSecondChar) {
            // Unnumbered list item substitution
            MHListCommand *listCommand = [MHListCommand listCommandWithType:MHListCommandUnnumberedItem];
            [compiledTextExpression addSubexpression:listCommand];
            codeColoringBuffer[charRange.location] |= kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringCommandName;
            codeColoringBuffer[charRange.location+1] |= kMHParserSyntaxColoringCharacterScanned;
            minIndex += 2;
        }
        else if (charRange.length >=3
                    && [_codeString characterAtIndex:charRange.location]==kMHParserCharNumberedListItemFirstChar
                    && [_codeString characterAtIndex:charRange.location+1]==kMHParserCharNumberedListItemSecondChar
                    && [_codeString characterAtIndex:charRange.location+2]==kMHParserCharNumberedListItemThirdChar) {
            // Numbered list item substitution
            MHListCommand *listCommand = [MHListCommand listCommandWithType:MHListCommandNumberedItem];
            [compiledTextExpression addSubexpression:listCommand];
            codeColoringBuffer[charRange.location] |= kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringCommandName;
            codeColoringBuffer[charRange.location+1] |= kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringCommandName;
            codeColoringBuffer[charRange.location+2] |= kMHParserSyntaxColoringCharacterScanned;
            minIndex += 3;
        }
        // code for checkbox items - disabling for now since this feature is incomplete
//        else if (charRange.length >=3
//                    && [_codeString characterAtIndex:charRange.location]==kMHParserCharCheckboxListItemFirstChar
//                    && [_codeString characterAtIndex:charRange.location+1]==kMHParserCharCheckboxListItemSecondChar
//                    && [_codeString characterAtIndex:charRange.location+2]==kMHParserCharCheckboxListItemThirdChar) {
//            // Numbered list item substitution
//            MHListCommand *listCommand = [MHListCommand listCommandWithType:MHListCommandCheckboxItem];
//            [compiledTextExpression addSubexpression:listCommand];
//            codeColoringBuffer[charRange.location] |= kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringCommandName;
//            codeColoringBuffer[charRange.location+1] |= kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringCommandName;
//            codeColoringBuffer[charRange.location+2] |= kMHParserSyntaxColoringCharacterScanned;
//            minIndex += 3;
//        }
    }
    

    for (index = minIndex; index <= maxIndex; index++) {
                
        // Classify the character so we can decide what to do
        if (index == maxIndex)
            currentCharType = MHParserCharEndOfCode;
        else {
            currentChar = [_codeString characterAtIndex:index];
            
            // Mark the character as scanned:
            codeColoringBuffer[index] |= kMHParserSyntaxColoringCharacterScanned;
            
            // Some substitution rules:
            
            // Substitute en dashes for two hyphens, em dashes for three, unless scanning a command
            if (currentChar == kMHParserCharHyphen && index < maxIndex-1 && currentState != MHParserStateScanningCommand) {
                unichar nextChar = [_codeString characterAtIndex:index+1];
                if (nextChar == kMHParserCharHyphen) {
                    if (index<maxIndex-2 && [_codeString characterAtIndex:index+2]==kMHParserCharHyphen) {
                        // three successive hyphens - skip the next two code characters (marking them as scanned) and substitute an em dash
                        codeColoringBuffer[index+1] |= kMHParserSyntaxColoringCharacterScanned;
                        codeColoringBuffer[index+2] |= kMHParserSyntaxColoringCharacterScanned;
                        index += 2;
                        currentChar = kMHParserCharEmDash;
                    }
                    else {
                        // two successive hyphens - skip the next code character (marking it as scanned) and substitute an en dash
                        codeColoringBuffer[index+1] |= kMHParserSyntaxColoringCharacterScanned;
                        index++;
                        currentChar = kMHParserCharEnDash;
                    }
                }
            }
            else if (currentChar == kMHParserCharASCIIApostrophe && currentState != MHParserStateScanningCommand) {
                // replace an ASCII non-curly apostrophe by a curly apostrophe
                currentChar = kMHParserCharTextApostrophe;
            }
            else if (currentChar == kMHParserCharASCIIAccentGrave && currentState != MHParserStateScanningCommand) {
                // replace an accent grave by an opening single quote
                currentChar = kMHParserCharOpeningSingleQuote;
            }
            else if (currentChar == kMHParserCharASCIIQuote && currentState != MHParserStateScanningCommand) {
                currentChar = (scanningDoubleQuotedBlock ? kMHParserCharRightDoubleQuote : kMHParserCharLeftDoubleQuote);
                scanningDoubleQuotedBlock = !scanningDoubleQuotedBlock;
            }
            else if (currentState != MHParserStateScanningCommand && currentChar == kMHParserCharCommentMarker) {
                // A comment - ignore everything from here to the end of the current line, but mark characters as a comment
                codeColoringBuffer[index] |= kMHParserSyntaxColoringComment;
                index++;
                while (index < maxIndex && [_codeString characterAtIndex:index] != kMHParserCharNewline) {
                    codeColoringBuffer[index] |= kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringComment;
                    index++;
                }
                if (index < maxIndex) {
                    // mark the newline character that terminates the comment field
                    codeColoringBuffer[index] |= kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringComment;
                }
                if (index == maxIndex) {
                    index--;    // This makes sure we enter the loop one last time to process the end of code token
                }
                continue;   // go to the next loop iteration
            }
            
            if (currentChar == kMHParserCharSpace || currentChar == kMHParserCharTab) {
                // tab characters are treated as ordinary spaces
                currentCharType = MHParserCharSpace;
            }
            else if (currentChar == kMHParserCharOpenBlock)
                currentCharType = MHParserCharOpenBlock;
            else if (currentChar == kMHParserCharCloseBlock)
                currentCharType = MHParserCharCloseBlock;
//
// disabling entering subscripts and superscripts using the underscore and caret shorthand notation (that's only available in math mode now)
// In text mode the correct way to enter subscripts and superscripts is now to use the ⌘subscript, ⌘superscript and ⌘subsuperscript commands
//            else if (currentChar == kMHParserCharSubscript)
//                currentCharType = MHParserCharSubscript;
//            else if (currentChar == kMHParserCharSuperscript)
//                currentCharType = MHParserCharSuperscript;
// Note: the code to enable caret and underscore sub/superscripts is still functional below, so by uncommenting the above four lines it will be possible to use this notation again. FIXME: decide whether to keep the code or not, it adds clutter and makes the parser less efficient, so could be better to remove it entirely
            else if (currentChar == kMHParserCharStartCommand)
                currentCharType = MHParserCharStartCommand;
            else if (currentChar == kMHParserCharNewline)
                currentCharType = MHParserCharNewline;
            else if (currentChar == kMHParserCharListDelimiter) {
                currentCharType = MHParserCharListDelimiter;
                currentDelimiterType = MHListDelimiterTypePrimary;
            }
            else if (currentChar == kMHParserCharSecondaryListDelimiter) {
                currentCharType = MHParserCharListDelimiter;
                currentDelimiterType = MHListDelimiterTypeSecondary;
            }
            else if (currentChar == kMHParserMathShiftFirstChar
                     && index < maxIndex-1
                     && [_codeString characterAtIndex:index+1] == kMHParserMathShiftSecondChar) {
                // A math shift pair of characters
                currentCharType = MHParserCharModeSwitch;
                codeColoringBuffer[index] |= kMHParserSyntaxColoringModeSwitch;
                codeColoringBuffer[index+1] |=
                kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringModeSwitch;
                index++;
            }
            else if (currentChar == kMHParserCharAttributesSymbol) {
                if (index < maxIndex-1 && [_codeString characterAtIndex:index+1] == kMHParserCharOpenBlock)
                    currentCharType = MHParserCharAttributes;
                else
                    currentCharType = MHParserCharIgnore;
            }
            else if (currentChar == kMHParserCharAssignment)
                currentCharType = MHParserCharAssignment;
            else if (currentChar == kMHParserCharOpenCodeQuoteBlock) {
                currentCharType = MHParserCharOpenCodeQuoteBlock;
                currentMatchingCloseBracket = kMHParserCharCloseCodeQuoteBlock;
            }
            else if (currentChar == kMHParserCharOpenMathModeCodeQuoteBlock) {
                currentCharType = MHParserCharOpenMathModeCodeQuoteBlock;
                currentMatchingCloseBracket = kMHParserCharCloseMathModeCodeQuoteBlock;
            }
            else if (currentChar == kMHParserCharOpenCodeAnnotationBlock) {
                currentCharType = MHParserCharOpenCodeAnnotationBlock;
                currentMatchingCloseBracket = kMHParserCharCloseCodeAnnotationBlock;
            }
            else
                currentCharType = MHParserCharText;
        }
        
        switch (currentState) {
#pragma mark - MHParserStateScanningWord
            case MHParserStateScanningWord:
                switch (currentCharType) {
                    case MHParserCharSpace: {
                        endOfSemanticUnitIndex = index-1;
                        MHExpression *completedExpression = [MHTextAtom textAtomWithString:currentWord];
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, completedExpression);
                        [currentContainer addSubexpression:completedExpression];
                        currentSpace = [MHWhitespace space];
                        currentState = MHParserStateScanningSpace;
                        beginningOfSemanticUnitIndex = index;
                    }
                        break;
                    case MHParserCharNewline: {
                        endOfSemanticUnitIndex = index-1;
                        MHExpression *completedExpression = [MHTextAtom textAtomWithString:currentWord];
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, completedExpression);
                        [currentContainer addSubexpression:completedExpression];
                        beginningOfSemanticUnitIndex = index;
                        endOfSemanticUnitIndex = index;
                        completedExpression = [MHWhitespace newline];
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, completedExpression);
                        [currentContainer addSubexpression:completedExpression];
                        currentState = MHParserStateGeneric;
                    }
                        break;
                    case MHParserCharText:
                        [currentWord appendFormat:@"%C", currentChar];
                        currentState = MHParserStateScanningWord;
                        break;
                    case MHParserCharOpenBlock: {
                        endOfSemanticUnitIndex = index-1;
                        MHExpression *completedExpression = [MHTextAtom textAtomWithString:currentWord];
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, completedExpression);
                        [currentContainer addSubexpression:completedExpression];
                        MHHorizontalLayoutContainer *newBlock = [MHHorizontalLayoutContainer expression];
//                        [newBlock.attributes setObject:[NSNumber numberWithUnsignedLong:index] forKey:@"codeBeginningIndex"];
                        [currentContainer addSubexpression:newBlock];   // ***need to mark this as a semantic unit eventually***
                        currentContainer = newBlock;
                        currentState = MHParserStateGeneric;
                        codeColoringBuffer[index] |= kMHParserSyntaxColoringBlock;
                    }
                        break;
                    case MHParserCharCloseBlock: {
                        endOfSemanticUnitIndex = index-1;
                        MHExpression *completedExpression = [MHTextAtom textAtomWithString:currentWord];
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, completedExpression);
                        [currentContainer addSubexpression:completedExpression];
                        MHExpression *currentContainerParent = currentContainer.parent;
                        if (currentContainerParent) {
                            MHHorizontalLayoutContainer *justClosedContainer = currentContainer;
                            if ([currentContainerParent isMemberOfClass:[MHPlaceholderCommand class]]) {
                                NSString *commandString = ((MHPlaceholderCommand *)currentContainerParent).name;
                                bool resolved;
                                MHExpression *resolvedCommand =
                                [_packageManager
                                 expressionForCommandString:commandString
                                 commandArgument:justClosedContainer
                                 allowNotebookConfigurationCommands:_notebookConfigurationCommandsEnabled
                                 resolvedSuccessfully:&resolved];
                                
                                if (resolved) {
                                    // Go back and change the syntax coloring info to mark the command as resolved
                                    NSRange commandRange = currentContainerParent.codeRange;
                                    NSUInteger anIndex;
                                    for (anIndex = commandRange.location; anIndex < commandRange.location + commandRange.length; anIndex++) {
                                        codeColoringBuffer[anIndex] &= kMHParserSyntaxColoringForgetClassification;
                                        codeColoringBuffer[anIndex] |= kMHParserSyntaxColoringCommandName;
                                    }
                                    resolvedCommand.codeRange = commandRange;
                                }
                                [resolvedCommand applyCodeRangeLinkbackToCode:_code];
                                
                                MHLayoutType resolvedCommandLayoutPreference = resolvedCommand.layoutPreference;
                                
                                NSArray <MHExpression *> *resolvedCommandAttachments = resolvedCommand.attachedContent;
                                if (resolvedCommandAttachments) {
                                    [attachedContentExpressions addObjectsFromArray:resolvedCommandAttachments];
                                }
                                
                                if (resolvedCommandLayoutPreference == MHLayoutHorizontal) {
                                    currentContainer = (MHHorizontalLayoutContainer *)(currentContainerParent.parent); // FIXME: assuming that it's of kind MHHorizontalLayoutContainer, checked that it doesn't cause problems but it's bad coding practice
                                    [currentContainer replaceExpressionAtIndex:currentContainer.numberOfSubexpressions-1
                                                                withExpression:resolvedCommand];

                                    // If the command is an attributes command, add the attributes dictionary to the container
                                    if ([resolvedCommand isKindOfClass:[MHAttributesCommand class]]) {
                                        currentContainer.attributes = [(MHAttributesCommand *)resolvedCommand attributesDictionary];
                                        
                                        // also reset the code coloring info to an attributes symbol
                                        // FIXME: bad design to do it after already setting it to a command symbol, improve
                                        codeColoringBuffer[currentContainerParent.codeRange.location] &= kMHParserSyntaxColoringForgetClassification;
                                        codeColoringBuffer[currentContainerParent.codeRange.location] |= kMHParserSyntaxColoringAttributesSymbol;
                                    }
                                }
                                else {
                                    currentContainer = (MHHorizontalLayoutContainer *)(currentContainerParent.parent); // FIXME: assuming that it's of kind MHHorizontalLayoutContainer, checked that it doesn't cause problems but it's bad coding practice
                                    
                                    // The resolved command is an expression that wants to be laid out vertically, so remove the placeholder using which it was created from the current container (instead of replacing the placeholder with the resolved command as in the if clause above)
                                    [currentContainer removeExpressionAtIndex:currentContainer.numberOfSubexpressions-1];

                                    // Instead, vertical layout commands are added as attached expressions (this logic may change in the future), unless they have attached expressions themselves, in which case their attached expressions were added above but we will not add the resolved command expression
                                    // FIXME: this works but seems confusing and illogical - improve
                                    // (part of why the current set up uses that logic is that only the MHTextParagraph class implements
                                    // an attachedContent property so I'm using it to package arrays of attached paragraphs.
                                    // It might ultimately be more logical to find a way to store attached content to non-paragraph
                                    // classes such as MHExpression or MHHorizontalLayoutContainer etc. But I'll leave that for the
                                    // future once I have a better understanding of what attached content can be used for.
                                    if (!resolvedCommandAttachments) {
                                        [attachedContentExpressions addObject:resolvedCommand];
                                    }
                                }
                            }
                            else if ([currentContainerParent isKindOfClass:[MHScriptedExpression class]]) {
                                currentContainer = (MHHorizontalLayoutContainer *)(currentContainerParent.parent); // FIXME: assuming that it's of kind MHHorizontalLayoutContainer, checked that it doesn't cause problems but it's bad coding practice
                            }
                            else {
                                currentContainer = (MHHorizontalLayoutContainer *)currentContainerParent; // FIXME: assuming that it's of kind MHHorizontalLayoutContainer, checked that it doesn't cause problems but it's bad coding practice
                            }
                        }
                        else {
//                            codeColoringBuffer[index] |= kMHParserSyntaxColoringBlock;
                            codeColoringBuffer[index] = 0;  // pretend we never scanned this character - it belongs to whoever sent the code to this parser
                            index--;
                            goto main_loop_exit;  // closing the outermost block - exit the main for(...) loop
                        }
                        currentState = MHParserStateGeneric;
                        codeColoringBuffer[index] |= kMHParserSyntaxColoringBlock;
                    }
                        break;
                    case MHParserCharSubscript: {
                        endOfSemanticUnitIndex = index-1;
                        MHTextAtom *textAtom = [MHTextAtom textAtomWithString:currentWord];
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, textAtom);
                        MHScriptedExpression *scriptedExpression = [MHScriptedExpression
                                                                    scriptedExpressionWithBody:textAtom
                                                                    subscript:[MHHorizontalLayoutContainer expression]
                                                                    superscript:[MHHorizontalLayoutContainer expression]];
                        [currentContainer addSubexpression:scriptedExpression]; // ***need to mark this as a semantic unit eventually***
                        currentContainer = (MHHorizontalLayoutContainer *)(scriptedExpression.subscript);
                        currentState = MHParserStateScanningQuickExpression;
                    }
                        break;
                    case MHParserCharSuperscript: {
                        endOfSemanticUnitIndex = index-1;
                        MHTextAtom *textAtom = [MHTextAtom textAtomWithString:currentWord];
                        MHScriptedExpression *scriptedExpression = [MHScriptedExpression
                                                                    scriptedExpressionWithBody:textAtom
                                                                    subscript:[MHHorizontalLayoutContainer expression]
                                                                    superscript:[MHHorizontalLayoutContainer expression]];
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, textAtom);
                        [currentContainer addSubexpression:scriptedExpression]; // ***need to mark this as a semantic unit eventually***
                        currentContainer = (MHHorizontalLayoutContainer *)(scriptedExpression.superscript);
                        currentState = MHParserStateScanningQuickExpression;
                    }
                        break;
                    case MHParserCharStartCommand:
                    case MHParserCharAttributes: {
                        endOfSemanticUnitIndex = index-1;
                        MHExpression *completedExpression = [MHTextAtom textAtomWithString:currentWord];
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, completedExpression);
                        [currentContainer addSubexpression:completedExpression];
                        currentCommand = [NSMutableString stringWithCapacity:0];
                        
                        // If the character is an attributes symbol, treat it like we're starting a commmand and append the attributes character to the name
                        // FIXME: this way of implementing the attributes feature is not very good design as it mixes it with another language feature in a way that's difficult to understand - improve
                        if (currentCharType == MHParserCharAttributes)
                            [currentCommand appendString:kMHParserCharAttributesString];
                        
                        currentState = MHParserStateScanningCommand;
                        codeColoringBuffer[index] |= kMHParserSyntaxColoringUnresolvedCommandName;
                        beginningOfSemanticUnitIndex = index;
                    }
                        break;
                    case MHParserCharListDelimiter: {
                        endOfSemanticUnitIndex = index-1;
                        MHExpression *completedExpression = [MHTextAtom textAtomWithString:currentWord];
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, completedExpression);
                        [currentContainer addSubexpression:completedExpression];
                        [currentContainer addListDelimiterWithType:currentDelimiterType]; // ***need to mark this as a semantic unit eventually***
                        currentState = MHParserStateGeneric;
                        codeColoringBuffer[index] |= kMHParserSyntaxColoringListDelimiter;
                    }
                        break;
                    case MHParserCharAssignment: {
                        endOfSemanticUnitIndex = index-1;
                        MHExpression *completedExpression = [MHTextAtom textAtomWithString:currentWord];
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, completedExpression);
                        [currentContainer addSubexpression:completedExpression];
                        MHExpression *assignmentExpression = [MHTextAtom textAtomWithString:kMHParserCharAssignmentString];
                        [currentContainer addSubexpression:assignmentExpression]; // ***need to mark this as a semantic unit eventually***
                        currentState = MHParserStateGeneric;
                        codeColoringBuffer[index] |= kMHParserSyntaxColoringAssignment;
                    }
                        break;
                    case MHParserCharEndOfCode: {
                        endOfSemanticUnitIndex = index-1;
                        MHExpression *completedExpression = [MHTextAtom textAtomWithString:currentWord];
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, completedExpression);
                        [currentContainer addSubexpression:completedExpression];
                    }
                        break;
                    case MHParserCharModeSwitch: {
                        endOfSemanticUnitIndex = index-1;
                        MHExpression *completedExpression = [MHTextAtom textAtomWithString:currentWord];
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, completedExpression);
                        [currentContainer addSubexpression:completedExpression];
                        if (index < maxIndex-1 && [_codeString characterAtIndex:index+1] == kMHParserCharOpenBlock) {
                            NSRange mathScannedRange;
                            codeColoringBuffer[index+1] |= kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringBlock;
                            MHExpression *mathExpression = [self parseMathModeCodeInRange:NSMakeRange(index+2, maxIndex - index - 2)
                                                                     actuallyScannedRange:&mathScannedRange
                                                                            rootContainer:nil];
                            [currentContainer addSubexpression:mathExpression]; // ***need to mark this as a semantic unit eventually***

                            index = mathScannedRange.location + mathScannedRange.length + 1;

                            // upon exiting the math parser, usually there will be a block close character. If so, mark it appropriately and skip to the next
                            if (index < maxIndex) {
                                unichar mathModeExitChar = [_codeString characterAtIndex:index];
                                if (mathModeExitChar == kMHParserCharCloseBlock) {
                                    codeColoringBuffer[index] |= kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringBlock;
                                }
                            }
                        }
                        else {
                            // If the math shift control string is not followed by an open block character, we ignore it, and mark the two characters as not scanned as a subtle cue to the user
                            codeColoringBuffer[index] &=
                            kMHParserSyntaxColoringBitMask - kMHParserSyntaxColoringCharacterScanned;
                            codeColoringBuffer[index-1] &=
                            kMHParserSyntaxColoringBitMask - kMHParserSyntaxColoringCharacterScanned;
                        }
                        currentState = MHParserStateGeneric;
                    }
                        break;
                    case MHParserCharOpenCodeQuoteBlock:
                    case MHParserCharOpenMathModeCodeQuoteBlock:
                    case MHParserCharOpenCodeAnnotationBlock: {
                        // A block of quoted code or a code annotation (what we call a "special block")
                        endOfSemanticUnitIndex = index-1;
                        MHExpression *completedExpression = [MHTextAtom textAtomWithString:currentWord];
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, completedExpression);
                        [currentContainer addSubexpression:completedExpression];
                        completedExpression = nil;
                        beginningOfSemanticUnitIndex = index;
                        
                        // Identify the range of the special code block
                        
                        // We will search for a string with the close code quote (either normal or math mode) character
                        NSString *specialCodeBlockString = [NSString stringWithFormat:@"%C", currentMatchingCloseBracket];

                        NSRange specialCodeBlockRange = [_codeString rangeOfString:specialCodeBlockString
                                                                           options:NSLiteralSearch
                                                                             range:NSMakeRange(index+1, maxIndex-index-1)];

                        // The special code block is everything between where we are now and this marker, or to the end of the allowed range if the marker is not found
                        bool closeMarkerFound = specialCodeBlockRange.location != NSNotFound;
                        NSRange rangeOfSpecialCodeBlock = NSMakeRange(index+1,
                                                                      (closeMarkerFound ? specialCodeBlockRange.location-index-1 : maxIndex-index-1));
                        
                        bool specialCodeBlockIsParagraphBlock = (rangeOfSpecialCodeBlock.length >= 3)
                                                && ([_codeString characterAtIndex:rangeOfSpecialCodeBlock.location]==kMHParserCharCodeQuoteParagraphPrefix);
                        NSRange reducedRangeOfSpecialCodeBlock = (specialCodeBlockIsParagraphBlock
                                                                  ? NSMakeRange(rangeOfSpecialCodeBlock.location+1, rangeOfSpecialCodeBlock.length-1) : rangeOfSpecialCodeBlock);
                        
                        NSString *specialCodeString = [_codeString substringWithRange:reducedRangeOfSpecialCodeBlock];
                        
                        endOfSemanticUnitIndex = rangeOfSpecialCodeBlock.location + rangeOfSpecialCodeBlock.length + (closeMarkerFound ? 0 : -1);
                        
                        if (rangeOfSpecialCodeBlock.length != 0 && currentCharType != MHParserCharOpenCodeAnnotationBlock) {
                            if (specialCodeBlockIsParagraphBlock) {
                                completedExpression = [MHQuotedCodeParagraph quotedCodeParagraphWithCodeString:specialCodeString
                                                                                                      inTextMode:(currentCharType == MHParserCharOpenCodeQuoteBlock)];
                                [attachedContentExpressions addObject:completedExpression];
                            }
                            else {
                                completedExpression = [MHQuotedCodeExpression quotedCodeExpressionWithCodeString:specialCodeString
                                                                                                      inTextMode:(currentCharType == MHParserCharOpenCodeQuoteBlock)];
                                [currentContainer addSubexpression:completedExpression];
                            }
                        }
                        
                        char syntaxColoringCode = (currentCharType == MHParserCharOpenCodeAnnotationBlock ?
                                                   kMHParserSyntaxColoringCodeAnnotationBlock : kMHParserSyntaxColoringQuotedCodeBlock);
                                                   
                        codeColoringBuffer[index] |= syntaxColoringCode;
                        for (NSUInteger j = rangeOfSpecialCodeBlock.location; j < rangeOfSpecialCodeBlock.location+rangeOfSpecialCodeBlock.length; j++) {
                            codeColoringBuffer[j] |= kMHParserSyntaxColoringCharacterScanned | syntaxColoringCode;
                        }
                        if (closeMarkerFound) {
                            codeColoringBuffer[specialCodeBlockRange.location] |= kMHParserSyntaxColoringCharacterScanned | syntaxColoringCode;
                        }
                        if (completedExpression) {
                            MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, completedExpression);
                        }
                        index += rangeOfSpecialCodeBlock.length+1;
                        currentState = MHParserStateGeneric;
                        break;
                    }
                    default:
                        codeColoringBuffer[index] &= kMHParserSyntaxColoringNotScanned;  // forget the color code classification and that the character was scanned
                        break;
                }
                break;
#pragma mark - MHParserStateScanningCommand
            case MHParserStateScanningCommand:
                if (currentChar == kMHParserCharQuickCloseCommand) {
                    endOfSemanticUnitIndex = index;
                    bool resolved;
                    MHExpression *command =
                    [_packageManager expressionForCommandString:currentCommand
                                                commandArgument:nil
                             allowNotebookConfigurationCommands:_notebookConfigurationCommandsEnabled
                                           resolvedSuccessfully:&resolved];
                    if (resolved) {
                        // Go back and change the syntax coloring info to mark the command as unresolved
                        NSUInteger anIndex;
                        for (anIndex = index - currentCommand.length - 1; anIndex < index; anIndex++) {
                            codeColoringBuffer[anIndex] &= kMHParserSyntaxColoringForgetClassification;
                            codeColoringBuffer[anIndex] |= kMHParserSyntaxColoringCommandName;
                        }
                    }
                    
                    MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, command);
                    
                    MHLayoutType commandLayoutPreference = command.layoutPreference;
                    NSArray <MHExpression *> *commandAttachments = command.attachedContent;
                    if (commandAttachments) {
                        [attachedContentExpressions addObjectsFromArray:commandAttachments];
                    }
                    
                    if (commandLayoutPreference == MHLayoutHorizontal) {
                        [currentContainer addSubexpression:command];
                    }
                    else {  // vertical layout - add as attached content unless the command has its own attached content in which case that content is added to the global attached content and the command itself is discarded
                        if (!commandAttachments) {
                            [attachedContentExpressions addObject:command];
                        }
                    }
                    
                    currentState = MHParserStateGeneric;
                    codeColoringBuffer[index] |= kMHParserSyntaxColoringBlock;
                }
                else switch (currentCharType) {
//                    case MHParserCharSpace:
//                        break;
//                    case MHParserCharNewline:
//                        break;
//                    case MHParserCharText:
//                        break;
                    case MHParserCharOpenBlock: {
                        codeColoringBuffer[index] |= kMHParserSyntaxColoringBlock;
                        MHHorizontalLayoutContainer *newBlock = [MHHorizontalLayoutContainer expression];
                        MHPlaceholderCommand *command = [MHPlaceholderCommand commandNamed:currentCommand withParameters:nil argument:newBlock];
                        command.codeRange = NSMakeRange(beginningOfSemanticUnitIndex, index-beginningOfSemanticUnitIndex);    // mark the code range for later use in the MHParserMarkSemanticUnit macro and for syntax coloring
                        [currentContainer addSubexpression:command]; // FIXME: need to mark this as a semantic unit
                        currentContainer = newBlock;
                        currentState = MHParserStateGeneric;
                    }
                        break;
//                    case MHParserCharCloseBlock:
//                        break;
//                    case MHParserCharSubscript:
//                        break;
//                    case MHParserCharSuperscript:
//                        break;
//                    case MHParserCharStartCommand:
//                        break;
//                    case MHParserCharModeSwitch:
//                        break;
                    case MHParserCharEndOfCode:
                        // reached end of code - no character to add to the command name
                        break;
                    default:
                        [currentCommand appendFormat:@"%C", currentChar];
                        codeColoringBuffer[index] |= kMHParserSyntaxColoringUnresolvedCommandName;
                        break;
                }
                break;
#pragma mark - MHParserStateScanningSpace
            case MHParserStateScanningSpace:
                switch (currentCharType) {
                    case MHParserCharSpace:
                        [currentSpace makeLarger];
                        break;
                    case MHParserCharNewline: {
                        endOfSemanticUnitIndex = index - 1;
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, currentSpace);
                        [currentContainer addSubexpression:currentSpace];
                        beginningOfSemanticUnitIndex = index;
                        endOfSemanticUnitIndex = index;
                        MHExpression *newline = [MHWhitespace newline];
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, newline);
                        [currentContainer addSubexpression:newline];
                        currentState = MHParserStateGeneric;
                    }
                        break;
                    case MHParserCharText:
                        endOfSemanticUnitIndex = index - 1;
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, currentSpace);
                        [currentContainer addSubexpression:currentSpace];
                        currentWord = [NSMutableString stringWithCapacity:0];
                        [currentWord appendFormat:@"%C", currentChar];
                        currentState = MHParserStateScanningWord;
                        beginningOfSemanticUnitIndex = index;
                        break;
                    case MHParserCharOpenBlock: {
                        endOfSemanticUnitIndex = index - 1;
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, currentSpace);
                        [currentContainer addSubexpression:currentSpace];
                        MHHorizontalLayoutContainer *newBlock = [MHHorizontalLayoutContainer expression];
                        [currentContainer addSubexpression:newBlock]; // ***need to mark this as a semantic unit eventually***
                        currentContainer = newBlock;
                        currentState = MHParserStateGeneric;
                        codeColoringBuffer[index] |= kMHParserSyntaxColoringBlock;
                    }
                        break;
                    case MHParserCharCloseBlock: {
                        endOfSemanticUnitIndex = index - 1;
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, currentSpace);
                        [currentContainer addSubexpression:currentSpace];
                        MHExpression *currentContainerParent = currentContainer.parent;
                        if (currentContainerParent) {
                            MHHorizontalLayoutContainer *justClosedContainer = currentContainer;
//                            currentContainer = currentContainerParent;
                            if ([currentContainerParent isMemberOfClass:[MHPlaceholderCommand class]]) {
                                NSString *commandString = ((MHPlaceholderCommand *)currentContainerParent).name;
                                bool resolved;
                                MHExpression *resolvedCommand =
                                [_packageManager expressionForCommandString:commandString
                                                            commandArgument:justClosedContainer
                                         allowNotebookConfigurationCommands:_notebookConfigurationCommandsEnabled
                                                       resolvedSuccessfully:&resolved];
                                if (resolved) {
                                    // Go back and change the syntax coloring info to mark the command as resolved
                                    NSRange commandRange = currentContainerParent.codeRange;
                                    NSUInteger anIndex;
                                    for (anIndex = commandRange.location; anIndex < commandRange.location + commandRange.length; anIndex++) {
                                        codeColoringBuffer[anIndex] &= kMHParserSyntaxColoringForgetClassification;
                                        codeColoringBuffer[anIndex] |= kMHParserSyntaxColoringCommandName;
                                    }
                                    resolvedCommand.codeRange = commandRange;
                                }
                                [resolvedCommand applyCodeRangeLinkbackToCode:_code];

//                                currentContainer = (MHHorizontalLayoutContainer *)(currentContainerParent.parent); // FIXME: assuming that it's of kind MHHorizontalLayoutContainer, checked that it doesn't cause problems but it's bad coding practice
//                                [currentContainer replaceExpressionAtIndex:currentContainer.numberOfSubexpressions-1
//                                                            withExpression:resolvedCommand];
                                                                
                                MHLayoutType resolvedCommandLayoutPreference = resolvedCommand.layoutPreference;
                                
                                NSArray <MHExpression *> *resolvedCommandAttachments = resolvedCommand.attachedContent;
                                if (resolvedCommandAttachments) {
                                    [attachedContentExpressions addObjectsFromArray:resolvedCommandAttachments];
                                }
                                
                                if (resolvedCommandLayoutPreference == MHLayoutHorizontal) {
                                    currentContainer = (MHHorizontalLayoutContainer *)(currentContainerParent.parent); // FIXME: assuming that it's of kind MHHorizontalLayoutContainer, checked that it doesn't cause problems but it's bad coding practice
                                    [currentContainer replaceExpressionAtIndex:currentContainer.numberOfSubexpressions-1
                                                                withExpression:resolvedCommand];

                                    // If the command is an attributes command, add the attributes dictionary to the container
                                    if ([resolvedCommand isKindOfClass:[MHAttributesCommand class]]) {
                                        currentContainer.attributes = [(MHAttributesCommand *)resolvedCommand attributesDictionary];
                                        
                                        // also reset the code coloring info to an attributes symbol
                                        // FIXME: bad design to do it after already setting it to a command symbol, improve
                                        codeColoringBuffer[currentContainerParent.codeRange.location] &= kMHParserSyntaxColoringForgetClassification;
                                        codeColoringBuffer[currentContainerParent.codeRange.location] |= kMHParserSyntaxColoringAttributesSymbol;
                                    }
                                }
                                else {
                                    currentContainer = (MHHorizontalLayoutContainer *)(currentContainerParent.parent); // FIXME: assuming that it's of kind MHHorizontalLayoutContainer, checked that it doesn't cause problems but it's bad coding practice
                                    
                                    // The resolved command is an expression that wants to be laid out vertically, so remove the placeholder using which it was created from the current container (instead of replacing the placeholder with the resolved command as in the if clause above)
                                    [currentContainer removeExpressionAtIndex:currentContainer.numberOfSubexpressions-1];

                                    // Instead, vertical layout commands are added as attached expressions (this logic may change in the future), unless they have attached expressions themselves, in which case their attached expressions were added above but we will not add the resolved command expression
                                    // FIXME: this works but seems confusing and illogical - improve
                                    // (part of why the current set up uses that logic is that only the MHTextParagraph class implements
                                    // an attachedContent property so I'm using it to package arrays of attached paragraphs.
                                    // It might ultimately be more logical to find a way to store attached content to non-paragraph
                                    // classes such as MHExpression or MHHorizontalLayoutContainer etc. But I'll leave that for the
                                    // future once I have a better understanding of what attached content can be used for.
                                    if (!resolvedCommandAttachments) {
                                        [attachedContentExpressions addObject:resolvedCommand];
                                    }
                                }
                            }
                            else if ([currentContainerParent isKindOfClass:[MHScriptedExpression class]]) {
                                currentContainer = (MHHorizontalLayoutContainer *)(currentContainerParent.parent); // FIXME: assuming that it's of kind MHHorizontalLayoutContainer, checked that it doesn't cause problems but it's bad coding practice
                            }
                            else {
                                currentContainer = (MHHorizontalLayoutContainer *)currentContainerParent; // FIXME: assuming that it's of kind MHHorizontalLayoutContainer, checked that it doesn't cause problems but it's bad coding practice
                            }
                        }
                        else {
//                            codeColoringBuffer[index] |= kMHParserSyntaxColoringBlock;
                            codeColoringBuffer[index] = 0;  // pretend we never scanned this character - it belongs to whoever sent the code to this parser
                            index--;
                            goto main_loop_exit;  // closing the outermost block - exit the main for(...) loop
                        }
                        currentState = MHParserStateGeneric;
                        codeColoringBuffer[index] |= kMHParserSyntaxColoringBlock;
                    }
                        break;
                    case MHParserCharSubscript: {
                        endOfSemanticUnitIndex = index - 1;
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, currentSpace);
                        [currentContainer addSubexpression:currentSpace];
                        MHHorizontalLayoutContainer *subscript = [MHHorizontalLayoutContainer expression];
                        MHScriptedExpression *scriptedExpression = [MHScriptedExpression
                                                                    scriptedExpressionWithBody:[MHExpression expression]
                                                                    subscript:subscript
                                                                    superscript:[MHHorizontalLayoutContainer expression]];
                        [currentContainer addSubexpression:scriptedExpression]; // ***need to mark this as a semantic unit eventually***
                        currentContainer = (MHHorizontalLayoutContainer *)subscript;
                        currentState = MHParserStateScanningQuickExpression;
                    }
                        break;
                    case MHParserCharSuperscript: {
                        endOfSemanticUnitIndex = index - 1;
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, currentSpace);
                        [currentContainer addSubexpression:currentSpace];
                        MHHorizontalLayoutContainer *superscript = [MHHorizontalLayoutContainer expression];
                        MHScriptedExpression *scriptedExpression = [MHScriptedExpression
                                                                    scriptedExpressionWithBody:[MHExpression expression]
                                                                    subscript:[MHHorizontalLayoutContainer expression]
                                                                    superscript:superscript];
                        [currentContainer addSubexpression:scriptedExpression]; // ***need to mark this as a semantic unit eventually***
                        currentContainer = (MHHorizontalLayoutContainer *)superscript;
                        currentState = MHParserStateScanningQuickExpression;
                    }
                        break;
                    case MHParserCharStartCommand:
                    case MHParserCharAttributes:
                        endOfSemanticUnitIndex = index - 1;
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, currentSpace);
                        [currentContainer addSubexpression:currentSpace];
                        currentCommand = [NSMutableString stringWithCapacity:0];
                        
                        // If the character is an attributes symbol, treat it like we're starting a commmand and append the attributes character to the name
                        // FIXME: this way of implementing the attributes feature is not very good design as it mixes it with another language feature in a way that's difficult to understand - improve
                        if (currentCharType == MHParserCharAttributes)
                            [currentCommand appendString:kMHParserCharAttributesString];
                        
                        currentState = MHParserStateScanningCommand;
                        codeColoringBuffer[index] |= kMHParserSyntaxColoringUnresolvedCommandName;
                        beginningOfSemanticUnitIndex = index;
                        break;
                    case MHParserCharListDelimiter:
                        endOfSemanticUnitIndex = index - 1;
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, currentSpace);
                        [currentContainer addSubexpression:currentSpace];
                        [currentContainer addListDelimiterWithType:currentDelimiterType]; // ***need to mark this as a semantic unit eventually***
                        currentState = MHParserStateGeneric;
                        codeColoringBuffer[index] |= kMHParserSyntaxColoringListDelimiter;
                        break;
                    case MHParserCharAssignment: {
                        endOfSemanticUnitIndex = index - 1;
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, currentSpace);
                        [currentContainer addSubexpression:currentSpace];
                        MHExpression *assignmentExpression = [MHTextAtom textAtomWithString:kMHParserCharAssignmentString];
                        [currentContainer addSubexpression:assignmentExpression]; // ***need to mark this as a semantic unit eventually***
                        currentState = MHParserStateGeneric;
                        codeColoringBuffer[index] |= kMHParserSyntaxColoringAssignment;
                    }
                        break;
                    case MHParserCharEndOfCode:
                        endOfSemanticUnitIndex = index - 1;
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, currentSpace);
                        [currentContainer addSubexpression:currentSpace];
                        break;
                    case MHParserCharModeSwitch:
                        endOfSemanticUnitIndex = index - 1;
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, currentSpace);
                        [currentContainer addSubexpression:currentSpace];
                        if (index < maxIndex-1 && [_codeString characterAtIndex:index+1] == kMHParserCharOpenBlock) {
                            NSRange mathScannedRange;
                            codeColoringBuffer[index+1] |= kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringBlock;
                            MHExpression *mathExpression = [self parseMathModeCodeInRange:NSMakeRange(index+2, maxIndex - index - 2)
                                                                     actuallyScannedRange:&mathScannedRange
                                                                            rootContainer:nil];
                            [currentContainer addSubexpression:mathExpression]; // ***need to mark this as a semantic unit eventually***

                            index = mathScannedRange.location + mathScannedRange.length + 1;

                            // upon exiting the math parser, usually there will be a block close character. If so, mark it appropriately and skip to the next
                            if (index < maxIndex) {
                                unichar mathModeExitChar = [_codeString characterAtIndex:index];
                                if (mathModeExitChar == kMHParserCharCloseBlock) {
                                    codeColoringBuffer[index] |= kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringBlock;
                                }
                            }
                        }
                        else {
                            // If the math shift control string is not followed by an open block character, we ignore it, and mark the two characters as not scanned as a subtle cue to the user
                            
                            codeColoringBuffer[index] &=
                            kMHParserSyntaxColoringBitMask - kMHParserSyntaxColoringCharacterScanned;
                            codeColoringBuffer[index-1] &=
                            kMHParserSyntaxColoringBitMask - kMHParserSyntaxColoringCharacterScanned;
                        }
                        currentState = MHParserStateGeneric;
                        break;
                    case MHParserCharOpenCodeQuoteBlock:
                    case MHParserCharOpenMathModeCodeQuoteBlock:
                    case MHParserCharOpenCodeAnnotationBlock: {
                        // A block of quoted code or a code annotation (what we call a "special block")
                        endOfSemanticUnitIndex = index - 1;
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, currentSpace);
                        [currentContainer addSubexpression:currentSpace];
                        beginningOfSemanticUnitIndex = index;
                        
                        // Identify the range of the special code block
                        
                        // We will search for a string with the close code quote (either normal or math mode) character
                        NSString *closeSpecialCodeBlockString = [NSString stringWithFormat:@"%C", currentMatchingCloseBracket];

                        NSRange closeSpecialCodeBlockRange = [_codeString rangeOfString:closeSpecialCodeBlockString
                                                                                options:NSLiteralSearch
                                                                                  range:NSMakeRange(index+1, maxIndex-index-1)];
                        
                        // The special code block is everything between where we are now and this marker, or to the end of the allowed range if the marker is not found
                        bool closeMarkerFound = closeSpecialCodeBlockRange.location != NSNotFound;
                        NSRange rangeOfSpecialCodeBlock = NSMakeRange(index+1,
                                                                      (closeMarkerFound ? closeSpecialCodeBlockRange.location-index-1 : maxIndex-index-1));
                        
                        bool specialCodeBlockIsParagraphBlock = (rangeOfSpecialCodeBlock.length >= 3)
                                                && ([_codeString characterAtIndex:rangeOfSpecialCodeBlock.location]==kMHParserCharCodeQuoteParagraphPrefix);
                        NSRange reducedRangeOfSpecialCodeBlock = (specialCodeBlockIsParagraphBlock
                                                                  ? NSMakeRange(rangeOfSpecialCodeBlock.location+1, rangeOfSpecialCodeBlock.length-1) : rangeOfSpecialCodeBlock);

                        NSString *specialCodeString = [_codeString substringWithRange:reducedRangeOfSpecialCodeBlock];
                        
                        endOfSemanticUnitIndex = rangeOfSpecialCodeBlock.location + rangeOfSpecialCodeBlock.length + (closeMarkerFound ? 0 : -1);

                        MHExpression *completedExpression = nil;
                        
                        if (rangeOfSpecialCodeBlock.length != 0 && currentCharType != MHParserCharOpenCodeAnnotationBlock) {
                            if (specialCodeBlockIsParagraphBlock) {
                                completedExpression = [MHQuotedCodeParagraph quotedCodeParagraphWithCodeString:specialCodeString
                                                                                                      inTextMode:(currentCharType == MHParserCharOpenCodeQuoteBlock)];
                                [attachedContentExpressions addObject:completedExpression];
                            }
                            else {
                                completedExpression = [MHQuotedCodeExpression quotedCodeExpressionWithCodeString:specialCodeString
                                                                                                      inTextMode:(currentCharType == MHParserCharOpenCodeQuoteBlock)];
                                [currentContainer addSubexpression:completedExpression];
                            }
                        }
                        
                        char syntaxColoringCode = (currentCharType == MHParserCharOpenCodeAnnotationBlock ?
                                                   kMHParserSyntaxColoringCodeAnnotationBlock : kMHParserSyntaxColoringQuotedCodeBlock);
                        
                        codeColoringBuffer[index] |= syntaxColoringCode;
                        for (NSUInteger j = rangeOfSpecialCodeBlock.location; j < rangeOfSpecialCodeBlock.location+rangeOfSpecialCodeBlock.length; j++) {
                            codeColoringBuffer[j] |= kMHParserSyntaxColoringCharacterScanned | syntaxColoringCode;
                        }
                        if (closeMarkerFound) {
                            codeColoringBuffer[closeSpecialCodeBlockRange.location] |= kMHParserSyntaxColoringCharacterScanned | syntaxColoringCode;
                        }
                        if (completedExpression) {
                            MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, completedExpression);
                        }
                        index += rangeOfSpecialCodeBlock.length+1;
                        currentState = MHParserStateGeneric;
                        break;
                    }
                    default:
                        codeColoringBuffer[index] &= kMHParserSyntaxColoringNotScanned;  // forget the color code classification and that the character was scanned
                        break;
                }
                break;
#pragma mark - MHParserStateScanningQuickExpression
            case MHParserStateScanningQuickExpression:
                if (currentCharType == MHParserCharOpenBlock || currentCharType == MHParserCharEndOfCode) {
                    currentState = MHParserStateGeneric;
                    if (currentCharType == MHParserCharOpenBlock)
                        codeColoringBuffer[index] |= kMHParserSyntaxColoringBlock;
                }
                else {
                    MHTextAtom *textAtom = [MHTextAtom textAtomWithString:[NSString stringWithFormat:@"%C",currentChar]];
                    MHExpression *currentContainerParent = currentContainer.parent;
                    if ([currentContainerParent isKindOfClass:[MHScriptedExpression class]]) {
                        MHScriptedExpression *scriptedExp = ((MHScriptedExpression *)currentContainerParent);
                        bool isSubscript = [currentContainer isEqualTo:scriptedExp.subscript];
                        beginningOfSemanticUnitIndex = index;
                        endOfSemanticUnitIndex = index;
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, textAtom);
                        if (isSubscript) {
                            scriptedExp.subscript = textAtom;
                        }
                        else {
                            scriptedExp.superscript = textAtom;
                        }
                        currentContainer = (MHHorizontalLayoutContainer *)(scriptedExp.parent); // FIXME: assuming that it's of kind MHHorizontalLayoutContainer, checked that it doesn't cause problems but it's bad coding practice
                    }
                    else
                        NSLog(@"error: expecting currentNode parent to be a MHScriptedExpression");
                    currentState = MHParserStateGeneric;
                }
                break;
#pragma mark - MHParserStateGeneric
            case MHParserStateGeneric:
                switch (currentCharType) {
                    case MHParserCharSpace:
                        currentSpace = [MHWhitespace space];
                        currentState = MHParserStateScanningSpace;
                        beginningOfSemanticUnitIndex = index;
                        break;
                    case MHParserCharNewline: {
                        beginningOfSemanticUnitIndex = index;
                        endOfSemanticUnitIndex = index;
                        MHExpression *newline = [MHWhitespace newline];
                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, newline);
                        [currentContainer addSubexpression:newline];
                        currentState = MHParserStateGeneric;
                    }
                        break;
                    case MHParserCharText:
                        currentWord = [NSMutableString stringWithCapacity:0];
                        [currentWord appendFormat:@"%C", currentChar];
                        currentState = MHParserStateScanningWord;
                        beginningOfSemanticUnitIndex = index;
                        break;
                    case MHParserCharOpenBlock: {
                        MHHorizontalLayoutContainer *newBlock = [MHHorizontalLayoutContainer expression];
                        [currentContainer addSubexpression:newBlock]; // ***need to mark this as a semantic unit eventually***
                        currentContainer = newBlock;
                        currentState = MHParserStateGeneric;
                        codeColoringBuffer[index] |= kMHParserSyntaxColoringBlock;
                    }
                        break;
                    case MHParserCharCloseBlock: {
                        MHExpression *currentContainerParent = currentContainer.parent;
                        if (currentContainerParent) {
                            MHHorizontalLayoutContainer *justClosedContainer = currentContainer;
                            if ([currentContainerParent isMemberOfClass:[MHPlaceholderCommand class]]) {
                                NSString *commandString = ((MHPlaceholderCommand *)currentContainerParent).name;
                                bool resolved;
                                MHExpression *resolvedCommand =
                                [_packageManager expressionForCommandString:commandString
                                                            commandArgument:justClosedContainer
                                         allowNotebookConfigurationCommands:_notebookConfigurationCommandsEnabled
                                                       resolvedSuccessfully:&resolved];
                                if (resolved) {
                                    // Go back and change the syntax coloring info to mark the command as resolved
                                    NSRange commandRange = currentContainerParent.codeRange;
                                    NSUInteger anIndex;
                                    for (anIndex = commandRange.location; anIndex < commandRange.location + commandRange.length; anIndex++) {
                                        codeColoringBuffer[anIndex] &= kMHParserSyntaxColoringForgetClassification;
                                        codeColoringBuffer[anIndex] |= kMHParserSyntaxColoringCommandName;
                                    }
                                    resolvedCommand.codeRange = commandRange;
                                }
                                [resolvedCommand applyCodeRangeLinkbackToCode:_code];

//                                currentContainer = (MHHorizontalLayoutContainer *)(currentContainerParent.parent); // FIXME: assuming that it's of kind MHHorizontalLayoutContainer, checked that it doesn't cause problems but it's bad coding practice
//                                [currentContainer replaceExpressionAtIndex:currentContainer.numberOfSubexpressions-1
//                                                            withExpression:resolvedCommand];
                                                                
                                MHLayoutType resolvedCommandLayoutPreference = resolvedCommand.layoutPreference;
                                
                                NSArray <MHExpression *> *resolvedCommandAttachments = resolvedCommand.attachedContent;
                                if (resolvedCommandAttachments) {
                                    [attachedContentExpressions addObjectsFromArray:resolvedCommandAttachments];
                                }
                                
                                if (resolvedCommandLayoutPreference == MHLayoutHorizontal) {
                                    currentContainer = (MHHorizontalLayoutContainer *)(currentContainerParent.parent); // FIXME: assuming that it's of kind MHHorizontalLayoutContainer, checked that it doesn't cause problems but it's bad coding practice
                                    [currentContainer replaceExpressionAtIndex:currentContainer.numberOfSubexpressions-1
                                                                withExpression:resolvedCommand];

                                    // If the command is an attributes command, add the attributes dictionary to the container
                                    if ([resolvedCommand isKindOfClass:[MHAttributesCommand class]]) {
                                        currentContainer.attributes = [(MHAttributesCommand *)resolvedCommand attributesDictionary];
                                        
                                        // also reset the code coloring info to an attributes symbol
                                        // FIXME: bad design to do it after already setting it to a command symbol, improve
                                        codeColoringBuffer[currentContainerParent.codeRange.location] &= kMHParserSyntaxColoringForgetClassification;
                                        codeColoringBuffer[currentContainerParent.codeRange.location] |= kMHParserSyntaxColoringAttributesSymbol;
                                    }
                                }
                                else {
                                    currentContainer = (MHHorizontalLayoutContainer *)(currentContainerParent.parent); // FIXME: assuming that it's of kind MHHorizontalLayoutContainer, checked that it doesn't cause problems but it's bad coding practice
                                    
                                    // The resolved command is an expression that wants to be laid out vertically, so remove the placeholder using which it was created from the current container (instead of replacing the placeholder with the resolved command as in the if clause above)
                                    [currentContainer removeExpressionAtIndex:currentContainer.numberOfSubexpressions-1];

                                    // Instead, vertical layout commands are added as attached expressions (this logic may change in the future), unless they have attached expressions themselves, in which case their attached expressions were added above but we will not add the resolved command expression
                                    // FIXME: this works but seems confusing and illogical - improve
                                    // (part of why the current set up uses that logic is that only the MHTextParagraph class implements
                                    // an attachedContent property so I'm using it to package arrays of attached paragraphs.
                                    // It might ultimately be more logical to find a way to store attached content to non-paragraph
                                    // classes such as MHExpression or MHHorizontalLayoutContainer etc. But I'll leave that for the
                                    // future once I have a better understanding of what attached content can be used for.
                                    if (!resolvedCommandAttachments) {
                                        [attachedContentExpressions addObject:resolvedCommand];
                                    }
                                }
                            }
                            else
                                if ([currentContainerParent isKindOfClass:[MHScriptedExpression class]]) {
                                currentContainer = (MHHorizontalLayoutContainer *)(currentContainerParent.parent); // FIXME: assuming that it's of kind MHHorizontalLayoutContainer, checked that it doesn't cause problems but it's bad coding practice
                            }
                            else {
                                currentContainer = (MHHorizontalLayoutContainer *)currentContainerParent; // FIXME: assuming that it's of kind MHHorizontalLayoutContainer, checked that it doesn't cause problems but it's bad coding practice
                            }
                        }
                        else {
//                            codeColoringBuffer[index] |= kMHParserSyntaxColoringBlock;
                            codeColoringBuffer[index] = 0;  // pretend we never scanned this character - it belongs to whoever sent the code to this parser
                            index--;
                            goto main_loop_exit;  // closing the outermost block - exit the main for(...) loop
                        }
                        currentState = MHParserStateGeneric;
                        codeColoringBuffer[index] |= kMHParserSyntaxColoringBlock;
                    }
                        break;
                    case MHParserCharSubscript: {
                        // Check if the last expression added was already scripted
                        MHExpression *lastExpressionAdded = nil;
                        if (currentContainer.numberOfSubexpressions > 0)
                            lastExpressionAdded = [currentContainer lastExpression];
                        if (lastExpressionAdded && [lastExpressionAdded isKindOfClass:[MHScriptedExpression class]]) {
                            MHHorizontalLayoutContainer *subscript = [MHHorizontalLayoutContainer expression];
                            ((MHScriptedExpression *)lastExpressionAdded).subscript = subscript;
                            currentContainer = subscript;
                            currentState = MHParserStateScanningQuickExpression;
                        }
                        else {
                            MHHorizontalLayoutContainer *subscript = [MHHorizontalLayoutContainer expression];
                            MHScriptedExpression *scriptedExpression = [MHScriptedExpression
                                                                        scriptedExpressionWithBody:
                                                                        (lastExpressionAdded ? lastExpressionAdded : [MHExpression expression])
                                                                        subscript:subscript
                                                                        superscript:[MHHorizontalLayoutContainer expression]];
                            if (lastExpressionAdded)
                                [currentContainer replaceExpressionAtIndex:currentContainer.numberOfSubexpressions-1
                                                            withExpression:scriptedExpression];
                            else
                                [currentContainer addSubexpression:scriptedExpression]; // ***need to mark this as a semantic unit eventually***
                            currentContainer = subscript;
                            currentState = MHParserStateScanningQuickExpression;
                        }
                    }
                        break;
                    case MHParserCharSuperscript: {
                        // Check if the last expression added was already scripted
                        MHExpression *lastExpressionAdded = nil;
                        if (currentContainer.numberOfSubexpressions > 0)
                            lastExpressionAdded = [currentContainer lastExpression];
                        if (lastExpressionAdded && [lastExpressionAdded isKindOfClass:[MHScriptedExpression class]]) {
                            MHHorizontalLayoutContainer *superscript = [MHHorizontalLayoutContainer expression];
                            ((MHScriptedExpression *)lastExpressionAdded).superscript = superscript;
                            currentContainer = superscript;
                            currentState = MHParserStateScanningQuickExpression;
                        }
                        else {
                            MHHorizontalLayoutContainer *superscript = [MHHorizontalLayoutContainer expression];
                            MHScriptedExpression *scriptedExpression = [MHScriptedExpression
                                                                        scriptedExpressionWithBody:
                                                                        (lastExpressionAdded ? lastExpressionAdded : [MHExpression expression])
                                                                        subscript:[MHHorizontalLayoutContainer expression]
                                                                        superscript:superscript];
                            if (lastExpressionAdded)
                                [currentContainer replaceExpressionAtIndex:currentContainer.numberOfSubexpressions-1
                                                            withExpression:scriptedExpression];
                            else
                                [currentContainer addSubexpression:scriptedExpression]; // ***need to mark this as a semantic unit eventually***
                            currentContainer = superscript;
                            currentState = MHParserStateScanningQuickExpression;
                        }
                    }
                        break;
                    case MHParserCharStartCommand:
                    case MHParserCharAttributes:
                        currentCommand = [NSMutableString stringWithCapacity:0];
                        
                        // If the character is an attributes symbol, treat it like we're starting a commmand and append the attributes character to the name
                        // FIXME: this way of implementing the attributes feature is not very good design as it mixes it with another language feature in a way that's difficult to understand - improve
                        if (currentCharType == MHParserCharAttributes)
                            [currentCommand appendString:kMHParserCharAttributesString];
                        
                        currentState = MHParserStateScanningCommand;
                        codeColoringBuffer[index] |= kMHParserSyntaxColoringUnresolvedCommandName;
                        beginningOfSemanticUnitIndex = index;
                        break;
                    case MHParserCharListDelimiter:
                        [currentContainer addListDelimiterWithType:currentDelimiterType];
                        currentState = MHParserStateGeneric;
                        codeColoringBuffer[index] |= kMHParserSyntaxColoringListDelimiter;
                        break;
                    case MHParserCharAssignment: {
                        MHExpression *assignmentExpression = [MHTextAtom textAtomWithString:kMHParserCharAssignmentString];
                        [currentContainer addSubexpression:assignmentExpression]; // ***need to mark this as a semantic unit eventually***
                        currentState = MHParserStateGeneric;
                        codeColoringBuffer[index] |= kMHParserSyntaxColoringAssignment;
                    }
                        break;
                    case MHParserCharEndOfCode:
                        break;
                    case MHParserCharModeSwitch:
                        if (index < maxIndex-1 && [_codeString characterAtIndex:index+1] == kMHParserCharOpenBlock) {
                            NSRange mathScannedRange;
                            codeColoringBuffer[index+1] |= kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringBlock;
                            MHExpression *mathExpression = [self parseMathModeCodeInRange:NSMakeRange(index+2, maxIndex - index - 2)
                                                                     actuallyScannedRange:&mathScannedRange
                                                                            rootContainer:nil];
                            [currentContainer addSubexpression:mathExpression]; // ***need to mark this as a semantic unit eventually***

                            index = mathScannedRange.location + mathScannedRange.length + 1;

                            // upon exiting the math parser, usually there will be a block close character. If so, mark it appropriately and skip to the next
                            if (index < maxIndex) {
                                unichar mathModeExitChar = [_codeString characterAtIndex:index];
                                if (mathModeExitChar == kMHParserCharCloseBlock) {
                                    codeColoringBuffer[index] |= kMHParserSyntaxColoringCharacterScanned | kMHParserSyntaxColoringBlock;
                                }
                            }
                        }
                        else {
                            // If the math shift control string is not followed by an open block character, we ignore it, and mark the two characters as not scanned as a subtle cue to the user
                            codeColoringBuffer[index] &=
                            kMHParserSyntaxColoringBitMask - kMHParserSyntaxColoringCharacterScanned;
                            codeColoringBuffer[index-1] &=
                            kMHParserSyntaxColoringBitMask - kMHParserSyntaxColoringCharacterScanned;
                        }
                        currentState = MHParserStateGeneric;
                        break;
                    case MHParserCharOpenCodeQuoteBlock:
                    case MHParserCharOpenMathModeCodeQuoteBlock:
                    case MHParserCharOpenCodeAnnotationBlock: {
                        // A block of quoted code or a code annotation (what we call a "special block")
                        beginningOfSemanticUnitIndex = index;
                        
                        // Identify the range of the special code block
                        
                        // We will search for a string with the close code quote (either normal or math mode) character
                        NSString *closeSpecialCodeBlockString = [NSString stringWithFormat:@"%C", currentMatchingCloseBracket];

                        NSRange closeSpecialCodeBlockRange = [_codeString rangeOfString:closeSpecialCodeBlockString
                                                                                options:NSLiteralSearch
                                                                                  range:NSMakeRange(index+1, maxIndex-index-1)];

                        // The special code block is everything between where we are now and this marker, or to the end of the allowed range if the marker is not found
                        bool closeMarkerFound = closeSpecialCodeBlockRange.location != NSNotFound;
                        NSRange rangeOfSpecialCodeBlock = NSMakeRange(index+1,
                                                                      (closeMarkerFound ? closeSpecialCodeBlockRange.location-index-1 : maxIndex-index-1));
                        
                        bool specialCodeBlockIsParagraphBlock = (rangeOfSpecialCodeBlock.length >= 3)
                                    && ([_codeString characterAtIndex:rangeOfSpecialCodeBlock.location]==kMHParserCharCodeQuoteParagraphPrefix);
                        NSRange reducedRangeOfSpecialCodeBlock = (specialCodeBlockIsParagraphBlock
                                                                  ? NSMakeRange(rangeOfSpecialCodeBlock.location+1, rangeOfSpecialCodeBlock.length-1) : rangeOfSpecialCodeBlock);
                        
                        NSString *specialCodeString = [_codeString substringWithRange:reducedRangeOfSpecialCodeBlock];
                        
                        endOfSemanticUnitIndex = rangeOfSpecialCodeBlock.location + rangeOfSpecialCodeBlock.length + (closeMarkerFound ? 0 : -1);

                        MHExpression *completedExpression = nil;
                        if (rangeOfSpecialCodeBlock.length != 0 && currentCharType != MHParserCharOpenCodeAnnotationBlock) {
                            if (specialCodeBlockIsParagraphBlock) {
                                completedExpression = [MHQuotedCodeParagraph quotedCodeParagraphWithCodeString:specialCodeString
                                                                                                      inTextMode:(currentCharType == MHParserCharOpenCodeQuoteBlock)];
                                [attachedContentExpressions addObject:completedExpression];
                            }
                            else {
                                completedExpression = [MHQuotedCodeExpression quotedCodeExpressionWithCodeString:specialCodeString
                                                                                                      inTextMode:(currentCharType == MHParserCharOpenCodeQuoteBlock)];
                                [currentContainer addSubexpression:completedExpression];
                            }
                        }

                        char syntaxColoringCode = (currentCharType == MHParserCharOpenCodeAnnotationBlock ?
                                                   kMHParserSyntaxColoringCodeAnnotationBlock : kMHParserSyntaxColoringQuotedCodeBlock);
                        
                        codeColoringBuffer[index] |= syntaxColoringCode;
                        for (NSUInteger j = rangeOfSpecialCodeBlock.location; j < rangeOfSpecialCodeBlock.location+rangeOfSpecialCodeBlock.length; j++) {
                            codeColoringBuffer[j] |= kMHParserSyntaxColoringCharacterScanned | syntaxColoringCode;
                        }
                        if (closeMarkerFound) {
                            codeColoringBuffer[closeSpecialCodeBlockRange.location] |= kMHParserSyntaxColoringCharacterScanned | syntaxColoringCode;
                        }
                        if (completedExpression) {
                            MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, completedExpression);
                        }
                        index += rangeOfSpecialCodeBlock.length+1;
                        currentState = MHParserStateGeneric;
                        break;
                    }
                    default:
                        codeColoringBuffer[index] &= kMHParserSyntaxColoringNotScanned;  // forget the color code classification and that the character was scanned
                        break;
                }
                break;
            default:
                NSLog(@"this code should never run");
                break;
        }
    }
    
main_loop_exit:
    *scannedRangePointer = NSMakeRange(charRange.location, index - charRange.location);
    
    // Logic for handling attached content expressions that were added during parsing: currently they are added as attached content to
    // the compiledTextExpression variable. At the moment only MHParagraph expressions implement an attachedContent property
    // so I'm adding a check if compiledTextExpression is of that class. If it's a different class the attached content
    // will be discarded
    // FIXME: improve this logic
    if (attachedContentExpressions.count > 0 &&  [compiledTextExpression isKindOfClass:[MHParagraph class]]) {
        ((MHParagraph *)compiledTextExpression).attachedContent = attachedContentExpressions;
        
//        for (MHExpression *attachedExpression in attachedContentExpressions) {
//            attachedExpression.parent = compiledTextExpression;
//        }
    }
    
    return compiledTextExpression;
}


@end










// lines 234-322
//case MHParserCharCloseBlock: {
//                        endOfSemanticUnitIndex = index-1;
//                        MHExpression *completedExpression = [MHTextAtom textAtomWithString:currentWord];
//                        MHParserMarkSemanticUnit(beginningOfSemanticUnitIndex, endOfSemanticUnitIndex, completedExpression);
//                        [currentContainer addSubexpression:completedExpression];
//                        MHExpression *currentContainerParent = currentContainer.parent;
//                        if (currentContainerParent) {
//                            MHHorizontalLayoutContainer *justClosedContainer = currentContainer;
//                            if ([currentContainerParent isMemberOfClass:[MHPlaceholderCommand class]]) {
//
//                                MHExpression *resolvedCommand;
//                                bool resolved;
//                                bool isAttributesPlaceholder = ((MHPlaceholderCommand *)currentContainerParent).isAttributesPlaceholder;
//                                if (isAttributesPlaceholder) {
//                                    resolved = true;
//                                    resolvedCommand = currentContainerParent;
//                                }
//                                else {
//                                    NSString *commandString = ((MHPlaceholderCommand *)currentContainerParent).name;
//                                    resolvedCommand = [_packageManager expressionForCommandString:commandString
//                                                                                  commandArgument:justClosedContainer
//                                                                             resolvedSuccessfully:&resolved];
//                                }
//
//                                if (resolved) {
//                                    // Go back and change the syntax coloring info to mark the command as resolved
//                                    NSRange commandRange = currentContainerParent.codeRange;
//                                    NSUInteger anIndex;
//                                    for (anIndex = commandRange.location; anIndex < commandRange.location + commandRange.length; anIndex++) {
//                                        codeColoringBuffer[anIndex] &= kMHParserSyntaxColoringForgetClassification;
//                                        codeColoringBuffer[anIndex] |= kMHParserSyntaxColoringCommandName;
//                                    }
//                                }
//                                [resolvedCommand applyCodeRangeLinkbackToCode:_code];
//
////                                currentContainer = (MHHorizontalLayoutContainer *)(currentContainerParent.parent); // FIXME: assuming that it's of kind MHHorizontalLayoutContainer, checked that it doesn't cause problems but it's bad coding practice
////                                [currentContainer replaceExpressionAtIndex:currentContainer.numberOfSubexpressions-1
////                                                            withExpression:resolvedCommand];
//
//                                MHLayoutType resolvedCommandLayoutPreference = resolvedCommand.layoutPreference;
//
//                                NSArray <MHExpression *> *resolvedCommandAttachments = resolvedCommand.attachedContent;
//                                if (resolvedCommandAttachments) {
//                                    [attachedContentExpressions addObjectsFromArray:resolvedCommandAttachments];
//                                }
//
//                                if (resolvedCommandLayoutPreference == MHLayoutHorizontal && !isAttributesPlaceholder) {
//                                    currentContainer = (MHHorizontalLayoutContainer *)(currentContainerParent.parent); // FIXME: assuming that it's of kind MHHorizontalLayoutContainer, checked that it doesn't cause problems but it's bad coding practice
//                                    [currentContainer replaceExpressionAtIndex:currentContainer.numberOfSubexpressions-1
//                                                                withExpression:resolvedCommand];
//                                }
//                                else {
//                                    currentContainer = (MHHorizontalLayoutContainer *)(currentContainerParent.parent); // FIXME: assuming that it's of kind MHHorizontalLayoutContainer, checked that it doesn't cause problems but it's bad coding practice
//
//                                    // The resolved command is an expression that wants to be laid out vertically, so remove the placeholder using which it was created from the current container (instead of replacing the placeholder with the resolved command as in the if clause above)
//                                    [currentContainer removeExpressionAtIndex:currentContainer.numberOfSubexpressions-1];
//
//                                    // Instead, vertical layout commands are added as attached expressions (this logic may change in the future), unless they have attached expressions themselves, in which case their attached expressions were added above but we will not add the resolved command expression
//                                    // FIXME: this works but seems confusing and illogical - improve
//                                    // (part of why the current set up uses that logic is that only the MHTextParagraph class implements
//                                    // an attachedContent property so I'm using it to package arrays of attached paragraphs.
//                                    // It might ultimately be more logical to find a way to store attached content to non-paragraph
//                                    // classes such as MHExpression or MHHorizontalLayoutContainer etc. But I'll leave that for the
//                                    // future once I have a better understanding of what attached content can be used for.
//                                    if (isAttributesPlaceholder) {
//                                        currentContainer.attributes = [(MHPlaceholderCommand *)resolvedCommand attributesDictionary];
//                                    }
//                                    else if (!resolvedCommandAttachments) {
//                                        [attachedContentExpressions addObject:resolvedCommand];
//                                    }
//                                }
//                            }
//                            else if ([currentContainerParent isKindOfClass:[MHScriptedExpression class]]) {
//                                currentContainer = (MHHorizontalLayoutContainer *)(currentContainerParent.parent); // FIXME: assuming that it's of kind MHHorizontalLayoutContainer, checked that it doesn't cause problems but it's bad coding practice
//                            }
//                            else {
//                                currentContainer = (MHHorizontalLayoutContainer *)currentContainerParent; // FIXME: assuming that it's of kind MHHorizontalLayoutContainer, checked that it doesn't cause problems but it's bad coding practice
//                            }
//                        }
//                        else {
////                            codeColoringBuffer[index] |= kMHParserSyntaxColoringBlock;
//                            codeColoringBuffer[index] = 0;  // pretend we never scanned this character - it belongs to whoever sent the code to this parser
//                            index--;
//                            goto main_loop_exit;  // closing the outermost block - exit the main for(...) loop
//                        }
//                        currentState = MHParserStateGeneric;
//                        codeColoringBuffer[index] |= kMHParserSyntaxColoringBlock;
//                    }
//                        break;
