all:
	dub build --nodeps --compiler=gdc

deps:
	dub build --compiler=gdc
