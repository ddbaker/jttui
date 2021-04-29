/*
 * jtcur.c
 *
 * verison 0.11.0/2002-05-08 20:55 CET
 *
 * license: Ruby's, see documentation included in this package
 * or http://www.ruby-lang.org
 *
 * library for accessing curses from ruby programming language
 * this implementation is tailored to jttui (J.T.'s textmode user interface)
 * it have internal one window clipping
 * new routines added to support acs character sets and colors
 * characters in range 0x00 to 0x1f (usually non printable) are mapped to acs
 * characters (see getacs function for details)
 *
 * curses's Window stuff has been eliminated
 * (IMHO it exist just because C programers don't have power
 *  of ruby to make it (or better) on their own :-))
 *
 * by Jakub Travnik <J.Travnik@sh.cvut.cz> or <jakub.travnik@rocketmail.com>
 *
 * based on curses.c ruby library (from ruby 1.6.4 source distribution
 * in etc/curses/)
 * curses.c was made
 * by MAEDA Shugo (ender@pic-internet.or.jp)
 * modified by Yukihiro Matsumoto (matz@netlab.co.jp)
 */

/* cygwin curses hack, it causes redefinition warning, ignore it */
#define ACS_BLOCK '#'
#define ACS_BOARD '#'
#define ACS_BTEE '+'
#define ACS_BULLET 'o'

#ifdef HAVE_NCURSES_H
# include <ncurses.h>
#else
# ifdef HAVE_NCURSES_CURSES_H
#  include <ncurses/curses.h>
#else
# ifdef HAVE_CURSES_COLR_CURSES_H
#  include <varargs.h>
#  include <curses_colr/curses.h>
# else
#  include <curses.h>
# endif
#endif
#endif

#include "stdio.h"
#include "ruby.h"
#include "ruby/io.h"

#if HAVE_TTYNAME
# include <unistd.h>
#endif

static VALUE mJTCur;


int jtcur_sx, jtcur_sy, jtcur_ex, jtcur_ey; /* clipping coordinates */
int jtcur_x, jtcur_y; /* current coordinates */

/*-------------------------- module JTCur --------------------------*/


#ifdef ACS_BLOCK
#undef ACS_BLOCK
#endif
#ifndef ACS_BLOCK
#define ACS_BLOCK '#'
#endif
#ifdef ACS_BOARD
#undef ACS_BOARD
#endif
#ifndef ACS_BOARD
#define ACS_BOARD '#'
#endif
#ifdef ACS_BTEE
#undef ACS_BTEE
#endif
#ifndef ACS_BTEE
#define ACS_BTEE '+'
#endif
#ifdef ACS_BULLET
#undef ACS_BULLET
#endif
#ifndef ACS_BULLET
#define ACS_BULLET 'o'
#endif
#ifdef ACS_CKBOARD
#undef ACS_CKBOARD
#endif
#ifndef ACS_CKBOARD
#define ACS_CKBOARD ':'
#endif
#ifdef ACS_DARROW
#undef ACS_DARROW
#endif
#ifndef ACS_DARROW
#define ACS_DARROW 'v'
#endif
#ifdef ACS_DEGREE
#undef ACS_DEGREE
#endif
#ifndef ACS_DEGREE
#define ACS_DEGREE '\''
#endif
#ifdef ACS_DIAMOND
#undef ACS_DIAMOND
#endif
#ifndef ACS_DIAMOND
#define ACS_DIAMOND '+'
#endif
#ifdef ACS_GEQUAL
#undef ACS_GEQUAL
#endif
#ifndef ACS_GEQUAL
#define ACS_GEQUAL '>'
#endif
#ifdef ACS_HLINE
#undef ACS_HLINE
#endif
#ifndef ACS_HLINE
#define ACS_HLINE '-'
#endif
#ifdef ACS_LANTERN
#undef ACS_LANTERN
#endif
#ifndef ACS_LANTERN
#define ACS_LANTERN '#'
#endif
#ifdef ACS_LARROW
#undef ACS_LARROW
#endif
#ifndef ACS_LARROW
#define ACS_LARROW '<'
#endif
#ifdef ACS_LEQUAL
#undef ACS_LEQUAL
#endif
#ifndef ACS_LEQUAL
#define ACS_LEQUAL '<'
#endif
#ifdef ACS_LLCORNER
#undef ACS_LLCORNER
#endif
#ifndef ACS_LLCORNER
#define ACS_LLCORNER '+'
#endif
#ifdef ACS_LRCORNER
#undef ACS_LRCORNER
#endif
#ifndef ACS_LRCORNER
#define ACS_LRCORNER '+'
#endif
#ifdef ACS_LTEE
#undef ACS_LTEE
#endif
#ifndef ACS_LTEE
#define ACS_LTEE '+'
#endif
#ifdef ACS_NEQUAL
#undef ACS_NEQUAL
#endif
#ifndef ACS_NEQUAL
#define ACS_NEQUAL '!'
#endif
#ifdef ACS_PI
#undef ACS_PI
#endif
#ifndef ACS_PI
#define ACS_PI '*'
#endif
#ifdef ACS_PLMINUS
#undef ACS_PLMINUS
#endif
#ifndef ACS_PLMINUS
#define ACS_PLMINUS '#'
#endif
#ifdef ACS_PLUS
#undef ACS_PLUS
#endif
#ifndef ACS_PLUS
#define ACS_PLUS '+'
#endif
#ifdef ACS_RARROW
#undef ACS_RARROW
#endif
#ifndef ACS_RARROW
#define ACS_RARROW '>'
#endif
#ifdef ACS_RTEE
#undef ACS_RTEE
#endif
#ifndef ACS_RTEE
#define ACS_RTEE '+'
#endif
#ifdef ACS_S1
#undef ACS_S1
#endif
#ifndef ACS_S1
#define ACS_S1 '-'
#endif
#ifdef ACS_S3
#undef ACS_S3
#endif
#ifndef ACS_S3
#define ACS_S3 '-'
#endif
#ifdef ACS_S7
#undef ACS_S7
#endif
#ifndef ACS_S7
#define ACS_S7 '-'
#endif
#ifdef ACS_S9
#undef ACS_S9
#endif
#ifndef ACS_S9
#define ACS_S9 '_'
#endif
#ifdef ACS_STERLING
#undef ACS_STERLING
#endif
#ifndef ACS_STERLING
#define ACS_STERLING 'f'
#endif
#ifdef ACS_TTEE
#undef ACS_TTEE
#endif
#ifndef ACS_TTEE
#define ACS_TTEE '+'
#endif
#ifdef ACS_UARROW
#undef ACS_UARROW
#endif
#ifndef ACS_UARROW
#define ACS_UARROW '^'
#endif
#ifdef ACS_ULCORNER
#undef ACS_ULCORNER
#endif
#ifndef ACS_ULCORNER
#define ACS_ULCORNER '+'
#endif
#ifdef ACS_URCORNER
#undef ACS_URCORNER
#endif
#ifndef ACS_URCORNER
#define ACS_URCORNER '+'
#endif
#ifdef ACS_VLINE
#undef ACS_VLINE
#endif
#ifndef ACS_VLINE
#define ACS_VLINE '|'
#endif


