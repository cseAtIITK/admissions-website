{-# LANGUAGE OverloadedStrings #-}

import Control.Applicative
import Control.Monad
import Data.String
import Data.Version
import Hakyll
import System.FilePath

------------- Configuration  ---------------------------------

websiteSrc :: String -- source from which the website is built
websiteSrc = "src"

rsyncPath :: String  -- where to rsync the generated site
rsyncPath =  "ppk@turing.cse.iitk.ac.in:"
          ++ "/homepages/local/ppk/admissions/"

-- The version of the twitter bootstrap that is used. When you use a
-- new version, make sure to change this.

bootstrapVersion :: Version
bootstrapVersion = Version [3, 2, 0] []

-------------- Rules for building ------------------------------

bootstrapPat = fromString $  "bootstrap-"
                          ++  showVersion bootstrapVersion
                          </> "**"

rules :: Rules ()
rules = do
  -- Get the bootstrap stuff on.
  match bootstrapPat $ do
    route idRoute
    compile copyFileCompiler

  -- Templates
  match "templates/*.html" $ compile templateCompiler

  match "index.md" $ do
    route $ setExtension "html"
    compilePipeline indexPage


--------------- Compilers and contexts --------------------------

indexContext :: Context String
indexContext = defaultContext

type Pipeline a b = Item a -> Compiler (Item b)

-- | Similar to compile but takes a compiler pipeline instead.
compilePipeline ::  Pipeline String String -> Rules ()
compilePipeline pipeline = compile $ getResourceBody >>= pipeline

pandoc :: Pipeline String String
pandoc = reader >=> writer
  where reader = return . readPandoc
        writer = return . writePandoc

indexPage = applyAsTemplate indexContext
            >=> pandoc
            >=> postPandoc indexContext

-- | Stuff to do after pandocing.
postPandoc :: Context String -> Pipeline String String
postPandoc cxt = apply layoutT >=> apply wrapperT >=> relativizeUrls
  where apply template = loadAndApplyTemplate template cxt
        layoutT  = "templates/layout.html"
        wrapperT = "templates/wrapper.html"


--------------- Main and sundry ---------------------------------

main :: IO ()
main = hakyllWith config rules

config :: Configuration -- ^ The configuration. Don't edit this
                        -- instead edit the stuff on the top section

config = defaultConfiguration { deployCommand     = deploy
                              , providerDirectory = websiteSrc
                              }
  where rsync  dest = "rsync -avvz _site/ " ++ dest
        deploy = rsync rsyncPath
