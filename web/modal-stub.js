const modalOpen = (() => {
  let modal;
  let modalCover;
  let modalBody;
  let isOpend = false;

  // モーダル開閉定義
  let mock = {
    title: "タイトル",
    open: () => {
      if (isOpend) return;

      // 背景設定
      modalCover = document.createElement("div");
      modalCover.style = "position: fixed; top: 0px; right: 0px; left: 0px; bottom: 0px; z-index: 1002; background: rgba(0,0,0,.8); display: none;";
      document.body.appendChild(modalCover);

      // モーダル本体設定
      modal = document.createElement("div");
      modal.style = "position: fixed; top: 32px; right: 0px; left: 0px; z-index: 1003; background: #fff; display: none; width: 600px; margin: 0 auto; padding: 24px;";
      modal.innerHTML = `  <h2 name="title">${mock.title}</h2>
        <div name="body"></div>`;
      document.body.appendChild(modal);

      // モーダルbody設定
      modalBody = modal.querySelector("[name=body]");
      mock.onOpen(modalBody);

      // モーダル表示
      modalCover.style.display = "block";
      modal.style.display = "block";
      isOpend = true;
    },
    close: () => {
      if (!isOpend) return;

      // モーダルbody終了処理
      mock.onClose(modalBody);

      // モーダル要素削除
      document.body.removeChild(modal);
      document.body.removeChild(modalCover);

      // 変数初期化
      modal = undefined;
      modalCover = undefined;
      modalBody = undefined;
      isOpend = false;
    },
    onOpen: (modalBody) => {},
    onClose: (modalBody) => {},
  };



  // モーダルの内部定義
  // モーダルタイトル
  mock.title = "スタブ";

  // モーダルを閉じるボタン
  let button;

  // モーダルを開いた際の処理
  mock.onOpen = (modalBody) => {
    button = document.createElement("input");
    button.type = "button";
    button.value = "モーダルを閉じる";
    button.addEventListener("click", mock.close);
    modalBody.appendChild(button);
  };

  // モーダルを閉じた際の処理
  mock.onClose = (modalBody) => {
    button.removeEventListener("click", mock.close);
    button = undefined;
  }

  return mock.open;
})();

