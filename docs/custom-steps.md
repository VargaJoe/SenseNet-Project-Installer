# Custom Step deklaráció 

Ahhoz hogy a fenti automatizmus működhessen, illetve testzőleges lépésekkel lehessen kiegészíteni a lépésnek az alábbi módon kell felépülnie:

```powershell
Function Step-Lepesneve {
<#
.SYNOPSIS
Lépés rövid leírása
.DESCRIPTION
lépés leírásának bővebb kifejtése
#>
[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[parameter(Mandatory=$false)]
[String]$section="Project"
)

try {
$ProjectSiteName = $GlobalSettings."$section".WebAppName
& "$ScriptBaseFolderPath\Ops\Stop-IISSite.ps1" $ProjectSiteName
$script:Result = $LASTEXITCODE
}
catch {
$script:Result = 1
}
}
```

A fenti példában a lépés közvetlenül meghívható a Run-on keresztül, ha nincs azonos nevű forgatókönyv:
```powershell
.\Run.ps1 lepesneve
```

vagy bővebben (itt ne tévesszen meg, hogy a paraméter neve plot):
```powershell
.\Run.ps1 -Plot lepesneve -Settings local
```

Az adott lépés futtatáskor a script leírásából megjelenítjük a synopsys részt, valahogy így:

```console
================================================
============= Plotneve/Lepesneve =============
================================================
Synopsis: Lépés rövid leírása
Progress: 100
```

A descriptiont érdemes a jövő felhasználói számára kitölteni, illetve itt használható egyéb komment lehetőség is. Ezek a Get-Help powershell függvénnyel hívhatók elő.

A következő paraméter biztosítja a step számára, hogy megcímezhető legyen a beállítás szekció. Példánkban a default szekció a "Project". Ha a lépés nem igényli, nem kötelező deklarálni, de azt vegyük figyelembe, hogy ha Section paraméterrel érkezik a hívás, a lépés hibát fog dobni.
```powershell
[CmdletBinding(SupportsShouldProcess=$True)]
Param(
[parameter(Mandatory=$false)]
[String]$section="Project"
)
```

Az üzleti logikát érdemes try/cacth feldolgozásba rakni, így biztosítható, hogy hiba esetén is legyen visszaadott érték. Általános hiba esetén megegyezés szerint 1-es értékkel térünk vissza. Ettől el lehet térni, tudomásom szerint - még - nem használja semmi a visszatérési értékeket, egyelőre csak információforrásként utazik.

A settings file beállításokat a section paraméterrel együtt egy globális változóból érjük el. Ebben már össze van fűzve a projekt és default beállítás is.
```powershell
$GlobalSettings."$section".beállításnév
```

Végül érdemes normál lefutás esetén a exitcode környezeti változó értékével visszatérni. Console applikációk esetén valószínűleg ez megfelelő értéket fog adni, egyedi scriptek esetén érdemes emulálni:
```powershell
$script:Result = $LASTEXITCODE
```