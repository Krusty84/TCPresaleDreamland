//
//  JSONTreeView.swift
//  tcPresaleDreamland
//
//  Created by Sedoykin Alexey on 25/05/2025.
//


import SwiftUI

struct JSONTreeView: View {
    let data: Any
    @State private var expandedNodes: Set<String> = ["root"]
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: 4) {
                // Header row
                HStack(spacing: 16) {
                    Text("Property").frame(width: 200, alignment: .leading)
                    Text("Value").frame(width: 150, alignment: .leading)
                    Text("Type").frame(width: 100, alignment: .leading)
                }
                .font(.headline)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.1))
                
                // Render the root node
                renderAny(value: data, key: "root", path: "root")
            }
            .font(.system(size: 13, design: .monospaced))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: Rendering Methods
    
    @ViewBuilder
    private func renderAny(value: Any, key: String, path: String) -> some View {
        if let dict = value as? [String: Any] {
            renderDictionary(dict: dict, key: key, path: path)
        } else if let array = value as? [Any] {
            renderArray(array: array, key: key, path: path)
        } else {
            renderNode(key: key, value: value, path: path)
        }
    }
    
    @ViewBuilder
    private func renderDictionary(dict: [String: Any], key: String, path: String) -> some View {
        let isExpanded = expandedNodes.contains(path)
        
        HStack(spacing: 16) {
            HStack(spacing: 4) {
                Button {
                    toggleNode(path: path)
                } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .frame(width: 12)
                }
                .buttonStyle(.plain)
                
                Text(key)
            }
            .frame(width: 200, alignment: .leading)
            
            Text("\(dict.count) items")
                .frame(width: 150, alignment: .leading)
            
            Text("Object")
                .frame(width: 100, alignment: .leading)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
        
        if isExpanded {
            ForEach(dict.sorted(by: { $0.key < $1.key }), id: \.key) { (key, value) in
                renderAny(value: value, key: key, path: "\(path).\(key)")
                    .padding(.leading, 16)
            }
        }
    }
    
    @ViewBuilder
    private func renderArray(array: [Any], key: String, path: String) -> some View {
        let isExpanded = expandedNodes.contains(path)
        
        HStack(spacing: 16) {
            HStack(spacing: 4) {
                Button {
                    toggleNode(path: path)
                } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .frame(width: 12)
                }
                .buttonStyle(.plain)
                
                Text(key)
            }
            .frame(width: 200, alignment: .leading)
            
            Text("\(array.count) items")
                .frame(width: 150, alignment: .leading)
            
            Text("Array")
                .frame(width: 100, alignment: .leading)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
        
        if isExpanded {
            ForEach(Array(array.enumerated()), id: \.offset) { index, value in
                renderAny(value: value, key: "[\(index)]", path: "\(path)[\(index)]")
                    .padding(.leading, 16)
            }
        }
    }
    
    @ViewBuilder
    private func renderNode(key: String, value: Any, path: String) -> some View {
        HStack(spacing: 16) {
            HStack(spacing: 4) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 6))
                    .frame(width: 12)
                
                Text(key)
            }
            .frame(width: 200, alignment: .leading)
            
            Text(String(describing: value))
                .frame(width: 150, alignment: .leading)
            
            Text(typeName(value))
                .frame(width: 100, alignment: .leading)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
    
    // MARK: Helper Methods
    
    private func toggleNode(path: String) {
        if expandedNodes.contains(path) {
            expandedNodes.remove(path)
        } else {
            expandedNodes.insert(path)
        }
    }
    
    private func typeName(_ value: Any) -> String {
        switch value {
        case is String: return "String"
        case is Int: return "Int"
        case is Double: return "Double"
        case is Float: return "Float"
        case is Bool: return "Bool"
        case is [Any]: return "Array"
        case is [String: Any]: return "Object"
        default: return "\(type(of: value))"
        }
    }
}

// MARK: Convenience Initializers

extension JSONTreeView {
    init<T: Encodable>(encodable: T) {
        if let dict = try? JSONSerialization.jsonObject(with: JSONEncoder().encode(encodable)) as? [String: Any] {
            self.init(data: dict)
        } else {
            self.init(data: ["error": "Could not encode object"])
        }
    }
    
    init(jsonData: Data) {
        if let dict = try? JSONSerialization.jsonObject(with: jsonData) {
            self.init(data: dict)
        } else {
            self.init(data: ["error": "Invalid JSON data"])
        }
    }
    
    init(jsonString: String) {
        if let data = jsonString.data(using: .utf8) {
            self.init(jsonData: data)
        } else {
            self.init(data: ["error": "Invalid JSON string"])
        }
    }
}
