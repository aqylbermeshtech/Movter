//
//  ImageLoader.swift
//  MovterNetwork
//
//  Created by Nurtore on 24.03.2026.
//

import UIKit

public final class ImageLoader {
    private static let cache = NSCache<NSString, UIImage>()

    public static func load(url: URL, completion: @escaping (UIImage?) -> Void) {
        if let cached = cache.object(forKey: url.absoluteString as NSString) {
            completion(cached)
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            cache.setObject(image, forKey: url.absoluteString as NSString)
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
}
