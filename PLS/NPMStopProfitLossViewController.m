//
//  NPMStopProfitLossViewController.m
//  PreciousMetals
//
//  Created by wangchao on 10/2/15.
//  Copyright (c) 2015 NetEase. All rights reserved.
//

#import "NPMStopProfitLossViewController.h"
#import "NPMStopLossProfitDataSource.h"
#import "PlaceLimitOrderParam.h"
#import "NPMTradeSession.h"
#import "NPMTradeQueryResponse.h"
#import "TradeQueryPosition.h"
#import "QueryPositionParam.h"
#import "NPMQueryPositionResponse.h"
#import "MJRefresh.h"
#import "NPMWebViewController.h"
#import "UIAlertView+MKBlockAdditions.h"
#import "LDPMStopProfitLossScrollView.h"
#import "LDPMSetStopProfitLossView.h"
#import "LDPMNumSetView.h"
#import "NPMServiceResponse.h"
#import "LDPMStopProfitLossWarning.h"
#import "LDPMEditableAlertView.h"
#import "UpdateRemindInfoParam.h"
#import "UpdateRemindInfo.h"
#import "PLSSubmitOrder.h"
#import "LDPMNjsPosition.h"
#import "LDSocketPushClient.h"
#import "LDPMSocketMessageTopicUtil.h"
#import "NPMRealTimeMarketInfo.h"
#import "LDSPMessage.h"
#import "UIScrollView+LDPMAdditions.h"
#import "LDPMTableViewHeader.h"

NSString * const StopProfitLossProductUpdatedNotification = @"StopProfitLossProductUpdatedNotification";
NSString * const StopProfitLossProductKey = @"StopProfitLossProductKey";
static const NSInteger kEmptyViewHeight = 200;
static NSString *const kDefaultWEARID = @"AG";
static NSString *const KVOPropertyName = @"isEnabled";

@interface NPMStopProfitLossViewController () <UIScrollViewDelegate>

@property (strong, nonatomic) IBOutlet UIView *tableHeaderView;
@property (weak, nonatomic) IBOutlet LDPMStopProfitLossScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *view2;
@property (weak, nonatomic) IBOutlet UIView *view3;
@property (weak, nonatomic) IBOutlet UIView *view4;
@property (weak, nonatomic) IBOutlet UIButton *remindMeButton;
@property (weak, nonatomic) IBOutlet UIButton *confirmSettingButton;
@property (assign, nonatomic) BOOL enabled;
@property (strong, nonatomic) LDPMNumSetView *numSetView;
@property (strong, nonatomic) LDPMSetStopProfitLossView *stopLossView;
@property (strong, nonatomic) LDPMSetStopProfitLossView *stopProfitView;
@property (strong, nonatomic) NSMutableArray *positionGoodsArray;
@property (strong, nonatomic) TradeQueryPosition *product;
@property (strong, nonatomic) UIView *emptyFooterView;
@property (strong, nonatomic) UILabel *emptyLabel;
@property (nonatomic, strong) NPMStopLossProfitDataSource *dataSorce;

@end

@implementation NPMStopProfitLossViewController

#pragma mark - lifeCycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //patnerId检查
    NSAssert(self.partnerId.length > 0, @"%@ partnerId不能为空", NSStringFromClass(self.class));
    if (self.partnerId.length <= 0) {
        self.partnerId = [[NPMTradeSession sharedInstance] defaultOpenedPartnerId];
    }
    
    self.title = @"止盈止损";
    self.product = [TradeQueryPosition new];
    [self initCustomViews];
    [self initRightBarButtonItems];
    self.tableView.delegate = (id<UITableViewDelegate>)self.dataSorce;
    self.tableView.dataSource = self.dataSorce;
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapped:)]];
    [self setupPullDownwardsRefresh];
    //add KVO to check if disable
    [self.stopProfitView addObserver:self forKeyPath:KVOPropertyName options:NSKeyValueObservingOptionNew context:nil];
    [self.stopLossView addObserver:self forKeyPath:KVOPropertyName options:NSKeyValueObservingOptionNew context:nil];
    self.isNeedNetErrorAlert = YES;
    self.dataSorce.hostVC = self;
    self.dataSorce.delegate = (id<stopProfitLossDelegate>)self;
    self.enabled = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.stopProfitView removeObserver:self forKeyPath:KVOPropertyName];
    [self.stopLossView removeObserver:self forKeyPath:KVOPropertyName];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView setAutoUnhideTextInputsByKeyboard:YES];
    if ([UIDevice iphoneFourScreen]) {
        self.tableView.translateOffSet = 0.0f;
    } else {
        self.tableView.translateOffSet = 90.0f;
    }
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //增加主动推
    [self subscribeMessageForWareID:self.product.wareId];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.tableView setAutoUnhideTextInputsByKeyboard:NO];
    //移除主动推
    [self unsubscribeMessageForWareID:self.product.wareId];
}

