import SwiftUI
import CoreData

struct InsightsView: View {
    @Environment(\.managedObjectContext) private var moc
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \JournalEntryEntity.timestamp, ascending: false)],
        animation: .default
    ) private var entries: FetchedResults<JournalEntryEntity>
    
    var body: some View {
        UIStyles.CustomZStack {
            Text("Insights")
                .font(UIStyles.headingFont)
                .foregroundColor(UIStyles.textColor)
            
            Spacer().frame(height: 20)
            
            MoodChartView(entries: entries)
                .frame(height: 180)
            
            Spacer().frame(height: 20)
            
            Text("Additional insights or placeholders can go here.")
                .font(UIStyles.bodyFont)
                .foregroundColor(UIStyles.textColor)
        }
    }
}

struct InsightsView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        return InsightsView().environment(\.managedObjectContext, context)
    }
}