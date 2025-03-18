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
                        Text("+ Add")
                            .font(UIStyles.bodyFont)
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(UIStyles.accentColor)
                            .cornerRadius(UIStyles.defaultCornerRadius)
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
            NewEntryView()
        }
    }
}

struct NotesView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        return NotesView().environment(\.managedObjectContext, context)
    }
}