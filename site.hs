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
