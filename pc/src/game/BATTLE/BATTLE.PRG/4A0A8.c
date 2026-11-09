#include "common.h"
#include "146C.h"
#include "2842C.h"
#include "30DB0.h"
#include "3A1A0.h"
#include "40564.h"
#include "4A0A8.h"
#include "573B8.h"
#include "5BF94.h"
#include "../../SLUS_010.40/main.h"
#include "../../SLUS_010.40/sfx.h"
#include "../../SLUS_010.40/32154.h"
#include "../../GIM/SCREFF2.PRG/0.h"
#include <stdio.h>
#include <memory.h>
#include <stddef.h>
#include <abs.h>

typedef struct {
    u_char mode;
    u_char ease1;
    u_char ease2;
    u_char ease3;
    u_char time;
    u_char duration;
    u_char follow;
    u_char following;
    int value;
    int delta;
    short angle;
    short angleDelta;
    VECTOR start;
    VECTOR position;
    VECTOR velocity;
    VECTOR aux;
    VECTOR followDelta;
    VECTOR followPosition;
    VECTOR previousCamera;
    VECTOR computed;
    VECTOR current;
    VECTOR target;
} D_800F4BA4_t2;

typedef struct {
    char unk0;
    char unk1;
    short unk2;
    short unk4;
    short unk6;
    short unk8;
    short unkA;
} func_800BD57C_t;

typedef struct {
    union {
        u_char u8[2];
        short s16;
    } unk0;
    short unk2;
    short unk4;
    short unk6;
    char unk8;
    char unk9;
    char unkA;
    char unkB;
} func_800BDF6C_t;

typedef struct {
    char unk0;
    char unk1;
    short unk2;
    short unk4;
    short unk6;
    char unk8;
    char unk9;
    char unkA;
    char unkB;
} func_800BDF6C_unk180_t;

typedef struct {
    char unk0;
    char unk1;
    short unk2;
    short unk4;
    short unk6;
    short unk8;
    short unkA;
    short unkC;
    short unkE;
    short unk10;
    short unk12;
    short unk14;
    short unk16;
    short unk18;
    short unk1A;
    short unk1C;
    short unk1E;
} func_800BDBB4_t;

typedef struct {
    D_800F4BA4_t2 lookAt;
    D_800F4BA4_t2 eye;
    func_800BD57C_t unk168;
    func_800BD57C_t unk174;
    func_800BDF6C_unk180_t projectionDistance;
    func_800BDF6C_unk180_t nearClip;
    func_800BDF6C_unk180_t farClip;
    func_800BDF6C_t unk1A4;
    func_800BDF6C_t unk1B0;
    short unk1BC;
    short unk1BE;
    short unk1C0;
    short unk1C2;
    short unk1C4;
    short unk1C6;
    short unk1C8;
    short unk1CA;
    int unk1CC[7];
    u_short unk1E8;
    u_short unk1EA;
    VECTOR unk1EC;
    func_800BDBB4_t unk1FC;
    func_800BDBB4_t unk21C;
    func_800BDBB4_t unk23C;
    func_800BDBB4_t unk25C;
    VECTOR unk27C;
} D_800F4BA4_t;

typedef struct {
    u_int unk0_0 : 1;
    u_int unk0_1 : 1;
    u_int unk0_2 : 1;
    u_int unk0_3 : 3;
    u_int unk0_6 : 18;
    u_int unk0_24 : 8;
    int unk4;
    short unk8;
    short unkA;
    short unkC;
    int unk10[0xFA];
} D_800EB9BC_t;

typedef struct {
    char unk0;
    char unk1;
    char unk2;
    char unk3;
    short unk4;
    short unk6;
    short unk8;
    short unkA;
    short unkC;
    short unkE;
    short unk10;
    short unk12;
} D_800F4B30_t;

typedef struct {
    char unk0;
    char unk1;
    char unk2;
    char unk3;
    short unk4;
    short unk6;
    short unk8;
    short unkA;
    short unkC;
    short unkE;
    short unk10;
    short unk12;
    short unk14;
} D_800F4B88_t;

typedef struct {
    int unk0;
} func_800BDBB4_t2;

typedef struct {
    char unk0;
    char unk1;
    char unk2[22];
} func_800BB68C_t;

typedef struct {
    int x : 12;
    int y : 12;
    u_int alignment : 2;
    u_int flags : 4;
} textOffset;

typedef struct {
    textOffset offset;
    short x;
    short y;
    int distance;
} textPlacement;

typedef struct {
    int value;
    int distance;
    char unk8[8];
    VECTOR v1;
    VECTOR v2;
    VECTOR v3;
    char unk40[16];
    SVECTOR rotation;
    SVECTOR rotation2;
    char unk60[16];
    MATRIX matrix;
} cameraScratch;

typedef struct {
    int distance;
    int steps;
    char unk8[8];
    VECTOR delta;
    VECTOR candidate;
    VECTOR direction;
    char unk40[0x30];
    MATRIX matrix;
} cameraMotionScratch;

typedef struct {
    char unk0[0x50];
    SVECTOR a;
    SVECTOR b;
    SVECTOR c;
} cameraShakeScratch;

typedef struct {
    u_char low;
    u_char high;
} scriptBytePair;

void func_8007DE88(int*);
void func_8007DEA8(P_CODE*);
void func_8007DECC(D_800F1A68_t*);
short func_8008DC7C(int, int);
int func_80090C2C(int);
void func_800A190C(int, int, SVECTOR*, int);
void func_800AACDC(void);
int func_800B6B98(
    SVECTOR* origin, u_char* script, textPlacement* result, u_char direction);
int func_800B9C58(u_char*, short);
void func_800BB68C(u_short, func_800BB68C_t*);
u_short func_800BB788(func_800BB68C_t* arg0);
int func_800BB7C4(int arg0, SVECTOR* arg1);
void func_800BBE10(u_short);
void func_800BBE04(int arg0);
void func_800BBE94(void);
void func_800BCA8C(D_800F4BA4_t2*, D_800F4BA4_t2*);
void func_800BCFB4(D_800F4BA4_t2*);
void func_800BC1CC(short, int);
int func_800BD2B8(MATRIX*);
void func_800BD57C(func_800BD57C_t* arg0);
int func_800BD610(void);
int func_800BDBB4(func_800BDBB4_t* arg0);
void func_800BDF6C(func_800BDF6C_unk180_t* arg0);
void func_800BE180(void);
void func_800BE36C(int, int);
void func_800BE3A0(void);
void func_800BE3D0(char arg0);
void func_800BE5A4(short arg0);
VECTOR* _vectorAdd(VECTOR* arg0, VECTOR* arg1, VECTOR* arg2);
VECTOR* _vectorSubtract(VECTOR* arg0, VECTOR* arg1, VECTOR* arg2);
VECTOR* _setVectorImm(VECTOR*, u_char*);
VECTOR* _vectorFixedPointMult(VECTOR*, VECTOR*, int);
void _vecToRotMatrix(VECTOR*, MATRIX*);
int _atan2FixedPoint(int arg0, int arg1);
static int _fixedPointMult(int a, int b);
void func_800BFD9C();
short vs_battle_getShort(u_char*);
int func_800BFEBC(int, int, int);
int vs_battle_setTextBox(int, char*);
void func_800CB79C(void);
int vs_battle_dismissTextBox(int);
void func_800CEF38(int);
void func_800F9BC0(int, int);
int vs_main_getcurrentMusicSlot(void);
static int _vectorMagnitude(VECTOR*);
static VECTOR* _copyVector(VECTOR* arg0, VECTOR* arg1);
static VECTOR* _sVectorToFixedPointVector(VECTOR* arg0, SVECTOR* arg1);
static void _toNormalIntegerVector(VECTOR*, VECTOR*);

