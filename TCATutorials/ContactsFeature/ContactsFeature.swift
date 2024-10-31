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
    @Presents var destination: Destination.State?
    var contacts: IdentifiedArrayOf<Contact> = []
  }

  enum Action {
    case addButtonTapped
    case destination(PresentationAction<Destination.Action>)
    case deleteButtonTapped(id: Contact.ID)

    enum Alert: Equatable {
      case confirmDeletion(id: Contact.ID)
    }
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .addButtonTapped:
        state.destination = .addContact(
          AddContactFeature.State(
            contact: Contact(id: UUID(), name: "")
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
          AlertState {
            TextState("Are you sure?")
          } actions: {
            ButtonState(role: .destructive, action: .confirmDeletion(id: id)) {
              TextState("Delete")
            }
          }
        )
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
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

// MARK: -

import SwiftUI

struct ContactsView: View {
  @Bindable var store: StoreOf<ContactsFeature>

  var body: some View {
    NavigationStack {
      List {
        ForEach(store.contacts) { contact in
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
