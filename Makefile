# You may need to do :
# export PATH=$PATH:/opt/arm-unknown-linux-gnueabi/bin/

all: 
	dub build --nodeps

deps:
	dub build --compiler=gdc

unittest:
	dub build --compiler=gdc --build=unittest

cross:
	dub build --compiler=arm-unknown-linux-gnueabi-gdc

crossunittest:
	dub build --compiler=arm-unknown-linux-gnueabi-gdc --build=unittest

crossrelease:
	dub build --compiler=arm-unknown-linux-gnueabi-gdc --build=release


#documentation generation
.PHONY: doc

doc:
	dmd -D -X -Xfdocs.json `find source -name "*.d"` -Dddoc -c -o-
	ddox generate-html docs.json doc
