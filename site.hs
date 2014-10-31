{-# LANGUAGE OverloadedStrings #-}

import Control.Applicative
import Control.Monad
import Data.List
import Data.Monoid
import Data.String
import Data.Version
import Hakyll
import System.Environment
import System.FilePath
import Text.Pandoc

------------- Configuration  ---------------------------------

websiteSrc :: String -- source from which the website is built
websiteSrc = "src"

rsyncPath :: String  -- where to rsync the generated site
rsyncPath =  "admissions@turing.cse.iitk.ac.in:"
          ++ "/homepages/local/admissions/admissions/"

dateFormat :: String
dateFormat = "%B %e, %Y (%A)"

maxAnnouncements :: Int
maxAnnouncements = 10

-- The version of the twitter bootstrap that is used. When you use a
-- new version, make sure to change this.

bootstrapVersion :: Version
bootstrapVersion = Version [3, 2, 0] []

-- The configuration of feeds.
feedConfig :: FeedConfiguration
feedConfig = FeedConfiguration
  { feedTitle       = "Admissions at CSE.IITK"
  , feedDescription = "PG admissions at Dept. CSE, IIT Kanpur"
  , feedAuthorName  = "Admissions"
  , feedAuthorEmail = "admissions@cse.iitk.ac.in.REMOVETHISIFYOUAREAHUMAN"
  , feedRoot        = "http://cse.iitk.ac.in/users/admissions"
  }


-------------- Rules for building ------------------------------
bootstrapPat :: Pattern
bootstrapPat = fromString $  "bootstrap-"
                          ++  showVersion bootstrapVersion
                          </> "**"

rules :: Rules ()
rules = do
  -- Get the bootstrap stuff on.
  match bootstrapPat $ do
    route idRoute
    compile copyFileCompiler

  match "images/*" $ do
    route idRoute
    compile copyFileCompiler

  -- Templates
  match "templates/*" $ compile templateCompiler

  -- Announcements. This is essentially a blog.
  match announcePat $ do
    route $ beautifulRoute
    compilePipeline announcePage

  -- Create atom feeds for announcements.
  create ["atom.xml"] $ do
    route idRoute
    compile announceFeeds

  dateTags <- buildTagsWith (\ ident -> return [getYear ident])
                            announcePat
                            $ fromCapture "announcements/archive/*.html"

  match "announcements.html" $ do
    deps <- makePatternDependency announcePat
    rulesExtraDependencies [deps] $ do
      route idRoute
      compilePipeline $ allAnnounce $ sortTagsBy sortYear dateTags

  match "index.md" $ do
    route $ setExtension "html"
    compilePipeline indexPage

  match "**/index.md" $ do
    route $ setExtension "html"
    compilePipeline page

  match "faq.md" $ do
    route $ setExtension "html"
    compilePipeline $ faqPandoc >=> postPandoc defaultContext


--------------- Compilers and contexts --------------------------

type Pipeline a b = Item a -> Compiler (Item b)

-- | Similar to compile but takes a compiler pipeline instead.
compilePipeline ::  Pipeline String String -> Rules ()
compilePipeline pipeline = compile $ getResourceBody >>= pipeline

-- Better named routes for announcements.
beautifulRoute :: Routes
beautifulRoute = customRoute $ \ ident -> dropExtension (toFilePath ident)
                                          </> "index.html"

-- | Convert foo/index.html to foo/
cleanUrl :: Item String -> Compiler (Item String)
cleanUrl = return . fmap (withUrls rmIndex)
  where rmIndex url
          | isInfixOf "://" url = url
          | otherwise           = case splitFileName url of
            (dir, "index.html") -> dir
            _                   -> url


defaultTemplates :: [Identifier]
defaultTemplates = [ "templates/layout.html"
                   , "templates/wrapper.html"
                   ]


pandoc :: Pipeline String String
pandoc = pandocWith readPandoc writePandoc

faqPandoc :: Pipeline String String
faqPandoc = pandocWith readPandoc $ writePandocWith opts
  where opts = defaultHakyllWriterOptions
               { writerTableOfContents = True
               , writerStandalone      = True
               , writerTOCDepth        = 4
               , writerNumberSections  = True
               , writerTemplate        = "$toc$\n<hr/>$body$"
               }

-- Pandoc with a given reader and writer functions.
pandocWith :: (Item String -> Item Pandoc) -- the reader
           -> (Item Pandoc -> Item String) -- The writer
           -> Pipeline String String
pandocWith reader writer = return . reader >=> return . writer

postPandoc :: Context String -> Pipeline String String
postPandoc cxt = applyTemplates cxt defaultTemplates
                 >=> cleanUrl >=> relativizeUrls

applyTemplates :: Context String
               -> [Identifier]
               -> Pipeline String String
applyTemplates cxt = foldr1 (>=>) . map apt
  where apt = flip loadAndApplyTemplate cxt

---------------  Index page ----------------------------------


indexPage :: Pipeline String String
indexPage = applyAsTemplate indexContext
            >=> pandoc
            >=> postPandoc indexContext

page :: Pipeline String String
page = pandoc >=> postPandoc defaultContext

indexContext :: Context String
indexContext = defaultContext
               <> listField "announcements" announceContext announceIndex
               <> totalAnnounce "announcecount"

  where announceIndex = loadAll announcePat
                        >>= fmap (take maxAnnouncements) . recentFirst
--------------- Compilers and routes for announcements --------

announcePat     :: Pattern
announcePat     = "announcements/*.md"

announcePage :: Pipeline String String
announcePage = pandoc
               >=> saveSnapshot "content"
               >=> postPandoc announceContext

announceContext :: Context String
announceContext = defaultContext  <> dateField "date" dateFormat
                                  <> dateField "month" "%b"
                                  <> dateField "year"  "%Y"
                                  <> dateField "day"   "%a"
                                  <> dateField "dayofmonth" "%e"
                                  <> teaserField "teaser" "content"
announceFeedContext :: Context String
announceFeedContext = announceContext <> bodyField "description"


-- | Generating feeds.
announceFeeds   :: Compiler (Item String)
announceFeeds   = loadAllSnapshots announcePat "content"
                >>= recentFirst
                >>= renderAtom feedConfig feedContext
                >>= relativizeUrls
  where feedContext = announceContext <> bodyField "description"

------------------- All announcements.

announceCount :: Compiler String
announceCount = fmap (show . length) $ getMatches announcePat

totalAnnounce :: String -> Context String
totalAnnounce nm = field nm (const announceCount)

allAnnounce :: Tags -> Pipeline String String
allAnnounce tags = applyAsTemplate allContext
                   >=> postPandoc indexContext
  where allContext = defaultContext
                   <> listField "yearly" announceContext
                                         announceIndex
        announceIndex = yearTagsCompiler tags

-- | This function generates the year of the post from its
-- identifier. This is used in building the archives.
getYear :: Identifier -> String
getYear = takeWhile (/= '-') . takeFileName . toFilePath

-- | Sorting year tags with
sortYear :: (String,a) -> (String, a) -> Ordering
sortYear (y,_) (y',_) = compare (read y :: Int) $ read y'

yearTagsCompiler :: Tags -> Compiler [Item String]
yearTagsCompiler tags =
  sequence [ yearTagRender y ids | (y,ids) <- tagsMap tags ]


yearTagRender :: String -> [Identifier] -> Compiler (Item String)
yearTagRender y idents = makeItem ("" :: String)
                         >>= loadAndApplyTemplate "templates/year.html"
                             context
  where context = constField "year" y
                  <> constField "count" (show $ length idents)
                  <> listField "announcements" announceContext annIndex


        annIndex = loadAll (fromList idents) >>= recentFirst

--------------- Main and sundry ---------------------------------

main :: IO ()
main = do conf <- config
          hakyllWith conf rules

config :: IO Configuration
config = fromEnv <$> getEnvironment
  where fromEnv  = maybe siteConf setRsyncUrl . lookup "SITE_RSYNC_URL"
        siteConf = defaultConfiguration { providerDirectory = websiteSrc }
        setRsyncUrl u = siteConf { deployCommand = rsync u }
        rsync  dest = "rsync -avvz _site/ " ++ dest
