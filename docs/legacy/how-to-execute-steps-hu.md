<!-- documentation-anchors:start -->
<a id="doc-how-to-execute-steps"></a>
<!-- documentation-anchors:end -->
# Lépések végrehajtása

<!-- documentation-navigation -->
[English](how-to-execute-steps.md) | [Magyar](how-to-execute-steps-hu.md) · [Dokumentáció](../README-hu.md) · [Projekt](../../README-hu.md)
<!-- /documentation-navigation -->

Egy forgatókönyv általában több lépésből áll, de ez nem kötelező: létrehozható egyetlen lépésből álló forgatókönyv is. A lépések közvetlenül is végrehajthatók, csak arra kell figyelni, hogy a lépés és a forgatókönyv neve eltérjen. Ha a végrehajtó nem talál futtatható forgatókönyvet a megadott névvel (-Plot x), azonos nevű lépést keres, és a megtaláltat végrehajtja. Korábban a Plot paraméter más nevet viselt és kevésbé volt kétértelmű, ezért később talán különválik ez a két lehetőség, vagy megszűnik a közvetlen végrehajtás. Egyelőre azonban hasznosnak tűnik: ez a logika indítja el a folyamatot, és szükség esetén visszatérési értéket biztosít a hívónak.
