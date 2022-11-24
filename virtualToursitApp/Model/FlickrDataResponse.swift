//
//  FlickrDataResponse.swift
//  virtualToursitApp
//
//  Created by MACBOOK PRO on 11/24/22.
//

import Foundation

struct FlickrDataResponse: Codable {
    let photos: PhotoResult
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case photos = "photos"
        case status = "stat"
    }
}

struct PhotoResult: Codable {
    let page: Int
    let pages: Int
    let perpage: Int
    let total: Int
    let photo: [FlickrPhoto]
}

struct FlickrPhoto: Codable {
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
    let ispublic: Int
    let isfriend: Int
    let isfamily: Int
    
}