/* def init_screen */
static VALUE jtcur_init_screen()
{
    initscr();
    if(!stdscr)
	rb_raise(rb_eRuntimeError, "cannot initialize curses");
    clear();
    jtcur_sx=0; jtcur_sy=0;
    jtcur_ex=COLS; jtcur_ey=LINES; /* clipping coordinates */
    jtcur_x=0; jtcur_y=0; /* current coordinates */
    return Qnil;
}

/* def close_screen */
static VALUE jtcur_close_screen()
{
#ifdef HAVE_ISENDWIN
    if (!isendwin())
#endif
	endwin();
    return Qnil;
}

static void
jtcur_finalize()
{
    if (stdscr
#ifdef HAVE_ISENDWIN
	&& !isendwin()
#endif
	)
	endwin();
}

/* def closed? */
static VALUE jtcur_closed()
{
#ifdef HAVE_ISENDWIN
    if (isendwin()) {
	return Qtrue;
    }
    return Qfalse;
#else
    rb_notimplement();
#endif
}

/* def clear */
static VALUE jtcur_clear(obj)
    VALUE obj;
{
    wclear(stdscr);
    jtcur_sx=0; jtcur_sy=0;
    jtcur_ex=COLS; jtcur_ey=LINES; /* clipping coordinates */
    jtcur_x=0; jtcur_y=0; /* current coordinates */

    return Qnil;
}

/* def refresh */
static VALUE jtcur_refresh(obj)
    VALUE obj;
{
    refresh();
    return Qnil;
}

/* def doupdate */
static VALUE jtcur_doupdate(obj)
    VALUE obj;
{
#ifdef HAVE_DOUPDATE
    doupdate();
#else
    refresh();
#endif
    return Qnil;
}

/* def echo */
static VALUE jtcur_echo(obj)
    VALUE obj;
{
    echo();
    return Qnil;
}

/* def noecho */
static VALUE jtcur_noecho(obj)
    VALUE obj;
{
    noecho();
    return Qnil;
}

/* def raw */
static VALUE jtcur_raw(obj)
    VALUE obj;
{
    raw();
    return Qnil;
}