extern int D_800E9B34[];
extern int D_800E9B4C[];
extern char D_800E9B58[];
extern char D_800E9BE0[];
extern char D_800E9BE8[];
extern u_char D_800E9BEC[];
extern u_char D_800E9BF0[];
extern short D_800E9BF4[];
extern short D_800E9BF8[];
extern void D_800E9B5C;
extern short D_800E9C00[];
extern u_char D_800E9C1C[];
extern short D_800E9C24[];
extern u_char D_800E9C28;
extern u_char D_800E9C2C;
extern u_char D_800E9C30[];
extern u_char* D_800EB588[];
extern D_800EB9BC_t* D_800EB9BC;
extern int D_800F19C8;
extern u_short D_800F4B20;
extern u_short D_800F4B28[];
extern D_800F4B30_t D_800F4B30[];
extern char D_800F4B70[];
extern D_800F4B88_t D_800F4B88;
extern char D_800F4B8B;
extern char D_800F4BA0;
extern D_800F4BA4_t* D_800F4BA4;
extern void* _mpdClearedSection;
extern u_short* D_800F4BB0;
extern char D_800F4BB4;
extern short D_800F4BB6;
extern char D_800F4BB8;
extern u_char D_800F4BB9;
extern short* D_800F4BBC;
extern char* D_800F4BC0[];
extern u_short D_800F4BE0;
extern char D_800F4BE4;
extern void* _mpdRoomDoorSection;
extern char D_800F4BF8;
extern char D_800F4C10[];
extern short D_800F4C22;
extern void* D_800F4C24;
extern char D_800F4C34;
extern u_char* D_800F4C38[];
extern short D_800F4C4C;
extern char D_800F4C4E;
extern short _mpdScriptSection;
extern short D_800F4C54;
extern char _textBoxSelectionPending;
extern int D_800F4C64;
extern char D_800F4C69;
extern char D_800F4C6A;

#ifndef ROOD_PC
__asm__(".set push;"
        ".set noreorder;"
        "glabel func_800B63AC;"
        "la         $v0, D_800F4538;"
        "sll        $v1, $a0, 2;"
        "addu       $v0, $v1;"
        "lw         $v0, 0x0($v0);"
        "nop;"
        "lb         $v1, 0xA($v0);"
        "lb         $t1, 0x5B0($v0);"
        "and        $t0, $v1, 0x40;"
        "bnez       $t0, .L800B6424;"
        "and        $t0, $v1, 0x20;"
        "bnez       $t0, .L800B6454;"
        "and        $t1, 0xFC;"
        "or         $t1, 0x1;"
        "sb         $t1, 0x5B0($v0);"
        ".L800B63E8:"
        "addu       $sp, -0x4;"
        "sw         $ra, 0x0($sp);"
        "jal        func_800A208C;"
        "addu       $a0, $v0, $zero;"
        "lw         $ra, 0x0($sp);"
        "addu       $sp, 0x4;"
        "jr         $ra;"
        "endlabel func_800B63AC;"
        ".set pop");

__asm__(".set push;"
        ".set reorder;"
        "glabel func_800B6404;"
        "la         $v0, D_800F4538;"
        "sll        $v1, $a0, 2;"
        "addu       $v0, $v1;"
        "lw         $v0, 0x0($v0);"
        "lb         $v1, 0xA($v0);"
        ".L800B6424:"
        "and        $v1, 0x9F;"
        "or         $v1, 0x40;"
        "sb         $v1, 0xA($v0);"
        ".set nomove;"
        "j          .L800B63E8;"
        "endlabel func_800B6404;"
        ".set pop");

void func_800B6438(int arg0, int* arg1, int arg2, int arg3)
{
    __asm__("la         $v0, D_800F4538;"
            "sll        $v1, $a0, 2;"
            "addu       $v0, $v1;"
            "lw         $v0, 0x0($v0);"
            "nop;"
            "lb         $v1, 0xA($v0);"
            ".L800B6454:"
            "addu       $sp, -0x14;"
            "sw         $v0, 0x0($sp);"
            "sw         $a1, 0x4($sp);"
            "sw         $a2, 0x8($sp);"
            "sw         $a3, 0xC($sp);"
            "sw         $ra, 0x10($sp);"
            "or         $v1, 0x60;"
            "sb         $v1, 0xA($v0);"
            "or         $a1, $zero, 0x1F;"
            "addu       $a2, $zero, $zero;"
            "jal        func_800A0204;"
            "or         $a3, $zero, 0x8;"
            "lw         $a0, 0x0($sp);"
            "lw         $a1, 0x4($sp);"
            "lw         $a2, 0x8($sp);"
            "jal        func_800A208C;"
            "lw         $a3, 0xC($sp);"
            "lw         $ra, 0x10($sp);"
            "addu       $sp, 0x14;");
}

__asm__(".set push;"
        ".set noreorder;"
        "glabel func_800B64A8;"
        "addu       $sp, -0x4;"
        "sw         $ra, 0x0($sp);"
        "jal        func_800B64CC;"
        "addu       $a3, $a1, $zero;"
        "or         $v1, $zero, 0x0;"
        "sb         $v1, 0x1848($v0);"
        "lw         $ra, 0x0($sp);"
        "addu       $sp, 0x4;"
        "j          $ra;"
        "endlabel func_800B64A8;"
        ".set pop");

void func_800B64CC(int arg0, int arg1, int arg2, int arg3)
{
    __asm__("la         $v0, D_800F4538;"
            "sll        $v1, %0, 2;"
            "addu       $v0, $v1;"
            "lw         $v0, 0x0($v0);"
            "or         $v1, $zero, 0x1;"
            "sll        $t0, %3, 16;"
            "or         $t0, %1;"
            "sw         $t0, 0x184C($v0);"
            "sw         %2, 0x1850($v0);"
            ".L800B64F4:"
            "sw         $v1, 0x1848($v0);"
        :
        : "r"(arg0), "r"(arg1), "r"(arg2), "r"(arg3));
}

__asm__("glabel func_800B6500;"
        "la         $v0, D_800F4538;"
        "sll        $v1, $a0, 2;"
        "addu       $v0, $v1;"
        "lw         $v0, 0x0($v0);"
        "lw         $t2, 0x0($a1);"
        "lw         $t3, 0x4($a1);"
        "sw         $t2, 0x1858($v0);"
        "sw         $t3, 0x185C($v0);"
        "lb         $t1, 0xA($v0);"
        "j          .L800B64F4;"
        "or         $v1, $zero, 0x2;"
        "endlabel func_800B6500;");

__asm__("glabel func_800B6530;"
        "ori     $t4, $zero, 0x4;"
        "j       .L800B6540;"
        "addu    $a3, $a2, $zero;"
        "endlabel func_800B6530;");

