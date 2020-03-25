/// Struct that provides common utility methods for RakutenInAppMessaging module.
internal struct CommonUtility {

    /// Convert Data type responses to `[String: Any]?` type.
    static func convertDataToDictionary(_ data: Data) -> [String: Any]? {
        do {
            guard let jsonData = try JSONSerialization
                .jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                    return nil
            }

            return jsonData
        } catch {
            debugPrint("InAppMessaging: Error converting data: \(error)")
            return nil
        }
    }

    /// Provides a way to lock objects when performing a function.
    /// - Parameter objects: A list of objects with resources to lock.
    /// - Parameter operation: The function to perform with the objects locked.
    static func lock(resourcesIn objects: [Lockable], for operation: () -> Void) {
        let resourcesToLock = objects.flatMap { $0.resourcesToLock }

        resourcesToLock.forEach { $0.lock() }
        operation()
        resourcesToLock.forEach { $0.unlock() }
    }

    /// Converts a `Trigger` object from `Button` object to a `CustomEvent`.
    /// - Parameter trigger: The trigger object to parse out.
    /// - Returns: The event object created the trigger object.
    static func convertTriggerObjectToCustomEvent(_ trigger: Trigger) -> CustomEvent {
        var attributeList = [CustomAttribute]()

        for attribute in trigger.attributes {
            if let customAttribute = convertAttributeObjectToCustomAttribute(attribute) {
                attributeList.append(customAttribute)
            }
        }

        return CustomEvent(withName: trigger.eventName, withCustomAttributes: attributeList)
    }

    /// Converts a `TriggerAttribute` into a `CustomAttribute`.
    /// - Parameter attribute: The trigger attribute to convert.
    /// - Returns: Converted trigger as `CustomAttribute` object (Optional).
    static func convertAttributeObjectToCustomAttribute(_ attribute: TriggerAttribute) -> CustomAttribute? {
        switch attribute.type {
        case .invalid:
            return nil
        case .string:
            return CustomAttribute(withKeyName: attribute.name, withStringValue: attribute.value)
        case .integer:
            guard let value = Int(attribute.value) else {
                break
            }

            return CustomAttribute(withKeyName: attribute.name, withIntValue: value)
        case .double:
            guard let value = Double(attribute.value) else {
                break
            }

            return CustomAttribute(withKeyName: attribute.name, withDoubleValue: value)
        case .boolean:
            var value: Bool?
            if let intRepresentation = Int(attribute.value) {
                value = Bool(exactly: NSNumber(value: intRepresentation))
            } else {
                value = Bool(attribute.value.lowercased())
            }
            guard let unwrappedValue = value else {
                break
            }

            return CustomAttribute(withKeyName: attribute.name, withBoolValue: unwrappedValue)
        case .timeInMilli:
            guard let value = Int(attribute.value) else {
                break
            }

            return CustomAttribute(withKeyName: attribute.name, withTimeInMilliValue: value)
        }

        debugPrint("InAppMessaging: Error converting value.")
        return nil
    }

    static func debugPrint(_ value: Any?) {
        #if DEBUG
            print(String(describing: value))
        #endif
    }

    static func debugPrint(_ message: String) {
        #if DEBUG
            print(message)
        #endif
    }
}