load "chabauty.m";

// curve of Gordon & Grant that is solved directly by Coleman's theorem for p:= 7: - 2sec
A2<x,y> := AffinePlane(Rationals());
F := -y^2 + x*(x-1)*(x-2)*(x-5)*(x-6);
C := Curve(A2, F);
boo, D1 := IsHyperelliptic(C);
D2 := MinimalWeierstrassModel(D1);
assert ChabautyColeman(D2);

// test 3 ~25sec
// ramified 5-cycles (g=2)  (solved by basic CC for p := 3)
A2<x,y> := AffinePlane(Rationals());
F := -y^2 + x^6 + 8*x^5 + 22*x^4 + 22*x^3 + 5*x^2 + 6*x + 1;
C := Curve(A2, F);
boo, D1 := IsHyperelliptic(C);
D2 := SimplifiedModel(D1);
assert ChabautyColeman(D2);
