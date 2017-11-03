//////////////////////////////////////////////////////////////////////
//
// chabauty.m
// Authors: Maarten Derickx, Solomon Vishkautsan, 1 October 2017
//
// Online at:
//  https://github.com/wishcow79/chabauty/blob/master/chabauty.m
// A file of examples is at
//  https://github.com/wishcow79/chabauty/blob/master/chabauty_tests.m
//
//
//  Chabauty package
//  ======================================================
//  An implementation of the Chabauty-Coleman algorithm for
//      curves of genus g >= 2.
//  The algorithm is based on examples by Michael Stoll,
//  esp. as in article "Rational 6-cycles under iteration of
//  quadratic polynomials".
//
//////////////////////////////////////////////////////////////////////


function ReduceCurveModp(C,p)
    assert IsCurve(C);
    assert IsPrime(p);

    if "Cp" in GetAttributes(Type(C)) and
        assigned C`Cp and
        IsDefined(C`Cp, p) then
            return C`Cp[p];
    end if;

    if not Type(C) eq CrvHyp and (not "UseReduction" in GetAttributes(Type(C)) or
        not assigned C`UseReduction or C`UseReduction) then
        Cp := Curve(Reduction(C, p));
    else
        if Type(C) eq CrvHyp then
            S := ChangeRing(C, GF(p));
        else
            S := BaseChange(C, Bang(Rationals(), GF(p)));
        end if;
        if IsCurve(S) then
            Cp := Curve(S);
        else
            error "reduction modulo p is not a curve.";
        end if;
    end if;

    if not "Cp" in GetAttributes(Type(C)) then
        AddAttribute(Type(C), "Cp");
    end if;

    if not assigned C`Cp then
        C`Cp := [];
    end if;

    C`Cp[p] := Cp;

    return Cp;
end function;

function CleanCurveEqs(C)
    eqs := DefiningEquations(C);
    eqseq := [ClearDenominators(e) : e in eqs];
    D := Curve(AmbientSpace(C), eqseq);

    // TODO: decide about saturation of curve
    if not IsSaturated(D) then
        Saturate(~D);
    end if;
    return D;
end function;

