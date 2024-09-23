//
//  ContentView.swift
//  BurnFM-iOS
//
//  Created by Bradley Cable on 19/10/2023.
//

import SwiftUI
import AVKit
import SwiftyJSON
import Foundation
import MediaPlayer

let streamingURL = URL(string: "https://stream.aiir.com/xz12nsvoppluv")!

let BURN_FM_BACKGROUND = Color.init(red: (74/255), green: (22/255), blue: (98/255))
let BURN_FM_TINT = Color(red: (144/255), green: (92/255), blue: (168/255))

class ViewModel: ObservableObject {

    @Published var isPlaying = false

    private let audioSession = AVAudioSession.sharedInstance()
    private var player: AVPlayer? = AVPlayer()

    init() {
        let asset = AVAsset(url: streamingURL)
        let playerItem = AVPlayerItem(asset: asset)
        player!.replaceCurrentItem(with: playerItem)
        
        try! self.audioSession.setCategory(AVAudioSession.Category.playback)
        try! self.audioSession.setActive(true)
        
        setupRemoteTransportControls()
        setupNowPlaying()
    }

    func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.changePlaybackPositionCommand.isEnabled = false
        
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [unowned self] event in
            if !self.isPlaying {
                self.play()
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            if self.isPlaying {
                self.pause()
                return .success
            }
            return .commandFailed
        }
        
    }

    func setupNowPlaying() {
        // Define Now Playing Info
        var nowPlayingInfo = [String : Any]()
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = "BurnFM Student Radio"
        nowPlayingInfo[MPMediaItemPropertyArtist] = "University Of Birmingham"

        if let image = UIImage(named: "lockscreen") {
            nowPlayingInfo[MPMediaItemPropertyArtwork] =
                MPMediaItemArtwork(boundsSize: image.size) { size in
                    return image
            }
        }
        
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player?.currentItem?.currentTime().seconds
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = 0
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player?.rate

        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    func play() {
        let asset = AVAsset(url: streamingURL)
        let playerItem = AVPlayerItem(asset: asset)
        
        player = AVPlayer()
        player!.replaceCurrentItem(with: playerItem)
        
        isPlaying.toggle()
        player!.play()
    }

    func pause() {
        isPlaying.toggle()
        player!.pause()
        
        player = nil
    }

}

struct ContentView: View {
    
    var body: some View {
        TabView {
            Group {
                mainScreen()
                    .preferredColorScheme(.dark)
                    .tabItem {
                        Label("ON AIR", systemImage: "radio.fill")
                    }
                Podcasts()
                    .tabItem {
                        Label("Podcasts", systemImage: "music.mic")
                    }
//                Schedule()
                Text("Under Maintenance")
                    .font(.largeTitle)
                    .italic()
                    .bold()
                    .preferredColorScheme(.dark)
                    .tabItem {
                        Label("Schedule", systemImage: "calendar.badge.clock")
                    }
//                OnDemand()
//                    .preferredColorScheme(.dark)
//                    .tabItem {
//                        Label("On Demand", systemImage: "clock.arrow.2.circlepath")
//                    }
                Committee()
                    .preferredColorScheme(.dark)
                    
                    .tabItem {
                        Label("Committee", systemImage: "shared.with.you")
                            .foregroundColor(.red)
                    }
            }
            .toolbarBackground(.black, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
        }
        .tint(BURN_FM_TINT)
    }
}

struct mainScreen: View {
    
    @State private var timer: Timer?
    
    @State private var show: Show? = Show(json: nil)
    @State private var schedule: [Show] = []
    
    @State private var loading: Bool = false
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(
                    Gradient(stops: [
                        Gradient.Stop(color: BURN_FM_BACKGROUND, location: 0),
                        Gradient.Stop(color: BURN_FM_BACKGROUND, location: 0.1),
                        Gradient.Stop(color: Color.init(.sRGB, white: 0.12, opacity: 1), location: 0.225)
                    ])
                    )
                .ignoresSafeArea(.all)
            
