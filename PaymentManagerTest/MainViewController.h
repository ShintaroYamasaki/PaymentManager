//
//  MainViewController.h
//  PaymentManagerTest
//
//  Created by user on 2014/10/29.
//  Copyright (c) 2014年 yamasaki. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iAd/iAd.h>

#import "PaymentManager.h"
#import "ProductManager.h"

@interface MainViewController : UIViewController <ADBannerViewDelegate, UITableViewDelegate, UITableViewDataSource, PaymentManagerDelegate>{
    /** iAdバナー */
    IBOutlet ADBannerView *_adBannerView;
    /** iAdバナーの表示/非表示 */
    BOOL _bannerVisible;
    
    /** テーブルビュー */
    IBOutlet UITableView *_tableView;

    /** ポイント表示 */
    IBOutlet UILabel *pointLabel;
    
    /** 購読型テキスト */
    IBOutlet UILabel *textLabel;
    
    /** アプリ内課金マネージャー */
    PaymentManager *_paymentManager;
    
    /** アラートビュー */
    UIAlertView *_alertView;
    
    /** 購入可能なプロダクト一覧 */
    NSArray *_products;

    /** プロダクト管理クラス */
    ProductManager *_productManager;
}

@end
