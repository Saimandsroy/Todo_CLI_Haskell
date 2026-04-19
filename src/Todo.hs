{-# LANGUAGE OverloadedStrings #-}

module Todo
  ( Priority (..)
  , Status (..)
  , Todo (..)
  , TodoList
  , TodoTitle (..)
  , validateTitle
  , parsePriority
  , addTodo
  , listTodos
  , formatTodo
  , completeTodo
  , deleteTodo
  , findTodo
  , nextTodoId
  , pendingTodos
  ) where

import Data.Aeson
  ( FromJSON (parseJSON)
  , ToJSON (toJSON)
  , Value (String)
  , object
  , withObject
  , withText
  , (.:)
  , (.=)
  )
import qualified Data.Text as Text

--- Represents the importance of a todo item.
data Priority = Low | Medium | High deriving (Show, Eq, Ord)

--- Represents whether a todo is still open or already finished.
data Status = Pending | Done deriving (Show, Eq)

--- Represents a single todo item in the system.
data Todo = Todo
  { todoId :: Int
  , title :: String
  , priority :: Priority
  , status :: Status
  } deriving (Show, Eq)

--- Represents the in-memory todo collection.
type TodoList = [Todo]

--- Wraps validated todo titles so invalid raw input does not leak into core logic.
newtype TodoTitle = TodoTitle { unTodoTitle :: String } deriving (Show, Eq)

--- Parses a text priority value into the domain type.
parsePriority :: String -> Either String Priority
parsePriority rawPriority =
  case Text.toLower $ Text.pack rawPriority of
    "low" -> Right Low
    "medium" -> Right Medium
    "high" -> Right High
    _ -> Left "Priority must be one of: low, medium, high."

--- Ensures a title is not blank before creating a todo.
validateTitle :: String -> Either String TodoTitle
validateTitle rawTitle =
  case Text.strip $ Text.pack rawTitle of
    textValue
      | Text.null textValue -> Left "Title cannot be empty."
      | otherwise -> Right $ TodoTitle $ Text.unpack textValue

--- Creates a new todo with the next available identifier.
addTodo :: TodoTitle -> Priority -> TodoList -> Todo
addTodo (TodoTitle todoTitle) todoPriority todos =
  Todo
    { todoId = nextTodoId todos
    , title = todoTitle
    , priority = todoPriority
    , status = Pending
    }

--- Renders all todos into CLI-friendly lines.
listTodos :: TodoList -> [String]
listTodos = map formatTodo

--- Renders a single todo into a human-readable line.
formatTodo :: Todo -> String
formatTodo todo =
  case status todo of
    Pending -> todoPrefix todo ++ " " ++ todoDetails todo
    Done -> todoPrefix todo ++ " " ++ todoDetails todo

--- Marks the matching todo as completed.
completeTodo :: Int -> TodoList -> Either String TodoList
completeTodo targetId todos =
  case findTodo targetId todos of
    Nothing -> Left $ "Todo #" ++ show targetId ++ " was not found."
    Just todo ->
      case status todo of
        Done -> Left $ "Todo #" ++ show targetId ++ " is already complete."
        Pending -> Right $ map (markDoneById targetId) todos

--- Removes the matching todo from the list.
deleteTodo :: Int -> TodoList -> Either String TodoList
deleteTodo targetId todos =
  case findTodo targetId todos of
    Nothing -> Left $ "Todo #" ++ show targetId ++ " was not found."
    Just _ -> Right $ filter (keepTodoById targetId) todos

--- Looks up a todo by its identifier.
findTodo :: Int -> TodoList -> Maybe Todo
findTodo targetId todos =
  case filter (matchesId targetId) todos of
    [] -> Nothing
    todo : _ -> Just todo

--- Calculates the next identifier using a fold over the current list.
nextTodoId :: TodoList -> Int
nextTodoId = (+ 1) . foldr highestId 0

--- Returns only todos that are still pending.
pendingTodos :: TodoList -> TodoList
pendingTodos = filter isPending

--- Renders the checkbox prefix for a todo.
todoPrefix :: Todo -> String
todoPrefix todo =
  case status todo of
    Pending -> "[ ]"
    Done -> "[x]"

--- Renders the descriptive part of a todo line.
todoDetails :: Todo -> String
todoDetails todo =
  "#" ++ show (todoId todo)
    ++ " "
    ++ title todo
    ++ " ("
    ++ show (priority todo)
    ++ ")"

--- Marks a todo as done when the identifier matches.
markDoneById :: Int -> Todo -> Todo
markDoneById targetId todo =
  case todoId todo == targetId of
    True -> todo {status = Done}
    False -> todo

--- Returns whether a todo should remain after deleting an identifier.
keepTodoById :: Int -> Todo -> Bool
keepTodoById targetId todo = todoId todo /= targetId

--- Returns whether the given todo has the requested identifier.
matchesId :: Int -> Todo -> Bool
matchesId targetId todo = todoId todo == targetId

--- Tracks the highest todo identifier seen so far.
highestId :: Todo -> Int -> Int
highestId todo currentMax = max (todoId todo) currentMax

--- Checks whether a todo is still pending.
isPending :: Todo -> Bool
isPending todo =
  case status todo of
    Pending -> True
    Done -> False

instance ToJSON Priority where
  --- Encodes a priority as a JSON string.
  toJSON priorityValue =
    case priorityValue of
      Low -> String "Low"
      Medium -> String "Medium"
      High -> String "High"

instance FromJSON Priority where
  --- Decodes a priority from a JSON string.
  parseJSON =
    withText "Priority" $ \rawPriority ->
      case parsePriority $ Text.unpack rawPriority of
        Left message -> fail message
        Right priorityValue -> pure priorityValue

instance ToJSON Status where
  --- Encodes a status as a JSON string.
  toJSON statusValue =
    case statusValue of
      Pending -> String "Pending"
      Done -> String "Done"

instance FromJSON Status where
  --- Decodes a status from a JSON string.
  parseJSON =
    withText "Status" $ \rawStatus ->
      case Text.toLower rawStatus of
        "pending" -> pure Pending
        "done" -> pure Done
        _ -> fail "Status must be either Pending or Done."

instance ToJSON Todo where
  --- Encodes a todo as a JSON object.
  toJSON todo =
    object
      [ "todoId" .= todoId todo
      , "title" .= title todo
      , "priority" .= priority todo
      , "status" .= status todo
      ]

instance FromJSON Todo where
  --- Decodes a todo from a JSON object.
  parseJSON =
    withObject "Todo" $ \todoObject ->
      Todo
        <$> todoObject .: "todoId"
        <*> todoObject .: "title"
        <*> todoObject .: "priority"
        <*> todoObject .: "status"
