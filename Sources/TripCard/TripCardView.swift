//
//  TripCardView.swift
//  MyLibrary
//
//  Created by Macbook on 30/3/25.
//

// https://www.youtube.com/watch?v=3zBSgXoSugU

import SwiftUI

@available(iOS 17.0, *)
/// Trip Card Model
public struct TripCard: Identifiable, Hashable {
    public var id: UUID = .init()
    public var title: String
    public var subTitle: String
    public var image: String
}


@available(iOS 17.0, *)
public struct TripCardDemoView: View {
    /// View Properties
    @State private var searchText: String = ""
    
    @State var tripCards: [TripCard] = [
        .init(title: "London", subTitle: "England", image: "Cycling_Field"),
        .init(title: "New York", subTitle: "USA", image: "Cycling_Field2"),
        .init(title: "Prague", subTitle: "Czech Republic", image: "Equestrian_Field")
    ]
    
    public var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 15) {
                HStack(spacing: 12) {
                    Button(action: {}, label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.title)
                            .foregroundStyle(.blue)
                    })
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.gray)
                        TextField("Search", text: $searchText)
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: .capsule)
                }
                
                TripCardView(mainView: { item in
                    getMainView(item: item)
                }, content: { item in
                    getContentView(item: item)
                }, listItem: tripCards)
            }
            .padding(15)
        }
        .scrollIndicators(.hidden)
    }
    
    @ViewBuilder
    func getMainView(item: TripCard) -> some View {
        Image(item.image)
            .resizable()
    }
    
    @ViewBuilder
    func getContentView(item: TripCard) -> some View {
        VStack(alignment: .leading, spacing: 4, content: {
            Text(item.title)
                .font(.title2)
                .fontWeight(.black)
                .foregroundStyle(.white)
            Text(item.subTitle)
                .font(.callout)
                .foregroundStyle(.white.opacity(0.8))
        })
        .padding(20)
    }
}

@available(iOS 17.0, *)
public struct TripCardView<MainView: View, Content: View, Item: Identifiable>: View {
    
    @ViewBuilder private var mainView: (Item) -> MainView
    @ViewBuilder private var content: (Item) -> Content
    @State private var listItem: [Item]
    
    public init(
        mainView: @escaping (Item) -> MainView,
        content: @escaping (Item) -> Content,
        listItem: [Item]
    ) {
        self.mainView = mainView
        self.content = content
        self.listItem = listItem
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ScrollView(.horizontal) {
                HStack(spacing: 5) {
                    ForEach(listItem) { item in
                        /// In order to Move the Card in Reverse Direction
                        /// (Parallax Effect)
                        GeometryReader(content: { proxy in
                            let cardSize = proxy.size
                            // Parallax 2
                            let minX = proxy.frame(in: .scrollView).minX
                            
                            // Parallax 1
                            //let minX = min((proxy.frame(in: .scrollView).minX - 30) * 1.4, size.width * 1.4)
                            //Image(card.image)
                                //.resizable()
                            mainView(item)
                                .aspectRatio(contentMode: .fill)
                                .scaleEffect(1.25) // Parallax 2
                                .offset(x: -minX)
                                //.frame(width: proxy.size.width * 2.5) // Parallax 1
                                .frame(width: cardSize.width, height: cardSize.height)
                                .overlay{
                                    OverlayView(item)
                                }
                                .clipShape(.rect(cornerRadius: 15))
                                .shadow(color: .black.opacity(0.25), radius: 8, x: 5, y: 10)
                        })
                        .frame(width: size.width - 60, height: size.height - 50)
                        .scrollTransition(.interactive, axis: .horizontal) { view, phase in
                            view
                                .scaleEffect(phase.isIdentity ? 1 : 0.95)
                        }
                    }
                }
                .padding(.horizontal, 30)
                .scrollTargetLayout()
                .frame(height: size.height, alignment: .top)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
        }
        .frame(height: 500)
        .padding(.horizontal, -15)
        .padding(.top, 10)
    }
    
    /// Overlay View
    @ViewBuilder
    func OverlayView(_ item: Item) -> some View {
        ZStack(alignment: .bottomLeading, content: {
            LinearGradient(colors: [
                .clear,
                .clear,
                .clear,
                .clear,
                .clear,
                .black.opacity(0.1),
                .black.opacity(0.5),
                .black
            ], startPoint: .top, endPoint: .bottom)
            content(item)
        })
    }
}
