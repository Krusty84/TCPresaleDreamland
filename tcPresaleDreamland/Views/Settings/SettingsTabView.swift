//
//  SettingsTabContent.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 21/05/2025
//

import SwiftUI
import Combine

// Main Settings View with three tabs: General, LLM Prompts, Teamcenter
struct SettingsTabContent: View {
    @State private var selectedTab: Int = 0
    private let apiService = DeepSeekAPIService()
    @StateObject private var vm = SettingsTabViewModel()
    @State private var isHovering = false
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("General").tag(0)
                Text("LLM").tag(1)
                Text("Teamcenter").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Divider()
            
            Group {
                switch selectedTab {
                    case 0: generalSettingsTab
                    case 1: llmPromptsTab.disabled(true)
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
                    SectionHeader(title: "Application Preferences", systemImage: "gearshape.fill", isExpanded: true)
                }
                
                Divider()
                
                Section {
                    HStack {
                        TextField("API Key", text: $vm.apiKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        apiKeyStatusIndicator
                        Button("Verify", action: vm.verifyAPIKey)
                            .frame(minWidth: 60)
                            .disabled(vm.apiKey.isEmpty)
                            .help("Check API Key")
                    }
                    .padding(.horizontal, 8)
                } header: {
                    HStack {
                        SectionHeader(title: "DeepSeek Authentication", systemImage: "key.fill",isExpanded: true)
                        Spacer()
                        Link("Get API Key/Usage Data", destination: URL(string: APIConfig.deepSeekPlatform)!)
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                            .onHover { hovering in
                                isHovering = hovering
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                    }
                }
            }
            .padding(20)
        }
    }
    
    // MARK: LLM Prompts Tab
    private var llmPromptsTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Items Generation Section
                DisclosureGroup(isExpanded: $vm.isItemsSectionExpanded) {
                    VStack(alignment: .leading, spacing: 8) {
                        TextEditor(text: $vm.itemsPrompt)
                            .font(.body)
                            .frame(minHeight: 80)
                            .padding(4)
                            .background(Color(.textBackgroundColor))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(.separatorColor), lineWidth: 1)
                            )
                            .help("The prompt being used")
                        
                        HStack(spacing: 20) {
                            HStack {
                                Slider(value: $vm.itemsTemperature, in: 0...1, step: 0.1)
                                Text("\(vm.itemsTemperature, specifier: "%.1f")")
                                    .monospacedDigit()
                                    .frame(width: 30, alignment: .trailing)
                            }
                            .help("Creativity level: the higher the value, the more creative it is, but it might be far from reality")
                            
                            HStack {
                                Text("Max Tokens")
                                Stepper(value: $vm.itemsMaxTokens, in: 100...4000, step: 100) {
                                    Text("\(vm.itemsMaxTokens)")
                                        .monospacedDigit()
                                        .frame(width: 45, alignment: .trailing)
                                }
                            }
                            .help("The maximum number of tokens that can be generated")
                        }
                        .padding(.vertical, 4)
                        
