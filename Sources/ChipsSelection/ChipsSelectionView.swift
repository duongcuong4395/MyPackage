//
//  ChipsSelectionView.swift
//  MyLibrary
//
//  Created by Macbook on 13/3/25.
//

import SwiftUI

public let tags: [String] = ["iOS 14", "SwiftUI", "macOS", "watchOS", "tvOS", "Xcode", "macCatalyst", "UIKit", "AppKit", "Cocoa", "Objective-C"]

/*
 
public protocol ChipViewProtocol {}

@available(iOS 17.0.0, *)
public extension ChipViewProtocol {
    @ViewBuilder
    func ChipView(_ itemName: String, isSelected: Bool) -> some View {
        HStack(spacing: 10) {
            Text(itemName)
                .font(.callout)
                .foregroundStyle(isSelected ? .white : Color.primary)
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            ZStack {
                Capsule()
                    .fill(.background)
                    .opacity(!isSelected ? 1 : 0)
                Capsule()
                    .fill(.green.gradient)
                    .opacity(isSelected ? 1 : 0)
            }
        }
    }
}

*/

@available(iOS 17.0.0, *)
public struct DemoChipsSelectionView: View {
    public var isSelectOne: Bool
    @State private var selectedTags: [String] = []
    public init(isSelectOne: Bool = false) {
        self.isSelectOne = isSelectOne
    }
    
    public var body: some View {
        NavigationStack {
            VStack {
                ChipsView(tags: tags, selectedTags: $selectedTags, isSelectOne: isSelectOne) { tag, isSelected in
                    /// Your Custom View
                    ChipView(tag, isSelected: isSelected)
                } didChangeSelection: { selection in
                    print("Item Selection: ", selection)
                }
                .padding(10)
                //.background(.gray.opacity(0.1), in: .rect(cornerRadius: 20))
                
            }
            .padding(15)
            .navigationTitle("Chips Selection")
        }
        
    }

    @ViewBuilder
    func ChipView(_ tag: String, isSelected: Bool) -> some View {
        HStack(spacing: 10) {
            Text(tag)
                .font(.callout)
                .foregroundStyle(isSelected ? .white : Color.primary)
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            ZStack {
                Capsule()
                    .fill(.background)
                    .opacity(!isSelected ? 1 : 0)
                Capsule()
                    .fill(.green.gradient)
                    .opacity(isSelected ? 1 : 0)
            }
        }
    }
}





// MARK: New

@available(iOS 17.0.0, *)
public struct ChipsView2<Content: View, Tag: Equatable>: View where Tag: Hashable {
    
    
    public var hasMutiline: Bool = false
    public var hasFixedFirstItem: Bool = false
    public var spacing: CGFloat = 10
    public var animation: Animation = .easeInOut(duration: 0.2)
    public var tags: [Tag]
    public var isSelectOne: Bool
    @ViewBuilder public var content: (Tag, Bool) -> Content
    public var didChangeSelection: ([Tag]) -> ()
    @Binding public var selectedTags: [Tag]
        
    
    
    public init(
        hasMutiline: Bool = false
        , hasFixedFirstItem: Bool = false
        , spacing: CGFloat = 10
        , animation: Animation = .easeInOut(duration: 0.2)
        , tags: [Tag],
                selectedTags: Binding<[Tag]>,
                isSelectOne: Bool = false,
                content: @escaping (Tag, Bool) -> Content,
                didChangeSelection: @escaping ([Tag]) -> Void) {
        self.spacing = spacing
        self.animation = animation
        self.tags = tags
        self.content = content
        self.didChangeSelection = didChangeSelection
        self.isSelectOne = isSelectOne
        self._selectedTags = selectedTags
        self.hasFixedFirstItem = hasFixedFirstItem
        self.hasMutiline = hasMutiline
    }

    public var body: some View {
        if hasMutiline {
            CustomChipLayout2(spacing: spacing) {
                ForEach(hasFixedFirstItem ? Array(tags.dropFirst()) : tags, id: \.self) { tag in
                    chipView(for: tag)
                }
            }
        } else {
            HStack {
                if hasFixedFirstItem, let firstTag = tags.first {
                    chipView(for: firstTag)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack {
                        ForEach(hasFixedFirstItem ? Array(tags.dropFirst()) : tags, id: \.self) { tag in
                            chipView(for: tag)
                        }
                    }
                    
                }
            }
            .frame(maxHeight: 200)
        }
    }
    
    private func chipView(for tag: Tag) -> some View {
        content(tag, selectedTags.contains(tag))
            .contentShape(.rect)
            .onTapGesture {
                withAnimation(animation) {
                    handleSelection(of: tag)
                }
            }
    }
    
    private func handleSelection(of tag: Tag) {
        if isSelectOne {
            selectedTags = [tag]
        } else {
            if selectedTags.contains(tag) {
                selectedTags.removeAll(where: { $0 == tag })
            } else {
                selectedTags.append(tag)
            }
        }
        didChangeSelection(selectedTags)
    }
}

@available(iOS 17.0.0, *)
fileprivate struct CustomChipLayout2: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        return .init(width: width, height: calculateHeight(proposal: proposal, subviews: subviews))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var origin = bounds.origin
        var currentLineHeight: CGFloat = 0

        for subview in subviews {
            let fitSize = subview.sizeThatFits(proposal)

            if origin.x + fitSize.width > bounds.maxX {
                // Xuống dòng mới
                origin.x = bounds.minX
                origin.y += currentLineHeight + spacing
                currentLineHeight = 0
            }

            subview.place(at: origin, proposal: proposal)
            origin.x += fitSize.width + spacing
            currentLineHeight = max(currentLineHeight, fitSize.height)
        }
    }

    private func calculateHeight(proposal: ProposedViewSize, subviews: Subviews) -> CGFloat {
        var origin: CGPoint = .zero
        var totalHeight: CGFloat = 0
        var currentLineHeight: CGFloat = 0

        for subview in subviews {
            let fitSize = subview.sizeThatFits(proposal)

            if origin.x + fitSize.width > (proposal.width ?? 0) {
                // Xuống dòng mới
                origin.x = 0
                totalHeight += currentLineHeight + spacing
                currentLineHeight = 0
            }

            origin.x += fitSize.width + spacing
            currentLineHeight = max(currentLineHeight, fitSize.height)
        }

        // Cộng thêm chiều cao dòng cuối cùng
        totalHeight += currentLineHeight
        return totalHeight
    }
}


