try {
    Start-Process -FilePath "MsiExec.exe" -ArgumentList "/x `{AD1F63E4-F31F-48A2-BB8D-CF7B96CC46A0`}", "/qn" -Wait
    Start-Process -FilePath "MsiExec.exe" -ArgumentList "/x `{FFD8CF3D-3063-4D97-B007-26258E71D02F`}", "/qn" -Wait
    Start-Process -FilePath "MsiExec.exe" -ArgumentList "/x `{425786D5-8047-4CB6-AE91-0EE67BD829F8`}", "/qn" -Wait
    Start-Process -FilePath "MsiExec.exe" -ArgumentList "/x `{dc44ee3f-d6c1-444d-a660-b0f1ac90b51d`}", "/qn" -Wait
    Start-Process -FilePath "MsiExec.exe" -ArgumentList "/x `{E530ABB7-9DCC-421B-B751-484375E8374A`}", "/qn" -Wait
}
catch {
    throw "Failed to execute uninstall!"
}
