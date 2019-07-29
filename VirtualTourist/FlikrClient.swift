//
//  FlikrClient.swift
//  VirtualTourist
//
//  Created by Michael Maryanoff on 7/29/19.
//  Copyright © 2019 Michael Maryanoff. All rights reserved.
//

import Foundation

class FlikrClient {
    
    let baseURLString = "https://www.flickr.com/services/rest/"
    let apiKey = "api_key=cfcda78c06f98952812fc893f4c92f24"
    let method = "method=flickr.photos.search"
    let radius = "radius=10"
    
    struct RequestConstants {
        
    }
    
    func requestPhotos(lat: Double, long: Double, completion: @escaping(Bool, Error?) -> Void) {
        var url = baseURLString + "?" + method + "&" + apiKey + "&" + "lat=\(lat)" + "&" + "lon=\(long)" + "&" + radius + "&format=json" + "&nosjoncallback=1"
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
