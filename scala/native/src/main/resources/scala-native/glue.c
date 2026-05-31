#include "raylib.h"
#include <stdbool.h>

// Scala Native 0.5.x struct-by-value ABI is unreliable on macOS ARM64.
// These wrappers accept/return structs via pointers so Scala only crosses
// the FFI boundary with scalar types and pointers.

void SN_ClearBackground(Color *c) { ClearBackground(*c); }

void SN_DrawRectangle(int x, int y, int w, int h, Color *c) {
    DrawRectangle(x, y, w, h, *c);
}

void SN_DrawRectangleLinesEx(Rectangle *r, float t, Color *c) {
    DrawRectangleLinesEx(*r, t, *c);
}

void SN_DrawText(const char *s, int x, int y, int fs, Color *c) {
    DrawText(s, x, y, fs, *c);
}

void SN_GetMousePosition(Vector2 *out) { *out = GetMousePosition(); }

bool SN_CheckCollisionPointRec(Vector2 *pt, Rectangle *r) {
    return CheckCollisionPointRec(*pt, *r);
}

void SN_LoadTexture(const char *f, Texture2D *out) { *out = LoadTexture(f); }

void SN_UnloadTexture(Texture2D *t) { UnloadTexture(*t); }

void SN_DrawTexturePro(Texture2D *t, Rectangle *src, Rectangle *dst,
                       Vector2 *ori, float rot, Color *tint) {
    DrawTexturePro(*t, *src, *dst, *ori, rot, *tint);
}
