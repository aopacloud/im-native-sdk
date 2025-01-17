#import "LoginViewController.h"
#import "ChatViewController.h"
#import "ConversationListViewController.h"

@interface LoginViewController ()
@property (nonatomic, assign) BOOL isLoggedIn;
@property (nonatomic, strong) UIPickerView *chatTypePicker;
@property (nonatomic, strong) UIPickerView *serverTypePicker;
@property (nonatomic, strong) NSArray *chatTypes;
@property (nonatomic, strong) NSArray *serverTypes;
@property (nonatomic, assign) NSInteger selectedChatType;
@property (nonatomic, assign) NSInteger selectedServerType;
@property (nonatomic, copy) NSString *publicPath; 
@property (nonatomic, strong) NSString *groupId; 
@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupPickers];
    [self setupInitialValues];
    [self setupUI];

    NSString *savedPath = [[NSUserDefaults standardUserDefaults] objectForKey:@"AopaImSdk"];
    if (savedPath) {
        self.publicPath = savedPath;
    } else {
        self.publicPath = [self setupPublicPath];
    }
}

- (void)setupPickers {
    self.chatTypes = @[@"未定义",@"私聊", @"群聊", @"聊天室"];
    self.serverTypes = @[@"测试国内",@"正式国内",  @"测试海外",@"正式海外"];
    
    // 创建 Picker
    self.chatTypePicker = [[UIPickerView alloc] init];
    self.serverTypePicker = [[UIPickerView alloc] init];
    
    // 设置代理
    self.chatTypePicker.delegate = self;
    self.chatTypePicker.dataSource = self;
    self.serverTypePicker.delegate = self;
    self.serverTypePicker.dataSource = self;
    
    // 设置输入视图
    self.chatTypeField.inputView = self.chatTypePicker;
    self.serverTypeField.inputView = self.serverTypePicker;
    
    // 禁用编辑
    self.chatTypeField.enabled = YES;
    self.serverTypeField.enabled = YES;
    self.chatTypeField.userInteractionEnabled = YES;
    self.serverTypeField.userInteractionEnabled = YES;
    
    // 创建工具栏
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"完成" 
                                                                  style:UIBarButtonItemStyleDone 
                                                                 target:self 
                                                                 action:@selector(dismissPicker)];
    toolbar.items = @[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
                                                                  target:nil 
                                                                  action:nil],
                     doneButton];
    
    self.chatTypeField.inputAccessoryView = toolbar;
    self.serverTypeField.inputAccessoryView = toolbar;
}

- (void)dismissPicker {
    [self.view endEditing:YES];
}


- (NSString *)setupPublicPath {
    // 获取 Documents 目录
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths firstObject];
    
    // 创建一个子目录（可选）
    NSString *storagePath = [documentsPath stringByAppendingPathComponent:@"AopaImSdk"];
    
    // 检查目录是否存在，如果不存在则创建
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:storagePath]) {
        NSError *error = nil;
        [fileManager createDirectoryAtPath:storagePath
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:&error];
        if (error) {
            NSLog(@"创建目录失败: %@", error);
            return nil;
        }
    }
    
    return storagePath;
}

// 7. 添加路径检查方法
- (BOOL)isValidStoragePath:(NSString *)path {
    if (!path) return NO;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory = NO;
    BOOL exists = [fileManager fileExistsAtPath:path isDirectory:&isDirectory];
    
    return exists && isDirectory;
}


// 获取设备和应用的 UUID（如果需要）
- (NSString *)getDeviceUUID {
    NSString *devicePath = [NSHomeDirectory() stringByDeletingLastPathComponent];
    devicePath = [devicePath stringByDeletingLastPathComponent];
    devicePath = [devicePath stringByDeletingLastPathComponent];
    return [devicePath lastPathComponent];
}

- (NSString *)getApplicationUUID {
    NSString *appPath = NSHomeDirectory();
    return [appPath lastPathComponent];
}



- (void)setupUI {
    // 设置按钮样式
    self.loginButton.layer.cornerRadius = 5;
    self.logoutButton.layer.cornerRadius = 5;
    
    // 设置输入框样式
    self.localUserIdField.borderStyle = UITextBorderStyleRoundedRect;
    self.remoteUserIdField.borderStyle = UITextBorderStyleRoundedRect;
    self.appIdField.borderStyle = UITextBorderStyleRoundedRect;
    
    // 设置键盘类型
    self.localUserIdField.keyboardType = UIKeyboardTypeNumberPad;
    self.remoteUserIdField.keyboardType = UIKeyboardTypeNumberPad;
    self.appIdField.keyboardType = UIKeyboardTypeNumberPad;

    self.chatTypeField.borderStyle = UITextBorderStyleRoundedRect;
    self.serverTypeField.borderStyle = UITextBorderStyleRoundedRect;
    
    // 禁用键盘
    self.chatTypeField.inputView = self.chatTypePicker;
    self.serverTypeField.inputView = self.serverTypePicker;
    
    // 更新按钮状态
    [self updateButtonStates];
}

- (void)setupInitialValues {
    // 设置初始值
    self.localUserIdField.text = @"1234562";
    self.remoteUserIdField.text = @"1234561";
    self.appIdField.text = @"66";
    self.groupId =@"1234567865";
    
    // 设置默认选中的行
    [self.chatTypePicker selectRow:1 inComponent:0 animated:NO];
    [self.serverTypePicker selectRow:1 inComponent:0 animated:NO];
    
    // 手动触发选择事件来更新文本
    [self pickerView:self.chatTypePicker didSelectRow:1 inComponent:0];
    [self pickerView:self.serverTypePicker didSelectRow:1 inComponent:0];
    
    // 保存选中的索引
    self.selectedChatType = 1;
    self.selectedServerType = 1;
}

