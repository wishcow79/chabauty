Attach("curve_ff.m");

// test 1
A2<x,y> := AffinePlane(Rationals());
C := Curve(A2, x^2+y^2-1);
FF := FunctionField(C);
f := FF ! (3*x);
ReduceRationalFunctionModp(f, 3);