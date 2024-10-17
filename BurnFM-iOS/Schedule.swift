//
//  Schedule.swift
//  BurnFM-iOS
//
//  Created by Bradley Cable on 23/10/2023.
//

//import SwiftUI
//import SwiftyJSON
//import Foundation
//
//struct Schedule: View {
//    
//    @State private var schedule: [String: JSON] = [:]
//    @State private var now_playing_id: Int = 0
//    
//    var body: some View {
//        
//        let daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
//        
//        NavigationView {
//            VStack(alignment: .leading) {
//                
//                if schedule.isEmpty != true {
//                    
//                    List {
//                        ForEach(daysOfWeek, id: \.self) { day in
//                            Section(header: Text(day)) {
//                                let daySchedule = schedule[day]!.arrayValue
//                                
//                                ForEach(0..<daySchedule.count, id: \.self) { index in
//                                    let show = Show(json: daySchedule[index])
//                                    
//                                    NavigationLink {
//                                        VStack(alignment: .leading) {
//                                
//                                            Text(show.title)
//                                                .font(.largeTitle)
//                                                .fontWeight(.bold)
//                                
//                                            Text("\(show.startTime) - \(show.endTime) | \(convertToHours(show.duration))")
//                                                .font(.title2)
//                                                .fontWeight(.light)
//                                                .foregroundStyle(.gray)
//                                
//                                            Divider()
//                                
//                                            Text(show.description)
//                                                .padding([.top], 2)
//                                
//                                            show.image
//                                                .aspectRatio(contentMode: .fit)
//                                                .clipShape(RoundedRectangle(cornerRadius: 8))
//                                
//                                                .padding([.top])
//                                
//                                            Spacer()
//                                            Spacer()
//                                        }
//                                        .padding()
//                                    } label: {
//                                        
//                                        HStack(alignment: .center) {
//                                            Text(show.title)
//                                                .fontWeight(.semibold)
//                                            
//                                            Spacer()
//                                            
//                                            Text(show.startTime)
//                                        }
//                                        
//                                    }
//                                    .listRowBackground((now_playing_id == show.id) ? BURN_FM_TINT : BURN_FM_BACKGROUND)
//                                }
//                            }
//                        }
//                    }
//                    .listStyle(.insetGrouped)
//                }
//            }
//            .navigationBarTitleDisplayMode(.inline)
//            .navigationTitle("Schedule")
//            
//        }
//        
//        .onAppear() {
//            schedule = [:]
//            
//            fetchData { result in
//                DispatchQueue.main.async {
//                    switch result {
//                    case .success(let json):
//
//                        schedule = json["schedule"].dictionaryValue
//                        now_playing_id = schedule["now_playing"]![0]["id"].intValue
//
//                    case .failure(let error):
//                        print("Error fetching data:", error)
//                        // Perform error handling or show an alert
//                    }
//                }
//            }
//
//        }
//    }
//    
//    func convertToHours(from timeString: String) -> String? {
//
//        let timeComponents = timeString.split(separator: ":").map { String($0) }
//        
//        guard timeComponents.count == 3,
//              let hours = Double(timeComponents[0]),
//              let minutes = Double(timeComponents[1]),
//              let seconds = Double(timeComponents[2]) else {
//            return nil
//        }
//        
//        let totalHours = hours + (minutes / 60) + (seconds / 3600)
//        
//        return String(format: "%.2f", totalHours)
//    }
//}
//
//#Preview {
////    CommitteeDetailView(member: fakeMember)
//    Schedule()
//}