-(void)initCustomViews
{
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productChanged:) name:StopProfitLossProductDidChangedNotification object:self.scrollView];
    [self.scrollView setContentWithPositionArray:self.positionArray defaultWareId:self.defaultWareId];

    self.numSetView = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([LDPMNumSetView class]) owner:self options:nil].firstObject;
    self.numSetView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view2.bounds), CGRectGetHeight(self.view2.bounds));
    self.numSetView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.view2 addSubview:self.numSetView];
    
    self.stopProfitView = [[NSBundle mainBundle]loadNibNamed:NSStringFromClass([LDPMSetStopProfitLossView class]) owner:self options:nil].firstObject;
    self.stopProfitView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view3.bounds), CGRectGetHeight(self.view3.bounds));
    self.stopProfitView.type = stopProfitLossTypeProfit;
    self.stopProfitView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.view3 addSubview:self.stopProfitView];
    
    self.stopLossView = [[NSBundle mainBundle]loadNibNamed:NSStringFromClass([LDPMSetStopProfitLossView class]) owner:self options:nil].firstObject;
    self.stopLossView.type = stopProfitLossTypeLoss;
    self.stopLossView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view4.bounds), CGRectGetHeight(self.view4.bounds));
    self.stopLossView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.view4 addSubview:self.stopLossView];
    
   
}

#pragma mark - rightBarButtonItems

- (void)initRightBarButtonItems
{
    UIButton *rulesBtn = [NPMUIFactory naviButtonWithTitle:@"规则" target:self selector:nil];
    [rulesBtn setTitleColor:[UIColor colorWithRGB:0x82afdf] forState:UIControlStateNormal];
    rulesBtn.size = CGSizeMake(44, 44);
    @weakify(self);
    rulesBtn.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        @strongify(self);
        NPMWebViewController *vc = [[NPMWebViewController alloc] init];
        vc.forceLocalTitle = YES;
        vc.title = @"智能仓位管理规则";
        vc.startupUrlString = [NSString stringWithFormat:@"http://fa.163.com/help/wapdetail/njsposrules?expandedItem=FullStop_of_NJS"];
        [vc setHidesBottomBarWhenPushed:YES];
        [self.navigationController pushViewController:vc animated:YES];
        return [RACSignal empty];
    }];
    UIBarButtonItem *rulesBarItem = [[UIBarButtonItem alloc] initWithCustomView:rulesBtn];
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    if ([UIDevice osMainVersion] < 7) {
        negativeSpacer.width = 0;
    } else {
        negativeSpacer.width = -12;
    }
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:negativeSpacer, rulesBarItem, nil];
}

#pragma mark - KVO

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:KVOPropertyName]) {
        if (!self.stopProfitView.isEnabled && !self.stopLossView.isEnabled) {
            self.enabled = NO;
        } else if (!self.remindMeButton.isEnabled) {
            self.enabled = YES;
        }
    }
}

#pragma mark - override StopProfitLossProductDidChangedNotification

-(void)productChanged:(NSNotification *)aNotificaiton
{
    [self unsubscribeMessageForWareID:self.product.wareId];
    NSInteger curPage = ((NSNumber *)aNotificaiton.userInfo[StopProfitLossProductIndexKey]).integerValue;
    self.product.wareId = ((LDPMNjsPosition *)self.positionArray[curPage]).WAREID;
    //只有切换商品的时候才会开启, 其余情况仅用tableview有下拉刷新
    [self startActivity:NSLocalizedString(@"Wait For Loading", @"努力加载中，请稍候...")];
    [self requestPositionData];
}

