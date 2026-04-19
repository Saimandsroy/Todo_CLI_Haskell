module Main (main) where

import Options.Applicative (execParser)
import Parser (Command (..), parserInfo)
import Storage (loadTodos, saveTodos)
import System.Exit (exitFailure)
import Todo
  ( TodoList
  , addTodo
  , completeTodo
  , deleteTodo
  , formatTodo
  , listTodos
  , parsePriority
  , pendingTodos
  , validateTitle
  )

--- The JSON file used for persistence.
storageFile :: FilePath
storageFile = "todos.json"

--- Runs the CLI application.
main :: IO ()
main = do
  command <- execParser parserInfo
  result <- runCommand storageFile command
  case result of
    Left message -> printError message
    Right output -> putStrLn output

--- Executes a command by coordinating storage and pure business logic.
runCommand :: FilePath -> Command -> IO (Either String String)
runCommand path command = do
  todosResult <- loadTodos path
  case todosResult of
    Left message -> pure $ Left message
    Right todos ->
      case command of
        Add rawTitle rawPriority -> createTodo path todos rawTitle rawPriority
        List -> pure $ Right $ renderTodoList todos
        Complete targetId -> updateTodos path "completed" targetId todos completeTodo
        Delete targetId -> updateTodos path "deleted" targetId todos deleteTodo

--- Creates and persists a new todo item.
createTodo :: FilePath -> TodoList -> String -> String -> IO (Either String String)
createTodo path todos rawTitle rawPriority =
  case validateTitle rawTitle of
    Left message -> pure $ Left message
    Right todoTitle ->
      case parsePriority rawPriority of
        Left message -> pure $ Left message
        Right todoPriority -> do
          let newTodo = addTodo todoTitle todoPriority todos
          saveResult <- saveTodos path $ todos ++ [newTodo]
          case saveResult of
            Left message -> pure $ Left message
            Right () -> pure $ Right $ "Added todo: " ++ formatTodo newTodo

--- Applies a modifying command and writes the result back to disk.
updateTodos
  :: FilePath
  -> String
  -> Int
  -> TodoList
  -> (Int -> TodoList -> Either String TodoList)
  -> IO (Either String String)
updateTodos path actionName targetId todos updateFn =
  case updateFn targetId todos of
    Left message -> pure $ Left message
    Right updatedTodos -> do
      saveResult <- saveTodos path updatedTodos
      case saveResult of
        Left message -> pure $ Left message
        Right () -> pure $ Right $ "Todo #" ++ show targetId ++ " " ++ actionName ++ "."

--- Renders the todo list and a short summary for the CLI.
renderTodoList :: TodoList -> String
renderTodoList todos =
  case todos of
    [] -> "No todos yet. Add one with: haskell-todo-manager add \"Write docs\" --priority high"
    _ ->
      unlines $
        listTodos todos
          ++ [ ""
             , "Total: " ++ show (length todos)
             , "Pending: " ++ show (length $ pendingTodos todos)
             ]

--- Prints an error and exits with a failure code.
printError :: String -> IO a
printError message = do
  putStrLn $ "Error: " ++ message
  exitFailure
