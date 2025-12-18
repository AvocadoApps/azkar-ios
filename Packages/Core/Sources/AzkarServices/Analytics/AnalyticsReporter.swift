import Foundation
import UIKit
import Extensions

// MARK: - AnalyticsTarget Protocol

/// Protocol that defines the required methods for any analytics reporting target.
public protocol AnalyticsTarget {
    func reportEvent(name: String, metadata: [String: Any]?)
    func reportScreen(screenName: String, className: String?)
    func setUserAttribute(_ type: UserAttributeType, value: String)
}

// MARK: - UserAttributeType Enum

/// Enum representing different types of user attributes.
public enum UserAttributeType: String {
    case age
    case gender
    case custom // For any custom attributes not predefined
}

// MARK: - AnalyticsReporter Class

/// Singleton class responsible for managing analytics reporting.
public final class AnalyticsReporter {
    
    // MARK: - Properties
    
    /// Shared instance of AnalyticsReporter.
    static let shared = AnalyticsReporter()
    
    /// Array of analytics targets to report to.
    private var targets: [AnalyticsTarget] = []
    
    /// Serial queue to ensure thread-safe operations.
    private let serialQueue = DispatchQueue(label: "com.analyticsReporter.serialQueue")
    
    // MARK: - Initializer
    
    /// Private initializer to enforce singleton usage.
    private init() {}
    
    // MARK: - Private Methods
    
    private func logEvent(name: String, metadata: [String: Any]?) {
        var message = "[ANALYTICS] Event: \(name)"
        if let metadata = metadata, !metadata.isEmpty {
            message += ", Metadata: \(metadata)"
        }
        print(message)
    }
    
    private func logScreen(screenName: String, className: String?) {
        var message = "[ANALYTICS] Screen: \(screenName)"
        if let className = className {
            message += ", Class: \(className)"
        }
        print(message)
    }
    
    private func logUserAttribute(_ type: UserAttributeType, value: String) {
        print("[ANALYTICS] User Attribute: \(type.rawValue) = \(value)")
    }
    
    // MARK: - Public Methods
    
    /// Adds an analytics target.
    /// - Parameter target: An object conforming to AnalyticsTarget protocol.
    public static func addTarget(_ target: AnalyticsTarget) {
        shared.serialQueue.sync {
            shared.targets.append(target)
        }
    }
    
    /// Reports an event to all added analytics targets.
    /// - Parameters:
    ///   - name: The name of the event.
    ///   - metadata: Optional dictionary containing additional information about the event.
    public static func reportEvent(_ name: String, metadata: [String: Any]? = nil) {
        shared.serialQueue.sync {
            if UIApplication.shared.shouldSendAnalytics {
                for target in shared.targets {
                    target.reportEvent(name: name, metadata: metadata)
                }
            } else {
                shared.logEvent(name: name, metadata: metadata)
            }
        }
    }

    /// Reports a screen view to all added analytics targets.
    /// - Parameters:
    ///   - screenName: The name of the screen.
    ///   - className: The name of the class.
    public static func reportScreen(_ screenName: String, className: String? = nil) {
        shared.serialQueue.sync {
            if UIApplication.shared.shouldSendAnalytics {
                for target in shared.targets {
                    target.reportScreen(screenName: screenName, className: className)
                }
            } else {
                shared.logScreen(screenName: screenName, className: className)
            }
        }
    }
    
    /// Sets a user attribute for all added analytics targets.
    /// - Parameters:
    ///   - type: The type of the user attribute.
    ///   - value: The value of the user attribute.
    public static func setUserAttribute(_ type: UserAttributeType, value: String) {
        shared.serialQueue.sync {
            if UIApplication.shared.shouldSendAnalytics {
                for target in shared.targets {
                    target.setUserAttribute(type, value: value)
                }
            } else {
                shared.logUserAttribute(type, value: value)
            }
        }
    }

}
