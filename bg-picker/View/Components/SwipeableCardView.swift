//
//  SwipeableCardView.swift
//  bg-picker
//
//  Created by Filipus Darren Siswanto on 05/05/26.
//

import SwiftUI
import Combine

struct SwipeableCardsView: View {
    
    @ObservedObject var swipeableViewModel: SwipeableViewModel
    @State private var dragState = CGSize.zero
    @State private var cardRotation: Double = 0
    
    private let swipeThreshold: CGFloat = 100.0
    private let rotationFactor: Double = 35.0
    
    var action: (SwipeableViewModel) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            let cardWidth  = geometry.size.width  * 0.85
            let cardHeight = geometry.size.height * 0.8

            if swipeableViewModel.unswipedCards.isEmpty && swipeableViewModel.swipedCards.isEmpty {
                emptyCardsView
                    .frame(width: geometry.size.width, height: geometry.size.height)
            } else if swipeableViewModel.unswipedCards.isEmpty {
                swipingCompletionView
                    .frame(width: geometry.size.width, height: geometry.size.height)
            } else {
                ZStack {
                    ForEach(swipeableViewModel.unswipedCards.reversed(), id: \.id) { card in
                        let isTop = card == swipeableViewModel.unswipedCards.first
                        let isSecond = card == swipeableViewModel.unswipedCards.dropFirst().first
                        
                        CardView(
                            model: card,
                            cardWidth: cardWidth,
                            cardHeight: cardHeight,
                            dragOffset: dragState,
                            isTopCard: isTop,
                            isSecondCard: isSecond
                        )
                        .offset(x: isTop ? dragState.width : 0)
                        .rotationEffect(.degrees(isTop ? Double(dragState.width) / rotationFactor : 0))
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    self.dragState = gesture.translation
                                    self.cardRotation = Double(gesture.translation.width) / rotationFactor
                                }
                                .onEnded { _ in
                                    if abs(self.dragState.width) > swipeThreshold {
                                        let swipeDirection: BoardGameCard.SwipeDirection = self.dragState.width > 0 ? .right : .left
                                        swipeableViewModel.updateTopCardSwipeDirection(swipeDirection)
                                        
                                        withAnimation(.easeOut(duration: 0.5)) {
                                            self.dragState.width = self.dragState.width > 0 ? 1000 : -1000
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            self.swipeableViewModel.removeTopCard()
                                            self.dragState = .zero
                                        }
                                    } else {
                                        withAnimation(.spring()) {
                                            self.dragState = .zero
                                            self.cardRotation = 0
                                        }
                                    }
                                }
                        )
                        .animation(.easeInOut, value: dragState)
                    }
                }
            }
        }
    }
    
    var emptyCardsView: some View {
        VStack {
            Text("No Cards")
                .font(.title)
                .padding(.bottom, 20)
                .foregroundStyle(.white.opacity(0.9))
        }
    }
    
    var swipingCompletionView: some View {
        VStack {
            Text("Finished Swiping")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.95))
        }
    }
}
