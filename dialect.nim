# dialect
import tables, strutils, sequtils, parseutils, random
from math import cumsummed
type
  Bet = object
    key: seq[string]#Table[string, uint16]
    cs: seq[uint16]
  Dialect = Table[char, Bet]
  Style = string

const Special = {'>', '&', '*'}

var styles: seq[string]

proc style(args: varargs[string])=
  for arg in args:
    add(styles, arg)

iterator mzip[A,B](a: var openarray[A]; b: openarray[B]): tuple[a: var A; b: B] =
  let len = min(len(a), len(a))
  var i = 0
  while i < len:
    yield (a[i], b[i])
    i += 1
#[
proc `$`(d: Dialect): string =
  var rs: seq[string]
  for k,v in d:
    var ls: seq[string]
    for k,v in v.tbl:
      add(ls, "$1:$2" % [$k, $v])
    add(rs, "$1: {$2}" % [$k, join(ls, ", ")])
  "{$1}" % join(rs, ", ")
]#
proc initDialect(r: var Dialect)=
  r = initTable[char, Bet](4)

proc initBet(ls: seq[(string, uint16)]): Bet =
  result.key = mapIt(ls, it[0])
  result.cs = cumsummed(mapIt(ls, it[1]))

proc initBet(ls: seq[string]; max: int = 10): Bet =
  result.key = ls
  let len = len(ls)
  var cs: seq[uint16]
  for i in 0..<len:
    add(cs, rand(max).uint16)
  result.cs = cumsummed(cs)

proc readDialect(fn: string): Dialect =
  var f: File
  if not open(f, fn):
    quit("Failed to open file `$1`" % fn)
  initDialect(result)
  var
    n: char
    ls: seq[(string, uint16)]
  for ln in lines(f):
    var st = strip(ln)
    if st[0]!='#': # ignore comments
      if st[0]=='@': # marks new Dialect key
        let ch = st[1]
        if ch!='\0': # don't allow '\0'
          if n!='\0':
            if len(ls) != 0:
              result[n] = initBet(ls)
              ls = @[]
          n = ch
      elif n!='\0':
        const
          comma = {',', ';'}
          equal = {'=', ':'}
        st = split(st, '#', 1)[0] # split comments
        for sp in split(st, comma):
          var tk = split(sp, equal, 1)
          (tk[0], tk[1]) = (strip(tk[0]), strip(tk[1]))
          var vl: uint
          discard parseUint(tk[1], vl)
          if vl != 0:
            add(ls, (tk[0], vl.uint16))
  if n!='\0' and len(ls) != 0:
    result[n] = initBet(ls)
  close(f)

proc weighted(b: Bet): string= sample(b.key, b.cs)

const # n = reads next char
  Prev = '>' # (n) same as previous Bet
  Same = '&' # same as previous
  Rand = '*' # random from any Bet
  Frce = '#' # (n) force a char

proc rndName(d: Dialect): string =
  let
    style = sample(styles)
    len = len(style)
  var
    prevs: Table[char, string]
    prev: string
  for k in keys(d):
    prevs[k] = ""
  var i = -1
  while (inc i; i) < len:
    let c = style[i]
    add(result,
      case c
      of Prev:
        let
          c = style[i+1]
          v = prevs[c]
        inc i
        prev = v
        v
      of Frce:
        let v = $style[i+1]
        inc i
        prev = v
        v
      of Same:
        prev
      of Rand:
        let
          k = sample(toSeq(keys(d)))
          v = weighted(d[k])
        prev = v
        v
      else:
        let v = weighted(d[c])
        prev = v
        prevs[c] = v
        v
    )

proc rndName(d: Dialect; n: int): seq[string] =
  result = newSeqOfCap[string](n)
  for i in 0..n:
    add(result, rndName(d))

proc rndDialect(): Dialect =
  let
    vowels = @["a","e","i","o","u","y"]
    consos = @["b","c","d","f","g","h","j","k","l","m","n","p","q","r","s","t","v","w","x","y","z"]
  result['v'] = initBet(vowels)
  result['c'] = initBet(consos)


when isMainModule:
  randomize()
  #var english = readDialect("/english.die")
  var english = rndDialect()
  style("cvc&>vc", "cvcv", "cv&cc>vc", "vcvc#y", "v#hvcv#s", "cvc>vc")
  echo rndName(english, 16)

