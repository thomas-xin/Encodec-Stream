if "%~1"=="" (
	for /f "delims=" %%I in ('powershell -Command "Add-Type -AssemblyName System.Windows.Forms; $dialog = New-Object System.Windows.Forms.OpenFileDialog; $dialog.InitialDirectory = 'C:\\'; $result = $dialog.ShowDialog(); if ($result -eq [System.Windows.Forms.DialogResult]::OK) { $dialog.FileName }"') do (
		py ecdc_stream.py -d "%%I" | ffplay -f s16le -ac 2 -ar 48k -i -
	)
) else (
	py ecdc_stream.py %2 %3 %4 %5 -d %1 | ffplay -f s16le -ac 2 -ar 48k -i -
)