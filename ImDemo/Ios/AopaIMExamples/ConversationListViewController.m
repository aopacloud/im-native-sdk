#import "ConversationListViewController.h"
#import "ChatViewController.h"
#import "AopaImEngineKit.h"

@interface ConversationListViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *conversations;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSMutableArray *filteredConversations;
@property (nonatomic, assign) BOOL isSearching;

@end

@implementation ConversationListViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Chat";
    self.conversations = [NSMutableArray array];
    self.filteredConversations = [NSMutableArray array];
    
    [self setupUI];
    [self setupNavigationBar];
    [self setupEventHandler];
    [self loadConversations];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupEventHandler];
    [self loadConversations];
}

#pragma mark - UI Setup

- (void)setupUI {
    // 设置搜索栏
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.placeholder = @"搜索";
    self.searchBar.delegate = self;
    
    // 设置表格视图
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableHeaderView = self.searchBar;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self.view addSubview:self.tableView];
}

- (void)setupNavigationBar {
    // 设置退出按钮
    UIBarButtonItem *logoutButton = [[UIBarButtonItem alloc] 
                                    initWithTitle:@"退出" 
                                    style:UIBarButtonItemStylePlain 
                                    target:self 
                                    action:@selector(logoutButtonTapped)];
    self.navigationItem.leftBarButtonItem = logoutButton;
}

#pragma mark - Data Loading

- (void)loadConversations {
    // 获取会话列表
    NSArray *conversationList = [[AopaImEngineKit sharedInstance] getConversationList];
    NSMutableArray *filteredConversations = [NSMutableArray array];
    BOOL targetExists = NO;
    
    // 根据聊天类型过滤会话
    for (Conversation *conv in conversationList) {
        // 私聊模式下只显示私聊会话
        if (self.chatType == BMSG_PRIVATE_CHAT) {
            if (conv.type == BMSG_PRIVATE_CHAT) {
                [filteredConversations addObject:[self convertConversationToDict:conv]];
                // 检查目标用户是否存在
                if (conv.targetId == [self.remoteUserId intValue]) {
                    targetExists = YES;
                }
            }
        }
        // 群聊模式下只显示群聊会话
        else if (self.chatType == BMSG_GROUP_CHAT) {
            if (conv.type == BMSG_GROUP_CHAT) {
                [filteredConversations addObject:[self convertConversationToDict:conv]];
                // 检查目标群组是否存在
                if (conv.targetId == [self.groupId intValue]) {
                    targetExists = YES;
                }
            }
        }
    }
    
    // 如果目标不存在，添加默认会话
    if (!targetExists) {
        NSMutableDictionary *defaultConv = [NSMutableDictionary dictionary];
        if (self.chatType == BMSG_PRIVATE_CHAT && self.remoteUserId.length > 0) {
            [defaultConv setObject:@"私聊" forKey:@"type"];
            [defaultConv setObject:self.remoteUserId forKey:@"name"];
            [defaultConv setObject:@(BMSG_PRIVATE_CHAT) forKey:@"conversationType"];
            [defaultConv setObject:@([self.remoteUserId intValue]) forKey:@"targetId"];
        }
        else if (self.chatType == BMSG_GROUP_CHAT && self.groupId.length > 0) {
            [defaultConv setObject:@"群聊" forKey:@"type"];
            [defaultConv setObject:self.groupId forKey:@"name"];
            [defaultConv setObject:@(BMSG_GROUP_CHAT) forKey:@"conversationType"];
            [defaultConv setObject:@([self.groupId intValue]) forKey:@"targetId"];
        }
        
        if (defaultConv.count > 0) {
            [defaultConv setObject:@"" forKey:@"lastMessage"];
            [defaultConv setObject:@(0) forKey:@"unreadCount"];
            [filteredConversations addObject:defaultConv];
        }
    }
    
    // 更新数据源并刷新UI
    [self.conversations removeAllObjects];
    [self.conversations addObjectsFromArray:filteredConversations];
    
    // 按未读数量排序
    [self.conversations sortUsingComparator:^NSComparisonResult(NSDictionary *conv1, NSDictionary *conv2) {
        NSInteger unread1 = [conv1[@"unreadCount"] integerValue];
        NSInteger unread2 = [conv2[@"unreadCount"] integerValue];
        if (unread1 > unread2) return NSOrderedAscending;
        if (unread1 < unread2) return NSOrderedDescending;
        return NSOrderedSame;
    }];
    
    [self.tableView reloadData];
}

// 辅助方法：将 Conversation 对象转换为字典
- (NSDictionary *)convertConversationToDict:(Conversation *)conv {
    NSMutableDictionary *convDict = [NSMutableDictionary dictionary];
    
    // 设置会话类型
    [convDict setObject:(conv.type == BMSG_GROUP_CHAT ? @"群聊" : @"私聊") forKey:@"type"];
    
    // 设置目标ID
    NSString *targetIdStr = [NSString stringWithFormat:@"%u", conv.targetId];
    [convDict setObject:targetIdStr forKey:@"name"];
    
    // 设置最后一条消息
    NSString *lastMessage = @"";
    if (conv.lastMessage.user.name.length > 0) {
        lastMessage = [NSString stringWithFormat:@"%@: ", conv.lastMessage.user.name];
    }
    lastMessage = [lastMessage stringByAppendingString:conv.lastMessage.content ?: @""];
    [convDict setObject:lastMessage forKey:@"lastMessage"];
    
    // 设置其他属性
    [convDict setObject:@(conv.unreadCount) forKey:@"unreadCount"];
    [convDict setObject:@(conv.type) forKey:@"conversationType"];
    [convDict setObject:@(conv.targetId) forKey:@"targetId"];
    
    return convDict;
}

