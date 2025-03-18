import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var currentInput: String = ""
    
    var body: some View {
        VStack {
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
            
            HStack {
                TextField("Type a message...", text: $currentInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: {
                    let trimmed = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    viewModel.sendMessage(trimmed)
                    currentInput = ""
                }) {
                    Text("Send")
                        .padding()
                        .background(UIStyles.chatSendButtonBackground)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
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
                        .background(UIStyles.assistantBubbleColor)
                        .cornerRadius(10)
                    Spacer()
                }
            } else {
                HStack {
                    Spacer()
                    Text(message.content ?? "")
                        .font(UIStyles.chatFont)
                        .padding()
                        .background(UIStyles.userBubbleColor)
                        .cornerRadius(10)
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