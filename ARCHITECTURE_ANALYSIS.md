# Architecture Analysis & MVVM Refactoring Recommendations

## Current State Analysis

### Current Architecture: "View-Heavy" Pattern

Your app currently uses what I'd call a **"View-Heavy"** or **"Pragmatic SwiftUI"** pattern:
- Views contain most business logic directly
- `@State` and `@Query` used for data management
- Services (LocationManager, BusinessRefreshService) provide utilities
- Computed properties handle filtering/sorting in views

**This is actually a common and acceptable pattern for SwiftUI apps**, especially for learning and smaller projects.

### What's Working Well ✅

1. **Simple and Direct**: Easy to understand data flow
2. **SwiftData Integration**: `@Query` works seamlessly
3. **Service Layer**: Good separation with LocationManager, BusinessRefreshService
4. **Testing**: Business logic in models is testable
5. **Fast Development**: Quick to prototype and iterate

### Current Issues & Code Smells ⚠️

Looking at your code, here are the main architectural concerns:

#### 1. **Fat Views** (Views doing too much)

**DashboardView** (~365 lines):
- 19 `@State` properties
- Filtering, sorting, validation logic
- Refresh logic
- Alert management
- UI rendering

**SearchView** (~207 lines):
- API calls directly in view
- Business creation logic
- Data conversion (OpeningHours)
- Sorting logic

**BusinessDetailView** (~320 lines):
- Refresh logic
- Label editing
- Alert management
- Map coordination

#### 2. **Duplicated Logic**

- `MessageType` enum defined in both DashboardView and BusinessDetailView
- Refresh logic duplicated
- Alert handling patterns repeated
- Sorting/filtering logic not reusable

#### 3. **Hard to Test**

