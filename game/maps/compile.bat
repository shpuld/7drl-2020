@echo off

cd\
cd E:\7drl\game\maps


echo Copying Files...
copy E:\7drl\game\maps\bigbox.map E:\7drl\game\maps


echo Converting map...


echo --------------QBSP--------------
E:\mapping\tools\ericw-tools-v0.18-win32\bin\qbsp.exe -bsp2 bigbox

echo --------------VIS---------------
E:\mapping\tools\ericw-tools-v0.18-win32\bin\vis.exe -fast bigbox

copy bigbox.bsp E:\7drl\game\maps
copy bigbox.pts E:\7drl\game\maps
copy bigbox.lit E:\7drl\game\maps
pause
