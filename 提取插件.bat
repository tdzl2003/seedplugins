@echo off

::遍历目录,结果存至temp
rd seed_plugins /S /Q
dir /o:e >temp

::从遍历结果中找出文件夹,存入foldersList

find "DIR" temp > foldersList
del temp
::删除seed_plugins目录下所有文件


mkdir seed_plugins
for /f "skip=4 tokens=3* " %%a in (foldersList) do (
	cd %%b 
	dir /o:e > plugins
	find ".lua" plugins > fileList 
	find "DIR" plugins > folder
	del plugins
	for /f "skip=1 tokens=3* " %%c in (fileList) do (
		copy %%d ..\seed_plugins\%%d
	)
	for /f "skip=1 tokens=3* " %%c in (folder) do (
		if not %%d == .. (
			if not %%d == . (
					echo %%d
					xcopy %%d ..\seed_plugins\%%d /i
				)
			)
	)
	del fileList
	del folder
	cd ..
)

pause>nul