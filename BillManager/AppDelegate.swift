//
//  AppDelegate.swift
//  BillManager
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    private let remindActionID = "remindAction"
    private let markAsPaidActionID = "markAsPaidAction"
    
    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let remindInAnHour = UNNotificationAction(identifier: remindActionID, title: "Remind in 1 hour", options: [])
        let markAsPaid = UNNotificationAction(identifier: markAsPaidActionID, title: "Already paid", options: [.authenticationRequired])
        
        let category = UNNotificationCategory(identifier: Bill.notficationCategoryID, actions: [remindInAnHour, markAsPaid], intentIdentifiers: [], options: [])
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let notificationID = response.notification.request.identifier
        guard var bill = Database.shared.getBill(notificationID: notificationID) else {
            completionHandler()
            return
        }
        
        if response.actionIdentifier == markAsPaidActionID {
            bill.scheduleReminder(date: Date().addingTimeInterval(60 * 60)) { updatedBill in
                Database.shared.updateAndSave(updatedBill)
            }
        } else if response.actionIdentifier == remindActionID {
            bill.paidDate = Date()
            Database.shared.updateAndSave(bill)
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
}

