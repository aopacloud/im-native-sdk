#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol IMTokenManagerDelegate <NSObject>
- (void)onTokenSuccess:(NSString *)token;
- (void)onTokenError:(NSString *)error;
@end

@interface IMTokenManager : NSObject

+ (NSString *)getHostAndPort:(NSString *)url;
+ (NSString *)getToken:(NSString *)userId wsUrl:(NSString *)wsUrl;
+ (void)getTokenTestEnv:(NSString *)userId 
              serverUrl:(NSString *)serverUrl 
              delegate:(id<IMTokenManagerDelegate>)delegate;
+ (void)getTokenEnvFormat:(NSString *)appId 
         userId:(NSString *)userId 
      serverUrl:(NSString *)serverUrl 
    redirectUrl:(NSString *)redirectUrl 
      delegate:(id<IMTokenManagerDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END