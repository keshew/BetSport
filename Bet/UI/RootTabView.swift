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

            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Profile")
                }
        }
    }
}


