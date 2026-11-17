import math, json, sys
from PIL import Image, ImageDraw

TORSO, UA, FA, TH, SH = 26.0, 15.0, 14.0, 22.0, 22.0
HEAD_R, NECK = 5.8, 8.5
FLOOR = 92.0

def v(a, l): r = math.radians(a); return (l*math.cos(r), l*math.sin(r))
def add(p, q): return (p[0]+q[0], p[1]+q[1])
def sub(p, q): return (p[0]-q[0], p[1]-q[1])
def dist(p, q): return math.hypot(p[0]-q[0], p[1]-q[1])
def ang(p, q): return math.degrees(math.atan2(q[1]-p[1], q[0]-p[0]))

def ik(root, target, a, b, s):
    dx, dy = target[0]-root[0], target[1]-root[1]
    d = math.hypot(dx, dy) or 0.001
    ux, uy = dx/d, dy/d
    dc = min(max(d, abs(a-b)+0.01), a+b-0.01)
    cosA = (a*a + dc*dc - b*b) / (2*a*dc)
    A = math.acos(max(-1, min(1, cosA))) * s
    jx = root[0] + a*(ux*math.cos(A) - uy*math.sin(A))
    jy = root[1] + a*(ux*math.sin(A) + uy*math.cos(A))
    ex, ey = target[0]-jx, target[1]-jy
    e = math.hypot(ex, ey) or 0.001
    return (jx, jy), (jx + b*ex/e, jy + b*ey/e)

# ---- helpers to build poses -------------------------------------------------
def straight(foot, shoulder):
    """Hip on the straight line foot->shoulder, leg length from the foot."""
    d = dist(foot, shoulder); u = ((shoulder[0]-foot[0])/d, (shoulder[1]-foot[1])/d)
    hip = (foot[0]+u[0]*(TH+SH), foot[1]+u[1]*(TH+SH))
    return hip, ang(hip, shoulder)

def plank_from_foot(foot, angle_deg):
    """Body straight from the foot at angle (screen degrees, from foot to head)."""
    sh = add(foot, v(angle_deg, TH+SH+TORSO))
    hip, t = straight(foot, sh)
    return hip, t, sh

def P(hip, torso, hand, foot, hand2=None, foot2=None, head=0):
    r = lambda p: [round(p[0], 1), round(p[1], 1)]
    return dict(hip=r(hip), torso=round(torso, 1), head=head, hand=r(hand), hand2=r(hand2 or hand),
                foot=r(foot), foot2=r(foot2 or foot))

E = {}
ARM = UA + FA
LEG = TH + SH

def circle_meet(c1, r1, c2, r2, upper=True):
    d = dist(c1, c2); x = (r1*r1 - r2*r2 + d*d) / (2*d); h = math.sqrt(max(0, r1*r1 - x*x))
    ux, uy = (c2[0]-c1[0])/d, (c2[1]-c1[1])/d
    px, py = c1[0] + ux*x, c1[1] + uy*x
    a1 = (px - uy*h, py + ux*h); a2 = (px + uy*h, py - ux*h)
    return min(a1, a2, key=lambda p: p[1]) if upper else max(a1, a2, key=lambda p: p[1])

def pushup_frames(foot, hand, depth=11):
    body = LEG + TORSO
    su = circle_meet(foot, body, hand, ARM - 0.6)                 # arms straight
    sd = circle_meet(foot, body, (hand[0] + 3, hand[1] - depth), 0.01)  # chest low
    sd = add(foot, v(ang(foot, (hand[0] + 3, hand[1] - depth)), body))
    hu, tu = straight(foot, su); hd, td = straight(foot, sd)
    return [P(hu, tu, hand, foot), P(hd, td, hand, foot)]

E['incline_pushup'] = dict(props=[dict(kind='box', r=[70, 64, 86, FLOOR])], arm=1, leg=-1,
    frames=pushup_frames((14, FLOOR), (76, 64)))
E['pushup'] = dict(props=[], arm=1, leg=-1, frames=pushup_frames((8, FLOOR), (70, FLOOR)))
E['elevated_pushup'] = dict(props=[dict(kind='box', r=[0, 70, 22, FLOOR])], arm=1, leg=-1,
    frames=pushup_frames((12, 70), (76, FLOOR)))

