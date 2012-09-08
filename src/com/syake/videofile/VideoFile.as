package com.syake.videofile
{
	import flash.data.SQLConnection;
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.errors.SQLError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	
	import mx.utils.UIDUtil;
	
	/**
	 * VideoFile オブジェクトは、メディアファイルをアプリケーションストレージ内にダウンロードして管理します。
	 * @version Flash Player 10.1
	 * @ActionScriptversion ActionScript 3.0
	 * @author Hiroaki Komatsu
	 */
	public class VideoFile extends EventDispatcher
	{
		/**
		 * @private
		 * DBファイル
		 * @see flash.filesystem.File
		 */
		protected var _db:File;
		
		/**
		 * @private
		 * ディレクトリファイル
		 * @see flash.filesystem.File
		 */
		protected var _dir:File;
		
		/**
		 * @private
		 * DBの接続状況
		 */
		protected var _isOpen:Boolean;
		
		/**
		 * @private
		 * 接続したSQLConnection
		 * @see flash.data.SQLConnection
		 */
		protected var _dbConnection:SQLConnection;
		
		/**
		 * @private
		 * メディアダウンロード用のURLLoader
		 * @see flash.net.URLLoader
		 */
		protected var loader:URLLoader;
		
		/**
		 * @private
		 * メディアダウンロード用のURLRequest
		 * @see flash.net.URLRequest
		 */
		protected var request:URLRequest;
		
		/**
		 * VideoFile クラスのコンストラクタ関数です。
		 * @param path　保存先のディレクトリパス
		 */
		public function VideoFile(path:String = "")
		{
			_dbConnection = new SQLConnection();
			create(path);
		}
		
		/**
		 * @private
		 * 指定されたバスから、DBを接続してテーブルを生成します。
		 * @param path　保存先のディレクトリパス
		 */
		protected function create(path:String):void
		{
			//dbファイル作成
			_dir = createPath(path);
			_db = _dir.resolvePath("dbfile.db");
			
			//接続
			open(_dbConnection, _db);
			
			//テーブルを生成
			if (_isOpen) {
				createTable(_dbConnection);
			}
		}
		
		/**
		 * @private
		 * 指定されたバスから、保存先のディレクトリファイルを生成して取得します。
		 * @param path 保存先のディレクトリパス
		 * @return ディレクトリファイル
		 */
		protected function createPath(path:String):File
		{
			var dir:File = File.applicationStorageDirectory;
			if (path.indexOf("/") == 0) path = path.substr(1);
			var tmp:Array = path.split("/");
			
			//ディレクトリの作成
			if (tmp.length > 0) {
				dir = dir.resolvePath(tmp.join("/"));
				dir.createDirectory();
			}
			return dir;
		}
		
		/**
		 * @private
		 * DBへの接続を確立します。
		 * @param sqlConnection 接続したSQLConnectionを指定します。
		 * @param dbFile 接続するDBファイルを指定します。
		 */
		protected function open(sqlConnection:SQLConnection, dbFile:File):void	
		{
			//同期処理
			try {
				sqlConnection.open(dbFile);
				_isOpen = true;
			} catch(error:SQLError) {
				trace("DB 接続失敗");
				trace("エラー: " + error.message);
				trace("詳細: " + error.details);
			}
		}
		
		/**
		 * @private
		 * DBにテーブルを作成します。
		 * @param sqlConnection 接続したSQLConnectionを指定します。
		 */
		protected function createTable(sqlConnection:SQLConnection):void
		{
			//テーブルが無いならばテーブルを作ります。
			var sqlString:String = "CREATE TABLE IF NOT EXISTS video(" +
				"no INTEGER PRIMARY KEY AUTOINCREMENT," +
				"id TEXT," +
				"movie_url TEXT," +
				"created_at TEXT" +
				")";
			
			var statement:SQLStatement = new SQLStatement();
			statement.sqlConnection = sqlConnection;
			statement.text = sqlString;
			
			try {
				statement.execute();
			} catch(error:SQLError) {
				trace("SQL CREATE 失敗");
				trace("エラー: " + error.message);
				trace("詳細: " + error.details);
			}
		}
		
		/**
		 * @private
		 * テーブルを削除します。
		 * @param sqlConnection 接続したSQLConnectionを指定します。
		 */
		protected function dropTable(sqlConnection:SQLConnection):void
		{
			//テーブルを削除します。
			var sqlString:String = "DROP TABLE video";
			
			var statement:SQLStatement = new SQLStatement();
			statement.sqlConnection = sqlConnection;
			statement.text = sqlString;
			
			try {
				statement.execute();
			} catch(error:SQLError) {
				trace("SQL DROP 失敗");
				trace("エラー: " + error.message);
				trace("詳細: " + error.details);
			}
		}
		
		/**
		 * @private
		 * DBにあるデータを取得します。
		 * @param sqlConnection 接続したSQLConnectionを指定します。
		 * @param value 条件式
		 * @return 
		 */
		protected function select(sqlConnection:SQLConnection, value:String = ""):Array
		{
			var sqlString:String = "SELECT * FROM video";
			if (value != "") sqlString += " WHERE " + value;
			var statement:SQLStatement = new SQLStatement();
			statement.sqlConnection = sqlConnection;
			statement.text = sqlString;
			
			try {
				statement.execute();
				var result:SQLResult = statement.getResult();
				return (result.data as Array);
			} catch(error:SQLError) {
				trace("SQL SELECT 失敗");
				trace("エラー: " + error.message);
				trace("詳細: " + error.details);
			}
			return null;
		}
		
		/**
		 * @private
		 * DBからデータを挿入します。
		 * @param sqlConnection 接続したSQLConnectionを指定します。
		 * @param data 購入するメディアデータ
		 */
		protected function insert(sqlConnection:SQLConnection, data:_DataModel):void
		{
			var sqlString:String = "INSERT INTO video" +
				"(id, movie_url, created_at)" +
				" VALUES " +
				"(:id, :movie_url, :created_at)";
			
			var statement:SQLStatement = new SQLStatement();
			statement.sqlConnection = sqlConnection;
			statement.parameters[":id"] = data.id;
			statement.parameters[":movie_url"] = data.movie_url;
			statement.parameters[":created_at"] = "";
			statement.text = sqlString;
			
			try {
				statement.execute();
			} catch(error:SQLError) {
				trace("SQL INSERT 失敗");
				trace("エラー: " + error.message);
				trace("詳細: " + error.details);
			}
		}
		
		/**
		 * @private
		 * DBからデータを削除します。
		 * @param sqlConnection 接続したSQLConnectionを指定します。
		 * @param value 条件式
		 */
		protected function delet(sqlConnection:SQLConnection, value:String = ""):void
		{
			var sqlString:String = "DELETE FROM video ";
			if (value != "") sqlString += " WHERE " + value;
			var statement:SQLStatement = new SQLStatement();
			statement.sqlConnection = sqlConnection;
			statement.text = sqlString;
			
			try {
				statement.execute();
			} catch(error:SQLError) {
				trace("SQL DELETE 失敗");
				trace("エラー: " + error.message);
				trace("詳細: " + error.details);
			}
		}
		
		/**
		 * ローカルディレクトリまたは Web サーバーからメディアファイルのダウンロードを開始します。
		 * @param url ダウンロードされるメディアのURL
		 * @param cache 同じファイルがすでにダウンロードされていたときファイルをキャッシュする
		 */
		public function download(url:String, cache:Boolean = false):void
		{
			if (!_isOpen) return;
			
			if (cache) {
				if (getFile(url)) {
					//イベントを受け渡す
					dispatchEvent(new Event(Event.COMPLETE));
					return;
				}
			}
			
			if (loader == null) {
				loader = new URLLoader();
				loader.dataFormat = URLLoaderDataFormat.BINARY;
			}
			if (request == null) {
				request = new URLRequest();
			}
			request.url = url;
			loader.addEventListener(Event.COMPLETE, handleDownloadComplete);
			loader.addEventListener(IOErrorEvent.IO_ERROR, handleDownloadIOError);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleDownloadSecurityError);
			loader.addEventListener(ProgressEvent.PROGRESS, dispatchEvent);
			loader.load(request);
		}
		
		/**
		 * @private
		 * イベントリスナーを解放します。
		 * @param dispatcher
		 */
		protected function deconfigureLoaderListeners(dispatcher:IEventDispatcher):void
		{
			dispatcher.removeEventListener(Event.COMPLETE, handleDownloadComplete);
			dispatcher.removeEventListener(IOErrorEvent.IO_ERROR, handleDownloadIOError);
			dispatcher.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, handleDownloadSecurityError);
			dispatcher.removeEventListener(ProgressEvent.PROGRESS, dispatchEvent);
		}
		
		/**
		 * @private
		 * メディアのダウンロードに成功したときに呼び出されます。
		 * @param event
		 */
		protected function handleDownloadComplete(event:Event):void
		{
			deconfigureLoaderListeners(loader);
			
			//古いデータを削除
			deleteFile(request.url);
			
			//データを挿入
			var data:_DataModel = new _DataModel();
			data.id = UIDUtil.createUID();
			data.movie_url = request.url;
			insert(_dbConnection, data);
			
			//ファイルを生成
			var file:File = _dir.resolvePath(data.id + ".flv");
			
			//ファイルの内容の書き込み
			var stream:FileStream = new FileStream();
			stream.open(file, FileMode.WRITE);
			stream.writeBytes(loader.data);
			stream.close();
			loader.close();
			
			//イベントを受け渡す
			dispatchEvent(event);
		}
		
		/**
		 * @private
		 * メディアのダウンロードに失敗したときに呼び出されます。
		 * @param event
		 */
		protected function handleDownloadIOError(event:IOErrorEvent):void
		{
			deconfigureLoaderListeners(loader);
			
			//イベントを受け渡す
			dispatchEvent(event);
		}
		
		/**
		 * @private
		 * メディアのダウンロード時にセキュリティエラーが発生したときに呼び出されます。
		 * @param event
		 */
		protected function handleDownloadSecurityError(event:SecurityErrorEvent):void
		{
			deconfigureLoaderListeners(loader);
			
			//イベントを受け渡す
			dispatchEvent(event);
		}
		
		/**
		 * 指定されたURLからファイルデータを取得します。
		 * @param url メディアのURL
		 * @return ファイルデータ
		 */
		public function getFile(url:String):File
		{
			if (!_isOpen) null;
			
			var result:Array = select(_dbConnection, "movie_url = '" + url + "'");
			if (result != null) {
				var obj:Object = (result.length > 0) ? result[0] : null;
				var file:File = _dir.resolvePath(obj.id + ".flv");
				if (file.exists) {
					return file;
				} else {
					delet(_dbConnection, "movie_url = '" + url + "'");
					return null;
				}
			}
			return null;
		}
		
		/**
		 * 指定されたURLからファイルデータを削除します。
		 * @param url メディアのURL
		 */
		public function deleteFile(url:String):void
		{
			if (!_isOpen) return;
			
			//DBからデータを削除
			delet(_dbConnection, "movie_url = '" + url + "'");
			
			var file:File = getFile(url);
			if (file != null) {
				file.deleteFile();
				file = null;
			}
		}
		
		/**
		 * 指定されたURLリストにないファイルデータを削除します。
		 * @param list メディアのURLリスト
		 * @param full 真（ture）のとき、VideoFileクラスが管理しているディレクトリ内の全てのメディアファイルを削除対象にする
		 */
		public function deleteDiffFiles(list:Vector.<String>, full:Boolean = false):void
		{
			if (!_isOpen) return;
			
			var file:File, i:uint;
			
			//指定リストをオブジェクト化
			var diff_obj:Object = {};
			if (list) {
				i = list.length;
				while (i--) {
					diff_obj[list[i]] = true;
				}
			}
			
			//ストレージ内のパスを格納したオブジェクトを用意
			var diff_obj2:Object = {};
			
			//ファイルデータを削除
			var result:Array = select(_dbConnection);
			if (result) {
				var temp:Array = [];
				var n:uint = result.length;
				for (i = 0; i < n; i++) {
					var obj:Object = result[i];
					var url:String = obj.id + ".flv";
					if (diff_obj[obj.movie_url]) {
						diff_obj2[url]= true;
						continue;
					}
					
					//削除するデータを生成
					temp.push("movie_url = '" + url + "'");
					
					//ファイル削除
					file = _dir.resolvePath(url);
					if (file.exists) {
						file.deleteFile();
						file = null;
					}
				}
				
				//DBからデータを削除
				if (temp.length > 0) delet(_dbConnection, temp.join(" OR "));
			}
			
			//それ以外の全てのファイルデータを削除
			if (full) {
				var files:Array = _dir.getDirectoryListing();
				i = files.length;
				while (i--) {
					file = files[i];
					if (file.extension == "flv" && !diff_obj2[file.name]) {
						file.deleteFile();
						file = null;
					}
				}
			}
		}
		
		/**
		 * ダウンロードしたメディアファイルを全て削除します。
		 */
		public function deleteAllFile():void
		{
			if (!_isOpen) return;
			
			//ファイルを削除
			var result:Array = select(_dbConnection);
			if (result) {
				var n:uint = result.length;
				for (var i:uint = 0; i < n; i++) {
					var obj:Object = result[i];
					var file:File = _dir.resolvePath(obj.id + ".flv");
					if (file.exists) {
						file.deleteFile();
						file = null;
					}
				}
			}
			
			//DBから全てのデータを削除
			delet(_dbConnection);
		}
		
		/**
		 * DBのテーブルを再構築します。
		 */
		public function rebuild():void
		{
			if (!_isOpen) return;
			
			//一応ファイルを削除
			deleteAllFile();
			
			//テーブルを削除
			dropTable(_dbConnection);
			
			//テーブルを生成
			createTable(_dbConnection);
		}
	}
}

/**
 * テーブルに購入するデータモデル
 * @version Flash Player 9
 * @ActionScriptversion ActionScript 3.0
 * @author Hiroaki Komatsu
 */
class _DataModel
{
	/**
	 * 作品ID
	 */
	public var id:String;
	
	/**
	 * 作品（動画）のURL
	 */
	public var movie_url:String;
}
