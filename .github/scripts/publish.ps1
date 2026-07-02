<#
自动发布Release脚本
配合nightly.yml，完成Tag创建、旧版本清理、安装包上传
#>
param(
    [Parameter(Mandatory = $false)]
    [int]$RetainCount = 15
)

# 基础变量
$RepoRoot = $PSScriptRoot | Split-Path -Parent
$ArtifactsDir = Join-Path $RepoRoot "artifacts"
$DateTag = "nightly-$(Get-Date -Format 'yyyy.MM.dd')"
$ReleaseTitle = "PowerToys Nightly Build $(Get-Date -Format 'yyyy-MM-dd')"
$CommitSha = $env:GITHUB_SHA

Write-Host "===== Nightly Release Publish ====="
Write-Host "Tag Name: $DateTag"
Write-Host "Retain Latest $RetainCount Nightly Releases"
Write-Host "Artifact Path: $ArtifactsDir"
Write-Host "==================================="

# 检查产物文件夹是否存在
if (-not (Test-Path $ArtifactsDir)) {
    Write-Error "构建产物目录不存在：$ArtifactsDir"
    exit 1
}
$pkgFiles = Get-ChildItem "$ArtifactsDir\*" -Include *.exe,*.msi
if ($pkgFiles.Count -eq 0) {
    Write-Error "目录内无exe/msi安装包，终止发布"
    exit 1
}

# 拉取全部Release列表
$allReleases = gh release list --limit 100 --json tagName,id | ConvertFrom-Json
# 筛选所有nightly版本
$nightlyList = $allReleases | Where-Object { $_.tagName -match "^nightly-\d{4}\.\d{2}\.\d{2}$" }
# 超出保留数量的旧版本删除
$needDelete = $nightlyList | Select-Object -Skip $RetainCount
foreach ($release in $needDelete) {
    Write-Host "删除过期Nightly: $($release.tagName) (ID:$($release.id))"
    gh release delete $release.tagName -y
}

# 拼接更新日志
$releaseNotes = @"
## 构建信息
- 源码提交哈希: $CommitSha
- 构建时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
- 编译平台: x64 Release
- 自动同步上游 microsoft/PowerToys main 分支

## 包含文件
$($pkgFiles.Name -Join "`n")
"@

# 创建预发布Release并上传安装包
gh release create $DateTag `
    --title "$ReleaseTitle" `
    --prerelease `
    --notes "$releaseNotes" `
    $pkgFiles.FullName

Write-Host "Release $DateTag 创建上传完成！"
exit 0
