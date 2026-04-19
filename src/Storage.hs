module Storage
  ( loadTodos
  , saveTodos
  , decodeTodos
  , encodeTodos
  ) where

import Control.Exception (IOException, try)
import Data.Aeson (eitherDecode, encode)
import qualified Data.ByteString.Lazy as ByteString
import System.Directory (doesFileExist)
import Todo (TodoList)

--- Converts raw JSON bytes into a todo list.
decodeTodos :: ByteString.ByteString -> Either String TodoList
decodeTodos = eitherDecode

--- Converts a todo list into JSON bytes.
encodeTodos :: TodoList -> ByteString.ByteString
encodeTodos = encode

--- Loads todos from disk and returns an empty list when the file does not exist yet.
loadTodos :: FilePath -> IO (Either String TodoList)
loadTodos path = do
  fileExists <- doesFileExist path
  case fileExists of
    False -> pure $ Right []
    True -> do
      readResult <- try $ ByteString.readFile path
      case readResult of
        Left fileError -> pure $ Left $ "Unable to read todos: " ++ showIoError fileError
        Right content -> pure $ decodeTodos content

--- Saves todos to disk as JSON.
saveTodos :: FilePath -> TodoList -> IO (Either String ())
saveTodos path todos = do
  writeResult <- try $ ByteString.writeFile path $ encodeTodos todos
  case writeResult of
    Left fileError -> pure $ Left $ "Unable to save todos: " ++ showIoError fileError
    Right _ -> pure $ Right ()

--- Normalizes IO exceptions into user-facing text.
showIoError :: IOException -> String
showIoError = show