- Business logic embedded in views (can't unit test)
- Side effects mixed with presentation
- No clear way to test filtering/sorting independently

#### 4. **State Management Complexity**

DashboardView manages:
```swift
@State private var showDeleteAlert = false
@State private var businessToDelete: Business?
@State private var sortOption: SortOption = .name
@State private var filterOption: FilterOption = .all
@State private var searchText = ""
@State private var isRefreshing = false
@State private var refreshMessage: String?
@State private var refreshMessageType: MessageType = .success
@State private var showLocationAlert = false
@State private var locationAlertMessage = ""
@State private var locationAlertAction: (() -> Void)?
```

This is a lot of coordinated state to manage!

## Recommended Architecture: MVVM with SwiftUI

### Why MVVM?

1. **Separation of Concerns**: Logic separate from presentation
2. **Testability**: ViewModels are pure Swift classes (easy to test)
3. **Reusability**: ViewModels can be shared/reused
4. **Maintainability**: Easier to modify and extend
5. **Industry Standard**: Common pattern in iOS development

### Proposed Structure

```
EasitOpen/
├── Models/                    # Data models (existing)
│   ├── Business.swift
│   ├── DaySchedule.swift
│   └── PlaceResult.swift
├── ViewModels/                # NEW: Business logic
│   ├── DashboardViewModel.swift
│   ├── SearchViewModel.swift
│   ├── BusinessDetailViewModel.swift
│   └── Shared/
│       ├── MessageType.swift  # Shared types
│       └── AlertState.swift
├── Views/                     # Pure UI (existing, simplified)
│   ├── Dashboard/
│   │   ├── DashboardView.swift
│   │   └── BusinessCardView.swift
│   ├── Search/
│   │   ├── SearchView.swift
│   │   └── SearchResultRow.swift
│   ├── BusinessDetail/
│   │   └── BusinessDetailView.swift
│   └── Settings/
│       ├── SettingsView.swift
│       └── HomeLocationPickerView.swift
├── Services/                  # Utilities (existing)
│   ├── GooglePlacesService.swift
│   ├── BusinessRefreshService.swift
│   ├── LocationManager.swift
│   ├── NotificationManager.swift
│   └── BackgroundRefreshManager.swift
└── EasitOpenApp.swift
```

## Detailed Refactoring Plan

### Phase 1: Extract Shared Types (Easiest - Good Starting Point)

**Priority: HIGH | Effort: LOW | Risk: LOW**

Create shared types used across multiple views:

**ViewModels/Shared/MessageType.swift**
```swift
enum MessageType {
    case success, info, warning, error
    
    var color: Color {
        switch self {
        case .success: return .green
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .info: return "info.circle.fill"
        case .warning, .error: return "exclamationmark.triangle.fill"
        }
    }
}
```

**ViewModels/Shared/AlertState.swift**
```swift
struct AlertState: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let primaryButton: AlertButton?
    let secondaryButton: AlertButton?
    
    struct AlertButton {
        let title: String
        let action: () -> Void
    }
}
```

**Benefits:**
- Eliminates duplication
- Makes testing easier
- Single source of truth
- Can add more message types without touching views

---

### Phase 2: Create DashboardViewModel (Highest Impact)

**Priority: HIGH | Effort: MEDIUM | Risk: MEDIUM**

This view has the most complex logic and would benefit most from extraction.

**ViewModels/DashboardViewModel.swift**
```swift
import Foundation
import SwiftUI
import SwiftData
import CoreLocation

@MainActor
class DashboardViewModel: ObservableObject {
    // MARK: - Published State
    @Published var sortOption: SortOption = .name
    @Published var filterOption: FilterOption = .all
    @Published var searchText = ""
    @Published var isRefreshing = false
    @Published var refreshMessage: String?
    @Published var refreshMessageType: MessageType = .success
    @Published var alertState: AlertState?
    
    // MARK: - Dependencies
    private let refreshService: BusinessRefreshService
    private let locationManager: LocationManager
    private var modelContext: ModelContext?
    
    // MARK: - Enums
    enum SortOption: String, CaseIterable {
        case name = "Name"
        case status = "Status"
        case distanceCurrent = "Distance (Current)"
        case distanceHome = "Distance (Home)"
    }
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case open = "Open"
        case closingSoon = "Closing Soon"
        case closed = "Closed"
    }
    
    // MARK: - Initialization
    init(
        refreshService: BusinessRefreshService = BusinessRefreshService(),
        locationManager: LocationManager = .shared
    ) {
        self.refreshService = refreshService
        self.locationManager = locationManager
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Business Logic
    
    func filteredAndSorted(_ businesses: [Business]) -> [Business] {
        var result = businesses
        
        // Filter by search
        if !searchText.isEmpty {
            result = result.filter { business in
                business.name.localizedCaseInsensitiveContains(searchText) ||
                business.address.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by status
        switch filterOption {
        case .all: break
        case .open: result = result.filter { $0.status == .open }
        case .closingSoon: result = result.filter { $0.status == .closingSoon }
        case .closed: result = result.filter { $0.status == .closed }
        }
        
        // Sort
        switch sortOption {
        case .name:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .status:
            result.sort { statusPriority($0.status) < statusPriority($1.status) }
        case .distanceCurrent:
            if let location = locationManager.currentLocation {
                result.sort { $0.distance(from: location) < $1.distance(from: location) }
            }
        case .distanceHome:
            if let location = locationManager.homeLocation {
                result.sort { $0.distance(from: location) < $1.distance(from: location) }
            }
        }
        
        return result
    }
    
    func referenceLocation() -> CLLocation? {
        switch sortOption {
        case .distanceCurrent: return locationManager.currentLocation
        case .distanceHome: return locationManager.homeLocation
        default: return nil
        }
    }
    
    func validateSortOption(_ option: SortOption) {
        var shouldShowAlert = false
        var alertTitle = "Location Required"
        var alertMessage = ""
        var alertAction: (() -> Void)?
        
        switch option {
        case .distanceCurrent:
            if locationManager.currentLocation == nil {
                shouldShowAlert = true
                switch locationManager.authorizationStatus {
                case .notDetermined:
                    alertMessage = "Enable location services to sort by distance."
                    alertAction = { self.locationManager.requestPermission() }
                case .denied, .restricted:
                    alertMessage = "Location access is disabled. Enable it in Settings."
                    alertAction = { 
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                default:
                    alertMessage = "Waiting for your location. Try again in a moment."
                }
            }
            
        case .distanceHome:
            if locationManager.homeLocation == nil {
                shouldShowAlert = true
                alertMessage = "Set a home location in Settings first."
            }
            
        default:
            break
        }
        
        if shouldShowAlert {
            alertState = AlertState(
                title: alertTitle,
                message: alertMessage,
                primaryButton: alertAction.map { action in
                    AlertState.AlertButton(title: "Open Settings", action: action)
                },
                secondaryButton: AlertState.AlertButton(title: "Cancel") {
                    self.sortOption = .name
                }
            )
        }
    }
    
    func refreshAllBusinesses(_ businesses: [Business]) async {
        print("\n🔄 Starting refresh of \(businesses.count) businesses...")
        isRefreshing = true
        
        let results = await refreshService.refreshAllBusinesses(businesses)
        
        isRefreshing = false
        
        let successCount = results.filter { $0.success }.count
        let changesCount = results.filter { $0.hasChanges }.count
        let failureCount = results.filter { !$0.success }.count
        
        if failureCount > 0 {
            showRefreshMessage("Updated \(successCount) of \(businesses.count) businesses", type: .warning)
        } else if changesCount > 0 {
            showRefreshMessage("Updated \(changesCount) business(es) with new hours", type: .success)
        } else {
            showRefreshMessage("All businesses are up to date", type: .info)
        }
    }
    
    func deleteBusiness(_ business: Business, from context: ModelContext) {
        context.delete(business)
        try? context.save()
    }
    
    // MARK: - Private Helpers
    
    private func statusPriority(_ status: BusinessStatus) -> Int {
        switch status {
        case .open: return 0
        case .closingSoon: return 1
        case .closed: return 2
        }
    }
    
    private func showRefreshMessage(_ message: String, type: MessageType) {
        refreshMessage = message
        refreshMessageType = type
        
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            refreshMessage = nil
        }
    }
}
```

**Updated DashboardView.swift** (Simplified - ~150 lines vs 365):
```swift
struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var businesses: [Business]
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showDeleteAlert = false
    @State private var businessToDelete: Business?
    
    var body: some View {
        NavigationStack {
            if businesses.isEmpty {
                emptyStateView
            } else {
                contentView
            }
        }
        .navigationTitle("My Businesses")
        .searchable(text: $viewModel.searchText)
        .overlay(alignment: .top) {
            if let message = viewModel.refreshMessage {
                messageToast(message)
            }
        }
        .alert(item: $viewModel.alertState) { alertState in
            createAlert(from: alertState)
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
    }
    
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
    
    private var filteredBusinesses: [Business] {
        viewModel.filteredAndSorted(businesses)
    }
    
    private var businessList: some View {
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
    
    private func promptDelete(at offsets: IndexSet) {
        if let index = offsets.first {
            businessToDelete = filteredBusinesses[index]
            showDeleteAlert = true
        }
    }
    
    // ... helper methods for toast and alert
}
```

**Benefits:**
- DashboardView goes from ~365 lines to ~150 lines
- All business logic now testable
- ViewModel reusable (e.g., could use in Widget)
- Clearer separation of concerns
- Easier to maintain and extend

---

### Phase 3: Create SearchViewModel

**Priority: MEDIUM | Effort: MEDIUM | Risk: LOW**

**ViewModels/SearchViewModel.swift**
```swift
@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var searchResults: [PlaceResult] = []
    @Published var isSearching = false
    @Published var errorMessage: String?
    @Published var addedBusinessIds: Set<String> = []
    @Published var distanceSortOption: DistanceSortOption = .relevance
    
    enum DistanceSortOption: String, CaseIterable {
        case relevance = "Relevance"
        case current = "Near Me"
        case home = "Near Home"
    }
    
    private let placesService: GooglePlacesService
    private let locationManager: LocationManager
    
    init(
        placesService: GooglePlacesService = GooglePlacesService(),
        locationManager: LocationManager = .shared
    ) {
        self.placesService = placesService
        self.locationManager = locationManager
    }
    
    func performSearch() async {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        
        do {
            searchResults = try await placesService.searchPlaces(query: searchText)
            isSearching = false
        } catch {
            isSearching = false
            errorMessage = "Failed to search. Please try again."
        }
    }
    
    func sortedResults() -> [PlaceResult] {
        guard let refLocation = referenceLocation() else { return searchResults }
        
        return searchResults.sorted { place1, place2 in
            let loc1 = CLLocation(latitude: place1.location?.latitude ?? 0, longitude: place1.location?.longitude ?? 0)
            let loc2 = CLLocation(latitude: place2.location?.latitude ?? 0, longitude: place2.location?.longitude ?? 0)
            return loc1.distance(from: refLocation) < loc2.distance(from: refLocation)
        }
    }
    
    func referenceLocation() -> CLLocation? {
        switch distanceSortOption {
        case .relevance: return nil
        case .current: return locationManager.currentLocation
        case .home: return locationManager.homeLocation
        }
    }
    
    func addBusiness(_ place: PlaceResult, to context: ModelContext) {
        let schedule = convertOpeningHours(place.currentOpeningHours)
        
        let business = Business(
            googlePlaceId: place.id,
            name: place.name,
            address: place.address,
            latitude: place.location?.latitude ?? 0,
            longitude: place.location?.longitude ?? 0,
            phoneNumber: place.internationalPhoneNumber,
            website: place.websiteUri,
            openingHours: schedule
        )
        
        do {
            context.insert(business)
            try context.save()
            addedBusinessIds.insert(place.id)
        } catch {
            errorMessage = "Failed to add business. Please try again."
        }
    }
    
    private func convertOpeningHours(_ hours: OpeningHours?) -> [DaySchedule] {
        // ... existing conversion logic
    }
}
```

---

### Phase 4: Create BusinessDetailViewModel

**Priority: LOW | Effort: LOW | Risk: LOW**

This is simpler than the others but good for completeness.

**ViewModels/BusinessDetailViewModel.swift**
```swift
@MainActor
class BusinessDetailViewModel: ObservableObject {
    @Published var showEditLabel = false
    @Published var editingLabel = ""
    @Published var isRefreshing = false
    @Published var refreshMessage: String?
    @Published var refreshMessageType: MessageType = .success
    
    let business: Business
    private let refreshService: BusinessRefreshService
    
    init(business: Business, refreshService: BusinessRefreshService = BusinessRefreshService()) {
        self.business = business
        self.refreshService = refreshService
    }
    
    func startEditingLabel() {
        editingLabel = business.customLabel ?? business.name
        showEditLabel = true
    }
    
    func saveLabel() {
        business.customLabel = editingLabel.isEmpty ? nil : editingLabel
    }
    
    func clearLabel() {
        business.customLabel = nil
    }
    
    func refreshBusiness() async {
        isRefreshing = true
        
        let result = await refreshService.refreshBusiness(business)
        
        isRefreshing = false
        
        if result.success {
            if result.hasChanges {
                showRefreshMessage("Business hours updated", type: .success)
            } else {
                showRefreshMessage("Already up to date", type: .info)
            }
        } else {
            showRefreshMessage("Failed to refresh", type: .error)
        }
    }
    
    func sortedSchedule() -> [DaySchedule] {
        business.openingHours.sorted { $0.weekday < $1.weekday }
    }
    
    private func showRefreshMessage(_ message: String, type: MessageType) {
        refreshMessage = message
        refreshMessageType = type
        
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            refreshMessage = nil
        }
    }
}
```

---

## Testing Strategy with ViewModels

One of the biggest advantages of ViewModels is testability!

**Example: DashboardViewModelTests.swift**
```swift
@MainActor
class DashboardViewModelTests: XCTestCase {
    var viewModel: DashboardViewModel!
    var mockRefreshService: MockBusinessRefreshService!
    var mockLocationManager: MockLocationManager!
    
    override func setUp() {
        mockRefreshService = MockBusinessRefreshService()
        mockLocationManager = MockLocationManager()
        viewModel = DashboardViewModel(
            refreshService: mockRefreshService,
            locationManager: mockLocationManager
        )
    }
    
    func testFilterBySearchText() {
        // Given
        let businesses = [
            createBusiness(name: "Coffee Shop"),
            createBusiness(name: "Pizza Place"),
            createBusiness(name: "Book Store")
        ]
        viewModel.searchText = "coffee"
        
        // When
        let filtered = viewModel.filteredAndSorted(businesses)
        
        // Then
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.name, "Coffee Shop")
    }
    
    func testSortByDistance() {
        // Given
        mockLocationManager.currentLocation = CLLocation(latitude: 0, longitude: 0)
        let near = createBusiness(name: "Near", lat: 0.001, lon: 0.001)
        let far = createBusiness(name: "Far", lat: 0.1, lon: 0.1)
        let businesses = [far, near]
        viewModel.sortOption = .distanceCurrent
        
        // When
        let sorted = viewModel.filteredAndSorted(businesses)
        
        // Then
        XCTAssertEqual(sorted[0].name, "Near")
        XCTAssertEqual(sorted[1].name, "Far")
    }
    
    func testValidateSortOptionShowsAlert() {
        // Given
        mockLocationManager.currentLocation = nil
        
        // When
        viewModel.validateSortOption(.distanceCurrent)
        
        // Then
        XCTAssertNotNil(viewModel.alertState)
        XCTAssertTrue(viewModel.alertState?.message.contains("location") ?? false)
    }
}
```

---

## Migration Strategy: Incremental Approach

**Don't refactor everything at once!** Here's a safe, incremental plan:

### Week 1: Foundation
1. ✅ Extract MessageType to shared file
2. ✅ Extract AlertState to shared file
3. ✅ Write tests for shared types
4. ✅ Update existing views to use shared types

### Week 2: Dashboard
1. ✅ Create DashboardViewModel
2. ✅ Write comprehensive tests
3. ✅ Update DashboardView to use ViewModel
4. ✅ Verify all functionality works
5. ✅ Test on device

### Week 3: Search
1. ✅ Create SearchViewModel
2. ✅ Write tests
3. ✅ Update SearchView
4. ✅ Test thoroughly

### Week 4: Detail & Polish
1. ✅ Create BusinessDetailViewModel (if needed)
2. ✅ Update BusinessDetailView
3. ✅ Add any missing tests
4. ✅ Update documentation

---

## Alternative: Keep Current Architecture?

### When NOT to Refactor

Consider keeping your current architecture if:
- ✅ App is working well
- ✅ You're still learning and current pattern makes sense
- ✅ Team is small (just you)
- ✅ Project is for learning/personal use
- ✅ You want to ship features quickly

### When TO Refactor

Consider MVVM if:
- 📈 Views are getting too complex (>300 lines)
- 🔄 You're duplicating logic
- 🧪 You want better test coverage
- 👥 Working with a team
- 📱 Planning to add Widget/Watch app
- 🏢 Building for production/clients

---

## My Recommendation

Given that this is your **first iOS app** and a **learning project**, here's what I'd suggest:

### Option A: Gradual MVVM (Recommended)
1. **Start small**: Extract MessageType and AlertState first
2. **Pick one view**: Refactor DashboardView to ViewModel
3. **Learn and evaluate**: See if you like the pattern
4. **Decide**: Continue or stick with current approach

**Pros:**
- Learn MVVM pattern
- Better testing
- Industry-standard approach
- Portfolio-ready code

**Cons:**
- Takes time
- Steeper learning curve
- More boilerplate initially

### Option B: Hybrid Approach
- Keep current architecture for simple views (Settings, BusinessCard)
- Use ViewModels only for complex views (Dashboard, Search)
- Extract shared types to reduce duplication

**Pros:**
- Pragmatic balance
- Quick wins without full refactor
- Flexibility

### Option C: Keep Current (Also Valid!)
- Your current architecture is **actually fine** for this app size
- Focus on features instead of architecture
- Refactor later if needed

**Pros:**
- Fast development
- Less complexity
- Good enough for now

---

## Next Steps

If you want to proceed with MVVM refactoring, I can help you:

1. **Create the shared types** (MessageType, AlertState)
2. **Build DashboardViewModel** with full tests
3. **Refactor DashboardView** to use it
4. **Write migration guide** for other views
5. **Update documentation**

Or if you prefer, we can:
- **Keep current architecture** and focus on new features
- **Do a hybrid approach** with selective refactoring
- **Discuss other architectural improvements**

What would you like to do? 🤔
