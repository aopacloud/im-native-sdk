package com.aopa.imexamples;

import static org.webrtc.ContextUtils.*;
import static org.webrtc.ContextUtils.MessageStatus.*;
import static org.webrtc.ContextUtils.MessageType.*;

import android.content.Context;
import android.graphics.Color;
import android.net.Uri;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;

import org.webrtc.ContextUtils;
import org.webrtc.Message;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

public class MessageAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> {
    private Context context;
    private List<Message> messages = new ArrayList<>();
    private OnMessageClickListener listener;

    private static final int VIEW_TYPE_SEND_TEXT = 0;
    private static final int VIEW_TYPE_RECEIVE_TEXT = 1;
    private static final int VIEW_TYPE_SEND_IMAGE = 2;
    private static final int VIEW_TYPE_RECEIVE_IMAGE = 3;
    private static final int VIEW_TYPE_SEND_AUDIO = 4;
    private static final int VIEW_TYPE_RECEIVE_AUDIO = 5;

    public MessageAdapter(Context context, OnMessageClickListener listener) {
        this.context = context;
        this.listener = listener;
    }

    public List<Message> getMessages() {
        return messages;
    }

    public void addMessage(Message message) {
        messages.add(message);
        notifyItemInserted(messages.size() - 1);
    }

    public void removeMessage(Message message) {
        int position = messages.indexOf(message);
        if (position != -1) {
            messages.remove(position);
            notifyItemRemoved(position);
        }
    }

    public void updateMessage(Message message) {
        int position = messages.indexOf(message);
        if (position != -1) {
            notifyItemChanged(position);
        }
    }

    @Override
    public int getItemViewType(int position) {
        Message message = messages.get(position);
        int type = message.getType();
        if (message.getDirection() == DirectionType.BMSG_DIRECTION_SEND.ordinal()) {
            switch (MessageType.values()[type]) {
                case BMSG_TYPE_IMAGE:
                    return VIEW_TYPE_SEND_IMAGE;
                case BMSG_TYPE_VOICE:
                    return VIEW_TYPE_SEND_AUDIO;
                default:
                    return VIEW_TYPE_SEND_TEXT;
            }
        } else {
            switch (MessageType.values()[type]) {
                case BMSG_TYPE_IMAGE:
                    return VIEW_TYPE_RECEIVE_IMAGE;
                case BMSG_TYPE_VOICE:
                    return VIEW_TYPE_RECEIVE_AUDIO;
                default:
                    return VIEW_TYPE_RECEIVE_TEXT;
            }
        }
    }