                        HStack {
                            Spacer()
                            Button(action: vm.reseItemsToDefault) {
                                Text("Reset Defaults")
                                    .frame(minWidth: 100)
                            }
                            .controlSize(.regular)
                            .help("Reset your changes")
                        }
                        .padding(.top, 8)
                    }
                    .padding(12)
                    .background(Color(.windowBackgroundColor))
                    .cornerRadius(8)
                } label: {
                    SectionHeader(title: "Items Generation",
                                  systemImage: "cube.box.fill",
                                  isExpanded: vm.isItemsSectionExpanded)
                }
                
                // BOM Generation Section
                DisclosureGroup(isExpanded: $vm.isBOMSectionExpanded) {
                    VStack(alignment: .leading, spacing: 8) {
                        TextEditor(text: $vm.bomPrompt)
                            .font(.body)
                            .frame(minHeight: 80)
                            .padding(4)
                            .background(Color(.textBackgroundColor))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(.separatorColor), lineWidth: 1)
                            )
                            .help("The prompt being used")
                        
                        HStack(spacing: 20) {
                            HStack {
                                Slider(value: $vm.bomTemperature, in: 0...1, step: 0.1)
                                Text("\(vm.bomTemperature, specifier: "%.1f")")
                                    .monospacedDigit()
                                    .frame(width: 30, alignment: .trailing)
                            }
                            .help("Creativity level: the higher the value, the more creative it is, but it might be far from reality")
                            
                            HStack {
                                Text("Max Tokens")
                                Stepper(value: $vm.bomMaxTokens, in: 100...4000, step: 100) {
                                    Text("\(vm.bomMaxTokens)")
                                        .monospacedDigit()
                                        .frame(width: 45, alignment: .trailing)
                                }
                            }
                            .help("The maximum number of tokens that can be generated")
                        }
                        .padding(.vertical, 4)
                        
                        HStack {
                            Spacer()
                            Button(action: vm.resetBOMToDefault) {
                                Text("Reset Defaults")
                                    .frame(minWidth: 100)
                            }
                            .controlSize(.regular)
                            .help("Reset your changes")
                        }
                        .padding(.top, 8)
                    }
                    .padding(12)
                    .background(Color(.windowBackgroundColor))
                    .cornerRadius(8)
                } label: {
                    SectionHeader(title: "BOM Generation",
                                  systemImage: "list.bullet.rectangle",
                                  isExpanded: vm.isBOMSectionExpanded)
                }
                
                // Req Spec Generation Section
                DisclosureGroup(isExpanded: $vm.isReqSpecSectionExpanded) {
                    VStack(alignment: .leading, spacing: 8) {
                        TextEditor(text: $vm.reqSpecPrompt)
                            .font(.body)
                            .frame(minHeight: 80)
                            .padding(4)
                            .background(Color(.textBackgroundColor))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(.separatorColor), lineWidth: 1)
                            )
                            .help("The prompt being used")
                        
                        HStack(spacing: 20) {
                            HStack {
                                Slider(value: $vm.reqSpecTemperature, in: 0...1, step: 0.1)
                                Text("\(vm.reqSpecTemperature, specifier: "%.1f")")
                                    .monospacedDigit()
                                    .frame(width: 30, alignment: .trailing)
                            }
                            .help("Creativity level: the higher the value, the more creative it is, but it might be far from reality")
                            
                            HStack {
                                Text("Max Tokens")
                                Stepper(value: $vm.reqSpecMaxTokens, in: 100...4000, step: 100) {
                                    Text("\(vm.reqSpecMaxTokens)")
                                        .monospacedDigit()
                                        .frame(width: 45, alignment: .trailing)
                                }
                            }
                            .help("The maximum number of tokens that can be generated")
                        }
                        .padding(.vertical, 4)
                        
                        HStack {
                            Spacer()
                            Button(action: vm.resetReqSpecToDefault) {
                                Text("Reset Defaults")
                                    .frame(minWidth: 100)
                            }
                            .controlSize(.regular)
                        }
                        .padding(.top, 8)
                    }
                    .padding(12)
                    .background(Color(.windowBackgroundColor))
                    .cornerRadius(8)
                } label: {
                    SectionHeader(title: "Requirements Specification",
                                  systemImage: "doc.text.fill",
                                  isExpanded: vm.isReqSpecSectionExpanded)
                }
            }
            .padding(16)
        }
        .frame(minWidth: 450, idealWidth: 500, maxWidth: .infinity)
    }
    
    // MARK: Teamcenter Tab
    private var teamcenterTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                //Section {
                DisclosureGroup(isExpanded: $vm.isTeamcenterGeneral) {
                    
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("http(s)://ip-or-name-tc-webtier:port/webtier-name-typically tc",text: $vm.tcURL)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onReceive(Just(vm.tcURL)) { newValue in
                                let filtered = newValue.unicodeScalars
                                    .filter { vm.allowedUrlCharacters.contains($0) }
                                let clean = String(String.UnicodeScalarView(filtered))
                                if clean != newValue {
                                    vm.tcURL = clean
                                }
                            }
                        if !vm.tcURL.isEmpty && !vm.isValidTCURL {
                            Text("⚠️ Must be http://…:port/… or https://…:port/…")
                                .font(.footnote)
                                .foregroundColor(.red)
                        }
                        
                        TextField("http(s)://ip-or-name-awc:port",text: $vm.awcURL)
                           .textFieldStyle(RoundedBorderTextFieldStyle())
                           .onReceive(Just(vm.awcURL)) { newValue in
                               let filtered = newValue.unicodeScalars
                                   .filter { vm.allowedUrlCharacters.contains($0) }
                               let clean = String(String.UnicodeScalarView(filtered))
                               if clean != newValue {
                                   vm.awcURL = clean
                               }
                           }
                        if !vm.awcURL.isEmpty && !vm.isValidAWCURL {
                            Text("⚠️ Must be http://…:port or https://…:port")
                                   .font(.footnote)
                                   .foregroundColor(.red)
                           }
                        
                        // All in one line: Username, Password, Status, Verify Button
                        HStack(spacing: 10) {
                            TextField("Username", text: $vm.tcUsername)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(minWidth: 120)
                            
                            SecureField("Password", text: $vm.tcPassword)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(minWidth: 120)
                            //
                            tcStatusIndicator
                            //
                            Button("Verify") {
                                Task {
                                    await vm.verifyTCConnect()
                                }
                            }
                            .frame(minWidth: 60)
                            .disabled(vm.tcURL.isEmpty || vm.tcUsername.isEmpty || vm.tcPassword.isEmpty)
                            Spacer()
                            
                        }
                    }
                }
                label: {
                    SectionHeader(
                        title: "Connection Settings",
                        systemImage: "personalhotspot",
                        isExpanded: vm.isTeamcenterGeneral
                    )
                }
                DisclosureGroup(isExpanded: $vm.isTeamcenterDataTargetFolder) {
                    HomeFolderContent(rawData: vm.homeFolderContent)
                } label: {
                    SectionHeader(
                        title: "Data Target Folder",
                        systemImage: "folder",
                        isExpanded: vm.isTeamcenterObjectType
                    )
                }
                .disabled(!vm.tcLoginValid)
                
                DisclosureGroup(isExpanded: $vm.isTeamcenterObjectType) {
                    HStack(spacing: 0) {
                        // Column A
                        VStack(spacing: 4) {
                            Text("Items")
                                .font(.caption)
                            // .foregroundColor(.secondary)
                            ListEditorView(items: SettingsManager.shared.itemsListOfTypes)
                                .frame(maxWidth: .infinity, maxHeight: 10)
                        }
                        
                        // Column B
                        VStack(spacing: 4) {
                            Text("BOM's")
                                .font(.caption)
                            // .foregroundColor(.secondary)
                            ListEditorView(items: SettingsManager.shared.itemsListOfTypes)
                                .frame(maxWidth: .infinity, maxHeight: 10)
                        }
                        
                        // Column C
                        VStack(spacing: 4) {
                            Text("Requirements")
                                .font(.caption)
                            // .foregroundColor(.secondary)
                            ListEditorView(items: SettingsManager.shared.itemsListOfTypes)
                                .frame(maxWidth: .infinity, maxHeight: 10)
                        }
                    }
                    .frame(height: 300) // keep same height as before
                } label: {
                    SectionHeader(
                        title: "Object Types",
                        systemImage: "pencil.and.list.clipboard",
                        isExpanded: vm.isTeamcenterObjectType
                    )
                }
                .disabled(!vm.tcLoginValid)
            }
            .padding(20)
        }
    }
    
    // Existing API Key status view
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
                    Image(systemName: (200...299).contains(code) || code == 400
                          ? "checkmark.circle.fill"
                          : "xmark.circle.fill")
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
    
    // New TC Connect status view
    private var tcStatusIndicator: some View {
        VStack(alignment: .leading, spacing: 4) {
            if vm.isLoading {
                HStack(spacing: 4) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Connecting...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            else if let code = vm.tcResponseCode {
                HStack(spacing: 4) {
                    Image(systemName: (200...299).contains(code)
                          ? "checkmark.circle.fill"
                          : "xmark.circle.fill")
                    .foregroundColor((200...299).contains(code) ? .green : .red)
                    Text(tcStatusMessage(for: code))
                        .font(.caption)
                        .foregroundColor((200...299).contains(code) ? .green : .red)
                }
            }
            else if let error = vm.tcErrorMessage {
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
    
    private func tcStatusMessage(for code: Int) -> String {
        switch code {
            case 200...299: return "Connected"
            case 401: return "Invalid Credentials"
            case 403: return "Forbidden"
            case 500...599: return "Server Error"
            default: return "Error (\(code))"
        }
    }
    
    // Custom SectionHeader view that shows disclosure indicator
    struct SectionHeader: View {
        let title: String
        let systemImage: String
        var isExpanded: Bool
        
        var body: some View {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.headline)
                Spacer()
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .contentShape(Rectangle())
        }
    }
}

#if DEBUG
//struct SettingsTabContent_Previews: PreviewProvider {
//    static var previews: some View {
//        SettingsTabContent()
//    }
//}
#endif


