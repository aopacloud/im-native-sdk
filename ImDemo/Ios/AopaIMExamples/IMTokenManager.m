#import "IMTokenManager.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation IMTokenManager

+ (NSString *)getHostAndPort:(NSString *)url {
    if (url.length == 0) {
        return @"";
    }
    
    NSError *error = nil;
    NSString *pattern = @"^(ws://|wss://|http://|https://)([^/]+)";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                         options:0
                                                                           error:&error];
    if (error) {
        NSLog(@"Error creating regex: %@", error);
        return @"";
    }
    
    NSTextCheckingResult *match = [regex firstMatchInString:url
                                                   options:0
                                                     range:NSMakeRange(0, url.length)];
    if (match && match.numberOfRanges > 2) {
        return [url substringWithRange:[match rangeAtIndex:2]];
    }
    
    return @"";
}

+ (NSString *)getToken:(NSString *)userId wsUrl:(NSString *)wsUrl {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSString *resultToken = @"";
    
    // 获取主机和端口
    NSString *hostAndPort = [self getHostAndPort:wsUrl];
    if (hostAndPort.length == 0) {
        return @"";
    }
    
    // 构建完整的URL
    NSString *httpProtocol = [wsUrl hasPrefix:@"wss://"] || [wsUrl hasPrefix:@"https://"] ? 
                            @"https://" : @"http://";
    NSString *urlString = [NSString stringWithFormat:@"%@%@/imapi/user/add", httpProtocol, hostAndPort];
    NSURL *url = [NSURL URLWithString:urlString];
    
    // 构建请求参数
    NSString *postData = [NSString stringWithFormat:@"userId=%@&name=yangjunios&portraitUri=%@&appId=66",
                         userId,
                         @"http://xs-image.im-ee.com/202303/27/816221207_64213beec639c0.97786485.jpg"];
    
    // 创建请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    request.HTTPBody = [postData dataUsingEncoding:NSUTF8StringEncoding];
    
    // 使用 NSURLSession 发送请求
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request 
                                           completionHandler:^(NSData *data, 
                                                             NSURLResponse *response, 
                                                             NSError *error) {
        if (!error && data) {
            NSError *jsonError = nil;
            NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data
                                                                       options:0
                                                                         error:&jsonError];
            if (!jsonError && jsonResponse[@"token"]) {
                resultToken = jsonResponse[@"token"];
            }
        }
        dispatch_semaphore_signal(semaphore);
    }];
    
    [task resume];
    
    // 等待请求完成
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC));
    
    return resultToken;
}


+ (void)getTokenTestEnv:(NSString *)userId 
              serverUrl:(NSString *)serverUrl 
              delegate:(id<IMTokenManagerDelegate>)delegate {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *token = [self getToken:userId wsUrl:serverUrl];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (token.length > 0) {
                [delegate onTokenSuccess:token];
            } else {
                [delegate onTokenError:@"Empty token received"];
            }
        });
    });
}


