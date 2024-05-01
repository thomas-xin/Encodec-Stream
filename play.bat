if "%~1"=="" (
	setlocal EnableDelayedExpansion
	for /f "delims=" %%I in ('powershell -Command "Add-Type -AssemblyName System.Windows.Forms; $dialog = New-Object System.Windows.Forms.OpenFileDialog; $dialog.InitialDirectory = 'C:\\'; $dialog.Filter = 'Encoded files (*.ecdc)|*.ecdc|All files (*.*)|*.*'; $result = $dialog.ShowDialog(); if ($result -eq [System.Windows.Forms.DialogResult]::OK) { $dialog.FileName } else { '' }"') do set "SelectedFile=%%I"
	if not "!SelectedFile!"=="" (
		py %~dp0/ecdc_stream.py -d "!SelectedFile!" | ffplay -f s16le -ac 2 -ar 48k -i -
	) else (
		echo No file selected, exiting.
	)
	endlocal
) else (
	py %~dp0/ecdc_stream.py %2 %3 %4 %5 -d %1 | ffplay -f s16le -ac 2 -ar 48k -i -
)