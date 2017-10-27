Attach("remove_pcontent.m")

intrinsic ReduceRationalFunctionModp(f::FldFunFracSchElt,p::RngIntElt) -> FldFunFracSchElt
{ Reduce rational function element of function field modulo p }
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
end intrinsic;
