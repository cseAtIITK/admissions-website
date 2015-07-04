# Admissions website

This is the source code that drives the [admissions website] of the
department of Computer Science and Engineering at the Indian Institute
of Technology, Kanpur.

## System requirements

This is a static website generated using [Hakyll]. Any version >=4.5
should be okey for this. Besides you will need `GNU make` and `git` if
you want to contribute back. The pre-built packages available in
Debian stable (jessie) is enough of building the site.

The website is styled using [bootstrap version 3.2.0][bootstrap] for
css and font-awesome for some iconic fonts. These are include in the
source so you do not have to worry installing them.

## Contributing.

You can contribute to our GitHub repository and report bugs to our
issue tracker.

- Our repository is at <https://github.com/cseAtIITK/admissions-website>

- Report issues at <https://github.com/cseAtIITK/admissions-website/issues>

You can use the following command while working with the site.


```bash
make build # build the site
make watch # run a development server on localhost:8000 for testing
```

If you only care about the contents and not the code that builds the
website, you do not need to know any Haskell. You might need to know a
bit of pandoc. Most likely you would want to add a new
announcements. All you need to do is create a file in the are in the
director 'src/announcements/' with a file name prefixed by the date in
YYYY-MM-DD-Title.md format and compile the code. The body till the
'<!--more-->' will be treated as a teaser for the announcement.

You are free to also hack on the [Hakyll] source that builds the
website. But for this you would need to understand some Haskell.

## License

The material here is copyright Dept. of Computer Sci. and Engg, IIT
Kanpur.  The source code of this website is released under the BSD3
license and the contents under the Creative Commons Shared Alike. See
the directory LICENCES for the details. If you wish to contribute,
then you should agree to the terms and conditions spelt
there. Further, any contribution to this repository via a pull request
will be treated as implicitly agreeing to our policy regarding the
contents.

[admissions website]: <http://cse.iitk.ac.in/users/admissions> "Admissions website"
[bootstrap]: <http://getbootstrap.com> "Twitter bootstrap"
[hakyll]: <http://jaspervdj.be/hakyll/> "Hakyll"
