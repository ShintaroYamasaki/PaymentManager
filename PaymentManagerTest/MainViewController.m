//
//  MainViewController.m
//  PaymentManagerTest
//
//  Created by user on 2014/10/29.
//  Copyright (c) 2014年 yamasaki. All rights reserved.
//

#import "MainViewController.h"

@implementation MainViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    // プロダクト管理クラスの設定
    _productManager = [ProductManager sharedInstance];
    
    // iAdバナーの設定
    _adBannerView.delegate = self;
    
    // アプリ内課金マネージャーの設定
    _paymentManager = [PaymentManager sharedInstance];  // 複数のクラスで単一のインスタンスを扱うことをできるようにsharedInstanceで初期化
    _paymentManager.delegate = self;  // PaymentManagerDelegateを設定

    // プロダクト情報の取得
    [_paymentManager requestProductInfo:_productManager.productIds];
    [self setAlertViewWithTitle:@"処理中" Message:@"プロダクト情報を取得中です" CancelButtonTitle:nil];
    [_alertView show];
    
    // テーブルビューの設定
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    [self reflectBought];
}


/** リストアボタン押下処理 */
- (IBAction)onRestoreButton:(id)sender {
    if ([_paymentManager startRestore]) {
        [self setAlertViewWithTitle:@"処理中" Message:@"リストア中です" CancelButtonTitle:nil];
        [_alertView show];
    };
}
/** 再表示ボタン押下処理 */
- (IBAction)onReload:(id)sender {
    [self reflectBought];
}

/** アラートのパラメータ設定 */
- (void) setAlertViewWithTitle: (NSString *) title Message: (NSString *) message CancelButtonTitle: (NSString *) cancel {
    _alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:cancel otherButtonTitles:nil];
}

/** 
 プロダクト名の取得 
 自動更新購読型の場合、ひとつの製品に複数の期間を設定できるため、
 IDごとに期間を明示する必要がある
 */
- (NSString *) productName: (SKProduct *) product {
    if ([product.productIdentifier isEqual:kProductShowText7days]) {
        return [product.localizedTitle stringByAppendingString:@" (7日間)"];
    } else if ([product.productIdentifier isEqual:kProductShowText1month]) {
        return [product.localizedTitle stringByAppendingString:@" (1ヶ月)"];
    } else {
        return product.localizedTitle;
    }
}

/** 購入したプロダクトを画面に反映させる */
- (void) reflectBought{
    [_adBannerView setHidden: _productManager.isRemoveAd];
    pointLabel.text = [[NSNumber numberWithInteger:_productManager.points] stringValue];
    if ([_productManager getIsText]) {
        [textLabel setHidden:NO];
    } else {
        // 期限切れならレシートの更新
        // 自動更新された場合、Appleサーバー側のレシートは更新されるが、
        // ローカル側のレシートは古いままなので、ローカル側のレシートを更新する
        [_paymentManager refreshReceipt];
    }
}

- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

// App内課金のデリゲート -----------------------------------------------------------------------
#pragma mark - PaymentManagerDelegate
- (void) completePayment:(SKPaymentTransaction *)transaction {
    // 購入状況の更新
    [_productManager bought:transaction.payment.productIdentifier];
    // 画面への反映
    [self reflectBought];
}

- (void) responseProductInfo:(NSArray *)products InvalidProducts:(NSArray *)invalidProducts {
    [_alertView dismissWithClickedButtonIndex:0 animated:YES];
    _alertView = nil;

    
    _products = products;
    // テーブルビューに表示
    [_tableView reloadData];
}

- (void) onPaymentStatus:(PaymentStatus)status {

    [_alertView dismissWithClickedButtonIndex:0 animated:YES];
    _alertView = nil;
    
    NSString *statusText;
    
    switch (status) {
        case PaymentStatusPurchasing:
            statusText = @"PaymentStatusPurchasing";
            break;
        case PaymentStatusPurchased:
            statusText = @"PaymentStatusPurchased";
            break;
        case PaymentStatusRestored:
            statusText = @"PaymentStatusRestored";
            break;
        case PaymentStatusFailed:
            statusText = @"PaymentStatusFailed";
            break;
        case PaymentStatusReceiptRefleshing:
            statusText = @"PaymentStatusReceiptRefleshing";
            break;
        case PaymentStatusReceiptRefleshed:
            statusText = @"PaymentStatusReceiptRefleshed";
            // 購読型コンテンツ表示更新
            [textLabel setHidden:![_productManager getIsText]];
            break;
        default:
            break;
    }
    
    // ステータス表示
    NSLog(@"%@", statusText);
    
}

- (void) onPaymentError:(PaymentError)error {
    NSString *errorText;
    
    switch (error) {
        case PaymentErrorNotAllowed:
            errorText = @"アプリ内課金が許可されていません";
            break;
        case PaymentErrorCancelled:
            errorText = @"キャンセルされました";
            break;
        case PaymentErrorClientInvalid:
            errorText = @"許可されていない処理を行おうとしました";
            break;
        case PaymentErrorInvalid:
            errorText = @"リクエストが不正です";
            break;
        case PaymentErrorResponsedProductInfo:
            errorText = @"プロダクト情報の取得に失敗しました";
            break;
        case PaymentErrorUnknown:
            errorText = @"不明なエラー";
            break;
        case PaymentErrorFailedRestore:
            errorText = @"リストアに失敗しました";
            break;
        default:
            break;
    }
    // エラー表示
    NSLog(@"%@", errorText);
    
    [self setAlertViewWithTitle:nil Message:errorText CancelButtonTitle:@"OK"];
    [_alertView show];
}


// 広告表示 ------------------------------------------------------
#pragma mark - ADBannerViewDelegate
- (void)bannerViewDidLoadAd:(ADBannerView *)banner {
    if (!_bannerVisible) {
        [UIView animateWithDuration:0.3f animations:^{
            banner.alpha = 1.0f;
        }];
        _bannerVisible = YES;
    }
}

-(void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
    if (_bannerVisible) {
        [UIView animateWithDuration:0.3f animations:^{
            banner.alpha = 0.0f;
        }];
        _bannerVisible = NO;
    }
}


// テーブル関連 ----------------------------------------------------------
#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_products count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if ( nil == cell ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:identifier];
    }
    
    // 製品名表示 -------------------------------------------------------------------
    SKProduct *product = [_products objectAtIndex:indexPath.row];
    cell.textLabel.text = [self productName:product];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", product.price];
    // ----------------------------------------------------------------------------
    
    return cell;
}

#pragma mark - UITableViewDelegate
// テーブルのセルをタップした時
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // 保持していたプロダクトのリストから該当のプロダクトを取り出す
    SKProduct *product = [_products objectAtIndex:indexPath.row];
    
    // 購入処理中にUIAlertViewを表示させる
    [self setAlertViewWithTitle:@"処理中" Message:[NSString stringWithFormat:@"%@の購入処理中です", product.localizedTitle] CancelButtonTitle:nil];
    [_alertView show];
    
    // プロダクトの購入処理を開始させる
    [_paymentManager buyProduct:product];
    
}

@end
