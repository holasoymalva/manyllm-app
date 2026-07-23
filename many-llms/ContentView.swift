//
//  ContentView.swift
//  many-llms
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = WorkspaceStore()
    @State private var isLoading = true
    @State private var isDrawerOpen = false
    
    var body: some View {
        ZStack(alignment: .leading) {
            if isLoading {
                LoadingSplashView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            withAnimation(.easeOut(duration: 0.4)) {
                                isLoading = false
                            }
                        }
                    }
            } else {
                // Main Chat Screen (Default central view for ManyLLMs!)
                ManyLLMMainChatView(store: store, isDrawerOpen: $isDrawerOpen)
                    .disabled(isDrawerOpen)
                
                // Backdrop dimming when side drawer is open
                if isDrawerOpen {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isDrawerOpen = false
                            }
                        }
                        .transition(.opacity)
                }
                
                // Sliding Side Drawer
                if isDrawerOpen {
                    ManyLLMDrawerSidebarView(store: store, isDrawerOpen: $isDrawerOpen)
                        .transition(.move(edge: .leading))
                        .zIndex(2)
                }
            }
        }
        .sheet(isPresented: $store.isSettingsPresented) {
            ManyLLMSettingsView(store: store)
        }
    }
}

#Preview {
    ContentView()
}
