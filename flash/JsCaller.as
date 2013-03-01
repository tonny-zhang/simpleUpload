package  {
	import flash.external.ExternalInterface;
	public class JsCaller {
		public static var EVENT_ERROR = 'error';
		public static var EVENT_INIT_SETTING_SUCCESS = 'initSettingSuccess';
		
		public static var EVENT_MOUSE_ENTER = 'mouseEnter';
		public static var EVENT_MOUSE_LEAVE = 'mouseLeave';
		public static var EVENT_MOUSE_DOWN = 'mouseDown';
		public static var EVENT_MOUSE_UP = 'mouseUp';
		
		public static var EVENT_TO_MAX_NUM = 'toMaxNum';
		public static var EVENT_TO_MAX_SIZE = 'toMaxSize';
		public static var EVENT_ILLEGAL_FILE_TYPE = 'illegalFileType';
		
		public static var EVENT_GET_FILES = 'getFiles';
		public static var EVENT_START_UPLOAD = 'startUpload';
		public static var EVENT_UPLOAD_PROCESS = 'uploadProcess';
		public static var EVENT_UPLOAD_ERROR = 'uploadError';
		public static var EVENT_UPLOAD_COMPLETE = 'uploadComplete';
		public static var EVENT_BEFORE_COMPRESS = 'beforeCompress';
		public static var EVENT_AFTER_COMPRESS = 'afterCompress';
		public static var EVENT_CANCEL_SUCCESS = 'cancelSuccess';

		private var handleName:String = 'cb';
		private var movieName = '';
		
		public function JsCaller(movieName:String,jsCallbackName:String){
			this.movieName = movieName;
			this.handleName = jsCallbackName;
		}
		//调用js方法，[jsFnName,args...]
		public function callback(... arguments){
			arguments.unshift(this.movieName);
			arguments.unshift(this.handleName);
			Debug.log(arguments);
			ExternalInterface.call.apply(null,arguments);
		}
	}	
}
