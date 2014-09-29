HAKYLL_TARGETS= watch build rebuild deploy clean

site: site.hs
	ghc --make site.hs

.PHONY: ${HAKYLL_TARGETS}
${HAKYLL_TARGETS}: site
	./site $@


dist-clean:
	rm site