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
    @Published var isBuffering = false
    @Published var hasFinishedLoading = false

    private let audioSession = AVAudioSession.sharedInstance()
    private var player: AVPlayer?
    private var playerStatusObserver: NSKeyValueObservation?

    init() {
        try? self.audioSession.setCategory(.playback)
        try? self.audioSession.setActive(true)
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
        
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player?.currentItem?.currentTime().seconds ?? 0
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = 0
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player?.rate ?? 0

        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    func play() {
        isBuffering = true
        isPlaying = false

        let asset = AVAsset(url: streamingURL)
        let playerItem = AVPlayerItem(asset: asset)

        if player == nil {
            player = AVPlayer()
        }
        player?.replaceCurrentItem(with: playerItem)

        // Observe the player's status
        playerStatusObserver = playerItem.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            guard let self = self else { return }
            switch item.status {
            case .readyToPlay:
                self.isBuffering = false
                self.isPlaying = true
                self.player?.play()
                self.playerStatusObserver = nil
            case .failed:
                self.isBuffering = false
                self.isPlaying = false
                // Handle error here
                self.playerStatusObserver = nil
            default:
                break
            }
        }
    }

    func pause() {
        isPlaying = false
        player?.pause()
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
                Schedule()
                    .preferredColorScheme(.dark)
                    .tabItem {
                        Label("Schedule", systemImage: "calendar.badge.clock")
                    }
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
                    .animation(.default, value: show)
                
                PlayerAndButton()
                
                Spacer()
                Spacer()
            }
            .padding([.leading, .trailing], 16)
            .onAppear {
                startUpdateTimer()
            }
        }
    }
    
    func startUpdateTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            // Run the code every 10 seconds
            fetchShowData()
        }
    }
        
    func fetchShowData() {
        getJSONfromURL(URL_string: "https://api.burnfm.com/get_schedule?now_playing=true") { result in
            switch result {
            case .success(let json):
                // Delay the state update by 1 second
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation {
                        show = Show(json: json["now_playing"].arrayValue.first)
                    }
                }
            case .failure(let error):
                print(error)
            }
        }
    }

}

struct ShowMetadata: View {
    
    @Binding var show: Show?
    
    var body: some View {
        VStack(alignment: .center) {
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
                
                let screenHeight = UIScreen.main.bounds.height
                if screenHeight > 667 {
                    Text(unwrappedShow.description)
                        .padding(.top, 30)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(5)
                }
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
            ZStack {
                if viewModel.isBuffering {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2)
                        .frame(width: 65, height: 65)
                        .background(BURN_FM_BACKGROUND)
                        .clipShape(Circle())
                } else {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .frame(width: 65, height: 65)
                        .background(BURN_FM_BACKGROUND)
                        .clipShape(Circle())
                }
            }
            .padding(25)
        }
    }
}



#Preview {
    ContentView()
}

