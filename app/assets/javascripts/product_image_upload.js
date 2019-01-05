
$(function(){

  //ドラッグアンドドロップのエリアを変数指定
  var droparea = document.getElementById('droparea');

  // 指定部分の上に乗っかっているときの処理
  droparea.addEventListener('dragover', function (e) {
    // ドロップ時にファイルが開かないようにする
    e.preventDefault();
    e.stopPropagation();
  });



  // 指定部分に画像をドロップした際の処理
  droparea.addEventListener('drop', function (e) {
    e.stopPropagation();
    // ドロップ時にファイルが開かないようにする
    e.preventDefault();
    // アップロードされた画像ファイルデータの取得
    var uploaded_file_data = e.dataTransfer.files;

    // 1番目にドロップさたものは1番目のinputタグに、2番目は2番目のinputタグにといったようにのD&Dされた画像データをinputタグに入れ込むために、プレビュー画像のliタグのidと連動させる。
    var preview_count = PreviewCount();

    // D&Dのデータを指定のinputタグに入れ込む(生成されているinputタグの個数をidに組み込むことで、ドロップとinputへの入れ込みを連動させる)
    document.getElementById('upload-form-' + preview_count).files = uploaded_file_data

    // プレビューを表示するための画像データを取得
    const reader = new FileReader();
    reader.readAsDataURL(e.dataTransfer.files[0]);
    reader.onload = function (e) {
      var upload_image = e.target.result
      // プレビュー表示の関数を呼び出す
      appendImage(upload_image);
      ImageCount();
      PreviewCount();
    }
  });

  // inputタグにデータが入る毎に新しいinputフォームを作成する
    $("#drop").change(function(e) {
      var upload_form = $("#drop")

      // プレビュー画像と連動し、idが変わったinputタグを生成するため、初期値0のPreviewCountに+1したものを変数に定義しidに組み込む
      var preview_count = PreviewCount() + 1;

      // inputタグが4つになったら追加を止める、すなわちi_countが4以上になったら追加を止める条件式。
      if (preview_count <= 4){
        var input_form = `<input class='product_images' id='upload-form-${preview_count}' multiple='multiple' name='images[image][]' type='file'>`
        // inputタグに画像データが投入されたら、新たなinputタグを生成する
        upload_form.append(input_form);
      }
    });


  // D&Dされた画像のプレビューを表示
  function appendImage(upload_image){
    // var i_count = ImageCount() + 1;
    var upload_area = $(".sell-dropbox-items ul");
    var html = `<li class='sell-dropbox-items_container'>
                    <div class='sell-dropbox-items-figure'>
                        <img alt='商品画像' src='${upload_image}'>
                    </div>
                    <a class="sell-dropbox-items-btn sell-image_edit">
                      <p>編集</p>
                    </a>
                    <a class="sell-dropbox-items-btn sell-image_delete">
                      <p>削除</p>
                    </a>
                </li>`
    upload_area.append(html);
  }

  //プレビュー画像が削除や追加される毎に、プレビュー画像のidを動的に変化させる
  function PreviewCount() {
    var preview_list = document.getElementsByClassName("sell-dropbox-items_container");
    var preview_list_len = preview_list.length;
    // console.log(preview_list);
    for (var preview_list_num  = 0; preview_list_num <= preview_list_len - 1; preview_list_num++) {

      preview_list[preview_list_num].setAttribute('id',preview_list_num);
    }
    return preview_list_len
  }

  //inputタグが削除や追加される毎に、inputタグのidを動的に変化させる
  function InputCount() {
    var input_list = document.getElementsByClassName("product_images");
    var input_list_len = input_list.length;
    // console.log(preview_list);
    for (var input_list_num  = 0; input_list_num <= input_list_len - 1; input_list_num++) {

      input_list[input_list_num].setAttribute('id',input_list_num);
    }
    return input_list_len
  }




  // プレビュー画像が4つ以上の時フォームを消す
  function ImageCount() {
    var imagelist = $('li.sell-dropbox-items_container');
    if(imagelist.length >= 4){
      $('.sell-dropbox-uploader').addClass('hidden');
      $('.product_images').addClass('hidden');
      $('ul.sell-dropbox-items').css('border','none');
    }
    else if (imagelist.length <= 3){
      $('.sell-dropbox-uploader').removeClass('hidden');
      $('.product_images').removeClass('hidden');
      $('ul.sell-dropbox-items').css('border-right','thin dashed gray');
    }
    // プレビュー画像の個数を戻り値として設定(初期値0)
    return imagelist.length
  }

  // 編集機能
  $(document).on("click",".sell-image_edit",function(e) {
    document.getElementById("btn").click();
  });

  // 削除機能
  $(document).on("click",".sell-image_delete",function(e) {
    $(this).parent().remove();
    var delete_obj = this.parentNode;
    var delete_obj_id = delete_obj.id;
    var delete_input_data = document.getElementById('upload-form-' + delete_obj_id);
    delete_input_data.remove();
    ImageCount();
    PreviewCount();
    InputCount();

  });






});


