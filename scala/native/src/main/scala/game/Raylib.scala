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
    def CloseWindow(): Unit                                         = extern
    def WindowShouldClose(): CBool                                  = extern
    def SetTargetFPS(fps: CInt): Unit                               = extern
    def BeginDrawing(): Unit                                        = extern
    def EndDrawing(): Unit                                          = extern
    def GetFrameTime(): CFloat                                      = extern
    def MeasureText(text: CString, fontSize: CInt): CInt            = extern
    def IsMouseButtonPressed(button: CInt): CBool                   = extern

    // Struct-via-pointer wrappers (glue.c)
    def SN_ClearBackground(color: Ptr[Color]): Unit = extern

    def SN_DrawRectangle(
        x: CInt,
        y: CInt,
        w: CInt,
        h: CInt,
        color: Ptr[Color]
    ): Unit = extern

    def SN_DrawRectangleLinesEx(
        rec: Ptr[Rectangle],
        lineThick: CFloat,
        color: Ptr[Color]
    ): Unit = extern

    def SN_DrawText(
        text: CString,
        x: CInt,
        y: CInt,
        fontSize: CInt,
        color: Ptr[Color]
    ): Unit = extern
    def SN_GetMousePosition(out: Ptr[Vector2]): Unit = extern

    def SN_CheckCollisionPointRec(
        point: Ptr[Vector2],
        rec: Ptr[Rectangle]
    ): CBool = extern
    def SN_LoadTexture(fileName: CString, out: Ptr[Texture2D]): Unit = extern
    def SN_UnloadTexture(texture: Ptr[Texture2D]): Unit              = extern

    def SN_DrawTexturePro(
        tex: Ptr[Texture2D],
        src: Ptr[Rectangle],
        dst: Ptr[Rectangle],
        origin: Ptr[Vector2],
        rot: CFloat,
        tint: Ptr[Color]
    ): Unit = extern

val MOUSE_LEFT: CInt = 0

// Named field accessors on native struct pointers
extension (c: Ptr[Color])
    def r: UByte = c._1; def r_=(v: UByte): Unit = c._1 = v
    def g: UByte = c._2; def g_=(v: UByte): Unit = c._2 = v
    def b: UByte = c._3; def b_=(v: UByte): Unit = c._3 = v
    def a: UByte = c._4; def a_=(v: UByte): Unit = c._4 = v

extension (r: Ptr[Rectangle])
    def x: CFloat      = r._1; def x_=(v: CFloat): Unit      = r._1 = v
    def y: CFloat      = r._2; def y_=(v: CFloat): Unit      = r._2 = v
    def width: CFloat  = r._3; def width_=(v: CFloat): Unit  = r._3 = v
    def height: CFloat = r._4; def height_=(v: CFloat): Unit = r._4 = v

// f6: Vector2 named accessors, consistent with Color and Rectangle
extension (v: Ptr[Vector2])
    def vx: CFloat = v._1; def vx_=(f: CFloat): Unit = v._1 = f
    def vy: CFloat = v._2; def vy_=(f: CFloat): Unit = v._2 = f

// inline so stackalloc lives in the caller's frame
inline def mkColor(r: Int, g: Int, b: Int, a: Int): Ptr[Color] =
    val p = stackalloc[Color]()
    p.r = r.toUByte; p.g = g.toUByte; p.b = b.toUByte; p.a = a.toUByte
    p

inline def mkRect(x: Float, y: Float, w: Float, h: Float): Ptr[Rectangle] =
    val p = stackalloc[Rectangle]()
    p.x = x; p.y = y; p.width = w; p.height = h
    p

inline def mkVec2(x: Float, y: Float): Ptr[Vector2] =
    val p = stackalloc[Vector2]()
    p.vx = x; p.vy = y
    p

// f1: derive RGB triplets from the authoritative RgbaColor values in core
object Colors:
    inline def BLACK:     Ptr[Color] = mkColor(RgbaColor.Black.r,     RgbaColor.Black.g,     RgbaColor.Black.b,     255)
    inline def DARKGRAY:  Ptr[Color] = mkColor(RgbaColor.DarkGray.r,  RgbaColor.DarkGray.g,  RgbaColor.DarkGray.b,  255)
    inline def DARKGREEN: Ptr[Color] = mkColor(RgbaColor.DarkGreen.r, RgbaColor.DarkGreen.g, RgbaColor.DarkGreen.b, 255)
    inline def GREEN:     Ptr[Color] = mkColor(RgbaColor.Green.r,     RgbaColor.Green.g,     RgbaColor.Green.b,     255)
    inline def LIGHTGRAY: Ptr[Color] = mkColor(RgbaColor.LightGray.r, RgbaColor.LightGray.g, RgbaColor.LightGray.b, 255)
    inline def RAYWHITE:  Ptr[Color] = mkColor(RgbaColor.RayWhite.r,  RgbaColor.RayWhite.g,  RgbaColor.RayWhite.b,  255)
    inline def RED:       Ptr[Color] = mkColor(RgbaColor.Red.r,       RgbaColor.Red.g,       RgbaColor.Red.b,       255)
    inline def SKYBLUE:   Ptr[Color] = mkColor(RgbaColor.SkyBlue.r,   RgbaColor.SkyBlue.g,   RgbaColor.SkyBlue.b,   255)
    inline def WHITE:     Ptr[Color] = mkColor(RgbaColor.White.r,     RgbaColor.White.g,     RgbaColor.White.b,     255)
