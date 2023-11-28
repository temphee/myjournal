//
//  JournalEditor.swift
//  MyJournal
//
//  Created by Reid on 2023/11/24.
//

import Foundation
import ComposableArchitecture

@Reducer
struct JournalEditor {
  struct State: Equatable {
    @PresentationState var destination: Destination.State?
    var journal: Journal
    @BindingState var contents: String = ""
    
    init(journal: Journal) {
      self.journal = journal
      self.contents = journal.contents
      self.destination = nil
    }
  }
  
  enum Action {
    case edit
    case dismissEditingMyJournal
    case doneEditingMyJournal
    case updateContents(String)
    case destination(PresentationAction<Destination.Action>)
    case delegate(Action.Delegate)
    case view(Action.ViewAction)
    
    public enum ViewAction: BindableAction {
      case binding(BindingAction<State>)
    }
    
    @CasePathable
    enum Delegate {
      case journalUpdated(Journal)
    }
  }
  
  var body: some Reducer<State, Action> {
    BindingReducer(action: \.view)
    
    Reduce { state, action in
      switch action {
      case .edit:
        state.destination = .sheetToEdit(JournalMeta.State(journal: state.journal))
        return .none
      case .view(.binding):
        state.journal.contents = state.contents
        return .none
      case .updateContents(let text):
        state.journal.contents = text
        return .none
      case .destination:
        return .none
      case .delegate:
        return .none
      case .dismissEditingMyJournal:
        state.destination = nil
        return .none
      case .doneEditingMyJournal:
        guard case let .sheetToEdit(metaData) = state.destination else {
          return .none
        }
        state.journal = metaData.journal
        state.destination = nil
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination) {
      Destination()
    }
    .onChange(of: \.journal) { oldValue, newValue in
      Reduce { state, action in
          .send(.delegate(.journalUpdated(newValue)))
      }
    }
  }
}


extension JournalEditor {
  @Reducer
  struct Destination {
    enum State: Equatable {
      case sheetToEdit(JournalMeta.State)
    }
    
    enum Action {
      case sheetToEdit(JournalMeta.Action)
    }
    
    var body: some ReducerOf<Self> {
      Scope(state: \.sheetToEdit, action: \.sheetToEdit) {
        JournalMeta()
      }
    }
  }
}

