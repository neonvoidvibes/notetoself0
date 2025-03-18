import SwiftUI
import CoreData

struct NotesView: View {
    @Environment(\.managedObjectContext) private var moc
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \JournalEntryEntity.timestamp, ascending: false)],
        animation: .default
    ) private var entries: FetchedResults<JournalEntryEntity>
    
    @State private var expandedEntry: NSManagedObjectID? = nil
    @State private var showNewEntryView = false
    
    // Draft text & mood
    @State private var draftNoteText: String = ""
    @State private var draftMood: String = "Neutral"
    
    var body: some View {
        UIStyles.CustomZStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Notes")
                    .font(UIStyles.headingFont)
                    .foregroundColor(UIStyles.textColor)
                    .padding(.bottom, 20)
                
                HStack {
                    Spacer()
                    Button {
                        withAnimation {
                            showNewEntryView = true
                        }
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 20))
                            .foregroundColor(UIStyles.secondaryAccentColor)
                    }
                }
                
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(entries) { entry in
                                EntryAccordionView(entry: entry, isExpanded: expandedEntry == entry.objectID)
                                    .id(entry.objectID)
                                    .onTapGesture {
                                        withAnimation {
                                            if expandedEntry == entry.objectID {
                                                expandedEntry = nil
                                            } else {
                                                expandedEntry = entry.objectID
                                                proxy.scrollTo(entry.objectID, anchor: .bottom)
                                            }
                                        }
                                    }
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .sheet(isPresented: $showNewEntryView) {
            NewEntryView(
                noteText: $draftNoteText,
                selectedMood: $draftMood
            ) {
                let newEntry = JournalEntryEntity(context: moc)
                newEntry.timestamp = Date()
                newEntry.text = draftNoteText
                newEntry.mood = draftMood
                do {
                    try moc.save()
                } catch {
                    print("Failed to save new entry: \(error)")
                }
                draftNoteText = ""
                draftMood = "Neutral"
            }
        }
    }
}

struct NotesView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        return NotesView().environment(\.managedObjectContext, context)
    }
}