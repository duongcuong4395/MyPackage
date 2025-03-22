//
//  ChipsSelectionView.swift
//  MyLibrary
//
//  Created by Macbook on 13/3/25.
//

import SwiftUI

public let tags: [String] = ["iOS 14", "SwiftUI", "macOS", "watchOS", "tvOS", "Xcode", "macCatalyst", "UIKit", "AppKit", "Cocoa", "Objective-C"]

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

@available(iOS 17.0.0, *)
public struct ChipsView<Content: View, Tag: Equatable>: View where Tag: Hashable {
    public var spacing: CGFloat = 10
    public var animation: Animation = .easeInOut(duration: 0.2)
    public var tags: [Tag]
    public var isSelectOne: Bool
    @ViewBuilder public  var content: (Tag, Bool) -> Content
    public var didChangeSelection: ([Tag]) -> ()
    /// View Properties
    //@State public var selectedTags: [Tag] = []
    @Binding public var selectedTags: [Tag]
    
    
    public init(tags: [Tag]
                , selectedTags: Binding<[Tag]>
                , isSelectOne: Bool = false
         , content: @escaping (Tag, Bool) -> Content
         , didChangeSelection: @escaping ([Tag]) -> Void) {
        self.tags = tags
        self.content = content
        self.didChangeSelection = didChangeSelection
        //self.selectedTags = selectedTags
        self.isSelectOne = isSelectOne
        self._selectedTags = selectedTags
    }
    
    
    public var body: some View {
        CustomChipLayout(spacing: spacing) {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    ForEach(tags, id: \.self) { tag in
                        content(tag, selectedTags.contains(tag))
                            .contentShape(.rect)
                            .onTapGesture {
                                withAnimation(animation) {
                                    if isSelectOne {
                                        selectedTags = [tag]
                                    } else {
                                        if selectedTags.contains(tag) {
                                            selectedTags.removeAll(where: { $0 == tag })
                                        } else {
                                            selectedTags.append(tag)
                                        }
                                    }
                                }
                                /// Callback after update!
                                didChangeSelection(selectedTags)
                            }
                    }
                }
                .padding(0)
            }
            .padding(0)
            
        }
        
    }
}

@available(iOS 17.0.0, *)
fileprivate struct CustomChipLayout: Layout {
    var spacing: CGFloat
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        return .init(width: width, height: maxHeight(proposal: proposal, subviews: subviews))
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var origin = bounds.origin
        for subview in subviews {
            let fitSize = subview.sizeThatFits(proposal)
            if (origin.x + fitSize.width) > bounds.maxX {
                origin.x = bounds.minX
                origin.y += fitSize.height + spacing
                subview.place(at: origin, proposal: proposal)
                origin.x += fitSize.width + spacing
            } else {
                subview.place(at: origin, proposal: proposal)
                origin.x += fitSize.width + spacing
            }
        }
    }

    private func maxHeight(proposal: ProposedViewSize, subviews: Subviews) -> CGFloat {
        var origin: CGPoint = .zero
        for subview in subviews {
            let fitSize = subview.sizeThatFits(proposal)
            if (origin.x + fitSize.width) > (proposal.width ?? 0) {
                origin.x = 0
                origin.y += fitSize.height + spacing
                
                origin.x += fitSize.width + spacing
            } else {
                origin.x += fitSize.width + spacing
            }
            
            if subview == subviews.last {
                origin.y = fitSize.height
            }
        }
        
        return origin.y
    }
}
