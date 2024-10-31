//
//  CounterFeature.swift
//  TCATutorials
//
//  Created by Taichi Yuki on 2024/10/29.
//

import ComposableArchitecture

@Reducer
struct CounterFeature {

  @ObservableState
  struct State: Equatable {
    var count: Int = 0
    var fact: String?
    var isLoading: Bool = false
    var isTimerRunning: Bool = false
  }

  enum Action {
    case decrementButtonTapped
    case factButtonTapped
    case factResponse(String)
    case incrementButtonTapped
    case timerTick
    case toggleTimerButtonTapped
  }

  enum CancelID {
    case timer
  }

  @Dependency(\.continuousClock) var clock
  @Dependency(\.numberFact) var numberFact

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .decrementButtonTapped:
        state.count -= 1
        state.fact = nil
        return .none

      case .factButtonTapped:
        state.fact = nil
        state.isLoading = true

        return .run { [count = state.count] send in
          let fact = try await self.numberFact.fetch(count)
          await send(.factResponse(fact))
        }

      case .factResponse(let fact):
        state.fact = fact
        state.isLoading = false
        return .none

      case .incrementButtonTapped:
        state.count += 1
        state.fact = nil
        return .none

      case .timerTick:
        state.count += 1
        state.fact = nil
        return .none

      case .toggleTimerButtonTapped:
        state.isTimerRunning.toggle()
        if state.isTimerRunning {
          return .run { send in
            for await _ in self.clock.timer(interval: .seconds(1)) {
              await send(.timerTick)
            }
          }
          .cancellable(id: CancelID.timer)
        }
        else {
          return .cancel(id: CancelID.timer)
        }
      }
    }
  }
}

// MARK: - View

import SwiftUI

struct CounterView: View {
  let store: StoreOf<CounterFeature>

  var body: some View {
    VStack {
      Text("\(store.state.count)")
        .font(.largeTitle)
        .padding()
        .background(Color.black.opacity(0.1))
        .cornerRadius(10)
      HStack {
        Button("-") {
          store.send(.decrementButtonTapped)
        }
        .font(.largeTitle)
        .padding()
        .background(Color.black.opacity(0.1))
        .cornerRadius(10)

        Button("+") {
          store.send(.incrementButtonTapped)
        }
        .font(.largeTitle)
        .padding()
        .background(Color.black.opacity(0.1))
        .cornerRadius(10)
      }

      Button(store.isTimerRunning ? "Stop timer" : "Start timer") {
        store.send(.toggleTimerButtonTapped)
      }
      .font(.largeTitle)
      .padding()
      .background(Color.black.opacity(0.1))
      .cornerRadius(10)

      Button("Fact") {
        store.send(.factButtonTapped)
      }
      .font(.largeTitle)
      .padding()
      .background(Color.black.opacity(0.1))
      .cornerRadius(10)

      if store.isLoading {
        ProgressView()
      } else if let fact = store.fact {
        Text(fact)
          .font(.largeTitle)
          .multilineTextAlignment(.center)
          .padding()
      }
    }
  }
}

#Preview {
  CounterView(
    store: Store(initialState: CounterFeature.State()) {
      CounterFeature()
    }
  )
}