/* def noraw */
static VALUE jtcur_noraw(obj)
    VALUE obj;
{
    noraw();
    return Qnil;
}

/* def cbreak */
static VALUE jtcur_cbreak(obj)
    VALUE obj;
{
    cbreak();
    return Qnil;
}

/* def nocbreak */
static VALUE jtcur_nocbreak(obj)
    VALUE obj;
{
    nocbreak();
    return Qnil;
}

/* def nl */
static VALUE jtcur_nl(obj)
    VALUE obj;
{
    nl();
    return Qnil;
}

/* def nonl */
static VALUE jtcur_nonl(obj)
    VALUE obj;
{
    nonl();
    return Qnil;
}

/* def beep */
static VALUE jtcur_beep(obj)
    VALUE obj;
{
#ifdef HAVE_BEEP
    beep();
#endif
    return Qnil;
}

/* def flash */
static VALUE jtcur_flash(obj)
    VALUE obj;
{
#ifdef HAVE_FLASH
    flash();
#endif
    return Qnil;
}

/* def getx */
static VALUE jtcur_getx  (){return INT2FIX(jtcur_x);}
/* def gety */
static VALUE jtcur_gety  (){return INT2FIX(jtcur_y);}

/* def move(x, y) */
static VALUE jtcur_move(obj, x, y)
    VALUE obj;
    VALUE y;
    VALUE x;
{
    jtcur_x=NUM2INT(x); jtcur_y=NUM2INT(y);
    move(jtcur_y, jtcur_x);
    return Qnil;
}

/* def moverel(x, y) */
static VALUE jtcur_moverel(obj, x, y)
    VALUE obj;
    VALUE y;
    VALUE x;
{
    jtcur_x+=NUM2INT(x); jtcur_y+=NUM2INT(y);
    move(jtcur_y, jtcur_x);
    return Qnil;
}
/* def leaveok(flag) */
static VALUE jtcur_leaveok(obj, flag)
    VALUE obj;
    VALUE flag;
{
    leaveok(stdscr,RTEST(flag));
    return Qnil;
}


static int getacs(c)
    chtype c;
{
    chtype attr=c & ~A_CHARTEXT;
    switch(c & 0x1f & A_CHARTEXT) {
    case 0x00: return ACS_BLOCK   | attr; /*   #   solid square block */
    case 0x01: return ACS_BOARD   | attr; /*   #   board of squares */
    case 0x02: return ACS_BTEE    | attr; /*   +   bottom tee */
    case 0x03: return ACS_BULLET  | attr; /*   o   bullet */
    case 0x04: return ACS_CKBOARD | attr; /*   :   checker board (stipple) */
    case 0x05: return ACS_DARROW  | attr; /*   v   arrow pointing down */
    case 0x06: return ACS_DEGREE  | attr; /*   '   degree symbol */
    case 0x07: return ACS_DIAMOND | attr; /*   +   diamond */
    case 0x08: return ACS_GEQUAL  | attr; /*   >   greater-than-or-equal-to */
    case 0x09: return ACS_HLINE   | attr; /*   -   horizontal line */
    case 0x0a: return ACS_LANTERN | attr; /*   #   lantern symbol */
    case 0x0b: return ACS_LARROW  | attr; /*   <   arrow pointing left */
    case 0x0c: return ACS_LEQUAL  | attr; /*   <   less-than-or-equal-to */
    case 0x0d: return ACS_LLCORNER| attr; /*   +   lower left-hand corner */
    case 0x0e: return ACS_LRCORNER| attr; /*   +   lower right-hand corner */
    case 0x0f: return ACS_LTEE    | attr; /*   +   left tee */
    case 0x10: return ACS_NEQUAL  | attr; /*   !   not-equal */
    case 0x11: return ACS_PI      | attr; /*   *   greek pi */
    case 0x12: return ACS_PLMINUS | attr; /*   #   plus/minus */
    case 0x13: return ACS_PLUS    | attr; /*   +   plus */
    case 0x14: return ACS_RARROW  | attr; /*   >   arrow pointing right */
    case 0x15: return ACS_RTEE    | attr; /*   +   right tee */
    case 0x16: return ACS_S1      | attr; /*   -   scan line 1 */
    case 0x17: return ACS_S3      | attr; /*   -   scan line 3 */
    case 0x18: return ACS_S7      | attr; /*   -   scan line 7 */
    case 0x19: return ACS_S9      | attr; /*   _   scan line 9 */
    case 0x1a: return ACS_STERLING| attr; /*   f   pound-sterling symbol */
    case 0x1b: return ACS_TTEE    | attr; /*   +   top tee */
    case 0x1c: return ACS_UARROW  | attr; /*   ^   arrow pointing up */
    case 0x1d: return ACS_ULCORNER| attr; /*   +   upper left-hand corner */
    case 0x1e: return ACS_URCORNER| attr; /*   +   upper right-hand corner */
    case 0x1f: return ACS_VLINE   | attr; /*   |   vertical line */
    }

    return ACS_PLMINUS | attr; /*   #   plus/minus */
}

