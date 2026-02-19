# 한글 깨짐 방지 세팅
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 1. 클립보드에서 원본 데이터 가져오기
$rawText = Get-Clipboard -Raw

if ([string]::IsNullOrWhiteSpace($rawText)) {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("클립보드가 비어있습니다. 엑셀/한글에서 원본을 먼저 복사(Ctrl+C)하세요.", "에러", 0, 16)
    exit
}

# 2. [출력 1] 정규표현식으로 슬래시 주변 공백 정리 (탭은 유지)
$format1 = $rawText -replace '\s*/\s*', ', '

# 3. [출력 2] 파싱 및 계급 정렬 로직
$rankWeight = @{
    "대장"=1; "중장"=2; "소장"=3; "준장"=4;
    "대령"=5; "중령"=6; "소령"=7;
    "대위"=8; "중위"=9; "소위"=10;
    "준위"=11;
    "원사"=12; "원사(진)"=13; "상사"=14; "중사"=15; "하사"=16;
    "병장"=17; "상병"=18; "일병"=19; "이병"=20
}

$allPeople = @()
$lines = $rawText -split "`r?`n" | Where-Object { $_.Trim() -ne "" }

foreach ($line in $lines) {
    $parts = $line -split "`t"
    
    if ($parts.Count -gt 0 -and $parts[0].Trim() -ne "") {
        $parts[0] -split "/" | Where-Object { $_.Trim() -ne "" } | ForEach-Object {
            $allPeople += [PSCustomObject]@{ Name = $_.Trim(); Time = "1시간" }
        }
    }
    if ($parts.Count -gt 1 -and $parts[1].Trim() -ne "") {
        $parts[1] -split "/" | Where-Object { $_.Trim() -ne "" } | ForEach-Object {
            $allPeople += [PSCustomObject]@{ Name = $_.Trim(); Time = "30분" }
        }
    }
}

function Get-Safe($idx) { if ($idx -lt $allPeople.Count) { $allPeople[$idx] } }

function Sort-ByRank($team) {
    if ($null -eq $team -or $team.Count -eq 0) { return @() }
    $team | Sort-Object -Property @{
        Expression = {
            $rank = ($_.Name -split ' ')[0]
            if ($rankWeight.ContainsKey($rank)) { $rankWeight[$rank] } else { 99 }
        }
    }
}

$t1 = Sort-ByRank (@(Get-Safe 0; Get-Safe 1; Get-Safe 5) | Where-Object { $_ })
$t2 = Sort-ByRank (@(Get-Safe 2; Get-Safe 3) | Where-Object { $_ })
$t3 = Sort-ByRank (@(Get-Safe 4; Get-Safe 6) | Where-Object { $_ })
$t4 = Sort-ByRank (@(Get-Safe 7) | Where-Object { $_ })

$out2 = @()
if ($t1) { $out2 += ($t1 | ForEach-Object { "$($_.Name) $($_.Time)" }) }
if ($t2) { $out2 += ($t2 | ForEach-Object { "$($_.Name) $($_.Time)" }) }
if ($t3) { $out2 += ($t3 | ForEach-Object { "$($_.Name) $($_.Time)" }) }
if ($t4) { $out2 += ($t4 | ForEach-Object { "$($_.Name) $($_.Time)" }) }
$format2 = $out2 -join "`r`n"

# 4. 클립보드에 다시 꽂아넣기
# (1번 아웃풋과 2번 아웃풋 사이에 줄바꿈을 넣어 구분하기 쉽게 만듦)
$finalOutput = "$format1`r`n`r`n`r`n$format2"
Set-Clipboard -Value $finalOutput

# 5. 완료 팝업창 띄우기
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show("자동 변환 및 정렬이 완료되었습니다!`n`n표에 [Ctrl + V] 로 붙여넣으세요.", "작업 완료", 0, 64)