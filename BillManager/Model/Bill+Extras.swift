//
//  Bill+Extras.swift
//  BillManager
//

import Foundation
import UserNotifications

extension Bill {
        
    static let notficationCategoryID = "notificationCategoryID"
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
    
    var hasReminder: Bool {
        return (remindDate != nil)
    }
    
    var isPaid: Bool {
        return (paidDate != nil)
    }
    
    var formattedDueDate: String {
        let dateString: String
        
        if let dueDate = self.dueDate {
            dateString = Bill.dateFormatter.string(from: dueDate)
        } else {
            dateString = ""
        }
        
        return dateString
    }
    
    mutating func removeReminder() {
        if let nID = notificationID {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [nID])
            notificationID = nil
            remindDate = nil
            
        }
    }
    
    mutating func scheduleReminder(date: Date, completion: @escaping (Bill) -> ()) {
        var updatedBill = self
        updatedBill.removeReminder()
        
        isAuthorized { granted in
            guard granted else {
                DispatchQueue.main.async {
                    completion(updatedBill)
                }
                return
            }
            
            let content = UNMutableNotificationContent()
            
            content.title = "Bill Reminder"
            content.body = "$\(updatedBill.amount ?? 0) due to \(updatedBill.payee ?? "") on \(updatedBill.formattedDueDate)"
            content.categoryIdentifier = Bill.notficationCategoryID
            content.sound = UNNotificationSound.default
            
            
            let triggerDateComponents = Calendar.current.dateComponents([.second, .minute, .hour, .day, .month, .year], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDateComponents, repeats: false)
            
            let notificationId = UUID().uuidString
            
            let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print(error.localizedDescription)
                    } else {
                        updatedBill.notificationID = notificationId
                        updatedBill.remindDate = date
                    }
                    DispatchQueue.main.async {
                        completion(updatedBill)
                    }
                }
            }
        }
        
    }
    
    private func isAuthorized(completion: @escaping (Bool) -> ()) {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings { (settings) in
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                completion(true)
            case .denied, .ephemeral:
                completion (false)
            case .notDetermined:
                notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    completion(granted)
                }
            }
            
        }
    }
    
}
