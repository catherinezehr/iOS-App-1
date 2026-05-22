//
//  ContentView.swift
//  golf app
//
//  Created by ccz8 on 5/20/26.
//

import SwiftUI

struct ContentView: View
{
    private let api = GolfAPI()
    
    @State private var courses: [GolfAPI.Course] = []
    @State private var isLoading = false
    @State private var error: String?
    
    
    //use the body to describle the design of the app
    var body: some View
    {
        NavigationStack
        {
            Group
            {
                if isLoading
                {
                    VStack
                    {
                        Image(systemName: "figure.golf")
                            .imageScale(.large)
                            .foregroundStyle(.tint)
                            .foregroundColor(Color.green)
                        Text("loading courses...")
                    }
                    .padding()
                }
                
                else
                {
                    VStack
                    {
                        List(courses, id: \.id)
                        {
                            course in
                            VStack
                            {
                                Text(course.club_name).font(.headline)
                                Text(course.course_name).font(.headline)
                                Text(course.location.state ?? "unknown location").font(.caption)
                            }
                        }
                        
                    }
                }
            }
            .task
            {
                //for debugging:
                print("task started yippee")
                do {try await loadCourses()}
                catch {self.error = error.localizedDescription
                    print("error boo: \(error)")
                }
            }
        }
    }
    
    //create a function to actually call the created api class and retrieve the data
    //make the function async because then it can await the data from the api since it might take time to fetch
    func loadCourses() async throws
    {
        //for debugging
        print("started loading courses YIPPEE")
        isLoading = true //when function is first called, it is loading from api
        
        defer {isLoading = false} //at the very end, once the function has been executed, the loading is done
        
        //call the api class
        do {courses = try await api.fetchFromAPI()}
        catch {throw error}
    }
    
}
