//
//  FlikrClient.swift
//  VirtualTourist
//
//  Created by Michael Maryanoff on 7/29/19.
//  Copyright © 2019 Michael Maryanoff. All rights reserved.
//

import Foundation

class FlikrClient {
    
    
    
    struct RequestConstants {
        static let baseURLString = "https://www.flickr.com/services/rest/"
        static let apiKey = "api_key=cfcda78c06f98952812fc893f4c92f24"
        static let method = "method=flickr.photos.search"
        static let radius = "radius=10"
    }
    
    func requestPhotos(lat: Double, long: Double, completion: @escaping(Bool, Error?) -> Void) {
        var url = RequestConstants.baseURLString + "?" + RequestConstants.method + "&" + RequestConstants.apiKey + "&" + "lat=\(lat)" + "&" + "lon=\(long)" + "&" + RequestConstants.radius + "&format=json" + "&nosjoncallback=1"
        var request = URLRequest(url: URL(string: url)!)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            print(url)
            print(String(data: data!, encoding: .utf8)!)
        }
        task.resume()
    }
    
    class func shared() -> FlikrClient {
        struct Singleton {
            private init() {}
            static var shared = FlikrClient()
        }
        return Singleton.shared
    }
}
