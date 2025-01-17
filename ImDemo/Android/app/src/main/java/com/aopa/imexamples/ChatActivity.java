package com.aopa.imexamples;

import static org.webrtc.ContextUtils.MessageStatus;
import static org.webrtc.ContextUtils.MessageType;
import static org.webrtc.ContextUtils.DirectionType;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.localbroadcastmanager.content.LocalBroadcastManager;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import android.content.Intent;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.provider.MediaStore;
import android.text.Editable;
import android.text.TextWatcher;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import com.aopa.imsdk.AopaImEngine;
import com.aopa.imsdk.AopaImMedia;
import com.google.android.material.dialog.MaterialAlertDialogBuilder;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.webrtc.ContextUtils;
import org.webrtc.IAopaImEventHandler;
import org.webrtc.IAopaImMediaHandler;
import org.webrtc.Message;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class ChatActivity extends AppCompatActivity {
    private static final int REQUEST_SELECT_IMAGE = 100;

    private RecyclerView rvMessages;
    private EditText etMessage;
    private MessageAdapter messageAdapter;
    private boolean isRecording = false;
    private View btnAudio;
    private String voiceMessageId;

    // 语音录制相关视图
    private View audioRecordingView;
    private TextView audioCountdownText;
    private View audioWaveformView;
    private ImageView audioRecordingIcon;
    private Handler recordingHandler = new Handler();
    private int recordingDuration = 0;
    private static final int MAX_RECORDING_DURATION = 60; // 最大录音时长(秒)
    private AopaImEventHandler mAopaImEventHandler;
    private AopaImMediaHandler mAopaImMediaHandler;

    private long recordTime = 0;
    private long recordMsgId = 0;

    private long[] messageIdsToDelete;
    private String mLocalUserId;
    private String mRemoteUserId;
    private String mGroupId;
    private String mServeUrl;
    private int mServeType = 0;
    private int mChatType = 0;
    private int mAppid;

    private Handler typingHandler = new Handler();
    private static final long TYPING_DELAY = 3000; // 3秒后停止输入状态
    private boolean isTyping = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_chat);

        Intent intent = getIntent();
        mLocalUserId = intent.getStringExtra("localUserId");
        mRemoteUserId = intent.getStringExtra("remote_user_id");
        mServeUrl = intent.getStringExtra("serverUrl");
        mGroupId = intent.getStringExtra("groupId");
        mServeType = intent.getIntExtra("serverType", 0);
        mChatType = intent.getIntExtra("chatType", 0);
        mAppid = intent.getIntExtra("appid", 0);
        AopaImEngine.setServerAddress(mServeUrl, "");


        initLogView();
        initUI();
        initMessageList();
        initAudioRecordingView();
        mAopaImEventHandler = new AopaImEventHandler();
        mAopaImMediaHandler = new AopaImMediaHandler();
        AopaImEngine.getInstance().setEventHandler(mAopaImEventHandler);
        AopaImMedia.getInstance().setEventHandler(mAopaImMediaHandler);

        loadHistoryMessages();
    }

    @Override
    public void onBackPressed() {
        AopaImEngine.getInstance().setEventHandler(null);
        AopaImMedia.getInstance().setEventHandler(null);
        stopAllOngoingOperations();
        Intent updateIntent = new Intent("update_conversation_list");
        LocalBroadcastManager.getInstance(this).sendBroadcast(updateIntent);
        finish();
        //showExitDialog();
    }

    private void loadHistoryMessages() {
        int  localTargetId = Integer.parseInt((ChatUtil.getChatType(mChatType) == ContextUtils.ConversationType.BMSG_PRIVATE_CHAT)?mRemoteUserId:mGroupId);
        // 获取本地和远程历史消息
        List<ContextUtils.MessageContent> localMsg = getHistoryMessages(mChatType, localTargetId, -1, 100, 0, false);
        List<ContextUtils.MessageContent> remoteMsg = getHistoryMessages(mChatType, Integer.parseInt(mLocalUserId), -1, 100, 0, false);
        
        // 合并消息列表
        List<Message> allMessages = new ArrayList<>();
        int currentIndex = 0; 
        int totalMessages = localMsg.size();
        // 处理本地消息
        if (localMsg != null) {
            for (ContextUtils.MessageContent msgContent : localMsg) {
                currentIndex++; 
                Message message = ContextUtils.convertToMessage(msgContent, true);
                if (message != null) {
                    allMessages.add(message);
                    if(ChatUtil.getChatType(mChatType) == ContextUtils.ConversationType.BMSG_GROUP_CHAT){
                        AopaImEngine.getInstance().sendReadReceiptMessage(msgContent.getConversationType().ordinal(),localTargetId, Long.parseLong(msgContent.getMessageId()));
                    }
                    // if (currentIndex == totalMessages) {
                    //     AopaImEngine.getInstance().sendReadReceiptMessage(msgContent.getConversationType().ordinal(),
                    //             (int) msgContent.getSenderId(), Long.parseLong(localMsg.get(0).getMessageId()));
                    // }    
                }
            }
        }
        
        // 处理远程消息
        currentIndex = 0;
        totalMessages = remoteMsg.size();
        if (remoteMsg != null) {
            for (ContextUtils.MessageContent msgContent : remoteMsg) {
                currentIndex++; 
                Message messageConv = ContextUtils.convertToMessage(msgContent, false);
                if (messageConv != null && String.valueOf(msgContent.getSenderId()).equals(mRemoteUserId)){
                    allMessages.add(messageConv);
                    AopaImEngine.getInstance().sendReadReceiptMessage(msgContent.getConversationType().ordinal(),
                                (int) msgContent.getSenderId(), Long.parseLong(msgContent.getMessageId()));
                    //if (currentIndex == totalMessages) {
                        // AopaImEngine.getInstance().sendReadReceiptMessage(msgContent.getConversationType().ordinal(),
                        //         (int) msgContent.getSenderId(), Long.parseLong(remoteMsg.get(0).getMessageId()));
                    //}
                }
            }
        }
        try {
            // 按时间排序
            Collections.sort(allMessages, (m1, m2) -> {
                long time1 = Long.parseLong(m1.getMessageId());
                long time2 = Long.parseLong(m2.getMessageId());
                return Long.compare(time1, time2);
            });
        } catch (Exception e) {
            e.printStackTrace();
        }
        // 添加到适配器
        for (Message message : allMessages) {
            messageAdapter.addMessage(message);
        }
        
        // 滚动到底部
        scrollToBottom();
    }

    private void initUI() {
        rvMessages = findViewById(R.id.rvMessages);
        etMessage = findViewById(R.id.etMessage);
        btnAudio = findViewById(R.id.btnAudio);

        findViewById(R.id.btnSend).setOnClickListener(v -> sendTextMessage());
        findViewById(R.id.btnImage).setOnClickListener(v -> selectImage());
        btnAudio.setOnClickListener(v -> handleAudioRecord());

        findViewById(R.id.toolbar).setOnClickListener(v -> showExitDialog());

        // 添加输入监听
        etMessage.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {}

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                if (!isTyping) {
                    isTyping = true;
                    sendTypingStatus();
                }

                // 重置定时器
                typingHandler.removeCallbacksAndMessages(null);
                typingHandler.postDelayed(() -> isTyping = false, TYPING_DELAY);
            }

            @Override
            public void afterTextChanged(Editable s) {}
        });
    }

    private void sendTypingStatus() {
        if (isTyping) {
            AopaImEngine.getInstance().sendTypingStatus(mChatType,
                    Integer.parseInt(mRemoteUserId)
            );
        }
    }

    private void initLogView() {
        View logContainer = findViewById(R.id.logContainer);
        TextView tvLog = findViewById(R.id.tvLog);
        ScrollView scrollView = findViewById(R.id.scrollView);
        Button btnShowLog = findViewById(R.id.btnShowLog);
    }

    private void initMessageList() {
        messageAdapter = new MessageAdapter(this, message -> {
            if (message.getType() == MessageType.BMSG_TYPE_IMAGE.ordinal() && !message.isRecalled()) {
                ChatUtil.showImageViewer(this, message.getContent());
            }
            showMessageOptions(message);
        });
        rvMessages.setLayoutManager(new LinearLayoutManager(this));
        rvMessages.setAdapter(messageAdapter);
    }

    private void initAudioRecordingView() {
        audioRecordingView = findViewById(R.id.audioRecordingView);
        audioCountdownText = findViewById(R.id.audioCountdownText);
        audioWaveformView = findViewById(R.id.audioWaveformView);
        audioRecordingIcon = findViewById(R.id.audioRecordingIcon);
        audioRecordingView.setVisibility(View.GONE);
    }

    private void scrollToBottom() {
        if (rvMessages != null && messageAdapter != null && messageAdapter.getItemCount() > 0) {
            rvMessages.scrollToPosition(messageAdapter.getItemCount() - 1);
        }
    }

    private void showExitDialog() {
        new MaterialAlertDialogBuilder(this)
                .setTitle("退出聊天")
                .setMessage("确定要退出聊天吗？")
                .setPositiveButton("确定", (dialog, which) -> {
                    stopAllOngoingOperations();
                    //onLogout();
                    setResult(RESULT_OK);
                    finish();
                })
                .setNegativeButton("取消", null)
                .show();
    }
  

    private void stopAllOngoingOperations() {
        if (isRecording) {
            stopRecording();
        }
        recordingHandler.removeCallbacksAndMessages(null);
    }

    private void updateUnreadCount() {
        // 当消息被读取时，通知会话列表更新未读数
        Intent intent = new Intent("update_conversation_list");
        LocalBroadcastManager.getInstance(this).sendBroadcast(intent);
    }

    private void startRecording() {
        voiceMessageId = String.valueOf(System.currentTimeMillis());
        AopaImMedia.getInstance().startRecording(voiceMessageId);
        ChatUtil.showToast(this, "开始录音");
    }

    private void stopRecording() {
        AopaImMedia.getInstance().stopRecording();
        ChatUtil.showToast(this, "录音完成");
    }

    private void startAudioCountdown() {
        recordingDuration = 0;
        recordingHandler.postDelayed(new Runnable() {
            @Override
            public void run() {
                recordingDuration++;
                if (recordingDuration < MAX_RECORDING_DURATION) {
                    updateCountdownText(recordingDuration);
                    recordingHandler.postDelayed(this, 1000);
                } else {
                    stopAudioRecording();
                }
            }
        }, 1000);
    }

    private void stopAudioCountdown() {
        recordingHandler.removeCallbacksAndMessages(null);
    }

    private void updateCountdownText(int seconds) {
        int minutes = seconds / 60;
        int remainingSeconds = seconds % 60;
        String timeText = String.format("%02d:%02d", minutes, remainingSeconds);
        audioCountdownText.setText(timeText);
    }

    private void showMessageOptions(Message message) {
        if(message.getDirection() == DirectionType.BMSG_DIRECTION_SEND.ordinal() || (message.getDirection() == 1 && message.getType() == MessageType.BMSG_TYPE_VOICE.ordinal())) {
            ArrayList<String> optionsList = new ArrayList<>();
            if( message.getDirection() == 0) {
                optionsList.add("撤回");
                optionsList.add("删除");
            }

            if (message.getType() == MessageType.BMSG_TYPE_VOICE.ordinal()) {
                optionsList.add("播放语音");
                optionsList.add("停止播放语音");
            }

            String[] options = optionsList.toArray(new String[0]);

            new MaterialAlertDialogBuilder(this)
                    .setItems(options, (dialog, which) -> {
                        String selectedOption = options[which];
                        switch (selectedOption) {
                            case "标记已读":
                                message.setRead(true);
                                messageAdapter.updateMessage(message);
                                break;
                            case "撤回":
                                handleMessageRecall(message);
                                break;
                            case "删除":
                                handleMessageDelete(message);
                                break;
                            case "播放语音":
                                if (message.getType() == MessageType.BMSG_TYPE_VOICE.ordinal()) {
                                    playVoiceMessage(message);
                                }
                                break;
                            case "停止播放语音":
                                if (message.getType() == MessageType.BMSG_TYPE_VOICE.ordinal()) {
                                    AopaImMedia.getInstance().stopPlaying();
                                }
                                break;
                        }
                    })
                    .show();
        }
    }

    private void handleMessageRecall(Message message) {
        message.setRecalled(true);
        messageAdapter.updateMessage(message);

        AopaImEngine.getInstance().recallMessage(Long.parseLong(message.getMessageId()));
        Log.e("yjj", "recallMessage messageId:" + Long.parseLong(message.getMessageId()));
        ChatUtil.showToast(this, "消息已撤回");
    }

    private void handleMessageDelete(Message message) {
        messageAdapter.removeMessage(message);

        AopaImEngine.getInstance().sendDeleteMessage(1, Integer.parseInt(mRemoteUserId), messageIdsToDelete);
        ChatUtil.showToast(this, "消息已删除");
    }

    private void playVoiceMessage(Message message) {
        if (message.getType() == MessageType.BMSG_TYPE_VOICE.ordinal()) {
            AopaImMedia.getInstance().startPlaying(message.getMessageId());
        }
    }

    public List<ContextUtils.MessageContent> getHistoryMessages(int type,
                                                                int targetId,
                                                                long oldestMessageId,
                                                                int count,
                                                                int direction,
                                                                boolean fromServer) {
        return  AopaImEngine.getInstance().getHistoryMessages(type, 
                                targetId, 
                                oldestMessageId,
                                count,
                                direction,
                                fromServer);                        
    }

    private void sendTextMessage() {
        String text = etMessage.getText().toString().trim();
        if (!text.isEmpty()) {
            String messageId = String.valueOf(System.currentTimeMillis());
            Message message = new Message(MessageType.BMSG_TYPE_TEXT.ordinal(), text);
            message.setMessageId(messageId);
            message.setStatus(MessageStatus.BMSG_STATUS_SENDING.ordinal());
            message.setDirection(DirectionType.BMSG_DIRECTION_SEND.ordinal());
            message.setUserId(mLocalUserId);
            messageAdapter.addMessage(message);
            etMessage.setText("");
            scrollToBottom();

            ContextUtils.SendMessageContent messageContent = new ContextUtils.SendMessageContent(
                    ChatUtil.getChatType(mChatType),
                    MessageType.BMSG_TYPE_TEXT,
                    ChatUtil.getChatType(mChatType) == ContextUtils.ConversationType.BMSG_GROUP_CHAT ? mGroupId : mRemoteUserId,
                    text,
                    messageId
            );

            ContextUtils.PushInfo pushInfo = new ContextUtils.PushInfo(
                    "New message",
                    "data",
                    "Chat"
            );

            AopaImEngine.getInstance().sendMessage(messageContent, pushInfo);
            runOnUiThread(() -> messageAdapter.notifyDataSetChanged());
        }
    }

    private void selectImage() {
        Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
        intent.setType("image/*");
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        startActivityForResult(Intent.createChooser(intent, "选择图片"), REQUEST_SELECT_IMAGE);
    }

    private void handleAudioRecord() {
        if (!isRecording) {
            startAudioRecording();
        } else {
            stopAudioRecording();
        }
        isRecording = !isRecording;
    }

    private Bitmap compressImage(Bitmap image) {
        int maxWidth = 1024;  // 最大宽度
        int maxHeight = 1024; // 最大高度
        
        int width = image.getWidth();
        int height = image.getHeight();
        
        float ratioBitmap = (float) width / height;
        
        if (ratioBitmap > 1) {
            // 宽图
            width = maxWidth;
            height = (int) (width / ratioBitmap);
        } else {
            // 长图
            height = maxHeight;
            width = (int) (height * ratioBitmap);
        }
        
        return Bitmap.createScaledBitmap(image, width, height, true);
    }

    private void startAudioRecording() {
        startRecording();
        btnAudio.setSelected(true);
        audioRecordingView.setVisibility(View.VISIBLE);
        startAudioCountdown();
        recordTime = System.currentTimeMillis();
    }

    private void stopAudioRecording() {
        String timeText = String.format("%02d:%02d", 0, 0);
        audioCountdownText.setText(timeText);

        stopRecording();
        btnAudio.setSelected(false);
        audioRecordingView.setVisibility(View.GONE);
        stopAudioCountdown();

        long endTime = System.currentTimeMillis();
        long duration = (endTime - recordTime) / 1000;
        sendVoiceMessage(duration, voiceMessageId);
    }

    private void sendVoiceMessage(long duration, String messageId) {
        Message message = new Message(MessageType.BMSG_TYPE_VOICE.ordinal(), messageId);
        message.setMessageId(messageId);
        message.setStatus(MessageStatus.BMSG_STATUS_SENDING.ordinal());
        message.setDirection(DirectionType.BMSG_DIRECTION_SEND.ordinal());
        message.setDuration((int) duration);
        messageAdapter.addMessage(message);
        scrollToBottom();

        ContextUtils.SendMessageContent messageContent = new ContextUtils.SendMessageContent(
                ChatUtil.getChatType(mChatType),
                MessageType.BMSG_TYPE_VOICE,
                ChatUtil.getChatType(mChatType) == ContextUtils.ConversationType.BMSG_GROUP_CHAT ? mGroupId : mRemoteUserId,
                messageId,
                messageId
        );

        ContextUtils.PushInfo pushInfo = new ContextUtils.PushInfo(
                "New message",
                "data",
                "Chat"
        );

        AopaImEngine.getInstance().sendVoiceMessage(messageContent, pushInfo, (int) duration);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == REQUEST_SELECT_IMAGE && resultCode == RESULT_OK && data != null) {
            Uri imageUri = data.getData();
            try {
                // 压缩图片
                Bitmap originalBitmap = MediaStore.Images.Media.getBitmap(getContentResolver(), imageUri);
                Bitmap compressedBitmap = compressImage(originalBitmap);

                // 将压缩后的 Bitmap 转换为 byte 数组
                ByteArrayOutputStream baos = new ByteArrayOutputStream();
                compressedBitmap.compress(Bitmap.CompressFormat.JPEG, 30, baos);
                byte[] imageData = baos.toByteArray();

                String messageId = String.valueOf(System.currentTimeMillis());
                Message message = new Message(MessageType.BMSG_TYPE_IMAGE.ordinal(), "/sdcard/"+messageId +".jpg");
                message.setMessageId(messageId);
                message.setStatus(MessageStatus.BMSG_STATUS_SENDING.ordinal());
                message.setDirection(DirectionType.BMSG_DIRECTION_SEND.ordinal());

                ContextUtils.SendMessageContent messageContent = new ContextUtils.SendMessageContent(
                        ChatUtil.getChatType(mChatType),
                        MessageType.BMSG_TYPE_IMAGE,
                        ChatUtil.getChatType(mChatType) == ContextUtils.ConversationType.BMSG_GROUP_CHAT ? mGroupId : mRemoteUserId,
                        imageUri.toString(),
                        messageId
                );

                ContextUtils.PushInfo pushInfo = new ContextUtils.PushInfo(
                        "New message",
                        "data",
                        "Chat"
                );

                AopaImEngine.getInstance().sendImageMessage(messageContent, pushInfo, "image/jpeg", imageData);
                runOnUiThread(() -> messageAdapter.notifyDataSetChanged());
                messageAdapter.addMessage(message);
                scrollToBottom();

            } catch (Exception e) {
                e.printStackTrace();
                ChatUtil.showToast(this, "图片处理失败: " + e.getMessage());
            }
        }
    }

    private class AopaImMediaHandler extends IAopaImMediaHandler {
        @Override
        public void OnRecordStatusChanged(int status) {
            runOnUiThread(() -> ChatUtil.showToast(ChatActivity.this, "OnRecordStatusChanged"));
        }

        @Override
        public void OnPlayStatusChanged(int status) {
            runOnUiThread(() -> {
                if (status == 2) {
                    AopaImMedia.getInstance().stopPlaying();
                    ChatUtil.showToast(ChatActivity.this, "OnPlayStatusChanged 播放完成");
                }
            });
        }
    }

    private class AopaImEventHandler extends IAopaImEventHandler {
        @Override
        public void OnError(int code, String msg) {
            runOnUiThread(() -> ChatUtil.showToast(ChatActivity.this, "错误: " + msg));
        }

        @Override
        public void OnSendMessage(int code, String msg, long client_message_id, int status) {
            messageIdsToDelete = new long[]{client_message_id};
            Log.e("yjj", "OnSendMessage messageId:" + client_message_id + ",code:" + code + ",status:" + status);
            runOnUiThread(() -> {
                String messageId = String.valueOf(client_message_id);
                recordMsgId = client_message_id;
                for (Message message : messageAdapter.getMessages()) {
                    if (message.getMessageId().equals(messageId)) {
                        message.setStatus(status);
                        message.setUserId(mLocalUserId);
                        messageAdapter.updateMessage(message);
                        break;
                    }
                }
            });
        }

        @Override
        public void OnConnectStatusChanged(int status_code) {
        }

        @Override
        public void OnKickOutNotify(int reason) {
            runOnUiThread(() -> {
                onBackPressed();
                ChatUtil.showToast(ChatActivity.this, "设备已经登录踢出房间");
            });
        }

        @Override
        public void OnNewMessageNotify(ContextUtils.MessageContent msgContent, int left) {
            runOnUiThread(() -> {
                Message message = null;
                switch (msgContent.getMsgType()) {
                    case BMSG_TYPE_IMAGE:
                        message = new Message(MessageType.BMSG_TYPE_IMAGE.ordinal(), msgContent.getImageUrl());
                        break;
                    case BMSG_TYPE_VOICE:
                        message = new Message(MessageType.BMSG_TYPE_VOICE.ordinal(), msgContent.getVoiceUrl());
                        if (msgContent.getDuration() > 0) {
                            message.setDuration(msgContent.getDuration());
                        }
                        break;
                    default:
                        message = new Message(MessageType.BMSG_TYPE_TEXT.ordinal(), msgContent.getContent());
                        break;
                }

                if (message != null) {
                    message.setMessageId(msgContent.getMessageId());
                    message.setStatus(msgContent.getSentStatus().ordinal());
                    message.setDirection(msgContent.getDirection().ordinal());
                    message.setUserId(String.valueOf(msgContent.getSenderId()));
                    messageAdapter.addMessage(message);
                    scrollToBottom();
                    
                    //if(left == 0){
                    int localTargetId = Integer.parseInt((ChatUtil.getChatType(mChatType) == ContextUtils.ConversationType.BMSG_PRIVATE_CHAT)?mRemoteUserId:mGroupId);
                    AopaImEngine.getInstance().sendReadReceiptMessage(msgContent.getConversationType().ordinal(),localTargetId, Long.parseLong(msgContent.getMessageId()));
                    //}
                }
            });
        }

        @Override
        public void OnReceiveReadReceipt(int type, int target_id, long timestamp) {
            Log.e("yjj", "OnReceiveReadReceipt type:" + type + ",target_id:" + target_id + ",timestamp:" + timestamp);
            runOnUiThread(() -> {
                for (Message message : messageAdapter.getMessages()) {
                    if (message.getDirection() == DirectionType.BMSG_DIRECTION_SEND.ordinal() &&
                            message.getStatus() == MessageStatus.BMSG_STATUS_SENT.ordinal()) {
                        long messageTimestamp = Long.parseLong(message.getMessageId());
                        if (messageTimestamp <= timestamp ) {
                            message.setStatus(MessageStatus.BMSG_STATUS_RECEIVED_READ.ordinal());
                            messageAdapter.updateMessage(message);
                        }
                    }
                }
            });
        }

        @Override
        public void OnRecallMessageNotify(ContextUtils.MessageContent msgContent) {
            Log.e("yjj", "OnRecallMessageNotify messageId:" + msgContent.getMessageId());
            runOnUiThread(() -> {
                if (msgContent.getMsgType() == MessageType.BMSG_TYPE_RECALL) {
                    String recalledMessageId = msgContent.getMessageId();
                    for (Message existingMessage : messageAdapter.getMessages()) {
                        if (existingMessage.getMessageId().equals(recalledMessageId)) {
                            if (existingMessage.getType() == MessageType.BMSG_TYPE_VOICE.ordinal()) {
                                AopaImMedia.getInstance().stopPlaying();
                            }

                            existingMessage.setContent("消息已撤回");
                            existingMessage.setRecalled(true);  // 设置撤回状态
                            messageAdapter.updateMessage(existingMessage);
                            messageAdapter.notifyDataSetChanged();  // 强制刷新列表
                            ChatUtil.showToast(ChatActivity.this, "对方撤回了一条消息");
                            break;
                        }
                    }
                }
            });
        }

        @Override
        public void OnCmdMessageNotify(ContextUtils.MessageContent msgContent) {
        }

        @Override
        public void OnUnreadCountNotify(int type, int target_id, int unread_count) {
            runOnUiThread(() -> {
                updateUnreadCount();
            });
        }

        @Override
        public void OnTypingStatusChanged(int type, int target_id) {
            runOnUiThread(() -> {
                ChatUtil.showToast(ChatActivity.this, target_id + ":正在输入");
                Log.e("yjj", "OnTypingStatusChanged" + type + ",target_id:" + target_id);
            });
        }

        @Override
        public void OnNotification(String payload) {
        }

        @Override
        public void OnOnlineMsg(String payload) {
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();

        stopAllOngoingOperations();
        typingHandler.removeCallbacksAndMessages(null);
    }
}