#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "AopaImModels.h"
#import "AopaImKit.h"

@class MessageContent;
@interface ChatViewController : UIViewController

@property (nonatomic, strong) NSString *localUserId;
@property (nonatomic, strong) NSString *remoteUserId;
@property (nonatomic, assign) NSInteger chatType;
@property (nonatomic, assign) NSInteger serverType;
@property (nonatomic, assign) NSInteger appId;
@property (nonatomic, strong) NSString *groupId; 

// Storyboard Outlets
@property (weak, nonatomic) IBOutlet UITableView *messageTableView;
@property (weak, nonatomic) IBOutlet UITextField *messageInput;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
@property (weak, nonatomic) IBOutlet UIButton *imageButton;
@property (weak, nonatomic) IBOutlet UIButton *audioButton;
@property (weak, nonatomic) IBOutlet UIView *inputToolbar;

@property (nonatomic, assign) BOOL isPlaying;
@end
