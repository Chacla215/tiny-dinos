from PIL import Image, ImageDraw
SRC='/Users/charlie/.claude/image-cache/15bc98a7-b342-472d-8601-e233fc1b4728/6.png'
img=Image.open(SRC).convert('RGB'); W,H=img.size
data=list(img.getdata())
def isred(r,g,b): return r>155 and g<95 and b<95
redset=set()
for i,(r,g,b) in enumerate(data):
    if isred(r,g,b): redset.add((i%W,i//W))
print('red px:',len(redset))
# connected components (8-conn) over red pixels
seen=set(); comps=[]
for p in redset:
    if p in seen: continue
    stack=[p]; seen.add(p); comp=[]
    while stack:
        cx,cy=stack.pop(); comp.append((cx,cy))
        for dx in(-1,0,1):
            for dy in(-1,0,1):
                q=(cx+dx,cy+dy)
                if q in redset and q not in seen:
                    seen.add(q); stack.append(q)
    if len(comp)>120: comps.append(comp)
comps.sort(key=len,reverse=True)
print('components(>120px):',[len(c) for c in comps])
oval=comps[0]
ominx=min(x for x,y in oval); omaxx=max(x for x,y in oval)
ominy=min(y for x,y in oval); omaxy=max(y for x,y in oval)
print('oval bbox px:',ominx,omaxx,ominy,omaxy)
# calibrate: oval extremes -> world boundary (RX585,RY230 about center 640,435)
def tow(px,py):
    wx=55+(px-ominx)*(1225-55)/(omaxx-ominx)
    wy=205+(py-ominy)*(665-205)/(omaxy-ominy)
    return (round(wx),round(wy))
def hull(points):
    pts=sorted(set(points))
    if len(pts)<3: return pts
    def cr(o,a,b): return (a[0]-o[0])*(b[1]-o[1])-(a[1]-o[1])*(b[0]-o[0])
    lo=[]
    for p in pts:
        while len(lo)>=2 and cr(lo[-2],lo[-1],p)<=0: lo.pop()
        lo.append(p)
    up=[]
    for p in reversed(pts):
        while len(up)>=2 and cr(up[-2],up[-1],p)<=0: up.pop()
        up.append(p)
    return lo[:-1]+up[:-1]
def simplify(poly,maxn=10):
    if len(poly)<=maxn: return poly
    step=len(poly)/maxn
    return [poly[int(i*step)] for i in range(maxn)]
boulders=[]
for comp in comps[1:]:
    h=hull(comp); h=simplify(h,10)
    wpts=[tow(x,y) for x,y in h]
    cx=sum(p[0] for p in wpts)/len(wpts); cy=sum(p[1] for p in wpts)/len(wpts)
    boulders.append((cy,cx,wpts))
boulders.sort()  # roughly top-to-bottom
print('boulders found:',len(boulders))
for cy,cx,wpts in boulders:
    flat=', '.join(f'{x}, {y}' for x,y in wpts)
    print(f'# centroid (~{round(cx)},{round(cy)})  PackedVector2Array({flat})')
# overlay polygons on current bg to verify
bg=Image.open('assets/tilesets/purple_fields_bg.png').convert('RGBA')
d=ImageDraw.Draw(bg,'RGBA'); OFF=(128,72)
for cy,cx,wpts in boulders:
    pts=[(x+OFF[0],y+OFF[1]) for x,y in wpts]
    d.line(pts+[pts[0]], fill=(255,40,40,255), width=4)
bg.save('/tmp/poly_check.png')
print('wrote /tmp/poly_check.png')
