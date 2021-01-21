.PHONY: build deploy clean

build/wcj-cli.tgz:
	tar pcvfz build/wcj-cli.tgz --owner=0 --group=0 --transform 's,^\.,wcj-cli,' --exclude='build' .

build: build/wcj-cli.tgz

deploy: build
	aws s3 cp build/wcj-cli.tgz s3://womply-builds/wcj-cli/
	aws s3 cp bin/install.sh s3://womply-builds/wcj-cli/

clean:
	rm -rf build

$(shell mkdir -p build)

