//
//  LDPMSetStopProfitLossView.m
//  PreciousMetals
//
//  Created by wangchao on 15/10/4.
//  Copyright © 2015年 NetEase. All rights reserved.
//

#import "LDPMSetStopProfitLossView.h"
#import "TradeQueryPosition.h"
#import "NPMStopProfitLossViewController.h"
#import "LDPMStopProfitLossScrollView.h"
#import "PopoverArrowView.h"
#import "NSString+NPMUtil.h"

#import "NPMSmartPLRReminInfo.h"
#import "UIStepperTextField.h"

@interface LDPMSetStopProfitLossView() <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *profitLossLabel;
@property (weak, nonatomic) IBOutlet UIStepperTextField *inputTextField;
@property (weak, nonatomic) IBOutlet UILabel *profitInfoLabel;
@property (weak, nonatomic) IBOutlet UILabel *profitLabel;
@property (weak, nonatomic) IBOutlet UIButton *checkbox;
@property (weak, nonatomic) IBOutlet UIButton *maskButton;

@property (strong, nonatomic) TradeQueryPosition *product;
@property (strong, nonatomic) PopoverArrowView *promptPopoverView;  //悬浮提示层
@property (assign, nonatomic) BOOL isfirstTime;
@property (assign, nonatomic) BOOL isEarn;
@property (strong, nonatomic, readwrite) UIColor *profitLableColor;
@property (assign, nonatomic) BOOL isDirty;
@property (strong, nonatomic) NSTimer *timer;
@end

@implementation LDPMSetStopProfitLossView

-(void)awakeFromNib
{
    [super awakeFromNib];
    self.inputTextField.delegate = self;
    self.inputTextField.stepperType = UIStepperContentTypeDouble;
    self.inputTextField.maxLength = 6;
    self.isEnabled = YES;
    self.isfirstTime = YES;
    self.isDirty = NO;
    [self.inputTextField addTarget:self action:@selector(textFieldEditingChanged:) forControlEvents:UIControlEventEditingChanged];
    [self.maskButton addTarget:self action:@selector(enableOrDisableTheView:) forControlEvents:UIControlEventTouchUpInside];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productChanged:) name:StopProfitLossProductDidChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productUpdated:) name:StopProfitLossProductUpdatedNotification object:nil];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:StopProfitLossProductDidChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:StopProfitLossProductUpdatedNotification object:nil];
}

#pragma mark - notification

-(void)productChanged:(NSNotification *)aNotification
{
    self.isfirstTime = YES;
    self.isDirty = NO;
    [self updateLimits];//setEnable 会改变UIStepperTextField的值, 所以要先更新极限值.
    self.isEnabled = YES;
    [self hidePromptLable];
}

-(void)productUpdated:(NSNotification *)aNotification
{
    if (!self.isEnabled) {
        return;
    }
    self.product = aNotification.userInfo[StopProfitLossProductKey];
    [self updateLimits];//setEnable 会改变UIStepperTextField的值, 所以要先更新极限值.

    //产品又决定不考虑手续费,跟持仓保持一致, 为了防止以后又改公式, 此处仅把手续费设成0;
    self.product.chargeRate = @"0";
    if (self.isfirstTime || !self.isDirty) {
        [self checkIsEarn];
        self.isEnabled = YES;
    }
    
    self.isfirstTime = NO;
}

- (void)updateLimits
{
    double limitDown, limitUp;
    switch (self.type) {
        case stopProfitLossTypeProfit:
            if ([self.product.buyOrSal isEqualToString:@"B"]){
                limitDown = self.product.currentPrice.doubleValue;
                limitUp = self.product.limitUp.doubleValue;
            } else {
                limitDown = self.product.limitDown.doubleValue;
                limitUp = self.product.currentPrice.doubleValue;
            }
            break;
        case stopProfitLossTypeLoss:
            if ([self.product.buyOrSal isEqualToString:@"B"]){
                limitDown = self.product.limitDown.doubleValue;
                limitUp = self.product.currentPrice.doubleValue;
            } else {
                limitDown = self.product.currentPrice.doubleValue;
                limitUp = self.product.limitUp.doubleValue;
            }
            break;
    }
    
    //以极限值无法成交,需要 +- 0.01
    limitDown += 0.01;
    limitUp -= 0.01;
    
    if (limitDown > limitUp) {
        NSLog(@"%@触发价输入框极限值错误! \n最小值为%f, 最大值为%f", self.profitLossLabel.text, limitDown, limitUp);
        return;
    }
    
    self.inputTextField.placeholder = [NSString stringWithFormat:@"%.2f ~ %.2f", limitDown, limitUp];
    self.inputTextField.maxValue = limitUp;
    self.inputTextField.minValue = limitDown;
}

