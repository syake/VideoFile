package com.syake.videofile
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	
	/**
	 * VideoFileManager オブジェクトは、複数のメディアファイルのダウンロードを一括して管理します。
	 * @version Flash Player 10.1
	 * @ActionScriptversion ActionScript 3.0
	 * @author Hiroaki Komatsu
	 */
	public class VideoFileManager extends EventDispatcher
	{
		/**
		 * グローバル化
		 */
		private static var shared:VideoFileManager;
		
		/**
		 * 指定されたURLからファイルデータを取得します。
		 * @param urlメディアのURL
		 * @return ファイルデータ
		 */
		public static function getFile(url:String):File
		{
			if (!shared) return null;
			var videoFile:VideoFile = shared.videoFile;
			return videoFile.getFile(url);
		}
		
		/**
		 * 指定されたURLからファイルデータを取得して、バイト配列に変換します。
		 * @param urlメディアのURL
		 * @return バイト配列
		 */
		public static function getFileBytes(url:String):ByteArray
		{
			//ファイルを取得
			var file:File = VideoFileManager.getFile(url);
			
			if (!file) {
				return null;
			}
			
			if (!file.exists) {
				return null;
			}
			
			//バイト配列生成
			var bytes:ByteArray = new ByteArray();
			
			//ファイルの内容の読み込み
			var stream:FileStream = new FileStream();
			stream.open(file, FileMode.READ);
			stream.readBytes(bytes);
			stream.close();
			
			return bytes;
		}
		
		/**
		 * VideoFileオブジェクト
		 * @see com.syake.filesystem.VideoFile
		 */
		public function get videoFile():VideoFile {
			return _videoFile;
		}
		private var _videoFile:VideoFile;
		
		/**
		 * 現在ロードされているメディアファイルの数です。
		 */
		public function get loaded():uint {
			return _downloadCount;
		}
		private var _downloadCount:uint;
		
		/**
		 * 指定されたメディアファイルの総数です。
		 */
		public function get total():uint {
			return _total;
		}
		private var _total:uint;
		
		/**
		 * 現在ダウンロードされている動画ファイルのリスト
		 */
		private var _list:Vector.<String>;
		
		/**
		 * 同じファイルがすでにダウンロードされていたときファイルをキャッシュする
		 */
		private var _cache:Boolean;
		
		/**
		 * 真（ture）のとき、ダウンロードエラーもしくはセキュリティエラーが発生し、尚かつイベントリスナーが登録されていたときに処理を一時的に止める
		 * 再開するためには nextDownload メソッドを実行する
		 */
		public var breakpoint:Boolean = true;
		
		/**
		 * VideoFileManagerクラスを生成します。
		 * @param path　保存先のディレクトリパス
		 */
		public function VideoFileManager(path:String = "")
		{
			shared = this;
			
			//VideoFileクラス生成
			_videoFile = new VideoFile(path);
			_downloadCount = 0;
			_total = 0;
		}
		
		/**
		 * メディアファイルのダウンロードを開始します。
		 * @param list
		 * @param cache 真（ture）のとき、同じファイルがすでにダウンロードされていたときファイルをキャッシュする
		 */
		public function downloads(list:Vector.<String>, cache:Boolean = false):void
		{
			if (!list) return;
			_list = list;
			_cache = cache;
			
			//イベントリスナーを登録
			_videoFile.addEventListener(Event.COMPLETE, handleDownloadComplete);
			_videoFile.addEventListener(IOErrorEvent.IO_ERROR, handleDownloadIOError);
			_videoFile.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleDownloadSecurityError);
			_videoFile.addEventListener(ProgressEvent.PROGRESS, dispatchEvent);
			
			//ダウンロード開始
			_downloadCount = 0;
			_total = _list.length;
			download();
		}
		
		/**
		 * メディアファイルをダウンロードします。
		 */
		private function download():void
		{
			if (_list.length > _downloadCount) {
				_videoFile.download(_list[_downloadCount], _cache);
			} else {
				//全て完了
				_list = null;
				_videoFile.removeEventListener(Event.COMPLETE, handleDownloadComplete);
				_videoFile.removeEventListener(IOErrorEvent.IO_ERROR, handleDownloadIOError);
				_videoFile.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, handleDownloadSecurityError);
				_videoFile.removeEventListener(ProgressEvent.PROGRESS, dispatchEvent);
				dispatchEvent(new Event(Event.COMPLETE));
			}
		}
		
		/**
		 * カウントアップして、次のダウンロードを開始します。
		 */
		public function nextDownload():void
		{
			if (!_list) return;
			_downloadCount++;
			download();
		}
		
		/**
		 * @private
		 * メディアのダウンロードに成功したときに呼び出されます。
		 * @param event
		 */
		protected function handleDownloadComplete(event:Event):void
		{
			nextDownload();
		}
		
		/**
		 * @private
		 * メディアのダウンロードに失敗したときに呼び出されます。
		 * @param event
		 */
		protected function handleDownloadIOError(event:IOErrorEvent):void
		{
			if (willTrigger(IOErrorEvent.IO_ERROR)) {
				dispatchEvent(event);
				if (breakpoint) return;
			}
			nextDownload();
		}
		
		/**
		 * @private
		 * メディアのダウンロード時にセキュリティエラーが発生したときに呼び出されます。
		 * @param event
		 */
		protected function handleDownloadSecurityError(event:SecurityErrorEvent):void
		{
			if (willTrigger(SecurityErrorEvent.SECURITY_ERROR)) {
				dispatchEvent(event);
				if (breakpoint) return;
			}
			nextDownload();
		}
		
		/**
		 * 指定されたURLからファイルデータを削除します。
		 * @param url メディアのURL
		 */
		public function deleteFile(url:String):void
		{
			_videoFile.deleteFile(url);
		}
		
		/**
		 * 指定されたURLリストにないファイルデータを削除します。
		 * @param list メディアのURLリスト
		 * @param 真（ture）のとき、VideoFileManagerクラスが管理しているディレクトリ内の全てのメディアファイルを削除対象にする
		 */
		public function deleteDiffFiles(list:Vector.<String>, full:Boolean = false):void
		{
			_videoFile.deleteDiffFiles(list, full);
		}
		
		/**
		 * ダウンロードしたメディアファイルを全て削除します。
		 */
		public function deleteAllFile():void
		{
			_videoFile.deleteAllFile();
		}
		
		/**
		 * DBのテーブルを再構築します。
		 */
		public function rebuild():void
		{
			_videoFile.rebuild();
		}
	}
}