- (void)keyboardDidShow:(NSNotification *)aNotification
{
    [LDPMUserEvent addEvent:EVENT_STOPPROFITLOSS tag:@"吊起键盘"];
}

#pragma mark - 主动推

- (void)subscribeMessageForWareID:(NSString *)wareID
{
    @weakify(self)
    [[LDSocketPushClient defaultClient] addObserver:self topic:[LDPMSocketMessageTopicUtil simplePriceTopicWithPartnerId:NPMPartnerIDNanJiaoSuo goodsId:wareID] pushType:LDSocketPushTypeGroup usingBlock:^(LDSPMessage *message) {
        @strongify(self)
        id object = [NSJSONSerialization JSONObjectWithData:message.body
                                                    options:NSJSONReadingMutableContainers
                                                      error:NULL];
        NPMRealTimeMarketInfo *marketInfo = [[NPMRealTimeMarketInfo alloc] initWithArray:object];
        if (marketInfo && [self.product.wareId isEqualToString:marketInfo.goodsId]) {
            self.product.currentPrice = [NSString stringWithFormat:@"%.2f", marketInfo.price];
            [self updateEarnMoney]; //根据最新价自己算盈亏和盈亏率
            [[NSNotificationCenter defaultCenter] postNotificationName:StopProfitLossProductUpdatedNotification object:self userInfo:@{StopProfitLossProductKey:self.product}];
        }
    }];
    
    [[LDSocketPushClient defaultClient] addObserver:self topic:[LDPMSocketMessageTopicUtil tradeOrderTopicWithPartnerId:NPMPartnerIDNanJiaoSuo] pushType:LDSocketPushTypeSpecial usingBlock:^(LDSPMessage *message) {
        @strongify(self)
        [self requestPositionData];
    }];
}

- (void)unsubscribeMessageForWareID:(NSString *)wareID
{
    [[LDSocketPushClient defaultClient] removeObserver:self topic:[LDPMSocketMessageTopicUtil simplePriceTopicWithPartnerId:NPMPartnerIDNanJiaoSuo goodsId:wareID]];
    [[LDSocketPushClient defaultClient] removeObserver:self topic:[LDPMSocketMessageTopicUtil tradeOrderTopicWithPartnerId:NPMPartnerIDNanJiaoSuo]];
}

#pragma mark - updateLabelWithSocketPrice
- (void)updateEarnMoney
{
    double earn = 0.;
    if ([self.product.buyOrSal isEqualToString:@"B"]) {
        earn = (self.product.currentPrice.doubleValue - self.product.price.doubleValue) * self.product.num.doubleValue;
    } else {
        earn = (self.product.price.doubleValue - self.product.currentPrice.doubleValue) * self.product.num.doubleValue;
    }
    double percent = (earn / (self.product.price.doubleValue * self.product.num.doubleValue)) * 100;

    self.product.consultFlat = [NSString stringWithFormat:@"%.2f", earn];
    self.product.flatScale = [NSString stringWithFormat:@"%.2f", percent];
}
#pragma mark - pull down refresh

- (void)setupPullDownwardsRefresh
{
    __weak typeof(self) weakSelf = self;
    self.tableView.mj_header = [LDPMTableViewHeader headerWithRefreshingBlock:^{
        [weakSelf.dataSorce requestQueryLimit];//查询止盈止损历史记录
        [weakSelf requestPositionData];//查询最近持仓接口
    }];
    
    [self.tableView.mj_header beginRefreshing];
   
}

#pragma mark - getter&setter


-(void)setEnabled:(BOOL)enabled
{
    _enabled = enabled;
    if (enabled) {
        self.remindMeButton.enabled = YES;
        [self.remindMeButton setImage:[UIImage imageNamed:@"PLS_remindMe_enabled"] forState:UIControlStateNormal];
        self.confirmSettingButton.enabled = YES;
        [self.confirmSettingButton setBackgroundImage:[UIImage imageNamed:@"PLS_confirm_enabled"] forState:UIControlStateNormal];
    } else {
        self.remindMeButton.enabled = NO;
        [self.remindMeButton setImage:[UIImage imageNamed:@"PLS_remindMe_disabled"] forState:UIControlStateNormal];
        self.confirmSettingButton.enabled = NO;
        [self.confirmSettingButton setBackgroundImage:[UIImage imageNamed:@"PLS_confirm_disabled"] forState:UIControlStateNormal];
    }
}

