import SwiftUI
import Combine

struct PodiumScreen: View {
    @Binding var path: NavigationPath
    @ObservedObject private var viewModel = PodiumViewModel()
    
    var body: some View {
        ZStack (){
            Image("BackgroundImage")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack(){
                Text("\(UserManager.shared.name)'s Room")
                    .font(.title)
                    .foregroundStyle(.white)
                    .padding(.top)
                
                ScrollView {
                    // Fetch and display podium categories
                    let groupedResults = viewModel.groupResultsByLikes()
                    
                    ForEach(groupedResults.keys.sorted(), id: \.self) { numLikes in
                        // Prepare the boardgames for each numLikes group
                        let boardgames = groupedResults[numLikes] ?? []
                        let images = boardgames.map { $0.boardgame.cover_image_path }

                        PodiumCard(title: "\(numLikes) Match", images: images)
                    }
                }
                
            }
            
            
        }
    }
}
#Preview {
    PodiumScreen(path: .constant(NavigationPath()))
}
