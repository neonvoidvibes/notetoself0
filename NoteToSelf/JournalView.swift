import SwiftUI
import CoreData

struct JournalView: View {
    @Environment(\.managedObjectContext) private var moc
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \JournalEntryEntity.timestamp, ascending: false)],
        animation: .default
    ) private var entries: FetchedResults<JournalEntryEntity>
    
    @State private var expandedEntry: NSManagedObjectID? = nil
    @State private var showNewEntryView = false
    
    @State private var draftNoteText: String = ""
    @State private var draftMood: String = "Neutral"
    
    @State private var entryToDelete: JournalEntryEntity? = nil

    var body: some View {
        ZStack {
            // Background
            UIStyles.appBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                Text("Journal")
                    .font(UIStyles.headingFont)
                    .foregroundColor(UIStyles.textColor)
                    .padding(.top, 16)
                    .padding(.bottom, 4)
                    .padding(.leading, UIStyles.globalHorizontalPadding)

                // The main scrollable list
                ScrollViewReader { proxy in
                    List {
                        ForEach(entries) { entry in
                            EntryAccordionView(
                                entry: entry,
                                isExpanded: expandedEntry == entry.objectID
                            )
                            .id(entry.objectID)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
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
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    entryToDelete = entry
                                } label: {
                                    Text("Delete")
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            
            // Floating + button at bottom right
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation {
                            showNewEntryView = true
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 56, height: 56)
                            .background(UIStyles.accentColor)
                            .cornerRadius(28)
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                            .padding()
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
        .alert(item: $entryToDelete) { entry in
            Alert(
                title: Text("Delete Entry?"),
                message: Text("Are you sure you want to delete this journal entry? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    moc.delete(entry)
                    do {
                        try moc.save()
                    } catch {
                        print("Failed to delete entry: \(error)")
                    }
                },
                secondaryButton: .cancel {
                    entryToDelete = nil
                }
            )
        }
    }
}

struct JournalView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        return JournalView().environment(\.managedObjectContext, context)
    }
}