- (NPMStopLossProfitDataSource *)dataSorce
{
    if (!_dataSorce) {
        _dataSorce = [NPMStopLossProfitDataSource new];
        _dataSorce.partnerId = self.partnerId;
    }
    
    return _dataSorce;
}

#pragma mark - tapGesture

- (void)backgroundTapped:(id)sender
{
    [self.view endEditing:YES];
}

#pragma mark - 查询最近持仓

- (void)requestPositionData
{
    if (!self.product)
        self.product.wareId = ((LDPMNjsPosition *)self.positionArray[0]).WAREID;
    
    QueryPositionParam *param = [QueryPositionParam new];
    param.partnerId= self.partnerId;
    param.wareId = self.product.wareId;
    
    @weakify(self);
    [[NPMTradeService sharedService] queryPositionOrder:param onComplete:^(NPMQueryPositionResponse *response) {
        @strongify(self);
        
        if (response.retCode == NPMRetCodeSuccess) {
            self.product = response.ret;
            if (self.product.num.doubleValue < 0.01) { //对进入止盈止损后, 如果外部挂单成交了, 当前持仓为0的时候的特殊处理.
                self.numSetView.num = 0;
                self.stopProfitView.isEnabled = NO;
                self.stopLossView.isEnabled = NO;
                [self.dataSorce requestQueryLimit];//查询止盈止损历史记录
            }
            if (self.product) {
                //增加主动推  注册必须在self.product更新完成之后, 否则会出现仅仅更新了wareId, 最高价和最低价并没有更新, 这时候收到了主动推的最新价, 导致止盈/止损触发价,文本框极限值设置错误.
                [[NSNotificationCenter defaultCenter] postNotificationName:StopProfitLossProductUpdatedNotification object:self userInfo:@{StopProfitLossProductKey:self.product}];
            }
            [self subscribeMessageForWareID:self.product.wareId];
        } else {
            [self alertWithResponse:response];
        }
        [self.tableView.mj_header endRefreshing];
        [self stopActivity];//无论开启与否,都直接关闭.只有切换商品的时候才会开启, 其余情况仅用tableview有下拉刷新
    }];
    
}

#pragma mark - 设置盈亏提醒
- (IBAction)setWarningMessages:(UIButton *)sender
{
    [LDPMUserEvent addEvent:EVENT_STOPPROFITLOSS tag:@"盈亏提醒"];
    [self.view endEditing:YES];
    
    if ((self.stopLossView.price < 0.01 && self.stopProfitView.price < 0.01)) {
        NPMAlertView *alertView = [[NPMAlertView alloc] initWithTitle:nil message:@"盈亏提醒设置不能为空，请您重新设置" cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alertView show];
        return;
    }
        
    if (self.product.num.integerValue) { // 判断是否有该商品持仓
        NSString *error;
         if (self.numSetView.num < 0.01) {
            NPMAlertView *alertView = [[NPMAlertView alloc] initWithTitle:nil message:@"请输入执行数量" cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alertView show];
            return;
        } else if (![self isPriceEnterCorrect:&error]) { // 止盈止损价格输入判断
            NPMAlertView *alertView = [[NPMAlertView alloc] initWithTitle:nil message:error cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alertView show];
            return;
        } else if (![self isAmountEnterCorrect:&error]) { // 执行数量输入判断
            NPMAlertView *alertView = [[NPMAlertView alloc] initWithTitle:nil message:error cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alertView show];
            return;
        } else {
            LDPMStopProfitLossWarning *contentView = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([LDPMStopProfitLossWarning class]) owner:self options:nil].firstObject;
            [contentView setContentWithProfitPrice:self.stopProfitView lossView:self.stopLossView];
            
            LDPMEditableAlertView *alert = [[LDPMEditableAlertView alloc] initWithTitle:nil
                                                                                  containerView:contentView
                                                                                   buttonTitles:@[@"达到以上条件时提醒我", @"取消"]];
            alert.appearType = LDPMConfirmAlertAnimationSheet;
            alert.cancelType = LDPMConfirmAlertAnimationMoveOutFromBottom;
            alert.doneType = LDPMConfirmAlertAnimationMoveOutFromBottom;
            alert.confirmButtonColor = [UIColor colorWithRGB:0xee5b5c];
            
            @weakify(self);
            alert.dismissBlock = ^(LDPMEditableAlertView *alert, NSUInteger index) {
                @strongify(self);
                
                BOOL isBuy = [self.product.buyOrSal isEqualToString:@"B"] ? YES : NO;
                
                double upPrice = 0;
                double downPrice = 0;
                
                if (self.stopProfitView.price > 0) {
                    if (self.stopProfitView.price > self.product.currentPrice.doubleValue) {
                        upPrice = self.stopProfitView.price;
                    } else {
                        downPrice = self.stopProfitView.price;
                    }
                }
                
                if (self.stopLossView.price > 0) {
                    if (self.stopLossView.price > self.product.currentPrice.doubleValue) {
                        upPrice = self.stopLossView.price;
                    } else {
                        downPrice = self.stopLossView.price;
                    }
                }
                
                if (index == 0) {
                    [LDPMUserEvent addEvent:EVENT_STOPPROFITLOSS tag:@"达到以上条件提醒我"];
                    [self.dataSorce setRemindeWithWareId:self.product.wareId isBuy:isBuy upPrice:upPrice downPrice:downPrice completion:^{
                        @strongify(self);
                        [self showToast:@"盈亏设置已生效"];
                    }];
                }
                [alert removeFromSuperview];
            };
            [alert show];
        }
    } else {
        NPMAlertView *alertView = [[NPMAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"StopLossProfit Operation Hint", @"您当前没有该商品的持仓，不能进行盈亏提醒操作") cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alertView show];
        return;
    }
}

