//
//  Committee.swift
//  BurnFM-iOS
//
//  Created by Bradley Cable on 31/08/2024.
//

import SwiftUI
import SwiftyJSON
import WebKit

struct member: Identifiable, Hashable {
    let id: UUID
    
    let name: String
    let role: String
    let course: String
    
    let description: String
    
    let funFact: String?
    let favSong: URL?
    
    let imageURL: URL
    
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
}

struct Committee: View {
    @State private var members: [member] = []
    @State private var committeeYears: [JSON] = []
    
    @State private var selectedYear: String = ""

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                
                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        ForEach(0..<committeeYears.count, id: \.self) { index in
                            
                            let year = committeeYears[index].stringValue
                            
                            Button {
                                selectedYear = year
                                members = []
                                loadMembers()
                                
                            } label: {
                                ZStack {
                                    Capsule()
                                        .frame(width: 100, height: 40)
                                        .padding(8)
                                    
                                        .foregroundStyle((selectedYear == year) ? BURN_FM_TINT : BURN_FM_BACKGROUND)
                                    
                                    Text(year.prefix(7))
                                        .foregroundColor(.white)
                                    
                                        .fontWeight((selectedYear == year) ? .bold : .regular)
                                        
                                }
                            }
                        }
                    }
                }
                
                Spacer()
                
                if members.isEmpty {
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
                            
                            ForEach(members) { member in
                                
                                NavigationLink(destination: CommitteeDetailView(member: member)) {
                                    
                                    HStack(alignment: .center) {
                                        member.image
                                            .frame(width: 85, height: 85)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .shadow(radius: 4)

                                        VStack(alignment: .leading) {
                                            Text(member.name)
                                                .font(.headline)
                                            Text(member.role)
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
            .navigationTitle("Committee")
            .onAppear {
                fetchCommitteeHistory()
            }
        }
    }

    func fetchCommitteeHistory() {
        
        print("Fetching Committee History")
        
        if (committeeYears.isEmpty) {
            getJSONfromURL(URL_string: "https://burnfm.com/committee/get-committee-history.php") { result in
                switch result {
                    
                case .success(let json):
                    
                DispatchQueue.main.async {
                    committeeYears = json.arrayValue
                    selectedYear = committeeYears.first!.stringValue
                    print(selectedYear)
                    loadMembers()
                }
                case .failure:
                    break
                }
            }
        } else {
            loadMembers()
        }
    }

    func loadMembers() {
        
        print("Fetching Committee Members")
        
        getJSONfromURL(URL_string: "https://burnfm.com/committee/\(selectedYear)") { result in
            switch result {
            case .success(let json):
                var fetchedMembers: [member] = []
                for memberJSON in json {
                    let newMember = member(
                        id: UUID(),
                        name: memberJSON.1["name"].stringValue,
                        role: memberJSON.1["role"].stringValue,
                        course: memberJSON.1["course"].stringValue,
                        description: memberJSON.1["description"].stringValue,
                        funFact: memberJSON.1["fun_fact"].stringValue,
                        favSong: URL(string: memberJSON.1["favourite_song"].stringValue),
                        imageURL: URL(string: "https://burnfm.com\(memberJSON.1["picture"].stringValue)")!
                    )
                    fetchedMembers.append(newMember)
                }
                DispatchQueue.main.async {
                    members = fetchedMembers
                }
            case .failure(let error):
                print("Error fetching committee data: \(error)")
            }
        }
    }
}


struct CommitteeDetailView: View {
    
    @State var member: member
    
    var body: some View {
        VStack(alignment: .leading) {
            ScrollView {
                
                member.image
                    .frame(width: 200, height: 200)
                    .clipShape(Circle())
                    .padding()
                
                Text(member.name)
                    .font(.title)
                    .fontWeight(.bold)
                Text(member.course)
                    .font(.subheadline)
                
                ChunkedTextView(textBlock: member.description)
                    .padding()
                
                if let funFact = member.funFact, !funFact.isEmpty {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Fun Fact ⚡️")
                                .fontWeight(.heavy)
                                .padding(.bottom, 2)
                            
                            Text(funFact)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(BURN_FM_TINT)
                }
                
                Spacer()
            }
        }
        .navigationTitle(member.role)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: Helper views

struct ChunkedTextView: View {
    var textBlock: String
    var chunkSize: Int = 250 // Adjust this based on your desired chunk size

    // Function to split the text into chunks that end with a newline or a full stop
    func splitTextIntoChunks(_ text: String, chunkSize: Int) -> [String] {
        var chunks: [String] = []
        var currentChunk = ""

        let sentences = text.split { $0 == "." || $0 == "\n" }.map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        
        for sentence in sentences {
            let sentenceWithDelimiter = sentence + (text.contains("\(sentence)\n") ? "\n" : ".")
            
            if currentChunk.count + sentenceWithDelimiter.count < chunkSize {
                currentChunk += sentenceWithDelimiter + " "
            } else {
                chunks.append(currentChunk.trimmingCharacters(in: .whitespacesAndNewlines))
                currentChunk = sentenceWithDelimiter + " "
            }
        }
        
        if !currentChunk.isEmpty {
            chunks.append(currentChunk.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        return chunks
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(splitTextIntoChunks(textBlock, chunkSize: chunkSize), id: \.self) { chunk in
                Text(chunk)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(.bottom, 8)
                    .multilineTextAlignment(.leading)
            }
        }
    }
}

//
//var fakeMember: member = member(id: UUID(), name: "Bradley Cable", role: "Head of Tech", course: "BSc Computer Science ", description: "Lorem ipsum dior sit amet, consectetur adipiscing elit. Nulla facilisi. Sed vel ante. Aliquam erat volutpat. Nulla facilisi. Sed vel ante. Aliquam erat volutpat.", imageURL: URL(string: "https://burnfm.com/profile_img/2023-24/Bradley_Cable.jpg")!)



#Preview {
//    CommitteeDetailView(member: fakeMember)
    Committee()
}
