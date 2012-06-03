'' This is the QBASIC source code which generates the authentic old-timey
'' sounds for Temple of Anput.  The sounds were recorded by running QBASIC
'' under DOSBox and using DOSBox's audio-recording feature.

PLAY "mb t130 l40"

SELECT CASE 18 '' Change this number to hear different sounds
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
    '' player get HP
    PLAY "o3  ceg"

CASE 5
    '' player get item
    PLAY "o2  g >c"

CASE 6
    '' player drop item
    PLAY "o2  b g+"

CASE 7
    '' monster cry
    PLAY "o1  d+d"

CASE 8
    '' monster die
    PLAY "o1  gfdccc <bff"

CASE 9
    '' monster get HP
    PLAY "o2  ceg"

CASE 10
    ''monster get item
    PLAY "o1  g >c"

CASE 11
    '' no ammo
    PLAY "o0  b"

CASE 12
    '' scary
    PLAY "o2  bb-bb-bb-bb- dd-dd-dd-dd-"

CASE 13
    '' pause
    PLAY "o2  gg+"

CASE 15
    '' menu select
    PLAY "o2  b"

CASE 16
    '' secret find
    PLAY "l10 o3  cfecd-."

CASE 17
    '' trap
    PLAY "l25 o2  g >c <b g+"

CASE 18
    '' get special item
    PLAY "l10 o3  cc+ g+g >c."

CASE 19
    '' shoot arrow
    PLAY "l64 o4  bb-"

CASE 20
    '' hit wall
    PLAY "o1  e-<c"
END SELECT

