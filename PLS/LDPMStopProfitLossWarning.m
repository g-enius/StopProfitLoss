//
//  LDPMStopProfitLossWarning.m
//  PreciousMetals
//
//  Created by wangchao on 10/8/15.
//  Copyright © 2015 NetEase. All rights reserved.
//

#import "LDPMStopProfitLossWarning.h"
#import "NPMSmartPLRReminInfo.h"
#import "TradeQueryPosition.h"
#import "LDPMSetStopProfitLossView.h"

@interface LDPMStopProfitLossWarning()

@property (weak, nonatomic) IBOutlet UILabel *profitPriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *profitPercentLabel;
@property (weak, nonatomic) IBOutlet UILabel *lossPriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *lossPercentLabel;
@property (weak, nonatomic) IBOutlet UILabel *profitInfoLabel;
@property (weak, nonatomic) IBOutlet UILabel *lossInfoLabel;

@end

@implementation LDPMStopProfitLossWarning

-(void)awakeFromNib
{
    [super awakeFromNib];
    self.frame = CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds) - 20, CGRectGetHeight(self.frame));
}


-(void)setContentWithProfitPrice:(LDPMSetStopProfitLossView *)profitView lossView: (LDPMSetStopProfitLossView *)lossView
{
    self.profitPriceLabel.text = profitView.price ? [NSString stringWithFormat:@"%.2f", profitView.price] : @"--";
    self.profitPriceLabel.textColor = profitView.price ? [UIColor colorWithRGB:0x333333] : [UIColor colorWithRGB:0x999999];
    self.lossPriceLabel.text = lossView.price ? [NSString stringWithFormat:@"%.2f", lossView.price] : @"--";
    self.lossPriceLabel.textColor = lossView.price ? [UIColor colorWithRGB:0x333333] : [UIColor colorWithRGB:0x999999];
    self.profitPercentLabel.text = profitView.profitString;
    self.lossPercentLabel.text = lossView.profitString;
    self.profitPercentLabel.textColor = profitView.price ? profitView.profitLableColor : [UIColor colorWithRGB:0x999999];
    self.lossPercentLabel.textColor = lossView.price ? lossView.profitLableColor : [UIColor colorWithRGB:0x999999];
    self.profitInfoLabel.text = profitView.profitInfoString;
    self.lossInfoLabel.text = lossView.profitInfoString;
}




@end
