//
//  ContactDetailFeature.swift
//  TCATutorials
//
//  Created by Taichi Yuki on 2024/10/31.
//

import ComposableArchitecture

@Reducer
struct ContactDetailFeature {

  @ObservableState
  struct State: Equatable {
    let contact: Contact
    @Presents var alert: AlertState<Action.Alert>?
  }

  enum Action {
    case alert(PresentationAction<Alert>)
    case delegate(Delegate)
    case deleteButtonTapped

    enum Alert: Equatable {
      case confirmDeletion
    }
    enum Delegate {
      case confirmDeletion
    }
  }

  @Dependency(\.dismiss) var dismiss

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .alert(.presented(.confirmDeletion)):
        return .run { send in
          await send(.delegate(.confirmDeletion))
          await self.dismiss()
        }

      case .alert:
        return .none

      case .delegate:
        return .none

      case .deleteButtonTapped:
        state.alert = .confirmDeletion
        return .none
      }
    }
    .ifLet(\.$alert, action: \.alert)
  }
}

extension AlertState where Action == ContactDetailFeature.Action.Alert {
  static let confirmDeletion = Self {
    TextState("Are you sure?")
  } actions: {
    ButtonState(role: .destructive, action: .confirmDeletion) {
      TextState("Delete")
    }
  }
}

// MARK: -

import SwiftUI

struct ContactDetailView: View {
  @Bindable var store: StoreOf<ContactDetailFeature>

  var body: some View {
    Form {
      Button("Delete") {
        store.send(.deleteButtonTapped)
      }
    }
    .navigationTitle(Text(store.contact.name))
    .alert($store.scope(state: \.alert, action: \.alert))
  }
}

#Preview {
  ContactDetailView(
    store: Store(
      initialState: ContactDetailFeature.State(
        contact: Contact(id: UUID(), name: "Blob")
      )
    ) {
      ContactDetailFeature()
    }
  )
}