/* def addch(ch) */
static VALUE jtcur_addch(obj, ch)
    VALUE obj;
    VALUE ch;
{
    int cc;
    if((jtcur_x<jtcur_ex) && (jtcur_x>=jtcur_sx)
	&& (jtcur_y<jtcur_ey) && (jtcur_y>=jtcur_sy)) {
	cc=NUM2INT(ch);
	cc=(cc & (A_CHARTEXT | A_ALTCHARSET)) >=32 ? cc : getacs(cc);
	addch(cc);
        jtcur_x++;
	}
    else {
        jtcur_x++;
	move(jtcur_y, jtcur_x);
    }
    return Qnil;
}

/* def inch */
static VALUE jtcur_inch  (){return INT2FIX(inch());}

static void _jtcur_addstra(c, len, attrc)
    unsigned char *c; /* unsigned for 8 bit clean */
    int len;
    chtype attrc;
{
    chtype cc;
    if((jtcur_y<jtcur_ey)&&(jtcur_y>=jtcur_sy))
        for(;len>0;len--) {
	    if((jtcur_x<jtcur_ex)&&(jtcur_x>=jtcur_sx)) {
	        cc=(*c & A_CHARTEXT) >=32 ? *c : getacs(*c);
	        addch(cc|attrc);
	        jtcur_x++;
	    }
	    else {
		jtcur_x++;
		move(jtcur_y, jtcur_x);
	    }
	    c++;
	}
    else jtcur_x+=len;
}

/* def addstra(str, attr) */
static VALUE jtcur_addstra(obj, vstr, vattr)
    VALUE obj;
    VALUE vstr;
    VALUE vattr;
{
    if (!NIL_P(vstr))
	_jtcur_addstra(RSTRING_PTR(vstr),RSTRING_LEN(vstr), NUM2INT(vattr));
    return Qnil;
}

/* def addstr(str) */
static VALUE jtcur_addstr(obj, vstr)
    VALUE obj;
    VALUE vstr;
{
    if (!NIL_P(vstr))
	_jtcur_addstra(RSTRING_PTR(vstr),RSTRING_LEN(vstr), 0);
    return Qnil;
}



#define JTMIN(a,b) (((a)<(b))?(a):(b))
#define JTMAX(a,b) (((a)>(b))?(a):(b))

/* def fillrect(sx, sy, ex, ey, c) */
static VALUE jtcur_fillrect(obj, vsx, vsy, vex, vey, vc)
    VALUE obj;
    VALUE vsx;
    VALUE vsy;
    VALUE vex;
    VALUE vey;
    VALUE vc;
{
    int sx,sy,ex,ey,c,i=0,ii=0;
    sx=NUM2INT(vsx);
    sy=NUM2INT(vsy);
    ex=NUM2INT(vex);
    ey=NUM2INT(vey);
    c=NUM2INT(vc);
    c=(c & A_CHARTEXT) >=32 ? c : getacs(c);
    sx=JTMAX(sx, jtcur_sx);
    sy=JTMAX(sy, jtcur_sy);
    ex=JTMIN(ex, jtcur_ex);
    ey=JTMIN(ey, jtcur_ey);
    for(i=sy; i<ey; i++) {
	move(i,sx);
	for(ii=sx; ii<ex; ii++) addch(c);
    }
    move(ey-1,ex);
    jtcur_x=ex; jtcur_y=ey-1;
    return Qnil;
}

/* def setclip( sx, sy, ex, ey) */
static VALUE jtcur_setclip(obj, vsx, vsy, vex, vey)
    VALUE obj;
    VALUE vsx;
    VALUE vsy;
    VALUE vex;
    VALUE vey;
{
    jtcur_sx=NUM2INT(vsx);
    jtcur_sy=NUM2INT(vsy);
    jtcur_ex=NUM2INT(vex);
    jtcur_ey=NUM2INT(vey);

    return Qnil;
}


/* def lines */
static VALUE jtcur_lines()
{
    return INT2FIX(LINES);
}

/* def cols */
static VALUE jtcur_cols()
{
    return INT2FIX(COLS);
}

/* def has_colors? */
static VALUE jtcur_has_colors()
{
    if(has_colors()) return Qtrue; else return Qfalse;
}

/* def start_color */
static VALUE jtcur_start_color()
{
    if(start_color()!=ERR) return Qtrue; else return Qfalse;
}