#pragma mark - 提交止盈止损单

- (IBAction)submitOrder:(UIButton *)sender
{
    __weak typeof(self) weakSelf = self;
    [LDPMUserEvent addEvent:EVENT_STOPPROFITLOSS tag:@"确定设置"];
    
    [self.view endEditing:YES];
    
    if ((self.stopLossView.price < 0.01 && self.stopProfitView.price < 0.01)) {
        NPMAlertView *alertView = [[NPMAlertView alloc] initWithTitle:nil message:@"请输入止盈价或止损价" cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alertView show];
        return;
    }
    
    if (self.product.num.intValue) {  // 判断是否有该商品持仓
        NSString *error;
        if (self.numSetView.num < 0.01) {
            NPMAlertView *alertView = [[NPMAlertView alloc] initWithTitle:nil message:@"请输入执行数量" cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alertView show];
            return;
        } else if (![self isPriceEnterCorrect:&error]) { // 止盈止损价格输入判断
            NPMAlertView *alertView = [[NPMAlertView alloc] initWithTitle:nil message:error cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alertView show];
            return;
        } else if (![self isAmountEnterCorrect:&error]) { // 执行数量输入判断
            NPMAlertView *alertView = [[NPMAlertView alloc] initWithTitle:nil message:error cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alertView show];
            return;
        } else {
            PLSSubmitOrder *contentView = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([PLSSubmitOrder class]) owner:self options:nil].firstObject;
            [contentView setContentWithNumSetView:self.numSetView profitView:self.stopProfitView lossView:self.stopLossView title:[NSString stringWithFormat:@"%@%@", self.product.wareName, self.product.wareId]];
            LDPMEditableAlertView *alert = [[LDPMEditableAlertView alloc] initWithTitle:nil
                                                                                  containerView:contentView
                                                                                   buttonTitles:@[@"取消", @"确定"]];
            alert.appearType = LDPMConfirmAlertAnimationMoveInFromTop;
            alert.cancelType = LDPMConfirmAlertAnimationMoveOutFromTop;
            alert.doneType = LDPMConfirmAlertAnimationMoveOutFromTop;
            alert.confirmButtonColor = [UIColor colorWithRGB:0xf16060];
            alert.dismissBlock = ^(LDPMEditableAlertView *alert, NSUInteger index) {
                if (index == 1) {
                    [LDPMUserEvent addEvent:EVENT_STOPPROFITLOSS tag:@"确定设置-确定"];
                    
                    PlaceLimitOrderParam *param = [PlaceLimitOrderParam new];
                    param.partnerId = weakSelf.partnerId;
                    param.wareId = weakSelf.product.wareId;
                    param.upPrice = weakSelf.stopProfitView.price < 0.01 ? @"0" : [NSString stringWithFormat:@"%.2f", weakSelf.stopProfitView.price];
                    param.downPrice = weakSelf.stopLossView.price < 0.01 ? @"0" : [NSString stringWithFormat:@"%.2f", weakSelf.stopLossView.price];
                    param.num = [NSString stringWithFormat:@"%d", weakSelf.numSetView.num];
                    
                    //下单入口事件统计
                    if ([weakSelf.partnerId isEqualToString:NPMPartnerIDNanJiaoSuo]) {
                        [LDPMUserEvent addEvent:EVENT_ORDER_ENTRANCE_NJS tag:@"止盈止损页"];
                    }
                    
                    [weakSelf.dataSorce requestPlaceLimitOrder:param];
                }
                [alert removeFromSuperview];
            };

            [alert show];

            return;
        }
    } else {
        NPMAlertView *alertView = [[NPMAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"StopLossProfit Operation Hint", @"您当前没有该商品的持仓，不能进行止盈止损操作") cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alertView show];
        return;
    }
}

