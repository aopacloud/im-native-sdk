package com.aopa.imexamples;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.SearchView;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.aopa.imsdk.AopaImEngine;
import com.aopa.imsdk.AopaImMedia;
import com.google.android.material.dialog.MaterialAlertDialogBuilder;
import org.json.JSONArray;
import org.json.JSONObject;
import org.webrtc.ContextUtils;
import org.webrtc.IAopaImEventHandler;
import java.util.ArrayList;
import java.util.List;

public class ConversationListActivity extends AppCompatActivity {

    private RecyclerView recyclerView;
    private ConversationAdapter adapter;
    private SearchView searchView;
    private List<ContextUtils.Conversation> conversations;
    private List<ContextUtils.Conversation> filteredConversations;
    private String mlocalUserId;
    private String mremoteUserId;
    private String mServeUrl;
    private String mGroupId = "1234567865";
    private int mappId;
    private int mserverType;
    private int mchatType;
    private BroadcastReceiver updateReceiver;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_conversation_list);

        // 获取传递的参数
        Intent intent = getIntent();
        mlocalUserId = intent.getStringExtra("localUserId");
        mremoteUserId = intent.getStringExtra("remote_user_id");
        mappId = intent.getIntExtra("appid", 0);
        mserverType = intent.getIntExtra("serverType", 0);
        mchatType = intent.getIntExtra("chatType", 0);
        mServeUrl = intent.getStringExtra("serverUrl");

        // 初始化列表
        conversations = new ArrayList<>();
        filteredConversations = new ArrayList<>();

        onLogin();
        initViews();
    }

    @Override
    protected void onResume() {
        super.onResume();
        setupEventHandler();
        loadConversations();
    }

    @Override
    protected void onPause() {
        super.onPause();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();

        if(AopaImEngine.getInstance() != null){
            AopaImEngine.getInstance().setEventHandler(null);
        }
        onLogout();
    }

    private void initViews() {
        // 初始化搜索框
        searchView = findViewById(R.id.searchView);
        searchView.setOnQueryTextListener(new SearchView.OnQueryTextListener() {
            @Override
            public boolean onQueryTextSubmit(String query) {
                filterConversations(query);
                return true;
            }

            @Override
            public boolean onQueryTextChange(String newText) {
                filterConversations(newText);
                return true;
            }
        });

        // 初始化列表
        recyclerView = findViewById(R.id.recyclerView);
        recyclerView.setLayoutManager(new LinearLayoutManager(this));

        adapter = new ConversationAdapter(conversation -> {
            startChatActivity(conversation);
        });

        recyclerView.setAdapter(adapter);

        // 设置退出按钮
        findViewById(R.id.btnLogout).setOnClickListener(v -> showLogoutDialog());
    }

    private void startChatActivity(ContextUtils.Conversation conversation) {
        // 暂时移除当前的事件处理器
        AopaImEngine.getInstance().setEventHandler(null);
        AopaImMedia.getInstance().setEventHandler(null);

        Intent chatIntent = new Intent(this, ChatActivity.class);
        chatIntent.putExtra("localUserId", mlocalUserId);
        chatIntent.putExtra("remote_user_id", String.valueOf(conversation.getTargetId()));
        chatIntent.putExtra("appid", mappId);
        chatIntent.putExtra("chatType", mchatType);
        chatIntent.putExtra("serverType", mserverType);
        chatIntent.putExtra("serverUrl", mServeUrl);
        chatIntent.putExtra("groupId", mGroupId);
        startActivity(chatIntent);
    }

    private void onLogin() {
        try {
            AopaImEngine.create(this);
            AopaImEngine.getInstance().initialize(mappId, "sleepless", "", "", "/sdcard/",mchatType);
            AopaImMedia.create();

            String token = "";
            switch (mserverType) {
                case 0: 
                    token = IMTokenManager.getTokenEnvTest(mlocalUserId, mServeUrl);
                    break;
                case 1: 
                    String SERVER_URL = "https://im-publish.aopacloud.net/";
                    String IM_SERVER_URL = "http://im.aopacloud-cn.private";
                    token = IMTokenManager.getTokenEnvFormat(String.valueOf(mappId),
                            mlocalUserId, SERVER_URL, IM_SERVER_URL);
                    Log.d("TAG", "onLogin getTokenEnvFormat token:" + token);
                    break;
                case 2:
                    break;
                case 3:
                    break;
            }

            AopaImEngine.getInstance().login(Integer.parseInt(mlocalUserId), token);
            AopaImMedia.getInstance().initialize("/sdcard/");

            if (mchatType == ContextUtils.ConversationType.BMSG_GROUP_CHAT.ordinal() && mlocalUserId.equals("1234561")) {
                String[] memberList = {"1234562", "1234563"};
                String groupName = "测试群12";
                String resulttmp = IMTokenManager.getGroup(mGroupId, groupName, "", mlocalUserId, memberList, String.valueOf(mappId), mServeUrl);
                Log.d("TAG", "onLogin mGroupId:" + mGroupId + ",token:" + resulttmp);

                String[] userIds = {mlocalUserId, "1234562","1234563"};
                String result = IMTokenManager.joinGroup(userIds, mGroupId, groupName, String.valueOf(mappId), mServeUrl);
                if ("200".equals(result)) {
                    Log.d("TAG", "加入群组成功");
                } else {
                    Log.e("TAG", "加入群组失败");
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            ChatUtil.showToast(this, "已登录");
        }
    }

    private void onLogout() {
        try {
            //解散群组
            if (mchatType == ContextUtils.ConversationType.BMSG_GROUP_CHAT.ordinal() && mlocalUserId.equals("1234561")) {
                String result = IMTokenManager.dismissGroup(mGroupId,  mlocalUserId, String.valueOf(mappId), mServeUrl);
                Log.d("TAG", "onLogout mGroupId:" + mGroupId + ",token:" + result);

                if ("200".equals(result)) {
                    Log.d("TAG", "解散群组成功");
                } else {
                    Log.e("TAG", "解散群组失败");
                }
            }
            AopaImMedia.getInstance().stopPlaying();
            AopaImMedia.getInstance().stopRecording();

            if (AopaImEngine.getInstance() != null) {
                AopaImEngine.getInstance().logout();
                AopaImEngine.destroy();
            }
            
            if (AopaImMedia.getInstance() != null) {
                AopaImMedia.destroy();
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            ChatUtil.showToast(this, "已登出");
        }
    }

    private void setupEventHandler() {
        if(AopaImEngine.getInstance() == null){
            return ;
        }

        AopaImEngine.getInstance().setEventHandler(new IAopaImEventHandler() {
            @Override
            public void OnError(int code, String msg) {
                runOnUiThread(() -> ChatUtil.showToast(ConversationListActivity.this,
                        "错误: " + msg));
            }

            @Override
            public void OnNewMessageNotify(ContextUtils.MessageContent msgContent, int left) {
                runOnUiThread(() -> loadConversations());
            }

            @Override
            public void OnKickOutNotify(int reason) {
                runOnUiThread(() -> {
                    onLogout();
                    ChatUtil.showToast(ConversationListActivity.this, "设备已在其他地方登录");
                    finish();
                });
            }

            @Override
            public void OnUnreadCountNotify(int type, int target_id, int unread_count) {
                runOnUiThread(() -> loadConversations());
            }
        });
    }

   

    private void loadConversations() {
        conversations = AopaImEngine.getInstance().getConversationList();
        if(mchatType == ContextUtils.ConversationType.BMSG_PRIVATE_CHAT.ordinal()) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                conversations.removeIf(conversation -> conversation.getType() == ContextUtils.ConversationType.BMSG_GROUP_CHAT.ordinal());
            }
            // 如果远程用户ID存在但不在会话列表中,添加一个默认会话
            if ((mremoteUserId != null && !remoteUserExists())) {
                ContextUtils.Conversation defaultConv = new ContextUtils.Conversation();
                defaultConv.setType(mchatType);
                defaultConv.setTargetId(Long.parseLong(mremoteUserId));

                defaultConv.setUnreadCount(0);
                conversations.add(defaultConv);
            }
        }else{
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                conversations.removeIf(conversation -> conversation.getType() == ContextUtils.ConversationType.BMSG_PRIVATE_CHAT.ordinal());
            }
            boolean exists = false;
            for (ContextUtils.Conversation conversation : conversations) {
                if (String.valueOf(conversation.getTargetId()).equals(mGroupId)) {
                    exists = true;
                    break;
                }
            }

            if(!exists){
                ContextUtils.Conversation defaultConv = new ContextUtils.Conversation();
                defaultConv.setType(mchatType);
                defaultConv.setTargetId(Long.parseLong(mGroupId));

                defaultConv.setUnreadCount(0);
                conversations.add(defaultConv);
            }
        }
        adapter.setConversations(conversations);
        adapter.notifyDataSetChanged();
    }

    private boolean remoteUserExists() {
        long remoteId = Long.parseLong(mremoteUserId);
        for (ContextUtils.Conversation conv : conversations) {
            if (conv.getTargetId() == remoteId) {
                return true;
            }
        }
        return false;
    }

    private void filterConversations(String query) {
        filteredConversations = new ArrayList<>();
        for (ContextUtils.Conversation conv : conversations) {
            if (String.valueOf(conv.getTargetId()).contains(query)) {
                filteredConversations.add(conv);
            }
        }
        adapter.setConversations(filteredConversations);
        adapter.notifyDataSetChanged();
    }

    @Override
    public void onBackPressed() {
        showLogoutDialog();
    }

    private void showLogoutDialog() {
        new MaterialAlertDialogBuilder(this)
                .setTitle("退出登录")
                .setMessage("确定要退出登录吗？")
                .setPositiveButton("确定", (dialog, which) -> {
                    onLogout();
                    finish();
                })
                .setNegativeButton("取消", null)
                .show();
    }
}