package com.aopa.imexamples;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import org.webrtc.ContextUtils;
import java.util.ArrayList;
import java.util.List;

public class ConversationAdapter extends RecyclerView.Adapter<ConversationAdapter.ViewHolder> {

    private List<ContextUtils.Conversation> conversations = new ArrayList<>();
    private OnConversationClickListener listener;

    public interface OnConversationClickListener {
        void onConversationClick(ContextUtils.Conversation conversation);
    }

    public ConversationAdapter(OnConversationClickListener listener) {
        this.listener = listener;
    }

    public void setConversations(List<ContextUtils.Conversation> conversations) {
        this.conversations = conversations;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_conversation, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        ContextUtils.Conversation conversation = conversations.get(position);
        
        // 设置会话类型
        String type = conversation.getType() == 1 ? "私聊" : "群聊";
        holder.tvType.setText(type);
        
        // 设置目标ID
        holder.tvName.setText(String.valueOf(conversation.getTargetId()));
        
        // 设置最后一条消息
        if (conversation.getLastMessage() != null) {
            String lastMsg = conversation.getLastMessage().getContent();
            holder.tvLastMessage.setText(lastMsg);
        }
        
        // 设置未读消息数
        int unreadCount = conversation.getUnreadCount();
        if (unreadCount > 0) {
            holder.tvUnreadCount.setVisibility(View.VISIBLE);
            holder.tvUnreadCount.setText(String.valueOf(unreadCount));
        } else {
            holder.tvUnreadCount.setVisibility(View.GONE);
        }

        holder.itemView.setOnClickListener(v -> {
            if (listener != null) {
                listener.onConversationClick(conversation);
            }
        });
    }

    @Override
    public int getItemCount() {
        return conversations.size();
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        TextView tvType;
        TextView tvName;
        TextView tvLastMessage;
        TextView tvUnreadCount;

        ViewHolder(View view) {
            super(view);
            tvType = view.findViewById(R.id.tvType);
            tvName = view.findViewById(R.id.tvName);
            tvLastMessage = view.findViewById(R.id.tvLastMessage);
            tvUnreadCount = view.findViewById(R.id.tvUnreadCount);
        }
    }
}