/*
 Copyright (c) 2015, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "ORKLabel.h"

#import "ORKHelpers_Internal.h"


@implementation ORKLabel

- (instancetype)init {
    self = [super init];
    if (self) {
        [self init_ORKLabel];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self init_ORKLabel];
    }
    return self;
}

- (void)init_ORKLabel {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateAppearance)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];
    [self updateAppearance];
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    [self updateAppearance];
}

- (void)updateAppearance {
    if (self.attributedText == nil)
        self.font = [[self class] defaultFont];

    [self invalidateIntrinsicContentSize];
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    NSMutableAttributedString *reformattedText = [attributedText mutableCopy];
    
    // Set text alignment to our label's alignment
    NSTextAlignment textAlignment = self.textAlignment;
    [reformattedText enumerateAttribute:NSParagraphStyleAttributeName inRange:NSMakeRange(0, reformattedText.length) options:0 usingBlock:^(NSParagraphStyle *style, NSRange range, BOOL * _Nonnull stop) {
        if (!style) style = [NSParagraphStyle defaultParagraphStyle];
        if (style.alignment != textAlignment) {
            NSMutableParagraphStyle *newStyle = [style mutableCopy];
            newStyle.alignment = textAlignment;
            [reformattedText addAttribute:NSParagraphStyleAttributeName value:newStyle range:range];
        }
    }];
    
    // Set the font and font size to our label's font & font size
    UIFontDescriptor *baseDescriptor = [[self class] defaultFont].fontDescriptor;
    [reformattedText enumerateAttribute:NSFontAttributeName inRange:NSMakeRange(0, reformattedText.length) options:0 usingBlock:^(UIFont *font, NSRange range, BOOL * _Nonnull stop) {
        // Instantiate a font with our base font's family, but with the current range's traits
        UIFontDescriptorSymbolicTraits traits = font.fontDescriptor.symbolicTraits;
        UIFontDescriptor *descriptor = [baseDescriptor fontDescriptorWithSymbolicTraits:traits];
        // Maintaining same size as the defaultFont
        UIFont *newFont = [UIFont fontWithDescriptor:descriptor size:baseDescriptor.pointSize];
        [reformattedText removeAttribute:NSFontAttributeName range:range];
        [reformattedText addAttribute:NSFontAttributeName value:newFont range:range];
    }];

    [super setAttributedText:reformattedText];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (UIFont *)defaultFont {
    UIFontDescriptor *descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleSubheadline];
    return ORKMediumFontWithSize(((NSNumber *)[descriptor objectForKey: UIFontDescriptorSizeAttribute]).doubleValue + 3.0);
}

@end
