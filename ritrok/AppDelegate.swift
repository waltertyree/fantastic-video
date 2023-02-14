//
//  AppDelegate.swift
//  ritrok
//
//  Created by Walter Tyree on 12/28/22.
//

import UIKit
import os
import VideoEditorSDK

//Create a logger we can use everywhere
let logger = Logger(subsystem: "com.example.ritrok", category: "application")


@main
class AppDelegate: UIResponder, UIApplicationDelegate {



  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    globalConfiguration()

    //Make sure we have a "finished" folder in our documents directory
    //    if let documentDirectory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
    //      let finishedVideos = documentDirectory.appendingPathComponent("finished")
    //      if !FileManager.default.fileExists(atPath: finishedVideos.path) {
    //        do {
    //          try FileManager.default.createDirectory(at: finishedVideos, withIntermediateDirectories: true)
    //        } catch let error as NSError {
    //          logger.error("Unable to create directory \(error.localizedDescription)")
    //        }
    //      }
    //    }

    return true
  }

  // MARK: UISceneSession Lifecycle

  func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }

  func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
  }

  func globalConfiguration() {
    //unlock with the license file to remove the watermark
    if let licenseURL = Bundle.main.url(forResource: "vesdk_ios_license", withExtension: "") {
      VESDK.unlockWithLicense(at: licenseURL)
    }


    
    IMGLY.bundleImageBlock = { imageName in
      logger.debug("requested icon: \(imageName)")
      //      Icons that the camera view wants
      //      imgly_icon_flash_auto
      //      imgly_icon_cam_switch
      //      imgly_icon_show_filter
      //      imgly_icon_flash_off
      switch imageName {
      case "imgly_icon_cam_switch":
        return UIImage(named: "336-reloop")?.icon(pt: 48)
      case "imgly_icon_show_filter":
        return UIImage(systemName: "camera.filters", withConfiguration: UIImage.SymbolConfiguration(scale: .large))?.icon(pt: 48, alpha: 1)
      default:
        return nil
      }
    }
  }

}

// Helper extension for replacing default icons with custom icons.
extension UIImage {
  /// Create a new icon image for a specific size by centering the input image and optionally applying alpha blending.
  /// - Parameters:
  ///   - pt: Icon size in point (pt).
  ///   - alpha: Icon alpha value.
  /// - Returns: A new icon image.
  func icon(pt: CGFloat, alpha: CGFloat = 1) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(CGSize(width: pt, height: pt), false, scale)
    let position = CGPoint(x: (pt - size.width) / 2, y: (pt - size.height) / 2)
    draw(at: position, blendMode: .normal, alpha: alpha)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return newImage
  }
}

