package com.aopa.imexamples;

import android.content.Context;
import android.net.Uri;
import android.util.Log;
import android.widget.ImageView;
import android.widget.Toast;

import com.bumptech.glide.Glide;
import com.google.android.material.dialog.MaterialAlertDialogBuilder;

import org.webrtc.ContextUtils;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.util.Random;

public class ChatUtil {

    private static final String TAG = "ChatUtil";

    /**
     * 显示 Toast 消息
     */
    public static void showToast(Context context, String message) {
        Toast.makeText(context, message, Toast.LENGTH_SHORT).show();
    }

    /**
     * 显示图片查看器
     */
    public static void showImageViewer(Context context, String imageUrl) {
        ImageView imageView = new ImageView(context);
        imageView.setAdjustViewBounds(true);

        Glide.with(context)
                .load(Uri.parse(imageUrl))
                .into(imageView);

        new MaterialAlertDialogBuilder(context)
                .setView(imageView)
                .show();
    }

    /**
     * 生成 10 位随机数字字符串
     */
    public static String generateRandomNumber() {
        Random random = new Random();
        StringBuilder sb = new StringBuilder(10);

        for (int i = 0; i < 10; i++) {
            sb.append(random.nextInt(10)); // 生成 0-9 的随机数字
        }

        return sb.toString();
    }

    /**
     * 从 InputStream 读取字节数据
     */
    public static byte[] getBytes(InputStream inputStream) throws Exception {
        ByteArrayOutputStream byteBuffer = new ByteArrayOutputStream();
        int bufferSize = 10 * 1024 * 1024; // 10MB buffer
        byte[] buffer = new byte[bufferSize];
        int len;
        while ((len = inputStream.read(buffer)) != -1) {
            byteBuffer.write(buffer, 0, len);
        }
        return byteBuffer.toByteArray();
    }

    /**
     * 获取聊天类型
     */
    public static ContextUtils.ConversationType getChatType(int chatType) {
        switch (chatType) {
            case 0: // BMSG_DOMESTIC_TEST
                return ContextUtils.ConversationType.BMSG_MSG_TYPE_UNIVERSAL;
            case 1: // BMSG_DOMESTIC_FORMAL
                return ContextUtils.ConversationType.BMSG_PRIVATE_CHAT;
            case 2: // BMSG_OVERSEA_TEST
                return ContextUtils.ConversationType.BMSG_GROUP_CHAT;
            case 3: // BMSG_OVERSEA_FORMAL
                return ContextUtils.ConversationType.BMSG_ROOM_CHAT;
            default:
                return ContextUtils.ConversationType.BMSG_PRIVATE_CHAT;
        }
    }
}