#import <UIKit/UIKit.h>
#import "AopaImModels.h"

@interface MessageCell : UITableViewCell
- (void)configureWithMessage:(Message *)message isOutgoing:(BOOL)isOutgoing;

@end
