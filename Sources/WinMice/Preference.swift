import Foundation

/// A value that can round-trip through `UserDefaults`.
protocol PreferenceRepresentable: Sendable {
    /// Returns the stored value, or `nil` when nothing valid is stored yet.
    static func preferenceValue(in defaults: UserDefaults, forKey key: String) -> Self?
    func store(in defaults: UserDefaults, forKey key: String)
}

/// A `UserDefaults` key bundled with the value to use before the user picks one.
struct Preference<Value: PreferenceRepresentable>: Sendable {
    let key: String
    let defaultValue: Value

    init(_ key: String, default defaultValue: Value) {
        self.key = key
        self.defaultValue = defaultValue
    }
}

extension UserDefaults {
    subscript<Value: PreferenceRepresentable>(preference: Preference<Value>) -> Value {
        get { Value.preferenceValue(in: self, forKey: preference.key) ?? preference.defaultValue }
        set { newValue.store(in: self, forKey: preference.key) }
    }

    /// Whether the user has ever set this preference, as opposed to falling back to its default.
    func hasValue<Value: PreferenceRepresentable>(for preference: Preference<Value>) -> Bool {
        object(forKey: preference.key) != nil
    }
}

extension Bool: PreferenceRepresentable {
    static func preferenceValue(in defaults: UserDefaults, forKey key: String) -> Bool? {
        defaults.object(forKey: key) as? Bool
    }

    func store(in defaults: UserDefaults, forKey key: String) {
        defaults.set(self, forKey: key)
    }
}

extension Int: PreferenceRepresentable {
    static func preferenceValue(in defaults: UserDefaults, forKey key: String) -> Int? {
        defaults.object(forKey: key) as? Int
    }

    func store(in defaults: UserDefaults, forKey key: String) {
        defaults.set(self, forKey: key)
    }
}

extension PreferenceRepresentable where Self: RawRepresentable, RawValue == String {
    static func preferenceValue(in defaults: UserDefaults, forKey key: String) -> Self? {
        defaults.string(forKey: key).flatMap(Self.init(rawValue:))
    }

    func store(in defaults: UserDefaults, forKey key: String) {
        defaults.set(rawValue, forKey: key)
    }
}