    @NonNull
    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        LayoutInflater inflater = LayoutInflater.from(parent.getContext());
        switch (viewType) {
            case VIEW_TYPE_SEND_TEXT:
                return new TextMessageViewHolder(
                    inflater.inflate(R.layout.item_message_send_text, parent, false)
                );
            case VIEW_TYPE_RECEIVE_TEXT:
                return new TextMessageViewHolder(
                    inflater.inflate(R.layout.item_message_receive_text, parent, false)
                );
            case VIEW_TYPE_SEND_IMAGE:
                return new ImageMessageViewHolder(
                    inflater.inflate(R.layout.item_message_send_image, parent, false)
                );
            case VIEW_TYPE_RECEIVE_IMAGE:
                return new ImageMessageViewHolder(
                    inflater.inflate(R.layout.item_message_receive_image, parent, false)
                );
            case VIEW_TYPE_SEND_AUDIO:
                return new AudioMessageViewHolder(
                    inflater.inflate(R.layout.item_message_send_audio, parent, false)
                );
            case VIEW_TYPE_RECEIVE_AUDIO:
                return new AudioMessageViewHolder(
                    inflater.inflate(R.layout.item_message_receive_audio, parent, false)
                );
            default:
                return new TextMessageViewHolder(
                    inflater.inflate(R.layout.item_message_send_text, parent, false)
                );
        }
    }

    @Override
    public void onBindViewHolder(@NonNull RecyclerView.ViewHolder holder, int position) {
        Message message = messages.get(position);
        if (holder instanceof ImageMessageViewHolder) {
            ((ImageMessageViewHolder) holder).bind(message);
        } else if (holder instanceof AudioMessageViewHolder) {
            ((AudioMessageViewHolder) holder).bind(message);
        } else {
            ((TextMessageViewHolder) holder).bind(message);
        }
    }

    @Override
    public int getItemCount() {
        return messages.size();
    }

    class TextMessageViewHolder extends RecyclerView.ViewHolder {
        private TextView contentText;
        private TextView statusText; // 改为 TextView
        private TextView recallText;

        TextMessageViewHolder(@NonNull View itemView) {
            super(itemView);
            contentText = itemView.findViewById(R.id.contentText);
            //statusIcon = itemView.findViewById(R.id.statusIcon);
            statusText = itemView.findViewById(R.id.statusText); // 修改 ID
            recallText = itemView.findViewById(R.id.recallText);

            itemView.setOnClickListener(v -> {
                int position = getAdapterPosition();
                if (position != RecyclerView.NO_POSITION && listener != null) {
                    listener.onMessageClick(messages.get(position));
                }
            });
        }

        void bind(Message message) {
            if (message.isRecalled()) {
                contentText.setVisibility(View.GONE);
                statusText.setVisibility(View.GONE);
                recallText.setVisibility(View.VISIBLE);
                recallText.setText("文字已撤回");

                itemView.setClickable(false);
                itemView.setEnabled(false);
            }else {
                contentText.setVisibility(View.VISIBLE);
                statusText.setVisibility(View.VISIBLE);
                recallText.setVisibility(View.GONE);

                itemView.setClickable(true);
                itemView.setEnabled(true);

                contentText.setText(message.getUserId() + ":"+message.getContent());
                if (message.getDirection() == DirectionType.BMSG_DIRECTION_SEND.ordinal()) {
                    updateStatus(statusText, message.getStatus());
                }
            }
        }
    }

    class ImageMessageViewHolder extends RecyclerView.ViewHolder {
        private ImageView messageImage;
        private TextView statusText;
        private TextView recallText;

        ImageMessageViewHolder(@NonNull View itemView) {
            super(itemView);
            messageImage = itemView.findViewById(R.id.messageImage);
            statusText = itemView.findViewById(R.id.statusText);
            recallText = itemView.findViewById(R.id.recallText);

            itemView.setOnClickListener(v -> {
                int position = getAdapterPosition();
                if (position != RecyclerView.NO_POSITION && listener != null) {
                    listener.onMessageClick(messages.get(position));
                }
            });
        }

        void bind(Message message) {
            if (message.isRecalled()) {
                messageImage.setVisibility(View.GONE);
                statusText.setVisibility(View.GONE);
                recallText.setVisibility(View.VISIBLE);
                recallText.setText("图片已撤回");

                itemView.setClickable(false);
                itemView.setEnabled(false);
            }else{
                messageImage.setVisibility(View.VISIBLE);
                statusText.setVisibility(View.VISIBLE);
                recallText.setVisibility(View.GONE);
                
                itemView.setClickable(true);
                itemView.setEnabled(true);

                // 处理本地文件路径
                String imagePath = message.getContent();
                Uri imageUri;
                if (imagePath.startsWith("http://") || imagePath.startsWith("https://") || imagePath.startsWith("content://")) {
                    // 网络图片
                    imageUri = Uri.parse(imagePath);
                } else {
                    // 本地文件
                    imageUri = Uri.fromFile(new File(imagePath));
                }

                Glide.with(context)
                        .load(imageUri)
                        .into(messageImage);

                if(message.getDirection() == DirectionType.BMSG_DIRECTION_SEND.ordinal()) {
                    updateStatus(statusText, message.getStatus());
                }
           }
        }
    }

    class AudioMessageViewHolder extends RecyclerView.ViewHolder {
        private ImageView audioIcon;
        private TextView durationText;
        private TextView statusText;
        private TextView recallText;

        AudioMessageViewHolder(@NonNull View itemView) {
            super(itemView);
            audioIcon = itemView.findViewById(R.id.audioIcon);
            durationText = itemView.findViewById(R.id.durationText);
            statusText = itemView.findViewById(R.id.statusText);
            recallText = itemView.findViewById(R.id.recallText);

            itemView.setOnClickListener(v -> {
                int position = getAdapterPosition();
                if (position != RecyclerView.NO_POSITION && listener != null) {
                    listener.onMessageClick(messages.get(position));
                }
            });
        }

        void bind(Message message) {
            if (message.isRecalled()) {
                audioIcon.setVisibility(View.GONE);
                durationText.setVisibility(View.GONE);
                statusText.setVisibility(View.GONE);
                recallText.setVisibility(View.VISIBLE);
                recallText.setText("语音已撤回");

                itemView.setClickable(false);
                itemView.setEnabled(false);
            }else{
                audioIcon.setVisibility(View.VISIBLE);
                durationText.setVisibility(View.VISIBLE);
                statusText.setVisibility(View.VISIBLE);
                recallText.setVisibility(View.GONE);
                itemView.setClickable(true);
                itemView.setEnabled(true);

                durationText.setText(formatDuration(message.getDuration()));
                if(message.getDirection() == DirectionType.BMSG_DIRECTION_SEND.ordinal()) {
                    updateStatus(statusText, message.getStatus());
                }
            }
        }
    }

    private void updateStatus(TextView statusText, int status) {
        String statusStr;
        switch (MessageStatus.values()[status]) {
            case BMSG_STATUS_SENDING:
                statusStr = "发送中";
                break;
            case BMSG_STATUS_SENT:
                statusStr = "已发送";
                break;
            case BMSG_STATUS_RECEIVED:
                statusStr = "已收到";
                break;
            case BMSG_STATUS_FAILED:
                statusStr = "发送失败";
                break;
            case BMSG_STATUS_READ:
                statusStr = "已送达";
                break;
            case BMSG_STATUS_RECEIVED_READ:
                statusStr = "对方已读";
                break;
            case BMSG_STATUS_DELETE:
                statusStr = "已删除";
                break;
            case BMSG_STATUS_DESTROYED:
                statusStr = "已销毁";
                break;
            default:
                statusStr = "";
        }
        statusText.setText(statusStr);
        statusText.setVisibility(statusStr.isEmpty() ? View.GONE : View.VISIBLE);
    }
    private String formatDuration(long seconds) {
        return String.format("%d\"", seconds);
    }

    public interface OnMessageClickListener {
        void onMessageClick(Message message);
    }
}