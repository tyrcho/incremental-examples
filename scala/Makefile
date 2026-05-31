.PHONY: build run clean fmt fmt-check lint

build:
	sbt nativeLink

run: build
	./target/scala-3.3.4/idle_clicker

fmt:
	sbt scalafmt

fmt-check:
	sbt scalafmtCheck

lint:
	sbt scalafix

clean:
	sbt clean
