#import <UIKit/UIKit.h>
#import "IMTokenManager.h"
@interface LoginViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource>

@property (weak, nonatomic) IBOutlet UITextField *localUserIdField;
@property (weak, nonatomic) IBOutlet UITextField *remoteUserIdField;
@property (weak, nonatomic) IBOutlet UITextField *appIdField;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *logoutButton;

@property (weak, nonatomic) IBOutlet UITextField *chatTypeField;
@property (weak, nonatomic) IBOutlet UITextField *serverTypeField;
@end