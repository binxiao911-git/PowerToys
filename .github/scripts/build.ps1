<#
PowerToys CI 辅助构建封装脚本
作用：统一封装编译、产物整理逻辑，供 workflow 调用
#>
param(
    [Parameter(Mandatory = $false)]
    [string]$Platform = "x64",

    [Parameter(Mandatory = $false)]
    [string]$Config = "Release",

    [Parameter(Mandatory = $false)]
    [bool]$CI = $true
)

# 根目录定位
$RepoRoot = $PSScriptRoot | Split-Path -Parent
$BuildScript = Join-Path $RepoRoot "tools\build\build-installer.ps1"
$ArtifactsDir = Join-Path $RepoRoot "artifacts"

Write-Host "====================================="
Write-Host "Repo Root: $RepoRoot"
Write-Host "Platform: $Platform | Config: $Config"
Write-Host "CI Mode: $CI"
Write-Host "====================================="

# 清理旧产物
if(Test-Path $ArtifactsDir) {
    Remove-Item $ArtifactsDir -Recurse -Force
}
New-Item -Path $ArtifactsDir -ItemType Directory -Force | Out-Null

# 执行官方构建脚本
& $BuildScript -Platform $Platform -Configuration $Config -CIBuild $CI
if($LASTEXITCODE -ne 0) {
    Write-Error "官方构建脚本执行失败，退出码 $LASTEXITCODE"
    exit $LASTEXITCODE
}

# 复制安装包到统一产物目录
$SetupPath = Join-Path $RepoRoot "installer\PowerToysSetupVNext\$Platform\$Config\MachineSetup"
Copy-Item (Join-Path $SetupPath "*.exe") $ArtifactsDir -Force
Copy-Item (Join-Path $SetupPath "*.msi") $ArtifactsDir -Force

Write-Host "构建完成，产物输出至：$ArtifactsDir"
Get-ChildItem $ArtifactsDir
exit 0
