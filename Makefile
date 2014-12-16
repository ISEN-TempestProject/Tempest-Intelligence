# You may need to do :
# export PATH=$PATH:/opt/arm-unknown-linux-gnueabi/bin/

all: 
	dub build --compiler=gdc --nodeps

deps:
	dub build --compiler=gdc

unittest:
	dub build --compiler=gdc --build=unittest

cov:
	dub build --compiler=gdc --build=unittest-cov
	./tempestintel
	gcov -p api
	-mkdir cov > /dev/null
	mv source\#* cov/
	rm *.gcov

cross:
	dub build --compiler=arm-unknown-linux-gnueabi-gdc

crossunittest:
	dub build --compiler=arm-unknown-linux-gnueabi-gdc --build=unittest

crossrelease:
	dub build --compiler=arm-unknown-linux-gnueabi-gdc --build=release

mount:
	-sudo umount /tmp/sshfs
	-rm -rf /tmp/sshfs
	-mkdir /tmp/sshfs
	sshfs /tmp/sshfs root@192.168.1.11:/root
	ls /tmp/sshfs

send: cross
	cp -r tempestintel res/ /tmp/sshfs/intel

sendconf: 
	cp -r res/ /tmp/sshfs/intel

#documentation generation
.PHONY: doc cov

doc:
	dmd -D -X -Xfdocs.json `find source -name "*.d"` -Dddoc -c -o-
	ddox generate-html docs.json doc

clean:
	rm -rf .dub/
	rm tempestintel