            VStack {
                if loading {
                    Spacer()
                    
                    LoadingView()
                    
                    Text("Please allow upto 10 seconds")
                        .italic()
                        .fontWeight(.light)
                        .foregroundStyle(.gray)
                        .padding(4)
                    
                    Spacer()
                    Spacer()
                } else {
                    if show != nil {
                        
                        VStack(alignment: .center) {
                            
                            HStack(spacing: 25) {
                                Image("LogoBurnFMWhite")
                                    .resizable()
                                    .frame(width: 70, height: 70)
                                    
                                
                                VStack(alignment: .leading) {
                                    Text("Burn FM Student Radio")
                                        .font(.title2)
                                        .bold()
                                    Text("University of Birmingham")
                                        .font(.title3)
                                        .fontWeight(.light)
                                }
                            }
                            
                            Spacer()
                            
                            ShowMetadata(show: $show)
                            
                            PlayerAndButton()
                            
                            Spacer()
                            
                        }
                    } else {
                        // no show now playing therefore, station off air
                        VStack(alignment: .center) {
                            
                            Spacer()
                            
                            Text("We're off air now :(")
                                .font(.largeTitle)
                                .fontWeight(.semibold)
                                .foregroundStyle(BURN_FM_TINT)
                                .italic()
                                .padding()
                            
                            Text("See the schedule to know when we're broadcasting next and who's on the airwaves!\n\nMaybe in the meantime check out our podcasts, for easy anytime listening...")
                                .opacity(0.20)
                            
                            Spacer()
                        }
                        .padding()
                        .multilineTextAlignment(.center)
                    }
                
                }
            }
            .padding([.leading, .trailing], 16)
            
            .onAppear {
                print("view shown")
                
                show = Show(json: nil)
                
//                updateMetadata()
//                
//                self.timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
//                    updateMetadata()
//                }
            }
        }
    }
    
    func updateMetadata() {
        fetchData { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let json):
                    let tempScheduleJSON = json["body"]["schedule"].array!
                    var tempScheduleForReplacement: [Show] = []
                    
                    for showJSON in tempScheduleJSON {
                        tempScheduleForReplacement.append(Show(json: showJSON))
                    }
                    
                    schedule = tempScheduleForReplacement
                    show = schedule.filter { $0.nowPlaying }.first
                    print(show ?? "no now playing show")
                    
                    loading = false
                    print("Updating now playing... ")
                    
                case .failure(let error):
                    print("Error fetching data:", error)
                    // Perform error handling or show an alert
                }
            }
        }
    }
}

struct ShowMetadata: View {
    
    @Binding var show: Show?
    
    var body: some View {
        VStack(alignment: .center) {
            // Show Artwork
            if let unwrappedShow = show {
                Text(unwrappedShow.title)
                    .padding([.top], 60)
                    .padding(.bottom, 20)
                    .font(.title)
                    .bold()
                
                ZStack {
                    unwrappedShow.image
                        .blur(radius: 65)
                    unwrappedShow.image
                        .clipShape(.rect(cornerRadius: 8))
                        
                }
                .frame(width: 250, height: 250)
                
                Text(unwrappedShow.description)
                    .padding(.top, 30)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(5)
            }
        }
    }
}

struct PlayerAndButton: View {
    
    @StateObject private var viewModel = ViewModel()
    
    var body: some View {
        Button(action: {
            if viewModel.isPlaying {
                viewModel.pause()
            } else {
                viewModel.play()
            }
        }) {
            Image(systemName: viewModel.isPlaying ? "pause.fill": "play.fill")
                .font(.largeTitle)
                .foregroundColor(.white)
                .padding(20)
            
                .background(BURN_FM_BACKGROUND)
                .clipShape(Circle())
                .padding(30)

        }
    }
}