- (IBAction)enableOrDisableTheView:(UIButton *)sender {
    self.isEnabled = !self.isEnabled;
    if (self.isEnabled) {
        self.isDirty = NO;
    } else {
        self.isDirty = YES;
    }
    
    [LDPMUserEvent addEvent:EVENT_STOPPROFITLOSS tag:[NSString stringWithFormat:@"%@触发价", self.profitLossLabel.text]];
}

#pragma mark - setter & getter

-(void)setType:(stopProfitLossType)type
{
    _type = type;
    [self checkIsEarn];
}

-(void)setProduct:(TradeQueryPosition *)product
{
    if (![_product.buyOrSal isEqual:product.buyOrSal]) {
        self.isfirstTime = YES;
        self.isDirty = NO;
    }
    _product = product;
}

- (BOOL)isDirty
{
    if (_isDirty && _isEnabled && !self.inputTextField.isFirstResponder && self.inputTextField.text.length > 0) {
        [self changeProfitLabel];
    }
    return _isDirty;
}

-(void)setIsEnabled:(BOOL)isEnabled
{
    NSString *checkboxImageName;
    _isEnabled = isEnabled;
    if (isEnabled) {
        if (self.type == stopProfitLossTypeProfit) {
            self.price = [self calcClosePriceWithPercent:0.01];
        } else {
            self.price = [self calcClosePriceWithPercent:0.005];
        }
        checkboxImageName = @"PLS_checkbox_checked";
        self.profitLabel.textColor = self.profitLableColor;
        self.inputTextField.enabled = YES;
    } else {
        self.price = 0;
        self.profitLabel.text = @"--";
        self.profitLabel.textColor = [UIColor colorWithRGB:0x999999];
        checkboxImageName = @"PLS_checkbox_unchecked";
        self.inputTextField.enabled = NO;
        [self hidePromptLable];
    }

    [self.checkbox setImage:[UIImage imageNamed:checkboxImageName] forState:UIControlStateNormal];
    self.inputTextField.enabled = isEnabled;
}

- (double)calcClosePriceWithPercent:(double)percent
{
    double price = 0.;
    
    if([self.product.buyOrSal isEqualToString:@"B"]) {
        if (self.type == stopProfitLossTypeProfit) {
            price = (percent * self.product.currentPrice.doubleValue + (1 + self.product.chargeRate.doubleValue) * self.product.currentPrice.doubleValue) / (1 - self.product.chargeRate.doubleValue);
            
        } else {
            price = (-percent * self.product.currentPrice.doubleValue + (1 + self.product.chargeRate.doubleValue) * self.product.currentPrice.doubleValue) / (1 - self.product.chargeRate.doubleValue);
            
        }
    } else {
        if (self.type == stopProfitLossTypeProfit) {
            price = (-percent * self.product.currentPrice.doubleValue + (1 - self.product.chargeRate.doubleValue) * self.product.currentPrice.doubleValue) / (1 + self.product.chargeRate.doubleValue);
            
        } else {
            price = (percent * self.product.currentPrice.doubleValue + (1 - self.product.chargeRate.doubleValue) * self.product.currentPrice.doubleValue) / (1 + self.product.chargeRate.doubleValue);
        }
    }
    return price;
}

-(void)checkIsEarn
{
    switch (self.type) {
        case stopProfitLossTypeProfit:{
            self.profitLossLabel.text = @"止盈";
            self.isEarn = [self.product.buyOrSal isEqualToString:@"B"] ? YES : NO;
            break;
        }
            
        case stopProfitLossTypeLoss:
        {
            self.profitLossLabel.text = @"止损";
            self.isEarn = [self.product.buyOrSal isEqualToString:@"B"] ? NO : YES;
            break;
        }
    }
}

-(void)setIsEarn:(BOOL)isEarn
{
    _isEarn = isEarn;
    if (isEarn) {
        self.profitInfoLabel.text = @"较当前价涨 ";
        self.profitLableColor = [UIColor colorWithRGB:0xf26061];
    } else {
        self.profitInfoLabel.text = @"较当前价跌 ";
        self.profitLableColor = [UIColor colorWithRGB:0x54c745];
    }
    self.profitLabel.textColor = self.profitLableColor;
}

-(void)setPrice:(double)price
{
    _price = price;
    if (price == 0) {
        self.inputTextField.text = @"";
    } else {
        self.inputTextField.text = [NSString stringWithFormat:@"%.2f", price];
        [self changeProfitLabel];
    }
}