def pike(hand, foot, hip_down, torso_down):
    D = dist(hand, foot); a, b = LEG, TORSO + ARM
    x = (a*a - b*b + D*D) / (2*D)
    hip = (foot[0] + x, foot[1] - math.sqrt(a*a - x*x))
    return [P(hip, ang(hip, hand), hand, foot), P(hip_down, torso_down, hand, foot)]
E['pike_pushup'] = dict(props=[], arm=-1, leg=-1, frames=pike((72, FLOOR), (24, FLOOR), (41, 53), 60))

# Dips: hands on the pillars beside the hips, lean forward a little.
pillar = dict(kind='box', r=[52, 62, 68, FLOOR])
def dip(sh, lean, foot):
    hip = sub(sh, v(lean, TORSO))
    return hip
hand = (60, 62)
sh0 = (59, 62 - ARM + 0.6); hip0 = dip(sh0, -76, None)
sh1 = (61, 48); hip1 = dip(sh1, -66, None)
E['pillar_dip'] = dict(props=[pillar], arm=1, leg=-1, frames=[
    P(hip0, -76, hand, (34, 76), foot2=(36, 77)),
    P(hip1, -66, hand, (32, 86), foot2=(34, 87))])
E['support_hold'] = dict(props=[pillar], arm=1, leg=-1, frames=[
    P(hip0, -76, hand, (34, 76), foot2=(36, 77)),
    P(add(hip0, (0, 0.8)), -75, hand, (34, 77), foot2=(36, 78))])

# Towel rows: towel round a post, feet at its base, lean back, pull chest to hands.
post = dict(kind='box', r=[84, 46, 98, FLOOR])
anchor = (85, 62)
foot = (74, FLOOR)
h0, t0, s0 = plank_from_foot(foot, -128)
hand0 = add(s0, v(ang(s0, anchor), ARM - 0.4))
h1, t1, s1 = plank_from_foot(foot, -108)
hand1 = add(s1, v(ang(s1, anchor) - 5, 11))
E['towel_row'] = dict(props=[post, dict(kind='towel', a=list(anchor))], arm=1, leg=-1,
    frames=[P(h0, t0, hand0, foot), P(h1, t1, hand1, foot)])

# Towel curls: upper arms stay still, hands come up to the forehead.
h0, t0, s0 = plank_from_foot(foot, -126)
hand0 = add(s0, v(ang(s0, anchor), ARM - 0.4))
h1, t1, s1 = plank_from_foot(foot, -114)
hand1 = add(s1, v(t1 + 35, 9))
E['towel_curl'] = dict(props=[post, dict(kind='towel', a=list(anchor))], arm=1, leg=-1,
    frames=[P(h0, t0, hand0, foot), P(h1, t1, hand1, foot)])

# Table rows: lie under the table, grip its edge, pull chest up to it.
table = dict(kind='table', r=[14, 56, 64, 60])
heel = (4, FLOOR); grip = (63, 60)
best = min(range(-30, -2), key=lambda a: abs(dist(plank_from_foot(heel, a)[2], grip) - (ARM - 0.6)))
h0, t0, s0 = plank_from_foot(heel, best)
h1, t1, s1 = plank_from_foot(heel, ang(heel, (58, 68)))
E['table_row'] = dict(props=[table], arm=1, leg=-1, frames=[P(h0, t0, grip, heel), P(h1, t1, grip, heel)])

# Squat: arms straight out in front for balance.
def arms_forward(hip, torso, drop=0):
    sh = add(hip, v(torso, TORSO)); return add(sh, (ARM - 0.5, drop))
E['squat'] = dict(props=[], arm=-1, leg=-1, frames=[
    P((50, FLOOR - LEG + 0.6), -90, arms_forward((50, FLOOR - LEG + 0.6), -90, 4), (52, FLOOR)),
    P((36, 72), -52, arms_forward((36, 72), -52), (54, FLOOR))])

hang = lambda hip, t: add(add(hip, v(t, TORSO)), (2, ARM - 0.5))
top = (50, FLOOR - LEG + 0.6)
E['reverse_lunge'] = dict(props=[], arm=1, leg=-1, frames=[
    P(top, -90, hang(top, -90), (52, FLOOR), foot2=(49, FLOOR)),
    P((44, 69), -88, hang((44, 69), -88), (64, FLOOR), foot2=(20, FLOOR))])
E['bulgarian_split_squat'] = dict(props=[dict(kind='box', r=[2, 70, 22, FLOOR])], arm=1, leg=-1, frames=[
    P((55, 50), -88, hang((55, 50), -88), (64, FLOOR), foot2=(13, 70)),
    P((46, 69), -80, hang((46, 69), -80), (64, FLOOR), foot2=(13, 70))])

