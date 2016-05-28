//
//  LDPMStopProfitLossWarning.h
//  PreciousMetals
//
//  Created by wangchao on 10/8/15.
//  Copyright © 2015 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>
@class LDPMSetStopProfitLossView;
@interface LDPMStopProfitLossWarning : UIView

-(void)setContentWithProfitPrice:(LDPMSetStopProfitLossView *)profitView lossView: (LDPMSetStopProfitLossView *)lossView;

@end
