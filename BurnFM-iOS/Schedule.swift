//
//  Schedule_new.swift
//  BurnFM-iOS
//
//  Created by Bradley Cable on 19/10/2024.
//

import SwiftUI
import SwiftyJSON

enum dayOfWeek: String {
    case Monday
    case Tuesday
    case Wednesday
    case Thursday
    case Friday
    case Saturday
    case Sunday
}

struct Schedule: View {
    
//    @State private var scrollProxy: ScrollViewProxy? = nil
    
    @State var now_playing: Show?
    @State var day_selected: dayOfWeek = .Monday
    @State var schedule: [Show]?
    
    let week: [dayOfWeek] = [.Monday, .Tuesday, .Wednesday, .Thursday, .Friday, .Saturday, .Sunday]
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            ForEach(week, id: \.self) { day in
                            
                                Button {
                                    day_selected = day
                                    
                                } label: {
                                    ZStack {
                                        Capsule()
                                            .frame(width: 120, height: 40)
                                            .padding(8)
                                        
                                            .foregroundStyle((day_selected == day) ? BURN_FM_TINT : BURN_FM_BACKGROUND)
                                        Text(day.rawValue)
                                            .foregroundColor(.white)
                                        
                                            .fontWeight((day_selected == day) ? .bold : .regular)
                                        
                                    }
                                }
                                .id(day)
                            }
                            .scrollTransition { view, transition in
                                view.opacity(transition.isIdentity ? 1 : 0.3)
                            }
                            
                        }
                    }
                    .contentMargins([.leading, .trailing], 11, for: .scrollContent)
                    .onAppear() {
                        let date = Date()
                        let calendar = Calendar.current
                        
                        if let dayOfWeekIndex = calendar.dateComponents([.weekday], from: date).weekday {
                            
                            let adjustedDayOfWeekIndex = (dayOfWeekIndex == 1) ? 7 : dayOfWeekIndex - 1
                            
                            day_selected = week[adjustedDayOfWeekIndex - 1]
                        }
                        
                        proxy.scrollTo(day_selected)
                    }
                }
                
                List {
                    if let schedule = schedule {
                        ForEach(schedule.filter({$0.day == day_selected})) { show in
                            
                            NavigationLink(destination: showDetailView(show: show), label: {
                                HStack(alignment: .center) {
                                    Text(show.title)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    Text(timeDurtationParser(show: show))
                                }
                            })
                            .listRowBackground((now_playing?.id == show.id) ? BURN_FM_TINT : BURN_FM_BACKGROUND)
                        }
                    } else { // schedule is null
                        Text("Loading")
                    }
                }
                .environment(\.defaultMinListRowHeight, 50) 
            }
            .onAppear() {
                getJSONfromURL(URL_string: "https://api.burnfm.com/get_schedule") { result in
                    switch result {
                    case .success(let json):
                        var tempSchedule: [Show] = []
                        
                        for jsonShow in json["schedule"].arrayValue {
                            let tempShow = Show(json: jsonShow)
                            //                        print(tempShow.title)
                            
                            tempSchedule.append(tempShow)
                        }
                        
                        schedule = tempSchedule
                    case .failure(let error):
                        print(error)
                    }
                }
                
                getJSONfromURL(URL_string: "https://api.burnfm.com/get_schedule?now_playing=true") { result in
                    switch result {
                    case .success(let json):
                        //                    print(json["now_playing"])
                        now_playing = Show(json: json["now_playing"].arrayValue.first)
                    case .failure(let error):
                        print(error)
                    }
                }
            }
            .navigationTitle("Schedule")
        }
    }

}

struct showDetailView: View {
    
    @State var show: Show
    
    var body: some View {
        VStack() {
            ScrollView {
                show.image
                    .frame(width: 250, height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding()
                
                Text(timeDurtationParser(show: show) + " | \(show.duration.dropLast(3)) (h:m)")
                    .foregroundStyle(.secondary)
                    .fontWeight(.light)
                    .padding([.bottom])
                
                VStack(alignment: .leading) {
                    Text("Description:")
                        .fontWeight(.semibold)
                    Text(show.description)
                    
                    if let hosts = show.hosts {
                        Text("Hosted By:")
                            .fontWeight(.semibold)
                        Text(hosts)
                    }
                }
            }
        }
        .navigationTitle(show.title)
    }
}

func timeDurtationParser(show: Show) -> String {
    let strippedStartTime = show.startTime.dropLast(3)
    let strippedEndTime = show.endTime.dropLast(3)
    
    let stringBuilder = "\(strippedStartTime) - \(strippedEndTime)"
    
    return stringBuilder
    
}

struct Show: Identifiable, Equatable  {
    var id: Int
    
    private var dayString: String
    var day: dayOfWeek {
        return dayOfWeek(rawValue: dayString)!
    }
    
    var startTime: String
    var endTime: String
    var duration: String
    
    var title: String
    var description: String
    var hosts: String?

    private var imagePath: String?
    var image: some View {
        Group {
            if let validImagePath = imagePath {
                AsyncImage(url: URL(string: "https://api.burnfm.com/schedule_img/\(validImagePath)")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        Image("ShowNoImg")
                            .resizable()
                            .scaledToFit()
                    case .empty:
                        ProgressView()
                    @unknown default:
                        Image("ShowNoImg")
                            .resizable()
                            .scaledToFit()
                    }
                }
            } else {
                Image("ShowNoImg")
                    .resizable()
                    .scaledToFit()
            }
        }
    }

    init(json: JSON?) {
        if let json = json {
            
            self.id = json["id"].int ?? 0
            self.dayString = json["day"].stringValue
            
            self.startTime = json["start_time"].string ?? "00:00:00"
            self.endTime = json["end_time"].string ?? "00:00:00"
            self.duration = json["duration"].string ?? "00:00:00"
            
            if let hosts = json["hosts"].string {
                self.hosts = hosts
            }
            
            if let imagePath = json["image_path"].string {
                self.imagePath = imagePath
            }
            
            self.title = json["title"].string ?? "Live on BurnFM"
            self.description = json["description"].string ?? "This is the pulse of Birmingham's campus. Your source for music, entertainment, and news"
            
        } else {
            self.id = 0
            
            self.dayString = "Monday"
            
            self.startTime = "00:00:00"
            self.endTime = "00:00:00"
            self.duration = "00:00:00"
            
            self.title = "Live on BurnFM"
            self.description = "This is the pulse of Birmingham's campus. Your source for music, entertainment, and news"
        }
    }
}

#Preview {
    Schedule()
}
