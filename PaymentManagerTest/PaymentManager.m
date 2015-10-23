//
//  PaymentManager.m
//  PaymentManagerTest
//
//  Created by user on 2014/10/29.
//  Copyright (c) 2014年 yamasaki. All rights reserved.
//

#import "PaymentManager.h"

#define kIsRemainTransaction  @"IsRemainTransaction"

@implementation PaymentManager

+ (PaymentManager *)sharedInstance {
    static PaymentManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[PaymentManager alloc] init];
    });
    return _sharedInstance;
}

- (id) init {
    if (self = [super init]) {
        // オブザーバの登録
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

- (SKProductsRequest *)requestProductInfo: (NSSet *) productIds {
    SKProductsRequest *productRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIds];
    productRequest.delegate = self;
    [productRequest start];
    
    return productRequest;
}

/** 
 アプリ内課金が許可されているか判定
    端末の機能制限でアプリ内課金が許可されていればアプリ内課金を利用出来る
 */
- (BOOL) checkCanMakePayments {
    if ([SKPaymentQueue canMakePayments]) {
        return YES;
    } else {
        [_delegate onPaymentStatus:PaymentStatusFailed];
        [_delegate onPaymentError:PaymentErrorNotAllowed];
        return NO;
    }
}

- (BOOL) buyProduct: (SKProduct *) product {
    // 初めにアプリ内課金が許可されているかどうか確かめる
    if ([self checkCanMakePayments]) {
        // 購入処理開始
        SKPayment *payment = [SKPayment paymentWithProduct:product];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
        
        return YES;
    };
    
    return NO;
}

- (BOOL) buyProduct: (SKProduct *) product WithQuantity:(NSInteger)quantity {
    // 初めにアプリ内課金が許可されているかどうか確かめる
    if ([self checkCanMakePayments]) {
        // 購入処理開始
        SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
        payment.quantity = quantity;
        [[SKPaymentQueue defaultQueue] addPayment:payment];
        
        return YES;
    };
    
    return NO;
}

- (BOOL) startRestore {
    // 初めにアプリ内課金が許可されているかどうか確かめる
    if ([self checkCanMakePayments]) {
        // リストアの開始
        [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
        return YES;
    };
    
    return NO;
}

/**
 購入処理中にエラーが発生したとき、エラーを通知する
 */
- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    
    switch (transaction.error.code) {
        case SKErrorPaymentCancelled:
            [_delegate onPaymentError:PaymentErrorCancelled];
            break;
            
        case SKErrorUnknown:
            [_delegate onPaymentError:PaymentErrorUnknown];
            break;
            
        case SKErrorClientInvalid:
            [_delegate onPaymentError:PaymentErrorClientInvalid];
            break;
            
        case SKErrorPaymentInvalid:
            [_delegate onPaymentError:PaymentErrorInvalid];
            break;
            
        case SKErrorPaymentNotAllowed:
            [_delegate onPaymentError:PaymentErrorNotAllowed];
            break;
            
        default:
            break;
    }
    
    // トランザクションを終了する
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

#pragma mark - SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    [_delegate responseProductInfo:response.products InvalidProducts:response.invalidProductIdentifiers];
}

#pragma mark - SKRequestDelegate
- (void)requestDidFinish:(SKRequest *)request {
    [_delegate onPaymentStatus:PaymentStatusResponsedProductInfo];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    [_delegate onPaymentError:PaymentErrorResponsedProductInfo];
}

#pragma mark - SKPaymentTransactionObserver Required Methods
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing:
                [_delegate onPaymentStatus:PaymentStatusPurchasing];
                // トランザクションが開始されたことを記憶しておく
                @synchronized(self) {
                    [[NSUserDefaults standardUserDefaults] setBool:YES
                                                            forKey:kIsRemainTransaction];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
                break;
                
            case SKPaymentTransactionStatePurchased:
                [_delegate onPaymentStatus:PaymentStatusPurchased];
                [_delegate completePayment:transaction];
                // トランザクションを終了する
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateFailed:
                [_delegate onPaymentStatus:PaymentStatusFailed];
                [self failedTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateRestored:
                [_delegate onPaymentStatus:PaymentStatusPurchased];
                [_delegate completePayment:transaction];
                // トランザクションを終了する
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
                
            default:
                break;
        }
    }
}

#pragma mark - SKPaymentTransactionObserver Optional Methods

// トランザクションがfinishTransaction経由でキューから削除されたときに送信されます。
- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions {
    // トランザクションが終了したことを記憶しておく
    @synchronized(self) {
        [[NSUserDefaults standardUserDefaults] setBool:NO
                                                forKey:kIsRemainTransaction];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    // リストアの失敗
    [_delegate onPaymentStatus:PaymentStatusFailed];
    [_delegate onPaymentError:PaymentErrorFailedRestore];
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    // リストアの完了
    [_delegate onPaymentStatus:PaymentStatusRestored];
}



@end
