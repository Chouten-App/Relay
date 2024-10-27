//
//  UIImageView+Extensions.swift
//  Chouten
//
//  Created by Inumaki on 19/10/2024.
//

import Nuke
import UIKit

extension UIImageView {
    func setAsyncImage(url: String) {
        if let imageUrl = URL(string: url) {
            let cookies = UserDefaults.standard.string(forKey: "Cookies-\(imageUrl.getDomain() ?? "")")
            var request = URLRequest(url: imageUrl)
            request.setValue(AppConstants.userAgent, forHTTPHeaderField: "User-Agent")
            request.setValue(cookies, forHTTPHeaderField: "Cookie")
            let imageRequest = ImageRequest(urlRequest: request)
            
            ImagePipeline.shared.loadImage(with: imageRequest) { result in
                do {
                    let imageResponse = try result.get()
                    self.image = imageResponse.image
                } catch {
                    print("\(error)")
                }
            }
        }
    }
    
    func setRepoImage(id: String) {
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let repoUrl = documentsDirectory.appendingPathComponent("Repos").appendingPathComponent(id)
            
            do {
                let files = try FileManager.default.contentsOfDirectory(atPath: repoUrl.path)
                        
                // Define the image file extensions
                let imageExtensions = ["png", "jpg", "jpeg", "gif", "bmp", "tiff"]
                
                // Filter the files for "icon" or "Icon" with specified extensions
                let foundImages = files.filter { file in
                    let fileName = file.lowercased() // Convert to lowercase for case-insensitivity
                    let fileExtension = (fileName as NSString).pathExtension // Get the file extension
                    
                    return (fileName.hasPrefix("icon") && imageExtensions.contains(fileExtension))
                }
                
                if let imagePath = foundImages.first {
                    let imageData = try? Data(contentsOf: repoUrl.appendingPathComponent(imagePath))
                    
                    if let imageData {
                        if imagePath.contains(".gif") {
                            self.animateGIF(data: imageData)
                        } else {
                            self.image = UIImage(data: imageData)
                        }
                    }
                }
            } catch {
                print("failed to find icon.")
            }
        }
    }
    
    func animateGIF(data: Data) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return }
        
        let count = CGImageSourceGetCount(source)
        var images = [UIImage]()
        var duration: TimeInterval = 0
        
        for i in 0..<count {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: image))
                // Get the duration of each frame
                if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
                   let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any],
                   let delay = gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String] as? TimeInterval {
                    duration += delay
                }
            }
        }
        
        // Animate the images
        self.animationImages = images
        self.animationDuration = duration
        self.startAnimating()
    }
}
