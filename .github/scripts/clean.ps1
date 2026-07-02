<#
构建清理脚本
清理构建中间文件、产物、缓存，用于CI前置清理或本地手动清理
#>
param()

$RepoRoot = $PSScriptRoot | Split-Path -Parent
Write-Host "开始清理仓库，根目录：$RepoRoot"

# 1. 删除构建产物目录
$artifacts = Join-Path $RepoRoot "artifacts"
if (Test-Path $artifacts) {
    Remove-Item $artifacts -Recurse -Force
    Write-Host "已删除产物目录 artifacts"
}

# 2. 删除项目各平台编译输出目录 bin / obj
Get-ChildItem -Path $RepoRoot -Directory -Recurse -Include bin, obj | ForEach-Object {
    Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "清理编译目录: $($_.FullName)"
}

# 3. 删除安装包工程临时输出
$installerOut = Join-Path $RepoRoot "installer\PowerToysSetupVNext\x64"
if (Test-Path $installerOut) {
    Get-ChildItem -Path $installerOut -Directory -Include Debug, Release | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "清理安装包编译输出"
}

# 4. 清理NuGet缓存（CI环境可选）
if ($env:CI -eq "true") {
    dotnet nuget locals all --clear
    Write-Host "已清空NuGet本地缓存"
}

Write-Host "全部清理操作执行完毕"
exit 0
