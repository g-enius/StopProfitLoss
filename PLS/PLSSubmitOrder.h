//
//  PLSSubmitOrder.h
//  PreciousMetals
//
//  Created by wangchao on 10/16/15.
//  Copyright © 2015 NetEase. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LDPMNumSetView;
@class LDPMSetStopProfitLossView;

@interface PLSSubmitOrder : UIView

- (void)setContentWithNumSetView:(LDPMNumSetView *)numSetView profitView:(LDPMSetStopProfitLossView *)profitView lossView:(LDPMSetStopProfitLossView *)lossView title:(NSString *)title;

@end
