    package com.aopa.imexamples;

    import androidx.annotation.NonNull;
    import androidx.annotation.Nullable;
    import androidx.appcompat.app.AppCompatActivity;
    import androidx.core.app.ActivityCompat;
    import androidx.core.content.ContextCompat;

    import android.Manifest;
    import android.content.Intent;
    import android.content.pm.PackageManager;
    import android.net.Uri;
    import android.os.Build;
    import android.os.Bundle;
    import android.os.Environment;
    import android.provider.Settings;
    import android.view.View;
    import android.widget.ArrayAdapter;
    import android.widget.AutoCompleteTextView;
    import android.widget.Button;
    import android.widget.ScrollView;
    import android.widget.TextView;
    import android.widget.Toast;

    import com.aopa.imsdk.AopaImEngine;
    import com.aopa.imsdk.AopaImMedia;
    import com.google.android.material.snackbar.Snackbar;
    import com.google.android.material.textfield.TextInputEditText;

    import org.webrtc.ContextUtils;

    import java.util.ArrayList;
    import java.util.List;
    import static org.webrtc.ContextUtils.ServerType;
    
    public class LoginActivity extends AppCompatActivity {
        private static final int PERMISSION_REQUEST_CODE = 1;
        private static final int MANAGE_STORAGE_PERMISSION_REQUEST_CODE = 2;
        private static final int REQUEST_CODE_CHAT = 11;

        private AutoCompleteTextView spinnerChatType;
        private AutoCompleteTextView spinnerServerType;
        private int selectedChatType = ContextUtils.ConversationType.BMSG_GROUP_CHAT.ordinal();
        private int selectedServerType = ServerType.BMSG_DOMESTIC_TEST.ordinal();
        

        private int appid = XXXX;//请联系aopa im团队获取appid
        private View rootView;
        
        private TextInputEditText etLocalUserId;
        private TextInputEditText etRemoteUserId;

        @Override
        protected void onCreate(Bundle savedInstanceState) {
            super.onCreate(savedInstanceState);
            setContentView(R.layout.activity_login);
            rootView = findViewById(android.R.id.content);
            
            // 初始化界面
            initLogView();
            initUI();
            
            checkAndRequestPermissions();
        }

        private void initUI() {
            etLocalUserId = findViewById(R.id.etLocalUserId);
            etRemoteUserId = findViewById(R.id.etRemoteUserId);
            spinnerChatType = findViewById(R.id.spinnerChatType);
            spinnerServerType = findViewById(R.id.spinnerServerType);
            etLocalUserId.setText("1234561");  // 设置本地用户ID默认值
            etRemoteUserId.setText("1234562"); // 设置远程用户ID默认值

            // 设置聊天类型下拉菜单
            String[] chatTypes = {"未定义","私聊", "群聊", "聊天室"};
            ArrayAdapter<String> chatTypeAdapter = new ArrayAdapter<>(
                this,
                    android.R.layout.simple_dropdown_item_1line,
                    chatTypes
            );
            spinnerChatType.setAdapter(chatTypeAdapter);
            
            // 设置服务器类型下拉菜单
            String[] serverTypes = { "测试国内", "正式国内", "测试海外","正式海外"};
            ArrayAdapter<String> serverTypeAdapter = new ArrayAdapter<>(
                this,
                    android.R.layout.simple_dropdown_item_1line,
                    serverTypes
            );
            spinnerServerType.setAdapter(serverTypeAdapter);
            
            // 设置默认选项
            spinnerChatType.setText(chatTypes[2], false);
            spinnerServerType.setText(serverTypes[0], false);
            
            // 处理聊天类型选择
            spinnerChatType.setOnItemClickListener((parent, view, position, id) -> {
                selectedChatType = position;
            });
            
            // 处理服务器类型选择
            spinnerServerType.setOnItemClickListener((parent, view, position, id) -> {
                selectedServerType = position;
            });

            findViewById(R.id.btnLogin).setOnClickListener(v -> onLogin());
            findViewById(R.id.btnLogout).setOnClickListener(v -> onLogout());
        }

        private void initLogView() {
            View logContainer = findViewById(R.id.logContainer);
            TextView tvLog = findViewById(R.id.tvLog);
            ScrollView scrollView = findViewById(R.id.scrollView);
            Button btnShowLog = findViewById(R.id.btnShowLog);
        }

        private void onLogin() {
            // 获取输入的用户ID
            String localUserIdStr = etLocalUserId.getText().toString().trim();
            String remoteUserIdStr = etRemoteUserId.getText().toString().trim();
            if (localUserIdStr.isEmpty() || remoteUserIdStr.isEmpty()) {
                showToast("请输入用户ID");
                return;
            }
            
            int localUserId = Integer.parseInt(localUserIdStr);
            int remoteUserId = Integer.parseInt(remoteUserIdStr);

            if (localUserId < 100000 || remoteUserId < 100000) {
                showToast("id 不能少于6位");
                return;
            }
            
            showLoading("正在登录...");
            

            String serverUrl;
            switch(selectedServerType) {
                case 0: // BMSG_DOMESTIC_TEST
                    serverUrl = "ws://115.29.215.193:6080/imgate/ws/connect";
                    break;
                case 1: // BMSG_DOMESTIC_FORMAL
                    serverUrl = "wss://im-gate.aopacloud.net:6511/ws/connect";
                    break;
                case 2: // BMSG_OVERSEA_TEST
                    serverUrl = "ws://115.29.215.193:6080/imgate/ws/connect";
                    break;
                case 3: // BMSG_OVERSEA_FORMAL
                    serverUrl = "wss://im-api.aopa.com/imgate/ws/connect";
                    break;
                default:
                    serverUrl = "ws://115.29.215.193:6080/imgate/ws/connect"; // 默认使用测试服务器
                    break;
            }
            
            Intent intent = new Intent(this, ConversationListActivity.class);
            intent.putExtra("remote_user_id", remoteUserIdStr);
            intent.putExtra("appid", appid);
            intent.putExtra("localUserId", localUserIdStr);
            intent.putExtra("chatType", selectedChatType);
            intent.putExtra("serverType", selectedServerType);
            intent.putExtra("serverUrl", serverUrl);
            startActivityForResult(intent, REQUEST_CODE_CHAT); 
        }


        @Override
        protected void onNewIntent(Intent intent) {
            super.onNewIntent(intent);
            setIntent(intent);
        }

        private void onLogout() {
            showLoading("正在登出...");
            try {
                
            } catch (Exception e) {
                e.printStackTrace();
            } finally {
                showToast("已登出");
            }
        }

        private void checkAndRequestPermissions() {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                if (!Environment.isExternalStorageManager()) {
                    try {
                        Intent intent = new Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION);
                        intent.addCategory("android.intent.category.DEFAULT");
                        intent.setData(Uri.parse(String.format("package:%s", getPackageName())));
                        startActivityForResult(intent, MANAGE_STORAGE_PERMISSION_REQUEST_CODE);
                    } catch (Exception e) {
                        Intent intent = new Intent();
                        intent.setAction(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION);
                        startActivityForResult(intent, MANAGE_STORAGE_PERMISSION_REQUEST_CODE);
                    }
                } else {
                    checkAndRequestAudioPermission();
                }
            } else {
                List<String> permissions = new ArrayList<>();
                permissions.add(Manifest.permission.RECORD_AUDIO);
                permissions.add(Manifest.permission.WRITE_EXTERNAL_STORAGE);
                permissions.add(Manifest.permission.READ_EXTERNAL_STORAGE);

                List<String> permissionsToRequest = new ArrayList<>();
                for (String permission : permissions) {
                    if (ContextCompat.checkSelfPermission(this, permission)
                            != PackageManager.PERMISSION_GRANTED) {
                        permissionsToRequest.add(permission);
                    }
                }

                if (!permissionsToRequest.isEmpty()) {
                    ActivityCompat.requestPermissions(this,
                            permissionsToRequest.toArray(new String[0]),
                            PERMISSION_REQUEST_CODE);
                }
            }
        }

        private void checkAndRequestAudioPermission() {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO)
                    != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(this,
                        new String[]{Manifest.permission.RECORD_AUDIO},
                        PERMISSION_REQUEST_CODE);
            }
        }

        @Override
        protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
            super.onActivityResult(requestCode, resultCode, data);
            if (requestCode == MANAGE_STORAGE_PERMISSION_REQUEST_CODE) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    if (Environment.isExternalStorageManager()) {
                        checkAndRequestAudioPermission();
                    } else {
                        showToast("存储权限被拒绝");
                    }
                }
            }
        }

        @Override
        public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions,
                                            @NonNull int[] grantResults) {
            super.onRequestPermissionsResult(requestCode, permissions, grantResults);
            if (requestCode == PERMISSION_REQUEST_CODE) {
                boolean allGranted = true;
                for (int result : grantResults) {
                    if (result != PackageManager.PERMISSION_GRANTED) {
                        allGranted = false;
                        break;
                    }
                }
                showToast(allGranted ? "已获得所需权限" : "部分权限被拒绝");
            }
        }


        private void showToast(String message) {
            Toast.makeText(this, message, Toast.LENGTH_SHORT).show();
        }

        private void showLoading(String message) {
            Snackbar.make(rootView, message, Snackbar.LENGTH_SHORT).show();
        }

    }