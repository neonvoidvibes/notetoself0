import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var currentInput: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    ForEach(viewModel.messages, id: \.id) { message in
                        ChatMessageBubble(message: message)
                            .id(message.id)
                    }
                }
                .onChange(of: viewModel.messages.count) { oldValue, newValue in
                    if let lastID = viewModel.messages.last?.id {
                        withAnimation {
                            scrollProxy.scrollTo(lastID, anchor: .bottom)
                        }
                    }
                }
            }
            // New Chat Input Container
            VStack(spacing: 0) {
                // Multiline TextEditor for input with transparent background
                TextEditor(text: $currentInput)
                    .font(UIStyles.bodyFont)
                    .foregroundColor(.white)
                    .background(Color.clear)
                    .frame(minHeight: 40, maxHeight: 100) // Expands up to approx 3 rows
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                HStack {
                    Spacer()
                    Button(action: {
                        let trimmed = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        viewModel.sendMessage(trimmed)
                        currentInput = ""
                    }) {
                        Image(systemName: "arrow.up")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .foregroundColor(UIStyles.chatSendButtonIconColor)
                            .padding()
                    }
                    .background(UIStyles.chatSendButtonColor)
                    .clipShape(Circle())
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            .background(UIStyles.chatInputContainerBackground)
            .clipShape(RoundedRectangle(cornerRadius: UIStyles.chatInputContainerCornerRadius))
        }
        .background(UIStyles.chatBackground.edgesIgnoringSafeArea(.all))
    }
}

struct ChatMessageBubble: View {
    let message: ChatMessageEntity
    
    var body: some View {
        HStack {
            if message.role == "assistant" {
                HStack {
                    Text(message.content ?? "")
                        .font(UIStyles.chatFont)
                        .padding()
                        .background(UIStyles.assistantMessageBubbleColor)
                        .clipShape(UIStyles.ChatBubbleShape(isUser: false))
                    Spacer()
                }
            } else {
                HStack {
                    Spacer()
                    Text(message.content ?? "")
                        .font(UIStyles.chatFont)
                        .padding()
                        .background(UIStyles.userMessageBubbleColor)
                        .clipShape(UIStyles.ChatBubbleShape(isUser: true))
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}