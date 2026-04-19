A small Haskell command-line application for managing todo items with pure business logic, typed domain modeling, explicit error handling, and JSON persistence.

## Features

- Add a todo item with a priority
- List all todos
- Mark a todo as complete
- Delete a todo
- Persist todos to `todos.json`

## Project Structure

```text
haskell-todo-manager/
├── haskell-todo-manager.cabal
├── README.md
├── todos.json
└── src
    ├── Main.hs
    ├── Parser.hs
    ├── Storage.hs
    └── Todo.hs
```

## Tech Stack

- GHC
- Cabal
- `aeson` for JSON serialization
- `optparse-applicative` for CLI parsing

## Getting Started

1. Install GHC and Cabal.
2. Open the project directory:

```bash
cd /Users/saimandsroy/Documents/New\ project/haskell-todo-manager
```

3. Build the executable:

```bash
cabal build
```

4. Run the CLI:

```bash
cabal run haskell-todo-manager -- list
```

## Example Commands

```bash
cabal run haskell-todo-manager -- add "Write project README" --priority high
cabal run haskell-todo-manager -- add "Refactor parser module" --priority medium
cabal run haskell-todo-manager -- list
cabal run haskell-todo-manager -- complete 1
cabal run haskell-todo-manager -- delete 2
```

## Terminal Demo

This is a sample CLI session that shows the app in action:

```text
$ cabal run haskell-todo-manager -- add "Build backend portfolio project" --priority high
Added todo: [ ] #1 Build backend portfolio project (High)

$ cabal run haskell-todo-manager -- add "Write Haskell README walkthrough" --priority medium
Added todo: [ ] #2 Write Haskell README walkthrough (Medium)

$ cabal run haskell-todo-manager -- list
[ ] #1 Build backend portfolio project (High)
[ ] #2 Write Haskell README walkthrough (Medium)

Total: 2
Pending: 2

$ cabal run haskell-todo-manager -- complete 1
Todo #1 completed.

$ cabal run haskell-todo-manager -- list
[x] #1 Build backend portfolio project (High)
[ ] #2 Write Haskell README walkthrough (Medium)

Total: 2
Pending: 1

$ cabal run haskell-todo-manager -- delete 2
Todo #2 deleted.

$ cabal run haskell-todo-manager -- list
[x] #1 Build backend portfolio project (High)

Total: 1
Pending: 0
```

## Functional Programming Concepts Demonstrated

### 1. Pure functions for business logic

All todo rules live in `src/Todo.hs`. Functions like `addTodo`, `completeTodo`, `deleteTodo`, `nextTodoId`, and `pendingTodos` work only with data passed into them and return new values without touching the filesystem or the terminal.

Why this matters:

- Pure logic is easier to test.
- Behavior stays predictable.
- Backend code becomes easier to refactor and reuse.

### 2. Custom data types with `data`

The project models domain concepts directly:

```haskell
data Priority = Low | Medium | High deriving (Show, Eq, Ord)
data Status = Pending | Done deriving (Show, Eq)
data Todo = Todo
  { todoId :: Int
  , title :: String
  , priority :: Priority
  , status :: Status
  }
```

Why this matters:

- Invalid states become harder to represent.
- The code reads more like the business domain.
- Pattern matching becomes clear and expressive.

### 3. `newtype` for stronger boundaries

`TodoTitle` is defined as a `newtype` so validated titles can be separated from raw user input.

```haskell
newtype TodoTitle = TodoTitle { unTodoTitle :: String }
```

Why this matters:

- It creates a small but meaningful boundary in the domain model.
- Validation happens once, then downstream code can rely on the result.

### 4. `Maybe` and `Either` instead of exceptions

The core logic never throws exceptions.

- `findTodo :: Int -> TodoList -> Maybe Todo` uses `Maybe` for optional results.
- `completeTodo` and `deleteTodo` return `Either String TodoList` for explicit failures.
- `validateTitle` and `parsePriority` also return `Either String ...`.

Why this matters:

- Error paths are visible in function signatures.
- Callers are forced to handle failures intentionally.
- This style scales well in backend services and APIs.

### 5. Pattern matching

Pattern matching is used throughout the app:

- Matching on `Priority` and `Status`
- Matching on `Maybe` and `Either`
- Matching on lists like `[]` and `todo : _`
- Matching on CLI commands in `Main.hs`

Why this matters:

- It keeps branching logic explicit.
- It often reads more clearly than imperative condition chains.

### 6. Function composition with `(.)` and `($)`

The code uses both operators in practical ways:

- `nextTodoId = (+ 1) . foldr highestId 0`
- `putStrLn $ "Error: " ++ message`
- `saveTodos path $ todos ++ [newTodo]`

Why this matters:

- Composition makes small pure functions easier to combine.
- It keeps code concise without losing readability.

### 7. `map`, `filter`, and `foldr`

Common list transforms are used in the core module:

- `map formatTodo` for rendering todos
- `filter` for deletion and pending-item views
- `foldr` for computing the next available ID

Why this matters:

- This is the everyday toolkit of functional collection processing.
- It replaces mutable loops with declarative transformations.

### 8. Separation of IO from pure logic

The project is split on purpose:

- `Main.hs` handles application flow and terminal output
- `Parser.hs` handles CLI parsing
- `Storage.hs` handles file IO only
- `Todo.hs` contains pure domain logic

Why this matters:

- It mirrors strong backend architecture
- Side effects stay isolated
- Core rules remain simple to reason about

## Module Notes

### `src/Main.hs`

This module coordinates the app. It loads todos, calls pure functions, saves updated state, and prints messages for the user.

### `src/Todo.hs`

This is the heart of the app. It owns the domain model, validation, rendering helpers, and state transitions.

### `src/Storage.hs`

This module sits at the IO edge. It reads and writes `todos.json` and translates failures into `Either String`.

### `src/Parser.hs`

This module defines the command-line interface with `optparse-applicative`.
