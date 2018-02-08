load "chabauty.m";

// test 1 - ~6.5sec
// 6-cycle
P3<x00, x10, x01, x11> := ProjectiveSpace(Rationals(), 3);
Flst := [-x10*x01 + x00*x11,
x00^3 - x00*x10^2 + x00^2*x01 - 5*x00*x10*x01 + 2*x10^2*x01 - x10*x01^2 + x10^2*x11 + 7*x10*x01*x11 - x01^2*x11 - 2*x10*x11^2 - 3*x11^3];
C := Curve(P3, Flst);
SetVerbose("User1", true);
booCC, C, pts, p, basept,
EmptyBadResidues, NonemptyBadResidues := ChabautyColeman(C : p := 5); // this is the prime used by Stoll
assert not booCC;
// TODO: remove nonempty bad residue class using power series expansion

// test 2 - ~9sec
// N4H2  (g=3,H)  (solved by basic CC)
Pr4<[w]> := ProjectiveSpace(Rationals(), 4);
qfseq := [w[2]^3 + 6*w[2]^2*w[3] + 2*w[1]*w[3]^2 + 12*w[2]*w[3]^2 + 9*w[3]^3 - w[2]*w[4]^2 + w[1]*w[3]*w[5] + w[2]*w[3]*w[5] + 3*w[3]^2*w[5] - 6*w[2]*w[4]*w[5] - w[1]*w[5]^2 - 11*w[2]*w[5]^2 - 7*w[3]*w[5]^2 - w[5]^3,
2*w[1]^2*w[3] + w[2]^2*w[3] + 9*w[1]*w[3]^2 + 6*w[2]*w[3]^2 + 12*w[3]^3 - w[1]^2*w[5] - w[2]^2*w[5] - 6*w[1]*w[3]*w[5] - 6*w[2]*w[3]*w[5] - 11*w[3]^2*w[5] - w[1]*w[5]^2,
w[2]^2*w[4] - w[2]*w[4]^2 + 6*w[2]^2*w[5] + 2*w[1]*w[3]*w[5] + 12*w[2]*w[3]*w[5] + 9*w[3]^2*w[5] - 6*w[2]*w[4]*w[5] - w[1]*w[5]^2 - 11*w[2]*w[5]^2 - 6*w[3]*w[5]^2 - w[5]^3,
w[1]*w[2] - w[3]^2,
w[1]*w[4] - w[3]*w[5],
w[3]*w[4] - w[2]*w[5]];
C := Curve(Pr4, qfseq);
assert ChabautyColeman(C);

// test 3 ~25sec
// ramified 5-cycles (g=2)  (solved by basic CC for p := 3)
A2<x,y> := AffinePlane(Rationals());
F := -y^2 + x^6 + 8*x^5 + 22*x^4 + 22*x^3 + 5*x^2 + 6*x + 1;
C := Curve(A2, F);
D, m := EmbedPlaneCurveInP3(C);
D := Curve(D);
assert ChabautyColeman(D);

// Diophantus curve that should fail the rank test
A2<x,y> := AffinePlane(Rationals());
F := -y^2 + x^6+x^2+1;
C := Curve(A2, F);
D, m := EmbedPlaneCurveInP3(C);
D := Curve(D);
try
	ChabautyColeman(D);
catch e
	assert e`Object eq "ERROR: rank >= genus";
end try;



