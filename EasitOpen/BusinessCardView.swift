import SwiftUI

struct BusinessCardView: View {
    let business: Business
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Business name and status badge
            HStack {
                Text(business.displayName)
                    .font(.headline)
                
                Spacer()
                
                // Status badge
                Text(business.status.text)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(business.status.color)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            // Address
            Text(business.address)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Today's hours
            if let todaySchedule = getTodaySchedule() {
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if todaySchedule.isClosed {
                        Text("Closed today")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(todaySchedule.openTimeFormatted) - \(todaySchedule.closeTimeFormatted)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func getTodaySchedule() -> DaySchedule? {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        return business.openingHours.first(where: { $0.weekday == weekday })
    }
}

#Preview {
    // Create sample business for preview
    let sampleSchedule = DaySchedule(weekday: 3, openTime: 540, closeTime: 1020) // 9 AM - 5 PM
    let sampleBusiness = Business(
        name: "Coffee Shop",
        address: "123 Main St, City",
        latitude: 0,
        longitude: 0,
        openingHours: [sampleSchedule]
    )
    
    return BusinessCardView(business: sampleBusiness)
        .padding()
}
