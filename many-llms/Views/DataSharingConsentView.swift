//
//  DataSharingConsentView.swift
//  many-llms
//
//  Created by Antigravity on 7/31/26.
//

import SwiftUI

public struct DataSharingConsentView: View {
    @ObservedObject var store: WorkspaceStore
    @Environment(\.dismiss) private var dismiss
    
    public init(store: WorkspaceStore) {
        self.store = store
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 64))
                .foregroundColor(.orange)
                .padding(.top, 40)
            
            // Title
            Text(store.loc("privacy_title"))
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            // Explanatory ScrollView
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(store.loc("privacy_subtitle"))
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineSpacing(4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(store.loc("privacy_what_data_title"))
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(store.loc("privacy_what_data_body"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineSpacing(3)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(store.loc("privacy_who_data_title"))
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(store.loc("privacy_who_data_body"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineSpacing(3)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(store.loc("privacy_security_title"))
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(store.loc("privacy_security_body"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineSpacing(3)
                    }
                    
                    if let privacyURL = URL(string: "https://github.com/holasoymalva/manyllm-app/blob/main/PRIVACY.md") {
                        Link(destination: privacyURL) {
                            HStack {
                                Text(store.loc("privacy_link"))
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Image(systemName: "arrow.up.forward.app")
                                    .font(.subheadline)
                            }
                            .foregroundColor(.orange)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 8)
            }
            
            Spacer()
            
            // Acceptance Button
            Button(action: {
                store.hasConsentedToDataSharing = true
                dismiss()
            }) {
                Text(store.loc("privacy_accept"))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.orange)
                    .cornerRadius(14)
                    .shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
        .interactiveDismissDisabled() // User must press the button to consent
    }
}
