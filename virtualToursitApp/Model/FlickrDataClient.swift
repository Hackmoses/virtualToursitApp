//
//  FlickrDataClient.swift
//  virtualToursitApp
//
//  Created by MACBOOK PRO on 11/24/22.
//


import Foundation
import UIKit

class FlickrDataClient {
    
    static let apiKey = "b3c9e6ddd0d3b466cad46d43b86ffce4"
    
    enum Endpoints {
        
        static let base = "https://api.flickr.com/services/rest/?method=flickr.photos.search"
        
        case getPhotos(Double, Double)
        case getUrls(String, String, String)
        
        var stringValue: String {
            
            switch self {
                
            case.getPhotos(let latitude, let longitude):
                return Endpoints.base + "&api_key=\(FlickrDataClient.apiKey)&lat=\(latitude)&lon=\(longitude)&per_page=20&page=\(Int.random(in: 1...10))&format=json&nojsoncallback=1"
                
            case .getUrls(let serverId, let id, let secret): return
                "https://live.staticflickr.com/\(serverId)/\(id)_\(secret).jpg"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func taskForGetRequest <ResponseType : Decodable> (url : URL, responseType : ResponseType.Type, completion : @escaping (ResponseType?, Error?)->Void) -> URLSessionTask {
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            let decoder = JSONDecoder()
            
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
                
            } catch  {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        
        task.resume()
        return task
    }
    
    class func getPhotos(latitude : Double, longitude : Double, completion : @escaping (FlickrDataResponse?, Error?) -> Void ) {
        taskForGetRequest(url: Endpoints.getPhotos(latitude, longitude).url, responseType: FlickrDataResponse.self) { response, error in
            
            if let response = response {
                completion(response.self, nil)
                
            } else {
                completion(nil, error)
            }
        }
    }
    
    class func downloadPhotos(imageURL: URL, completion: @escaping (Data?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: imageURL) { data, response, error in
            DispatchQueue.main.async {
                completion(data, error)
            }
        }
        task.resume()
    }
    
}

