import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var businesses: [Business]
    @State private var showDeleteAlert = false
    @State private var businessToDelete: Business?
    @State private var sortOption: SortOption = .name
    @State private var filterOption: FilterOption = .all
    @State private var searchText = ""
    @State private var isRefreshing = false
    @State private var refreshMessage: String?
    
    private let refreshService = BusinessRefreshService()

    enum SortOption: String, CaseIterable {
        case name = "Name"
        case status = "Status"
    }

    enum FilterOption: String, CaseIterable {
        case all = "All"
        case open = "Open"
        case closingSoon = "Closing Soon"
        case closed = "Closed"
    }
    
    private var filteredAndSortedBusinesses: [Business] {
        var result = businesses
        
        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { business in
                business.name.localizedCaseInsensitiveContains(searchText) ||
                business.address.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by status
        switch filterOption {
        case .all:
            break
        case .open:
            result = result.filter { $0.status == .open }
        case .closingSoon:
            result = result.filter { $0.status == .closingSoon }
        case .closed:
            result = result.filter { $0.status == .closed }
        }
        
        // Sort
        switch sortOption {
        case .name:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .status:
            // Sort by status priority: open, closingSoon, closed
            result.sort { business1, business2 in
                let priority1 = statusPriority(business1.status)
                let priority2 = statusPriority(business2.status)
                return priority1 < priority2
            }
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            let _ = print("Dashboard: Found \(businesses.count) businesses")
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
                    
                    Text("Tap the Search tab below to get started")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.top, 8)
                }
            } else {
                VStack(spacing: 0) {
                    // Filter and Sort controls
                    HStack {
                        // Filter picker
                        Menu {
                            Picker("Filter", selection: $filterOption) {
                                ForEach(FilterOption.allCases, id: \.self) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                        } label: {
                            Label(filterOption.rawValue, systemImage: "line.3.horizontal.decrease.circle")
                                .font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                        
                        // Sort picker
                        Menu {
                            Picker("Sort", selection: $sortOption) {
                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                        } label: {
                            Label("Sort", systemImage: "arrow.up.arrow.down")
                                .font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        // Count badge
                        Text("\(filteredAndSortedBusinesses.count) of \(businesses.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    // List of businesses
                    if filteredAndSortedBusinesses.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("No businesses match your filters")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(filteredAndSortedBusinesses) { business in
                                NavigationLink(destination: BusinessDetailView(business: business)) {
                                    BusinessCardView(business: business)
                                }
                            }
                            .onDelete(perform: promptDelete)
                        }
                        .refreshable {
                            await refreshAllBusinesses()
                        }
                    }
                }
            }
        }
        .navigationTitle("My Businesses")
        .searchable(text: $searchText, prompt: "Search businesses")
        .overlay(alignment: .top) {
            if let message = refreshMessage {
                Text(message)
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
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
    }
    
    private func statusPriority(_ status: BusinessStatus) -> Int {
        switch status {
        case .open: return 0
        case .closingSoon: return 1
        case .closed: return 2
        }
    }
    
    private func promptDelete(at offsets: IndexSet) {
        if let index = offsets.first {
            // Find the actual business in the filtered list
            let businessToRemove = filteredAndSortedBusinesses[index]
            businessToDelete = businessToRemove
            showDeleteAlert = true
        }
    }
    
    @MainActor
    private func refreshAllBusinesses() async {
        print("\n🔄 Starting refresh of \(businesses.count) businesses...")
        
        isRefreshing = true
        
        let results = await refreshService.refreshAllBusinesses(businesses)
        
        isRefreshing = false
        
        // Count successes and changes
        let successCount = results.filter { $0.success }.count
        let changesCount = results.filter { $0.hasChanges }.count
        let failureCount = results.filter { !$0.success }.count
        
        print("✅ Refresh complete: \(successCount) succeeded, \(changesCount) had changes, \(failureCount) failed")
        
        // Show message to user
        if failureCount > 0 {
            showRefreshMessage("Updated \(successCount) of \(businesses.count) businesses")
        } else if changesCount > 0 {
            showRefreshMessage("✓ Updated \(changesCount) business(es) with new hours")
        } else {
            showRefreshMessage("✓ All businesses are up to date")
        }
    }
    
    private func showRefreshMessage(_ message: String) {
        withAnimation {
            refreshMessage = message
        }
        
        // Hide message after 3 seconds
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation {
                refreshMessage = nil
            }
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Business.self, DaySchedule.self])
}
