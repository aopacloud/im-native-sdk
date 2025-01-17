package com.aopa.imexamples;

import android.os.Build;
import android.text.TextUtils;
import android.util.Log;

import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.util.Base64;

import javax.crypto.Cipher;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;

public class IMTokenManager {
    private static final String TAG = "IMTokenManager";

    public interface TokenCallback {
        void onSuccess(String token);
        void onError(String error);
    }

    /**
     * 获取主机和端口
     *
     * @param url 完整的 URL
     * @return 主机和端口部分，例如 "example.com:8080"
     */
    public static String getHostAndPort(String url) {
        if (TextUtils.isEmpty(url)) {
            return "";
        }

        try {
            String protocol = "";
            if (url.startsWith("ws://") || url.startsWith("http://")) {
                protocol = url.startsWith("ws://") ? "ws://" : "http://";
            } else if (url.startsWith("wss://") || url.startsWith("https://")) {
                protocol = url.startsWith("wss://") ? "wss://" : "https://";
            } else {
                return "";
            }

            int start = url.indexOf(protocol) + protocol.length();
            int end = url.indexOf("/", start);
            if (end == -1) {
                return url.substring(start);
            }
            return url.substring(start, end);
        } catch (Exception e) {
            Log.e("TAG", "Error parsing URL: " + e.getMessage());
            return "";
        }
    }

    /**
     * 发送 POST 请求（同步方法，只能在子线程调用）
     *
     * @param url      请求的 URL
     * @param postData POST 请求的数据
     * @return 服务器返回的响应字符串
     */
    private static String sendPostRequestSync(String url, String postData) {
        final Object lock = new Object();
        final String[] result = new String[1];
        final String[] error = new String[1];

        new Thread(() -> {
            synchronized (lock) {
                try {
                    // 创建 URL 连接
                    URL apiUrl = new URL(url);
                    HttpURLConnection conn = (HttpURLConnection) apiUrl.openConnection();
                    conn.setRequestMethod("POST");
                    conn.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
                    conn.setDoOutput(true);
                    conn.setConnectTimeout(15000);
                    conn.setReadTimeout(15000);

                    // 写入请求数据
                    try (OutputStream os = conn.getOutputStream()) {
                        byte[] input = postData.getBytes(StandardCharsets.UTF_8);
                        os.write(input, 0, input.length);
                    }

                    // 获取响应
                    StringBuilder response = new StringBuilder();
                    try (InputStream is = conn.getInputStream();
                         BufferedReader br = new BufferedReader(new InputStreamReader(is, StandardCharsets.UTF_8))) {
                        String line;
                        while ((line = br.readLine()) != null) {
                            response.append(line);
                        }
                    }

                    // 返回响应数据
                    result[0] = response.toString();
                } catch (Exception e) {
                    Log.e(TAG, "Error sending POST request: " + e.getMessage());
                    error[0] = e.getMessage();
                } finally {
                    lock.notify(); // 通知等待的线程
                }
            }
        }).start();

        synchronized (lock) {
            try {
                lock.wait(); // 等待结果
            } catch (InterruptedException e) {
                Log.e(TAG, "Thread interrupted", e);
                error[0] = "Thread interrupted";
            }
        }

        if (error[0] != null) {
            throw new RuntimeException(error[0]);
        }

        return result[0];
    }

    /**
     * 解析 JSON 响应并获取指定字段的值
     *
     * @param response JSON 响应字符串
     * @param key      要获取的字段名
     * @return 字段的值，如果不存在则返回 null
     */
    private static String parseJsonResponse(String response, String key) {
        try {
            JSONObject jsonResponse = new JSONObject(response);
            if (jsonResponse.has(key)) {
                return jsonResponse.getString(key);
            }
        } catch (Exception e) {
            Log.e(TAG, "Error parsing JSON response: " + e.getMessage());
        }
        return null;
    }

    /**
     * 创建群组
     *
     * @param groupId     群组 ID
     * @param groupName   群组名称
     * @param headImgUrl  群组头像 URL
     * @param userId      用户 ID
     * @param memberList  成员列表
     * @param appId       应用 ID
     * @param wsUrl       WebSocket URL
     * @return 服务器返回的响应代码
     */
    
