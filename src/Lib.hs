module Lib
    ( process
    ) where

import           CMark
import           Control.Monad   (forM, forM_)
import           Data.Maybe      (catMaybes, mapMaybe)
import           Data.Text       (isPrefixOf, pack, splitOn, unpack)
import qualified Data.Text       as Text
import           System.FilePath (takeBaseName)

getCode :: NodeType -> Text.Text
getCode (CODE t) = t

isCode :: Node -> Bool
isCode (Node _ (CODE t) _) = t /= "" && not (pack "." `isPrefixOf` t)
isCode _                   = False

notHeading :: Node -> Bool
notHeading (Node _ (HEADING _) _) = False
notHeading _                      = True

processNode :: Node -> [Node] -> IO [String]
processNode (Node _ (HEADING _) titles) adj = do
  let kwds = filter isCode titles
  print kwds
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

process :: [FilePath] -> IO ()
process filepaths = do
  properties <- forM filepaths $ \ filepath -> do
        contents <- readFile filepath
        let mode = last $ splitOn "-" $ pack $ takeBaseName filepath
        properties <- processTop $ commonmarkToNode [] $ Text.pack contents
        return (mode, properties)
  writeFile "build/out.ts" $
    "// @ts-nocheck\n\n"
    <> concatMap (\ (m, s) -> "export const " <> unpack m <> " = {\n" <> unlines s <> "};\n") properties
    <> "export default {\n" <> unlines (map (\ (m, _) -> "..." <> unpack m <> ",") properties) <> "};\n"
