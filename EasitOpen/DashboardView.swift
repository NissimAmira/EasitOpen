import SwiftUI
import SwiftData
import CoreLocation

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var businesses: [Business]
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showDeleteAlert = false
    @State private var businessToDelete: Business?
    
    private var filteredBusinesses: [Business] {
        viewModel.filteredAndSorted(businesses)
    }
    
    var body: some View {
        NavigationStack {
            if businesses.isEmpty {
                emptyStateView
            } else {
                contentView
            }
        }
        .navigationTitle("My Businesses")
        .searchable(text: $viewModel.searchText, prompt: "Search businesses")
        .overlay(alignment: .top) {
            if let message = viewModel.refreshMessage {
                messageToast(message: message, type: viewModel.refreshMessageType)
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
        .alert(item: $viewModel.alertState) { alertState in
            createAlert(from: alertState)
        }
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
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
    }
    
    private var contentView: some View {
        VStack(spacing: 0) {
            filterAndSortControls
            businessList
        }
    }
    
    private var filterAndSortControls: some View {
        HStack {
            Menu {
                Picker("Filter", selection: $viewModel.filterOption) {
                    ForEach(DashboardViewModel.FilterOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            } label: {
                Label(viewModel.filterOption.rawValue, systemImage: "line.3.horizontal.decrease.circle")
                    .font(.subheadline)
            }
            .buttonStyle(.bordered)
            
            Menu {
                Picker("Sort", selection: $viewModel.sortOption) {
                    ForEach(DashboardViewModel.SortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down")
                    .font(.subheadline)
            }
            .buttonStyle(.bordered)
            .onChange(of: viewModel.sortOption) { _, newValue in
                viewModel.validateSortOption(newValue)
            }
            
            Spacer()
            
            Text("\(filteredBusinesses.count) of \(businesses.count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var businessList: some View {
        Group {
            if filteredBusinesses.isEmpty {
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
                    ForEach(filteredBusinesses) { business in
                        NavigationLink(destination: BusinessDetailView(business: business)) {
                            BusinessCardView(
                                business: business,
                                referenceLocation: viewModel.referenceLocation()
                            )
                        }
                    }
                    .onDelete(perform: promptDelete)
                }
                .refreshable {
                    await viewModel.refreshAllBusinesses(businesses)
                }
            }
        }
    }
    
    private func messageToast(message: String, type: MessageType) -> some View {
        HStack(spacing: 8) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
            Text(message)
                .font(.subheadline)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(type.color.opacity(0.15))
        .background(.ultraThinMaterial)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(type.color.opacity(0.3), lineWidth: 1)
        )
        .padding(.top, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    private func createAlert(from alertState: AlertState) -> Alert {
        if let primary = alertState.primaryButton,
           let secondary = alertState.secondaryButton {
            return Alert(
                title: Text(alertState.title),
                message: Text(alertState.message),
                primaryButton: .default(Text(primary.title), action: primary.action),
                secondaryButton: .cancel(Text(secondary.title), action: secondary.action)
            )
        } else if let secondary = alertState.secondaryButton {
            return Alert(
                title: Text(alertState.title),
                message: Text(alertState.message),
                dismissButton: .cancel(Text(secondary.title), action: secondary.action)
            )
        } else {
            return Alert(
                title: Text(alertState.title),
                message: Text(alertState.message)
            )
        }
    }
    
    private func promptDelete(at offsets: IndexSet) {
        if let index = offsets.first {
            businessToDelete = filteredBusinesses[index]
            showDeleteAlert = true
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Business.self, DaySchedule.self])
}
