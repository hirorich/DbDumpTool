// Light DOM に template で読み込み
function initSample2() {
    console.log("initSample2");
    var template = document.querySelector("#template2");
    var clone = template.content.cloneNode(true);
    document.querySelector("#sample2").appendChild(clone);
}

// Shadow DOM に template で読み込み
function initSample3() {
    console.log("initSample3");
    var template = document.querySelector("#template3");
    var clone = template.content.cloneNode(true);
    var shadowRoot = document.querySelector("#sample3").attachShadow({mode: 'closed'});
    shadowRoot.appendChild(clone);
}

// Shadow DOM にベタ打ちで読み込み
function initSample4() {
    console.log("initSample4");
    var shadowRoot = document.querySelector("#sample4").attachShadow({mode: 'closed'});
    var el = document.createElement("div");
    el.innerHTML = `
    <link href="./css/sample4.css" rel="stylesheet" />
    <script src="./js/sample4.js"></script>
    <button class="class1" onclick="func1();">sample 1</button>
    <button class="class2" onclick="func2();">sample 2</button>
    <button class="class3" onclick="func3();">sample 3</button>
    <button class="class4" onclick="func4();">sample 4</button>
    <button class="class5" onclick="func5();">sample 5</button>
`;
    shadowRoot.appendChild(el);
}

// 各初期化実行
document.addEventListener("DOMContentLoaded", () => {
    console.log("DOMContentLoaded");
    initSample2();
    initSample3();
    initSample4();
});
