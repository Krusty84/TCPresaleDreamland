//
//  SettingsTabContent.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 21/05/2025
//

import SwiftUI
import LaunchAtLogin

// Main Settings View with three tabs: General, LLM Prompts, Teamcenter
struct SettingsTabContent: View {
    @State private var selectedTab: Int = 0
    private let apiService = DeepSeekAPIService()
    @StateObject private var vm = SettingsTabViewModel()
    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("General").tag(0)
                Text("LLM Prompts").tag(1)
                Text("Teamcenter").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.top, 20)

            Divider()

            Group {
                switch selectedTab {
                case 0: generalSettingsTab
                case 1: llmPromptsTab
                case 2: teamcenterTab
                default: EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: General Tab
    private var generalSettingsTab: some View {
        ScrollView {
            VStack(spacing: 10) {
                Section {
                    HStack(spacing: 20) {
                        Toggle("Application Logging", isOn: $vm.appLoggingEnabled)
                            .toggleStyle(.switch)
                            .help("Enable/disable application logging")
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                } header: {
                    SectionHeader(title: "Application Preferences", systemImage: "gearshape.fill")
                }

                Divider()

                Section {
                    HStack {
                        TextField("API Key", text: $vm.apiKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        apiKeyStatusIndicator
                        Button("Verify", action: vm.verifyAPIKey)
                            .frame(minWidth: 60)
                    }
                    .padding(.horizontal, 8)
                } header: {
                    SectionHeader(title: "API Key", systemImage: "key.fill")
                }
            }
            .padding(20)
        }
    }

    // MARK: LLM Prompts Tab
    private var llmPromptsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("BOM Generation Prompt", text: $vm.bomPrompt)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        TextField("Req Spec Generation Prompt", text: $vm.reqSpecPrompt)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        TextField("Items Generation Prompt", text: $vm.itemsPrompt)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.horizontal, 8)
                } header: {
                    SectionHeader(title: "LLM Prompts", systemImage: "brain.head.profile")
                }

                HStack {
                    Spacer()
                    Button("Reset Defaults", action: vm.resetPromptsToDefault)
                }
                .padding()
            }
            .padding(20)
        }
    }

    // MARK: Teamcenter Tab
    private var teamcenterTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("TC URL", text: $vm.tcURL)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        TextField("AWC URL", text: $vm.awcURL)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        TextField("Username", text: $vm.tcUsername)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        SecureField("Password", text: $vm.tcPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.horizontal, 8)
                } header: {
                    SectionHeader(title: "Teamcenter Settings", systemImage: "server.rack")
                }

                HStack {
                    Spacer()
                    Button("Verify", action: vm.verifyTCConnect)
                }
                .padding()
            }
            .padding(20)
        }
    }
    
    
    // MARK: – Helpers
    private struct SectionHeader: View {
        let title: String
        let systemImage: String
        var body: some View {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.headline)
                Spacer()
            }
            .padding(.bottom, 8)
        }
    }
    
    private var apiKeyStatusIndicator: some View {
        VStack(alignment: .leading, spacing: 4) {
            if vm.isLoading {
                HStack(spacing: 4) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Checking...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            else if let code = vm.responseCode {
                HStack(spacing: 4) {
                    Image(systemName: (200...299).contains(code) || code == 400 ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor((200...299).contains(code) || code == 400 ? .green : .red)
                    
                    Text(statusMessage(for: code))
                        .font(.caption)
                        .foregroundColor((200...299).contains(code) || code == 400 ? .green : .red)
                }
            }
            else if let error = vm.errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
    }

    private func statusMessage(for code: Int) -> String {
        switch code {
        case 200...299: return "Valid API Key"
        case 400: return "Valid Key (Empty Request)"
        case 401: return "Invalid API Key"
        case 403: return "Access Denied"
        case 429: return "Rate Limited"
        case 500...599: return "Server Error"
        default: return "Error (\(code))"
        }
    }
}


#if DEBUG
struct SettingsTabContent_Previews: PreviewProvider {
    static var previews: some View {
        SettingsTabContent()
    }
}
#endif

