module Parser
  ( Command (..)
  , commandParser
  , parserInfo
  ) where

import Options.Applicative
  ( Parser
  , ParserInfo
  , argument
  , auto
  , command
  , fullDesc
  , header
  , help
  , helper
  , hsubparser
  , info
  , long
  , metavar
  , progDesc
  , short
  , strArgument
  , strOption
  , value
  )

--- Represents the supported CLI actions.
data Command
  = Add String String
  | List
  | Complete Int
  | Delete Int
  deriving (Show, Eq)

--- Builds the top-level command parser.
commandParser :: Parser Command
commandParser =
  hsubparser $
    command "add" (info addParser $ progDesc "Add a new todo")
      <> command "list" (info listParser $ progDesc "List all todos")
      <> command "complete" (info completeParser $ progDesc "Mark a todo as complete")
      <> command "delete" (info deleteParser $ progDesc "Delete a todo")

--- Defines the executable parser metadata.
parserInfo :: ParserInfo Command
parserInfo =
  info
    (helper <*> commandParser)
    ( fullDesc
        <> progDesc "Manage todos from the command line"
        <> header "haskell-todo-manager"
    )

--- Parses the add command arguments.
addParser :: Parser Command
addParser =
  Add
    <$> strArgument
      ( metavar "TITLE"
          <> help "Title of the todo item"
      )
    <*> strOption
      ( long "priority"
          <> short 'p'
          <> metavar "PRIORITY"
          <> value "medium"
          <> help "Priority: low, medium, or high"
      )

--- Parses the list command.
listParser :: Parser Command
listParser = pure List

--- Parses the complete command arguments.
completeParser :: Parser Command
completeParser = Complete <$> todoIdArgument

--- Parses the delete command arguments.
deleteParser :: Parser Command
deleteParser = Delete <$> todoIdArgument

--- Parses a todo identifier from the command line.
todoIdArgument :: Parser Int
todoIdArgument =
  argument auto
    ( metavar "TODO_ID"
        <> help "Identifier of the todo item"
    )
