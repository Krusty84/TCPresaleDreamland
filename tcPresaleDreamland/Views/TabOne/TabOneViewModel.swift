//
//  ExampleViewModel.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 21/05/2025.
//

import Foundation

class TabOneViewModel: ObservableObject {
    @Published var title: String = "Hello, SwiftUI!"

    func changeTitle() {
        title = "Title changed!"
    }
}
