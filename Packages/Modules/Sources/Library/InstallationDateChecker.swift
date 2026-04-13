import Foundation

public class InstallationDateChecker {
    /// Returns the date when the app was installed based on the creation date of the Documents directory.
    public static func getAppInstallationDate() -> Date {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return Date()
        }
        if let attributes = try? FileManager.default.attributesOfItem(atPath: documentsURL.path),
           let creationDate = attributes[.creationDate] as? Date {
            return creationDate
        }
        return Date()
    }
    
    /// Checks if the app was installed within the specified number of days.
    public static func isRecentlyInstalled(days: Int) -> Bool {
        let installDate = getAppInstallationDate()
        let currentDate = Date()
        let calendar = Calendar.current
        if let daysDifference = calendar.dateComponents([.day], from: installDate, to: currentDate).day {
            return daysDifference <= days
        }
        return false
    }
}
