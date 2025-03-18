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
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let lastID = viewModel.messages.last?.id {
                        withAnimation {
                            scrollProxy.scrollTo(lastID, anchor: .bottom)
                        }
                    }
                }
            }
            // Chat input container with proper padding and rounded corners
            HStack(spacing: 8) {
                TextEditor(text: $currentInput)
                    .font(UIStyles.bodyFont)
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .background(UIStyles.chatInputFieldBackground)
                    .cornerRadius(UIStyles.defaultCornerRadius)
                    .frame(minHeight: 40, maxHeight: 100)
                Button(action: {
                    let trimmed = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    viewModel.sendMessage(trimmed)
                    currentInput = ""
                }) {
                    Image(systemName: "arrow.up")
                        .font(Font.system(size: 26, weight: .bold))
                        .foregroundColor(Color(hex: "#555555"))
                }
                .frame(width: 36, height: 36)
                .background(Color.white)
                .clipShape(Circle())
            }
            .padding(.horizontal, UIStyles.globalHorizontalPadding)
            .padding(.vertical, 8)
            .padding(.bottom, 16)
            .background(UIStyles.chatInputContainerBackground)
            .cornerRadius(UIStyles.chatInputContainerCornerRadius)
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
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.clear)
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
                        .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .trailing)
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