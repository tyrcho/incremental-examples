package game

import scala.scalanative.unsafe.*
import scala.scalanative.unsigned.*

type Color     = CStruct4[UByte, UByte, UByte, UByte]
type Rectangle = CStruct4[CFloat, CFloat, CFloat, CFloat]
type Vector2   = CStruct2[CFloat, CFloat]
type Texture2D = CStruct5[CUnsignedInt, CInt, CInt, CInt, CInt]

@link("raylib")
@extern
object Raylib:
  def InitWindow(width: CInt, height: CInt, title: CString): Unit = extern
  def CloseWindow(): Unit                                          = extern
  def WindowShouldClose(): CBool                                   = extern
  def SetTargetFPS(fps: CInt): Unit                                = extern
  def BeginDrawing(): Unit                                         = extern
  def EndDrawing(): Unit                                           = extern
  def GetFrameTime(): CFloat                                       = extern
  def MeasureText(text: CString, fontSize: CInt): CInt             = extern
  def IsMouseButtonPressed(button: CInt): CBool                    = extern

  // Struct-via-pointer wrappers (glue.c)
  def SN_ClearBackground(color: Ptr[Color]): Unit                                                                       = extern
  def SN_DrawRectangle(x: CInt, y: CInt, w: CInt, h: CInt, color: Ptr[Color]): Unit                                    = extern
  def SN_DrawRectangleLinesEx(rec: Ptr[Rectangle], lineThick: CFloat, color: Ptr[Color]): Unit                          = extern
  def SN_DrawText(text: CString, x: CInt, y: CInt, fontSize: CInt, color: Ptr[Color]): Unit                            = extern
  def SN_GetMousePosition(out: Ptr[Vector2]): Unit                                                                      = extern
  def SN_CheckCollisionPointRec(point: Ptr[Vector2], rec: Ptr[Rectangle]): CBool                                        = extern
  def SN_LoadTexture(fileName: CString, out: Ptr[Texture2D]): Unit                                                      = extern
  def SN_UnloadTexture(texture: Ptr[Texture2D]): Unit                                                                   = extern
  def SN_DrawTexturePro(tex: Ptr[Texture2D], src: Ptr[Rectangle], dst: Ptr[Rectangle],
                        origin: Ptr[Vector2], rot: CFloat, tint: Ptr[Color]): Unit                                      = extern

val MOUSE_LEFT: CInt = 0

// inline so stackalloc lives in the caller's frame
inline def mkColor(r: Int, g: Int, b: Int, a: Int): Ptr[Color] =
  val p = stackalloc[Color]()
  p._1 = r.toUByte; p._2 = g.toUByte; p._3 = b.toUByte; p._4 = a.toUByte
  p

inline def mkRect(x: Float, y: Float, w: Float, h: Float): Ptr[Rectangle] =
  val p = stackalloc[Rectangle]()
  p._1 = x; p._2 = y; p._3 = w; p._4 = h
  p

inline def mkVec2(x: Float, y: Float): Ptr[Vector2] =
  val p = stackalloc[Vector2]()
  p._1 = x; p._2 = y
  p

object Colors:
  inline def RAYWHITE:  Ptr[Color] = mkColor(245, 245, 245, 255)
  inline def BLACK:     Ptr[Color] = mkColor(  0,   0,   0, 255)
  inline def DARKGRAY:  Ptr[Color] = mkColor( 80,  80,  80, 255)
  inline def LIGHTGRAY: Ptr[Color] = mkColor(200, 200, 200, 255)
  inline def GREEN:     Ptr[Color] = mkColor(  0, 228,  48, 255)
  inline def DARKGREEN: Ptr[Color] = mkColor(  0, 117,  44, 255)
  inline def SKYBLUE:   Ptr[Color] = mkColor(102, 191, 255, 255)
  inline def RED:       Ptr[Color] = mkColor(230,  41,  55, 255)
  inline def WHITE:     Ptr[Color] = mkColor(255, 255, 255, 255)