/* def color_pairs_count */
static VALUE jtcur_color_pairs_count()
{
    return INT2FIX(COLOR_PAIRS);
}

/* def colors_count */
static VALUE jtcur_colors_count()
{
    return INT2FIX(COLORS);
}

/* def color_ */
static VALUE jtcur_color_black  (){return INT2FIX(COLOR_BLACK  );}
static VALUE jtcur_color_red    (){return INT2FIX(COLOR_RED    );}
static VALUE jtcur_color_green  (){return INT2FIX(COLOR_GREEN  );}
static VALUE jtcur_color_yellow (){return INT2FIX(COLOR_YELLOW );}
static VALUE jtcur_color_blue   (){return INT2FIX(COLOR_BLUE   );}
static VALUE jtcur_color_magenta(){return INT2FIX(COLOR_MAGENTA);}
static VALUE jtcur_color_cyan   (){return INT2FIX(COLOR_CYAN   );}
static VALUE jtcur_color_white  (){return INT2FIX(COLOR_WHITE  );}

/* def init_pair( n, fg, bg) */
static VALUE jtcur_init_pair(obj, vn, vfg, vbg)
    VALUE obj;
    VALUE vn;
    VALUE vfg;
    VALUE vbg;
{
    if(init_pair(NUM2INT(vn),NUM2INT(vfg),NUM2INT(vbg))!=ERR) return Qtrue;
	else return Qfalse;
}

/* def color_pair( n ) */
static VALUE jtcur_color_pair(obj, vn)
    VALUE obj;
    VALUE vn;
{
    int n,r;
    n=NUM2INT(vn);
    r=COLOR_PAIR(n);
    return INT2FIX(r);
}

/*
    A_NORMAL        Normal display (no highlight)
    A_STANDOUT      Best highlighting mode of the terminal.
    A_UNDERLINE     Underlining
    A_REVERSE       Reverse video
    A_BLINK         Blinking
    A_DIM           Half bright
    A_BOLD          Extra bright or bold
    A_PROTECT       Protected mode
    A_INVIS         Invisible or blank mode
    A_ALTCHARSET    Alternate character set
*/

static VALUE jtcur_attr_normal    (){return INT2FIX(A_NORMAL    );}
static VALUE jtcur_attr_standout  (){return INT2FIX(A_STANDOUT  );}
static VALUE jtcur_attr_underline (){return INT2FIX(A_UNDERLINE );}
static VALUE jtcur_attr_reverse   (){return INT2FIX(A_REVERSE   );}
static VALUE jtcur_attr_blink     (){return INT2FIX(A_BLINK     );}
static VALUE jtcur_attr_dim       (){return INT2FIX(A_DIM       );}
static VALUE jtcur_attr_bold      (){return INT2FIX(A_BOLD      );}
static VALUE jtcur_attr_protect   (){return INT2FIX(A_PROTECT   );}
static VALUE jtcur_attr_invis     (){return INT2FIX(A_INVIS     );}
static VALUE jtcur_attr_altcharset(){return INT2FIX(A_ALTCHARSET);}
static VALUE jtcur_attr_chartext  (){return INT2FIX(A_CHARTEXT);}


/* def attrset( attr) */
static VALUE jtcur_attrset(obj, vattr)
    VALUE obj;
    VALUE vattr;
{
    attrset(NUM2INT(vattr));
    return Qnil;
}
/* def attroff( attr) */
static VALUE jtcur_attroff(obj, vattr)
    VALUE obj;
    VALUE vattr;
{
    attroff(NUM2INT(vattr));
    return Qnil;
}
/* def attron( attr) */
static VALUE jtcur_attron(obj, vattr)
    VALUE obj;
    VALUE vattr;
{
    attron(NUM2INT(vattr));
    return Qnil;
}

/* from curs_addch(3X) man page
       Name           Default   Description
       --------------------------------------------------
       ACS_BLOCK      #         solid square block
       ACS_BOARD      #         board of squares
       ACS_BTEE       +         bottom tee
       ACS_BULLET     o         bullet
       ACS_CKBOARD    :         checker board (stipple)
       ACS_DARROW     v         arrow pointing down
       ACS_DEGREE     '         degree symbol
       ACS_DIAMOND    +         diamond
       ACS_GEQUAL     >         greater-than-or-equal-to
       ACS_HLINE      -         horizontal line
       ACS_LANTERN    #         lantern symbol
       ACS_LARROW     <         arrow pointing left
       ACS_LEQUAL     <         less-than-or-equal-to
       ACS_LLCORNER   +         lower left-hand corner
       ACS_LRCORNER   +         lower right-hand corner
       ACS_LTEE       +         left tee
       ACS_NEQUAL     !         not-equal
       ACS_PI         *         greek pi
       ACS_PLMINUS    #         plus/minus
       ACS_PLUS       +         plus
       ACS_RARROW     >         arrow pointing right
       ACS_RTEE       +         right tee
       ACS_S1         -         scan line 1
       ACS_S3         -         scan line 3
       ACS_S7         -         scan line 7
       ACS_S9         _         scan line 9
       ACS_STERLING   f         pound-sterling symbol
       ACS_TTEE       +         top tee
       ACS_UARROW     ^         arrow pointing up
       ACS_ULCORNER   +         upper left-hand corner
       ACS_URCORNER   +         upper right-hand corner
       ACS_VLINE      |         vertical line
 */

