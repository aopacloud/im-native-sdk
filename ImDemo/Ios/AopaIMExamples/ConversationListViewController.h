#import <UIKit/UIKit.h>

@interface ConversationListViewController : UIViewController

@property (nonatomic, strong) NSString *localUserId;
@property (nonatomic, strong) NSString *appId;
@property (nonatomic, assign) NSInteger serverType;
@property (nonatomic, assign) NSInteger chatType;
@property (nonatomic, strong) NSString *remoteUserId; 
@property (nonatomic, strong) NSString *groupId; 

@end