__asm__(".set push;"
        ".set noreorder;"
        "glabel func_800B653C;"
        "ori        $t4, $zero, 0x3;"
        ".L800B6540:"
        "la         $v0, D_800F4538;"
        "sll        $v1, $a0, 2;"
        "addu       $v0, $v1;"
        "lw         $v0, 0x0($v0);"
        "lw         $t2, 0x0($a1);"
        "lw         $t3, 0x4($a1);"
        "sw         $a2, 0x1850($v0);"
        "lb         $t1, 0xA($v0);"
        "sh         $a3, 0x184E($v0);"
        "sw         $t2, 0x1858($v0);"
        "sw         $t3, 0x185C($v0);"
        "or         $t1, 0x20;"
        "sb         $t1, 0xA($v0);"
        "sw         $t4, 0x1848($v0);"
        "j          $ra;"
        "endlabel func_800B653C;"
        ".set pop;");

__asm__(".set push;"
        ".set noreorder;"
        "glabel func_800B6580;"
        "la         $v0, D_800F4538;"
        "sll        $v1, $a0, 2;"
        "addu       $v0, $v1;"
        "lw         $v0, 0x0($v0);"
        "lw         $t2, 0x0($a1);"
        "lb         $t1, 0xB($v0);"
        "sll        $t0, $a2, 16;"
        "and        $t1, 0xF;"
        "bnez       $t1, .L800B65E4;"
        "or         $t1, 0x1;"
        "lbu        $a0, 0x17FD($v0);"
        "sh         $zero, 0x1A($v0);"
        "sw         $t2, 0x5EC($v0);"
        "sw         $t0, 0x5F0($v0);"
        "sb         $t1, 0xB($v0);"
        "slt        $t3, $a0, 0x2;"
        "bnez       $t3, .L800B65E4;"
        ".nop;"
        "addu       $sp, -0x4;"
        "sw         $ra, 0x0($sp);"
        "jal        func_800B6580;"
        ".nop;"
        "lw         $ra, 0x0($sp);"
        "addu       $sp, 0x4;"
        ".L800B65E4:"
        "jr         $ra;"
        "endlabel func_800B6580;"
        ".set pop;");

__asm__(".set push;"
        ".set noreorder;"
        "glabel func_800B65E8;"
        "ori     $t1,$zero,0x10;"
        "j       .L800B65F8;"
        ".nop;"
        "endlabel func_800B65E8;"
        ".set pop;");

__asm__(".set push;"
        ".set noreorder;"
        "glabel func_800B65F4;"
        "ori        $t1, $zero, 0x40;"
        ".L800B65F8:"
        "la         $v0, D_800F4538;"
        "sll        $v1, $a0, 2;"
        "addu       $v0, $v0, $v1;"
        "lw         $v0, 0x0($v0);"
        "lw         $t2, 0x0($a1);"
        "lw         $t3, 0x4($a1);"
        "lb         $t4, 0xB($v0);"
        "sw         $t2, 0x5EC($v0);"
        "sw         $t3, 0x5F0($v0);"
        "sh         $a2, 0x5F2($v0);"
        "and        $t4, 0x8F;"
        "or         $t1, $t4, $t1;"
        "sb         $t1, 0xB($v0);"
        "j          $ra;"
        "endlabel func_800B65F4;"
        ".set pop;");

void func_800B6634(int arg0, int arg1)
{
    __asm__("la         $v0, D_800F4538;"
            "sll        $v1, $a0, 2;"
            "addu       $v0, $v1;"
            "lw         $v0, 0x0($v0);"
            "addu       $sp, -0xC;"
            "lhu        $t0, 0x63C($v0);"
            "sw         $ra, 0x0($sp);"
            "or         $a2, $zero, 0x80;"
            "sltu       $t0, 0x80;"
            "beqz       $t0, .L800B6668;"
            "sw         $a0, 0x4($sp);"
            "or         $a2, $zero, 0x20;"
            ".L800B6668:"
            "jal        func_800A9EB4;"
            "sw         $a1, 0x8($sp);"
            ".L800B6670:"
            "lw         $a0, 0x4($sp);"
            "jal        func_800A249C;"
            "lw         $a1, 0x8($sp);"
            "lw         $ra, 0x0($sp);"
            "addu       $sp, 0xC;");
}

__asm__(".set push;"
        ".set reorder;"
        "glabel func_800B668C;"
        "addu       $sp, -0xC;"
        "sw         $ra, 0x0($sp);"
        "sw         $a0, 0x4($sp);"
        "sw         $a1, 0x8($sp);"
        "jal        func_800AA8D0;"
        "j          .L800B6670;"
        "endlabel func_800B668C;"
        ".set pop;");

#endif

int vs_battle_invalidOpcode(u_char* arg0, short arg1);

int func_800B66E4(u_char* arg0, short arg1);

int func_800B66F4(u_char* arg0, short arg1);

int func_800B6724(u_char* arg0, short arg1);

int func_800B6744(u_char* arg0, short arg1);

void func_800B6778(u_char* arg0);

int func_800B6868(u_char* arg0, short arg1);

int func_800B68C4(u_char* arg0, short arg1);

int vs_battle_script_initTextBox(u_char* script, short arg1 __attribute__((unused)));

int vs_battle_script_showTextBox(u_char* script, short arg1 __attribute__((unused)));

int vs_battle_script_dismissTextBox(u_char* arg0, short arg1);

textOffset func_800CCE10(int, int, int, int);

int func_800B6B98( SVECTOR* origin, u_char* script, textPlacement* result, u_char direction);

int func_800B6D48(u_char* script, short arg1 __attribute__((unused)));

int func_800B6F8C(u_char* arg0, short arg1);

int vs_battle_script_buttonPressed(u_char* arg0, short arg1);

int vs_battle_script_loadGim(u_char* arg0, short arg1);

int func_800B7014(u_char* arg0, short arg1);

int func_800B70E8(u_char* arg0, short arg1);

int func_800B71C4(u_char* arg0, short arg1);

int func_800B71F4(u_char* arg0, short arg1);

int vs_battle_script_setStringContextInt(u_char* arg0, short arg1);

int func_800B7358(u_char* arg0, short arg1);

int vs_battle_script_selectTextBox(u_char* script, short arg1 __attribute__((unused)));

int func_800B7428(u_char* arg0, short arg1);

int func_800B7490(u_char* arg0, short arg1);

int func_800B7574(u_char* arg0, short arg1);

int func_800B75F4(u_char* arg0, short arg1);

int func_800B76A8(u_char* arg0);

int func_800B770C(u_char* arg0, short arg1);

int func_800B77DC(u_char* arg0, short arg1);

int func_800B784C(u_char* arg0, short arg1);

void func_800A9988(int, SVECTOR*, int, int);

int func_800B792C(u_char* arg0, short arg1);

int func_800B7A98(u_char* arg0, short arg1);

int func_800B7B58(u_char* arg0, short arg1);

int func_800B7C90(u_char* arg0, short arg1);

int func_800B7D10(u_char* arg0, short arg1);

int func_800B7DC4(u_char* arg0, short arg1);

int func_800B7EF0(u_char* arg0, short arg1);

int func_800B7F84(u_char* arg0, short arg1);

int func_800B804C(u_char* arg0, short arg1);

int func_800B80B4(u_char* arg0, short arg1);

