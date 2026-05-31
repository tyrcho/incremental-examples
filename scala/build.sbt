import scala.scalanative.build.*

enablePlugins(ScalaNativePlugin)

scalaVersion := "3.3.4"
name         := "idle_clicker"

semanticdbEnabled := true
semanticdbVersion := scalafixSemanticdb.revision

nativeConfig ~= { c =>
  c.withLTO(LTO.none)
   .withMode(Mode.releaseFast)
   .withGC(GC.commix)
   .withLinkingOptions(c.linkingOptions ++ Seq(
     "-L/opt/homebrew/lib",
     "-framework", "Cocoa",
     "-framework", "IOKit",
     "-framework", "OpenGL"
   ))
   .withCompileOptions(c.compileOptions ++ Seq("-I/opt/homebrew/include"))
}
