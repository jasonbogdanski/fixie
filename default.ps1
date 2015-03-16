Framework '4.0'

properties {
    $birthYear = 2013
    $maintainers = "Patrick Lioi"

    $configuration = 'Release'
	$platform64 = 'x64'
	$platformAny = 'Any CPU'
	$base_dir = Resolve-Path .
    $src = combine_path @($base_dir, "src")
	$buildPath = combine_path @($base_dir, "build")
    $build = if ($env:build_number -ne $NULL) { $env:build_number } else { '0' }
    $version = [IO.File]::ReadAllText('.\VERSION.txt') + '.' + $build
    $projects = @(gci $src -rec -filter *.csproj)
    $selfTestProjects = "Fixie.Tests","Fixie.Samples"
}

task default -depends Test

task Package -depends Test {
    rd .\package -recurse -force -ErrorAction SilentlyContinue | out-null
    mkdir .\package -ErrorAction SilentlyContinue | out-null
    exec { & $src\.nuget\NuGet.exe pack $src\Fixie\Fixie.csproj -Symbols -Prop Configuration=$configuration -OutputDirectory .\package }

    write-host
    write-host "To publish these packages, issue the following command:"
    write-host "   nuget push .\package\Fixie.$version.nupkg"
}

task Test -depends Compile {
    Write-Host -ForegroundColor Yellow "Running tests against Any CPU build"
    $fixieRunner = combine_path @($buildPath, "Fixie.Console.exe")
	run-unit-tests $fixieRunner
	
	Write-Host -ForegroundColor Yellow "Running tests against x64 build"
	$fixie64Runner = combine_path @($buildPath, "Fixie.Console.x64.exe")
	run-unit-tests $fixie64Runner
}

task Compile -depends SanityCheckOutputPaths, AssemblyInfo, License {
  rd .\build -recurse -force  -ErrorAction SilentlyContinue | out-null
  compile-source $configuration $platform64 
  
  $fixie64Runner = combine_path @($buildPath, "Fixie.Console.exe")
  rni $fixie64Runner "Fixie.Console.x64.exe"
  $fixie64Config = combine_path @($buildPath,"Fixie.Console.exe.config")
  rni $fixie64Config "Fixie.Console.x64.exe.config"
  
  compile-source $configuration $platformAny
}

task SanityCheckOutputPaths {
    $blankLine = ([System.Environment]::NewLine + [System.Environment]::NewLine)
    $expectedPath = "..\..\build\"

    foreach ($project in $projects) {
        $projectName = [System.IO.Path]::GetFileNameWithoutExtension($project)

        $lines = [System.IO.File]::ReadAllLines($project.FullName, [System.Text.Encoding]::UTF8)

        if (!($selfTestProjects -contains $projectName)) {
            foreach($line in $lines) {
                if ($line.Contains("<OutputPath>")) {

                    $outputPath = [regex]::Replace($line, '\s*<OutputPath>(.+)</OutputPath>\s*', '$1')

                    if($outputPath -ne $expectedPath){
                        $summary = "The project '$projectName' has a suspect *.csproj file."
                        $detail = "Expected OutputPath to be $expectedPath for Any CPU configurations"

                        Write-Host -ForegroundColor Yellow "$($blankLine)$($summary)  $($detail)$($blankLine)"
                        throw $summary
                    }
                }
            }
        }
    }
}

task AssemblyInfo {
    $copyright = get-copyright

    foreach ($project in $projects) {
        $projectName = [System.IO.Path]::GetFileNameWithoutExtension($project)

        regenerate-file "$($project.DirectoryName)\Properties\AssemblyInfo.cs" @"
using System.Reflection;
using System.Runtime.InteropServices;

[assembly: ComVisible(false)]
[assembly: AssemblyProduct("Fixie")]
[assembly: AssemblyTitle("$projectName")]
[assembly: AssemblyVersion("$version")]
[assembly: AssemblyFileVersion("$version")]
[assembly: AssemblyCopyright("$copyright")]
[assembly: AssemblyCompany("$maintainers")]
[assembly: AssemblyConfiguration("$configuration")]
"@
    }
}

task License {
    $copyright = get-copyright

    regenerate-file "LICENSE.txt" @"
The MIT License (MIT)
$copyright

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
"@
}

function get-copyright {
    $date = Get-Date
    $year = $date.Year
    $copyrightSpan = if ($year -eq $birthYear) { $year } else { "$birthYear-$year" }
    return "Copyright © $copyrightSpan $maintainers"
}

function regenerate-file($path, $newContent) {
    $oldContent = [IO.File]::ReadAllText($path)

    if ($newContent -ne $oldContent) {
        $relativePath = Resolve-Path -Relative $path
        write-host "Generating $relativePath"
        [System.IO.File]::WriteAllText($path, $newContent, [System.Text.Encoding]::UTF8)
    }
}

function combine_path([string[]]$paths) {
    [System.IO.Path]::GetFullPath(([System.IO.Path]::Combine($paths)))
}

function compile-source($config, $platform) {
	Write-Host -ForegroundColor Yellow "Compiling source as $config and platform $platform"
    exec { msbuild /t:clean /v:q /nologo /p:Configuration=$config /p:Platform=$platform $src\Fixie.sln }
	exec { msbuild /t:build /v:q /nologo /p:Configuration=$config /p:Platform=$platform $src\Fixie.sln }
}

function run-unit-tests($fixieRunner) {
	exec { & $fixieRunner $src\Fixie.Tests\bin\$configuration\Fixie.Tests.dll $src\Fixie.Samples\bin\$configuration\Fixie.Samples.dll }
}