int func_800B810C(u_char* arg0);

int func_800B81A0(u_char* arg0, short arg1);

int func_800B822C(u_char* arg0);

int func_800B8290(u_char* arg0, short arg1);

int func_800B8360(u_char* arg0, short arg1);

int func_800B83D4(u_char* arg0);

int func_800B8438(u_char* arg0);

int func_800B849C(u_char* arg0, short arg1);

int func_800B8510(u_char* arg0, short arg1);

int func_800B8590(u_char* arg0, short arg1);

int func_800B860C(u_char* arg0, short arg1);

int func_800B86E8(u_char* arg0, short arg1);

int func_800B8708(u_char* arg0, short arg1);

int func_800B8764(u_char* arg0, short arg1);

int func_800B8788(u_char* arg0, short arg1);

int func_800B884C(u_char* arg0, short arg1);

int vs_battle_script_jumpFwdIfFlag(u_char* arg0, short arg1);

int vs_battle_script_jumpFwdIfFlags(u_char* arg0, short arg1);

int vs_battle_script_jumpFwd(u_char* arg0, short arg1);

int vs_battle_script_jumpFwd2(u_char* arg0, short arg1);

int vs_battle_script_setFlagImmContext(u_char* arg0, short arg1);

int vs_battle_script_jumpFwdIfFlagContext(u_char* arg0, short arg1);

int func_800B8C44(u_char* arg0, short arg1);

int func_800B8C54(u_char* arg0, short arg1);

int vs_battle_script_jumpBackIf(u_char* arg0, short arg1);

int vs_battle_script_jumpFwd3(u_char* arg0, short arg1);

int vs_battle_script_jumpFwd4(u_char* arg0, short arg1);

int vs_battle_script_setFlagImm(u_char* arg0, short arg1);

int vs_battle_script_setFlag(u_char* arg0, short arg1);

int vs_battle_script_setFlagIfItemInInventory(u_char* arg0, short arg1);

int func_800B91C4(u_char* arg0, short arg1);

int func_800B91F0(u_char* arg0, short arg1);

int func_800B9230(u_char* arg0, short arg1);

int vs_battle_script_setFlagIfButton(u_char* arg0, short arg1);

int func_800B92A0(u_char* arg0, short arg1);

int func_800B92D0(u_char* arg0, short arg1);

int func_800B92F4(u_char* script, short arg1);

int func_800B94D8(u_char* arg0, short arg1);

int func_800B9564(u_char* arg0, short arg1);

int func_800B9608(u_char* arg0, short arg1);

int func_800B9670(u_char* arg0, short arg1);

int func_800B96B0(u_char* arg0, short arg1);

int func_800B9724(u_char* arg0, short arg1);

int func_800B9770(u_char* arg0, short arg1);

int func_800B979C(u_char* arg0, short arg1);

int func_800B97E4(u_char* arg0, short arg1);

int func_800B97F8(u_char* arg0, short arg1);

int func_800B9818(u_char* arg0, short arg1);

int func_800B983C(u_char* arg0, short arg1);

int func_800B9860(u_char* arg0, short arg1);

int func_800B988C(u_char* arg0, short arg1);

int func_800B98C0(u_char* arg0, short arg1);

int func_800B9A40(u_char* arg0, short arg1);

int func_800B9A94(u_char* arg0);

int func_800B9AC4(u_char* arg0, short arg1);

int func_800B9AE8(u_char* arg0, short arg1);

int func_800B9B18(u_char* arg0, short arg1);

int func_800B9BF8(void);

int func_800B9C18(u_char* arg0, short arg1);

int func_800B9C58(u_char* arg0, short arg1);

int func_800B9D74(u_char* arg0, short arg1);

int func_800B9DB4(u_char* arg0, short arg1);

int func_800B9F28(u_char* arg0, short arg1);

int func_800B9F4C(u_char* arg0, short arg1);

int func_800B9F70(u_char* arg0, short arg1);

int func_800B9F90(u_char* arg0, short arg1);

int func_800B9FC0(u_char* arg0, short arg1);

int func_800BA0E4(u_char* arg0, short arg1);

int func_800BA108(u_char* arg0, short arg1);

int func_800BA194(u_char* arg0, short arg1);

int func_800BA218(u_char* arg0, short arg1);

int func_800BA264(u_char* arg0, short arg1);

int func_800BA288(u_char* arg0, short arg1);

int func_800BA2B4(u_char* arg0, short arg1);

int func_800BA2E0(u_char* arg0);

int func_800BA35C(u_char* arg0, short arg1);

int func_800BA39C(u_char* arg0, short arg1);

int func_800BA3E4(u_char* arg0, short arg1);

int func_800BA404(u_char* arg0, short arg1);

int vs_battle_script_loadSfxSlot(u_char* arg0, short arg1);

int vs_battle_script_freeSfxSlot(u_char* arg0, short arg1);

int vs_battle_script_freeSfx(u_char* arg0, short arg1);

int vs_battle_script_setCurrentSfx(u_char* arg0, short arg1);

int vs_battle_script_loadSoundFile(u_char* arg0, short arg1);

int func_800BA52C(u_char* arg0);

int vs_battle_script_loadMusicSlot(u_char* arg0, short arg1);

int vs_battle_script_freeMusic(u_char* arg0, short arg1);

int func_800BA5E8(u_char* arg0, short arg1);

int func_800BA61C(u_char* arg0, short arg1);

int func_800BA650(u_char* arg0, short arg1);

int func_800BA684(u_char* arg0, short arg1);

int func_800BA6B8(u_char* arg0, short arg1);

int func_800BA6E0(u_char* arg0, short arg1);

int func_800BA72C(u_char* arg0, short arg1);

int vs_battle_script_clearMusicLoadSlot(u_char* arg0, short arg1);

int vs_battle_script_loadSoundFile2(u_char* arg0, short arg1);

int vs_battle_script_processSoundQueue(u_char* arg0, short arg1);

int func_800BA7BC(u_char* arg0, short arg1);

int func_800BA800(u_char* arg0, short arg1);

int func_800BA848(u_char* arg0, short arg1);

int func_800BA890(u_char* arg0, short arg1);

int func_800BA8BC(u_char* arg0, short arg1);

int func_800BA90C(u_char* arg0, short arg1);

int func_800BA94C(u_char* arg0, short arg1);

int func_800BAA04(u_char* arg0, short arg1);

int func_800BAA34(u_char* arg0, short arg1);

int func_800BAA58(u_char* arg0, short arg1);

int func_800BAACC(u_char* arg0, short arg1);

int func_800BAAF0(u_char* arg0, short arg1);

int func_800BAB14(u_char* arg0);

int func_800BABCC(u_char* arg0, short arg1);

int func_800BAC38(u_char* arg0, short arg1);

int func_800BAC5C(u_char* arg0, short arg1);

int func_800BAD78(u_char* arg0, short arg1);

int func_800BADE0(u_char* arg0);

int func_800BAE74(u_char* arg0, short arg1);

int func_800BAEA0(u_char* arg0, short arg1);

void func_800BAF6C(short arg0);

int vs_battle_script_specialOp(u_char* arg0, short arg1);

int func_800BB288(u_char* arg0, short arg1);

int func_800BB2B8(u_char* arg0, short arg1);

int func_800BB2E4(u_char* arg0, short arg1);

