module Lib
    ( process
    ) where

import           CMark
import           Control.Monad (forM, forM_)
import           Data.Maybe    (catMaybes, mapMaybe)
import           Data.Text     (unpack)
import qualified Data.Text     as Text

getCode :: NodeType -> Text.Text
getCode (CODE t) = t

isCode :: Node -> Bool
isCode (Node _ (CODE t) _) = t /= ""
isCode _                   = False

notHeading :: Node -> Bool
notHeading (Node _ (HEADING _) _) = False
notHeading _                      = True

processNode :: Node -> [Node] -> IO [String]
processNode (Node _ (HEADING _) titles) adj = do
  let kwds = filter isCode titles
  fmap concat $ forM kwds $ \ (Node _ t _) -> do
    let kwd = unpack $ getCode t
    let prettyDef = concatMap (\ c -> if c == '`' then ['\\', c] else [c]) $ unlines (map (unpack . nodeToCommonmark [] Nothing) adj)
    return ["'" <> kwd <> "' : `" <> prettyDef <> "`,\n"]
processNode _ _ = return []

processTop :: Node -> IO [String]
processTop (Node _ DOCUMENT kids) = aux kids
  where
    aux (h:rest) =
      case h of
        Node _ (HEADING _) _ ->
          processNode h (takeWhile notHeading rest) <> aux rest
        _ -> aux rest
    aux [] = return []

process :: String -> IO ()
process contents = do
  properties <- processTop $ commonmarkToNode [] $ Text.pack contents
  writeFile "build/out.ts" $
    "// @ts-nocheck\n\nexport default {\n" <> unlines properties <> "};\n"
