//
//  ContactsFeature.swift
//  TCATutorials
//
//  Created by Taichi Yuki on 2024/10/31.
//

import Foundation
import ComposableArchitecture

struct Contact: Equatable, Identifiable {
  let id: UUID
  var name: String
}

@Reducer
struct ContactsFeature {

  @ObservableState
  struct State: Equatable {
    var contacts: IdentifiedArrayOf<Contact> = []
    @Presents var destination: Destination.State?
    var path = StackState<ContactDetailFeature.State>()
  }

  enum Action {
    case addButtonTapped
    case destination(PresentationAction<Destination.Action>)
    case deleteButtonTapped(id: Contact.ID)
    case path(StackAction<ContactDetailFeature.State, ContactDetailFeature.Action>)

    enum Alert: Equatable {
      case confirmDeletion(id: Contact.ID)
    }
  }

  @Dependency(\.uuid) var uuid

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .addButtonTapped:
        state.destination = .addContact(
          AddContactFeature.State(
            contact: Contact(id: self.uuid(), name: "")
          )
        )
        return .none

      case .destination(.presented(.addContact(.delegate(.saveContact(let contact))))):
        state.contacts.append(contact)
        return .none

      case .destination(.presented(.alert(.confirmDeletion(let id)))):
        state.contacts.remove(id: id)
        return .none

      case .destination:
        return .none

      case .deleteButtonTapped(let id):
        state.destination = .alert(
          .deleteConfirmation(id: id)
        )
        return .none

      case .path(.element(id: let id, action: .delegate(.confirmDeletion))):
        guard let detailState = state.path[id: id] else { return .none }
        state.contacts.remove(id: detailState.contact.id)
        return .none

      case .path:
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
    .forEach(\.path, action: \.path) {
      ContactDetailFeature()
    }
  }
}

extension ContactsFeature {
  @Reducer
  enum Destination {
    case addContact(AddContactFeature)
    case alert(AlertState<ContactsFeature.Action.Alert>)
  }
}
extension ContactsFeature.Destination.State: Equatable {}

extension AlertState where Action == ContactsFeature.Action.Alert {
  static func deleteConfirmation(id: UUID) -> Self {
    Self {
      TextState("Are you sure?")
    } actions: {
      ButtonState(role: .destructive, action: .confirmDeletion(id: id)) {
        TextState("Delete")
      }
    }
  }
}

// MARK: -

import SwiftUI

struct ContactsView: View {
  @Bindable var store: StoreOf<ContactsFeature>

  var body: some View {
    NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
      List {
        ForEach(store.contacts) { contact in
          NavigationLink(state: ContactDetailFeature.State(contact: contact)) {
            HStack {
              Text(contact.name)
              Spacer()
              Button {
                store.send(.deleteButtonTapped(id: contact.id))
              } label: {
                Image(systemName: "trash")
                  .foregroundColor(.red)
              }
            }
          }
          .buttonStyle(.borderless)
        }
      }
      .navigationTitle("Contacts")
      .toolbar {
        ToolbarItem {
          Button {
            store.send(.addButtonTapped)
          } label: {
            Image(systemName: "plus")
          }
        }
      }
    } destination: { store in
      ContactDetailView(store: store)
    }
    .sheet(
      item: $store.scope(state: \.destination?.addContact, action: \.destination.addContact)
    ) { addContantStore in
      NavigationStack {
        AddContactView(store: addContantStore)
      }
    }
    .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
  }
}

#Preview {
  ContactsView(
    store: Store(
      initialState: ContactsFeature.State(
        contacts: [
          Contact(id: UUID(), name: "Blob"),
          Contact(id: UUID(), name: "Blob Jr"),
          Contact(id: UUID(), name: "Blob Sr"),
        ]
      )
    ) {
      ContactsFeature()
    }
  )
}
