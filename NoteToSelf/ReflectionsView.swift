import SwiftUI

struct ReflectionsView: View {
    @StateObject private var viewModel = ReflectionsViewModel()
    @State private var currentInput: String = ""
    
    // We'll define some animation states if needed.
    @State private var textFlowAnimation: Bool = false
    
    // For limiting usage alert
    @State private var showUsageLimitAlert: Bool = false
    
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
            
            // Chat messages with auto-scroll
            ScrollViewReader { scrollProxy in
                ScrollView {
                    ForEach(viewModel.messages, id: \.id) { message in
                        ReflectionMessageBubble(
                            message: message,
                            onSave: { content in
                                saveAssistantReplyToJournal(content)
                            }
                        )
                        .id(message.id)
                    }
                    
                    // If the assistant is typing, show loading indicator
                    if viewModel.isAssistantTyping {
                        HStack {
                            UIStyles.reflectionAssistantLoadingIndicator
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
            
            // Input container
            HStack(spacing: 8) {
                TextEditor(text: viewModel.isAssistantTyping ? .constant("") : $currentInput)
                    .font(UIStyles.bodyFont)
                    .foregroundColor(viewModel.isAssistantTyping ? .gray : .white)
                    .accentColor(UIStyles.accentColor)
                    .scrollContentBackground(.hidden)
                    .cornerRadius(UIStyles.defaultCornerRadius)
                    .frame(minHeight: 50, maxHeight: 120)
                    .disabled(viewModel.isAssistantTyping)
                
                Button(action: {
                    if viewModel.isAssistantTyping {
                        viewModel.userStop()
                    } else {
                        let trimmed = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        
                        // Check usage limit
                        if !viewModel.canSendMessage() {
                            showUsageLimitAlert = true
                            return
                        }
                        
                        viewModel.sendMessage(trimmed)
                        currentInput = ""
                    }
                }) {
                    if viewModel.isAssistantTyping {
                        Image(systemName: "stop.fill")
                            .font(Font.system(size: 18, weight: .bold))
                            .foregroundColor(UIStyles.reflectionInputContainerBackground)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(Font.system(size: 26, weight: .bold))
                            .foregroundColor(Color(hex: "#000000"))
                    }
                }
                .frame(width: 40, height: 40)
                .background(Color.white)
                .clipShape(Circle())
                .padding(.bottom, UIStyles.globalHorizontalPadding)
            }
            .padding(.horizontal, UIStyles.globalHorizontalPadding)
            .padding(.vertical, 16)
            .padding(.bottom, 16)
            .background(UIStyles.reflectionInputContainerBackground)
            .cornerRadius(UIStyles.defaultCornerRadius * 3)
        }
        .background(UIStyles.reflectionBackground.edgesIgnoringSafeArea(.all))
        .alert(isPresented: $showUsageLimitAlert) {
            Alert(
                title: Text("Daily Limit Reached"),
                message: Text("You have reached the free daily limit for sending reflections. Please upgrade or come back tomorrow."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func saveAssistantReplyToJournal(_ content: String) {
        // Access CoreData
        let context = PersistenceController.shared.container.viewContext
        let newEntry = JournalEntryEntity(context: context)
        newEntry.timestamp = Date()
        newEntry.text = content
        newEntry.mood = "Neutral"
        do {
            try context.save()
        } catch {
            print("Failed to save reflection to journal: \(error)")
        }
    }
}

struct ReflectionMessageBubble: View {
    let message: ReflectionMessageEntity
    let onSave: (String) -> Void
    
    var body: some View {
        HStack {
            if message.role == "assistant" {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(message.content ?? "")
                            .font(UIStyles.reflectionFont)
                            .foregroundColor(.white)
                            .padding([.top, .trailing, .bottom], 16)
                            .background(Color.clear)
                            .clipShape(UIStyles.ChatBubbleShape(isUser: false))
                        
                        // Show "Save to Journal" if this is assistant
                        Button(action: {
                            if let content = message.content {
                                onSave(content)
                            }
                        }) {
                            Text("Save to Journal")
                                .font(UIStyles.smallLabelFont)
                                .foregroundColor(UIStyles.accentColor)
                                .underline()
                        }
                        .padding(.leading, 8)
                    }
                    Spacer()
                }
            } else {
                HStack {
                    Spacer()
                    Text(message.content ?? "")
                        .font(UIStyles.reflectionFont)
                        .padding()
                        .background(UIStyles.reflectionUserBubbleColor)
                        .clipShape(UIStyles.ChatBubbleShape(isUser: true))
                        .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .trailing)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

struct ReflectionsView_Previews: PreviewProvider {
    static var previews: some View {
        ReflectionsView()
    }
}