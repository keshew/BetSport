import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            EventsFeedView()
                .tabItem {
                    Image(systemName: "sportscourt")
                    Text("Events")
                }

            LeaderboardView()
                .tabItem {
                    Image(systemName: "rosette")
                    Text("Leaders")
                }

            TournamentsView()
                .tabItem {
                    Image(systemName: "trophy")
                    Text("Tournaments")
                }

            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Profile")
                }
        }
    }
}


