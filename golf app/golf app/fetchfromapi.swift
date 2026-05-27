//
//  fetchfromapi.swift
//  golf app
//
//  Created by ccz8 on 5/20/26.
//

//need to import API key from hidden file

import Foundation
import SwiftUI

class GolfAPI
{
    
    func fetchFromAPI(searchTerm: String) async throws -> [Course]

        {
            //do not want to hardcode api key because of security reasons
            //instead store in config file and then access from there
            guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
                    let config = NSDictionary(contentsOfFile: path) as? [String: Any],
                    let apiKey = config["API_KEY"] as? String
            else //need an else statement anytime you use guard
            {
                throw FetchError.invalidAPIKey
            }
            
            //change the term entered by the user to ensure the url isn't broken if they add spaces
            let encoded = searchTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? searchTerm

            //set up the url for the api
            //use guard and else error in case the url is invalid
            guard let url = URL(string:"https://api.golfcourseapi.com/v1/search?search_query=\(encoded)")
            else
            {
                throw FetchError.invalidUrl
            }

            //api is protected by key so need to use http headers to authenticate
            //golf api stated you need to "include a request header in the format 'Authorization: Key {api_key}'
            var request = URLRequest(url: url)
            request.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")

            let (data, _) = try await URLSession.shared.data(for: request)

            let decoded = try JSONDecoder().decode(GolfCourses.self, from: data)

            return decoded.courses

        }

    enum FetchError: Error
    {
        case invalidUrl
        case invalidAPIKey
    }

    struct GolfCourses: Decodable
    {
        let courses: [Course]
    }

    struct Course: Decodable
    {
        let id: Int
        let club_name: String
        let course_name: String
        let location: Location
        let tees: Tees?
    }
    
    struct Location: Decodable
    {
        let address: String?
        let city: String?
        let state: String?
        let country: String?
        let latitude: Double?
        let longitude: Double?
    }
    
    struct Tees: Decodable
    {
        let male: [TeeInfo]?
        let female: [TeeInfo]?
    }
    
    struct TeeInfo: Decodable
    {
        let tee_name: String
        let holes: [CourseInfo]
    }
    
    struct CourseInfo: Decodable
    {
        let par: Int
        let yardage: Int
        let handicap: Int?
    }
        
}


