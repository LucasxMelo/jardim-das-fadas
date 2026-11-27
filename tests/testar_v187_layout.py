"""Modelo geométrico independente da v187; não executa GDScript nem Godot."""
from math import ceil
from itertools import product

def clamp(v,a,b): return max(a,min(b,v))

def layout(w,h,n,slots,tutorial,actions):
    width=w-16; gap=5; obj_w=(width-gap)*.58; score_w=width-obj_w-gap
    space=clamp(obj_w*.022,5,8); card=min(188,(obj_w-16-space)/2)
    rows=ceil(slots/2)
    bottom=max(26+rows*card+(rows-1)*space+32,116+32*n)
    instructions=80 if tutorial else 64
    garden=h-16-instructions-81-30-bottom-4*gap
    buy_y=8+instructions+gap+garden+gap
    buy_h=116
    bottom_y=buy_y+buy_h+gap
    available=81+gap if actions else buy_h
    purchase=min(140,available-23,width/3-22)
    card_y=buy_y+(available-purchase-19)/2
    return locals()

count=0
for w,h,n,slots,actions in product([360,420,480],[820,920,1020],range(1,5),[1,3,4],[False,True]):
    tut=slots==1
    if tut and (n!=1 or actions): continue
    g=layout(w,h,n,slots,tut,actions)
    assert g['garden']>150
    assert abs(g['bottom_y']+g['bottom']-(h-8))<1e-6
    assert g['card_y']-2 >= g['buy_y']
    assert g['card_y']+g['purchase']+14 <= g['buy_y']+g['available']
    assert g['purchase']+14 < g['width']/3
    assert g['rows']*g['card']+(g['rows']-1)*g['space']+26 <= g['bottom']-32+1e-6
    assert g['score_w']>60
    score_height=g['bottom']-54
    assert score_height-34>=n*26
    assert g['bottom']-48 >= score_height
    count+=1
r=layout(420,920,2,4,False,True)
assert .46 < r['garden']/920 < .49
print(f'OK: {count} geometrias independentes; jardim padrão {r["garden"]:.1f}px ({100*r["garden"]/920:.1f}%).')

# Modelo matemático do enquadramento: mesma escala para as coordenadas lógicas.
checks=0
for w,h,z,x0,y0,x1,y1 in product([344,404,464],[250,435,600],[.45,1,1.9],[-10,-2],[0,-7],[2,12],[1,15]):
    base=clamp(min((h-12)/3.5,(w-20)/4),22,88)
    zx=min(z,clamp(min((w-18)/((x1-x0+2)*base),(h-18)/((y1-y0+2)*base)),.12,1.9))
    assert zx<=z
    # In all sampled cases where the minimum zoom permits, full bounds fit.
    if zx>.12:
        assert (x1-x0+2)*base*zx<=w-18+1e-6
        assert (y1-y0+2)*base*zx<=h-18+1e-6
    checks+=1
print(f'OK: {checks} cálculos de enquadramento, sem ampliar zoom automaticamente.')