int func_800BB304(u_char* arg0, short arg1);

int func_800BB30C(u_char* arg0, short arg1);

int func_800BB33C(u_char* arg0, short arg1);

int func_800BB35C(u_char* arg0, short arg1);

int func_800BB38C(u_char* arg0, short arg1);

int func_800BB3BC(u_char* arg0, short arg1);

int func_800BB41C(u_char* arg0, short arg1);

int func_800BB450(u_char* arg0, short arg1);

int func_800BB474(u_char* arg0, short arg1);

int func_800BB4CC(u_char* arg0, short arg1);

int func_800BB4F0(u_char* arg0, short arg1);

int func_800BB504(u_char* arg0, short arg1);

int func_800BB554(u_char* arg0, short arg1);

int func_800BB5A4(u_char* arg0, short arg1);

int func_800BB5AC(u_char* arg0, short arg1);

int func_800BB604(u_char* arg0, short arg1);

int vs_battle_script_playMenuSelectSfx(u_char* arg0, short arg1);

void func_800BB68C(u_short arg0, func_800BB68C_t* arg1);

u_short func_800BB788(func_800BB68C_t* arg0);

int func_800BB7C4(int arg0, SVECTOR* arg1);

void func_800BB874(void);

void func_800BB9B0(void);

void func_800BBAFC(void);

extern P_CODE D_800E9C08;
extern D_800F1A68_t D_800E9C0C;

void func_800BBBE8(void);

void func_800BBDDC(void);

void func_800BBE04(int arg0);

void func_800BBE10(u_short arg0);

void func_800BBE94(void);

void vs_battle_applyCameraState(void);

void func_800BC1CC(short arg0, int arg1);

int func_800BC2E8(u_char* script, short unused);

void func_800BC9E0(void);

void func_800BCA8C(D_800F4BA4_t2* c, D_800F4BA4_t2* other);

void func_800BCFB4(D_800F4BA4_t2* c);

int func_800BD2B8(MATRIX* arg0);

int func_800BD444(u_char* arg0, short arg1);

void func_800BD57C(func_800BD57C_t* arg0);

int func_800BD610(void);

int func_800BD6C4(u_char* script, short arg1);

void func_800BDAB4(void);

int func_800BDBB4(func_800BDBB4_t* arg0);

int func_800BDC9C(u_char* script, short arg1);

void func_800BDF6C(func_800BDF6C_unk180_t* arg0);

int func_800BE01C(func_800BDF6C_t* arg0);

void func_800BE180(void);

void func_800BE36C(int arg0, int arg1);

void func_800BE3A0(void);

void func_800BE3D0(char arg0);

void func_800BE53C(D_800F4BA4_t2* arg0);

void func_800BE5A4(short arg0);

VECTOR* _vectorAdd(VECTOR* arg0, VECTOR* arg1, VECTOR* arg2);

VECTOR* _vectorSubtract(VECTOR* arg0, VECTOR* arg1, VECTOR* arg2);

VECTOR* _vectorFixedPointMult(VECTOR* arg0, VECTOR* arg1, int arg2);

static VECTOR* _copyVector(VECTOR* arg0, VECTOR* arg1)
{
    copyVector(arg0, arg1);
    return arg0;
}

static int _vectorMagnitude(VECTOR* arg0)
{
    VECTOR sp10;
    int temp_lo;
    int temp_lo_2;
    int temp_v0;

    _copyVector(&sp10, arg0);
    temp_lo = (sp10.vx >> 0xC) * (sp10.vx >> 0xC);
    temp_lo_2 = (sp10.vy >> 0xC) * (sp10.vy >> 0xC);
    temp_v0 = (sp10.vz >> 0xC) * (sp10.vz >> 0xC);
    sp10.vx = sp10.vx >> 0xC;
    sp10.vy = sp10.vy >> 0xC;
    sp10.vz = sp10.vz >> 0xC;
    return vs_gte_rsqrt(temp_lo + temp_lo_2 + temp_v0) * ONE;
}

VECTOR* _setVectorImm(VECTOR* arg0, u_char* arg1);

static VECTOR* _sVectorToFixedPointVector(VECTOR* arg0, SVECTOR* arg1)
{
    arg0->vx = arg1->vx * ONE;
    arg0->vy = arg1->vy * ONE;
    arg0->vz = arg1->vz * ONE;
    return arg0;
}

static int _fixedPointMult(int a, int b)
{
#ifdef ROOD_PC
    return (int)(((long long)a * b) >> 12);
#else
    int result;
    __asm__("mult       %1, %2;"
            "mflo       $t0;"
            "mfhi       $t1;"
            "srl        $t0, 12;"
            "sll        $t1, 20;"
            "or         %0, $t0, $t1;"
        : "=r"(result)
        : "r"(a), "r"(b));
    return result;
#endif
}

int _atan2FixedPoint(int arg0, int arg1);

void _vecToRotMatrix(VECTOR* arg0, MATRIX* arg1);

static void _toNormalIntegerVector(VECTOR* arg0, VECTOR* arg1)
{
    VECTOR sp10;

    setVector(&sp10, arg0->vx >> 0xC, arg0->vy >> 0xC, arg0->vz >> 0xC);
    VectorNormal(&sp10, arg1);
}

int _loadMpdClearedScriptDoorSections(void* clearedSection, u_short clearedSectionLen, void* scriptSection, u_short scriptSectionLen, void* doorSection, u_short doorSectionLen, int startState);

int func_800BEB00(void);

short func_800BEB10(void);

void func_800BEB34(void);

void func_800BEB9C(int arg0);

void func_800BEBEC(void);

char vs_battle_getStateFlag(short arg0);

void vs_battle_setStateFlag(short id, char value);

int func_800BEC30(void);

extern char D_800F4BA8;
int func_8007C218(int);
int func_800A0024(int, void*);
int func_800A92B8(int, int);
int func_8007CFCC(int);

short func_800BEC58(int arg0, int arg1, int arg2, int arg3);

void func_800BF5F0(u_char* data);

short func_800BFBB8(u_char** arg0, short arg1);

int func_800BF850(void);

/* The event opcode table: native function pointers in the original's order (guest address 0x800E9D30).
 * pc_event_* take the handlers that the original calls with fewer arguments. */
