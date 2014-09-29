{-# LANGUAGE OverloadedStrings #-}

import Control.Applicative
import Control.Monad
import Data.Monoid
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

dateFormat :: String
dateFormat = "%B %e, %Y (%A)"

maxAnnouncements :: Int
maxAnnouncements = 10

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

  -- Announcements. This is essentially a blog.
  match announcePat $ do
    route $ announceRoute
    compilePipeline announcePage

  match "index.md" $ do
    route $ setExtension "html"
    compilePipeline indexPage


--------------- Compilers and contexts --------------------------

stdContext   :: Context String
stdContext   = defaultContext

indexContext :: Context String
indexContext = stdContext <> listField "announcements" announceContext
                                       announcements

defaultTemplates :: [Identifier]
defaultTemplates = [ "templates/layout.html"
                   , "templates/wrapper.html"
                   ]

type Pipeline a b = Item a -> Compiler (Item b)

-- | Similar to compile but takes a compiler pipeline instead.
compilePipeline ::  Pipeline String String -> Rules ()
compilePipeline pipeline = compile $ getResourceBody >>= pipeline

pandoc :: Pipeline String String
pandoc = reader >=> writer
  where reader = return . readPandoc
        writer = return . writePandoc

indexPage :: Pipeline String String
indexPage = applyAsTemplate indexContext
            >=> pandoc
            >=> postPandoc indexContext

postPandoc :: Context String -> Pipeline String String
postPandoc cxt = applyTemplates cxt defaultTemplates

applyTemplates :: Context String
               -> [Identifier]
               -> Pipeline String String
applyTemplates cxt = foldr (>=>) relativizeUrls . map apt
  where apt = flip loadAndApplyTemplate cxt

--------------- Compilers and routes for announcements --------
announcePat     :: Pattern
announcePat     = "announcements/*.md"

announceContext :: Context String
announceContext = stdContext <> dateField "date" dateFormat

-- Better named routes for announcements.
announceRoute :: Routes
announceRoute = customRoute beautify
  where beautify ident = dropExtension (toFilePath ident)
                         </> "index.html"

announcePage :: Pipeline String String
announcePage = pandoc
               >=> saveSnapshot "content"
               >=> postPandoc announceContext


-- | Generating feeds.
compileFeeds :: Compiler [Item String]
compileFeeds =   loadAllSnapshots announcePat "content"
             >>= fmap (take maxAnnouncements) . recentFirst
             >>= mapM relativizeUrls


announcements = loadAll announcePat
              >>= fmap (take maxAnnouncements) . recentFirst

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
