//
//  PaymentManager.m
//  PaymentManagerTest
//
//  Created by user on 2014/10/29.
//  Copyright (c) 2014年 yamasaki. All rights reserved.
//

#import "PaymentManager.h"

#define kIsRemainTransaction  @"IsRemainTransaction"

// 自動更新（Auto-Renewable）プロダクト用の共有シークレット
// 本来はこのようにソースコードに直接、値を書くべきではない
#define kSharedSecret @"2444cdeeb8f641b6a14b262f83384513"

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
 購入完了した際の処理
 */
- (void)completedTransaction:(SKPaymentTransaction *)transaction {
    
    // 完了の旨を通知
    [_delegate completePayment:transaction];
    // トランザクションを終了する
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
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

- (NSTimeInterval) checkReceipt: (NSString *) productId {
    // レシートデータ取得
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    
    BOOL result = verifyReceiptAtPath([receiptURL path], [[NSBundle mainBundle] bundleIdentifier]);
    if (result == YES) {
        NSDictionary *dict = dictionaryWithAppStoreReceipt([receiptURL path]);
//        NSLog(@"%@", dict);
        
        // InApp配列をまわして、最大の有効期限値を取得する
        NSArray *inAppArray = [dict objectForKey:@"InApp"];
        NSTimeInterval expires = 0.0;
        for (NSDictionary *inApp in inAppArray) {
            NSString *expiresDate = [inApp objectForKey:@"SubExpDate"];
            if ([[inApp objectForKey:@"ProductIdentifier"] hasPrefix:productId]) {
                NSTimeInterval e = [self dateFromRFC3339String:expiresDate];
                if (expires < e) {
                    expires = e;
                }
            }
        }
        
        return expires;
    }
    
    return 0.0;
}

- (void) refreshReceipt {
    receiptRequest = [[SKReceiptRefreshRequest alloc] init];
    receiptRequest.delegate = self;
    // レシート再取得
    [receiptRequest start];
    [_delegate onPaymentStatus:PaymentStatusReceiptRefleshing];
}

- (NSTimeInterval)dateFromRFC3339String:(NSString *)dateString {
    // Create date formatter
    static NSDateFormatter *dateFormatter = nil;
    if (!dateFormatter) {
        NSLocale *en_US_POSIX = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:en_US_POSIX];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    }
    
    // Process date
    NSDate *date = nil;
    NSString *RFC3339String = [[NSString stringWithString:dateString] uppercaseString];
    RFC3339String = [RFC3339String stringByReplacingOccurrencesOfString:@"Z" withString:@"-0000"];
    // Remove colon in timezone as iOS 4+ NSDateFormatter breaks. See https://devforums.apple.com/thread/45837
    if (RFC3339String.length > 20) {
        RFC3339String = [RFC3339String stringByReplacingOccurrencesOfString:@":"
                                                                 withString:@""
                                                                    options:0
                                                                      range:NSMakeRange(20, RFC3339String.length - 20)];
    }
    if (!date) { // 1996-12-19T16:39:57-0800
        [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZ"];
        date = [dateFormatter dateFromString:RFC3339String];
    }
    if (!date) { // 1937-01-01T12:00:27.87+0020
        [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSZZZ"];
        date = [dateFormatter dateFromString:RFC3339String];
    }
    if (!date) { // 1937-01-01T12:00:27
        [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss"];
        date = [dateFormatter dateFromString:RFC3339String];
    }
    if (!date) {
        NSLog(@"Could not parse RFC3339 date: \"%@\" Possibly invalid format.", dateString);
    }
    NSTimeInterval expires = [date timeIntervalSince1970];
    
    return expires;
}

#pragma mark - SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    [_delegate responseProductInfo:response.products InvalidProducts:response.invalidProductIdentifiers];
}

#pragma mark - SKRequestDelegate
- (void)requestDidFinish:(SKRequest *)request {
    if (request == receiptRequest) {
        [_delegate onPaymentStatus:PaymentStatusReceiptRefleshed];
    } else {
    }
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
                [self completedTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateFailed:
                [_delegate onPaymentStatus:PaymentStatusFailed];
                [self failedTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateRestored:
                [_delegate onPaymentStatus:PaymentStatusPurchased];
                [self completedTransaction:transaction];
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
