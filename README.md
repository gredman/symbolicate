# symbolicate

A simple tool to symbolicate iOS JSON crash reports. These reports can be found on the device under Settings > Privacy > Analytic & Improvements > Analytics Data and have the file extension `.ips`. Symbols are derived from dSYM symbols packages using `atos`.

## Usage

> symbolicate --report MyApp-YYYY-MM-DD-hhmmss.ips --symbols MyApp.dSYM MyAppExtension.dSYM ... --output symbolicated.ips
