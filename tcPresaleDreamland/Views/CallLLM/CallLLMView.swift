//
//  CallLLM.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 16/06/2025.
//

import SwiftUI

struct CallLLMView: View {
    // — Bindings for the values you edit —
    @Binding var domainName: String
    @Binding var countText: String
    @Binding var temperature: Double
    @Binding var maxTokens: Int

    // — Read-only flags & actions —
    let isLoading: Bool
    let generateAction: () -> Void
    //
    let generateButtonLabel: String
    let generateButtonHelp: String

    var body: some View {
        HStack {
            TextField("Domain", text: $domainName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 200)
                .help("Product (for example: airplane, transmitter)")

            HStack(spacing: 4) {
                Text("Count:")
                Stepper(
                    value: Binding(
                        get: { Int(countText) ?? 10 },
                        set: { countText = "\($0)" }
                    ),
                    in: 1...1000,
                    step: 1
                ) {
                    Text("\(Int(countText) ?? 10)")
                        .monospacedDigit()
                        .frame(width: 60)
                }
            }
            .help("Expected number of generated items")
            .frame(width: 140)

            HStack(spacing: 4) {
                Text("Temperature:")
                Stepper(value: $temperature, in: 0...1, step: 0.1) {
                    Text(String(format: "%.1f", temperature))
                        .monospacedDigit()
                        .frame(width: 40)
                }
            }
            .help("Higher = more creative, but less accurate")
            .frame(width: 200)

            HStack(spacing: 4) {
                Text("Tokens:")
                Stepper(value: $maxTokens, in: 100...4000, step: 100) {
                    Text("\(maxTokens)")
                        .monospacedDigit()
                        .frame(width: 50)
                }
            }
            .help("Maximum tokens the model can return")
            .frame(width: 160)

            Button(generateButtonLabel, action: generateAction)
                       .help(generateButtonHelp)
                       .disabled(isLoading || domainName.isEmpty)
        }
    }
}
