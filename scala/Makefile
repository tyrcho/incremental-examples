.PHONY: build build-native run-native build-js serve-js fmt fmt-check lint clean

JS_OUT := js/target/scala-3.3.4/idle-clicker-js-fastopt

build: build-native build-js

build-native:
	sbt native/nativeLink

run-native: build-native
	./native/target/scala-3.3.4/idle-clicker-native

build-js:
	sbt js/fastLinkJS
	cp ../assets/coin_sheet.png $(JS_OUT)/
	cp js/src/main/resources/index.html $(JS_OUT)/

serve-js: build-js
	cd $(JS_OUT) && python3 -m http.server 8080

fmt:
	sbt scalafmt

fmt-check:
	sbt scalafmtCheck

lint:
	sbt scalafix

clean:
	sbt clean
