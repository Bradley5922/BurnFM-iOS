////
////  schedule_new.swift
////  BurnFM-iOS
////
////  Created by Bradley Cable on 24/09/2024.
////
//
//import SwiftUI
//
//struct schedule_new: View {
//    var body: some View {
//        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
//    }
//}
//
//ForEach(
//    schedule.filter { getDayOfWeek(unixTimestamp: Double( $0.startTime )) == day }
//) { show in
//    NavigationLink {
//        VStack(alignment: .leading) {
//            
//            Text(show.title)
//                .font(.largeTitle)
//                .fontWeight(.bold)
//            
//            Text("\(getDayOfWeek(unixTimestamp: Double(show.startTime))), \(humanTime(Double(show.startTime))) - \(humanTime(Double(show.endTime)))")
//                .font(.title2)
//                .fontWeight(.light)
//                .foregroundStyle(.gray)
//            
//            Divider()
//            
//            Text(show.description)
//                .padding([.top], 2)
//            
//            show.image
//                .aspectRatio(contentMode: .fit)
//                .clipShape(RoundedRectangle(cornerRadius: 8))
//            
//                .padding([.top])
//            
//            Spacer()
//            Spacer()
//        }
//        .padding()
//    } label: {
//        HStack(alignment: .center) {
//            Text(show.title)
//                .fontWeight(.semibold)
//            
//            Spacer()
//            
//            Text(humanTime(Double(show.startTime)))
//        }
//    }
//    .listRowBackground(show.nowPlaying ? BURN_FM_TINT : BURN_FM_BACKGROUND)
//}
//}
//.headerProminence(.increased)
//
//#Preview {
//    schedule_new()
//}