- (BOOL)isPriceEnterCorrect: (NSString **)alertMessage               // 止盈止损输入判断
{
    BOOL isLossEnterRight = YES;
    BOOL isProfitEnterRight = YES;
    NSString *alertMessageLoss;
    NSString *alertMessageProfit;
    
    if ([self.product.buyOrSal isEqualToString:@"S"]) {// 持仓方向：卖出
        // 判断止损输入
        if (self.stopLossView.price > 0.01) {
            if (self.stopLossView.price > self.product.limitUp.doubleValue) {
                alertMessageLoss = [NSString stringWithFormat:@"止损触发价不能高于涨停价%@", self.product.limitUp];
                isLossEnterRight = NO;
            } else if (self.stopLossView.price <= self.product.currentPrice.doubleValue) {
                alertMessageLoss = [NSString stringWithFormat:@"止损触发价必须大于当前最新价"];
                isLossEnterRight = NO;
            }
        }
        
        if (self.stopProfitView.price > 0.01) {
            // 判断止盈输入
            if (self.stopProfitView.price >= self.product.currentPrice.doubleValue) {
                alertMessageProfit = @"止盈触发价必须小于当前最新价";
                isProfitEnterRight = NO;
            } else if (self.stopProfitView.price < self.product.limitDown.doubleValue) {
                alertMessageProfit = [NSString stringWithFormat:@"止盈触发价不能低于跌停价%@", self.product.limitDown];
                isProfitEnterRight = NO;
            }
        }
        
        if (!isProfitEnterRight && !isLossEnterRight) {
            alertMessageLoss = [NSString stringWithFormat:@"当持仓为卖出时，%@", alertMessageLoss];
            *alertMessage = [NSString stringWithFormat:@"%@，%@。", alertMessageLoss, alertMessageProfit];
        } else if (!isProfitEnterRight || !isLossEnterRight) {
            *alertMessage = [NSString stringWithFormat:@"当持仓为卖出时，%@。", (isLossEnterRight ? alertMessageProfit : alertMessageLoss)];
        } else {
            *alertMessage = @"";
        }
    } else {        // 持仓方向：买入
        if (self.stopLossView.price > 0.01) {
            if (self.stopLossView.price < self.product.limitDown.doubleValue) {
                alertMessageLoss = [NSString stringWithFormat:@"止损触发价不能低于跌停价%@", self.product.limitDown];
                isLossEnterRight = NO;
            } else if (self.stopLossView.price >= self.product.currentPrice.doubleValue) {
                alertMessageLoss = [NSString stringWithFormat:@"止损触发价必须小于当前最新价"];
                isLossEnterRight = NO;
            }
        }
        
        if (self.stopProfitView.price > 0.01) {
            // 判断止盈输入
            if (self.stopProfitView.price <= self.product.currentPrice.doubleValue) {
                alertMessageProfit = [NSString stringWithFormat:@"止盈触发价必须大于当前最新价"];
                isProfitEnterRight = NO;
            } else if (self.stopProfitView.price > self.product.limitUp.doubleValue) {
                alertMessageProfit = [NSString stringWithFormat:@"止盈触发价不能高于涨停价%@", self.product.limitUp];
                isProfitEnterRight = NO;
            }
        }
        
        if (!isProfitEnterRight && !isLossEnterRight) {
            alertMessageLoss = [NSString stringWithFormat:@"当持仓为买入时，%@", alertMessageLoss];
            *alertMessage = [NSString stringWithFormat:@"%@，%@。", alertMessageLoss, alertMessageProfit];
        } else if (!isLossEnterRight || !isProfitEnterRight) {
            *alertMessage = [NSString stringWithFormat:@"当持仓为买入时，%@", (isLossEnterRight ? alertMessageProfit : alertMessageLoss)];
        } else {
            *alertMessage = @"";
        }
    }
    
    if (!isLossEnterRight || !isProfitEnterRight) {
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)isAmountEnterCorrect:(NSString **)alertMessage
{
    if (self.numSetView.num > self.product.num.doubleValue) {
        *alertMessage = @"输入的数量不能大于最大执行数量；最大执行数量为持仓数量和反向委托单量的差值。";
        return NO;
    } else {
        return YES;
    }
}

#pragma mark - dataSource hostVC methods    TODO to change to delegate methods

- (void)refreshLimitData
{
    [self.dataSorce requestQueryLimit];
}

//查询接口错误弹窗

- (void)alertWithResponse:(NPMServiceResponse *)response
{
    __weak typeof(self) weakSelf = self;
    
    if (response.httpError && !weakSelf.isNeedNetErrorAlert) return;
    else if (response.httpError && weakSelf.isNeedNetErrorAlert) weakSelf.isNeedNetErrorAlert = NO;
    
    NPMAlertView *alert = [[NPMAlertView  alloc] initWithTitle:@"提示" message:response.errorMessage cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    alert.onDismissBlock = ^(NSInteger buttonIndex) {
        if (response.httpError) {
            weakSelf.isNeedNetErrorAlert = YES;
        }
    };
    [alert show];
}

- (void)showEmptyView:(BOOL)type
{
    if (type) {
        if (!self.emptyLabel || !self.emptyFooterView) {
            NSInteger viewHeight = self.view.height - self.tableHeaderView.height;
            self.emptyFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.size.width, MAX(viewHeight, kEmptyViewHeight))];
            [self.emptyFooterView setBackgroundColor:[UIColor whiteColor]];
            UIImageView *emptyImageView = [[UIImageView alloc] init];
            emptyImageView.contentMode = UIViewContentModeCenter;
            emptyImageView.image = [UIImage imageNamed:@"empty_list_back"];
            [self.emptyFooterView addSubview:emptyImageView];
            [emptyImageView autoAlignAxisToSuperviewAxis:ALAxisVertical];
            [emptyImageView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:40.];
            [emptyImageView autoSetDimension:ALDimensionWidth toSize:45];
            [emptyImageView autoSetDimension:ALDimensionHeight toSize:62];
            
            self.emptyLabel = [[UILabel alloc] init];
            [self.emptyLabel setTextAlignment:NSTextAlignmentCenter];
            [self.emptyLabel setTextColor:[NPMColor grayTextColor]];
            self.emptyLabel.font = [UIFont systemFontOfSize:12];
            [self.emptyFooterView addSubview:self.emptyLabel];
            [self.emptyLabel autoAlignAxisToSuperviewMarginAxis:ALAxisVertical];
            [self.emptyLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:emptyImageView withOffset:20];
            [self.emptyLabel autoSetDimension:ALDimensionHeight toSize:14];
        }
        
        self.emptyLabel.text = @"您当前暂无限价单";
        
        [self.tableView setTableFooterView:self.emptyFooterView];
    } else {
        [self.tableView setTableFooterView:nil];
    }
}

#pragma mark - stopProfitLossDelegate

- (void)dataHasLoaded:(NPMStopLossProfitDataSource *)dataSource
{
    [self.tableView reloadData];
    [self.tableView.mj_header endRefreshing];
}

- (void)submitOrderSuccessed:(NPMStopLossProfitDataSource *)datasource
{
    [self showOkToast:NSLocalizedString(@"StopLossProfit Order set Successfully", @"止盈止损单委托成功")];
    [self refreshLimitData];
}

@end
