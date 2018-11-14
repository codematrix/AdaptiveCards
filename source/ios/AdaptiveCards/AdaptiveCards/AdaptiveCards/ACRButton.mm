//
//  ACRButton
//  ACRButton.mm
//
//  Copyright © 2017 Microsoft. All rights reserved.
//

#import "ACOBaseActionElementPrivate.h"
#import "ACRButton.h"
#import "ACRViewPrivate.h"
#import "ACRUIImageView.h"
#import "SharedAdaptiveCard.h"
#import "ACOHostConfigPrivate.h"
#import <objc/runtime.h>

@implementation UIButton(ACRButton)

@dynamic positiveUseDefault, positiveForegroundColor, positiveBackgroundColor;
@dynamic destructiveUseDefault, destructiveForegroundColor, destructiveBackgroundColor;

+ (void)setImageView:(UIImage*)image inButton:(UIButton*)button withConfig:(ACOHostConfig *)config contentSize:(CGSize)contentSize inconPlacement:(ACRIconPlacement)iconPlacement
{
    float imageHeight = 0.0f;

    // apply explicit image size when the below condition is met
    if(iconPlacement == ACRAboveTitle && config.allActionsHaveIcons) {
        imageHeight = [config getHostConfig]->GetActions().iconSize;
    } else { // format the image so it fits in the button
        imageHeight = contentSize.height;
    }

    CGFloat widthToHeightRatio = 0.0f;
    if(image && image.size.height > 0) {
        widthToHeightRatio = image.size.width / image.size.height;
    }

    CGSize imageSize = CGSizeMake(imageHeight * widthToHeightRatio, imageHeight);

    ACRUIImageView *imageView = [[ACRUIImageView alloc] initWithFrame:CGRectMake(0, 0, imageSize.width, imageSize.height)];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.image = image;
    [button addSubview:imageView];
    // scale the image using UIImageView
    [NSLayoutConstraint constraintWithItem:imageView
                                 attribute:NSLayoutAttributeWidth
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:nil
                                 attribute:NSLayoutAttributeNotAnAttribute
                                multiplier:1.0
                                  constant:imageSize.width].active = YES;

    [NSLayoutConstraint constraintWithItem:imageView
                                 attribute:NSLayoutAttributeHeight
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:nil
                                 attribute:NSLayoutAttributeNotAnAttribute
                                multiplier:1.0
                                  constant:imageSize.height].active = YES;

    if(iconPlacement == ACRAboveTitle && config.allActionsHaveIcons) {
        // fix image view to top and center x of the button
        [NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:button
            attribute:NSLayoutAttributeTop multiplier:1.0 constant:config.buttonPadding].active = YES;
        [NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:button
            attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0].active = YES;
        // image can't be postion at the top of the title, so adjust title inset edges
        [button setTitleEdgeInsets:UIEdgeInsetsMake(imageHeight, 0, -imageHeight, 0)];
        // readjust content edge, so intrinsic content size can be accurately determined by system library, and give enough room for title and image icon
        [button setContentEdgeInsets:UIEdgeInsetsMake(config.buttonPadding, config.buttonPadding + button.layer.cornerRadius, config.buttonPadding + imageHeight, config.buttonPadding + button.layer.cornerRadius)];
        // configure button frame to correct size; in case translatesAutoresizingMaskIntoConstraints is used
        button.frame = CGRectMake(0, 0, MAX(imageSize.width, contentSize.width), imageSize.height + config.buttonPadding);
    } else {
        int iconPadding = [config getHostConfig]->GetSpacing().defaultSpacing;
        [button setTitleEdgeInsets:UIEdgeInsetsMake(config.buttonPadding, (imageSize.width) + iconPadding, config.buttonPadding, -(iconPadding + imageSize.width))];
        [button setContentEdgeInsets:UIEdgeInsetsMake(config.buttonPadding, config.buttonPadding, config.buttonPadding, imageSize.width + iconPadding + button.layer.cornerRadius)];
        [NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:button attribute:NSLayoutAttributeLeft multiplier:1.0 constant:config.buttonPadding].active = YES;
        [NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:button attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0].active = YES;
        button.frame = CGRectMake(0, 0, imageSize.width + config.buttonPadding + contentSize.width, MAX(imageSize.height, contentSize.height));
    }
}

