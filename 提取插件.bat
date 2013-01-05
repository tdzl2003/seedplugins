@echo off

::遍历目录,结果存至temp
dir /o:e >temp

::从遍历结果中找出文件夹,存入foldersList
find "DIR" temp > foldersList
del temp
::删除seed_plugins目录下所有文件

rd seed_plugins /S /Q
mkdir seed_plugins
for /f "skip=5 tokens=3* " %%a in (foldersList) do (
	cd %%b 
	dir /o:e > plugins
	::从文件夹中寻找.lua文件
	find ".lua" plugins > fileList 
	del plugins
	::拷贝相应文件至seed_plugins目录同名文件
	for /f "skip=1 tokens=3* " %%c in (fileList) do (
		copy %%d ..\seed_plugins\%%d
	)
	del fileList
	cd ..
)

del foldersList

pause>nul