procedure SetUseReduction(~C, UseReduction)
    if not "UseReduction" in GetAttributes(Type(C)) then
        AddAttribute(Type(C), "UseReduction");
    end if;

    C`UseReduction := UseReduction;
end procedure;

function ConvertPointToIntSeq(pt)
    dim := #Eltseq(pt) -1 ;

    pt_seq := [pt[i]*d where d := LCM([Denominator(pt[j]) : j in [1..dim+1]]): i in [1..dim+1]];
    pt_seq := ChangeUniverse(pt_seq, Integers());

    return pt_seq;
end function;

function ReducePointModp(pt, p)
    C := Curve(pt);
    Cp := ReduceCurveModp(C, p);

    pt_seq := ConvertPointToIntSeq(pt);
    pt_mod_p := Cp ! pt_seq;

    return pt_mod_p;
end function;

function ReducePointsModp(pts, p)
    assert #pts ge 1;
    assert IsPrime(p);
    C := Curve(pts[1]);
    Cp := ReduceCurveModp(C, p);

    pts_mod_p := [Cp ! ConvertPointToIntSeq(pt) : pt in pts];

    return pts_mod_p;
end function;

procedure PrintPoints(pts)
    pts_seq := [ConvertPointToIntSeq(pt) : pt in pts];

    print "the points found are: \n";
    for i in [1..#pts_seq] do
        printf "P_%o = %o\n", i , pts_seq[i];
    end for;
end procedure;

function PrimesOfBadReduction(C)
    /* Find primes of bad reduction for a projective nonsingular curve */
    assert IsCurve(C);
    assert BaseField(C) eq Rationals();
    assert IsProjective(C);

    ambientC := AmbientSpace(C);
    dimC := Dimension(ambientC);

    definingC := DefiningEquations(C);
    definingC := [ClearDenominators(q) : q in definingC];
    PZ<[a]> := PolynomialRing(Integers(), dimC);

    // for each standard affine patch generate the elimination ideal
    eqnss := [[Evaluate(q, a[1..j-1] cat [1] cat a[j..dimC]) : q in definingC] : j in [1..(dimC+1)]];
    reslist := [];
    for eqns in eqnss do
      dermat := Matrix([[Derivative(q,i) : i in [1..dimC]] : q in eqns]);
      minors := Minors(dermat,dimC-1);
      I := ideal<PZ | eqns, minors>;
      elim := EliminationIdeal(I, {});
      Append(~reslist, Integers()!Basis(elim)[1]);
    end for;
    badprimes := &join{Set(PrimeDivisors(b)) : b in reslist};

    return badprimes;
end function;

function IsPrimeOfBadReduction(C,p)
    try
        Cp := ReduceCurveModp(C, p);
        FF := FunctionField(Cp);
    catch err
        return true;
    end try;
    return not IsNonsingular(Cp);
end function;

function FindGoodPrimes(C, ngp)
    p := 3;
    good_primes := [];
    while #good_primes lt ngp do
        if not IsPrimeOfBadReduction(C,p) then
            Append(~good_primes, p);
        end if;
        p := NextPrime(p);
    end while;
    return good_primes;
end function;

function GetClassGroupModp(C, p)
    Cp := ReduceCurveModp(C,p);
    Clp, fromClp, toClp := ClassGroup(Cp);

    return [*Clp, fromClp, toClp*];
end function;

function GetClGrpProd(C, GoodPrimes)
    // We cache the class group product in the curve C's attributes

    if "ClGrpProd" in GetAttributes(Type(C)) and
        assigned C`ClGrpProd and
        IsDefined(C`ClGrpProd, GoodPrimes) then
            return Explode(C`ClGrpProd[GoodPrimes]);
    end if;

    if not "ClGrpProd" in GetAttributes(Type(C)) then
        AddAttribute(Type(C), "ClGrpProd");
    end if;

    if not assigned C`ClGrpProd then
        C`ClGrpProd := AssociativeArray();
    end if;

    ClgrpsWithMaps := [GetClassGroupModp(C,p) : p in GoodPrimes];
    Clgrps := [Cl[1] : Cl in ClgrpsWithMaps];

    Clprod, injs, projs := DirectProduct(Clgrps);

    C`ClGrpProd[GoodPrimes] := [*Clprod, injs, projs*];

    return Clprod, injs, projs;
end function;

function MapFAtoClProd(C, pts, GoodPrimes)
    /* Determine map from free abelian group generated by the given rational points
        to the product of the class groups of the curves C_p for p in the set of given
        good primes
    */
    Clprod, injs, projs := GetClGrpProd(C, GoodPrimes);

    imgs := [*
             [toClp(Divisor(Place(pt)))
                 where Clp, fromClp, toClp := Explode(GetClassGroupModp(C,p)):
                 pt in ReducePointsModp(pts, p)] :
             p in GoodPrimes
            *];

    FA := FreeAbelianGroup(#pts);
    FAtoClprod := hom<FA -> Clprod | [&+[injs[i](imgs[i][j]) :
                                            i in [1..#GoodPrimes]]:
                                            j in [1..#pts]]>;

    return FAtoClprod;
end function;

function RationalPointsModp(C, p)
    if "rat_pts_mod_p" in GetAttributes(Type(C)) and
        assigned C`rat_pts_mod_p and
        IsDefined(C`rat_pts_mod_p, p) then
            return C`rat_pts_mod_p[p];
    end if;

    Cp := ReduceCurveModp(C, p);
    rat_pts := RationalPoints(Cp);
    if not "rat_pts_mod_p" in GetAttributes(Type(C)) then
        AddAttribute(Type(C), "rat_pts_mod_p");
    end if;

    if not assigned C`rat_pts_mod_p then
        C`rat_pts_mod_p := [];
    end if;

    rat_pts := [ChangeUniverse(Eltseq(pt), Integers()) : pt in rat_pts];
    C`rat_pts_mod_p[p] := rat_pts;

    return rat_pts;
end function;

function MapCpsToClprod(C, GoodPrimes, basept)
    assert IsCoercible(C, basept);

    Clprod,injs, projs := GetClGrpProd(C, GoodPrimes);

    CpsToClprod := [**];
    for i in [1..#GoodPrimes] do
        p := GoodPrimes[i];
        inj := injs[i];
        Cp := ReduceCurveModp(C,p);
        ptsCp := RationalPointsModp(C, p);
        Clp,fromClp,toClp := Explode(GetClassGroupModp(C,p));

        baseptCp := ReducePointModp(basept, p);

        CpToClProd := map<ptsCp->Clprod|x:->inj(toClp(Place(Cp ! x)-Place(baseptCp)))>;
        Append(~CpsToClprod, CpToClProd);
    end for;

    return CpsToClprod;
end function;

function MapCpsToJps(C, GoodPrimes, basept)
    assert IsCoercible(C, basept);

    Clprod,injs, projs := GetClGrpProd(C, GoodPrimes);

    maps := MapCpsToClprod(C, GoodPrimes, basept);
    return [maps[i]*projs[i] : i in [1..#GoodPrimes]];
end function;

function MapCpProdToClprod(C, GoodPrimes, basept)
    maps := MapCpsToClprod(C, GoodPrimes, basept);
    Clprod,injs, projs := GetClGrpProd(C, GoodPrimes);

    car := CartesianProduct([Set(RationalPointsModp(C,p)) : p in GoodPrimes]);
    return map<car->Clprod| x:->&+[maps[i](x[i]) : i in [1..#GoodPrimes]]>;
end function;

function JacobianTorsionBound(C, pts, GoodPrimes)
    /* Find torsion bound for Jacobian */
    // Get upper bound for torsion structure
    // (do not use reduction mod 2, since 2-torsion may not map injectively)
    ClgrpsWithMaps := [GetClassGroupModp(C,p) : p in GoodPrimes | p ne 2];
    Clgrps := [Cl[1] : Cl in ClgrpsWithMaps];
    invs := [[i : i in Invariants(Cl) | i ne 0] : Cl in Clgrps];
    tors_bound := [GCD([#seq gt j select seq[#seq-j] else 1 : seq in invs])
                 : j in [Max([#seq : seq in invs])-1..0 by -1]];
    tors_bound := [i : i in tors_bound | i gt 1];

    return tors_bound;
end function;

function JacobianRankLowerBound(C, pts, GoodPrimes)
    /* Find lower bound for rank of the Jacobian */
    tors_bound := JacobianTorsionBound(C, pts, GoodPrimes);
    FAtoClprod := MapFAtoClProd(C, pts, GoodPrimes);

    imFAtoClprod := Image(FAtoClprod);
    iminvs := Invariants(imFAtoClprod);
    iminvs := [inv : inv in iminvs | inv ne 0];

    i := 1;
    if #tors_bound ne 0 then
        total_tors_bound := &*tors_bound;
        while i le #iminvs do
            boo := IsDivisibleBy(total_tors_bound, iminvs[i]);
            if not boo then
                break;
            end if;
            i := i + 1;
        end while;
    end if;

    if i gt #iminvs then
        return 0;
    else
        return #iminvs - i + 1;
    end if;
end function;

function PrincipalGenerators(C, pts, GoodPrimes : NormBound := 50)
    FAtoClprod := MapFAtoClProd(C, pts, GoodPrimes);
    ker := Kernel(FAtoClprod);

    kerlat := Lattice(Matrix([Eltseq(Domain(FAtoClprod)!b) : b in OrderedGenerators(ker)]));
    basis := Basis(LLL(kerlat));
    small_basis := [b : b in basis | Norm(b) le NormBound];

    rels := [&+[b[i]*Place(pts[i]) : i in [1..#pts]] : b in small_basis];
    principal_gens := [small_basis[i] : i in [1..#rels]| IsPrincipal(rels[i])];

    return principal_gens;
end function;

function Deg0Divisors(FA)
    Div0, iDiv0toFA := sub<FA|[FA.i - FA.1 : i in [2..Ngens(FA)]]>;
    return Div0, iDiv0toFA;
end function;

function JacobianKnownSubgroup(C, pts, GoodPrimes)
    FA2Clprod := MapFAtoClProd(C, pts, GoodPrimes);
    FA := Domain(FA2Clprod);
    Clprod := Codomain(FA2Clprod);
    prgens := PrincipalGenerators(C, pts, GoodPrimes);
    prgens := [ChangeUniverse(Eltseq(g), Integers()) : g in prgens];
    Div0, iDiv0toFA := Deg0Divisors(FA);
    quot,pi := quo<Div0| [FA ! g : g in prgens]>;
    return quot, [iDiv0toFA(g @@ pi) : g in OrderedGenerators(quot)];
end function;

function MapJknownToClprod(C, pts, GoodPrimes)
    Jknown, JknownGenerators := JacobianKnownSubgroup(C, pts, GoodPrimes);
    Clprod, injs, projs := GetClGrpProd(C, GoodPrimes);
    FA2Clprod := MapFAtoClProd(C, pts, GoodPrimes);
    FA := Domain(FA2Clprod);
    phi := hom<Jknown->Clprod | [FA2Clprod(FA ! Eltseq(g)) : g in JknownGenerators]>;
    return phi;
end function;

function MapsJknownToJp(C, pts, GoodPrimes)
    Jknown, JknownGenerators := JacobianKnownSubgroup(C, pts, GoodPrimes);
    Clprod, injs, projs := GetClGrpProd(C, GoodPrimes);
    FA2Clprod := MapFAtoClProd(C, pts, GoodPrimes);
    FA := Domain(FA2Clprod);
    phi := hom<Jknown->Clprod | [FA2Clprod(FA ! Eltseq(g)) : g in JknownGenerators]>;
    maps := [phi * projs[i] : i in [1..#GoodPrimes]];
    return maps;
end function;

function JacobianRankUpperBound(C, pts, GoodPrimes : NormBound := 50)
    principal_gens := PrincipalGenerators(C, pts, GoodPrimes : NormBound := NormBound);

    return #pts - #principal_gens - 1, principal_gens;
end function;

function FindRankJacobianSubgrp(C, pts, GoodPrimes)
    rank_lower_bound := JacobianRankLowerBound(C, pts, GoodPrimes);
    rank_upper_bound, principal_gens := JacobianRankUpperBound(C, pts, GoodPrimes);

    print "Lower bound on rank of the Jacobian subgroup:", rank_lower_bound;
    print "Upper bound on rank of the Jacobian subgroup:", rank_upper_bound;
    assert(rank_lower_bound eq rank_upper_bound);
    print "Upper bound = lower bound, so we can proceed.";

    return rank_upper_bound, principal_gens;
end function;

function RemovePContentModI(F, p, I)
    assert F ne 0;

    RZ := Generic(I);
    assert BaseRing(RZ) eq Integers();
    Rp := ChangeRing(RZ, GF(p));

    gens_I := Generators(I);
    gens_Ip := [Rp ! g : g in gens_I];
    Ip := IdealWithFixedBasis(gens_Ip);

    Fp := Rp ! F;
    coeff := 1;

    while Fp in Ip do
        Fp_coords := Coordinates(Ip, Fp);
        fixF := &+[gens_I[i]*(RZ ! Fp_coords[i]) : i in [1..#Fp_coords]];
        F -:= fixF;
        contentF := Content(F);
        coeff *:= contentF;
        F := ExactQuotient(F , contentF);
        Fp := Rp ! F;
    end while;

    return F, coeff;
end function;

function SaturatedIdealOfCurveAtPrime(C,p)
    if "SaturatedIdeal" in GetAttributes(Type(C)) and
        assigned C`SaturatedIdeal and
        IsDefined(C`SaturatedIdeal, p) then
            return C`SaturatedIdeal[p];
    end if;

    if not "SaturatedIdeal" in GetAttributes(Type(C)) then
        AddAttribute(Type(C), "SaturatedIdeal");
    end if;

    if not assigned C`SaturatedIdeal then
        C`SaturatedIdeal := [];
    end if;

    I := Ideal(C);
    basisI := [ClearDenominators(b) : b in Basis(I)];
    I := Ideal(basisI);

    ambR := CoordinateRing(Ambient(C));
    ambRZ := ChangeRing(ambR, Integers());
    IZ := Ideal([ambRZ ! b:b in basisI]);
    IZsat := Saturation(IZ, ambRZ ! p);

    C`SaturatedIdeal[p] := IZsat;

    return IZsat;
end function;

function ValuationOfRationalFunction(f,p)
    FF := Parent(f);
    C := Curve(FF);

    IZsat := SaturatedIdealOfCurveAtPrime(C,p);
    ambRZ := Generic(IZsat);

    num1, den1 := IntegralSplit(f,C); // num and den are in ambR

    num2, lcd_num1 := ClearDenominators(num1);
    den2, lcd_den1 := ClearDenominators(den1);

    num3 := ambRZ ! num2;
    den3 := ambRZ ! den2;

    content_num3, num4 := ContentAndPrimitivePart(num3);
    content_den3, den4 := ContentAndPrimitivePart(den3);

    num5,coeff_num5 := RemovePContentModI(num4, p, IZsat);
    den5,coeff_den5 := RemovePContentModI(num5, p, IZsat);

    coeff := (lcd_den1 * content_num3 * coeff_num5) / (lcd_num1 * content_den3 * coeff_den5);
    v := Valuation(coeff,p);

    return v;
end function;

function ReduceRationalFunctionModp(f,p)
    assert IsPrime(p);

    FF := Parent(f);
    C := Curve(FF);

    R := CoordinateRing(C);
    I := Ideal(C);
    basisI := [ClearDenominators(b) : b in Basis(I)];
    I := Ideal(basisI);

    ambR := CoordinateRing(Ambient(C));
    ambRp := ChangeRing(ambR, GF(p));

    IZsat := SaturatedIdealOfCurveAtPrime(C,p);
    ambRZ := Generic(IZsat);

    Cp := ReduceCurveModp(C,p);
    FFp := FunctionField(Cp);
    Ip := Ideal(Cp);
    basisIp := Basis(Ip);
    Ip := Ideal([ambRp ! b : b in basisIp]);
    Rp<[a]> := CoordinateRing(Ambient(Cp));

    num1, den1 := IntegralSplit(f,C); // num and den are in ambR

    num2, lcd_num1 := ClearDenominators(num1);
    den2, lcd_den1 := ClearDenominators(den1);

    num3 := ambRZ ! num2;
    den3 := ambRZ ! den2;

    content_num3, num4 := ContentAndPrimitivePart(num3);
    content_den3, den4 := ContentAndPrimitivePart(den3);

    num4p := ambRp ! num4;
    den4p := ambRp ! den4;
    coeff4 := (lcd_den1 * content_num3) / (lcd_num1 * content_den3);

    if not den4p in Ip and Valuation(coeff4, p) ge 0 then
        return FFp ! (Evaluate((coeff4 * num4p), a) / Evaluate(den4p,a));
    end if;

    // if we can't fix the numerator then we will never be able to fix either the denominator
    // or the bad coefficient.
    if not num4p in Ip then
        error "Error in reducing rational function. Nothing we can do to fix p in denominator.";
    end if;

    num5, coeff_num5 := RemovePContentModI(num4, p, IZsat);

    if den4p in Ip then
        den5, coeff_den5 := RemovePContentModI(den4, p, IZsat);
    else
        coeff_den5 := 1;
        den5 := den4;
    end if;

    num5p := ambRp ! num5;
    den5p := ambRp ! den5;

    // sanity check:
    assert not num5p in Ip and not den5p in Ip;

    coeff5 := coeff4 * coeff_num5 / coeff_den5;

    if Valuation(coeff5, p) lt 0 then
        error "Failed to reduce rational function mod p";
    end if;

    return FFp ! (Evaluate((coeff5 * num5p), a) / Evaluate(den5p,a));
end function;

// function LiftRationalFunction(f, C)
//     // lift rational function to a rational function on the curve C
//     FF<[x]> := FunctionField(C);
//     dim := Dimension(AmbientSpace(C));
//     R<[a]> := PolynomialRing(BaseRing(C), dim);

//     N := Numerator(f);
//     coeffs_N := ChangeUniverse(Eltseq(Coefficients(N)), Integers());
//     N_lift := Polynomial(coeffs_N,[Monomial(R, Exponents(m)) : m in Monomials(N)]);

//     D := Denominator(f);
//     coeffs_D := ChangeUniverse(Eltseq(Coefficients(D)), Integers());
//     D_lift := Polynomial(coeffs_D,[Monomial(R, Exponents(m)) : m in Monomials(D)]);

//     f_lift := Evaluate(N_lift/D_lift,x);
//     return f_lift;
// end function;

function ReduceDifferentialModp(d, p, uni)
    C := Curve(d);
    duni := Differential(uni);
    f := d / duni;
    f_p := ReduceRationalFunctionModp(f,p);
    uni_p := ReduceRationalFunctionModp(uni, p);
    duni_p := Differential(uni_p);
    return f_p * duni_p;
end function;

procedure PrintKernelModp(ker_basis, p)
    printf "Basis of kernel of reduction modulo %o:\n", p;
    for b in ker_basis do
        for i in [1..#b] do
            if b[i] eq 0 then
                continue i;
            end if;
            if b[i] lt 0 or i eq 1 then
                printf "%o*P_%o", b[i], i;
            else
                printf "+%o*P_%o", b[i], i;
            end if;
        end for;
        printf "\n";
    end for;
end procedure;

function GetKernelModp(C, pts, p, ker_basis)
    // We take the kernel of FA->Pic(Q) and complete
    // to a basis of the kernel of reduction mod p from FA->Pic(F_p),
    // up to a finite index.
    // The extra vectors map into a finite index subgroup
    // of the kernel of Pic(Q)->Pic(F_p)
    assert p gt 2;
    pts_p := ReducePointsModp(pts, p);
    Cl_p_seq := GetClassGroupModp(C,p);
    Cl_p := Cl_p_seq[1];
    fromCl_p := Cl_p_seq[2];

    FA := FreeAbelianGroup(#pts);
    hom_p := hom<FA -> Cl_p | [Divisor(Place(Curve(Codomain(fromCl_p)) ! Eltseq(pt))) @@ fromCl_p : pt in pts_p]>;

//    homs := [hom<FA -> Cls[i] | [Divisor(Place(pt)) @@ fromCls[i]
//                                   : pt in ptsred[i]]>  : i in [1..#Cls]];


    KerQ := sub<FA | [FA!Eltseq(b) : b in ker_basis]>;
//    Pic, mPic := quo<FA | [FA!Eltseq(b) : b in basis]>;

    ker_p := Kernel(hom_p);
    L_p := Lattice(Matrix([Eltseq(FA!k) : k in OrderedGenerators(ker_p)]));
    // basis_p := Basis(LLL(L_p));

    E := EchelonForm(Matrix(GF(5),[Reverse( Coordinates(L_p ! Vector(Eltseq(FA ! g)))) : g in OrderedGenerators(KerQ)]));

    pivots := [];
    j := 1;
    for i in [1..Nrows(E)] do
        while j le Ncols(E) and E[i,j] eq 0 do
            j +:= 1;
        end while;
        if j gt Ncols(E) then
            error "unexpected end of matrix";
        end if;
        Append(~pivots, j);
    end for;
    non_pivots := [j : j in [1..Ncols(E)] | not j in pivots];

    gens := [Eltseq(L_p.(Ncols(E)-j+1)) : j in non_pivots];

    return gens;
/*
    // small_basis := [Eltseq(b) : b in basis_p | Norm(b) le NormBound];
    divs_p := [&+[small_basis[i,j]*Place(pts[j]) : j in [1..#pts]] : i in [1..#small_basis]];
    // first we eliminate the principal divisors in the basis of the kernel
    idx_ker_p := [i : i in [1..#small_basis] | not IsPrincipal(divs_p[i])];
    small_basis := [small_basis[i] : i in idx_ker_p];
    divs_p := [divs_p[i] : i in idx_ker_p];

    divs_p_reduced := [];
    small_basis_reduced := [];
    for i in [1..#divs_p] do
        d1 := divs_p[i];
        for d2 in divs_p_reduced do
            if IsLinearlyEquivalent(d1,d2) then
                continue i;
            end if;
        end for;
        Append(~divs_p_reduced, d1);
        Append(~small_basis_reduced, small_basis[i]);
    end for;
    divs_p := divs_p_reduced;
    small_basis := small_basis_reduced;

    assert mPic(sub<FA | small_basis>) eq mPic(ker_p);

    return small_basis;
*/
end function;

function GetCharpols(ker_basis, pts, basept, uni, p)
    // input: generators of kernel of reduction mod p
    // computes D_i - n*basept
    // output: characteristic polynomial of D_i
    // TODO: change function input to be divisors and not intseq
    // we CACHE this in the curve, as this is the most expensive step in the computation
    C := Curve(basept);
    basept_div := Divisor(Place(basept));

    divs_p := [&+[ker_basis[i,j]*Place(pts[j]) : j in [1..#pts]] : i in [1..#ker_basis]];

    divs_p_red := [Reduction(d, basept_div) : d in divs_p];
    decomps := [Decomposition(d) : d in divs_p_red];
    assert forall{d : d in decomps | #d eq 1 and d[1,2] eq 1};
    dpts := [* RepresentativePoint(d[1,1]) : d in decomps *];
    charpols := [MinimalPolynomial(Evaluate(uni,pt)) : pt in dpts];
    for charpol in charpols do
        coeffs_charpol := Coefficients(charpol);
        try
            assert forall{c : c in coeffs_charpol[1..(#coeffs_charpol-1)]| Valuation(c, p) gt 0};
        catch e
            print "ERROR: charpol does not reduce to t^n mod p.";
            print "Charpol = ", charpol;
            print "Coefficients", coeffs_charpol[1..(#coeffs_charpol-1)];
            print [Valuation(c, p) : c in coeffs_charpol[1..(#coeffs_charpol-1)]];
            error e`Object;
        end try;
    end for;

    return charpols;
end function;

function IsGoodUniformizer(u, basept, p)
    v := Valuation(u, basept);
    C := Curve(basept);
    Cp := ReduceCurveModp(C,p);
    up := ReduceRationalFunctionModp(u, p);

    vp := Valuation(up, Cp ! Eltseq(ReducePointModp(basept,p)));
    if v eq 1 and vp eq 1 then
        return true;
    else
        return false;
    end if;
end function;


// function GetGoodUniformizer2(basept, p)
//     C := Curve(basept);
//     dim := Dimension(AmbientSpace(C));
//     Cp := ReduceCurveModp(C,p);

//     FF<[x]> := FunctionField(C);
//     FFp<[b]> := FunctionField(Cp);
//     PolQ<[a]> := PolynomialRing(BaseRing(C), dim);

//     // we reduce the basept modulo p
//     basept_seq := Eltseq(basept);
//     basept_seq := [basept_seq[i]*d where d := LCM([Denominator(basept_seq[j]) : j in [1..dim+1]]): i in [1..dim+1]];
//     basept_seq := ChangeUniverse(basept_seq, Integers());
//     basept_modp := Cp ! basept_seq;

//     // we start with a uniformizer u1 at the basept and reduce it modulo p
//     // but first we replace u1 with a function that can be reduced mod p
//     u1 := UniformizingParameter(basept);
//     N := Evaluate(Numerator(u1), a);
//     D := Evaluate(Denominator(u1), a);
//     N, L1 := ClearDenominators(N);
//     D, L2 := ClearDenominators(D);
//     N := N / GCD(ChangeUniverse(Coefficients(N), Integers()));
//     D := D / GCD(ChangeUniverse(Coefficients(D), Integers()));
//     u1 := Evaluate(N/D, x);
//     // sanity check::: we make sure u1 is still a uniformizer:
//     assert Valuation(u1, basept) eq 1;

//     // we reduce the uniformizer u1 mod p
//     u1modp := ReduceRationalFunction(u1, Cp);

//     // if u1modp is a uniformizer at the reduction of the basept then we are done
//     v1 := Valuation(u1modp, basept_modp);
//     if v1 eq 1 then
//         vprint User1: "Reduction of u1 is a uniformizer";
//         return u1;
//     end if;

//     // We now have the situation where u1modp is not a uniformizer at basept_modp.
//     // We take a uniformizer at basept_modp and lift it to a rational function on C
//     u2modp := UniformizingParameter(basept_modp);
//     u2 := LiftRationalFunction(u2modp, C);
//     v2 := Valuation(u2, basept);
//     if v2 eq 1 then
//         vprint User1: "lift of u2 is a uniformizer";
//         // sanity check:::
//         assert Valuation(ReduceRationalFunction(u2, Cp), basept_modp) eq 1;
//         return u2;
//     end if;

//     if v2 gt 1 then
//         u3 := p*u1+u2;
//     else
//         // we get here only if v2 is now < 0
//         u3 := 1/(p/u1 + 1/u2);
//     end if;

//     // sanity check:::
//     assert Valuation(u3, basept) eq 1;
//     assert Valuation(ReduceRationalFunction(u3, Cp), basept_modp) eq 1;
//     return u3;
// end function;

function GetGoodUniformizer(basept, p)
    C := Curve(basept);
    dim := Dimension(AmbientSpace(C));
    Cp := ReduceCurveModp(C,p);
    RCp<[W]> := AmbientSpace(Cp);
    RC<[A]> := AmbientSpace(C);

    FF<[x]> := FunctionField(C);
    FFp<[b]> := FunctionField(Cp);
    PolQ<[a]> := PolynomialRing(BaseRing(C), dim);

    // we reduce the basept modulo p
    basept_seq := Eltseq(basept);
    basept_seq := [basept_seq[i]*d where d := LCM([Denominator(basept_seq[j]) : j in [1..dim+1]]): i in [1..dim+1]];
    basept_seq := ChangeUniverse(basept_seq, Integers());
    basept_modp := Cp ! basept_seq;

    // find non-zero entry of basept (mod p) for dehomogenization
    basept_modp_seq := Eltseq(basept_modp);
    i := 1;
    while i le #basept_modp_seq do
        if basept_modp_seq[#basept_modp_seq - i + 1] ne 0 then
            break;
        end if;
        i +:= 1;
    end while;
    i := #basept_modp_seq - i + 1;

    uni := 0;
    for j in [1..dim+1] do
        if j eq i then
            continue j;
        end if;
        l_p := (W[j] / W[i]) - (basept_modp[j] / basept_modp[i]);
        v_p := Valuation(l_p,basept_modp);
        // assert Valuation(FFp ! l_p, basept_modp) eq v_p;

        if v_p eq 1 then
            l := A[j]/A[i] - (basept_seq[j] / basept_seq[i]);
            assert Valuation(l, basept) eq 1;
            uni := FF ! l;

            break j;
        end if;
    end for;

    if uni eq 0 then
        error "Could not find a good uniformizer";
    end if;

    // clear p-powers from numerator and denominator
    /*
    N := Numerator(uni);
    coeffs_N := Coefficients(N);
    minN := Min([Valuation(c,p) : c in coeffs_N]);
    D := Denominator(uni);
    coeffs_D := Coefficients(D);
    minD := Min([Valuation(c,p) : c in coeffs_D]);
    uni := (FF ! (N / p^minN)) / (FF ! (D / p^minD));
    */

    // sanity checks
    assert ValuationOfRationalFunction(uni, p) eq 0;
    assert IsGoodUniformizer(uni, basept, p);

    return uni;
end function;

function ExpandWithUniformizer(f, pt, u, z : Precision := 50, Power := 0)
    assert Valuation(f,pt) ge 0;
    assert Valuation(u,pt) eq 1;

    FF := Parent(f);
    R, m := Completion(FF,Place(pt) : Precision := Precision);
    ex_f := m(f);
    leading := Evaluate(ex_f,0);
    ex_f := ex_f - leading;
    rev := Reversion(m(u));

    return Composition(ex_f, rev) + leading;
end function;

procedure PrintKillingBasis(killing_basis, DiffForms, p, pAdicPrecision)
    printf "Basis of forms killing J_1 when reduced modulo p^%o:\n",pAdicPrecision;

    for i := 1 to #killing_basis do
      start := true;
      printf "    ";
      for j := 1 to #DiffForms do
        c := killing_basis[i,j];
        if c ne 0 then
          if not start then printf " + "; else start := false; end if;
          if c ne Integers(p^pAdicPrecision)!1 then
            printf "%o ", c;
          end if;
          printf "w_%o", j-1;
        end if;
      end for;
      printf "\n";
    end for;
end procedure;


function BasisOfKillingForms(DiffForms, charpols, basept, uni, p : Precision := 50, targetpAdicPrecision := 5, computationalpAdicPrecision := 5)
    if targetpAdicPrecision gt computationalpAdicPrecision then
        computationalpAdicPrecision := targetpAdicPrecision;
    end if;
    reciprocal_charpols := [ReciprocalPolynomial(charpol): charpol in charpols];

    diff_uni := Differential(uni);

    diff_forms_funcs := [d/diff_uni : d in DiffForms];

    Pws_Q<z> := LaurentSeriesAlgebra(Rationals());
    diff_forms_exps := [];
    for d in diff_forms_funcs do
        exp_d := ExpandWithUniformizer(d, basept, uni, z : Precision := Precision);

        Append(~diff_forms_exps, exp_d);
    end for;

    powersums := [-z*Evaluate(Derivative(reciprocal_charpol), z) / Evaluate(reciprocal_charpol, z) :
                                reciprocal_charpol in reciprocal_charpols];

    logs := [Integral(om) : om in diff_forms_exps];
    // print "logs:\n", logs;

    // TODO: set precision of p-adic field
    Qp := pAdicField(p : Precision := computationalpAdicPrecision);
    Pws_Qp<w> := LaurentSeriesAlgebra(Qp);

    mat := Matrix([[Qp ! Evaluate(Convolution(Evaluate(powersum, w), Evaluate(l,w)),1) : powersum in powersums] : l in logs]) / p;
    // print "mat:\n", mat;
    mat_prec := ChangeRing(mat, Bang(Qp, Integers()) * Bang(Integers(), Integers(p^computationalpAdicPrecision)));
    ker := Kernel(mat_prec);
    ker_mat_prec := BasisMatrix(ker);
    expected_dim := #DiffForms - #charpols;
    d := ElementaryDivisors(ker_mat_prec);
    if #d gt expected_dim then
        actual_prec := Valuation(Integers() ! d[expected_dim+1],p);
        if actual_prec lt targetpAdicPrecision then
            print "Raising precision by:", targetpAdicPrecision - actual_prec; // TODO::: CHECK!!!
            return BasisOfKillingForms(DiffForms, charpols, basept, uni, p : Precision := Precision, targetpAdicPrecision := targetpAdicPrecision, computationalpAdicPrecision := 2*computationalpAdicPrecision - actual_prec);
        end if;
    end if;

    ker_mat_prec := ChangeRing(ker_mat_prec, Integers(p^targetpAdicPrecision));
    S,A,B := SmithForm(ker_mat_prec);
    //A*S*B eq ker_mat_prec
    Binv := B^(-1);
    ker_rows := [v*Binv : v in S[1..expected_dim]];

    return ker_rows, mat;
end function;

function ChooseGoodBasept(pts, p)
    assert #pts ge 1;
    C := Curve(pts[1]);
    dim := Dimension(AmbientSpace(C));
    Cp := ReduceCurveModp(C,p);
    assert IsNonSingular(Cp);

    pts_seq := [[pt[i]*d where d := LCM([Denominator(pt[j]) : j in [1..dim+1]]): i in [1..dim+1]] : pt in pts];
    pts_seq := [ChangeUniverse(pt, Integers()) : pt in pts_seq];
    for pt in pts_seq do
        //if not IsWeierstrassPlace(Place(Cp!pt)) then
            return C ! pt;
        //end if;
    end for;

    error "There are no good base points to choose from :(";
end function;


procedure PrintDifferentialForms(DiffForms)
    print "Chosen basis of differential forms for the curve:";
    ctr := 0;
    for w in DiffForms do
        if ctr eq 0 then
            printf "w_%o = %o \n", ctr, w;
            w0 := w;
        else
            printf "w_%o = (%o) w_0 \n", ctr, w / w0;
        end if;
        ctr +:= 1;
    end for;
end procedure;

function GoodBasisOfDifferentials(C, p : DiffForms := [])
    if DiffForms eq [] then
        DiffForms := BasisOfHolomorphicDifferentials(C);
    end if;

    V, m := SpaceOfHolomorphicDifferentials(C);
    minv := Inverse(m);
    Cp := ReduceCurveModp(C,p);
    Vp, mp := SpaceOfHolomorphicDifferentials(Cp);
    mpinv := Inverse(mp);

    // sanity check:
    assert Dimension(sub<V | [minv(d) : d in DiffForms]>) eq Genus(C);

    Pr<[X]> := AmbientSpace(C);
    FF := FunctionField(C);
    x := FF ! (X[1]/X[2]);
    dx := Differential(x);

    // we clear any p-powers from numerators and denominators
    // of the differential forms
    fixed_diff_forms := [];
    for d in DiffForms do
        f := d / dx;
        v := ValuationOfRationalFunction(f,p);
        Append(~fixed_diff_forms, p^(-v)*d);
    end for;

    diff_vectors := [minv(d) : d in fixed_diff_forms];
    diffs_p := [ReduceDifferentialModp(d,p,x) : d in fixed_diff_forms];
    diff_p_vectors := [mpinv(d) : d in diffs_p];

    while Dimension(sub<Vp | diff_p_vectors>) ne Genus(C) do
        DiffLatC := FreeAbelianGroup(Genus(C));
        DiffLatCp := AbelianGroup([p : x in [1..Genus(C)]]);
        h := hom<DiffLatC->DiffLatCp |
                 [DiffLatCp ! Eltseq(mpinv(d)) : d in diffs_p]>;
        new_diff_vec_coordinates := [Eltseq(DiffLatC ! d) : d in OrderedGenerators(Kernel(h)) |
                                     not d in p*DiffLatC];

        new_diffs := [&+[coord[i]*fixed_diff_forms[i] : i in [1..#coord]] :
                      coord in new_diff_vec_coordinates];

        for d in new_diffs do
            f := d / dx;
            v := ValuationOfRationalFunction(f,p);
            d_fixed := p^(-v)*d;
            Append(~diff_vectors, minv(d_fixed));
        end for;
        L := Lattice(Matrix(diff_vectors));
        diff_vectors := [V ! Eltseq(b) : b in Basis(L)];
        fixed_diff_forms := [];
        for dv in diff_vectors do
            d := m(dv);
            f := d / dx;
            v := ValuationOfRationalFunction(f,p);
            Append(~fixed_diff_forms, p^(-v)*d);
        end for;
        diff_vectors := [minv(d) : d in fixed_diff_forms];
        diffs_p := [ReduceDifferentialModp(d,p,x) : d in fixed_diff_forms];
        diff_p_vectors := [mpinv(d) : d in diffs_p];
    end while;

    return fixed_diff_forms;
end function;

function ChoosePrecision(g,p : pAdicPrecision := 5)
    l := 1;
    while (Ceiling((l*p+1)/g) - Valuation(l*p+1,p)) lt pAdicPrecision do
        l +:= 1;
    end while;

    return l*p + 1;
end function;

function pAdicCoefficients(x : pAdicPrecision := 5)
    Zp := Parent(x);
    p := Prime(Zp);

    //prec_x := Precision(x);
    //assert prec_x ge pAdicPrecision;

    assert Degree(Zp) eq 1;
    xint := Integers()!x;
    xint := xint mod p^(pAdicPrecision);
    intseq := Intseq(xint, Prime(Zp));
    // pad intseq with zeros up to precision
    return intseq cat [0 : i in [1..pAdicPrecision - #intseq - 1]];
end function;

function pAdicPrettyPrint(x : pAdicPrecision := 5)
    Zp := Parent(x);
    p := Prime(Zp);

    // prec_x := Precision(x);
    // assert prec_x ge pAdicPrecision;

    coeffs := pAdicCoefficients(x : pAdicPrecision := pAdicPrecision);
    strs := [];
    for i in [0..pAdicPrecision-2] do
        c := coeffs[i+1];
        if c eq 0 then
            continue i;
        end if;
        case i:
        when 0:
            Append(~strs,Sprintf("%o", c));
        else
            if c gt 0 then
                Append(~strs,"+");
            end if;
            if c ne 1 then
                Append(~strs,Sprintf("%o*", c));
            end if;
            Append(~strs,Sprintf("%o", p));
            if i ne 1 then
                Append(~strs,Sprintf("^%o", i));
            end if;
        end case;
    end for;
    Append(~strs,Sprintf("+O(%o^%o)", p, pAdicPrecision));
    return &cat strs;
end function;

function IsReductionModpSurjective(C,pts,p)
    Cp := ReduceCurveModp(C, p);
    rat_pts_Cp := RationalPoints(Cp);
    pts_mod_p := ReducePointsModp(pts, p);

    is_surjective := #rat_pts_Cp eq #Set(pts_mod_p);

    return is_surjective;
end function;

function GetResidueClasses(C,pts, p)
    // TODO: move print out of this function
    Cp := ReduceCurveModp(C, p);
    ptsCp := RationalPointsModp(C,p);
    pts_seq := [ConvertPointToIntSeq(pt) : pt in pts];

    residue_classes := [];
    for pt in ptsCp do
        Append(~residue_classes, []);
    end for;

    for pt in pts_seq do
        pt_modp := Cp ! pt;
        i := Index(ptsCp, ChangeUniverse(Eltseq(pt_modp), Integers()));
        Append(~residue_classes[i], C ! pt);
    end for;

    printf "These are the residue classes mod %o: \n", p;
    residue_classes_out := [];
    for i in [1..#ptsCp] do
        Append(~residue_classes_out, [*ptsCp[i], residue_classes[i]*]);
        printf "%o <---", ptsCp[i];
        for pt in residue_classes[i] do
            printf "%o,", pt;
        end for;
        printf "\n";
    end for;

    return residue_classes_out;
end function;

function ZerosOfKillingFormsModp(DiffForms, killing_basis, p, uniformizer)
    assert #DiffForms ge 1;
    C := Curve(DiffForms[1]);
    Cp := ReduceCurveModp(C,p);
    rat_pts_p := RationalPoints(Cp);
    FFp := FunctionField(Cp);

    diff_forms_p := [ReduceDifferentialModp(d,p, uniformizer) : d in DiffForms];
    ker_diffs_p := [&+[(FFp ! k[i])*diff_forms_p[i] : i in [1..#DiffForms]] : k in killing_basis];
    valuations := [[Valuation(d, Place(pt)) : pt in rat_pts_p] : d in ker_diffs_p];

    return valuations;
end function;

function FindBadResidueClasses(residue_classes, valuations, Cp)
    bad_residues := [i : i in [1..#residue_classes] |
            forall{v : v in valuations | #residue_classes[i][2] lt v[i] + 1}];
    empty_bad_residues := [Cp ! residue_classes[i][1] : i in bad_residues | #residue_classes[i][2] eq 0];
    nonempty_bad_residues := [Cp ! residue_classes[i][1] : i in bad_residues | #residue_classes[i][2] ne 0];

    return bad_residues, empty_bad_residues, nonempty_bad_residues;
end function;

function ExpandAtBadResidueClasses(DiffForms, killing_basis, residue_classes, bad_residues)
    p := Characteristic(BaseField(Scheme(residue_classes[1][1])));

    bad_rc_logs := [];
    for b in bad_residues do
        // for now we do not deal with expansion at empty residue classes
        if #residue_classes[b][2] eq 0 then
            continue b;
        end if;

        basept := residue_classes[b][2][1];
        ker_diffs := [&+[(Integers() ! k[i])*DiffForms[i] : i in [1..#DiffForms]] : k in killing_basis];
        uni := GetGoodUniformizer(basept, p);
        diff_uni := Differential(uni);
        ker_diff_forms_funcs := [d/diff_uni : d in ker_diffs];

        Pws_Q<z> := LaurentSeriesAlgebra(pAdicField(p));
        exps := [];
        for d in ker_diff_forms_funcs do
            exp_d := ExpandWithUniformizer(d, basept, uni, z : Precision := 20);
            Append(~exps, exp_d);
        end for;
        logs := [Integral(om) : om in exps];
        Append(~bad_rc_logs, logs);
    end for; // b in bad_residues
    return bad_rc_logs;
end function;

/*
HeightBound := 100000;
NumberOfGoodPrimes := 5;
GoodPrimes := [];
DiffForms := [];
basept := 0;
uni := 0;
p := 0;
pAdicPrecision := 1;
UseReduction := true;
*/
function ChabautyColeman(C :
                            HeightBound := 100000,
                            NumberOfGoodPrimes := 5,
                            GoodPrimes := [],
                            DiffForms := [],
                            basept := 0,
                            uni := 0,
                            p := 0, // chosen prime for Chabauty Coleman
                            pAdicPrecision := 5,
                            UseReduction := true
                        )
    t1 := Cputime();

    assert IsCurve(C);
    assert IsProjective(AmbientSpace(C));
    assert IsNonsingular(C);

    // CleanCurveEqs(~C);
    SetUseReduction(~C, UseReduction);

    dim := Dimension(AmbientSpace(C));

    print "Computing genus of curve.";
    print "I am timing this:";
    time g := Genus(C);
    print "attempting Chabauty Coleman on curve of genus", g;
    assert g ge 2;

    printf "\nSearching for rational points up to height %o:\n", HeightBound;
    print "I am timing this:";

    pts := [];
    if Type(C) eq CrvHyp then
        //this is needed because the code in the else statement does not work for hyperelliptic curves
        //maybe the code in the else statement can be removed, I did not check this yet
        time pts := RationalPoints(C : Bound := HeightBound);
    else
        time pts := PointSearch(C, HeightBound);
    end if;
    printf "There are %o rational points on C.\n", #pts;
    assert #pts gt 0;

    PrintPoints(pts);

    ngp := NumberOfGoodPrimes;
    if GoodPrimes eq [] then
        GoodPrimes := FindGoodPrimes(C, ngp);
    end if;
    printf "Using the following good primes for the algorithm:%o\n", GoodPrimes;

    torsion_bound := JacobianTorsionBound(C, pts, GoodPrimes);
    print "Torsion bounds for Jacobian:", torsion_bound;

    rank, principal_gens := FindRankJacobianSubgrp(C, pts, GoodPrimes);
    try
        assert rank lt g;
    catch e
        error "ERROR: the rank of the Jacobian subgroup is greater or equal than the genus...";
    end try;

    // choose prime for Chabauty--Coleman
    if p eq 0 then
        CC_prime_idx := 1;
        p := GoodPrimes[CC_prime_idx];
    else
        CC_prime_idx := Index(GoodPrimes, p);
    end if;
    print "Good prime chosen for Chabauty-Coleman:", p;
    Cp := ReduceCurveModp(C,p);

    printf "Reduction mod %o is surjective: %o \n", p, IsReductionModpSurjective(C, pts, p);

    prec := ChoosePrecision(g,p : pAdicPrecision := pAdicPrecision);
    printf "Precision sufficient to calculate integrals to precision O(p^%o) is: %o\n",pAdicPrecision, prec;

    if not IsCoercible(C, basept) then
        basept := ChooseGoodBasept(pts, p);
    end if;
    baseptidx := Index(pts, basept);
    assert baseptidx in [1..#pts];
    printf "I chose base point P_%o = %o (reduces to non-Weierstrass point mod %o)\n", baseptidx, basept, p;

    if uni eq 0 then
        uni := GetGoodUniformizer(basept, p);
    end if;
    printf "Choosing uniformizer at the basepoint %o.\n", basept;

    print "Searching for the basis of the kernel of reduction J(Q)_known->J(F_p). I am timing this:";
    time ker_p_basis := GetKernelModp(C, pts, p, principal_gens);
    PrintKernelModp(ker_p_basis,p);

    print "Choosing basis of differential forms...";
    if #DiffForms eq 0 then
        DiffForms := GoodBasisOfDifferentials(C,p);
    else
        DiffForms := GoodBasisOfDifferentials(C,p : DiffForms := DiffForms);
    end if;
    // PrintDifferentialForms(DiffForms);

    print "Reducing each D in basis of Kernel to the form SUM(Q_i)-gQ,";
    print "and find the characteristic polynomial of the Q_i";
    print "This might take a *very* long time. Timing:";
    time charpols := GetCharpols(ker_p_basis, pts, basept, uni, p);

    /*
    print "Characteristic polynomials for the representative points of the Kernel basis:";
    PolQ<x> := PolynomialRing(Rationals());
    ctr := 1;
    charpols_out := [];
    for pol in charpols do
        Append(~charpols_out, Evaluate(pol,x));
        printf "p_%o(x) = %o \n", ctr, Evaluate(pol, x);
        ctr +:= 1;
    end for;
    */

    print "Integrating each differential form and evaluating at the basis elements of the kernel.";
    print "I am timing this:";
    time killing_basis, integration_values := BasisOfKillingForms(DiffForms, charpols, basept, uni, p : Precision := prec, targetpAdicPrecision := pAdicPrecision);

    print "These are the integration values (each row for a diff form):";
    print [[pAdicPrettyPrint(integration_values[i,j]):j in [1..Ncols(integration_values)]]
                                    : i in [1..Nrows(integration_values)]];

    PrintKillingBasis(killing_basis, DiffForms, p, pAdicPrecision);

    print "We evaluate each element in the killing forms at points of C(F_p):";
    valuations := ZerosOfKillingFormsModp(DiffForms, killing_basis, p, uni);
    print valuations;

    residue_classes := GetResidueClasses(C,pts, p);
    bad_residues, empty_bad_residues, nonempty_bad_residues := FindBadResidueClasses(residue_classes, valuations, Cp);

    t2 := Cputime(t1);
    printf "Total CPU time for Chabauty-Coleman: %o \n", t2;

    if #bad_residues eq 0 then
        print "Chabauty--Coleman procedure successful!";
        return true, pts;
    end if;

    return false, C, pts, p, basept, empty_bad_residues, nonempty_bad_residues;
end function;

function MWsieve(C, pts, p, basept, SievePrimes, EmptyBadResidues)
    GoodPrimes := [p] cat SievePrimes;

    mJknownToClprod := MapJknownToClprod(C, pts, GoodPrimes);
    imageJknownToClprod := Image(mJknownToClprod);

    mCpProdToClprod := MapCpProdToClprod(C, GoodPrimes, basept);
    cart := Domain(mCpProdToClprod);
    cart_subset := [x : x in cart | x[1] in EmptyBadResidues];
    to_intersection := [x : x in cart_subset | mCpProdToClprod(x) in imageJknownToClprod];

    return #to_intersection eq 0;
end function;


// We can try to get better expansions at the bad residue classes if they are non-empty
// logs_at_bad_residues := ExpandAtBadResidueClasses(DiffForms, killing_basis, residue_classes, bad_residues);
// return logs_at_bad_residues;
