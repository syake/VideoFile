VideoFile
=========

メディアファイルをアプリケーションストレージ内にダウンロードして管理します。

ASDoc
---------------
[http://syake.github.com/VideoFile/asdoc/com/syake/videofile/VideoFile.html](http://syake.github.com/VideoFile/asdoc/com/syake/videofile/VideoFile.html "ASDoc")

Example
---------------

ファイルをアプリケーションストレージにダウンロードして再生
```javascript
public class Exmaple extends Sprite
{
  /**
   * ダウンロードで使用する動画ファイル
   */
  private var url = "http://syake.github.com/VideoFileExample/QfPqYM174JQ.flv";
  
  /**
   * @see com.syake.filesystem.VideoFile
   */
  private var videoFile:VideoFile;
  
  /**
   * @see flash.media.Video
   */
  private var video:Video;
  
  /**
   * コンストラクタ
   */
  function Exmaple(){
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
   * メディアのダウンロードに成功したときに呼び出されます。
   * @param event
   */
  private function handleDownloadComplete(event:Event):void
  {
    //ファイルを取得
    var file:File = videoFile.getFile(url);
    
    var bytes:ByteArray = new ByteArray();
    
    //ファイルの内容の読み込み
    var stream:FileStream = new FileStream();
    stream.open(file, FileMode.READ);
    stream.readBytes(bytes);
    stream.close();
    
    //ローカルファイルアクセス用のネットコネクションを作成する
    var connection:NetConnection = new NetConnection();
    connection.connect(null);
    
    //ネットストリームオブジェクトを作成する
    var netStream:NetStream = new NetStream(connection);
    var client:Object = new Object();
    client.onMetaData = function(param:Object):void {
      trace("総時間 : " + param.duration + "秒");
      trace("幅 : " + param.width);
      trace("高さ : " + param.height);
      trace("ビデオレート : " + param.videodatarate + "kb");
      trace("フレームレート : " + param.framerate + "fps");
      trace("コーデックＩＤ : " + param.videocodecid);
    }
    netStream.client = client;
    
    //ビデオオブジェクトとネットストリームオブジェクトを関連付ける
    video.attachNetStream(netStream);
    
    //再正開始
    try {
      netStream.play(null);
      netStream.appendBytesAction(NetStreamAppendBytesAction.RESET_BEGIN);
      netStream.appendBytes(bytes);
    } catch (err:Error) {
      trace(err);
    }
  }
}
```
VideoFileExample  
[https://github.com/syake/VideoFileExample](https://github.com/syake/VideoFileExample "VideoFileExample")
