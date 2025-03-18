import SwiftUI

struct NewEntryView: View {
    @Environment(\.dismiss) var dismiss
    @State private var noteText: String = ""
    
    var body: some View {
        ZStack {
            // Fully transparent background with a real, native blur effect
            Color.clear
                .edgesIgnoringSafeArea(.all)
                .overlay(
                    BlurView(style: .dark)
                        .edgesIgnoringSafeArea(.all)
                )
            
            VStack(alignment: .leading, spacing: 20) {
                // Top section with Cancel button and "Add Note" title
                VStack(alignment: .leading, spacing: 8) {
                    Button("Cancel", action: {
                        dismiss()
                    })
                    .buttonStyle(UIStyles.PrimaryButtonStyle())
                    
                    HStack {
                        Spacer()
                        Text("Add Note")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                .padding(.horizontal)
                .padding(.top, 40)
                
                // Input area with enforced black background (#111111) and white text.
                TextEditor(text: $noteText)
                    .scrollContentBackground(.hidden)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(12)
                    .frame(height: 150)
                    .background(Color(hex: "#111111"))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                // Save button aligned to the right below the input area
                HStack {
                    Spacer()
                    Button("Save", action: {
                        // Save action implementation
                    })
                    .buttonStyle(UIStyles.PrimaryButtonStyle())
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
    }
}

struct NewEntryView_Previews: PreviewProvider {
    static var previews: some View {
        NewEntryView()
    }
}