- (void)changeProfitLabel
{
    if (self.product.currentPrice.doubleValue < DBL_EPSILON) {
        self.profitLabel.text = @"--";
        self.profitLabel.textColor = [NPMColor grayTextColor];
        return;
    }
    
    double diff = self.price - self.product.currentPrice.doubleValue;
    double earnMoney = diff - (self.price + self.product.currentPrice.doubleValue) * self.product.chargeRate.doubleValue;//盈利 - 买卖双向手续费
    double earnMoneyPercent = earnMoney / self.product.currentPrice.doubleValue ;
    if (earnMoney > 0) {
        self.isEarn = YES;
        self.profitLabel.text = [NSString stringWithFormat:@"+%.2f%%", earnMoneyPercent * 100];

    } else if (earnMoney < 0) {
        self.isEarn = NO;
        self.profitLabel.text = [NSString stringWithFormat:@"%.2f%%", earnMoneyPercent * 100];
    } else {
        self.profitLabel.text = @"0.00%";
        self.profitLabel.textColor = [NPMColor blackTextColor];
    }
}

-(NSString *)profitString
{
    return self.profitLabel.text;
}

-(NSString *)profitInfoString
{
    return self.profitInfoLabel.text;
}

#pragma mark - textFieldEditingChanged

- (void)textFieldEditingChanged:(UITextField *)sender
{
    if (!sender.isFirstResponder) {
        _price = self.inputTextField.text.doubleValue;//此处不能调setter, 否则用户把2.72删成2.7,就又会被改成2.70
        [self changeProfitLabel];
    } 
    _price = sender.text.doubleValue;
    self.isDirty = YES;
}

#pragma mark - promptPopoverView

- (void)showPromptPopoverView:(UITextField *)sender text:(NSString *)text
{
    if (sender == nil || text == nil) {
        return;
    }
    
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    
    if (self.promptPopoverView) {
        [self.promptPopoverView removeFromSuperview];
        self.promptPopoverView = nil;
    }
    
    if (!self.timer) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(hidePromptLable) userInfo:nil repeats:NO];
    }
    
    UIFont *font = [UIFont boldSystemFontOfSize:12.0f];
    CGFloat width = [NSString calculateTextWidth:text font:font] + 8;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat height;
    NSLineBreakMode lineBreakMode;
    NSInteger numberOfLines;
    NSTextAlignment textAlignment;
    NSString *str= @"";
    if (width > screenWidth*0.75) {
        width = 0;
        NSString *widthStr = text;
        textAlignment = NSTextAlignmentLeft;
        lineBreakMode = NSLineBreakByTruncatingTail;
        numberOfLines = 1;
        width = [NSString calculateTextWidth:widthStr font:font] + 8;
        height = 30.0;
        str = text;
    } else {
        textAlignment = NSTextAlignmentCenter;
        lineBreakMode = NSLineBreakByTruncatingTail;
        numberOfLines = 1;
        height = 30.0;
        str = text;
    }
    self.promptPopoverView = [[PopoverArrowView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    self.promptPopoverView.popoverPoint = CGPointMake(width / 2, height - 2.0f);
    self.promptPopoverView.arrowDirection = DYArrowDirectionDown;
    self.promptPopoverView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.promptPopoverView.bgColor = [UIColor colorWithRGB:0x333333];
    self.promptPopoverView.borderColor = [UIColor colorWithRGB:0x333333];
    self.promptPopoverView.textColor = [UIColor whiteColor];
    self.promptPopoverView.font = font;
    self.promptPopoverView.alpha = 0.;
    self.promptPopoverView.textAlignment = textAlignment;
    self.promptPopoverView.lineBreakMode = lineBreakMode;
    self.promptPopoverView.numberOfLines = numberOfLines;
    
    self.promptPopoverView.center = sender.center;
    CGRect rect = self.promptPopoverView.frame;
    rect.origin.y = rect.origin.y - height;
    self.promptPopoverView.frame = rect;
    self.promptPopoverView.text = str;
    
    [[sender superview] addSubview:self.promptPopoverView];
    
    [UIView animateWithDuration:1 animations:^{
        self.promptPopoverView.alpha = 0.85;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)hidePromptLable
{
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    if (self.promptPopoverView) {
        [UIView animateWithDuration:1 animations:^{
            self.promptPopoverView.alpha = 0;
        } completion:^(BOOL finished) {
            [self.promptPopoverView removeFromSuperview];
            self.promptPopoverView = nil;
        }];
    }
}


#pragma mark - UITextFieldDelegate

-(void)textFieldDidBeginEditing:(UIStepperTextField *)textField
{
    [self hidePromptLable];
}

-(void)textFieldDidEndEditing:(UIStepperTextField *)textField
{
    if (textField.text.length == 0) {
        self.profitLabel.text = @"--";
        self.profitLabel.textColor = [UIColor colorWithRGB:0x999999];
        return;
    }
    
    NSString *prompString;
    if (self.price > textField.maxValue || self.price < textField.minValue) {
        prompString = [NSString stringWithFormat:@"%@触发价范围：%.2f ~ %.2f", self.profitLossLabel.text, textField.minValue, textField.maxValue];
        [self showPromptPopoverView:textField text:prompString];
    }
    self.price = textField.text.doubleValue;
}

@end
