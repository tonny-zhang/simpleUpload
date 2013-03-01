package{
	internal class State{
		public static const ERROR_LOAD_FILE = 10;				//加载本地图片错误
		public static const ERROR_UPLOAD_FILE_IO  = 11;			//上传文件IO错误
		public static const ERROR_UPLOAD_FILE_SECURITY  = 112;	//上传文件安全错误security
		public static const ERROR_MIN_WIDTH = 12;				//文件宽度太小
		public static const ERROR_MIN_HEIGHT = 121;				//文件高度太小
		public static const ERROR_MAX_SIZE = 122;				//文件尺寸太大
		public static const ERROR_FILE_TYPE = 123;				//文件类型不对
		public static const ERROR_TIMEOUT_LOAD_DATA = 13;		//加载本地图片超时
		public static const ERROR_TIMEOUT_UPLOAD = 131;			//上传超时
		public static const ERROR_COMPRESS = 140;				//压缩错误
		
		public static const FILE_STATE_LOADING_FILE = 20;		//加载本地图片
		public static const FILE_STATE_LOADING_DATA = 21;		//加载图片二进制数据
		public static const FILE_STATE_UPLOAD_PREPARING = 22;	//上传前准备
		public static const FILE_STATE_COMPRESSING = 23;		//压缩中
		public static const FILE_STATE_UPLOADING = 24;			//上传中
		public static const FILE_STATE_UPLOADED = 25;			//上传完成
		public static const FILE_STATE_CANCEL = 26;				//取消上传
	}
}