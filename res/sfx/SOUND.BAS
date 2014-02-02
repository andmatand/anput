DECLARE SUB PlaySound (num)

'' This is the QBASIC source code which generates the authentic old-timey
'' sounds for Temple of Anput.  The sounds were recorded by running QBASIC
'' under DOSBox and using DOSBox's audio-recording feature.

PlaySound (39)


'PlaySound (34)
'PlaySound (34)
'PlaySound (35)
'PlaySound (34)
'PlaySound (36)
'PlaySound (35)

'PlaySound (37)
'PlaySound (37)
'PlaySound (38)
'PlaySound (37)
'PlaySound (39)
'PlaySound (38)
'PlaySound (37)
'PlaySound (37)

PLAY "p3"

SUB PlaySound (num)

PLAY "mb t130 l40"

SELECT CASE num
CASE 1
    '' theme
    PLAY "l10 o3  cd-e gg+ b g+g > l5c"
    'PLAY "l10 o3 b g+g f e p10 d- p10 c." 'l40cc+cc+cc+cc+"
    'PLAY "l10 o3 b g+g f e c+ c <b> c."
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
    PLAY "l64 o3  fe"

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
    PLAY "o1 p4 d d+ e f f+ g+ a a+ b > c c+ d d+"
CASE 26
    '' Golem spawn
    'PLAY "l5 o1  ><>e-"
    'PLAY "l30 o1 e-a g->c <a>e- cg- e-a"
    'PLAY "l30 o2 ae- g-c e-<a> c<g- ae-"
    'PLAY "l25 o1 e-a g->c"
    PLAY "l25 o1 efg-"
CASE 27
    '' Door open
    PLAY "l64 ms o0"
    PLAY "e-a p15"
    PLAY "g->c p15"
    PLAY "<a>e- p15"
    PLAY "cf+ p15"
    PLAY "e-a"
CASE 28
    '' Fight to the Death
    PLAY "l20 mn o1 p5 f+d+ fd f+d+ fd"
CASE 29
    '' Khnum's theme
    PLAY "l10 o2 c d- e d- c p10 <b> p10 l40 ff+ ff+ ff+ ff+ ff+ ff+"
CASE 30
    '' Spikes trigger
    PLAY "l64 o4b o3b o2gf o1e-c<fe"
CASE 31
    '' Set's theme
    PLAY "o2 l5 c. l10 c+ l5 e l15 d-e g l40 bb- bb- bb- bb- bb- bb-"
CASE 32
    '' Set teleport
    PLAY "l30 o1 e-a g->c <a>e- cg- e-a"
CASE 33 '' VICTORY THEME
    PLAY "l10 o3  cd-e ga b ag > l5c << l20 cdcdc."
CASE 34 '' funky dance I
    PLAY "t210 ms"
    PLAY "o0 l8 c p8 l4 c l8 >c p8 l4 <c l8 b- p8 ae- p8 e l8 c p8"
CASE 35 '' funky dance IV
    PLAY "t210 ms"
    PLAY "o0 l8 f p8 l4 f l8 >e- p8 <f >e-d <f >dc <f b-a-a"
CASE 36 '' funky dance V
    PLAY "t210 ms"
    PLAY "o0 l8 g p8 l4 g l8 >f p8 l8 e p8 <b-b p8 l4 g l8 dgf+"
CASE 37 '' funky dance I with hits
    PLAY "t210 ms"
    PLAY "o0 l8 c p8 l4 c l8 >c"
    PLAY "o3 l32ce p16"
    PLAY "o0 l8 <c"
    PLAY "o3 l32<b->d p16"
    PLAY "o0 l8 b- p8 ae- p8"
    PLAY "o0 l8 ec"
    PLAY "o3 l32 <b->d p16"
CASE 38 '' funky dance IV with hits
    PLAY "t210 ms"
    PLAY "o0 l8 f p8 l4 f l8 >e-"
    PLAY "o3 l32 fa p16"
    PLAY "o0 l8 <f >e-d"
    PLAY "o3 l32 e-g p16"
    PLAY "o0 l8 >dc"
    PLAY "o3 l32 df p16"
    PLAY "o0 l8 b-a-"
    PLAY "o3 l32 ce- p16"
CASE 39 '' funky dance V with hits
    'PLAY "o0 l8 g p8 l4 g l8 >f p8 l8 e p8 <b-b p8 l4 g l8 dgf+"
    PLAY "t210 ms"
    PLAY "o0 l8 g p8 l4 g l8 >f"
    PLAY "o3 l32 gb p16"
    PLAY "o0 l8 >e"
    PLAY "o3 l32 a>c p16"
    PLAY "o0 l8 b-b"
    PLAY "o3 l32 b>d p16"
    PLAY "o0 l4 g l8 dgf+"
END SELECT

END SUB

