@echo off


::删除seed_plugins目录
rd seed_plugins /S /Q
::遍历目录,结果存至temp
dir /o:e >temp

::从遍历结果中找出文件夹,存入foldersList
find "DIR" temp > foldersList
del temp
::创建seed_plugins目录
mkdir seed_plugins

::遍历文件夹列表.将其中的文件夹.lua文件复制到seed_plugin目录.
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
del foldersList
pause>nul