#pragma mark - Actions

- (void)logoutButtonTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认退出"
                                                                 message:@"确定要退出登录吗？"
                                                          preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定"
                                                          style:UIAlertActionStyleDestructive
                                                        handler:^(UIAlertAction * _Nonnull action) {
        // 执行登出操作
        [[AopaImEngineKit sharedInstance] logout];
        
        // 关闭所有视图控制器，返回登录页面
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [alert addAction:cancelAction];
    [alert addAction:confirmAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.isSearching ? self.filteredConversations.count : self.conversations.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"ConversationCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
    }
    
    NSDictionary *conversation = self.isSearching ? 
        self.filteredConversations[indexPath.row] : self.conversations[indexPath.row];
    
    // 设置主标题
    cell.textLabel.text = conversation[@"name"];
    
    // 设置副标题
    cell.detailTextLabel.text = conversation[@"lastMessage"];
    cell.detailTextLabel.textColor = [UIColor grayColor];
    
    // 添加会话类型标签
    UILabel *typeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 40, 20)];
    typeLabel.text = conversation[@"type"];
    typeLabel.textColor = [UIColor redColor];
    typeLabel.font = [UIFont systemFontOfSize:12];
    
    // 显示未读消息数
    NSInteger unreadCount = [conversation[@"unreadCount"] integerValue];
    if (unreadCount > 0) {
        UILabel *badgeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        badgeLabel.text = [NSString stringWithFormat:@"%ld", (long)unreadCount];
        badgeLabel.backgroundColor = [UIColor redColor];
        badgeLabel.textColor = [UIColor whiteColor];
        badgeLabel.textAlignment = NSTextAlignmentCenter;
        badgeLabel.layer.cornerRadius = 10;
        badgeLabel.layer.masksToBounds = YES;
        cell.accessoryView = badgeLabel;
    } else {
        cell.accessoryView = typeLabel;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *conversation = self.isSearching ? 
        self.filteredConversations[indexPath.row] : self.conversations[indexPath.row];
    
    // 从 Storyboard 实例化 ChatViewController
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ChatViewController *chatVC = [storyboard instantiateViewControllerWithIdentifier:@"Chat-View-Controller"];
    
    // 设置属性
    chatVC.localUserId = self.localUserId;
    //chatVC.remoteUserId = self.remoteUserId;
    chatVC.remoteUserId = conversation[@"name"];  // 或者使用 targetId，取决于您的需求
    chatVC.appId = [self.appId integerValue];
    chatVC.chatType = self.chatType;
    //chatVC.chatType = [conversation[@"conversationType"] integerValue] -1; // 使用会话中的类型
    chatVC.serverType = self.serverType;
    chatVC.groupId = self.groupId;
    //chatVC.targetId = [conversation[@"targetId"] unsignedIntValue];
    
    [self.navigationController pushViewController:chatVC animated:YES];
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText.length > 0) {
        self.isSearching = YES;
        [self.filteredConversations removeAllObjects];
        
        for (NSDictionary *conversation in self.conversations) {
            NSString *name = conversation[@"name"];
            if ([name.lowercaseString containsString:searchText.lowercaseString]) {
                [self.filteredConversations addObject:conversation];
            }
        }
    } else {
        self.isSearching = NO;
    }
    
    [self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.text = @"";
    self.isSearching = NO;
    [searchBar resignFirstResponder];
    [self.tableView reloadData];
}


#pragma mark - Event Handler

- (void)setupEventHandler {
    [[AopaImEngineKit sharedInstance] setEventHandler:self];
    [[AopaImMediaKit sharedInstance] setEventHandler:self];
}


#pragma mark - AopaImEventHandler

- (void)OnRecordStatusChanged:(int)status {
}

- (void)OnPlayStatusChanged:(int)status {
}

- (void)onError:(int)code message:(NSString *)msg {
}

- (void)onConnectStatusChanged:(ConnectStatus)status {
}

- (void)onSendMessage:(int)code message:(NSString *)msg clientMessageId:(int64_t)messageId status:(MessageStatus)status {
}

- (void)onNewMessageNotify:(MessageContent *)content left:(int)left {
    [self loadConversations];
}

- (void)onReceiveReadReceipt:(ConversationType)type targetId:(uint32_t)targetId timestamp:(int64_t)timestamp {
}

- (void)onRecallMessageNotify:(MessageContent *)content {
}

- (void)onTypingStatusChanged:(ConversationType)type targetId:(uint32_t)targetId {
}

- (void)onKickOutNotify:(int)reason {
}

- (void)onCmdMessageNotify:(MessageContent *)content {}
- (void)onUnreadCountNotify:(ConversationType)type targetId:(uint32_t)targetId unreadCount:(int)unreadCount {}
- (void)onNotification:(NSString *)payload {}
- (void)onOnlineMsg:(NSString *)payload {}
@end
