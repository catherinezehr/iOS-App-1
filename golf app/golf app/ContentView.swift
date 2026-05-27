//
//  ContentView.swift
//  golf app
//
//  Created by ccz8 on 5/20/26.
//

import SwiftUI
import MapKit
import CoreLocation
import GeoToolbox


//set up different tabs of the apps
//struct TabView: View
//{
//    var body: some View
//    {
//        HomeView().tabItem{Label("Home"), systemImage: "star.fill"}
//    }
//}

struct HomeView: View
{
    var body: some View
    {
        VStack
        {
            Image("golf")
                .resizable()
                .aspectRatio(contentMode: .fit)
            Text("click 'start' to begin viewing courses!").font(.headline).foregroundColor(.white)
        }
    }
}

struct ContentView: View
{
    private let api = GolfAPI()
    
    @State private var courses: [GolfAPI.Course] = []
    @State private var isLoading = false
    @State private var error: String?
    @State var entry: String = ""
    @State private var debouncedEntry: String = ""
    
    
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
                            NavigationLink(destination: CourseDetailView(course: course))
                            {
                                VStack(alignment: .leading)
                                {
                                    Text(course.club_name).font(.headline)
                                    Text(course.course_name).font(.subheadline)
                                    Text(course.location.state ?? "unknown location").font(.caption)
                                    Image(systemName: "figure.golf").imageScale(.small).foregroundColor(Color.green)
                                }
                            }
                        }
                    }
                        
                        
                
                }
            }
            .searchable(text: $entry)
            .onChange(of: entry)
            {
                _, newValue in Task {
                    try? await Task.sleep(for: .milliseconds(200))
                    guard !Task.isCancelled else {return}
                    debouncedEntry = newValue
                }
            }
            .task(id: debouncedEntry)
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
        guard debouncedEntry.count >= 3
        else
        {
                courses = []
                return
        }
        isLoading = true //when function is first called, it is loading from api
        
        defer {isLoading = false} //at the very end, once the function has been executed, the loading is done
        
        //call the api class
        do {courses = try await api.fetchFromAPI(searchTerm: entry)}
        catch {throw error}
    }
    
    
    struct CourseDetailView: View
    {
        let course: GolfAPI.Course
        
        //before printing out the individual tees for each course, want to degroup them by gender and ensure no overlap, since often the male/female tees are the same tee boxes, so listing them twice is unnecessary
        var allTees: [GolfAPI.TeeInfo]
        {
            var all_tees = (course.tees?.male ?? []) + (course.tees?.female ?? [])
            var s = Set<String>()
            all_tees.forEach {tee in
                s.insert(tee.tee_name)}
            var placeholder = 0
            all_tees.forEach {tee in
                if(s.contains(tee.tee_name))
                {
                    s.remove(tee.tee_name)
                    placeholder += 1
                }
                else
                {
                    all_tees.remove(at: placeholder)
                }
            }
            return all_tees
        }
        
        @State private var position: MapCameraPosition
        init(course: GolfAPI.Course)
        {
            self.course = course
            self._position = State(initialValue: MapKit.MapCameraPosition.region(MKCoordinateRegion(center: CLLocationCoordinate2D(
                latitude: course.location.latitude ?? 0.0,
                longitude: course.location.longitude ?? 0.0
            ), span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))))
        }
        
        var body: some View
        {
            VStack(alignment: .leading)
            {
                Map(position: $position)
                {
                }
                .mapStyle(.hybrid(elevation: .realistic, pointsOfInterest: .including([.golf])))
                Text(course.club_name)
                    .font(.headline)
                VStack(alignment: .leading)
                {
                    ForEach(allTees, id: \.tee_name)
                    { tee in
                        NavigationLink(destination: MoreDetailView(tee:tee, courseLocation:course.location))
                        {
                            Text(tee.tee_name).font(.caption)
                        }
                    }
                }
            }
        }
    }
    
    struct MoreDetailView: View
    {
        let tee: GolfAPI.TeeInfo
        let courseLocation: GolfAPI.Location
        
        private let osm = CourseHoleInfo()
        
        var body: some View
        {
            ScrollView
            {
                Text(tee.tee_name).font(.headline)
                VStack(alignment: .leading)
                {
                    ForEach(Array(tee.holes.enumerated()), id: \.offset)
                    {
                        index, hole in
                                VStack(alignment: .leading)
                                {
                                    Text("hole number: \(index+1)")
                                    Text(String(hole.par)).font(.subheadline)
                                    Text(String(hole.yardage)).font(.subheadline)
                                    Text(String(hole.handicap ?? 0)).font(.subheadline)
                                }
                    }
                }
            }.task {
                do {
                    let osmData = try await osm.fetchCourseInfo(
                        latitude: courseLocation.latitude ?? 0.0,
                        longitude: courseLocation.longitude ?? 0.0
                    )
                    
                    // NEW: print everything we got
                    print("Total OSM elements: \(osmData.elements.count)")
                    for element in osmData.elements {
                    let golfType = element.tags?["golf"] ?? "unknown"
                    let ref = element.tags?["ref"] ?? "no ref"
                    let name = element.tags?["name"] ?? "no name"
                    print("  type=\(golfType) ref=\(ref) name=\(name) points=\(element.geometry?.count ?? 0)")
                    }
                    
                    for hole in 1...18 {
                        if let coords = osm.teeCoordinates(for: hole, in: osmData) {
                            print("Hole \(hole) tee: \(coords.lat), \(coords.lon)")
                        } else {
                            print("Hole \(hole): no tee data found")
                        }
                    }
                } catch {
                    print("OSM error: \(error)")
                }
            }
        }
    }
}
