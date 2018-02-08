/* TODO: Brute reduction might fail if coefficients are not integers */ 

intrinsic ReduceCurveModp(C::Crv,p::RngIntElt : saturate := true) -> Crv
{Reduce curve modulo p. This function also caches the reduced curve Cp in the curve C}
    assert IsCurve(C);
    assert IsPrime(p);

    if not Type(C) eq CrvHyp and saturate then
        Cp := Curve(Reduction(C, p)); // Reduction uses saturation 
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

    return Cp;
end intrinsic;

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

