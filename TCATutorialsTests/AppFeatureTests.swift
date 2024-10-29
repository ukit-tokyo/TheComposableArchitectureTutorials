//
//  AppFeatureTests.swift
//  TCATutorialsTests
//
//  Created by Taichi Yuki on 2024/10/30.
//

import Testing
import ComposableArchitecture

@testable import TCATutorials

@MainActor
struct AppFeatureTests {

  @Test
  func incrementInFirstTab() async {
    let store = TestStore(initialState: AppFeature.State()) {
      AppFeature()
    }

    await store.send(\.tab1.incrementButtonTapped) {
      $0.tab1.count = 1
    }
  }
}
