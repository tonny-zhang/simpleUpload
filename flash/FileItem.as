package  {
	import flash.net.FileReference;
	import flash.display.Loader;
	import flash.events.*;	
	
	import flash.utils.Timer;

	import flash.events.Event;
	import flash.display.Sprite;
	
	public class FileItem extends Sprite {
		public var file_name:String;
		public var file_reference:FileReference;
		private var _this:FileItem;
		public var settings:Object;
		public var jsCaller:JsCaller;
		
		private var _timer:Timer;
		private var _timer_handle:Function;
		
		private var _file_data_loader:Loader;
		private var compressor:Compressor;
		
		public function FileItem(file_name:String,file_reference:FileReference,settings:Object) {
			_this = this;
			_this.file_name = file_name;
			_this.file_reference = file_reference;
			_this.settings = settings;
			jsCaller = new JsCaller(settings.movieName,settings.cb);
		}
		public function getFileName(){
			return _this.file_name;
		}
		/*开始处理*/
		public function startDeal(){
			//在打开本地图片之前响应，给用户更好的体验
			jsCaller.callback(JsCaller.EVENT_START_UPLOAD,_this.file_name);
			
			_this.file_reference.addEventListener(Event.COMPLETE, _this._handle_load_file_complete);
			_this.file_reference.addEventListener(IOErrorEvent.IO_ERROR, _this._handle_load_file_error);
			_this.file_reference.load();
		}
		/*处理完成*/
		public function completeDeal(msg:String){
			_this.dispatchEvent(new UploadEvent(UploadEvent.UPLOAD_COMPLETE,_this.file_name,msg));
		}
		/*取消处理*/
		public function cancelDeal(){
			_this._removeAllEvent();
			_this.dispatchEvent(new UploadEvent(UploadEvent.UPLOAD_CANCEL_COMPLETE,_this.file_name));
		}
		/***********************　工具方法　***************************/
		/*清除超时*/
		private function _clearTimeout(){
			if(_this._timer){
				_this._timer.removeEventListener(TimerEvent.TIMER_COMPLETE,_this._timer_handle);
			}
		}
		/*超时*/
		private function _setTimeout(handle:Function,delay:Number){
			_this._clearTimeout();//先清除之前的超时处理
			_this._timer = new Timer(delay,1);
			_this._timer_handle = handle;
			_this._timer.addEventListener(TimerEvent.TIMER_COMPLETE,handle);
			_this._timer.start();
		}
		/*调用js里错误通知*/
		public function errorMsg(state:Number,msg:String){
			_this.jsCaller.callback(JsCaller.EVENT_UPLOAD_ERROR,_this.file_name,state,msg);
			_this.dispatchEvent(new UploadEvent(UploadEvent.UPLOAD_ERROR,_this.file_name,msg));
		}
		
		/*****************  事件处理  *********************/
		private function _removeAllEvent(){
			_this._remove_load_file_event();
			_this._remove_load_file_data_event();
			_this._remove_compress_event();
			_this._clearTimeout();
		}
		private function _remove_load_file_event(){
			if(_this.file_reference){
				_this.file_reference.removeEventListener(Event.COMPLETE, _this._handle_load_file_complete);
				_this.file_reference.removeEventListener(IOErrorEvent.IO_ERROR, _this._handle_load_file_error);
			}
			//把超时清除
			_this._clearTimeout();
		}
		/*加载超时*/
		private function _handle_delay_load(e:TimerEvent){
			/*if(_this._state == State.FILE_STATE_LOADING_FILE || _this._state == State.FILE_STATE_LOADING_DATA){
				_this._removeAllEvent();
				_this.errorMsg(State.ERROR_TIMEOUT_LOAD_DATA,'文件加载超时');
			}*/
		}
		/*加载文件信息*/
		private function _handle_load_file_complete(e:Event){
			_this._remove_load_file_event();
			
			//_this._state = State.FILE_STATE_LOADING_DATA;
			var _fileDataLoader = _this._file_data_loader = new Loader();
			
			_fileDataLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, _this._handle_load_file_data_complete);
			_fileDataLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, _this._handle_load_file_data_error);
			
			if(_this.settings.loadDelay){
				_this._setTimeout(_handle_delay_load,_this.settings.loadDelay);
			}
			_fileDataLoader.loadBytes(e.target.data);
		}
		/*加载文件信息失败*/
		private function _handle_load_file_error(e:IOErrorEvent){
			_this._remove_load_file_event();
			_this.errorMsg(State.ERROR_LOAD_FILE,'加载本地图片时出现错误');
		}
		
		/*删除加载图片数据事件*/
		private function _remove_load_file_data_event(){
			var t = _this._file_data_loader;
			if(t){
				t.removeEventListener(Event.COMPLETE, _this._handle_load_file_data_complete);
				t.removeEventListener(IOErrorEvent.IO_ERROR, _this._handle_load_file_data_error);
				t = null;
			}
			//清除超时
			_this._clearTimeout();
		}
		/*loader加载本地图片数据完成事件*/
		private function _handle_load_file_data_complete(e:Event){
			_this._remove_load_file_data_event();
			
			var loader:Loader = Loader(e.target.loader);
			var _oldWidth = loader.width,
				_oldHeight = loader.height;
			
			var error_state:Number,
				error_message:String;
				
			if(_oldWidth * _oldHeight >= 16000000){
				error_state = State.ERROR_MAX_SIZE;
				error_message = '图片尺寸过大，请尝试缩小尺寸后再上传';
			}else{
				if(_oldWidth < settings.minWidth){
					error_state = State.ERROR_MIN_WIDTH;
					error_message = '图片尺寸太小，图片宽不能小于'+settings.minWidth+'像素';
				}else if(_oldHeight < settings.minHeight){
					error_state = State.ERROR_MIN_HEIGHT;
					error_message = '图片尺寸太小，图片高不能小于'+settings.minHeight+'像素';
				}
			}
			if(error_state && error_message){
				_this._removeAllEvent();
				_this.errorMsg(error_state,error_message);
				return;
			}
			//当文件的大小太小时不进行压缩处理
			if(_this.settings.noCompressUnderSize > _this.file_reference.size){
				new Uploader(_this,_this.file_reference.data,false);
			}else{
				var compressor = _this.compressor = new Compressor();
				compressor.addEventListener(UploadEvent.UPLOAD_BEFORE_COMPRESS,_this._handle_before_compress);
				compressor.addEventListener(UploadEvent.UPLOAD_AFTER_COMPRESS,_this._handle_after_compress);
				compressor.addEventListener(UploadEvent.UPLOAD_COMPRESS_ERROR,_this._handle_error_compress);
				
				compressor.compress(loader,settings.thumbnailWidth,settings.thumbnailHeight,settings.thumbnailQuality);
			}
		}
		/*loader加载本地图片数据错误事件*/
		private function _handle_load_file_data_error(e:IOErrorEvent){			
			_this._remove_load_file_data_event();
			_this.errorMsg(State.FILE_STATE_LOADING_DATA,'加载本地图片数据时出现错误');
		}
		
		/*删除压缩事件*/
		private function _remove_compress_event(){
			var t = _this.compressor;
			if(t){
				compressor.removeEventListener(UploadEvent.UPLOAD_BEFORE_COMPRESS,_this._handle_before_compress);
				compressor.removeEventListener(UploadEvent.UPLOAD_AFTER_COMPRESS,_this._handle_after_compress);
				compressor.removeEventListener(UploadEvent.UPLOAD_COMPRESS_ERROR,_this._handle_error_compress);
			}
		}
		/*压缩前事件*/
		private function _handle_before_compress(e:UploadEvent){
			_this.jsCaller.callback(JsCaller.EVENT_BEFORE_COMPRESS,_this.file_name,e.msg);
		}
		/*压缩后事件*/
		private function _handle_after_compress(e:UploadEvent){
			_this._remove_compress_event();
			var info = e.msg;
			_this.jsCaller.callback(JsCaller.EVENT_AFTER_COMPRESS,_this.file_name,{width:info.width,height:info.width,size:info.byte.length});
			new Uploader(_this,info.byte);			
		}
		/*压缩错误事件*/
		private function _handle_error_compress(e:UploadEvent){
			_this._remove_compress_event();
			_this.errorMsg(State.ERROR_COMPRESS,'压缩图片数据时出现错误');			
		}
	}
}
