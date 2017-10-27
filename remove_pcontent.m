intrinsic pContentModI(F, p, I)
{Return pPrimitive part and pContent of the multivariate polynomial F modulp ideal I}
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
end intrinsic;