func fetchData(completion: @escaping (Result<JSON, Error>) -> Void) {
    // MARK: Fetch Data
    /// Production URL: `https://api.broadcast.radio/api/nowplaying/957?size=600&scheduleLength=true`
    /// Test URL: `https://bradleycable.co.uk/test_burn.php`
    
    if let url = URL(string: "https://api.broadcast.radio/api/nowplaying/957?size=600&scheduleLength=true") {
        
        // Create a URLSession instance.
        let session = URLSession.shared
        
        // Create a data task to retrieve the data from the URL.
        let task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let data = data {
                do {
                    let json = try JSON(data: data)
//                    print(json)
                    completion(.success(json))
                } catch let parseError {
                    completion(.failure(parseError))
                }
            }
        }
        
        // Start the data task.
        task.resume()
    } else {
        completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
    }
}

struct Show: Identifiable, Equatable  {
    var id: UUID = UUID()
    
    var title: String = "Now On Burn..."
    var description: String = "This is the pulse of Birmingham's campus. Your source for music, entertainment, and news"
    
    var imageURL: URL?
    
    var startTime: Int = .zero
    var endTime: Int = .zero
    
    var nowPlaying: Bool = false
    
    static func == (lhs: Show, rhs: Show) -> Bool {
        return lhs.id == rhs.id
    }
    
    private func bodyToURL(body: String) -> URL {
        let fileCompoents = body.components(separatedBy: ":")
        let baseURL = "https://api.broadcast.radio/api/image/"
        let params = "?g=center&w=500&h=500&c=true"
        
        let filetype = fileCompoents[0].components(separatedBy: "/")[1] // eg: cms-blob_image/png
        let fileLocation = fileCompoents[1] // 287b0521-1913-48c3-8043-5cb722d9bf8c
        
        guard let imgURL = URL(string: baseURL + fileLocation + "." + filetype + params) else { return URL(string: "")! }
        
        return imgURL
    }

    var image: some View {
        AsyncImage(url: imageURL) { fetchImg in
            switch fetchImg {
            case .success(let image):
                image
                    .resizable()
            default:
                Image("ShowNoImg")
                    .resizable()
            }
        }
    }

    init(json: JSON?) {
        if let json = json {
            self.startTime = json["start_time_in_station_tz"].intValue / 1000
            self.endTime = json["end_time_in_station_tz"].intValue / 1000
            
            // if now playing
            let currentTimestamp = Int(Date().timeIntervalSince1970)
            nowPlaying = currentTimestamp >= startTime && currentTimestamp <= endTime
            
            if let showImgContent = json["content"].array?.first(where: { $0["contentType"]["slug"].stringValue == "featuredImage" }) {
                // show has img
                
                if let bodyIMGString = showImgContent["body"].string {
                    self.imageURL = bodyToURL(body: bodyIMGString)
                }
//                print(json["content"].array![1].stringValue)
                self.title = (json["content"].array![1])["display_title"].stringValue
                self.description = (json["content"].array![1])["excerpt"].stringValue
            } else {
                
                let showContent = (json["content"].array)?[0]
                self.title = showContent?["display_title"].stringValue ?? "Now Playing On Burn..."
                self.description = showContent?["excerpt"].stringValue ?? "This is the pulse of Birmingham's campus. Your source for music, entertainment, and news"
            }
        }
        
        if self.description == "" {
            self.description = "This is the pulse of Birmingham's campus. Your source for music, entertainment, and news"
        }
        
        if self.title == "" {
            self.description = "Live on BurnFM"
        }
    }
}

struct LoadingView: View {
    
    var maxDots: Int = 4
    
    @State private var loadingText = "Loading"
    @State private var dotCount = 1
    
    var body: some View {
        Text(loadingText)
            .font(.largeTitle)
            .fontWeight(.semibold)
        
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                    if dotCount < maxDots {
                        loadingText += "."
                        dotCount += 1
                    } else {
                        loadingText = "Loading"
                        dotCount = 1
                    }
                }
            }
    }
}


#Preview {
    ContentView()
}
