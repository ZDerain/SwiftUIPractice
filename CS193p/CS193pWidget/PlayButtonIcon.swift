//
//  PlayButtonIcon.swift
//  CS193p
//
//  Created by WisidomCleanMaster on 2023/7/20.
//

import SwiftUI

struct PlayButtonIcon: View {
    let width: CGFloat
    let height: CGFloat
    let radius: CGFloat
    let gradientColors = Gradient(
      colors: [Color("gradient-dark"), Color("gradient-light")])
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius)
                .fill(LinearGradient(
                    gradient: gradientColors,
                    startPoint: .leading,
                    endPoint: .trailing))
                .frame(width: width, height: height)
            
            Image(systemName: "play.circle.fill")
                .font(.title)
                .colorInvert()
        }
    }
}

struct PlayButtonIcon_Previews: PreviewProvider {
    static var previews: some View {
        PlayButtonIcon(width: 50, height: 50, radius: 10)
            .previewLayout(.sizeThatFits)
    }
}