    public static String getGroup(String groupId, String groupName, String headImgUrl, String userId, String[] memberList, String appId, String wsUrl) {
        try {
            // 获取主机和端口
            String hostAndPort = getHostAndPort(wsUrl);
            if (TextUtils.isEmpty(hostAndPort)) {
                return "";
            }

            // 根据输入URL的协议类型决定HTTP请求的协议
            String httpProtocol = wsUrl.startsWith("wss://") || wsUrl.startsWith("https://") ?
                    "http://" : "http://";

            // 构建完整的URL
            String url = httpProtocol + hostAndPort + "/imapi/group/create";

            StringBuilder postDataBuilder = new StringBuilder();
            postDataBuilder.append("groupId=").append(groupId)
                    .append("&groupName=").append(groupName)
                    .append("&headImgUrl=").append(headImgUrl)
                    .append("&userId=").append(userId)
                    .append("&appId=").append(appId);

            // 添加 memberList 中的每个成员
            for (String member : memberList) {
                postDataBuilder.append("&member=").append(member);
            }

            String postData = postDataBuilder.toString();
            Log.e("TAG", "postData:" + postData);
            // 发送 POST 请求
            String response = sendPostRequestSync(url, postData);
            if (response != null) {
                return parseJsonResponse(response, "code");
            }
        } catch (Exception e) {
            Log.e("TAG", "Error getting token: " + e.getMessage());
        }
        return "";
    }
    
    public static String dismissGroup(String groupId,  String userId, String appId, String wsUrl) {
        try {
            // 获取主机和端口
            String hostAndPort = getHostAndPort(wsUrl);
            if (TextUtils.isEmpty(hostAndPort)) {
                return "";
            }

            // 根据输入URL的协议类型决定HTTP请求的协议
            String httpProtocol = wsUrl.startsWith("wss://") || wsUrl.startsWith("https://") ?
                    "http://" : "http://";

            // 构建完整的URL
            String url = httpProtocol + hostAndPort + "/imapi/group/dismiss";

            StringBuilder postDataBuilder = new StringBuilder();
            postDataBuilder.append("groupId=").append(groupId)
                    .append("&userId=").append(userId)
                    .append("&appId=").append(appId);

            String postData = postDataBuilder.toString();
            Log.e("TAG", "postData:" + postData);
            // 发送 POST 请求
            String response = sendPostRequestSync(url, postData);
            if (response != null) {
                return parseJsonResponse(response, "code");
            }
        } catch (Exception e) {
            Log.e("TAG", "Error getting token: " + e.getMessage());
        }
        return "";
    }

    /**
     * 获取用户 Token
     *
     * @param userId 用户 ID
     * @param wsUrl  WebSocket URL
     * @return 服务器返回的 Token
     */
    public static String getTokenEnvTest(String userId, String wsUrl) {
        try {
            // 获取主机和端口
            String hostAndPort = getHostAndPort(wsUrl);
            if (TextUtils.isEmpty(hostAndPort)) {
                return "";
            }

            // 根据输入URL的协议类型决定HTTP请求的协议
            String httpProtocol = wsUrl.startsWith("wss://") || wsUrl.startsWith("https://") ?
                    "http://" : "http://";

            // 构建完整的URL
            String url = httpProtocol + hostAndPort + "/imapi/user/add";

            // 构建请求参数
            String postData = String.format("userId=%s&name=yangjunandroid&portraitUri=%s&appId=66",
                    userId,
                    "http://xs-image.im-ee.com/202303/27/816221207_64213beec639c0.97786485.jpg");

            // 发送 POST 请求
            String response = sendPostRequestSync(url, postData);
            if (response != null) {
                return parseJsonResponse(response, "token");
            }
        } catch (Exception e) {
            Log.e("TAG", "Error getting token: " + e.getMessage());
        }
        return "";
    }

