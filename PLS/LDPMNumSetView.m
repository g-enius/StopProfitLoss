//
//  LDPMNumSetView.m
//  PreciousMetals
//
//  Created by wangchao on 15/10/5.
//  Copyright © 2015年 NetEase. All rights reserved.
//

#import "LDPMNumSetView.h"
#import "TradeQueryPosition.h"
#import "LDPMStopProfitLossScrollView.h"
#import "NPMStopProfitLossViewController.h"
#import "UIStepperTextField.h"
#import "LDPMBuySellCountFastInputView.h"

@interface LDPMNumSetView() <LDPMBuySellCountFastInputViewDelegate>

@property (weak, nonatomic) IBOutlet UIStepperTextField *amountTextfield;
@property (weak, nonatomic) IBOutlet LDPMBuySellCountFastInputView *fastInputView;

@property (strong, nonatomic) TradeQueryPosition *product;
@property (assign, nonatomic) BOOL isFirstTime;
@property (assign, nonatomic) BOOL isDirty;

@end

@implementation LDPMNumSetView

-(void)awakeFromNib
{
    [super awakeFromNib];
    self.isFirstTime = YES;
    self.isDirty = NO;
    self.fastInputView.delegate = self;
    self.amountTextfield.stepperType = UIStepperContentTypeInteger;
    [self.amountTextfield addTarget:self action:@selector(textFieldEditingChanged:) forControlEvents:UIControlEventEditingChanged];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productChanged:) name:StopProfitLossProductDidChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productUpdated:) name:StopProfitLossProductUpdatedNotification object:nil];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:StopProfitLossProductDidChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:StopProfitLossProductUpdatedNotification object:nil];
}

#pragma notification

-(void)productChanged:(NSNotification *)aNotification
{
    self.isFirstTime = YES;
    self.isDirty = NO;
}

-(void)productUpdated:(NSNotification *)aNotification
{
    self.product = aNotification.userInfo[StopProfitLossProductKey];
    self.amountTextfield.placeholder = [NSString stringWithFormat:@"最大执行数量 %@", self.product.maxExecNum];
    self.amountTextfield.maxValue = self.product.maxExecNum.doubleValue;
    self.amountTextfield.minValue = 0.;
    
    if (self.isFirstTime || !self.isDirty) {
        self.fastInputView.selectedButton = self.fastInputView.allButton;
    }
    
    self.isFirstTime = NO;
}

#pragma mark - getter & setter

@synthesize num = _num;

-(void)setNum:(int)num
{
    if (num == 0) {
        self.amountTextfield.minValue = 0.;
        self.amountTextfield.maxValue = 0.;
        self.fastInputView.selectedButton = nil;
    }
    _num = num;
    self.amountTextfield.text = [NSString stringWithFormat:@"%d", num];
}

-(int)num
{
    return self.amountTextfield.text.intValue;
}

#pragma mark - UIStepperTextFieldValueChanged

-(void)textFieldEditingChanged:(UITextField *)sender
{
    self.fastInputView.selectedButton = nil;
    self.isDirty = YES;
    if (!self.amountTextfield.isFirstResponder) {
        [LDPMUserEvent addEvent:EVENT_STOPPROFITLOSS tag:@"设置数量-加减"];
    }
}

#pragma mark - LDPMBuySellCountFastInputViewDelegate

-(void)countFastInputViewPressedWithPercent:(double)percent
{
    if (1.0/3.0 == percent) {
        [LDPMUserEvent addEvent:EVENT_STOPPROFITLOSS tag:@"数量-1/3"];
    } else if (0.5 == percent) {
        [LDPMUserEvent addEvent:EVENT_STOPPROFITLOSS tag:@"数量-1/2"];
    }
    
    if (!self.isFirstTime) {
        self.isDirty = YES;
    }

    self.amountTextfield.text = [NSString stringWithFormat:@"%.0f", ceil(self.product.maxExecNum.doubleValue * percent)];
}
@end
