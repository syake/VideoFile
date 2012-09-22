VideoFile
=========

条件
---------------
 * Flash 10.1
 * AIR 2.0

機能
---------------
 * メディアファイルをアプリケーションストレージ内にダウンロードする
 * ダウンロードしたファイルをSQLiteで管理する
 * ローカル再生するためにurlを指定してFileクラスを取得する
 * その他SQLiteのテーブルをリセット

ダウンロード
---------------
 * このプラグインはGitHubにて公開されています
    * [https://github.com/syake/VideoFile/downloads](https://github.com/syake/VideoFile/downloads)

ドキュメント
---------------
 * VideoFile
    * [http://syake.github.com/VideoFile/asdoc/com/syake/videofile/VideoFile.html](http://syake.github.com/VideoFile/asdoc/com/syake/videofile/VideoFile.html "VideoFile")  
 * VideoFileManager
    * [http://syake.github.com/VideoFile/asdoc/com/syake/videofile/VideoFileManager.html](http://syake.github.com/VideoFile/asdoc/com/syake/videofile/VideoFileManager.html "VideoFileManager")  

サンプルファイル
---------------
 * VideoFileExample
    * 動画リストを連続してダウンロードするサンプルです。
    * 開発環境は Flex モバイルプロジェクト で作成しています。 

Example
---------------

ファイルをアプリケーションストレージにダウンロードして再生
```javascript
public class Exmaple extends Sprite
{
  /**
   * ダウンロードで使用する動画ファイル
   */
  private var url = "http://syake.github.com/VideoFile/video/QfPqYM174JQ.flv";
  
  /**
   * @see com.syake.filesystem.VideoFile
   */
  private var videoFile:VideoFile;
  
  /**
   * @see flash.media.Video
   */
  private var video:Video;
  
  /**
   * @see flash.net.NetStream
   */
  private var netStream:NetStream;
  
  /**
   * コンストラクタ
   */
  function Exmaple()
  {
    //ビデオインスタンス生成
    video = new Video(320, 240);
    addChild(video);
    
    //ダウンロード開始
    download();
  }
  
  /**
   * ダウンロード開始
   */
  private function download():void
  {
    videoFile = new VideoFile("video");
    videoFile.addEventListener(Event.COMPLETE, handleDownloadComplete);
    videoFile.download(url);
  }
  
  /**
   * メモリ解放
   */
  private function dispose():void
  {
    if (netStream) netStream.dispose();
    video.clear();
  }
  
  /**
   * メディアのダウンロードに成功したときに呼び出されます。
   * @param event
   */
  private function handleDownloadComplete(event:Event):void
  {
    //ファイルを取得
    var file:File = videoFile.getFile(url);
    
    //メディアファイルのバイト配列を取得
    var bytes:ByteArray = new ByteArray();
    
    //ファイルの内容の読み込み
    var stream:FileStream = new FileStream();
    stream.open(file, FileMode.READ);
    stream.readBytes(bytes);
    stream.close();
    
    //メモリ解放
    dispose();
    
    if (netStream == null) {
      //ローカルファイルアクセス用のネットコネクションを作成する
      var connection:NetConnection = new NetConnection();
      connection.connect(null);
      
      //ネットストリームオブジェクトを作成する
      netStream = new NetStream(connection);
      var client:Object = new Object();
      client.onMetaData = function(param:Object):void {
        var bytevalue:String = (function(bytelength:uint):String {
          if (bytelength > 1024 * 1024) {
            return String(bytelength / 1024 / 1024) + " MB";
          }
          else if (bytelength > 1024) {
            return String(bytelength / 1024) + " KB";
          }
          return bytelength + " バイト";
        })(param.bytelength);
        trace("総時間 : " + param.duration + " 秒");
        trace("現在のサイズ : " + param.width + " × " + param.height + " ピクセル");
        trace("FPS : " + param.framerate);
        trace("データ容量 : " + bytevalue);
        trace("データレート : " + param.totaldatarate + " キロビット／秒");
        trace("ビデオレート : " + param.videodatarate + " キロビット／秒");
        trace("オーディオレート : " + param.audiodatarate + " キロビット／秒");
        if (param.videocodecid) trace("コーデックＩＤ : " + param.videocodecid);
      }
      netStream.client = client;
      
      //ビデオオブジェクトとネットストリームオブジェクトを関連付ける
      video.attachNetStream(netStream);
    }
    
    //プレイアウト
    try {
      netStream.play(null);
      netStream.appendBytesAction(NetStreamAppendBytesAction.RESET_BEGIN);
      netStream.appendBytes(bytes);
      if (netStream.info.dataBufferByteLength == 0) {
        netStream = null;
        return false;
      }
    } catch (err:Error) {
      trace(err);
    }
  }
}
```

差分を削除
```javascript
var list:Vector.<String> = Vector.<String>(["*.flv","*.flv","*.flv","*.flv","*.flv"]);
videoFile.deleteDiffFiles(list, true);
```

DBの中身を全て削除する
```javascript
videoFile.deleteAllFile();
```

DBのテーブルを再構築する
```javascript
videoFile.rebuild();
``` 