int pc_event_func_800B76A8(u_char* script, short slot);
int pc_event_func_800B810C(u_char* script, short slot);
int pc_event_func_800B822C(u_char* script, short slot);
int pc_event_func_800B83D4(u_char* script, short slot);
int pc_event_func_800B8438(u_char* script, short slot);
int pc_event_func_800B9A94(u_char* script, short slot);
int pc_event_func_800B9BF8(u_char* script, short slot);
int pc_event_func_800BA2E0(u_char* script, short slot);
int pc_event_func_800BA52C(u_char* script, short slot);
int pc_event_func_800BAB14(u_char* script, short slot);
int pc_event_func_800BADE0(u_char* script, short slot);
int vs_battle_invalidOpcode(u_char* script, short slot);
int func_800B66F4(u_char* script, short slot);
int func_800B6724(u_char* script, short slot);
int func_800B6744(u_char* script, short slot);
int func_800B6868(u_char* script, short slot);
int func_800B68C4(u_char* script, short slot);
int vs_battle_script_initTextBox(u_char* script, short slot);
int vs_battle_script_showTextBox(u_char* script, short slot);
int vs_battle_script_dismissTextBox(u_char* script, short slot);
int func_800B6D48(u_char* script, short slot);
int func_800B6F8C(u_char* script, short slot);
int vs_battle_script_buttonPressed(u_char* script, short slot);
int vs_battle_script_loadGim(u_char* script, short slot);
int func_800B7014(u_char* script, short slot);
int func_800B70E8(u_char* script, short slot);
int func_800B71C4(u_char* script, short slot);
int func_800B71F4(u_char* script, short slot);
int vs_battle_script_setStringContextInt(u_char* script, short slot);
int vs_battle_script_selectTextBox(u_char* script, short slot);
int func_800B7358(u_char* script, short slot);
int func_800B7428(u_char* script, short slot);
int func_800B7490(u_char* script, short slot);
int func_800B7574(u_char* script, short slot);
int func_800B75F4(u_char* script, short slot);
int func_800B770C(u_char* script, short slot);
int func_800B77DC(u_char* script, short slot);
int func_800B784C(u_char* script, short slot);
int func_800B792C(u_char* script, short slot);
int func_800B7A98(u_char* script, short slot);
int func_800B7B58(u_char* script, short slot);
int func_800B7C90(u_char* script, short slot);
int func_800B7D10(u_char* script, short slot);
int func_800B7DC4(u_char* script, short slot);
int func_800B7EF0(u_char* script, short slot);
int func_800B7F84(u_char* script, short slot);
int func_800B804C(u_char* script, short slot);
int func_800B80B4(u_char* script, short slot);
int func_800B81A0(u_char* script, short slot);
int func_800B8290(u_char* script, short slot);
int func_800B8360(u_char* script, short slot);
int func_800B849C(u_char* script, short slot);
int func_800B8510(u_char* script, short slot);
int func_800B8590(u_char* script, short slot);
int func_800B860C(u_char* script, short slot);
int func_800B86E8(u_char* script, short slot);
int func_800B8708(u_char* script, short slot);
int func_800B8764(u_char* script, short slot);
int func_800B8788(u_char* script, short slot);
int func_800B884C(u_char* script, short slot);
int vs_battle_script_jumpFwdIfFlag(u_char* script, short slot);
int vs_battle_script_jumpFwdIfFlags(u_char* script, short slot);
int vs_battle_script_jumpFwd(u_char* script, short slot);
int func_800B66E4(u_char* script, short slot);
int vs_battle_script_jumpFwd2(u_char* script, short slot);
int vs_battle_script_setFlagImmContext(u_char* script, short slot);
int vs_battle_script_jumpFwdIfFlagContext(u_char* script, short slot);
int func_800B8C44(u_char* script, short slot);
int func_800B8C54(u_char* script, short slot);
int vs_battle_script_jumpBackIf(u_char* script, short slot);
int vs_battle_script_jumpFwd4(u_char* script, short slot);
int vs_battle_script_jumpFwd3(u_char* script, short slot);
int vs_battle_script_setFlagImm(u_char* script, short slot);
int vs_battle_script_setFlag(u_char* script, short slot);
int vs_battle_script_setFlagIfItemInInventory(u_char* script, short slot);
int func_800B91C4(u_char* script, short slot);
int func_800B91F0(u_char* script, short slot);
int func_800B9230(u_char* script, short slot);
int vs_battle_script_setFlagIfButton(u_char* script, short slot);
int func_800B92A0(u_char* script, short slot);
int func_800B92D0(u_char* script, short slot);
int func_800B92F4(u_char* script, short slot);
int func_800B94D8(u_char* script, short slot);
int func_800B9564(u_char* script, short slot);
int func_800B9608(u_char* script, short slot);
int func_800B9670(u_char* script, short slot);
int func_800B96B0(u_char* script, short slot);
int func_800B9724(u_char* script, short slot);
int func_800B9770(u_char* script, short slot);
int func_800B979C(u_char* script, short slot);
int func_800B97E4(u_char* script, short slot);
int func_800B97F8(u_char* script, short slot);
int func_800B9818(u_char* script, short slot);
int func_800B983C(u_char* script, short slot);
int func_800B9860(u_char* script, short slot);
int func_800B988C(u_char* script, short slot);
int func_800B98C0(u_char* script, short slot);
int func_800B9A40(u_char* script, short slot);
int func_800B9AC4(u_char* script, short slot);
int func_800B9AE8(u_char* script, short slot);
int func_800B9B18(u_char* script, short slot);
int func_800B9C18(u_char* script, short slot);
int func_800B9C58(u_char* script, short slot);
int func_800B9D74(u_char* script, short slot);
int func_800B9DB4(u_char* script, short slot);
int func_800B9F28(u_char* script, short slot);
int func_800B9F4C(u_char* script, short slot);
int func_800B9F70(u_char* script, short slot);
int func_800B9F90(u_char* script, short slot);
int func_800B9FC0(u_char* script, short slot);
int func_800BA0E4(u_char* script, short slot);
int func_800BA194(u_char* script, short slot);
int func_800BA108(u_char* script, short slot);
int func_800BA218(u_char* script, short slot);
int func_800BA264(u_char* script, short slot);
int func_800BA288(u_char* script, short slot);
int func_800BA2B4(u_char* script, short slot);
int func_800BA35C(u_char* script, short slot);
int func_800BA39C(u_char* script, short slot);
int func_800BA3E4(u_char* script, short slot);
int func_800BA404(u_char* script, short slot);
int vs_battle_script_loadSfxSlot(u_char* script, short slot);
int vs_battle_script_freeSfxSlot(u_char* script, short slot);
int vs_battle_script_freeSfx(u_char* script, short slot);
int vs_battle_script_setCurrentSfx(u_char* script, short slot);
int vs_battle_script_loadSoundFile(u_char* script, short slot);
int vs_battle_script_loadMusicSlot(u_char* script, short slot);
int vs_battle_script_freeMusic(u_char* script, short slot);
int func_800BA5E8(u_char* script, short slot);
int func_800BA61C(u_char* script, short slot);
int func_800BA650(u_char* script, short slot);
int func_800BA684(u_char* script, short slot);
int func_800BA6B8(u_char* script, short slot);
int func_800BA6E0(u_char* script, short slot);
int func_800BA72C(u_char* script, short slot);
int vs_battle_script_clearMusicLoadSlot(u_char* script, short slot);
int func_800BA7BC(u_char* script, short slot);
int func_800BA800(u_char* script, short slot);
int func_800BA848(u_char* script, short slot);
int vs_battle_script_loadSoundFile2(u_char* script, short slot);
int vs_battle_script_processSoundQueue(u_char* script, short slot);
int func_800BA890(u_char* script, short slot);
int func_800BA8BC(u_char* script, short slot);
int func_800BA90C(u_char* script, short slot);
int func_800BA94C(u_char* script, short slot);
int func_800BAA04(u_char* script, short slot);
int func_800BAA34(u_char* script, short slot);
int func_800BAA58(u_char* script, short slot);
int func_800BAACC(u_char* script, short slot);
int func_800BAAF0(u_char* script, short slot);
int func_800BABCC(u_char* script, short slot);
int func_800BAC38(u_char* script, short slot);
int func_800BAC5C(u_char* script, short slot);
int func_800BAD78(u_char* script, short slot);
int func_800BAE74(u_char* script, short slot);
int func_800BAEA0(u_char* script, short slot);
int vs_battle_script_specialOp(u_char* script, short slot);
int func_800BB288(u_char* script, short slot);
int func_800BD6C4(u_char* script, short slot);
int func_800BB2B8(u_char* script, short slot);
int func_800BB2E4(u_char* script, short slot);
int func_800BB304(u_char* script, short slot);
int func_800BB30C(u_char* script, short slot);
int func_800BC2E8(u_char* script, short slot);
int func_800BB33C(u_char* script, short slot);
int func_800BB35C(u_char* script, short slot);
int func_800BB41C(u_char* script, short slot);
int func_800BB450(u_char* script, short slot);
int func_800BD444(u_char* script, short slot);
int func_800BB38C(u_char* script, short slot);
int func_800BB3BC(u_char* script, short slot);
int func_800BDC9C(u_char* script, short slot);
int func_800BB474(u_char* script, short slot);
int func_800BB4CC(u_char* script, short slot);
int vs_battle_script_playMenuSelectSfx(u_char* script, short slot);
int func_800BB4F0(u_char* script, short slot);
int func_800BB504(u_char* script, short slot);
int func_800BB554(u_char* script, short slot);
int func_800BB5A4(u_char* script, short slot);
int func_800BB5AC(u_char* script, short slot);
int func_800BB604(u_char* script, short slot);
int (*_opcodeFunctionTable[256])(u_char*, short) = {
    vs_battle_invalidOpcode, /* 0x00 */
    vs_battle_invalidOpcode, /* 0x01 */
    vs_battle_invalidOpcode, /* 0x02 */
    vs_battle_invalidOpcode, /* 0x03 */
    vs_battle_invalidOpcode, /* 0x04 */
    vs_battle_invalidOpcode, /* 0x05 */
    vs_battle_invalidOpcode, /* 0x06 */
    vs_battle_invalidOpcode, /* 0x07 */
    vs_battle_invalidOpcode, /* 0x08 */
    vs_battle_invalidOpcode, /* 0x09 */
    func_800B66F4, /* 0x0a */
    vs_battle_invalidOpcode, /* 0x0b */
    func_800B6724, /* 0x0c */
    func_800B6744, /* 0x0d */
    func_800B6868, /* 0x0e */
    func_800B68C4, /* 0x0f */
    vs_battle_script_initTextBox, /* 0x10 */
    vs_battle_script_showTextBox, /* 0x11 */
    vs_battle_script_dismissTextBox, /* 0x12 */
    func_800B6D48, /* 0x13 */
    func_800B6F8C, /* 0x14 */
    vs_battle_script_buttonPressed, /* 0x15 */
    vs_battle_script_loadGim, /* 0x16 */
    func_800B7014, /* 0x17 */
    func_800B70E8, /* 0x18 */
    func_800B71C4, /* 0x19 */
    func_800B71F4, /* 0x1a */
    vs_battle_script_setStringContextInt, /* 0x1b */
    vs_battle_script_selectTextBox, /* 0x1c */
    func_800B7358, /* 0x1d */
    func_800B7428, /* 0x1e */
    func_800B7490, /* 0x1f */
    func_800B7574, /* 0x20 */
    func_800B75F4, /* 0x21 */
    pc_event_func_800B76A8, /* 0x22 */
    func_800B770C, /* 0x23 */
    func_800B77DC, /* 0x24 */
    func_800B784C, /* 0x25 */
    func_800B792C, /* 0x26 */
    func_800B7A98, /* 0x27 */
    func_800B7B58, /* 0x28 */
    func_800B7C90, /* 0x29 */
    func_800B7D10, /* 0x2a */
    func_800B7DC4, /* 0x2b */
    func_800B7EF0, /* 0x2c */
    func_800B7F84, /* 0x2d */
    func_800B804C, /* 0x2e */
    func_800B80B4, /* 0x2f */
    pc_event_func_800B810C, /* 0x30 */
    func_800B81A0, /* 0x31 */
    pc_event_func_800B822C, /* 0x32 */
    func_800B8290, /* 0x33 */
    func_800B8360, /* 0x34 */
    pc_event_func_800B83D4, /* 0x35 */
    pc_event_func_800B8438, /* 0x36 */
    func_800B849C, /* 0x37 */
    func_800B8510, /* 0x38 */
    func_800B8590, /* 0x39 */
    func_800B860C, /* 0x3a */
    func_800B86E8, /* 0x3b */
    func_800B8708, /* 0x3c */
    func_800B8764, /* 0x3d */
    func_800B8788, /* 0x3e */
    func_800B884C, /* 0x3f */
    vs_battle_script_jumpFwdIfFlag, /* 0x40 */
    vs_battle_script_jumpFwdIfFlags, /* 0x41 */
    vs_battle_script_jumpFwd, /* 0x42 */
    func_800B66E4, /* 0x43 */
    func_800B66E4, /* 0x44 */
    vs_battle_script_jumpFwd2, /* 0x45 */
    vs_battle_script_setFlagImmContext, /* 0x46 */
    vs_battle_script_jumpFwdIfFlagContext, /* 0x47 */
    func_800B8C44, /* 0x48 */
    func_800B8C54, /* 0x49 */
    vs_battle_script_jumpBackIf, /* 0x4a */
    vs_battle_script_jumpFwd4, /* 0x4b */
    vs_battle_script_jumpFwd3, /* 0x4c */
    vs_battle_invalidOpcode, /* 0x4d */
    vs_battle_invalidOpcode, /* 0x4e */
    vs_battle_invalidOpcode, /* 0x4f */
    vs_battle_script_setFlagImm, /* 0x50 */
    vs_battle_script_setFlag, /* 0x51 */
    vs_battle_script_setFlagIfItemInInventory, /* 0x52 */
    func_800B91C4, /* 0x53 */
    func_800B91F0, /* 0x54 */
    func_800B9230, /* 0x55 */
    vs_battle_script_setFlagIfButton, /* 0x56 */
    func_800B92A0, /* 0x57 */
    func_800B92D0, /* 0x58 */
    func_800B92F4, /* 0x59 */
    func_800B94D8, /* 0x5a */
    func_800B9564, /* 0x5b */
    func_800B9608, /* 0x5c */
    func_800B9670, /* 0x5d */
    func_800B96B0, /* 0x5e */
    func_800B9724, /* 0x5f */
    func_800B9770, /* 0x60 */
    func_800B979C, /* 0x61 */
    func_800B97E4, /* 0x62 */
    func_800B97F8, /* 0x63 */
    func_800B9818, /* 0x64 */
    func_800B983C, /* 0x65 */
    func_800B9860, /* 0x66 */
    func_800B988C, /* 0x67 */
    func_800B98C0, /* 0x68 */
    func_800B9A40, /* 0x69 */
    pc_event_func_800B9A94, /* 0x6a */
    func_800B9AC4, /* 0x6b */
    func_800B9AE8, /* 0x6c */
    func_800B9B18, /* 0x6d */
    pc_event_func_800B9BF8, /* 0x6e */
    func_800B9C18, /* 0x6f */
    func_800B9C58, /* 0x70 */
    func_800B9D74, /* 0x71 */
    func_800B9DB4, /* 0x72 */
    func_800B9F28, /* 0x73 */
    func_800B9F4C, /* 0x74 */
    func_800B9F70, /* 0x75 */
    func_800B9F90, /* 0x76 */
    func_800B9FC0, /* 0x77 */
    func_800BA0E4, /* 0x78 */
    func_800BA194, /* 0x79 */
    func_800BA108, /* 0x7a */
    func_800BA218, /* 0x7b */
    func_800BA264, /* 0x7c */
    func_800BA288, /* 0x7d */
    func_800BA2B4, /* 0x7e */
    vs_battle_invalidOpcode, /* 0x7f */
    pc_event_func_800BA2E0, /* 0x80 */
    func_800BA35C, /* 0x81 */
    func_800BA39C, /* 0x82 */
    func_800BA3E4, /* 0x83 */
    func_800BA404, /* 0x84 */
    vs_battle_script_loadSfxSlot, /* 0x85 */
    vs_battle_script_freeSfxSlot, /* 0x86 */
    vs_battle_script_freeSfx, /* 0x87 */
    vs_battle_script_setCurrentSfx, /* 0x88 */
    vs_battle_script_loadSoundFile, /* 0x89 */
    vs_battle_invalidOpcode, /* 0x8a */
    vs_battle_invalidOpcode, /* 0x8b */
    vs_battle_invalidOpcode, /* 0x8c */
    vs_battle_invalidOpcode, /* 0x8d */
    vs_battle_invalidOpcode, /* 0x8e */
    pc_event_func_800BA52C, /* 0x8f */
    vs_battle_script_loadMusicSlot, /* 0x90 */
    vs_battle_script_freeMusic, /* 0x91 */
    func_800BA5E8, /* 0x92 */
    func_800BA61C, /* 0x93 */
    func_800BA650, /* 0x94 */
    func_800BA684, /* 0x95 */
    func_800BA6B8, /* 0x96 */
    func_800BA6E0, /* 0x97 */
    func_800BA72C, /* 0x98 */
    vs_battle_script_clearMusicLoadSlot, /* 0x99 */
    func_800BA7BC, /* 0x9a */
    func_800BA800, /* 0x9b */
    func_800BA848, /* 0x9c */
    vs_battle_script_loadSoundFile2, /* 0x9d */
    vs_battle_script_processSoundQueue, /* 0x9e */
    func_800BA890, /* 0x9f */
    func_800BA8BC, /* 0xa0 */
    func_800BA90C, /* 0xa1 */
    func_800BA94C, /* 0xa2 */
    func_800BAA04, /* 0xa3 */
    func_800BAA34, /* 0xa4 */
    func_800BAA58, /* 0xa5 */
    func_800BAACC, /* 0xa6 */
    vs_battle_invalidOpcode, /* 0xa7 */
    func_800BAAF0, /* 0xa8 */
    pc_event_func_800BAB14, /* 0xa9 */
    func_800BABCC, /* 0xaa */
    vs_battle_invalidOpcode, /* 0xab */
    vs_battle_invalidOpcode, /* 0xac */
    vs_battle_invalidOpcode, /* 0xad */
    vs_battle_invalidOpcode, /* 0xae */
    vs_battle_invalidOpcode, /* 0xaf */
    vs_battle_invalidOpcode, /* 0xb0 */
    func_800BAC38, /* 0xb1 */
    func_800BAC5C, /* 0xb2 */
    func_800BAD78, /* 0xb3 */
    pc_event_func_800BADE0, /* 0xb4 */
    func_800BAE74, /* 0xb5 */
    func_800BAEA0, /* 0xb6 */
    vs_battle_script_specialOp, /* 0xb7 */
    func_800BB288, /* 0xb8 */
    func_800BD6C4, /* 0xb9 */
    func_800BD6C4, /* 0xba */
    func_800BB2B8, /* 0xbb */
    func_800BB2E4, /* 0xbc */
    func_800BB304, /* 0xbd */
    func_800BB30C, /* 0xbe */
    func_800BD6C4, /* 0xbf */
    func_800BC2E8, /* 0xc0 */
    func_800BC2E8, /* 0xc1 */
    func_800BC2E8, /* 0xc2 */
    func_800BC2E8, /* 0xc3 */
    func_800BC2E8, /* 0xc4 */
    func_800BC2E8, /* 0xc5 */
    vs_battle_invalidOpcode, /* 0xc6 */
    func_800BC2E8, /* 0xc7 */
    func_800BC2E8, /* 0xc8 */
    func_800BC2E8, /* 0xc9 */
    func_800BC2E8, /* 0xca */
    func_800BC2E8, /* 0xcb */
    vs_battle_invalidOpcode, /* 0xcc */
    vs_battle_invalidOpcode, /* 0xcd */
    vs_battle_invalidOpcode, /* 0xce */
    vs_battle_invalidOpcode, /* 0xcf */
    func_800BC2E8, /* 0xd0 */
    func_800BC2E8, /* 0xd1 */
    func_800BC2E8, /* 0xd2 */
    func_800BC2E8, /* 0xd3 */
    func_800BC2E8, /* 0xd4 */
    func_800BC2E8, /* 0xd5 */
    vs_battle_invalidOpcode, /* 0xd6 */
    func_800BC2E8, /* 0xd7 */
    func_800BC2E8, /* 0xd8 */
    func_800BC2E8, /* 0xd9 */
    func_800BC2E8, /* 0xda */
    func_800BC2E8, /* 0xdb */
    vs_battle_invalidOpcode, /* 0xdc */
    vs_battle_invalidOpcode, /* 0xdd */
    func_800BB33C, /* 0xde */
    func_800BB35C, /* 0xdf */
    func_800BB41C, /* 0xe0 */
    func_800BB450, /* 0xe1 */
    func_800BD444, /* 0xe2 */
    func_800BD444, /* 0xe3 */
    func_800BD6C4, /* 0xe4 */
    func_800BD6C4, /* 0xe5 */
    func_800BD6C4, /* 0xe6 */
    func_800BD6C4, /* 0xe7 */
    func_800BB38C, /* 0xe8 */
    func_800BB3BC, /* 0xe9 */
    func_800BDC9C, /* 0xea */
    func_800BDC9C, /* 0xeb */
    func_800BDC9C, /* 0xec */
    func_800BD6C4, /* 0xed */
    func_800BDC9C, /* 0xee */
    func_800BDC9C, /* 0xef */
    func_800BB474, /* 0xf0 */
    func_800BB4CC, /* 0xf1 */
    vs_battle_script_playMenuSelectSfx, /* 0xf2 */
    func_800BB4F0, /* 0xf3 */
    func_800BB504, /* 0xf4 */
    func_800BB554, /* 0xf5 */
    func_800BB5A4, /* 0xf6 */
    func_800BB5AC, /* 0xf7 */
    vs_battle_invalidOpcode, /* 0xf8 */
    vs_battle_invalidOpcode, /* 0xf9 */
    vs_battle_invalidOpcode, /* 0xfa */
    vs_battle_invalidOpcode, /* 0xfb */
    vs_battle_invalidOpcode, /* 0xfc */
    vs_battle_invalidOpcode, /* 0xfd */
    func_800BB604, /* 0xfe */
    func_800BB604, /* 0xff */
};