#pragma mark - UIPickerViewDelegate & DataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (pickerView == self.chatTypePicker) {
        return self.chatTypes.count;
    } else {
        return self.serverTypes.count;
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (pickerView == self.chatTypePicker) {
        return self.chatTypes[row];
    } else {
        return self.serverTypes[row];
    }
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (pickerView == self.chatTypePicker) {
        self.chatTypeField.text = self.chatTypes[row];
        self.selectedChatType = row;
    } else {
        self.serverTypeField.text = self.serverTypes[row];
        self.selectedServerType = row;
    }
}


#pragma mark - Actions

- (IBAction)onClickLogin:(id)sender {
     if (!self.publicPath) {
        [self showAlert:@"错误" message:@"无法创建存储路径"];
        return;
    }
    
    // 根据选择的服务器类型设置服务器URL
    NSString *serverUrl;
    switch(self.selectedServerType) {
        case 0: // 测试国内 
            serverUrl = @"ws://115.29.215.193:6080/imgate/ws/connect";
            break;
        case 1: // 正式国内 
            serverUrl = @"wss://im-gate.aopacloud.net:6511/ws/connect";
            break;
        case 2: // 测试海外
            serverUrl = @"ws://115.29.215.193:6080/imgate/ws/connect";
            break;
        case 3: // 正式海外
            serverUrl = @"ws://115.29.215.193:6080/imgate/ws/connect";
            break;
        default:
            serverUrl = @"ws://115.29.215.193:6080/imgate/ws/connect";
            break;
    }


    [AopaImEngineKit setRtcServerAddress:serverUrl domain:@""];

    [[AopaImEngineKit sharedInstance] initialize:66 
                                    packageName:@"sleepless"
                                    pushVendor:@""
                                    pushToken:@""
                                    publicStoragePath:self.publicPath
                                    chatType:self.selectedChatType]; 
    [[AopaImMediaKit sharedInstance] initialize:self.publicPath];
    
     // 将文本转换为 uint32_t
    uint32_t uid = (uint32_t)[self.localUserIdField.text integerValue];
    if(uid < 100000){
         [self showAlert:@"错误" message:@"登录不能少于6位数"];
    }
    
    switch(self.selectedServerType) {
        case 0: { // 测试国内
            [IMTokenManager getTokenTestEnv:self.localUserIdField.text 
                                serverUrl:@"ws://115.29.215.193:6080/imgate/ws/connect"
                                delegate:self];
            break;
        }
        case 1: { // 正式国内
            [IMTokenManager getTokenEnvFormat:@"66"
                            userId:self.localUserIdField.text
                         serverUrl:@"https://im-publish.aopacloud.net/"
                       redirectUrl:@"http://im.aopacloud-cn.private"
                         delegate:self];
             NSLog(@"onTokenSuccess: 000 failed");
            break;
        }
    }
}

// 添加 prepareForSegue 方法
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showConversationList"]) {
        UINavigationController *navController = segue.destinationViewController;
        ConversationListViewController *conversationListVC = (ConversationListViewController *)navController.topViewController;
        conversationListVC.localUserId = self.localUserIdField.text;
        conversationListVC.remoteUserId = self.remoteUserIdField.text;
        conversationListVC.appId = self.appIdField.text;
        conversationListVC.serverType = self.selectedServerType;
        conversationListVC.groupId= self.groupId;
        conversationListVC.chatType = self.selectedChatType;
    }
}

- (IBAction)onClickLogout:(id)sender {
    self.isLoggedIn = NO;
    [self updateButtonStates];
    [self showAlert:@"提示" message:@"已登出"];

    [[AopaImEngineKit sharedInstance] logout];
}

- (void)updateButtonStates {
    self.loginButton.enabled = !self.isLoggedIn;
    self.loginButton.alpha = self.loginButton.enabled ? 1.0 : 0.5;
    self.logoutButton.enabled = self.isLoggedIn;
    self.logoutButton.alpha = self.logoutButton.enabled ? 1.0 : 0.5;
}

#pragma mark - IMTokenManagerDelegate
- (void)onTokenSuccess:(NSString *)token {
     NSLog(@"onTokenSuccess: 1111");
    int result = [[AopaImEngineKit sharedInstance] login:[self.localUserIdField.text intValue] token:token];
    [[AopaImMediaKit sharedInstance] initialize:self.publicPath];
     NSLog(@"onTokenSuccess: 222");
    if (result == 0) {
        self.isLoggedIn = YES;
        [self updateButtonStates];
        
        // 创建会话列表视图控制器
        ConversationListViewController *conversationListVC = [[ConversationListViewController alloc] init];
        conversationListVC.localUserId = self.localUserIdField.text;
        conversationListVC.remoteUserId = self.remoteUserIdField.text;
        conversationListVC.appId = self.appIdField.text;
        conversationListVC.serverType = self.selectedServerType;
        conversationListVC.chatType = self.selectedChatType;
        conversationListVC.groupId = self.groupId;
        
        // 创建导航控制器
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:conversationListVC];
        navController.modalPresentationStyle = UIModalPresentationFullScreen;
        
        // 显示会话列表
        [self presentViewController:navController animated:YES completion:nil];
         NSLog(@"onTokenSuccess: 333");
    } else {
        [self showAlert:@"错误" message:@"登录失败"];
         NSLog(@"onTokenSuccess: 4444");
    }
}

- (void)onTokenError:(NSString *)error {
    NSLog(@"onTokenSuccess 555: %@", error);
    [self showAlert:@"错误" message:error];
}

#pragma mark - Helper Methods

- (void)showAlert:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                 message:message
                                                          preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                            style:UIAlertActionStyleDefault
                                          handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
