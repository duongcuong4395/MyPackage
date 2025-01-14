//
//  StackedCards.swift
//  MyLibrary
//
//  Created by Macbook on 14/1/25.
//

/*
 struct StackedCardsView<Item: Identifiable, Content: View>: View {
     var items: [Item]
     @State private var isRotationEnabled: Bool = true
     @State private var showsIndicator: Bool = false
     let content: (Item) -> Content

     var body: some View {
         VStack {
             GeometryReader { proxy in
                 let size = proxy.size
                 ScrollView(.horizontal) {
                     HStack(spacing: 0) {
                         ForEach(items) { item in
                             content(item) // Sử dụng closure để render từng item
                                 .padding(.horizontal, 10)
                                 .frame(width: size.width)
                                 .visualEffect { content, geometryProxy in
                                     content
                                         .scaleEffect(scale(proxy: geometryProxy, scale: 0.1), anchor: .trailing)
                                         .rotationEffect(rotation(proxy: geometryProxy, rotation: isRotationEnabled ? 5 : 0))
                                         .offset(x: minX(geometryProxy))
                                         .offset(x: excessMinX(proxy: geometryProxy, offset: isRotationEnabled ? 8 : 10))
                                 }
                                 .zIndex(items.zIndex(item)) // Áp dụng zIndex
                         }
                     }
                     .padding(.vertical, 15)
                 }
                 .scrollTargetBehavior(.paging)
                 .scrollIndicators(showsIndicator ? .visible : .hidden)
             }
         }
     }

     // MARK: - Helper Functions
     func minX(_ proxy: GeometryProxy) -> CGFloat {
         let minX = proxy.frame(in: .scrollView(axis: .horizontal)).minX
         return minX < 0 ? 0 : -minX
     }

     func progress(_ proxy: GeometryProxy, limit: CGFloat = 2) -> CGFloat {
         let maxX = proxy.frame(in: .scrollView(axis: .horizontal)).maxX
         let width = proxy.bounds(of: .scrollView(axis: .horizontal))?.width ?? 0
         let progress = (maxX / width) - 1.0
         return min(progress, limit)
     }

     func scale(proxy: GeometryProxy, scale: CGFloat = 0.1) -> CGFloat {
         let progress = progress(proxy)
         return 1 - (progress * scale)
     }

     func excessMinX(proxy: GeometryProxy, offset: CGFloat = 10) -> CGFloat {
         let progress = progress(proxy)
         return progress * offset
     }

     func rotation(proxy: GeometryProxy, rotation: CGFloat = 5) -> Angle {
         let progress = progress(proxy)
         return .degrees(progress * rotation)
     }
 }

 */
