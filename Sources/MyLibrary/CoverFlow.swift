//
//  CoverFlow.swift
//  MyLibrary
//
//  Created by Macbook on 14/1/25.
//

/*
 import SwiftUI

 struct CoverFlowItem: Identifiable {
     let id: UUID = .init()
     let color: Color
 }

 struct DemoCoverFlowView: View {
     @State private var items: [CoverFlowItem] = [.red, .blue, .green, .yellow, .primary].compactMap {
         return .init(color: $0)
     }
     /// View Properties
     @State private var spacing: CGFloat = 0
     @State private var rotation: CGFloat = .zero
     @State private var enableReflection: Bool = false
     
     @State private var paddingH: CGFloat = 10

     var body: some View {
         NavigationStack {
             VStack {
                 Spacer(minLength: 0)
                 CoverFlowView(
                     itemWidth: UIScreen.main.bounds.width - paddingH,// , //280
                     enableReflection: enableReflection,
                     spacing: spacing,
                     rotation: rotation,
                     items: items
                 ) { item in
                     RoundedRectangle(cornerRadius: 20)
                         .fill(item.color.gradient)
                 }
                 //.frame(height: 180)
                 
                 Spacer(minLength: 0)
                 VStack(alignment: .leading, spacing: 10, content: {
                     Toggle("Toggle Reflection", isOn: $enableReflection)
                     /*
                     Text("Card Spacing \(spacing)")
                         .font(.caption2)
                         .foregroundStyle(.gray)
                     Slider(value: $spacing, in: -100...100)
                      */
                     Text("Padding Horizoltal \(rotation)")
                         .font(.caption2)
                         .foregroundStyle(.gray)
                     Slider(value: $paddingH, in: 0...90)
                     Text("Card Rotation \(rotation)")
                         .font(.caption2)
                         .foregroundStyle(.gray)
                     Slider(value: $rotation, in: 0...90)
                 })
                 .padding(15)
                 .background(.ultraThinMaterial, in: .rect(cornerRadius: 10))
                 .padding(15)
             }
             .navigationTitle("CoverFlow")
         }
         .preferredColorScheme(.dark)
     }
 }

 struct CoverFlowView<Content: View, Item: RandomAccessCollection>: View where Item.Element: Identifiable {
     /// Các thuộc tính tùy chỉnh
     var itemWidth: CGFloat
     var enableReflection: Bool = false // Tính năng phản chiếu (chưa được triển khai trong ví dụ này)
     var spacing: CGFloat = 0
     var rotation: Double = 45 // Góc xoay tối đa
     var items: Item
     var content: (Item.Element) -> Content

     var body: some View {
         GeometryReader {
             
             let size = $0.size
             
             ScrollView(.horizontal) {
                 LazyHStack(spacing: spacing) { // Sử dụng LazyHStack để tối ưu hiệu suất
                     ForEach(items) { item in
                         content(item)
                             .frame(width: itemWidth)
                             .reflection(enableReflection)
                             .visualEffect { content, geometryProxy in
                                 content
                                     .rotation3DEffect(.init(degrees: rotation(geometryProxy)), axis: (x: 0, y: 1, z: 0), anchor: .center)
                             }
                             //.padding(.trailing, item.id == items.last?.id ? 0 : spacing)
                             
                     }
                 }
                 .padding(.horizontal, (size.width - itemWidth) / 2) // Căn giữa các item
                 .scrollTargetLayout() // Cho phép cuộn đến từng item
             }
             
             .scrollTargetBehavior(.viewAligned) // Căn chỉnh item vào giữa khi cuộn
             .scrollIndicators(.hidden)
             .scrollClipDisabled()
         }
     }
     
     func rotation(_ proxy: GeometryProxy) -> Double {
         guard let bounds = proxy.bounds(of: .scrollView(axis: .horizontal)) else {
                 return 0 // Giá trị mặc định khi không có bounds
             }
             let scrollViewWidth = max(bounds.width, 1) // Đảm bảo không chia cho 0
             let midX = proxy.frame(in: .scrollView(axis: .horizontal)).midX
             let progress = midX / scrollViewWidth
             let cappedProgress = max(min(progress, 1), 0)

             let cappedRotation = max(min(rotation, 90), 0)
             let degrees = cappedProgress * (cappedRotation * 2)
             
             return max(min(cappedRotation - degrees, 90), -90)
     }

 }

 fileprivate extension View {
     @ViewBuilder
     func reflection(_ added: Bool) -> some View {
         self
             .overlay {
                 if added {
                     GeometryReader {
                         let size = $0.size
                         self
                             /// Flipping Upside Down
                             .scaleEffect(y: -1)
                             .mask {
                                 Rectangle()
                                     .fill(
                                         LinearGradient(colors: [
                                             .white,
                                             .white.opacity(0.7),
                                             .white.opacity(0.5),
                                             .white.opacity(0.3),
                                             .white.opacity(0.1),
                                             .white.opacity(0)
                                         ] + Array(repeating: Color.clear, count: 5), startPoint: .top, endPoint: .bottom)
                                     )
                             }
                             /// Moving to Bottom
                             .offset(y: size.height + 5)
                             .opacity(0.5)
                     }
                 }
                 
             }
     }
 }
 */
