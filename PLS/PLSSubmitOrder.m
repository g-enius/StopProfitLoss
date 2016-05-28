//
//  PLSSubmitOrder.m
//  PreciousMetals
//
//  Created by wangchao on 10/16/15.
//  Copyright © 2015 NetEase. All rights reserved.
//

#import "PLSSubmitOrder.h"
#import "LDPMNumSetView.h"
#import "LDPMSetStopProfitLossView.h"

@interface PLSSubmitOrder()

@property (weak, nonatomic) IBOutlet UILabel *numLabel;
@property (weak, nonatomic) IBOutlet UILabel *profitPriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *profitInfoLabel;
@property (weak, nonatomic) IBOutlet UILabel *profitPercentLabel;
@property (weak, nonatomic) IBOutlet UILabel *lossPriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *lossInfoLabel;
@property (weak, nonatomic) IBOutlet UILabel *lossPercentLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@end

@implementation PLSSubmitOrder

- (void)setContentWithNumSetView:(LDPMNumSetView *)numSetView profitView:(LDPMSetStopProfitLossView *)profitView lossView:(LDPMSetStopProfitLossView *)lossView title:(NSString *)title
{
    self.nameLabel.text = [NSString stringWithFormat:@"%@", title];
    self.numLabel.text = [NSString stringWithFormat:@"%d手", numSetView.num];
    self.profitPriceLabel.text = profitView.price ? [NSString stringWithFormat:@"%.2f", profitView.price] : @"--";
    self.profitPriceLabel.textColor = profitView.price ? [UIColor colorWithRGB:0x333333] : [UIColor colorWithRGB:0x999999];
    self.profitInfoLabel.text = profitView.profitInfoString;
    self.profitPercentLabel.text = profitView.profitString;
    self.profitPercentLabel.textColor = profitView.price ? profitView.profitLableColor : [UIColor colorWithRGB:0x999999];
    self.lossPriceLabel.text = lossView.price ? [NSString stringWithFormat:@"%.2f", lossView.price] : @"--";
    self.lossPriceLabel.textColor = lossView.price ? [UIColor colorWithRGB:0x333333] : [UIColor colorWithRGB:0x999999];
    self.lossInfoLabel.text = lossView.profitInfoString;
    self.lossPercentLabel.text = lossView.profitString;
    self.lossPercentLabel.textColor = lossView.price ? lossView.profitLableColor : [UIColor colorWithRGB:0x999999];
    self.layer.cornerRadius = 5.f;
}

@end
