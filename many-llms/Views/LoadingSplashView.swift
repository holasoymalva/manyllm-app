//
//  LoadingSplashView.swift
//  many-llms
//

import SwiftUI

public struct LoadingSplashView: View {
    public var body: some View {
        VStack(spacing: 20) {
            #if os(iOS)
            GIFView(urlString: "https://media2.giphy.com/media/v1.Y2lkPTc5MGI3NjExdHdwbnlzZTNiYTVnbGl4eTZlZjFueG90NjhjdWIyN2Z2dzZwNmxxYiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9cw/w5WFZZMK1jZ2rZTHpg/giphy.gif")
                .frame(width: 80, height: 80)
            #else
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            #endif
            
            VStack(spacing: 8) {
                Text("Preparing Environment")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 20/255, green: 28/255, blue: 45/255))
                
                Text("Setting up your ManyLLM preview workspace...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
}
