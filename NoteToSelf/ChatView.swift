import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var currentInput: String = ""
    
    // We'll define some animation states if needed (like for textFlowAnimation).
    @State private var textFlowAnimation: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Top toolbar row with clear conversation button
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
            
            // Chat messages with auto-scroll and loading dot
            ScrollViewReader { scrollProxy in
                ScrollView {
                    ForEach(viewModel.messages, id: \.id) { message in
                        ChatMessageBubble(message: message)
                            .id(message.id)
                    }
                    
                    // If the assistant is typing, show loading dot
                    if viewModel.isAssistantTyping {
                        HStack {
                            UIStyles.assistantLoadingIndicator
                            Spacer()
                        }
                        .padding(.leading, 24)
                        .padding(.trailing, 16)
                        .padding(.vertical, 24)
                    }
                    
                    // Invisible anchor to scroll to
                    Color.clear
                        .frame(height: 1)
                        .id("BottomAnchor")
                }
                .onAppear {
                    withAnimation {
                        scrollProxy.scrollTo("BottomAnchor", anchor: .bottom)
                    }
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    withAnimation {
                        scrollProxy.scrollTo("BottomAnchor", anchor: .bottom)
                    }
                }
                .onChange(of: viewModel.isAssistantTyping) { _, newValue in
                    if newValue {
                        withAnimation {
                            scrollProxy.scrollTo("BottomAnchor", anchor: .bottom)
                        }
                    }
                }
            }
            
            // Black margin between chat bubbles and the input container
            Rectangle()
                .fill(Color.black)
                .frame(height: 20)
            
            // Chat input container
            HStack(spacing: 8) {
                if !viewModel.isAssistantTyping {
                    // Normal text editor + send button
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
                } else {
                    // "Stop" button replaces send, user can't input text
                    TextEditor(text: .constant(""))
                        .font(UIStyles.bodyFont)
                        .foregroundColor(.gray)
                        .disabled(true)
                        .frame(minHeight: 50, maxHeight: 120)
                        .opacity(0.3)
                    
                    Button(action: {
                        // user stops
                        viewModel.userStop()
                    }) {
                        Image(systemName: "stop.fill")
                            .font(Font.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 40, height: 40)
                    .background(Color.red)
                    .clipShape(Circle())
                    .padding(.bottom, UIStyles.globalHorizontalPadding)
                }
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
                        .padding([.top, .trailing, .bottom], 16)
                        .padding(.leading, 0)
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