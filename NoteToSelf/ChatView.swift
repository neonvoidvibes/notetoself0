import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var currentInput: String = ""
    @State private var hasInitiallyLoaded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Top toolbar row with square.and.pencil to clear conversation
            HStack {
                Button {
                    viewModel.clearConversation()
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 28))
                        .foregroundColor(UIStyles.offWhite)
                }
                Spacer()
            }
            .padding(.horizontal, UIStyles.globalHorizontalPadding)
            .padding(.vertical, 16)
            
            ScrollViewReader { scrollProxy in
                ScrollView {
                    ForEach(viewModel.messages, id: \.id) { message in
                        ChatMessageBubble(message: message)
                            .id(message.id)
                    }
                }
                .onAppear {
                    // Scroll to bottom on first appear only
                    if !hasInitiallyLoaded {
                        hasInitiallyLoaded = true
                        if let lastID = viewModel.messages.last?.id {
                            withAnimation {
                                scrollProxy.scrollTo(lastID, anchor: .bottom)
                            }
                        }
                    }
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    // Always scroll to bottom when new messages are appended
                    if let lastID = viewModel.messages.last?.id {
                        withAnimation {
                            scrollProxy.scrollTo(lastID, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Add black margin between chat bubbles and the input container
            Rectangle()
                .fill(Color.black)
                .frame(height: 20)
            
            // Chat input container with extended height, increased padding, and more rounded corners
            HStack(spacing: 8) {
                TextEditor(text: $currentInput)
                    .font(UIStyles.bodyFont)
                    .foregroundColor(.white)
                    .accentColor(UIStyles.accentColor)
                    .scrollContentBackground(.hidden)
                    .cornerRadius(UIStyles.defaultCornerRadius)
                    .frame(minHeight: 50, maxHeight: 120)
                
                Button(action: {
                    let trimmed = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    viewModel.sendMessage(trimmed)
                    currentInput = ""
                }) {
                    Image(systemName: "arrow.up")
                        .font(Font.system(size: 26, weight: .bold))
                        .foregroundColor(Color(hex: "#000000"))
                }
                .frame(width: 40, height: 40)
                .background(Color.white)
                .clipShape(Circle())
                .padding(.bottom, UIStyles.globalHorizontalPadding)
            }
            .padding(.horizontal, UIStyles.globalHorizontalPadding)
            .padding(.vertical, 16)
            .padding(.bottom, 16)
            .background(Color(hex: "#313131"))
            .cornerRadius(UIStyles.chatInputContainerCornerRadius * 3)
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