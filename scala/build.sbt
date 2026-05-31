import scala.scalanative.build.*

val scala3 = "3.3.4"

lazy val core = crossProject(JSPlatform, NativePlatform)
    .crossType(CrossType.Pure)
    .in(file("core"))
    .settings(
        name         := "idle-clicker-core",
        scalaVersion := scala3,
        semanticdbEnabled := true,
        semanticdbVersion := scalafixSemanticdb.revision
    )

lazy val native = project
    .in(file("native"))
    .enablePlugins(ScalaNativePlugin)
    .dependsOn(core.native)
    .settings(
        name         := "idle-clicker-native",
        scalaVersion := scala3,
        nativeConfig ~= { c =>
            c.withLTO(LTO.none)
                .withMode(Mode.releaseFast)
                .withGC(GC.commix)
                .withLinkingOptions(
                    c.linkingOptions ++ Seq(
                        "-L/opt/homebrew/lib",
                        "-framework",
                        "Cocoa",
                        "-framework",
                        "IOKit",
                        "-framework",
                        "OpenGL"
                    )
                )
                .withCompileOptions(
                    c.compileOptions ++ Seq("-I/opt/homebrew/include")
                )
        }
    )

lazy val js = project
    .in(file("js"))
    .enablePlugins(ScalaJSPlugin)
    .dependsOn(core.js)
    .settings(
        name         := "idle-clicker-js",
        scalaVersion := scala3,
        scalaJSUseMainModuleInitializer := true,
        libraryDependencies += "org.scala-js" %%% "scalajs-dom" % "2.8.0"
    )
