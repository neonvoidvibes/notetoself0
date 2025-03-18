import SwiftUI

struct NewEntryView: View {
    @Environment(\.dismiss) var dismiss
    @State private var noteText: String = ""
    
    var body: some View {
        ZStack {
            // Fully transparent background with heavy blur to reveal underlying elements
            Color.clear
                .edgesIgnoringSafeArea(.all)
                .overlay(
                    BlurView(style: .systemMaterialDark)
                        .edgesIgnoringSafeArea(.all)
                        .blur(radius: 20)
                )
            
            VStack(alignment: .leading, spacing: 20) {
                // Top section with Cancel button and "Add Note" title
                VStack(alignment: .leading, spacing: 8) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .cornerRadius(8)
                    }
                    
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
                    Button(action: {
                        // Save action implementation
                    }) {
                        Text("Save")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(8)
                    }
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