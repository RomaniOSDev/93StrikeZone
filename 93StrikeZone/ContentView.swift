//
//  ContentView.swift
//  93StrikeZone
//
//  Created by Роман Главацкий on 24.02.2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = StrikeZoneViewModel()
    @State private var hasCompletedOnboarding = OnboardingStorage.hasCompletedOnboarding

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                mainTabView
            } else {
                OnboardingView(isCompleted: $hasCompletedOnboarding)
            }
        }
        .preferredColorScheme(.dark)
        .tint(.strikeGold)
        .onAppear {
            viewModel.loadFromUserDefaults()
        }
    }

    private var mainTabView: some View {
        TabView {
            HomeView(viewModel: viewModel)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            GamesListView(viewModel: viewModel)
                .tabItem {
                    Label("Games", systemImage: "figure.bowling")
                }

            StatsView(viewModel: viewModel)
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }

            PlayersView(viewModel: viewModel)
                .tabItem {
                    Label("Players", systemImage: "person.fill")
                }

            LocationsView(viewModel: viewModel)
                .tabItem {
                    Label("Places", systemImage: "mappin.circle.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}

