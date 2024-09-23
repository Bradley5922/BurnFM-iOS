//
//  OnDemand.swift
//  BurnFM-iOS
//
//  Created by Bradley Cable on 22/09/2024.
//

import SwiftUI
import AVFoundation

struct onDemandShow: Identifiable {
    
    var id: UUID
    
    var title: String
    var imageURL: URL
    var playback: URL

    // Private computed property to parse the title and extract the show title and timestamp
    private var parsedTitle: (showTitle: String, timestamp: Date) {
        let dateTimeLength = 16 // Length of "yyyy-MM-dd HH:mm"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"

        guard title.count >= dateTimeLength + 1 else {
            // Not enough characters to contain a date and time
            return (title, Date.distantPast)
        }

        // Extract the last 16 characters as potential date and time
        let dateTimeStartIndex = title.index(title.endIndex, offsetBy: -dateTimeLength)
        let dateTimeString = String(title[dateTimeStartIndex...])


        if let date = dateFormatter.date(from: dateTimeString) {

            let titleEndIndex = title.index(dateTimeStartIndex, offsetBy: -1)
            
            let showTitle = String(title[..<titleEndIndex])
            
            return (showTitle, date)
        } else {
            // Date is not valid, return the entire title and nil for timestamp
            return (title, Date.distantPast)
        }
    }

    var showTitle: String {
        return parsedTitle.showTitle
    }

    var timestamp: Date {
        return parsedTitle.timestamp
    }

    // Existing computed property for the image
    var image: some View {
        AsyncImage(url: imageURL) { fetchImg in
            switch fetchImg {
            case .success(let image):
                image.resizable()
            default:
                Image("ShowNoImg").resizable()
            }
        }
    }
}



struct OnDemand: View {
    
    let feeds: [String] = ["1d5ba995-6e23-47e2-805b-1ef1aeff4a39"]
    @State var shows: [onDemandShow] = []
    
    @State private var hasLoaded = false // prevents duplicate appends upon coming back from detail view
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                if shows.isEmpty {
                    HStack {
                        Spacer()
                        
                        ProgressView()
                            .scaleEffect(3)
                        
                        Spacer()
                    }
                    .padding()
                    
                    Spacer()
                        
                } else {
                    ScrollView {
                        VStack(alignment: .leading) {
                            
                            ForEach(shows.sorted(by: { $0.timestamp < $1.timestamp })) { show in
                                
                                NavigationLink(destination: detailOndemandShow(show: show)) {
                                    
                                    HStack(alignment: .center) {
                                        show.image
                                            .frame(width: 85, height: 85)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .shadow(radius: 4)

                                        VStack(alignment: .leading) {
                                            Text(show.showTitle)
                                                .font(.headline)
                                            Text(formatTimestamp(date: show.timestamp))
                                                .fontWeight(.light)
                                        }
                                        .padding([.leading])

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                            .padding([.trailing])
                                    }
                                    
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(Color(.systemGray6))
                                    )
                                }
                                .padding([.leading, .trailing])
                                .buttonStyle(PlainButtonStyle())
                            }
                            .scrollTransition { view, transition in
                                view.opacity(transition.isIdentity ? 1 : 0.3)
                            }
                        }
                    }
                    
                }
            }
            .navigationTitle("On Demand")
            .onAppear {
                if !hasLoaded {
                    loadShow_RSS_JSON(feed: feeds.first!)
                    hasLoaded = true
                }
            }
        }
    }
    
    func formatTimestamp(date: Date) -> String {
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "d MMMM"
        let dayMonth = dateFormatter.string(from: date)
        
        dateFormatter.dateFormat = "HH:mm"
        let time = dateFormatter.string(from: date)
        
        let formattedDate = "\(dayMonth) - \(time)"
        
        return formattedDate
    }
    
    func loadShow_RSS_JSON(feed: String) {
        getJSONfromURL(URL_string: "https://api.rss2json.com/v1/api.json?rss_url=https%3A%2F%2Fshows.aiir.com%2Fapi%2Fpublic%2Fpodcasts%2F\(feed)%2Frss&api_key=cvccwaaagtgxwub0pkgdtkp5hsceicwhbjfwmv7l") { result in
            switch result {
            case .success(let json):
                print(json["items"])
                
                var fetchedShows: [onDemandShow] = []
                for showJSON in json["items"].arrayValue {
                    let newShow = onDemandShow(
                        id: UUID(),
                        title: showJSON["title"].stringValue,
                        imageURL: URL(string: showJSON["thumbnail"].stringValue)!,
                        playback: URL(string: showJSON["enclosure"]["link"].stringValue)!
                    )
                    fetchedShows.append(newShow)
                }
                DispatchQueue.main.async {
                    shows.append(contentsOf: fetchedShows)
                }
            case .failure(let error):
                print("Error fetching committee data: \(error)")
            }
        }
    }

}

struct detailOndemandShow: View {
    
    @State var show: onDemandShow
    
    let player = AVPlayer()
    @State var isPlaying: Bool = false
    
    
    var body: some View {
        VStack {
            show.image
                .frame(width: 250, height: 250)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 4)
            
            Button(action: {
                if isPlaying {
                    isPlaying = false
                    pause()
                } else {
                    isPlaying = true
                    play()
                }
            }) {
                Image(systemName: isPlaying ? "pause.fill": "play.fill")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding(20)
                
                    .background(BURN_FM_BACKGROUND)
                    .clipShape(Circle())
                    .padding(30)

            }
        }
        .navigationTitle(show.showTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func play() {
        let asset = AVAsset(url: show.playback)
        let playerItem = AVPlayerItem(asset: asset)
        
        player.replaceCurrentItem(with: playerItem)
        
        player.play()
    }

    func pause() {
        player.pause()
    }
}

#Preview {
    OnDemand()
}
