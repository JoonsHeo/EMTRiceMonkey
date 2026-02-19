```<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <title>통제대 인원 편성 파싱 툴 v3.0</title>
    <style>
        body { font-family: 'Malgun Gothic', sans-serif; padding: 20px; background-color: #f4f7f6; }
        .container { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1); max-width: 700px; margin: auto; }
        label { font-weight: bold; color: #2c3e50; }
        textarea { width: 100%; height: 100px; padding: 10px; margin-top: 10px; border: 1px solid #ccc; border-radius: 4px; resize: vertical; box-sizing: border-box; }
        .main-btn { background-color: #27ae60; color: white; border: none; padding: 12px; font-size: 16px; border-radius: 4px; cursor: pointer; font-weight: bold; width: 100%; margin: 20px 0; }
        .main-btn:hover { background-color: #2ecc71; }
        
        .output-box { margin-bottom: 20px; background: #eee; padding: 15px; border-radius: 4px; }
        .header-area { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; }
        h3 { margin: 0; color: #2c3e50; font-size: 16px; }
        .copy-btn { background-color: #3498db; color: white; border: none; padding: 5px 10px; border-radius: 4px; cursor: pointer; font-size: 13px; font-weight: bold; }
        .copy-btn:hover { background-color: #2980b9; }
        
        .result-area { width: 100%; padding: 10px; border: 1px solid #ccc; background-color: #fff; box-sizing: border-box; resize: vertical; font-family: 'Malgun Gothic', sans-serif; white-space: pre-wrap; }
    </style>
</head>
<body>

<div class="container">
    <h2>🛠️ 통제대 맞춤형 인원 파싱 & 정렬기 (v3.0)</h2>
    
    <label for="inputData">📥 원본 데이터 한 번에 붙여넣기 (탭 포함)</label>
    <textarea id="inputData" placeholder="예시:&#10;원사 이름1/ 중위 이름 2&#10;원사(진) 이름3/ 대위 이름4/ 소위 이름5    병장 이름6/ 소위 이름7/ 중령 이름8"></textarea>

    <button class="main-btn" onclick="processData()">자동 변환 및 팀 편성 실행 🚀</button>

    <div class="output-box">
        <div class="header-area">
            <h3>출력 1. 쉼표 구분 (원본 형태 유지)</h3>
            <button class="copy-btn" onclick="copyToClipboard('output1')">📋 복사하기</button>
        </div>
        <textarea id="output1" class="result-area" readonly style="height: 100px;"></textarea>
    </div>

    <div class="output-box">
        <div class="header-area">
            <h3>출력 2. 팀별 계급 정렬 및 시간 부여</h3>
            <button class="copy-btn" onclick="copyToClipboard('output2')">📋 복사하기</button>
        </div>
        <textarea id="output2" class="result-area" readonly style="height: 250px;"></textarea>
    </div>
</div>

<script>
    // 공군 전체 계급 서열 딕셔너리 (중령, 대령 등 추가 완료)
    const rankWeight = {
        "대장": 1, "중장": 2, "소장": 3, "준장": 4,
        "대령": 5, "중령": 6, "소령": 7,
        "대위": 8, "중위": 9, "소위": 10,
        "준위": 11,
        "원사": 12, "원사(진)": 13, "상사": 14, "중사": 15, "하사": 16,
        "병장": 17, "상병": 18, "일병": 19, "이병": 20
    };

    function sortByRank(teamArray) {
        return teamArray.sort((a, b) => {
            let rankA = a.name.split(" ")[0];
            let rankB = b.name.split(" ")[0];
            let weightA = rankWeight[rankA] || 99;
            let weightB = rankWeight[rankB] || 99;
            return weightA - weightB; // 숫자가 작을수록(높은 계급) 위로 올라감
        });
    }

    function processData() {
        const rawText = document.getElementById("inputData").value;
        if (!rawText.trim()) return;

        // ==========================================
        // [출력 1] 정규표현식으로 슬래시(/)와 주변 공백만 ', '로 치환
        // 탭(\t)과 줄바꿈(\n)은 절대 건드리지 않음
        // ==========================================
        const format1 = rawText.replace(/ *\/ */g, ", ");
        document.getElementById("output1").value = format1;

        // ==========================================
        // [출력 2] 탭을 기준으로 1시간 / 30분 판별 및 파싱
        // ==========================================
        let allPeople = [];
        let lines = rawText.split("\n");

        for (let line of lines) {
            if (!line.trim()) continue; // 빈 줄 무시

            // 한 줄 안에서 탭(\t)을 기준으로 좌/우 분리
            let parts = line.split("\t");
            
            // 1. 탭 왼쪽 그룹 (1시간)
            if (parts[0]) {
                let leftGroup = parts[0].split("/").map(s => s.trim()).filter(Boolean);
                leftGroup.forEach(p => allPeople.push({ name: p, time: "1시간" }));
            }
            
            // 2. 탭 오른쪽 그룹 (30분)
            if (parts[1]) {
                let rightGroup = parts[1].split("/").map(s => s.trim()).filter(Boolean);
                rightGroup.forEach(p => allPeople.push({ name: p, time: "30분" }));
            }
        }

        // 인덱스 매핑 (결원 발생 시 에러 방지를 위해 filter(Boolean) 유지)
        let t1 = [allPeople[0], allPeople[1], allPeople[5]].filter(Boolean);
        let t2 = [allPeople[2], allPeople[3]].filter(Boolean);
        let t3 = [allPeople[4], allPeople[6]].filter(Boolean);
        let t4 = [allPeople[7]].filter(Boolean);

        // 각 팀별로 계급 정렬
        t1 = sortByRank(t1);
        t2 = sortByRank(t2);
        t3 = sortByRank(t3);
        t4 = sortByRank(t4);

        // 모든 팀을 하나의 배열로 합친 뒤, "이름 시간" 형태로 변환
        let sortedAll = [...t1, ...t2, ...t3, ...t4];
        let output2Text = sortedAll.map(p => `${p.name} ${p.time}`).join("\n");

        document.getElementById("output2").value = output2Text;
    }

    function copyToClipboard(elementId) {
        const copyText = document.getElementById(elementId);
        if(!copyText.value) {
            alert("먼저 변환을 실행해주세요!");
            return;
        }
        copyText.select();
        document.execCommand("copy");
        window.getSelection().removeAllRanges();
    }
</script>

</body>
</html>```