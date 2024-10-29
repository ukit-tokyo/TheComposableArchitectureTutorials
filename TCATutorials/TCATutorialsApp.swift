//
//  TCATutorialsApp.swift
//  TCATutorials
//
//  Created by Taichi Yuki on 2024/10/29.
//

import SwiftUI
import ComposableArchitecture

@main
struct TCATutorialsApp: App {
  static let store = Store(initialState: CounterFeature.State()) {
    CounterFeature()
      ._printChanges()
  }

  var body: some Scene {
    WindowGroup {
      CounterView(store: Self.store)
    }
  }
}
