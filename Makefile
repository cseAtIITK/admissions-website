HAKYLL_TARGETS= watch build rebuild  clean
MAIN=admissions@turing.cse.iitk.ac.in:/homepages/global/admissions/
PREVIEW=admissions@turing.cse.iitk.ac.in:/homepages/local/admissions/

site: site.hs
	ghc --make site.hs

.PHONY: ${HAKYLL_TARGETS} deploy
${HAKYLL_TARGETS}: site
	./site $@

deploy-production: build
	SITE_RSYNC_URL=${MAIN} ./site deploy
deploy: build
	SITE_RSYNC_URL=${PREVIEW} ./site deploy

dist-clean:
	rm site