module Main where

import           Control.Monad      (when)
import           Lib                (process)
import           System.Directory   (canonicalizePath, listDirectory)
import           System.Environment (getArgs)
import           System.FilePath    ((</>))

main :: IO ()
main = do
  args <- getArgs
  case args of
    [] -> error "Specify filepath to directory containing Markdown documentation"
    dir:_ ->
      listDirectory dir
      >>= mapM (readFile . (dir </>))
      >>= process . concat
