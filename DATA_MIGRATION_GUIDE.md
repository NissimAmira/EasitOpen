# Data Migration Guide

## What Happened

When updating to Phase 4 & 6, SwiftData detected schema changes and deleted existing businesses. This happened because:

1. **No Schema Versioning**: SwiftData defaults to wiping data when it detects model changes
2. **Model Changes**: Adding optional fields triggers schema updates
3. **No Migration Plan**: No explicit migration path was defined

## Current Protection

The app now has basic migration handling in `EasitOpenApp.swift`:
- Attempts to preserve data when adding optional fields
- Logs warnings if migration fails
- Provides clear error messages

## Best Practices for Future Updates

### Safe Changes (No Data Loss)

These changes are generally safe and won't cause data loss:

✅ **Adding Optional Properties**
```swift
@Model
class Business {
    // Existing properties...
    var newOptionalField: String? = nil  // ✅ Safe - has default
}
```

✅ **Adding Computed Properties**
```swift
var calculatedValue: Int {
    return someProperty * 2  // ✅ Safe - not stored
}
```

✅ **Adding Methods**
```swift
func doSomething() {
    // ✅ Safe - doesn't affect storage
}
```

### Dangerous Changes (Potential Data Loss)

These changes require careful migration planning:

⚠️ **Adding Required Properties**
```swift
@Model
class Business {
    var newRequiredField: String  // ⚠️ Dangerous - no default value
}
```

**Solution:** Add with optional first, then migrate data, then make required

⚠️ **Renaming Properties**
```swift
@Model
class Business {
    // var oldName: String  // Deleted
    var newName: String     // ⚠️ SwiftData sees this as new field
}
```

**Solution:** Use `@Attribute(.originalName("oldName"))` to preserve data

⚠️ **Changing Property Types**
```swift
@Model
class Business {
    var age: String  // Was Int  // ⚠️ Data conversion needed
}
```

**Solution:** Implement custom migration or add new field + migrate + remove old

⚠️ **Removing Properties**
```swift
@Model
class Business {
    // Deleted: var obsoleteField: String
}
```

**Solution:** Comment out first, verify in next release, then remove

## Proper Migration Process

### Step 1: Create Schema Versions

```swift
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [Business.self, DaySchedule.self]
    }
    
    @Model
    class Business {
        // Original schema
    }
}

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [Business.self, DaySchedule.self]
    }
    
    @Model
    class Business {
        // Updated schema with new fields
    }
}
```

### Step 2: Define Migration Plan

```swift
enum EasitOpenMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }
    
    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }
    
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: { context in
            // Prepare migration
        },
        didMigrate: { context in
            // Cleanup after migration
        }
    )
}
```

### Step 3: Update ModelContainer

```swift
.modelContainer(for: SchemaV2.self, migrationPlan: EasitOpenMigrationPlan.self)
```

## Quick Reference: Change Impact

| Change | Risk | Requires Migration | Example |
|--------|------|-------------------|---------|
| Add optional property | Low | No | `var field: String? = nil` |
| Add computed property | None | No | `var total: Int { a + b }` |
| Add method | None | No | `func calculate() { }` |
| Add required property | High | Yes | `var field: String` |
| Rename property | High | Yes | Use `@Attribute` |
| Change type | High | Yes | Custom migration |
| Remove property | Medium | Maybe | Test first |
| Add relationship | Medium | Maybe | Depends on optionality |

## Recovery Tips

### If Data Was Lost

1. **Check for Backups**:
   - iCloud backup (if enabled)
   - iTunes/Finder backup
   - TestFlight previous versions

2. **Restore from Backup**:
   ```bash
   # Restore app data from iPhone backup
   # Settings > General > Transfer or Reset iPhone > Reset
   ```

3. **Re-add Businesses**:
   - Use Search tab to find businesses again
   - Import from exported data (if you had export feature)

### Prevent Future Loss

1. **Test on Clean Device**: Always test updates on a device without data first
2. **Use TestFlight**: Distribute to testers before public release
3. **Version Clearly**: Use semantic versioning (1.0.0, 1.1.0, 2.0.0)
4. **Document Changes**: Keep changelog of model changes
5. **Add Export**: Implement data export feature for user backups

## When to Version

**Always create new version for:**
- Public releases (App Store)
- TestFlight releases
- Major feature additions
- Any model changes affecting stored data

**Optional for:**
- Internal development
- Adding computed properties
- UI-only changes
- Bug fixes not touching models

## Testing Migrations

```swift
// Test migration in unit tests
func testMigrationV1toV2() async throws {
    // 1. Create V1 container with test data
    let v1Container = try ModelContainer(for: SchemaV1.self)
    let v1Context = ModelContext(v1Container)
    
    let oldBusiness = SchemaV1.Business(name: "Test", ...)
    v1Context.insert(oldBusiness)
    try v1Context.save()
    
    // 2. Migrate to V2
    let v2Container = try ModelContainer(
        for: SchemaV2.self,
        migrationPlan: EasitOpenMigrationPlan.self
    )
    
    // 3. Verify data preserved
    let v2Context = ModelContext(v2Container)
    let businesses = try v2Context.fetch(FetchDescriptor<SchemaV2.Business>())
    
    XCTAssertEqual(businesses.count, 1)
    XCTAssertEqual(businesses.first?.name, "Test")
}
```

## Current Schema (v1.0.0)

```swift
@Model
class Business {
    var id: UUID
    var googlePlaceId: String?
    var name: String
    var customLabel: String?
    var address: String
    var latitude: Double
    var longitude: Double
    var phoneNumber: String?
    var website: String?
    var openingHours: [DaySchedule]
    var dateAdded: Date
    var lastUpdated: Date
    var lastChecked: Date?
}

@Model
class DaySchedule {
    var weekday: Int
    var openTime: Int
    var closeTime: Int
    var isClosed: Bool
}
```

## Future Additions

If you need to add fields in the future:

1. **Always make them optional first**:
   ```swift
   var newField: String? = nil
   ```

2. **Add with default values**:
   ```swift
   var newField: String = "default"
   ```

3. **For complex types, use optional**:
   ```swift
   var newRelationship: RelatedModel? = nil
   ```

4. **Document the change**:
   ```swift
   // Added in v1.1.0 - stores user preferences
   var preferences: UserPreferences? = nil
   ```

## Resources

- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [Schema Migration Guide](https://developer.apple.com/documentation/swiftdata/migrating-your-app)
- [Versioned Schema](https://developer.apple.com/documentation/swiftdata/versionedschema)

## Note for This Update

**For the current update (Phase 4 & 6):**
- Data loss has already occurred
- Future updates now have basic protection
- Consider implementing full schema versioning before next major release
- Users will need to re-add businesses (one-time inconvenience)

**Apology to Users:**
We apologize for the data loss. This was a learning experience in iOS development. Future updates will handle data migration properly to prevent this from happening again.
