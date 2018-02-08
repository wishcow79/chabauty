load "pcontent.m";
load "curve_funcs.m";

// load "curve_funcs.m";

/*

This file is dedicated to all functions that relate to function fields of curves, including differentials.

TODO: improve comments.
TODO: the line "reduce coordinate ring of curve modulo p" might crash if there are p-s in the denominator

*/


// function SaturatedIdealOfCurveAtPrime(C,p)

//     if "SaturatedIdeal" in GetAttributes(Type(C)) and
//         assigned C`SaturatedIdeal and
//         IsDefined(C`SaturatedIdeal, p) then
//             return C`SaturatedIdeal[p];
//     end if;

//     if not "SaturatedIdeal" in GetAttributes(Type(C)) then
//         AddAttribute(Type(C), "SaturatedIdeal");
//     end if;

//     if not assigned C`SaturatedIdeal then
//         C`SaturatedIdeal := [];
//     end if;

//     I := Ideal(C);
//     basisI := [ClearDenominators(b) : b in Basis(I)];
//     I := Ideal(basisI);

//     ambR := CoordinateRing(Ambient(C));
//     ambRZ := ChangeRing(ambR, Integers());
//     IZ := Ideal([ambRZ ! b:b in basisI]);
//     IZsat := Saturation(IZ, ambRZ ! p);

// //    C`SaturatedIdeal[p] := IZsat;

//     return IZsat;
// end function;


/*
Given a rational function with integer coefficients, we want to reduce the function mod p,
to the function field of the curve modulo p.
TODO: the functions currently only work well with projective curves, 
      otherwise if affine the function Curve(FF) will return a different curve each time it is called.

To do this we reduce the numerator and denominator modulo the curve ideal, 
we then need to reduce the fraction by the highest p-power before reducing modulo p.
Uses external functions:
* ReduceCurveModp
* pContentModI
*/

// intrinsic ReduceRationalFunctionModp(f::FldFunFracSchElt,p::RngIntElt) -> FldFunFracSchElt
// { Reduce rational function element of function field modulo p}
function ReduceRationalFunctionModp(f,p)
    assert IsPrime(p);

    FF := Parent(f); // The function field of the function f
    C := Curve(FF);  // The curve defining the function field. CAREFUL: This function does not return the original curve C if C is not projective!

    R := CoordinateRing(C);
    I := Ideal(C);
    basisI := [ClearDenominators(b) : b in Basis(I)]; // make sure that coefficients of the basis of I are integers
    I := Ideal(basisI);

    ambR := CoordinateRing(Ambient(C));
    ambRp := ChangeRing(ambR, GF(p)); // reduce coordinate ring of curve modulo p

//    IZsat := SaturatedIdealOfCurveAtPrime(C,p);
//    ambRZ := Generic(IZsat);

    I := Ideal(C);
    basisI := [ClearDenominators(b) : b in Basis(I)];
    ambRZ := ChangeRing(ambR, Integers());
    IZ := Ideal([ambRZ ! b:b in basisI]); // TODO: We assume that the ideal IZ is saturated at p!

    Cp := ReduceCurveModp(C,p);
    FFp := FunctionField(Cp);
    Ip := Ideal(Cp);
    basisIp := Basis(Ip);
    Ip := Ideal([ambRp ! b : b in basisIp]);
    Rp<[a]> := CoordinateRing(Ambient(Cp));

    num1, den1 := IntegralSplit(f,C); // num and den are in ambR, this function is VERY SLOW :(

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

    coeff_num5,num5 := pContentModI(num4, p, IZ);

    if den4p in Ip then
        coeff_den5, den5 := pContentModI(den4, p, IZ);
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

// intrinsic ReduceDifferentialModp(d::DiffCrvElt, p::RngIntElt, uni::FldFunFracSchElt) -> DiffCrvElt
// {returns reduction of differential mod p}
function ReduceDifferentialModp(d, p, uni)
    C := Curve(d);
    du := Differential(uni);
    f := d / du;
    f_p := ReduceRationalFunctionModp(f,p);
    uni_p := ReduceRationalFunctionModp(uni, p);
    duni_p := Differential(uni_p);
    return f_p * duni_p;
end function;

// intrinsic ValuationOfRationalFunction(f::FldFunFracSchElt,p::RngIntElt) -> RngIntElt
// {returns valuation of a rational function of a curve at a prime p}
function ValuationOfRationalFunction(f,p)
    FF := Parent(f);
    C := Curve(FF);

//    IZsat := SaturatedIdealOfCurveAtPrime(C,p);
//    ambRZ := Generic(IZsat);

    ambR := CoordinateRing(Ambient(C));
    I := Ideal(C);
    basisI := [ClearDenominators(b) : b in Basis(I)];
    ambRZ := ChangeRing(ambR, Integers()); 
    IZ := Ideal([ambRZ ! b:b in basisI]); // TODO: We assume that the ideal IZ is saturated at p!

    num1, den1 := IntegralSplit(f,C); // num and den are in ambR

    num2, lcd_num1 := ClearDenominators(num1);
    den2, lcd_den1 := ClearDenominators(den1);

    num3 := ambRZ ! num2;
    den3 := ambRZ ! den2;

    content_num3, num4 := ContentAndPrimitivePart(num3);
    content_den3, den4 := ContentAndPrimitivePart(den3);

    coeff_num5, num5 := pContentModI(num4, p, IZ);
    coeff_den5, den5 := pContentModI(num5, p, IZ);

    coeff := (lcd_den1 * content_num3 * coeff_num5) / (lcd_num1 * content_den3 * coeff_den5);
    v := Valuation(coeff,p);

    return v;
end function;

