package  {
	import flash.events.Event;
	public class UploadEvent extends Event {

		/*上传完成触发*/
		public static const UPLOAD_COMPLETE:String = "UPLOAD_COMPLETE";
		/*上传出现错误*/
		public static const UPLOAD_ERROR:String = "UPLOAD_ERROR";
		public static const UPLOAD_CANCEL_COMPLETE:String = 'UPLOAD_CANCEL_COMPLETE';
		
		public static const UPLOAD_BEFORE_COMPRESS = 'BEFORE_COMPRESS';
		public static const UPLOAD_AFTER_COMPRESS = 'AFTER_COMPRESS';
		public static const UPLOAD_COMPRESS_ERROR = 'COMPRESS_ERROR';
		
		public var fileName:String;
		public var msg:Object;
		public function UploadEvent(type:String,fileName:String,msg:Object='') {
			super(type);
			this.fileName = fileName;
			this.msg = msg;
		}
	}	
}