+ (UIButton* )rootView:(ACRView *)rootView
     baseActionElement:(ACOBaseActionElement *)acoAction
                 title:(NSString *)title
         andHostConfig:(ACOHostConfig *)config;
{
    NSBundle* bundle = [NSBundle bundleWithIdentifier:@"MSFT.AdaptiveCards"];
    UIButton *button = [bundle loadNibNamed:@"ACRButton" owner:rootView options:nil][0];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    
    std::shared_ptr<AdaptiveCards::BaseActionElement> action = [acoAction element];
    std::shared_ptr<AdaptiveCards::HostConfig> hostConfig = [config getHostConfig];
    
    switch (action->GetSentiment()) {
        case AdaptiveCards::Sentiment::Positive: {
            NSNumber *obj = button.positiveUseDefault;
            BOOL usePositiveDefault = [obj boolValue];
            
            // By default, positive sentiment must have background accentColor and white text/foreground color
            if(usePositiveDefault) {
                ContainerStylesDefinition containerStyles = hostConfig->GetContainerStyles();
                ColorsConfig cc = containerStyles.defaultPalette.foregroundColors;
                
                UIColor *color = [ACOHostConfig getTextBlockColor:ForegroundColor::Accent colorsConfig:cc subtleOption:false];
                [button setBackgroundColor:color];
                [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
            } else {
                UIColor *foregroundColor = button.positiveForegroundColor;
                UIColor *backgroundColor = button.positiveBackgroundColor;
                
                [button setBackgroundColor:backgroundColor];
                [button setTitleColor:foregroundColor forState:UIControlStateNormal];
            }
            break;
        }
        
        case AdaptiveCards::Sentiment::Destructive: {
            NSNumber *obj = button.destructiveUseDefault;
            BOOL useDestructiveDefault = [obj boolValue];
        
            if(useDestructiveDefault) {
                
                ContainerStylesDefinition containerStyles = hostConfig->GetContainerStyles();
                ColorsConfig cc = containerStyles.defaultPalette.foregroundColors;
                
                UIColor *color = [ACOHostConfig getTextBlockColor:ForegroundColor::Attention colorsConfig:cc subtleOption:false];
                [button setTitleColor:color forState:UIControlStateNormal];
                
            } else {
                UIColor *foregroundColor = button.destructiveForegroundColor;
                UIColor *backgroundColor = button.destructiveBackgroundColor;
                
                [button setBackgroundColor:backgroundColor];
                [button setTitleColor:foregroundColor forState:UIControlStateNormal];
            }
            break;
        }
        
        case AdaptiveCards::Sentiment::Default:
        default:
        break;
    }
    
    NSDictionary *imageViewMap = [rootView getImageMap];
    NSString *key = [NSString stringWithCString:action->GetIconUrl().c_str() encoding:[NSString defaultCStringEncoding]];
    UIImage *img = imageViewMap[key];

    if(img){
        CGSize contentSize = [button.titleLabel intrinsicContentSize];
        [UIButton setImageView:img inButton:button withConfig:config contentSize:contentSize
                inconPlacement:[config getIconPlacement]];
    } else {
        // button's intrinsic content size is determined by title size and content edge
        // add corner radius to content size by adding it to content edge inset
        [button setContentEdgeInsets:UIEdgeInsetsMake(config.buttonPadding, config.buttonPadding + button.layer.cornerRadius, config.buttonPadding, config.buttonPadding + button.layer.cornerRadius)];
    }

    return button;
}

-(void)setPositiveUseDefault:(NSNumber *)_positiveUseDefault {
    objc_setAssociatedObject(self, @selector(positiveUseDefault), _positiveUseDefault, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSNumber *)positiveUseDefault {
    return objc_getAssociatedObject(self, @selector(positiveUseDefault));
}

-(void)setPositiveForegroundColor:(UIColor *)_positiveForegroundColor {
    objc_setAssociatedObject(self, @selector(positiveForegroundColor), _positiveForegroundColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSNumber *)positiveForegroundColor {
    return objc_getAssociatedObject(self, @selector(positiveForegroundColor));
}

-(void)setPositiveBackgroundColor:(UIColor *)_positiveBackgroundColor {
    objc_setAssociatedObject(self, @selector(positiveBackgroundColor), _positiveBackgroundColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(UIColor *)positiveBackgroundColor {
    return objc_getAssociatedObject(self, @selector(positiveBackgroundColor));
}

-(void)setDestructiveUseDefault:(NSNumber *)_destructiveUseDefault {
    objc_setAssociatedObject(self, @selector(destructiveUseDefault), _destructiveUseDefault, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSNumber *)destructiveUseDefault {
    return objc_getAssociatedObject(self, @selector(destructiveUseDefault));
}

-(void)setDestructiveForegroundColor:(UIColor *)_destructiveForegroundColor {
    objc_setAssociatedObject(self, @selector(destructiveForegroundColor), _destructiveForegroundColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSNumber *)destructiveForegroundColor {
    return objc_getAssociatedObject(self, @selector(destructiveForegroundColor));
}

-(void)setDestructiveBackgroundColor:(UIColor *)_destructiveBackgroundColor {
    objc_setAssociatedObject(self, @selector(destructiveBackgroundColor), _destructiveBackgroundColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(UIColor *)destructiveBackgroundColor {
    return objc_getAssociatedObject(self, @selector(destructiveBackgroundColor));
}

@end
