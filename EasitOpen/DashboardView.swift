import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var businesses: [Business]
    @State private var showDeleteAlert = false
    @State private var businessToDelete: Business?
    
    var body: some View {
        NavigationStack {
            if businesses.isEmpty {
                // Empty state - no businesses saved yet
                VStack(spacing: 20) {
                    Image(systemName: "storefront")
                        .font(.system(size: 80))
                        .foregroundStyle(.gray)
                    
                    Text("No Businesses Yet")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Add businesses to track their opening hours")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Temporary test button
                    Button("Add Sample Business") {
                        addSampleBusiness()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top)
                }
            } else {
                // List of businesses
                List {
                    ForEach(businesses) { business in
                        NavigationLink(destination: BusinessDetailView(business: business)) {
                            BusinessCardView(business: business)
                        }
                    }
                    .onDelete(perform: promptDelete)
                }
                .alert("Remove Business", isPresented: $showDeleteAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Remove", role: .destructive) {
                        if let business = businessToDelete {
                            modelContext.delete(business)
                            businessToDelete = nil
                        }
                    }
                } message: {
                    if let business = businessToDelete {
                        Text("Are you sure you want to remove \(business.name) from your dashboard?")
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Add Sample") {
                            addSampleBusiness()
                        }
                    }
                }
            }
        }
        .navigationTitle("My Businesses")
    }
    
    private func addSampleBusiness() {
        // Create sample schedule (Monday-Friday, 9 AM - 6 PM)
        let schedule = [
            DaySchedule(weekday: 2, openTime: 540, closeTime: 1320),  // Monday
            DaySchedule(weekday: 3, openTime: 540, closeTime: 1320),  // Tuesday
            DaySchedule(weekday: 4, openTime: 540, closeTime: 1320),  // Wednesday
            DaySchedule(weekday: 5, openTime: 540, closeTime: 1320),  // Thursday
            DaySchedule(weekday: 6, openTime: 540, closeTime: 1320),  // Friday
            DaySchedule(weekday: 7, openTime: 600, closeTime: 840, isClosed: false), // Saturday 10 AM - 2 PM
            DaySchedule(weekday: 1, openTime: 0, closeTime: 0, isClosed: true)       // Sunday closed
        ]
        
        let business = Business(
            name: "Sample Coffee Shop",
            address: "123 Main Street, Tel Aviv",
            latitude: 32.0853,
            longitude: 34.7818,
            phoneNumber: "03-1234567",
            website: "https://example.com",
            openingHours: schedule
        )
        
        modelContext.insert(business)
    }
    
    private func promptDelete(at offsets: IndexSet) {
        if let index = offsets.first {
            businessToDelete = businesses[index]
            showDeleteAlert = true
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Business.self, DaySchedule.self])
}
