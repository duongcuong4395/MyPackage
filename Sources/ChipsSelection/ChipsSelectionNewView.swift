//
//  ChipsSelectionNewView.swift
//  MyLibrary
//
//  Created by Macbook on 6/4/25.
//

import SwiftUI

public enum ScrollType {
    case none
    case vertical
    case horizontal
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
    public var scrollType: ScrollType = .none
    
    public init(
        animation: Animation = .easeInOut(duration: 0.2)
            , tags: [Tag]
                , selectedTags: Binding<[Tag]>
                , isSelectOne: Bool = false
                , scrollType: ScrollType = .none
         , content: @escaping (Tag, Bool) -> Content
         , didChangeSelection: @escaping ([Tag]) -> Void) {
             self.animation = animation
        self.tags = tags
        self.content = content
        self.didChangeSelection = didChangeSelection
        //self.selectedTags = selectedTags
        self.isSelectOne = isSelectOne
        self._selectedTags = selectedTags
             self.scrollType = scrollType
    }
    
    
    public var body: some View {
        
        Group {
            switch scrollType {
            case .none:
                contentLayout()
            case .vertical:
                
                ScrollView(.vertical, showsIndicators: false) {
                    contentLayout()
                        .id("chipList")
                }
                
            case .horizontal:
                ScrollView(.horizontal, showsIndicators: false) {
                    contentLayout()
                }
            }
            
        }
        /*
        CustomChipLayout(spacing: spacing) {
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
        */
        
    }
    
    @ViewBuilder
    private func contentLayout() -> some View {
        CustomChipLayout(spacing: spacing) {
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
                        didChangeSelection(selectedTags)
                    }
            }
        }
        .padding(.vertical, 8)
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
