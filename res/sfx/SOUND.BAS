'' This is the QBASIC source code which generates the authentic old-timey
'' sounds for Temple of Anput.  The sounds were recorded by running QBASIC
'' under DOSBox and using DOSBox's audio-recording feature.

PLAY "mb t130 l40"

SELECT CASE 25 '' Change this number to hear different sounds
CASE 1
    '' theme
    PLAY "l10 o3  cde-b >c <b a- g c."

CASE 2
    '' player cry
    PLAY "l40 o1  bb-a"

CASE 3
    '' player die
    PLAY "o1  baa-a-geeedd-c+ccccc"

CASE 4
    '' player get item
    PLAY "o2  g >c"

CASE 5
    '' player get HP
    PLAY "o3  ceg"

CASE 6
    '' player get magic
    PLAY "o3  cgg+"

CASE 7
    '' player drop item
    PLAY "o2  b g+"

CASE 8
    '' monster cry
    PLAY "o1  d+d"

CASE 9
    '' monster die
    PLAY "o1  gfdccc <bff"

CASE 10
    ''monster get item
    PLAY "o1  g >c"

CASE 11
    '' monster get HP
    PLAY "o2  ceg"

CASE 12
    '' monster get magic
    PLAY "o2  cgg+"

CASE 13
    '' monster drop item
    PLAY "o1  b g+"

CASE 14
    '' no ammo
    PLAY "o0  b"

CASE 15
    '' scary enemy
    PLAY "o2  bb-bb-bb-bb- dd-dd-dd-dd-"

CASE 16
    '' pause
    PLAY "o2  gg+"

CASE 17
    '' menu select
    PLAY "o2  b"

CASE 18
    '' secret find
    PLAY "l10 o3  cfecd-."

CASE 19
    '' trap
    PLAY "l25 o2  g >c <b g+"

CASE 20
    '' get special item
    PLAY "l10 o3  cc+ g+g >c."

CASE 21
    '' shoot arrow
    PLAY "l64 o4  bb-"

CASE 22
    '' hit wall
    PLAY "o1  e-<c"

CASE 23
    '' Camel run around!
    'PLAY "o2 fff bbb fff bbb"
    'PLAY "o2 f+f+f+ ccc f+f+f+ ccc"
    PLAY "o2 ccc f+f+f+ ccc f+f+f+"
    'PLAY "o2 ff cc bbb"
CASE 24
    '' Catch camel
    PLAY "o2 ggg > ccc < ccc"
CASE 25
    '' Camel gulp
    PLAY "t255 mb l64 ml"
    PLAY "o1 p1 d d+ e f f+ g+ a a+ b > c c+ d d+"
END SELECT

