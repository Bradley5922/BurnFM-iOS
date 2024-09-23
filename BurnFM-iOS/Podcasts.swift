//
//  Podcasts.swift
//  BurnFM-iOS
//
//  Created by Bradley Cable on 29/10/2023.
//

import SwiftUI

struct Podcasts: View {
    var body: some View {
        
        VStack(alignment: .center) {
            Text("Podcasting Divison 🎙️")
                .font(.title)
                .fontWeight(.semibold)
                .padding()
            
            Text(
                "*Welcome to BurnFM's Podcast Section!* \n\nExplore captivating student-produced podcasts covering a wide range of topics. Dive into thought-provoking discussions, entertaining stories, and insightful interviews. Whether you're into tech, pop culture, or even academic insights, we've got something for everyone.\n\nClick on the links below to enjoy our podcasts on your preferred platform and stay tuned for fresh, engaging content created by the talented students at the **University of Birmingham**."
            )
            
            Spacer()
            
            LinkButton(
                color: Color.init(red: 177/255, green: 80/255, blue: 226/255),
                link: URL(string: "https://podcasts.apple.com/us/podcast/burn-fm/id1521913304")!, 
                text: "Apple", 
                imgText: "ApplePodcast"
            )
            
            LinkButton(
                color: Color.init(red: 30/255, green: 215/255, blue: 96/255),
                link: URL(string: "https://open.spotify.com/show/0ALexnN0yS3OX4xdiPetic")!, 
                text: "Spotify", 
                imgText: "SpotifyLogo"
            )
            
            Spacer()
        }
        .padding()
    }
}

struct LinkButton: View {
    
    @Environment(\.openURL) var openURL
    
    var color: Color
    var link: URL
    var text: String
    var imgText: String
    
    var body: some View {
        Button(action: {
            openURL(link)
        }) {
            HStack(alignment: .center) {
                Text("Listen On \(text)")
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.white)
                    .font(.title)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Image(imgText)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 50)
                    .foregroundColor(.white)
            }
            .padding()
            
            .background(
                color
                    .cornerRadius(8)
            )
            
            .padding([.top])
            .shadow(radius: 25)
        }
    }
}

#Preview {
    Podcasts()
}