static VALUE jtcur_acs_block(){return INT2FIX(ACS_BLOCK);}
static VALUE jtcur_acs_board(){return INT2FIX(ACS_BOARD);}
static VALUE jtcur_acs_btee(){return INT2FIX(ACS_BTEE);}
static VALUE jtcur_acs_bullet(){return INT2FIX(ACS_BULLET);}
static VALUE jtcur_acs_ckboard(){return INT2FIX(ACS_CKBOARD);}
static VALUE jtcur_acs_darrow(){return INT2FIX(ACS_DARROW);}
static VALUE jtcur_acs_degree(){return INT2FIX(ACS_DEGREE);}
static VALUE jtcur_acs_diamond(){return INT2FIX(ACS_DIAMOND);}
static VALUE jtcur_acs_gequal(){return INT2FIX(ACS_GEQUAL);}
static VALUE jtcur_acs_hline(){return INT2FIX(ACS_HLINE);}
static VALUE jtcur_acs_lantern(){return INT2FIX(ACS_LANTERN);}
static VALUE jtcur_acs_larrow(){return INT2FIX(ACS_LARROW);}
static VALUE jtcur_acs_lequal(){return INT2FIX(ACS_LEQUAL);}
static VALUE jtcur_acs_llcorner(){return INT2FIX(ACS_LLCORNER);}
static VALUE jtcur_acs_lrcorner(){return INT2FIX(ACS_LRCORNER);}
static VALUE jtcur_acs_ltee(){return INT2FIX(ACS_LTEE);}
static VALUE jtcur_acs_nequal(){return INT2FIX(ACS_NEQUAL);}
static VALUE jtcur_acs_pi(){return INT2FIX(ACS_PI);}
static VALUE jtcur_acs_plminus(){return INT2FIX(ACS_PLMINUS);}
static VALUE jtcur_acs_plus(){return INT2FIX(ACS_PLUS);}
static VALUE jtcur_acs_rarrow(){return INT2FIX(ACS_RARROW);}
static VALUE jtcur_acs_rtee(){return INT2FIX(ACS_RTEE);}
static VALUE jtcur_acs_s1(){return INT2FIX(ACS_S1);}
static VALUE jtcur_acs_s3(){return INT2FIX(ACS_S3);}
static VALUE jtcur_acs_s7(){return INT2FIX(ACS_S7);}
static VALUE jtcur_acs_s9(){return INT2FIX(ACS_S9);}
static VALUE jtcur_acs_sterling(){return INT2FIX(ACS_STERLING);}
static VALUE jtcur_acs_ttee(){return INT2FIX(ACS_TTEE);}
static VALUE jtcur_acs_uarrow(){return INT2FIX(ACS_UARROW);}
static VALUE jtcur_acs_ulcorner(){return INT2FIX(ACS_ULCORNER);}
static VALUE jtcur_acs_urcorner(){return INT2FIX(ACS_URCORNER);}
static VALUE jtcur_acs_vline(){return INT2FIX(ACS_VLINE);}


/* crop computes intersection between two rectangles */
static VALUE
jtcur_crop(ignored,vax,vbx,vay,vby,vaw,vbw,vah,vbh)
	VALUE ignored;
	VALUE vax;
	VALUE vbx;
	VALUE vay;
	VALUE vby;
	VALUE vaw;
	VALUE vbw;
	VALUE vah;
	VALUE vbh;
{
	int ay,by,ah,bh;
	int ax=FIX2INT(vax),bx=FIX2INT(vbx),
		aw=FIX2INT(vaw),bw=FIX2INT(vbw);
	int newsx,newex,newsy,newey,as,bs;
	newsx=JTMAX(ax, bx);
	as=ax+aw; bs=bx+bw;
	newex=JTMIN(as, bs);
	if(newex < newsx) return Qnil;

	ay=FIX2INT(vay); by=FIX2INT(vby);
	ah=FIX2INT(vah); bh=FIX2INT(vbh);

	newsy=JTMAX(ay, by);
	as=ay+ah; bs=by+bh;
	newey=JTMIN(as, bs);
	if(newey < newsy) return Qnil;
	return rb_ary_new3(4, INT2FIX(newsx), INT2FIX(newsy),
			   INT2FIX((newex-newsx)), INT2FIX((newey-newsy)));
}

