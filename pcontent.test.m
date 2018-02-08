Attach("pcontent.m");

// test 1
RZ2<x,y> := PolynomialRing(Integers(), 2);
I := ideal<RZ2 | [x^2-3*y]>;
content, F := pContentModI(x^2, 3, I);
assert(content eq 3);
assert(F eq y);

// test 2
RZ2<x,y> := PolynomialRing(Integers(), 2);
I := ideal<RZ2 | [x^2]>;
content, F := pContentModI(3*x^2, 3, I);
assert(content eq 3);
assert(F eq y);
