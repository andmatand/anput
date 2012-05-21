'' This is the QBASIC source code which generates the authentic old-timey
'' sounds for Temple of Anput.  The sounds were recorded by running QBASIC
'' under DOSBox and using DOSBox's audio-recording feature.

SELECT CASE 13 '' Change this number to hear different sounds
CASE 1
    '' theme
    PLAY "mb t130 l10 o3  cde-b >c <b a- g c."

CASE 2
    '' player cry
    PLAY "mb t130 l40 o1  bb-a"

CASE 3
    '' player die
    PLAY "mb t130 l40 o1  baa-a-geeedd-c+ccccc"

CASE 4
    '' player get HP
    PLAY "mb t130 l40 o3  ceg"

CASE 5
    '' player get item
    PLAY "mb t130 l40 o2  g > c"

CASE 6
    '' player drop item
    PLAY "mb t130 l40 o2  b g+"

CASE 7
    '' monster cry
    PLAY "mb t130 l40 o1  d+d"

CASE 8
    '' monster die
    PLAY "mb t130 l40 o1  gfdccc < bff"

CASE 9
    '' monster get HP
    PLAY "mb t130 l40 o2  ceg"

CASE 10
    ''monster get item
    PLAY "mb t130 l40 o1  g > c"

CASE 11
    '' no ammo
    PLAY "mb t130 l40 o0  b"

CASE 12
    '' scary
    PLAY "mb t130 l40 o2  bb-bb-bb-bb- dd-dd-dd-dd-"

CASE 13
    '' pause
    PLAY "mb t130 l40 o2  gg+"

CASE 15
    '' menu select
    PLAY "mb t130 l40 o2  b"

CASE 16
    '' secret find
    PLAY "mb t130 l10 o3  cfecd-."

CASE 17
    '' trap
    PLAY "mb t130 l25 o2  g >c <b g+"
END SELECT

