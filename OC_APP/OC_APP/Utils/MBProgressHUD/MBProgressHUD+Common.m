//
//  MBProgressHUD+Common.m
//  OC_APP
//
//  Created by xingl on 2017/7/7.
//  Copyright © 2017年 兴林. All rights reserved.
//

#import "MBProgressHUD+Common.h"

@implementation MBProgressHUD (Common)

#pragma mark 显示错误信息
+ (void)showError:(NSString *)error ToView:(UIView *)view{
    [self showCustomIcon:@"error.png" Title:error ToView:view];
}

+ (void)showSuccess:(NSString *)success ToView:(UIView *)view
{
    [self showCustomIcon:@"success.png" Title:success ToView:view];
}



#pragma mark 显示一些信息
+ (MBProgressHUD *)showMessage:(NSString *)message ToView:(UIView *)view {
    
    
    if (view == nil) view = (UIView*)[UIApplication sharedApplication].delegate.window;
    // 快速显示一个提示信息
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.label.text = message;
    // 隐藏时候从父控件中移除
    hud.removeFromSuperViewOnHide = YES;
    // YES代表需要蒙版效果
    hud.backgroundView.style = MBProgressHUDBackgroundStyleSolidColor;
    hud.backgroundView.color = [UIColor colorWithWhite:0.f alpha:.3f];
    return hud;
}

//加载视图
+(void)showLoadToView:(UIView *)view{
    [self showMessage:@"Loading..." ToView:view];
}


/**
 *  进度条View
 */
+ (MBProgressHUD *)showProgressToView:(UIView *)view ProgressModel:(MBProgressHUDMode)model Text:(NSString *)text{
    if (view == nil) view = (UIView*)[UIApplication sharedApplication].delegate.window;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.mode = model;
    hud.label.text = text;
    return hud;
}


//快速显示一条提示信息
+ (void)showAutoMessage:(NSString *)message{
    
    [self showAutoMessage:message ToView:nil];
}


//自动消失提示，无图
+ (void)showAutoMessage:(NSString *)message ToView:(UIView *)view {
    [self showMessage:message ToView:view RemainTime:0.9 Model:MBProgressHUDModeText];
}

//自定义停留时间，有图
+(void)showIconMessage:(NSString *)message ToView:(UIView *)view RemainTime:(CGFloat)time{
    [self showMessage:message ToView:view RemainTime:time Model:MBProgressHUDModeIndeterminate];
}

//自定义停留时间，无图
+(void)showMessage:(NSString *)message ToView:(UIView *)view RemainTime:(CGFloat)time{
    [self showMessage:message ToView:view RemainTime:time Model:MBProgressHUDModeText];
}

+(void)showMessage:(NSString *)message ToView:(UIView *)view RemainTime:(CGFloat)time Model:(MBProgressHUDMode)model{
    
    if (view == nil) view = (UIView*)[UIApplication sharedApplication].delegate.window;
    // 快速显示一个提示信息
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.label.text = message;
    //模式
    hud.mode = model;
    // 隐藏时候从父控件中移除
    hud.removeFromSuperViewOnHide = YES;
    // YES代表需要蒙版效果
    hud.backgroundView.style = MBProgressHUDBackgroundStyleSolidColor;
    hud.backgroundView.color = [UIColor colorWithWhite:0.f alpha:.3f];
    
    [hud hideAnimated:YES afterDelay:time];
}

+ (void)showCustomIcon:(NSString *)iconName Title:(NSString *)title ToView:(UIView *)view
{
    if (view == nil) view = (UIView*)[UIApplication sharedApplication].delegate.window;
    // 快速显示一个提示信息
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.label.text = title;
    // 设置图片
    if ([iconName isEqualToString:@"error.png"] || [iconName isEqualToString:@"success.png"]) {
        hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"MBProgressHUD.bundle/%@", iconName]]];
    }else{
        hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:iconName]];
    }
    // 再设置模式
    hud.mode = MBProgressHUDModeCustomView;
    
    // 隐藏时候从父控件中移除
    hud.removeFromSuperViewOnHide = YES;
    // 1秒之后再消失
    [hud hideAnimated:YES afterDelay:0.9];
}

+ (void)hideHUDForView:(UIView *)view
{
    if (view == nil) view = (UIView*)[UIApplication sharedApplication].delegate.window;
    [self hideHUDForView:view animated:YES];
}

+ (void)hideHUD
{
    [self hideHUDForView:nil];
}


@end