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


#import "ORKInstructionStepView.h"

#import "ORKStepHeaderView_Internal.h"
#import "ORKTintedImageView.h"
#import "ORKVerticalContainerView_Internal.h"

#import "ORKNavigationContainerView_Internal.h"

#import "ORKInstructionStep.h"
#import "ORKCompletionStep.h"
#import "ORKStep_Private.h"

#import "ORKHelpers_Internal.h"
#import "ORKSkin.h"


@implementation ORKInstructionStepView {
    ORKTintedImageView *_auxiliaryInstructionImageView;
    ORKTintedImageView *_instructionImageView;
    UIView *_imageContainerView;
    BOOL _isCompletionStep;
    NSLayoutConstraint *_imageContainerHeightConstraint;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _instructionImageView = [ORKTintedImageView new];
        _instructionImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _instructionImageView.contentMode = UIViewContentModeScaleAspectFit;
        
        _auxiliaryInstructionImageView = [ORKTintedImageView new];
        _auxiliaryInstructionImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _auxiliaryInstructionImageView.contentMode = UIViewContentModeScaleAspectFit;
        _auxiliaryInstructionImageView.tintColor = ORKColor(ORKAuxiliaryImageTintColorKey);
        
        _imageContainerView = [[UIView alloc] initWithFrame:frame];
        _imageContainerView.translatesAutoresizingMaskIntoConstraints = NO;
        [_imageContainerView addSubview:_auxiliaryInstructionImageView];
        [_imageContainerView addSubview:_instructionImageView];
        
        self.stepView = _imageContainerView;
    }
    return self;
}

- (void)setInstructionStep:(ORKInstructionStep *)instructionStep {
    _instructionStep = instructionStep;
    UIImage *image = _instructionStep.image;
    UIImage *auxiliaryImage = _instructionStep.auxiliaryImage;
    BOOL hasImage = (image != nil);
    BOOL hasFootnote = _instructionStep.footnote.length > 0;
    
    _isCompletionStep = [_instructionStep isKindOfClass:[ORKCompletionStep class]];
    
    self.verticalCenteringEnabled = !hasImage;
    self.continueHugsContent = !hasImage && !hasFootnote;
    self.stepViewFillsAvailableSpace = ((hasImage || hasFootnote) && !_isCompletionStep);
    
    _instructionImageView.image = image;
    _instructionImageView.shouldApplyTint = instructionStep.shouldTintImages;
    _auxiliaryInstructionImageView.image = auxiliaryImage;
    _auxiliaryInstructionImageView.shouldApplyTint = instructionStep.shouldTintImages;
    
    CGSize imageSize = image.size;
    if (imageSize.width > 0 && imageSize.height > 0) {
        [NSLayoutConstraint deactivateConstraints:[_imageContainerView constraints]];
        NSMutableArray *constraints = [NSMutableArray new];
        [constraints addObject:[NSLayoutConstraint constraintWithItem:_imageContainerView
                                                            attribute:NSLayoutAttributeHeight
                                                            relatedBy:NSLayoutRelationLessThanOrEqual
                                                               toItem:_imageContainerView
                                                            attribute:NSLayoutAttributeWidth
                                                           multiplier:imageSize.height / imageSize.width
                                                             constant:0.0]];
        
        _imageContainerHeightConstraint = [NSLayoutConstraint constraintWithItem:_imageContainerView
                                                                       attribute:NSLayoutAttributeHeight
                                                                       relatedBy:NSLayoutRelationLessThanOrEqual
                                                                          toItem:nil
                                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                                      multiplier:1.0
                                                                        constant:300.0];
        
        [constraints addObject:_imageContainerHeightConstraint];
        
        NSDictionary *views = NSDictionaryOfVariableBindings(_instructionImageView, _auxiliaryInstructionImageView);
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_instructionImageView]|"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:views]];
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_instructionImageView]|"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:views]];
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_auxiliaryInstructionImageView]|"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:views]];
        [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_auxiliaryInstructionImageView]|"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:views]];
        
        [NSLayoutConstraint activateConstraints:constraints];
        
        _instructionImageView.isAccessibilityElement = YES;
        _instructionImageView.accessibilityLabel = [NSString stringWithFormat:ORKLocalizedString(@"AX_IMAGE_ILLUSTRATION", nil), _instructionStep.title];
    } else {
        _instructionImageView.isAccessibilityElement = NO;
    }
    
    self.headerView.iconImageView.image = _instructionStep.iconImage;
    self.headerView.captionLabel.text = _instructionStep.title;
    
    NSAttributedString *attributedText = _instructionStep.attributedText;
    if (!attributedText) {
        NSString *text = _instructionStep.text;
        if (text.length) {
            attributedText = [[NSAttributedString alloc] initWithString:text attributes:nil];
        }
    }
    
    NSAttributedString *attributedDetail = _instructionStep.attributedDetailText;
    if (!attributedDetail) {
        NSString *detail = _instructionStep.detailText;
        if (detail.length) {
            attributedDetail = [[NSAttributedString alloc] initWithString:detail attributes:nil];
        }
    }

    NSAttributedString *attributedInstruction = nil;
    if (attributedText && attributedDetail) {
        NSMutableAttributedString *a = [[NSMutableAttributedString alloc] init];
        a = [[NSMutableAttributedString alloc] init];
        [a appendAttributedString:attributedText];
        [a appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:nil]];
        [a appendAttributedString:attributedDetail];

        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        [style setParagraphSpacingBefore:self.headerView.instructionLabel.font.lineHeight * 0.5];
        [style setAlignment:NSTextAlignmentCenter];

        [a addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(0, a.length)];
        attributedInstruction = a;
        
    } else if (attributedText || attributedDetail) {
        attributedInstruction = (attributedText ?: attributedDetail);
    }

    self.headerView.instructionLabel.attributedText = attributedInstruction;
    
    self.continueSkipContainer.footnoteLabel.text = _instructionStep.footnote;
    [self.continueSkipContainer updateContinueAndSkipEnabled];
    
    [self tintColorDidChange];
    
    [self setNeedsUpdateConstraints];
}

- (void)updateConstraintConstantsForWindow:(UIWindow *)window {
    [super updateConstraintConstantsForWindow:window];
    
    const CGFloat IllustrationHeight = ORKGetMetricForWindow(ORKScreenMetricInstructionImageHeight, window);
    _imageContainerHeightConstraint.constant = (_instructionImageView.image ? IllustrationHeight : 0);
}

@end
