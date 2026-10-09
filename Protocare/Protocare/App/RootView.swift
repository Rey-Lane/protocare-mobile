//
//  RootView.swift
//  Protocare
//
//  Created by Alex Gorev on 21.12.2025.
//

import SwiftUI

struct RootView: View {
    @ObservedObject var authStore: AuthStore
    let api: AuthAPI

    var body: some View {
        if authStore.isAuthenticated {
            MainTabView(
                api: api,
                authStore: authStore
            )
        } else {
            AuthContainerView(api: api, authStore: authStore)
        }
    }
}

private struct MainTabView: View {
    let api: AuthAPI
    @ObservedObject var authStore: AuthStore
    @State private var selectedTab = 0

    @StateObject private var dashboardVM: DailyDashboardViewModel
    @StateObject private var journalVM: JournalListViewModel
    @StateObject private var protocolsVM: ProtocolsViewModel
    @StateObject private var profileVM: ProfileViewModel

    init(api: AuthAPI, authStore: AuthStore) {
        self.api = api
        self._authStore = ObservedObject(wrappedValue: authStore)
        _dashboardVM = StateObject(wrappedValue: DailyDashboardViewModel(api: api, authStore: authStore))
        _journalVM = StateObject(wrappedValue: JournalListViewModel(api: api, authStore: authStore))
        _protocolsVM = StateObject(wrappedValue: ProtocolsViewModel(api: api, authStore: authStore))
        _profileVM = StateObject(wrappedValue: ProfileViewModel(api: api, authStore: authStore))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DailyDashboardView(
                vm: dashboardVM,
                api: api,
                authStore: authStore,
                profileVM: profileVM
            )
            .tabItem {
                Label("Daily", systemImage: "checklist")
            }
            .tag(0)
            .onChange(of: selectedTab) { _, newTab in
                // Bug #6 fix: `.task` runs once per view lifetime inside a
                // TabView, so returning to the Daily tab showed stale data
                // (e.g. a check-in made from the Journal tab). Reload when
                // the tab becomes selected again.
                if newTab == 0 {
                    Task {
                        await dashboardVM.load()
                    }
                }
            }

            JournalListView(
                vm: journalVM,
                api: api,
                authStore: authStore
            )
            .tabItem {
                Label("Journal", systemImage: "book.fill")
            }
            .tag(1)

            ProtocolsView(
                vm: protocolsVM,
                api: api,
                authStore: authStore
            )
            .tabItem {
                Label("Protocols", systemImage: "list.clipboard.fill")
            }
            .tag(2)

            ProfileView(
                vm: profileVM,
                api: api,
                authStore: authStore
            )
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
            .tag(3)
        }
    }
}

#Preview {
    let api = APIClient(baseURL: URL(string: "http://localhost:8000/v1")!)
    RootView(
        authStore: AuthStore(),
        api: api
    )
}
