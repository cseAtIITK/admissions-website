HAKYLL_TARGETS= watch build rebuild  clean

site: site.hs
	ghc --make site.hs

.PHONY: ${HAKYLL_TARGETS} deploy
${HAKYLL_TARGETS}: site
	./site $@

deploy: build
	./site deploy

dist-clean:
	rm site