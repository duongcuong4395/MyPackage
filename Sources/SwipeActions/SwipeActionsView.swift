//
//  SwipeActionsView.swift
//  MyLibrary
//
//  Created by Macbook on 5/2/25.
//


import SwiftUI

@available(iOS 16.0, *)
public struct DemoSwipeActionsView: View {
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView(.vertical, content: {
                VStack {

                    ForEach(1...100, id: \.self) { _ in
                        Rectangle()
                            .fill(.black.gradient)
                        
                            .frame(height: 50)
                            .swipeActions {
                                Action(symbolImage: "square.and.arrow.up.fill", tint: .white, background: .blue) {
                                    resetPosition in
                                    resetPosition.toggle()
                                }
                                Action(symbolImage: "square.and.arrow.down.fill", tint: .white, background: .purple) {
                                    resetPosition in
                                }
                                Action(symbolImage: "trash.fill", tint: .white, background: .red) {
                                    resetPosition in
                                }
                            }
                    }
                }
                .padding(18)
            })
        }
        .navigationTitle("Custom Swipe Actions")
    }
}
