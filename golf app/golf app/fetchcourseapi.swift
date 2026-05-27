//
//  fetchcourseapi.swift
//  golf app
//
//  Created by ccz8 on 5/27/26.
//

//other api fetch handles getting basic course data including course name, hole pars, etc.
//this api fetch file handles retrieving the map data for each individual hole for each course

import Foundation


//using open street map (OSM) api to get course data/maps of each hole based on the coordinates
class CourseHoleInfo
{
    func fetchCourseInfo(latitude: Double, longitude: Double) async throws -> OSMResponse
    {
        //create the bounding square around the course
        let delta = 0.01
        let boundingbox = "\(latitude-delta), \(longitude-delta), \(latitude+delta), \(longitude+delta)"
        
        //going to collect data as a json for parsing
        let query = """
        [out:json][timeout:30];
        (
            way["golf"="hole"](\(boundingbox));
            way["golf"="fairway"](\(boundingbox));
            way["golf"="green"](\(boundingbox));
            way["golf"="tee"](\(boundingbox));
            way["golf"="bunker"](\(boundingbox));
        );
        out geom;
        """
        
        //convert the query into something safe for adding to url
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        guard let url = URL(string: "https://overpass-api.de/api/interpreter?data=\(encoded)")
        else
        {
            throw OSMError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(OSMResponse.self, from: data)
    }
    
    //isolate the coordinates for each hole on the course
    func teeCoordinates(for holeNumber: Int, in response: OSMResponse) -> (lat: Double, lon: Double)?
    {
        let holeLine = response.elements.first
        {
            $0.tags?["golf"] == "hole" &&
            $0.tags?["ref"] == "\(holeNumber)"
        }
        guard let firstNode = holeLine?.geometry?.first
        else {return nil}
            
        return(firstNode.lat, firstNode.lon)
    }
    
    //structs for decoding
    struct OSMResponse: Decodable
    {
        let elements: [OSMElement]
    }
    
    struct OSMElement: Decodable
    {
        let id: Int
        let tags: [String: String]?
        let geometry: [OSMNode]?
    }
    
    struct OSMNode: Decodable
    {
        let lat: Double
        let lon: Double
    }
    
    enum OSMError: Error
    {
        case invalidURL
    }
}
