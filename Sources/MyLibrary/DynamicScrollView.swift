//
//  DynamicScrollView.swift
//  MyLibrary
//
//  Created by Macbook on 15/1/25.
//

import SwiftUI

@available(iOS 17.0, *)
public struct ScrollTransitionView<Item: Identifiable, Content: View>: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    public var items: [Item]
    public var axis: Axis.Set = .horizontal
    public var numberItemPerpage: Int = 1
    public let content: (Item) -> Content
    
    
    
    public init(items: [Item], axis: Axis.Set, numberItemPerpage: Int, content: @escaping (Item) -> Content) {
        self.items = items
        self.axis = axis
        self.numberItemPerpage = numberItemPerpage
        self.content = content
    }
    
    public var body: some View {
        ScrollView(axis) {
            HStack {
                ForEach(items) { item in
                    content(item)
                        .containerRelativeFrame(.horizontal,
                                                count: verticalSizeClass == .regular ? numberItemPerpage : 4,
                                                spacing: 16)
                        //.foregroundStyle(item.color.gradient)
                        .scrollTransition { content, phase in
                            content
                                .opacity(phase.isIdentity ? 1.0 : 0.0)
                                .scaleEffect(x: phase.isIdentity ? 1.0 : 0.3,
                                             y: phase.isIdentity ? 1.0 : 0.3)
                                .offset(y: phase.isIdentity ? 0 : 50)
                        }
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(16, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
    }
}

// MARK: Example
/*
@available(iOS 17.0, *)
struct PowerScrollView: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass

    var numberItem = [1,2,3]
    @State var selectNumber: Int = 3
    
    
    var body: some View {
        Picker("select items", selection: $selectNumber) {
            ForEach(numberItem, id: \.self) { it in
                Text("\(it)")
            }
        }
        ScrollView(.horizontal) {
            HStack {
                ForEach(MockData.items) { item in
                    VStack {
                        Text("\(item.color)")
                            .font(.caption.bold())
                        Circle()
                            .containerRelativeFrame(.horizontal,
                                                    count: verticalSizeClass == .regular ? selectNumber : 4,
                                                    spacing: 16)
                            .foregroundStyle(item.color.gradient)
                            
                            
                    }
                    .scrollTransition { content, phase in
                        content
                            .opacity(phase.isIdentity ? 1.0 : 0.0)
                            .scaleEffect(x: phase.isIdentity ? 1.0 : 0.3,
                                         y: phase.isIdentity ? 1.0 : 0.3)
                            .offset(y: phase.isIdentity ? 0 : 50)
                    }
                    
                }
            }
            .scrollTargetLayout()
        }
        
        .contentMargins(16, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
    }
}

 @available(iOS 17.0, *)
 struct Item: Identifiable {
 let id = UUID()
 let color: Color
 }
 
 @available(iOS 17.0, *)
 struct MockData {
 static let items: [Item] = [
 Item(color: .brown),
 Item(color: .purple),
 Item(color: .indigo),
 Item(color: .teal),
 Item(color: .pink),
 Item(color: .red),
 Item(color: .blue),
 Item(color: .green),
 Item(color: .yellow),
 Item(color: .orange)
 ]
 }
 */