+ (void)getTokenEnvFormat:(NSString *)appId 
                  userId:(NSString *)userId 
               serverUrl:(NSString *)serverUrl 
             redirectUrl:(NSString *)redirectUrl 
               delegate:(id<IMTokenManagerDelegate>)delegate {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @try {
            // 1. 生成随机字符串
            NSString *randomStr = [self generateRandomString:16];
            NSLog(@"Random string: %@", randomStr);

            // 2. 加密数据
            NSString *encryptedText = [self encryptData:@"Hello, World!" randomStr:randomStr];
            NSLog(@"Encrypted text: %@", encryptedText);

            // 3. 构建请求
            NSURL *url = [NSURL URLWithString:serverUrl];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
            request.HTTPMethod = @"POST";
            [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
            request.timeoutInterval = 15.0;

            // 4. 构建请求参数
            NSString *postData = [NSString stringWithFormat:@"im_secret_public=%@&im_random_iv=%@&im_request_address=%@&userId=%@&name=%@&portraitUri=%@&appId=%@",
                                [encryptedText stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]],
                                [randomStr stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]],
                                [redirectUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]],
                                [userId stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]],
                                [@"yangjun1" stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]],
                                [@"https://rtc-resouce.oss-ap-southeast-1.aliyuncs.com/github_pic/11.png" stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]],
                                [appId stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];

            NSLog(@"Request data: %@", postData);
            request.HTTPBody = [postData dataUsingEncoding:NSUTF8StringEncoding];

            // 5. 发送请求
            NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
            config.timeoutIntervalForRequest = 15.0;
            config.timeoutIntervalForResource = 15.0;
            
            NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
            NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                                  completionHandler:^(NSData *data,
                                                                    NSURLResponse *response,
                                                                    NSError *error) {
                if (error) {
                    NSLog(@"Error getting token: %@", error);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [delegate onTokenError:error.localizedDescription];
                    });
                    return;
                }

                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                NSLog(@"Response code: %ld", (long)httpResponse.statusCode);

                if (httpResponse.statusCode == 200) {
                    if (!data) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [delegate onTokenError:@"Empty response data"];
                        });
                        return;
                    }

                    NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    NSLog(@"Response: %@", responseString);

                    NSError *jsonError;
                    NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data
                                                                              options:0
                                                                                error:&jsonError];
                    if (jsonError) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [delegate onTokenError:@"JSON parsing error"];
                        });
                        return;
                    }

                    NSString *token = jsonResponse[@"token"];
                    if (token && token.length > 0) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [delegate onTokenSuccess:token];
                        });
                    } else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [delegate onTokenError:@"Empty token received"];
                        });
                    }
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [delegate onTokenError:[NSString stringWithFormat:@"Server returned code: %ld", (long)httpResponse.statusCode]];
                    });
                }
            }];

            [task resume];

        } @catch (NSException *exception) {
            NSLog(@"Error getting token: %@", exception);
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate onTokenError:exception.description];
            });
        }
    });
}

// 修改 encryptData 方法
+ (NSString *)encryptData:(NSString *)plainText randomStr:(NSString *)randomStr {
    NSData *keyData = [@"my32lengthsupersecretnooneknows1" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *ivData = [randomStr dataUsingEncoding:NSUTF8StringEncoding];
    NSData *dataToEncrypt = [plainText dataUsingEncoding:NSUTF8StringEncoding];
    
    // 实现 CTR 模式
    NSMutableData *counter = [NSMutableData dataWithData:ivData];
    NSMutableData *keyStream = [NSMutableData data];
    NSMutableData *encryptedData = [NSMutableData data];
    
    // 创建加密缓冲区
    size_t bufferSize = 16; // AES block size
    void *buffer = malloc(bufferSize);
    
    // 生成密钥流
    for (NSUInteger i = 0; i < (dataToEncrypt.length + 15) / 16; i++) {
        size_t numBytesEncrypted = 0;
        
        // 加密计数器
        CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                            kCCAlgorithmAES,
                                            kCCOptionECBMode,  // 使用 ECB 模式加密计数器
                                            keyData.bytes,
                                            kCCKeySizeAES256,
                                            NULL,             // ECB 模式不需要 IV
                                            counter.bytes,
                                            16,              // 一个块的大小
                                            buffer,
                                            bufferSize,
                                            &numBytesEncrypted);
        
        if (cryptStatus != kCCSuccess) {
            free(buffer);
            return @"";
        }
        
        // 添加到密钥流
        [keyStream appendBytes:buffer length:numBytesEncrypted];
        
        // 增加计数器
        uint8_t *counterBytes = (uint8_t *)counter.mutableBytes;
        for (int j = 15; j >= 0; j--) {
            if (++counterBytes[j] != 0) {
                break;
            }
        }
    }
    
    free(buffer);
    
    // 执行 XOR 操作
    uint8_t *keyStreamBytes = (uint8_t *)keyStream.bytes;
    uint8_t *plaintextBytes = (uint8_t *)dataToEncrypt.bytes;
    
    for (NSUInteger i = 0; i < dataToEncrypt.length; i++) {
        uint8_t encryptedByte = plaintextBytes[i] ^ keyStreamBytes[i];
        [encryptedData appendBytes:&encryptedByte length:1];
    }
    
    // Base64 编码
    return [encryptedData base64EncodedStringWithOptions:0];
}

+ (NSString *)generateRandomString:(NSInteger)length {
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity:length];
    
    for (int i = 0; i < length; i++) {
        uint32_t rand = arc4random_uniform((uint32_t)letters.length);
        unichar c = [letters characterAtIndex:rand];
        [randomString appendFormat:@"%C", c];
    }
    
    return randomString;
}


@end
