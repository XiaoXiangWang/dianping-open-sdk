//
//  DPAPI.h
//  apidemo
//
//  Created by ZhouHui on 13-1-28.
//  Copyright (c) 2013年 Dianping. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QDDianPingRequest.h"




@interface QDDianPingAPI : NSObject

+ (QDDianPingRequest*)QDDianPingRequestWithURL:(NSString *)url
                              params:(NSDictionary *)params
                               completionBlock:(QDDianPingRequestCompletionBlock)completionBlock
                                  failureBlock:(QDDianPingRequestFailureBlock)failureBlock;

+ (QDDianPingRequest *)QDDianPingRequestWithURL:(NSString *)url
                                    queryString:(NSString *)queryString
                                completionBlock:(QDDianPingRequestCompletionBlock)completionBlock
                                   failureBlock:(QDDianPingRequestFailureBlock)failureBlock;;
@end