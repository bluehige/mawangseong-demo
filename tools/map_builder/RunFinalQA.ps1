param([string]$OutputRoot='tmp/v130_qa/regression',[string[]]$Only=@())
$ErrorActionPreference='Stop'
$taskRoot=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$taskCases=@()
foreach ($taskScene in @(
    'V1213StageOneTest','V1213S1FollowupTest','V1213StageTwoTest',
    'V1213U5ATest','V1213U5BTest','V1213U5CTest','V1213U5DTest','V1213U5ETest','V1213U5FTest','V1213PerfFreezeTest',
    'V130AutoRoadTest','V130MapIntegrationTest','V130CombatMapTest','V130SavePlotTest',
    'SaveV5MigrationTest','EnglishTranslationTest','ChineseLocalizationTest','V122Stage10LocalizationTest',
    'Update4ReleaseCandidatePhase36Test','Update4DataContractTest','CampaignModePhase3Test',
    'UpperFloorObjectivesPhase11Test','Update4EndingsPhase32Test','Update4EndingsPhase33Test',
    'OutpostTypesPhase9Test','PopoCombatPhase15Test','VesperBossPhase23Test',
    'CrownFacilityRecoveryTest','CrownMobilityRecoveryTest','BasicSupportRecoveryTest','EchoObjectiveRecoveryTest',
    'Update4ChronicleAccessibilityPhase35Test','CombatAudioDirectorRoutingTest','V122ManagementUIContractTest','Update4WorldArtPhase34Test',
    'V130RouteTimingTest')) {
    $taskCases+=@{Id=$taskScene;Scene=$taskScene;Gui=$false;Resolution='1920x1080';Args=@()}
}
$taskCases+=@{Id='M1_1280';Scene='V130MapIntegrationTest';Gui=$true;Resolution='1280x720';Args=@()}
$taskCases+=@{Id='M2_DAY12';Scene='V130CombatMapTest';Gui=$false;Resolution='1920x1080';Args=@('--day=12')}
$taskCases+=@{Id='M3_mouse';Scene='V130PlacementTest';Gui=$true;Resolution='1920x1080';Args=@()}
$taskCases+=@{Id='M3_touch';Scene='V130PlacementTest';Gui=$true;Resolution='1920x1080';Args=@('--mobile-touch-ui')}
$taskCases+=@{Id='M4_direct';Scene='V130DecorationTest';Gui=$false;Resolution='1920x1080';Args=@('--checks-only')}
$taskCases+=@{Id='M4_GUI';Scene='V130DecorationTest';Gui=$true;Resolution='1920x1080';Args=@()}
$taskCases+=@{Id='M4_projection';Scene='V130PlotProjectionTest';Gui=$true;Resolution='1920x1080';Args=@()}
$taskCases+=@{Id='M5_mouse';Scene='V130SpectatorTest';Gui=$true;Resolution='1920x1080';Args=@()}
$taskCases+=@{Id='M5_touch';Scene='V130SpectatorTest';Gui=$true;Resolution='1920x1080';Args=@('--mobile-touch-ui')}
$taskCases+=@{Id='U5C_touch';Scene='V1213U5CTest';Gui=$true;Resolution='1920x1080';Args=@('--mobile-touch-ui')}
$taskCases+=@{Id='Council1F_GUI';Scene='V130Council1FTest';Gui=$true;Resolution='1920x1080';Args=@()}
$taskResults=@()
New-Item -ItemType Directory -Force (Join-Path $taskRoot $OutputRoot) | Out-Null
foreach ($taskCase in $taskCases) {
    if ($Only.Count -and $taskCase.Id -notin $Only) { continue }
    $taskStarted=Get-Date
    $taskResult='PASS'; $taskFailure=''
    $taskCaseRoot="$OutputRoot/$($taskCase.Id)"
    $taskParameters=@{Scene=$taskCase.Scene;OutputRoot=$taskCaseRoot;Resolution=$taskCase.Resolution;TimeoutSeconds=300;ExtraArgs=@("--output-dir=res://$taskCaseRoot/results")+$taskCase.Args}
    if ($taskCase.Gui) { $taskParameters.Gui=$true }
    Write-Output "QA_START $($taskCase.Id)"
    try { & (Join-Path $PSScriptRoot 'RunV130.ps1') @taskParameters }
    catch { $taskResult='FAIL'; $taskFailure=$_.Exception.Message; Write-Output "QA_FAIL $($taskCase.Id): $taskFailure" }
    $taskLog="$taskCaseRoot/$($taskCase.Scene)-$($taskCase.Resolution)/run.log"
    $taskLines=@(Get-Content -LiteralPath (Join-Path $taskRoot $taskLog) -Encoding UTF8 -ErrorAction SilentlyContinue)
    $taskSummary=@($taskLines | Where-Object { $_ -match 'PASS|checks=|failures=|TEST:' } | Select-Object -Last 2) -join ' | '
    $taskResults+=[pscustomobject]@{Id=$taskCase.Id;Scene=$taskCase.Scene;Result=$taskResult;Seconds=[Math]::Round(((Get-Date)-$taskStarted).TotalSeconds,2);Summary=$taskSummary;Log=$taskLog;Error=$taskFailure}
    $taskResults | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $taskRoot "$OutputRoot/results.json") -Encoding UTF8
    $taskResults | Export-Csv -LiteralPath (Join-Path $taskRoot "$OutputRoot/results.csv") -NoTypeInformation -Encoding UTF8
    Write-Output "QA_DONE $($taskCase.Id) $taskResult ($($taskResults.Count) completed)"
}
$taskFailed=@($taskResults | Where-Object Result -eq 'FAIL')
Write-Output "FINAL_QA cases=$($taskResults.Count) failed=$($taskFailed.Count)"
if ($taskFailed.Count) { throw 'Final QA contains failed cases; inspect results.json.' }
