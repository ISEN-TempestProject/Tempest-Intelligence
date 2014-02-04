# You may need to do :
# export PATH=$PATH:/opt/arm-unknown-linux-gnueabi/bin/

all: native

native:
	dub build --compiler=gdc --nodeps

nativedeps:
	dub build --compiler=gdc

cross:
	dub build --compiler=arm-unknown-linux-gnueabi-gdc --nodeps

crossdeps:
	dub build --compiler=arm-unknown-linux-gnueabi-gdc
