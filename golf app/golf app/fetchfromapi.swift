//
//  fetchfromapi.swift
//  golf app
//
//  Created by ccz8 on 5/20/26.
//

//need to import API key from hidden file

import Foundation

struct Environment
{
    static var APIkey: String
    {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "GOLF_API_KEY") as String
        else
        {
            fatalError("missing API key")
        }
        return key
    }
}

class GolfAPI
{
    func fetchCoursesFromAPI() async throws -> [Course]
    {
        //get the API key using the struct to get it from the hidden file
        let APIkey = Environment.APIkey
        //can use String interpolation to include key in link
        let url = URL(string: "https://api.golfcourseapi.com/v1/courses?api_key=\(APIkey)")
        let (data, response) = try await URLSession.shared.data(from: url)
        let coursesList = try JSONDecoder().decode([Course].self, from: data)
        return coursesList
    }

    struct GolfCourses: Decodable
    {
        let results: [Course]
    }

    struct Course: Decodable
    {
        let club_name: String
        let course_name: String
        let address: String
    }
    
}


