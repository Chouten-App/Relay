//
//  AppDelegate.swift
//  Chouten
//
//  Created by Inumaki on 13/10/2024.
//

import UIKit
import GoogleCast
import AVFoundation
import Network

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func copyFileToDocumentsFolder(nameForFile: String, extForFile: String) {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let destURL = documentsURL.unsafelyUnwrapped
            .appendingPathComponent("Themes")
            .appendingPathComponent(nameForFile)
            .appendingPathExtension(extForFile)
        
        let fileExists = (try? destURL.checkResourceIsReachable()) ?? false
        if fileExists {
            return
        }
        
        guard let sourceURL = Bundle.main.url(forResource: nameForFile, withExtension: extForFile) else {
            print("Source File not found.")
            return
        }
        let fileManager = FileManager.default
        do {
            try fileManager.copyItem(at: sourceURL, to: destURL)
        } catch {
            print("Unable to copy file")
        }
    }
    
    func createModuleAndThemesFoldersIfNeeded() {
        let fileManager = FileManager.default
        let documentsURL = (try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)).unsafelyUnwrapped
        let modulesURL = documentsURL.appendingPathComponent("Repos", isDirectory: true)
        let themesURL = documentsURL.appendingPathComponent("Themes", isDirectory: true)
        let cacheURL = documentsURL.appendingPathComponent("CACHE", isDirectory: true)
        
        var isDirectory: ObjCBool = false
        
        if !fileManager.fileExists(atPath: modulesURL.path, isDirectory: &isDirectory) {
            do {
                try fileManager.createDirectory(at: modulesURL, withIntermediateDirectories: false, attributes: nil)
                print("Created Repos folder")
            } catch {
                print("Error: \(error)")
            }
        }
        
        if !fileManager.fileExists(atPath: themesURL.path, isDirectory: &isDirectory) {
            do {
                try fileManager.createDirectory(at: themesURL, withIntermediateDirectories: false, attributes: nil)
                print("Created Themes folder")
            } catch {
                print("Error: \(error)")
            }
        }
        
        if fileManager.fileExists(atPath: cacheURL.path, isDirectory: &isDirectory) {
            do {
                try fileManager.removeItem(at: cacheURL)
                print("Removed CACHE folder")
            } catch {
                print("Error: \(error)")
            }
        }
    }
    
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        print("Application directory: \(NSHomeDirectory())")
        
        // create modules and theme folder if they dont exist
        createModuleAndThemesFoldersIfNeeded()
        
        let options = GCKCastOptions(discoveryCriteria: GCKDiscoveryCriteria(applicationID: kGCKDefaultMediaReceiverApplicationID))
        GCKCastContext.setSharedInstanceWith(options)
        
        requestPermissions()
        
        return true
    }
    
    private func requestPermissions() {
        // Check Bluetooth permission
        let bluetoothStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        if bluetoothStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                if granted {
                    print("Bluetooth access granted.")
                } else {
                    print("Bluetooth access denied.")
                }
            }
        }

        // Check Local Network permission (iOS 14 and later)
        let localNetworkStatus = NWPathMonitor().currentPath.status
        if localNetworkStatus == .requiresConnection || localNetworkStatus == .satisfied {
            print("Local network access is already granted.")
        } else {
            // Here you can inform the user that they need to enable Local Network access in settings
            print("Local network access is not granted.")
        }
    }
    
    func application(_: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options _: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        let configuration = UISceneConfiguration(
            name: connectingSceneSession.configuration.name,
            sessionRole: connectingSceneSession.role
        )
        
        configuration.delegateClass = SceneDelegate.self
        
        return configuration
    }
    
    func application(_: UIApplication, didDiscardSceneSessions _: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

