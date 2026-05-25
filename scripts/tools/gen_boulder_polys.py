from PIL import Image, ImageDraw
import math
OFF=(128,72); ox,oy=OFF
bg=Image.open('assets/tilesets/purple_fields_bg.png').convert('RGB')
nine=Image.open('/Users/charlie/.claude/image-cache/15bc98a7-b342-472d-8601-e233fc1b4728/9.png').convert('RGB').resize((1536,864))
out=bg.copy(); pxo=out.load(); n=nine.load()
for y in range(864):
    for x in range(1536):
        r,g,b=n[x,y]
        if r>150 and g<95 and b<95: pxo[x,y]=(255,0,0)
d=ImageDraw.Draw(out)
CX,CY,RX,RY=640,420,616,218
pts=[(CX+RX*math.cos(k/120*2*math.pi)+ox,CY+RY*math.sin(k/120*2*math.pi)+oy) for k in range(120)]
d.line(pts+[pts[0]],fill=(0,255,0),width=2)
P={'TL':[(298,235),(325,192),(372,172),(415,185),(446,225),(433,260),(378,273),(323,262)],
'TR':[(822,238),(845,196),(888,170),(932,184),(960,228),(946,263),(890,275),(844,262)],
'ML':[(178,420),(200,372),(255,345),(318,365),(343,412),(325,448),(258,462),(190,450)],
'MR':[(935,415),(958,368),(1012,343),(1072,362),(1098,408),(1082,442),(1015,455),(948,442)],
'BC':[(538,548),(560,495),(632,450),(695,470),(733,520),(720,572),(635,592),(558,580)]}
for k,p in P.items():
    q=[(x+ox,y+oy) for x,y in p]; d.line(q+[q[0]],fill=(0,255,0),width=2)
out.resize((1340,754)).save('/tmp/finalcheck.png'); print('ok')
