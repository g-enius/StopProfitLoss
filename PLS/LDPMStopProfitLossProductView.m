 //
//  LDPMStopProfitLossProductView.m
//  PreciousMetals
//
//  Created by wangchao on 9/29/15.
//  Copyright © 2015 NetEase. All rights reserved.
//

#import "LDPMStopProfitLossProductView.h"
#import "LDPMStopProfitLossScrollView.h"
#import "NPMStopProfitLossViewController.h"
#import "TradeQueryPosition.h"
#import "LDPMNjsPosition.h"

@interface LDPMStopProfitLossProductView()

@property (weak, nonatomic) IBOutlet UIImageView *productTypeImage;
@property (weak, nonatomic) IBOutlet UILabel *positionAmountLabel;
@property (weak, nonatomic) IBOutlet UILabel *averagePriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *marketPriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *breakEvenLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *earnMoneyLabel;
@property (weak, nonatomic) IBOutlet UILabel *earnPercentLabel;
@property (copy, nonatomic) NSString *productID;

@end

@implementation LDPMStopProfitLossProductView

#pragma mark - life Cycle

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productUpdated:) name:StopProfitLossProductUpdatedNotification object:nil];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:StopProfitLossProductUpdatedNotification object:nil];
}

#pragma notification

//单个产品刷新的时候,根据TradeQueryPosition赋值
-(void)productUpdated:(NSNotification *)aNotification
{
    TradeQueryPosition *product = aNotification.userInfo[StopProfitLossProductKey];
    if ([self.productID isEqualToString: product.wareId]) {
        self.nameLabel.text = [product.wareName stringByAppendingString:product.wareId];
        NSMutableAttributedString *amoutStr = [[NSMutableAttributedString alloc]initWithString:[NSString stringWithFormat:@"持仓数量  %@手",product.num]];
        [amoutStr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRGB:0x333333] range:NSMakeRange(4, amoutStr.length - 4)];
        self.positionAmountLabel.attributedText = amoutStr;
        
        NSMutableAttributedString *averageStr = [[NSMutableAttributedString alloc]initWithString:[NSString stringWithFormat:@"持仓均价  %.2f", product.price.doubleValue]];
        [averageStr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRGB:0x333333] range:NSMakeRange(4, averageStr.length - 4)];
        self.averagePriceLabel.attributedText = averageStr;
        
        self.marketPriceLabel.text = [NSString stringWithFormat:@"%.2f", product.currentPrice.doubleValue];
       
        NSMutableAttributedString *breakEvenStr = [[NSMutableAttributedString alloc]initWithString:[NSString stringWithFormat:@"保  本  价  %.2f", product.breakEven.doubleValue]];
        [breakEvenStr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRGB:0x333333] range:NSMakeRange(7, breakEvenStr.length - 7)];
        self.breakEvenLabel.attributedText = breakEvenStr;
        
        if ([product.buyOrSal isEqualToString:@"B"]) {
            self.productTypeImage.image = [UIImage imageNamed:@"PLS_buy_icon"];
        } else {
            self.productTypeImage.image = [UIImage imageNamed:@"PLS_sell_icon"];
        }
        
        if (product.consultFlat.doubleValue > 0) {
            self.earnMoneyLabel.text = [NSString stringWithFormat:@"+%.2f", product.consultFlat.doubleValue];
            self.earnMoneyLabel.textColor = [UIColor colorWithRGB:0xf206061];
            self.earnPercentLabel.text = [NSString stringWithFormat:@"+%.2f%%", product.flatScale.doubleValue];
            self.earnPercentLabel.textColor = [UIColor colorWithRGB:0xf206061];
        } else if(product.consultFlat.doubleValue < 0) {
            self.earnMoneyLabel.text = [NSString stringWithFormat:@"%.2f", product.consultFlat.doubleValue];
            self.earnMoneyLabel.textColor = [UIColor colorWithRGB:0x54c745];
            self.earnPercentLabel.text = [NSString stringWithFormat:@"%.2f%%", product.flatScale.doubleValue];
            self.earnPercentLabel.textColor = [UIColor colorWithRGB:0x54c745];
        } else {
            self.earnMoneyLabel.text = [NSString stringWithFormat:@"%.2f", product.consultFlat.doubleValue];
            self.earnMoneyLabel.textColor = [UIColor colorWithRGB:0x333333];
            self.earnPercentLabel.text = [NSString stringWithFormat:@"%.2f%%", product.flatScale.doubleValue];
            self.earnPercentLabel.textColor = [UIColor colorWithRGB:0x333333];
        }
    }
}

#pragma mark - public methods

//初始化的时候根据TradeQueryHold 把所有产品的值都赋上, 否则网路慢的时候会看见storyboard中的默认的数据
- (void)initContentWithTradeQueryHold:(LDPMNjsPosition *)hold
{
    self.productID = hold.WAREID; // 初始化的时候指定每个View的ID
    self.nameLabel.text = [hold.WAREIDDESC stringByAppendingString:hold.WAREID];
    self.marketPriceLabel.text = [NSString stringWithFormat:@"%.2f", hold.NEWPRICE.doubleValue];
    self.breakEvenLabel.text = [NSString stringWithFormat:@"保  本  价  %@", hold.BBPRICE];
    
    if (hold.GOODSNUM.doubleValue > 0) {
        self.productTypeImage.image = [UIImage imageNamed:@"PLS_buy_icon"];
        self.positionAmountLabel.text = [NSString stringWithFormat:@"持仓数量  %@手", hold.GOODSNUM];
        self.averagePriceLabel.text = [NSString stringWithFormat:@"持仓均价  %.2f", hold.BAVGPRICE.doubleValue];
    } else {
        self.productTypeImage.image = [UIImage imageNamed:@"PLS_sell_icon"];
        self.positionAmountLabel.text = [NSString stringWithFormat:@"持仓数量  %@手", hold.RHNUMBER];
        self.averagePriceLabel.text = [NSString stringWithFormat:@"持仓均价  %.2f", hold.SAVGPRICE.doubleValue];
    }

    if (hold.CONSULTFLAT.doubleValue > 0) {
        self.earnMoneyLabel.text = [NSString stringWithFormat:@"+%.2f", hold.CONSULTFLAT.doubleValue];
        self.earnPercentLabel.text = [NSString stringWithFormat:@"+%.2f%%", hold.FLATSCALE.doubleValue];
        self.earnMoneyLabel.textColor = [UIColor colorWithRGB:0xf206061];
        self.earnPercentLabel.textColor = [UIColor colorWithRGB:0xf206061];
    } else if (hold.CONSULTFLAT.doubleValue < 0){
        self.earnMoneyLabel.text = [NSString stringWithFormat:@"%.2f", hold.CONSULTFLAT.doubleValue];
        self.earnPercentLabel.text = [NSString stringWithFormat:@"%.2f%%", hold.FLATSCALE.doubleValue];
        self.earnMoneyLabel.textColor = [UIColor colorWithRGB:0x54c745];
        self.earnPercentLabel.textColor = [UIColor colorWithRGB:0x54c745];
    } else {
        self.earnMoneyLabel.text = [NSString stringWithFormat:@"%.2f", hold.CONSULTFLAT.doubleValue];
        self.earnMoneyLabel.textColor = [UIColor colorWithRGB:0x333333];
        self.earnPercentLabel.text = [NSString stringWithFormat:@"%.2f%%", hold.FLATSCALE.doubleValue];
        self.earnPercentLabel.textColor = [UIColor colorWithRGB:0x333333];
    }
}

@end