/* def ttyname */
static VALUE jtcur_ttyname(ignored, fd)
     VALUE ignored;
     VALUE fd;
{
#ifdef HAVE_TTYNAME
    char *name;
    name=ttyname(FIX2INT(fd));
    if(name)
      return rb_str_new2(name);
    else
      return Qnil;
#else
    return Qnil;
#endif
}

/*------------------------- Initialization -------------------------*/
void Init_jtcur()
{
    mJTCur = rb_define_module("JTCur");
    rb_define_module_function(mJTCur, "init_screen", jtcur_init_screen, 0);
    rb_define_module_function(mJTCur, "close_screen", jtcur_close_screen, 0);
    rb_define_module_function(mJTCur, "closed?", jtcur_closed, 0);
    rb_define_module_function(mJTCur, "clear", jtcur_clear, 0);
    rb_define_module_function(mJTCur, "refresh", jtcur_refresh, 0);
    rb_define_module_function(mJTCur, "doupdate", jtcur_doupdate, 0);
    rb_define_module_function(mJTCur, "echo", jtcur_echo, 0);
    rb_define_module_function(mJTCur, "noecho", jtcur_noecho, 0);
    rb_define_module_function(mJTCur, "raw", jtcur_raw, 0);
    rb_define_module_function(mJTCur, "noraw", jtcur_noraw, 0);
    rb_define_module_function(mJTCur, "cbreak", jtcur_cbreak, 0);
    rb_define_module_function(mJTCur, "nocbreak", jtcur_nocbreak, 0);
    rb_define_alias(mJTCur, "crmode", "cbreak");
    rb_define_alias(mJTCur, "nocrmode", "nocbreak");
    rb_define_module_function(mJTCur, "nl", jtcur_nl, 0);
    rb_define_module_function(mJTCur, "nonl", jtcur_nonl, 0);
    rb_define_module_function(mJTCur, "beep", jtcur_beep, 0);
    rb_define_module_function(mJTCur, "flash", jtcur_flash, 0);
    rb_define_module_function(mJTCur, "getx", jtcur_getx, 0);
    rb_define_module_function(mJTCur, "gety", jtcur_gety, 0);
    rb_define_module_function(mJTCur, "move", jtcur_move, 2);
    rb_define_module_function(mJTCur, "moverel", jtcur_moverel, 2);
    rb_define_module_function(mJTCur, "leaveok", jtcur_leaveok, 1);
    rb_define_module_function(mJTCur, "addch", jtcur_addch, 1);
    rb_define_module_function(mJTCur, "inch", jtcur_inch, 0);
    rb_define_module_function(mJTCur, "addstr", jtcur_addstr, 1);
    rb_define_module_function(mJTCur, "addstra", jtcur_addstra, 2);
    rb_define_module_function(mJTCur, "fillrect", jtcur_fillrect, 5);
    rb_define_module_function(mJTCur, "setclip", jtcur_setclip, 4);
    rb_define_module_function(mJTCur, "lines", jtcur_lines, 0);
    rb_define_module_function(mJTCur, "cols", jtcur_cols, 0);
    rb_define_module_function(mJTCur, "has_colors?", jtcur_has_colors, 0);
    rb_define_module_function(mJTCur, "start_color", jtcur_start_color, 0);
    rb_define_module_function(mJTCur, "color_pairs_count",
					    jtcur_color_pairs_count, 0);
    rb_define_module_function(mJTCur, "colors_count", jtcur_colors_count, 0);

    rb_define_module_function(mJTCur, "color_black", jtcur_color_black, 0);
    rb_define_module_function(mJTCur, "color_red", jtcur_color_red, 0);
    rb_define_module_function(mJTCur, "color_green", jtcur_color_green, 0);
    rb_define_module_function(mJTCur, "color_yellow", jtcur_color_yellow, 0);
    rb_define_module_function(mJTCur, "color_blue", jtcur_color_blue, 0);
    rb_define_module_function(mJTCur, "color_magenta", jtcur_color_magenta, 0);
    rb_define_module_function(mJTCur, "color_cyan", jtcur_color_cyan, 0);
    rb_define_module_function(mJTCur, "color_white", jtcur_color_white, 0);

    rb_define_module_function(mJTCur, "init_pair", jtcur_init_pair, 3);
    rb_define_module_function(mJTCur, "color_pair", jtcur_color_pair, 1);

    rb_define_module_function(mJTCur, "attr_normal", jtcur_attr_normal, 0);
    rb_define_module_function(mJTCur, "attr_standout", jtcur_attr_standout, 0);
    rb_define_module_function(mJTCur, "attr_underline", jtcur_attr_underline, 0);
    rb_define_module_function(mJTCur, "attr_reverse", jtcur_attr_reverse, 0);
    rb_define_module_function(mJTCur, "attr_blink", jtcur_attr_blink, 0);
    rb_define_module_function(mJTCur, "attr_dim", jtcur_attr_dim, 0);
    rb_define_module_function(mJTCur, "attr_bold", jtcur_attr_bold, 0);
    rb_define_module_function(mJTCur, "attr_protect", jtcur_attr_protect, 0);
    rb_define_module_function(mJTCur, "attr_invis", jtcur_attr_invis, 0);
    rb_define_module_function(mJTCur, "attr_altcharset", jtcur_attr_altcharset, 0);
    rb_define_module_function(mJTCur, "attr_chartext", jtcur_attr_chartext, 0);

    rb_define_module_function(mJTCur, "attrset", jtcur_attrset, 1);
    rb_define_module_function(mJTCur, "attroff", jtcur_attroff, 1);
    rb_define_module_function(mJTCur, "attron", jtcur_attron, 1);

    rb_define_module_function(mJTCur, "acs_block", jtcur_acs_block, 0);
    rb_define_module_function(mJTCur, "acs_board", jtcur_acs_board, 0);
    rb_define_module_function(mJTCur, "acs_btee", jtcur_acs_btee, 0);
    rb_define_module_function(mJTCur, "acs_bullet", jtcur_acs_bullet, 0);
    rb_define_module_function(mJTCur, "acs_ckboard", jtcur_acs_ckboard, 0);
    rb_define_module_function(mJTCur, "acs_darrow", jtcur_acs_darrow, 0);
    rb_define_module_function(mJTCur, "acs_degree", jtcur_acs_degree, 0);
    rb_define_module_function(mJTCur, "acs_diamond", jtcur_acs_diamond, 0);
    rb_define_module_function(mJTCur, "acs_gequal", jtcur_acs_gequal, 0);
    rb_define_module_function(mJTCur, "acs_hline", jtcur_acs_hline, 0);
    rb_define_module_function(mJTCur, "acs_lantern", jtcur_acs_lantern, 0);
    rb_define_module_function(mJTCur, "acs_larrow", jtcur_acs_larrow, 0);
    rb_define_module_function(mJTCur, "acs_lequal", jtcur_acs_lequal, 0);
    rb_define_module_function(mJTCur, "acs_llcorner", jtcur_acs_llcorner, 0);
    rb_define_module_function(mJTCur, "acs_lrcorner", jtcur_acs_lrcorner, 0);
    rb_define_module_function(mJTCur, "acs_ltee", jtcur_acs_ltee, 0);
    rb_define_module_function(mJTCur, "acs_nequal", jtcur_acs_nequal, 0);
    rb_define_module_function(mJTCur, "acs_pi", jtcur_acs_pi, 0);
    rb_define_module_function(mJTCur, "acs_plminus", jtcur_acs_plminus, 0);
    rb_define_module_function(mJTCur, "acs_plus", jtcur_acs_plus, 0);
    rb_define_module_function(mJTCur, "acs_rarrow", jtcur_acs_rarrow, 0);
    rb_define_module_function(mJTCur, "acs_rtee", jtcur_acs_rtee, 0);
    rb_define_module_function(mJTCur, "acs_s1", jtcur_acs_s1, 0);
    rb_define_module_function(mJTCur, "acs_s3", jtcur_acs_s3, 0);
    rb_define_module_function(mJTCur, "acs_s7", jtcur_acs_s7, 0);
    rb_define_module_function(mJTCur, "acs_s9", jtcur_acs_s9, 0);
    rb_define_module_function(mJTCur, "acs_sterling", jtcur_acs_sterling, 0);
    rb_define_module_function(mJTCur, "acs_ttee", jtcur_acs_ttee, 0);
    rb_define_module_function(mJTCur, "acs_uarrow", jtcur_acs_uarrow, 0);
    rb_define_module_function(mJTCur, "acs_ulcorner", jtcur_acs_ulcorner, 0);
    rb_define_module_function(mJTCur, "acs_urcorner", jtcur_acs_urcorner, 0);
    rb_define_module_function(mJTCur, "acs_vline", jtcur_acs_vline, 0);

    rb_define_module_function(mJTCur, "crop", jtcur_crop, 8);

    rb_define_module_function(mJTCur, "ttyname", jtcur_ttyname, 1);

    rb_set_end_proc(jtcur_finalize, 0);
}
