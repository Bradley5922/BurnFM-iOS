//
//  Schedule.swift
//  BurnFM-iOS
//
//  Created by Bradley Cable on 23/10/2023.
//

import SwiftUI
import SwiftyJSON
import Foundation

struct Schedule: View {
    
    @State private var schedule: [Show] = []
    
    var body: some View {
        
        let daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        
        NavigationView {
            VStack(alignment: .leading) {
                
                if schedule.isEmpty != true {
                    List {
                        ForEach(daysOfWeek, id: \.self) { day in
                            Section(header: Text(day)) {
                                ForEach(
                                    schedule.filter { getDayOfWeek(unixTimestamp: Double( $0.startTime )) == day }
                                ) { show in
                                    NavigationLink {
                                        VStack(alignment: .leading) {
                                            
                                            Text(show.title)
                                                .font(.largeTitle)
                                                .fontWeight(.bold)
                                            
                                            Text("\(getDayOfWeek(unixTimestamp: Double(show.startTime))), \(humanTime(Double(show.startTime))) - \(humanTime(Double(show.endTime)))")
                                                .font(.title2)
                                                .fontWeight(.light)
                                                .foregroundStyle(.gray)
                                            
                                            Divider()
                                            
                                            Text(show.description)
                                                .padding([.top], 2)
                                            
                                            show.image
                                                .aspectRatio(contentMode: .fit)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            
                                                .padding([.top])
                                            
                                            Spacer()
                                            Spacer()
                                        }
                                        .padding()
                                    } label: {
                                        HStack(alignment: .center) {
                                            Text(show.title)
                                                .fontWeight(.semibold)
                                            
                                            Spacer()
                                            
                                            Text(humanTime(Double(show.startTime)))
                                        }
                                    }
                                    .listRowBackground(show.nowPlaying ? BURN_FM_TINT : BURN_FM_BACKGROUND)
                                }
                            }
                            .headerProminence(.increased)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Schedule")
//                    .toolbar {
//                        ToolbarItem(placement: .principal) {
//                            VStack {
//                                Text("Schedule")
//                                    .font(.headline)
//                                Text("Showtimes displayed in London time [GMT/BST]")
//                                    .font(.subheadline)
//                                    .opacity(0.20)
//                                    .italic()
//                            }
//                            .padding([.bottom])
//                        }
//                    }
            
        }
        
        .onAppear() {
            schedule = []
            
            fetchData { result in
                switch result {
                case .success(let json):
                    
                    for showJSON in json["body"]["schedule"].arrayValue {
                        
                        schedule.append(Show(json: showJSON))
                        
                        let currentDate = Date()
                        let calendar = Calendar.current
                        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: currentDate)?.start.timeIntervalSince1970 ?? 0
                        let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: currentDate)?.end.timeIntervalSince1970 ?? 0

                        
                        schedule = schedule.filter { show in
                            return show.startTime >= Int(startOfWeek) && show.endTime <= Int(endOfWeek)
                        }
                        
                        schedule = schedule.sorted(by: { $0.startTime < $1.startTime })
                    
                        
                    }
                case .failure(let error):
                    print("Error: \(error)")
                }
            }
        }
    }
    
    func getDayOfWeek(unixTimestamp: Double) -> String {
//        print(unixTimestamp)
        let date = Date(timeIntervalSince1970: unixTimestamp)

        // Convert the dayOfWeek integer to a more human-readable format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        dateFormatter.timeZone = TimeZone(abbreviation: "Europe/London")
        let dayOfWeekString = dateFormatter.string(from: date)
        
        return dayOfWeekString
    }
    
    
    func humanTime(_ startTime: Double) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date(timeIntervalSince1970: TimeInterval(startTime)))
    }
}