foot = (6, FLOOR)
hp, tp, sp = plank_from_foot(foot, ang(foot, (72, FLOOR - UA)))
E['plank'] = dict(props=[], arm=1, leg=-1, frames=[
    P(hp, tp, (86, FLOOR), foot), P(add(hp, (0, -1.0)), tp - 0.7, (86, FLOOR), foot)])

E['leg_raise'] = dict(props=[], arm=-1, leg=1, frames=[
    P((52, 88), 180, (58, 90), (96, 88)),
    P((52, 88), 180, (58, 90), (86, 60)),
    P((52, 88), 180, (58, 90), (57, 44))])

# ---- render ----------------------------------------------------------------
def joints(f, arm, leg):
    hip = tuple(f['hip']); sh = add(hip, v(f['torso'], TORSO))
    head = add(sh, v(f['torso'] + f['head'], NECK))
    e1, h1 = ik(sh, f['hand'], UA, FA, arm); e2, h2 = ik(sh, f['hand2'], UA, FA, arm)
    k1, f1 = ik(hip, f['foot'], TH, SH, leg); k2, f2 = ik(hip, f['foot2'], TH, SH, leg)
    return dict(hip=hip, sh=sh, head=head, e1=e1, h1=h1, e2=e2, h2=h2, k1=k1, f1=f1, k2=k2, f2=f2)

def draw(d, ex, f, ox, oy, s):
    T = lambda p: (ox + p[0]*s, oy + p[1]*s)
    d.line([T((-2, FLOOR)), T((102, FLOOR))], fill=(150, 150, 150), width=2)
    for pr in ex['props']:
        if pr['kind'] in ('box',):
            r = pr['r']; d.rectangle([T((r[0], r[1])), T((r[2], r[3]))], fill=(200, 190, 175))
        if pr['kind'] == 'table':
            r = pr['r']; d.rectangle([T((r[0], r[1])), T((r[2], r[3]))], fill=(200, 190, 175))
            d.rectangle([T((r[0]+2, r[3])), T((r[0]+5, FLOOR))], fill=(200, 190, 175))
            d.rectangle([T((r[2]-5, r[3])), T((r[2]-2, FLOOR))], fill=(200, 190, 175))
    j = joints(f, ex['arm'], ex['leg'])
    w = int(8*s)
    far = (120, 140, 200); near = (40, 60, 160)
    for pr in ex['props']:
        if pr['kind'] == 'towel':
            d.line([T(j['h1']), T(tuple(pr['a']))], fill=(220, 120, 40), width=int(2*s))
    def seg(a, b, c, ww=None):
        ww = ww or w; d.line([T(a), T(b)], fill=c, width=ww)
        for p in (a, b):
            x, y = T(p); r = ww/2; d.ellipse([x-r, y-r, x+r, y+r], fill=c)
    for a, b in [('hip','k2'),('k2','f2'),('sh','e2'),('e2','h2')]: seg(j[a], j[b], far)
    seg(j['hip'], j['sh'], near, int(11*s))
    for a, b in [('hip','k1'),('k1','f1')]: seg(j[a], j[b], (255,255,255), w + int(2.4*s))
    for a, b in [('hip','k1'),('k1','f1')]: seg(j[a], j[b], near)
    for a, b in [('sh','e1'),('e1','h1')]: seg(j[a], j[b], (255,255,255), w + int(2.4*s))
    for a, b in [('sh','e1'),('e1','h1')]: seg(j[a], j[b], near)
    hx, hy = T(j['head']); r = HEAD_R*s
    d.ellipse([hx-r, hy-r, hx+r, hy+r], fill=near)

if __name__ == '__main__':
    names = list(E)
    s = 2.0; cw = 220
    img = Image.new('RGB', (cw*2+20, len(names)*(cw//1)+10), 'white')
    d = ImageDraw.Draw(img)
    for i, n in enumerate(names):
        ex = E[n]
        fr = ex['frames']
        for k, f in enumerate([fr[0], fr[-1]]):
            draw(d, ex, f, 10 + k*cw, 10 + i*cw, s)
        d.text((10, 10 + i*cw), n, fill='black')
    img.save(sys.argv[1] if len(sys.argv) > 1 else 'sheet.png')
    json.dump(E, open('poses.json', 'w'))
