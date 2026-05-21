//
//  contentview.swift
//  golf app
//
//  Created by ccz8 on 5/20/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "figure.golf")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Testing Golf API...")
        }
        .padding()
        // This fires automatically as soon as the view shows up on screen
        .onAppear {
            Task {
                do {
                    print("🚀 Starting API test...")
                    let api = GolfAPI()
                    let courses = try await api.fetchCoursesFromAPI()
                    
                    print("✅ SUCCESS! Fetched \(courses.count) courses.")
                    // Print out the first course name to prove it worked!
                    if let firstCourse = courses.first {
                        print("⛳️ First course found: \(firstCourse)")
                    }
                } catch {
                    print("❌ API TEST FAILED with error: \(error)")
                }
            }
        }
    }
}
