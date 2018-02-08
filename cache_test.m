load "cache.m";

//This file tests the functionality of the functions in cache.m

QQ := Rationals();
assert not IsCached(QQ,"test");
assert not IsArrayCached(QQ,"test",2);

InitiateArrayCache(QQ,"test");
assert IsCached(QQ,"test");
assert Type(GetCache(QQ,"test")) eq Assoc;
assert not IsArrayCached(QQ,"test",2);

SetArrayCache(QQ,"test",2,"I exist!");
assert Type(GetCache(QQ,"test")) eq Assoc;
assert not IsArrayCached(QQ,"test",3);
assert IsArrayCached(QQ,"test",2);
assert GetArrayCache(QQ,"test",2) eq "I exist!";

QQ := Rationals();
assert not IsCached(QQ,"test2");
assert not IsArrayCached(QQ,"test2",2);

SetArrayCache(QQ,"test2",2,"I exist!");
assert IsCached(QQ,"test2");
assert Type(GetCache(QQ,"test2")) eq Assoc;
assert not IsArrayCached(QQ,"test2",3);
assert IsArrayCached(QQ,"test",2);
assert GetArrayCache(QQ,"test",2) eq "I exist!";