    /**
     * 获取 Token（带加密和环境参数）
     *
     * @param appId       应用 ID
     * @param userId      用户 ID
     * @param serverUrl   服务器 URL
     * @param redirectUrl 重定向 URL
     * @return 服务器返回的 Token
     */
    public static String getTokenEnvFormat(String appId, String userId, String serverUrl, String redirectUrl) {
        try {
            // 1. 生成随机字符串
            String randomStr = generateRandomString(16);
            Log.d(TAG, "Random string: " + randomStr);

            // 2. 加密数据
            String encryptedText = encryptData("Hello, World!", randomStr);
            Log.d(TAG, "Encrypted text: " + encryptedText);

            // 3. 构建请求参数
            String postData = String.format("im_secret_public=%s" +
                            "&im_random_iv=%s" +
                            "&im_request_address=%s" +
                            "&userId=%s" +
                            "&name=%s" +
                            "&portraitUri=%s" +
                            "&appId=%s",
                    URLEncoder.encode(encryptedText, "UTF-8"),
                    URLEncoder.encode(randomStr, "UTF-8"),
                    URLEncoder.encode(redirectUrl, "UTF-8"),
                    URLEncoder.encode(userId, "UTF-8"),
                    URLEncoder.encode("yangjun1", "UTF-8"),
                    URLEncoder.encode("https://rtc-resouce.oss-ap-southeast-1.aliyuncs.com/github_pic/11.png", "UTF-8"),
                    URLEncoder.encode(appId, "UTF-8"));

            Log.d(TAG, "Request data: " + postData);

            // 4. 发送 POST 请求
            String response = sendPostRequestSync(serverUrl, postData);
            if (response != null) {
                return parseJsonResponse(response, "token");
            }
        } catch (Exception e) {
            Log.e(TAG, "Error getting token: " + e.getMessage());
        }
        return "";
    }

    /**
     * 生成随机字符串
     *
     * @param length 字符串长度
     * @return 随机字符串
     */
    private static String generateRandomString(int length) {
        String chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        SecureRandom random = new SecureRandom();
        StringBuilder sb = new StringBuilder(length);
        for (int i = 0; i < length; i++) {
            sb.append(chars.charAt(random.nextInt(chars.length())));
        }
        return sb.toString();
    }

    /**
     * 加密数据
     *
     * @param plainText  明文数据
     * @param randomStr  随机字符串（用于初始化向量）
     * @return 加密后的 Base64 编码字符串
     */
    private static String encryptData(String plainText, String randomStr) {
        try {
            byte[] keyBytes = "my32lengthsupersecretnooneknows1".getBytes(StandardCharsets.UTF_8);
            byte[] ivBytes = randomStr.getBytes(StandardCharsets.UTF_8);

            SecretKeySpec secretKey = new SecretKeySpec(keyBytes, "AES");
            IvParameterSpec iv = new IvParameterSpec(ivBytes);

            Cipher cipher = Cipher.getInstance("AES/CTR/NoPadding");
            cipher.init(Cipher.ENCRYPT_MODE, secretKey, iv);

            byte[] encrypted = cipher.doFinal(plainText.getBytes());
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                return Base64.getEncoder().encodeToString(encrypted);
            } else {
                return android.util.Base64.encodeToString(encrypted, android.util.Base64.NO_WRAP);
            }
        } catch (Exception e) {
            Log.e(TAG, "Encryption error: " + e.getMessage());
            return "";
        }
    }


    /**
 * 加入群组
 *
 * @param userIds    要加入的用户ID数组
 * @param groupId    群组ID
 * @param groupName  群组名称
 * @param appId      应用ID
 * @param wsUrl      WebSocket URL
 * @return 服务器返回的响应代码，成功返回"200"
 */
public static String joinGroup(String[] userIds, String groupId, String groupName, String appId, String wsUrl) {
        try {
            // 获取主机和端口
            String hostAndPort = getHostAndPort(wsUrl);
            if (TextUtils.isEmpty(hostAndPort)) {
                return "";
            }

            // 根据输入URL的协议类型决定HTTP请求的协议
            String httpProtocol = wsUrl.startsWith("wss://") || wsUrl.startsWith("https://") ? 
                    "http://" : "http://";

            // 构建完整的URL
            String url = httpProtocol + hostAndPort + "/imapi/group/join";

            // 构建请求参数
            StringBuilder postDataBuilder = new StringBuilder();
            
            // 添加多个userId
            for (String userId : userIds) {
                if (postDataBuilder.length() > 0) {
                    postDataBuilder.append("&");
                }
                postDataBuilder.append("userId=").append(URLEncoder.encode(userId, "UTF-8"));
            }
            
            // 添加其他参数
            postDataBuilder.append("&groupId=").append(groupId)
                        .append("&groupName=").append(URLEncoder.encode(groupName, "UTF-8"))
                        .append("&appId=").append(URLEncoder.encode(appId, "UTF-8"));

            String postData = postDataBuilder.toString();
            Log.d(TAG, "Join group request data: " + postData);

            // 发送POST请求
            String response = sendPostRequestSync(url, postData);
            if (response != null) {
                return parseJsonResponse(response, "code");
            }
        } catch (Exception e) {
            Log.e(TAG, "Error joining group: " + e.getMessage());
        }
        return "";
    }
}